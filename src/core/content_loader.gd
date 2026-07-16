extends RefCounted

signal content_loaded
signal content_error(error: Dictionary)

const JsonSchemaValidatorClass = preload("res://src/core/json_schema_validator.gd")
const MANIFEST_FILE := "manifest.json"
const SUPPORTED_SCHEMA_MAJOR := 1

const SCHEMA_FILES := {
    "states/state_registry.json": "state_registry.schema.json",
    "npcs/npcs.json": "npc.schema.json",
    "locations/locations.json": "location.schema.json",
    "items/items.json": "item.schema.json",
    "enemies/enemies.json": "enemy.schema.json",
    "skills/skills.json": "skill.schema.json",
    "combats/combats.json": "combat.schema.json",
    "presentation_tags.json": "presentation_tags.schema.json",
    "quest_dependencies.json": "quest_dependency.schema.json",
}

const COLLECTION_IDS := {
    "npcs": ["npc_id", "npc"],
    "locations": ["location_id", "location"],
    "items": ["item_id", "item"],
    "enemies": ["enemy_id", "enemy"],
    "skills": ["skill_id", "skill"],
    "combats": ["combat_id", "combat"],
}

var content_root := ""
var manifest: Dictionary = {}
var loaded_files: Dictionary = {}
var global_index: Dictionary = {}
var state_index: Dictionary = {}
var last_error: Dictionary = {}

var _schema_validator := JsonSchemaValidatorClass.new()


func load_content(root_path: String = "res://content") -> bool:
    _reset()
    content_root = root_path.trim_suffix("/").trim_suffix("\\")

    var manifest_path := _join_content_path(MANIFEST_FILE)
    var parsed_manifest: Variant = _parse_json_file(manifest_path, "CONTENT_MANIFEST_MISSING", "CONTENT_MANIFEST_INVALID")
    if parsed_manifest == null:
        return _finish_failure()
    if not _validate_document(parsed_manifest, "res://schemas/content_manifest.schema.json", MANIFEST_FILE):
        return _finish_failure()
    manifest = parsed_manifest

    if not _validate_schema_version(manifest, MANIFEST_FILE):
        return _finish_failure()
    if not _load_declared_files():
        return _finish_failure()
    if not _build_indexes():
        return _finish_failure()
    if not _validate_references():
        return _finish_failure()

    content_loaded.emit()
    return true


func has_id(global_id: String) -> bool:
    return global_index.has(global_id)


func get_by_id(global_id: String) -> Variant:
    if not global_index.has(global_id):
        return null
    return global_index[global_id]["data"]


func get_type_for_id(global_id: String) -> String:
    if not global_index.has(global_id):
        return ""
    return global_index[global_id]["type"]


func get_state_definition(state_key: String) -> Variant:
    return state_index.get(state_key)


func get_state_definitions() -> Array:
    var definitions: Array = []
    for definition: Variant in state_index.values():
        definitions.append(definition.duplicate(true))
    return definitions


func get_item(item_id: String) -> Variant:
    if get_type_for_id(item_id) != "item":
        return null
    var item: Variant = get_by_id(item_id)
    if item is Dictionary:
        return item.duplicate(true)
    return null


func get_item_definitions() -> Array:
    var definitions: Array = []
    for global_id: Variant in global_index.keys():
        var indexed: Dictionary = global_index[global_id]
        if str(indexed.get("type", "")) != "item":
            continue
        var data: Variant = indexed.get("data")
        if data is Dictionary:
            definitions.append(data.duplicate(true))
    return definitions


func get_enemy(enemy_id: String) -> Variant:
    return _get_typed_definition(enemy_id, "enemy")


func get_enemy_definitions() -> Array:
    return _get_definitions_by_type("enemy")


func get_skill(skill_id: String) -> Variant:
    return _get_typed_definition(skill_id, "skill")


func get_skill_definitions() -> Array:
    return _get_definitions_by_type("skill")


func get_combat(combat_id: String) -> Variant:
    return _get_typed_definition(combat_id, "combat")


func get_combat_definitions() -> Array:
    return _get_definitions_by_type("combat")


func get_combat_runtime_registry() -> Dictionary:
    var document: Variant = loaded_files.get("combats/combats.json", {})
    if not document is Dictionary or not document.get("runtime") is Dictionary:
        return {}
    return document["runtime"].duplicate(true)


func get_story(story_id: String) -> Variant:
    if get_type_for_id(story_id) != "quest":
        return null
    var story: Variant = get_by_id(story_id)
    if story is Dictionary:
        return story.duplicate(true)
    return null


func get_quest_definitions() -> Array:
    var definitions: Array = []
    for global_id: Variant in global_index.keys():
        var indexed: Dictionary = global_index[global_id]
        if str(indexed.get("type", "")) != "quest":
            continue
        var data: Variant = indexed.get("data")
        if data is Dictionary:
            definitions.append(data.duplicate(true))
    return definitions


func get_quest_dependencies() -> Dictionary:
    var dependencies: Variant = loaded_files.get("quest_dependencies.json", {})
    return dependencies.duplicate(true) if dependencies is Dictionary else {}


func get_index_size() -> int:
    return global_index.size()


func _get_typed_definition(global_id: String, expected_type: String) -> Variant:
    if get_type_for_id(global_id) != expected_type:
        return null
    var definition: Variant = get_by_id(global_id)
    if definition is Dictionary:
        return definition.duplicate(true)
    return null


func _get_definitions_by_type(expected_type: String) -> Array:
    var definitions: Array = []
    for global_id: Variant in global_index.keys():
        var indexed: Dictionary = global_index[global_id]
        if str(indexed.get("type", "")) != expected_type:
            continue
        var data: Variant = indexed.get("data")
        if data is Dictionary:
            definitions.append(data.duplicate(true))
    return definitions


func _load_declared_files() -> bool:
    var listed_files: Array = manifest.get("content_files", [])
    var forbidden_fragments: Array = manifest.get("forbidden_path_fragments", [])
    var seen_paths := {}

    for raw_path: Variant in listed_files:
        var relative_path := str(raw_path).replace("\\", "/")
        if not _is_safe_relative_path(relative_path):
            return _set_error("MANIFEST_PATH_INVALID", "Manifest path must stay inside the content root", relative_path)
        if seen_paths.has(relative_path):
            return _set_error("MANIFEST_DUPLICATE_FILE", "Manifest lists the same content file twice", relative_path)
        seen_paths[relative_path] = true
        for fragment: Variant in forbidden_fragments:
            if relative_path.to_lower().contains(str(fragment).replace("\\", "/").to_lower()):
                return _set_error("MANIFEST_FORBIDDEN_PATH", "Manifest references a forbidden path", relative_path)

        var schema_path := _schema_path_for(relative_path)
        if schema_path.is_empty():
            return _set_error("CONTENT_SCHEMA_MISSING", "No runtime schema is registered for manifest entry", relative_path)

        var full_path := _join_content_path(relative_path)
        if not FileAccess.file_exists(full_path):
            return _set_error("CONTENT_FILE_MISSING", "Manifest references a missing content file", relative_path)
        var document: Variant = _parse_json_file(full_path, "CONTENT_FILE_MISSING", "CONTENT_JSON_INVALID")
        if document == null:
            if not last_error.has("path") or str(last_error.get("path", "")).is_empty():
                last_error["path"] = relative_path
            return false
        if not _validate_document(document, schema_path, relative_path):
            return false
        if not _validate_schema_version(document, relative_path):
            return false
        loaded_files[relative_path] = document
    return true


func _build_indexes() -> bool:
    for source_path: Variant in loaded_files.keys():
        var document: Dictionary = loaded_files[source_path]
        if document.has("quest_id"):
            if not _add_global_id(document["quest_id"], "quest", document, str(source_path)):
                return false

        for collection_name: String in COLLECTION_IDS:
            if not document.has(collection_name):
                continue
            var id_config: Array = COLLECTION_IDS[collection_name]
            for entry: Variant in document[collection_name]:
                if not _add_global_id(entry[id_config[0]], id_config[1], entry, str(source_path)):
                    return false

        if document.has("states"):
            for state: Variant in document["states"]:
                var state_key := str(state["key"])
                if state_index.has(state_key):
                    return _set_error("DUPLICATE_STATE_KEY", "Duplicate state key '%s'" % state_key, str(source_path))
                state_index[state_key] = state
    return true


func _add_global_id(raw_id: Variant, kind: String, data: Dictionary, source_path: String) -> bool:
    var global_id := str(raw_id)
    if global_index.has(global_id):
        var first_source := str(global_index[global_id]["source"])
        return _set_error(
            "DUPLICATE_CONTENT_ID",
            "Duplicate global ID '%s' in %s and %s" % [global_id, first_source, source_path],
            source_path,
        )
    global_index[global_id] = {"type": kind, "data": data, "source": source_path}
    return true


func _validate_references() -> bool:
    var background_ids := _presentation_id_set("background_ids")
    var music_ids := _presentation_id_set("music_ids")
    var combat_status_ids := _combat_status_id_set()
    var inventory_ownership_keys := {}
    for raw_indexed: Variant in global_index.values():
        var indexed_item: Dictionary = raw_indexed
        if str(indexed_item.get("type", "")) != "item":
            continue
        var item_data: Dictionary = indexed_item["data"]
        var item_runtime: Variant = item_data.get("runtime")
        if not item_runtime is Dictionary:
            continue
        var ownership_key := str(item_runtime.get("ownership_state_key", ""))
        if ownership_key.is_empty():
            continue
        if inventory_ownership_keys.has(ownership_key):
            return _set_error(
                "INVALID_CONTENT_REFERENCE",
                "Inventory ownership state key '%s' is assigned to multiple items" % ownership_key,
                str(indexed_item.get("source", "")),
            )
        inventory_ownership_keys[ownership_key] = item_data.get("item_id", "")

    for indexed: Variant in global_index.values():
        var kind := str(indexed["type"])
        var data: Dictionary = indexed["data"]
        var source := str(indexed["source"])
        match kind:
            "npc":
                var portrait_set: Dictionary = data["portrait_set"]
                if not portrait_set["expressions"].has(portrait_set["default_expression"]):
                    return _set_error("INVALID_CONTENT_REFERENCE", "NPC default expression is not declared", source)
            "location":
                for target: Variant in data["connections"]:
                    if not _require_global_reference(str(target), "location", source, "location connection"):
                        return false
                if not background_ids.has(data["background_id"]):
                    return _set_error("INVALID_CONTENT_REFERENCE", "Unknown background ID '%s'" % data["background_id"], source)
                if not music_ids.has(data["music_id"]):
                    return _set_error("INVALID_CONTENT_REFERENCE", "Unknown music ID '%s'" % data["music_id"], source)
                if not _validate_state_references(data["unlock_conditions"], source):
                    return false
            "enemy":
                for skill_id: Variant in data["skill_ids"]:
                    if not _require_global_reference(str(skill_id), "skill", source, "enemy skill"):
                        return false
                if data.get("runtime") is Dictionary and not _validate_enemy_runtime_references(
                    data,
                    data["runtime"],
                    combat_status_ids,
                    source,
                ):
                    return false
            "skill":
                if data.get("runtime") is Dictionary and not _validate_combat_effect_references(
                    data.get("effects", []),
                    combat_status_ids,
                    source,
                ):
                    return false
            "combat":
                if not _require_global_reference(str(data["location_id"]), "location", source, "combat location"):
                    return false
                for enemy_id: Variant in data["enemy_ids"]:
                    if not _require_global_reference(str(enemy_id), "enemy", source, "combat enemy"):
                        return false
                for ally_id: Variant in data["ally_ids"]:
                    if not _require_global_reference(str(ally_id), "npc", source, "combat ally"):
                        return false
                if data.get("runtime") is Dictionary and not _validate_combat_runtime_references(
                    data,
                    data["runtime"],
                    combat_status_ids,
                    source,
                ):
                    return false
            "item":
                var runtime: Variant = data.get("runtime")
                if runtime is Dictionary:
                    var ownership_state_key := str(runtime.get("ownership_state_key", ""))
                    if not ownership_state_key.is_empty() and not state_index.has(ownership_state_key):
                        return _set_error(
                            "INVALID_CONTENT_REFERENCE",
                            "Unknown inventory ownership state key '%s'" % ownership_state_key,
                            source,
                        )
                    if (
                        not ownership_state_key.is_empty()
                        and str(state_index[ownership_state_key].get("type", "")) != "boolean"
                    ):
                        return _set_error(
                            "INVALID_CONTENT_REFERENCE",
                            "Inventory ownership state key '%s' must be boolean" % ownership_state_key,
                            source,
                        )
                    if (
                        not ownership_state_key.is_empty()
                        and not _inventory_state_write_allowed(ownership_state_key, source)
                    ):
                        return false
                    if not _validate_state_references(runtime.get("use_effects", []), source):
                        return false
                    if not _validate_combat_effect_references(
                        runtime.get("combat_effects", []),
                        combat_status_ids,
                        source,
                    ):
                        return false
                    for raw_effect: Variant in runtime.get("use_effects", []):
                        var effect_key := str(raw_effect.get("key", ""))
                        if not _inventory_state_write_allowed(effect_key, source):
                            return false
                        if inventory_ownership_keys.has(effect_key):
                            return _set_error(
                                "INVALID_CONTENT_REFERENCE",
                                "Item use effect cannot modify inventory ownership state '%s'" % effect_key,
                                source,
                            )
            "quest":
                if not _validate_quest_references(data, source):
                    return false
                for excluded_quest: Variant in data.get("mutual_exclusions", []):
                    if not _require_global_reference(str(excluded_quest), "quest", source, "mutually exclusive quest"):
                        return false

    var dependencies: Variant = loaded_files.get("quest_dependencies.json")
    if dependencies is Dictionary:
        var dependency_owners := {}
        for dependency: Variant in dependencies["quests"]:
            var owner_id := str(dependency["quest_id"])
            if dependency_owners.has(owner_id):
                return _set_error("QUEST_DEPENDENCY_DUPLICATE", "Quest dependency owner '%s' is declared more than once" % owner_id, "quest_dependencies.json")
            dependency_owners[owner_id] = true
            if not _require_global_reference(owner_id, "quest", "quest_dependencies.json", "quest dependency owner"):
                return false
            var seen_dependencies := {}
            for required_quest: Variant in dependency["depends_on"]:
                var required_id := str(required_quest)
                if seen_dependencies.has(required_id):
                    return _set_error("QUEST_DEPENDENCY_DUPLICATE", "Quest '%s' repeats dependency '%s'" % [owner_id, required_id], "quest_dependencies.json")
                seen_dependencies[required_id] = true
                if not _require_global_reference(required_id, "quest", "quest_dependencies.json", "quest dependency"):
                    return false
        if not _validate_quest_dependency_cycles(dependencies["quests"]):
            return false
    return true


func _combat_status_id_set() -> Dictionary:
    var result := {}
    var registry_document: Variant = loaded_files.get("combats/combats.json", {})
    if not registry_document is Dictionary:
        return result
    var runtime: Variant = registry_document.get("runtime")
    if not runtime is Dictionary:
        return result
    for raw_status: Variant in runtime.get("status_definitions", []):
        if raw_status is Dictionary:
            result[str(raw_status.get("status_id", ""))] = true
    return result


func _validate_combat_effect_references(
    raw_effects: Variant,
    combat_status_ids: Dictionary,
    source: String,
) -> bool:
    if not raw_effects is Array:
        return _set_error("CONTENT_SCHEMA_INVALID", "Combat effects must be an array", source)
    for raw_effect: Variant in raw_effects:
        if not raw_effect is Dictionary:
            return _set_error("CONTENT_SCHEMA_INVALID", "Combat effect must be an object", source)
        var effect_type := str(raw_effect.get("effect", raw_effect.get("type", "")))
        if effect_type in ["apply_status", "remove_status"]:
            var status_id := str(raw_effect.get("status_id", ""))
            if not combat_status_ids.has(status_id):
                return _set_error(
                    "INVALID_CONTENT_REFERENCE",
                    "Combat effect references unknown status '%s'" % status_id,
                    source,
                )
        if effect_type == "state_effect":
            var state_effects: Array = []
            if raw_effect.get("effects") is Array:
                state_effects = raw_effect["effects"]
            elif raw_effect.has("key") and raw_effect.has("op") and raw_effect.has("value"):
                state_effects = [raw_effect]
            if state_effects.is_empty():
                return _set_error("CONTENT_SCHEMA_INVALID", "Combat state effect has no operations", source)
            if not _validate_state_references(state_effects, source):
                return false
    return true


func _validate_enemy_runtime_references(
    enemy: Dictionary,
    runtime: Dictionary,
    combat_status_ids: Dictionary,
    source: String,
) -> bool:
    var equipped_skills := {}
    for raw_skill_id: Variant in enemy.get("skill_ids", []):
        equipped_skills[str(raw_skill_id)] = true
    for raw_action: Variant in runtime.get("ai_actions", []):
        if not raw_action is Dictionary:
            return _set_error("CONTENT_SCHEMA_INVALID", "Enemy AI action must be an object", source)
        var action: Dictionary = raw_action
        if str(action.get("action_type", "")) == "skill":
            var skill_id := str(action.get("skill_id", ""))
            if not equipped_skills.has(skill_id):
                return _set_error(
                    "INVALID_CONTENT_REFERENCE",
                    "Enemy AI action references unequipped skill '%s'" % skill_id,
                    source,
                )
            if not _require_global_reference(skill_id, "skill", source, "enemy AI skill"):
                return false
        for raw_condition: Variant in action.get("conditions", []):
            if raw_condition is Dictionary and raw_condition.has("status_id"):
                var status_id := str(raw_condition.get("status_id", ""))
                if not combat_status_ids.has(status_id):
                    return _set_error(
                        "INVALID_CONTENT_REFERENCE",
                        "Enemy AI condition references unknown status '%s'" % status_id,
                        source,
                    )
    for raw_status_id: Variant in runtime.get("status_immunities", []):
        var status_id := str(raw_status_id)
        if not combat_status_ids.has(status_id):
            return _set_error(
                "INVALID_CONTENT_REFERENCE",
                "Enemy immunity references unknown status '%s'" % status_id,
                source,
            )
    return true


func _validate_combat_runtime_references(
    combat: Dictionary,
    runtime: Dictionary,
    combat_status_ids: Dictionary,
    source: String,
) -> bool:
    var unit_ids := {}
    var units: Array = []
    if runtime.get("player_unit") is Dictionary:
        units.append(runtime["player_unit"])
    units.append_array(runtime.get("companion_units", []))
    units.append_array(runtime.get("enemy_instances", []))
    for raw_unit: Variant in units:
        if not raw_unit is Dictionary:
            return _set_error("CONTENT_SCHEMA_INVALID", "Combat runtime unit must be an object", source)
        var unit_id := str(raw_unit.get("unit_id", ""))
        if unit_id.is_empty() or unit_ids.has(unit_id):
            return _set_error("INVALID_CONTENT_REFERENCE", "Combat runtime unit IDs must be non-empty and unique", source)
        unit_ids[unit_id] = true
        if raw_unit.has("enemy_id") and not _require_global_reference(
            str(raw_unit.get("enemy_id", "")),
            "enemy",
            source,
            "combat runtime enemy",
        ):
            return false
        var equipped_skills := {}
        for raw_skill_id: Variant in raw_unit.get("skill_ids", []):
            var skill_id := str(raw_skill_id)
            if not _require_global_reference(skill_id, "skill", source, "combat runtime unit skill"):
                return false
            equipped_skills[skill_id] = true
        for raw_action: Variant in raw_unit.get("ai_actions", []):
            if raw_action is Dictionary and str(raw_action.get("action_type", "")) == "skill":
                var skill_id := str(raw_action.get("skill_id", ""))
                if not equipped_skills.has(skill_id):
                    return _set_error(
                        "INVALID_CONTENT_REFERENCE",
                        "Companion AI action references unequipped skill '%s'" % skill_id,
                        source,
                    )
                if not _require_global_reference(skill_id, "skill", source, "companion AI skill"):
                    return false
    for raw_rule: Variant in runtime.get("inspect_rules", []):
        if raw_rule is Dictionary:
            var target_id := str(raw_rule.get("target_unit_id", ""))
            if not target_id.is_empty() and not unit_ids.has(target_id):
                return _set_error(
                    "INVALID_CONTENT_REFERENCE",
                    "Inspect rule references unknown unit '%s'" % target_id,
                    source,
                )
    var phase_ids := {}
    for raw_phase: Variant in runtime.get("phases", []):
        if not raw_phase is Dictionary:
            return _set_error("CONTENT_SCHEMA_INVALID", "Combat runtime phase must be an object", source)
        var phase_id := str(raw_phase.get("phase_id", ""))
        if phase_id.is_empty() or phase_ids.has(phase_id):
            return _set_error("INVALID_CONTENT_REFERENCE", "Combat runtime phase IDs must be non-empty and unique", source)
        phase_ids[phase_id] = true
        var target_unit_id := str(raw_phase.get("target_unit_id", raw_phase.get("unit_id", "")))
        if not target_unit_id.is_empty() and not unit_ids.has(target_unit_id):
            return _set_error(
                "INVALID_CONTENT_REFERENCE",
                "Combat phase references unknown unit '%s'" % target_unit_id,
                source,
            )
        for raw_skill_id: Variant in raw_phase.get("skill_ids", []):
            if not _require_global_reference(str(raw_skill_id), "skill", source, "combat phase skill"):
                return false
        var trigger: Variant = raw_phase.get("trigger")
        if trigger is Dictionary and trigger.has("status_id"):
            var status_id := str(trigger.get("status_id", ""))
            if not combat_status_ids.has(status_id):
                return _set_error(
                    "INVALID_CONTENT_REFERENCE",
                    "Combat phase references unknown status '%s'" % status_id,
                    source,
                )
    return true


func _validate_quest_references(quest: Dictionary, source: String) -> bool:
    if not _require_global_reference(str(quest["trigger"]["location_id"]), "location", source, "quest trigger location"):
        return false
    if not _validate_state_references(quest["prerequisites"], source):
        return false
    if not _validate_state_references(quest["trigger"]["conditions"], source):
        return false

    var node_ids := {}
    for node: Variant in quest["nodes"]:
        node_ids[node["node_id"]] = true
    if not node_ids.has(quest["entry_node"]):
        return _set_error("INVALID_CONTENT_REFERENCE", "Quest entry node does not exist", source)

    for node: Variant in quest["nodes"]:
        if not _require_global_reference(str(node["location_id"]), "location", source, "quest node location"):
            return false
        if node.has("speaker_id") and not _require_global_reference(str(node["speaker_id"]), "npc", source, "quest speaker"):
            return false
        if node.has("combat_ref") and not _require_global_reference(str(node["combat_ref"]), "combat", source, "quest combat"):
            return false
        for item_id: Variant in node.get("reward_item_ids", []):
            if not _require_global_reference(str(item_id), "item", source, "quest reward"):
                return false
        if not _validate_state_references(node.get("conditions", []), source):
            return false
        if not _validate_state_references(node.get("effects", []), source):
            return false
        for next_field: String in ["next", "next_on_win", "next_on_loss"]:
            if node.has(next_field) and not node_ids.has(node[next_field]):
                return _set_error("INVALID_CONTENT_REFERENCE", "Quest node references missing node '%s'" % node[next_field], source)
        for choice: Variant in node.get("choices", []):
            if not node_ids.has(choice["goto"]):
                return _set_error("INVALID_CONTENT_REFERENCE", "Quest choice references missing node '%s'" % choice["goto"], source)
            if not _validate_state_references(choice.get("conditions", []), source):
                return false
            if not _validate_state_references(choice.get("effects", []), source):
                return false
    for raw_reward: Variant in quest.get("rewards", []):
        if not raw_reward is Dictionary:
            continue
        var reward: Dictionary = raw_reward
        if str(reward.get("type", "")) != "items":
            continue
        for raw_grant: Variant in reward.get("items", []):
            if not raw_grant is Dictionary:
                continue
            if not _require_global_reference(str(raw_grant.get("item_id", "")), "item", source, "quest item reward"):
                return false
    if quest.has("runtime") and not _validate_quest_runtime_references(quest["runtime"], source):
        return false
    return true


func _validate_quest_runtime_references(runtime: Dictionary, source: String) -> bool:
    for state_key_field: String in ["status_state_key", "reward_granted_state_key"]:
        var state_key := str(runtime.get(state_key_field, ""))
        if not state_index.has(state_key):
            return _set_error("INVALID_CONTENT_REFERENCE", "Unknown QuestManager state key '%s'" % state_key, source)
    var failure: Dictionary = runtime.get("failure", {})
    var continuation_key := str(failure.get("continuation_state_key", ""))
    if not state_index.has(continuation_key):
        return _set_error("INVALID_CONTENT_REFERENCE", "Unknown QuestManager continuation state key '%s'" % continuation_key, source)
    var availability: Dictionary = runtime.get("availability", {})
    for group_name: String in ["all", "any"]:
        for raw_condition: Variant in availability.get(group_name, []):
            if not raw_condition is Dictionary:
                return _set_error("CONTENT_SCHEMA_INVALID", "QuestManager availability condition must be an object", source)
            var condition: Dictionary = raw_condition
            if str(condition.get("kind", "")) == "state":
                var key := str(condition.get("key", ""))
                if not state_index.has(key):
                    return _set_error("INVALID_CONTENT_REFERENCE", "Unknown QuestManager condition state key '%s'" % key, source)
            elif str(condition.get("kind", "")) == "quest":
                if not _require_global_reference(str(condition.get("quest_id", "")), "quest", source, "QuestManager prerequisite"):
                    return false
    for raw_objective: Variant in runtime.get("objectives", []):
        if not raw_objective is Dictionary:
            return _set_error("CONTENT_SCHEMA_INVALID", "QuestManager objective must be an object", source)
        var objective: Dictionary = raw_objective
        if str(objective.get("type", "")) == "state_condition":
            var condition: Dictionary = objective.get("condition", {})
            var condition_key := str(condition.get("key", ""))
            if not state_index.has(condition_key):
                return _set_error("INVALID_CONTENT_REFERENCE", "Unknown objective condition state key '%s'" % condition_key, source)
        else:
            var progress_key := str(objective.get("progress_state_key", ""))
            if not state_index.has(progress_key):
                return _set_error("INVALID_CONTENT_REFERENCE", "Unknown objective progress state key '%s'" % progress_key, source)
    return true


func _validate_quest_dependency_cycles(raw_dependencies: Array) -> bool:
    var graph := {}
    for global_id: Variant in global_index.keys():
        if str(global_index[global_id].get("type", "")) == "quest":
            graph[str(global_id)] = []
    for raw_dependency: Variant in raw_dependencies:
        var dependency: Dictionary = raw_dependency
        var owner_id := str(dependency.get("quest_id", ""))
        var edges: Array = []
        for raw_required: Variant in dependency.get("depends_on", []):
            var required_id := str(raw_required)
            if owner_id == required_id:
                return _set_error("QUEST_DEPENDENCY_CYCLE", "Quest '%s' depends on itself" % owner_id, "quest_dependencies.json")
            edges.append(required_id)
        graph[owner_id] = edges

    var indegree := {}
    for node_id: Variant in graph.keys():
        indegree[str(node_id)] = 0
    for node_id: Variant in graph.keys():
        for target: Variant in graph[node_id]:
            indegree[str(target)] = int(indegree.get(str(target), 0)) + 1
    var queue: Array[String] = []
    for node_id: Variant in indegree.keys():
        if int(indegree[node_id]) == 0:
            queue.append(str(node_id))
    var visited := 0
    while not queue.is_empty():
        var node_id: String = queue.pop_front()
        visited += 1
        for target: Variant in graph.get(node_id, []):
            var target_id := str(target)
            indegree[target_id] = int(indegree[target_id]) - 1
            if int(indegree[target_id]) == 0:
                queue.append(target_id)
    if visited != indegree.size():
        return _set_error("QUEST_DEPENDENCY_CYCLE", "Quest dependency graph contains a cycle", "quest_dependencies.json")
    return true


func _validate_state_references(operations: Array, source: String) -> bool:
    for operation: Variant in operations:
        var state_key := str(operation["key"])
        if not state_index.has(state_key):
            return _set_error("INVALID_CONTENT_REFERENCE", "Unknown state key '%s'" % state_key, source)
    return true


func _inventory_state_write_allowed(state_key: String, source: String) -> bool:
    if not state_index.has(state_key):
        return false
    var definition: Dictionary = state_index[state_key]
    var write_sources: Variant = definition.get("write_sources", [])
    if bool(definition.get("read_only", false)):
        return _set_error(
            "INVALID_CONTENT_REFERENCE",
            "Inventory state key '%s' is read-only" % state_key,
            source,
        )
    if not write_sources is Array or (not write_sources.is_empty() and "inventory" not in write_sources):
        return _set_error(
            "INVALID_CONTENT_REFERENCE",
            "Inventory state key '%s' does not allow inventory writes" % state_key,
            source,
        )
    return true


func _require_global_reference(global_id: String, expected_type: String, source: String, label: String) -> bool:
    if not global_index.has(global_id):
        return _set_error("INVALID_CONTENT_REFERENCE", "Unknown %s ID '%s'" % [label, global_id], source)
    if global_index[global_id]["type"] != expected_type:
        return _set_error("INVALID_CONTENT_REFERENCE", "%s '%s' has the wrong content type" % [label, global_id], source)
    return true


func _presentation_id_set(field_name: String) -> Dictionary:
    var result := {}
    var tags: Variant = loaded_files.get("presentation_tags.json")
    if tags is Dictionary:
        for value: Variant in tags.get(field_name, []):
            result[value] = true
    return result


func _validate_document(document: Variant, schema_path: String, source_path: String) -> bool:
    if not document is Dictionary:
        return _set_error("CONTENT_SCHEMA_INVALID", "Top-level JSON value must be an object", source_path)
    var schema: Variant = _parse_json_file(schema_path, "CONTENT_SCHEMA_MISSING", "CONTENT_SCHEMA_INVALID")
    if schema == null:
        last_error["path"] = source_path
        return false
    var errors: Array[String] = _schema_validator.validate(document, schema)
    if not errors.is_empty():
        return _set_error("CONTENT_SCHEMA_INVALID", errors[0], source_path, errors)
    return true


func _validate_schema_version(document: Dictionary, source_path: String) -> bool:
    var version := str(document.get("schema_version", ""))
    var parts := version.split(".")
    if parts.size() != 3 or not parts[0].is_valid_int():
        return _set_error("CONTENT_SCHEMA_VERSION_UNSUPPORTED", "Invalid schema_version '%s'" % version, source_path)
    if int(parts[0]) != SUPPORTED_SCHEMA_MAJOR:
        return _set_error("CONTENT_SCHEMA_VERSION_UNSUPPORTED", "Unsupported schema major version '%s'" % version, source_path)
    return true


func _schema_path_for(relative_path: String) -> String:
    if SCHEMA_FILES.has(relative_path):
        return "res://schemas/%s" % SCHEMA_FILES[relative_path]
    if relative_path.begins_with("quests/") and relative_path.ends_with(".json"):
        return "res://schemas/quest.schema.json"
    return ""


func _parse_json_file(path: String, missing_code: String, invalid_code: String) -> Variant:
    if not FileAccess.file_exists(path):
        _set_error(missing_code, "JSON file does not exist", path)
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _set_error(missing_code, "JSON file could not be opened (error %d)" % FileAccess.get_open_error(), path)
        return null
    var parser := JSON.new()
    var parse_result := parser.parse(file.get_as_text())
    if parse_result != OK:
        _set_error(invalid_code, "JSON parse error at line %d: %s" % [parser.get_error_line(), parser.get_error_message()], path)
        return null
    return parser.data


func _is_safe_relative_path(relative_path: String) -> bool:
    if relative_path.is_empty() or relative_path.begins_with("/") or relative_path.contains(":"):
        return false
    for part: String in relative_path.split("/"):
        if part == ".." or part == "." or part.is_empty():
            return false
    return true


func _join_content_path(relative_path: String) -> String:
    return "%s/%s" % [content_root, relative_path]


func _set_error(code: String, message: String, path: String = "", details: Array[String] = []) -> bool:
    last_error = {"code": code, "message": message, "path": path, "details": details}
    return false


func _finish_failure() -> bool:
    loaded_files.clear()
    global_index.clear()
    state_index.clear()
    content_error.emit(last_error)
    return false


func _reset() -> void:
    manifest = {}
    loaded_files.clear()
    global_index.clear()
    state_index.clear()
    last_error = {}
