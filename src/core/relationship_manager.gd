extends RefCounted

signal relationship_changed(result: Dictionary)
signal stage_changed(relationship_id: String, previous_stage: String, current_stage: String, source: String)
signal flag_changed(relationship_id: String, flag_id: String, old_value: bool, new_value: bool, source: String)
signal boundary_changed(relationship_id: String, boundary_id: String, old_value: bool, new_value: bool, source: String)
signal conflict_changed(result: Dictionary)
signal relationship_error(error: Dictionary)

const DIMENSION_EFFECTS := ["set", "inc", "dec", "clamp"]
const CONDITION_KINDS := ["dimension", "flag", "boundary", "conflict", "stage", "state"]

const RELATIONSHIP_NOT_INITIALIZED := "RELATIONSHIP_NOT_INITIALIZED"
const RELATIONSHIP_NOT_FOUND := "RELATIONSHIP_NOT_FOUND"
const RELATIONSHIP_DEFINITION_INVALID := "RELATIONSHIP_DEFINITION_INVALID"
const RELATIONSHIP_DIMENSION_NOT_FOUND := "RELATIONSHIP_DIMENSION_NOT_FOUND"
const RELATIONSHIP_EFFECT_INVALID := "RELATIONSHIP_EFFECT_INVALID"
const RELATIONSHIP_VALUE_OUT_OF_BOUNDS := "RELATIONSHIP_VALUE_OUT_OF_BOUNDS"
const RELATIONSHIP_STATE_WRITE_FAILED := "RELATIONSHIP_STATE_WRITE_FAILED"
const RELATIONSHIP_FLAG_NOT_FOUND := "RELATIONSHIP_FLAG_NOT_FOUND"
const RELATIONSHIP_BOUNDARY_NOT_FOUND := "RELATIONSHIP_BOUNDARY_NOT_FOUND"
const RELATIONSHIP_ACTION_NOT_FOUND := "RELATIONSHIP_ACTION_NOT_FOUND"
const RELATIONSHIP_ACTION_BLOCKED := "RELATIONSHIP_ACTION_BLOCKED"
const RELATIONSHIP_CONDITION_INVALID := "RELATIONSHIP_CONDITION_INVALID"
const RELATIONSHIP_CONFLICT_INVALID := "RELATIONSHIP_CONFLICT_INVALID"

var last_error: Dictionary = {}

var _content_loader: RefCounted
var _game_state: RefCounted
var _dimensions: Dictionary = {}
var _stages: Dictionary = {}
var _relationships: Dictionary = {}
var _flag_keys: Dictionary = {}
var _boundary_keys: Dictionary = {}
var _initialized := false


func initialize(content_loader: RefCounted, game_state: RefCounted) -> bool:
    _clear_runtime()
    if content_loader == null or game_state == null:
        return _initialize_fail("RelationshipManager requires ContentLoader and GameState")
    if not content_loader.has_method("get_relationship_registry"):
        return _initialize_fail("ContentLoader does not expose the relationship registry")
    if not game_state.has_method("has_state") or not game_state.has_method("apply_effects"):
        return _initialize_fail("GameState does not expose the required state interface")
    _content_loader = content_loader
    _game_state = game_state
    var registry: Variant = content_loader.call("get_relationship_registry")
    if not registry is Dictionary:
        return _initialize_fail("Relationship registry must be an object")
    for raw_dimension: Variant in registry.get("dimension_definitions", []):
        if not raw_dimension is Dictionary:
            return _initialize_fail("Relationship dimension definition must be an object")
        var dimension_id := str(raw_dimension.get("dimension_id", ""))
        if dimension_id.is_empty() or _dimensions.has(dimension_id):
            return _initialize_fail("Relationship dimension IDs must be non-empty and unique")
        if not _is_number(raw_dimension.get("default")) or not _is_number(raw_dimension.get("min")) or not _is_number(raw_dimension.get("max")):
            return _initialize_fail("Relationship dimension bounds must be numeric")
        if raw_dimension["min"] > raw_dimension["max"] or raw_dimension["default"] < raw_dimension["min"] or raw_dimension["default"] > raw_dimension["max"]:
            return _initialize_fail("Relationship dimension bounds or default are invalid")
        _dimensions[dimension_id] = raw_dimension.duplicate(true)
    for required_dimension: String in ["trust", "affection", "respect", "tension"]:
        if not _dimensions.has(required_dimension) and not registry.get("relationships", []).is_empty():
            return _initialize_fail("Required relationship dimension '%s' is missing" % required_dimension)
    for raw_stage: Variant in registry.get("stage_definitions", []):
        if not raw_stage is Dictionary:
            return _initialize_fail("Relationship stage definition must be an object")
        var stage_id := str(raw_stage.get("stage_id", ""))
        if stage_id.is_empty() or _stages.has(stage_id):
            return _initialize_fail("Relationship stage IDs must be non-empty and unique")
        _stages[stage_id] = raw_stage.duplicate(true)
    for required_stage: String in ["stranger", "acquaintance", "trusted", "close", "intimate"]:
        if not _stages.has(required_stage) and not registry.get("relationships", []).is_empty():
            return _initialize_fail("Required relationship stage '%s' is missing" % required_stage)
    for raw_relationship: Variant in registry.get("relationships", []):
        if not raw_relationship is Dictionary:
            return _initialize_fail("Relationship definition must be an object")
        var definition: Dictionary = raw_relationship.duplicate(true)
        var relationship_id := str(definition.get("relationship_id", ""))
        if relationship_id.is_empty() or _relationships.has(relationship_id):
            return _initialize_fail("Relationship IDs must be non-empty and unique", relationship_id)
        _relationships[relationship_id] = definition
        if not _validate_relationship_definition(relationship_id):
            return false
    _initialized = true
    last_error = {}
    return true


func is_initialized() -> bool:
    return _initialized


func has_relationship(relationship_id: String) -> bool:
    return _relationships.has(relationship_id)


func list_relationships() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    var values: Array = []
    for relationship_id: Variant in _relationships.keys():
        values.append(get_relationship_state(str(relationship_id))["relationship"])
    return _result(true, "OK", "Relationships listed", "", {"relationships": values})


func get_relationship_state(relationship_id: String) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var definition: Dictionary = _relationships[relationship_id]
    var dimensions := {}
    for dimension_id: Variant in definition["dimensions"].keys():
        dimensions[str(dimension_id)] = _game_state.call("get_state", definition["dimensions"][dimension_id])
    var flags := {}
    for flag_id: Variant in _flag_keys[relationship_id].keys():
        flags[str(flag_id)] = _game_state.call("get_state", _flag_keys[relationship_id][flag_id])
    var boundaries := {}
    for boundary_id: Variant in _boundary_keys[relationship_id].keys():
        boundaries[str(boundary_id)] = _game_state.call("get_state", _boundary_keys[relationship_id][boundary_id])
    var conflict_definition: Dictionary = definition["conflict"]
    return _result(true, "OK", "Relationship state returned", relationship_id, {
        "relationship": {
            "relationship_id": relationship_id,
            "actor_id": definition["actor_id"],
            "target_id": definition["target_id"],
            "dimensions": dimensions,
            "stage": _game_state.call("get_state", definition["stage_state_key"]),
            "flags": flags,
            "boundaries": boundaries,
            "conflict": {
                "active": _game_state.call("get_state", conflict_definition["active_state_key"]),
                "reason": _game_state.call("get_state", conflict_definition["reason_state_key"]),
                "repair_progress": _game_state.call("get_state", conflict_definition["repair_progress_state_key"]),
                "repair_threshold": conflict_definition["repair_threshold"],
            },
            "metadata": definition.get("metadata", {}).duplicate(true),
        },
    })


func get_dimension(relationship_id: String, dimension_id: String) -> Dictionary:
    if not _require_dimension(relationship_id, dimension_id):
        return last_error.duplicate(true)
    var key: String = _relationships[relationship_id]["dimensions"][dimension_id]
    return _result(true, "OK", "Relationship dimension returned", relationship_id, {
        "dimension_id": dimension_id,
        "value": _game_state.call("get_state", key),
        "definition": _dimensions[dimension_id].duplicate(true),
    })


func get_stage(relationship_id: String) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship stage returned", relationship_id, {
        "stage": str(_game_state.call("get_state", _relationships[relationship_id]["stage_state_key"])),
    })


func apply_effect(relationship_id: String, effect: Dictionary, source: String = "system") -> Dictionary:
    return apply_effects(relationship_id, [effect], source)


func apply_effects(relationship_id: String, effects: Array, source: String = "system") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    if effects.is_empty():
        return _result(true, "OK", "No relationship effects to apply", relationship_id, {"changes": [], "changed": false})
    var definition: Dictionary = _relationships[relationship_id]
    var overlay := {}
    var changes_by_dimension := {}
    for raw_effect: Variant in effects:
        if not raw_effect is Dictionary:
            return _set_error(RELATIONSHIP_EFFECT_INVALID, "Relationship effect must be an object", relationship_id)
        var effect: Dictionary = raw_effect
        var dimension_id := str(effect.get("dimension_id", ""))
        if not _require_dimension(relationship_id, dimension_id):
            return last_error.duplicate(true)
        var operation := str(effect.get("op", ""))
        if operation not in DIMENSION_EFFECTS:
            return _set_error(RELATIONSHIP_EFFECT_INVALID, "Unknown relationship effect '%s'" % operation, relationship_id, {"dimension_id": dimension_id})
        var key: String = definition["dimensions"][dimension_id]
        var current: Variant = overlay.get(key, _game_state.call("get_state", key))
        var next: Variant = current
        var bounds: Dictionary = _dimensions[dimension_id]
        match operation:
            "set":
                if not _is_number(effect.get("value")):
                    return _set_error(RELATIONSHIP_EFFECT_INVALID, "Relationship set effect requires a numeric value", relationship_id, {"dimension_id": dimension_id})
                next = effect["value"]
                if next < bounds["min"] or next > bounds["max"]:
                    return _set_error(RELATIONSHIP_VALUE_OUT_OF_BOUNDS, "Relationship set value is outside the declared range", relationship_id, {"dimension_id": dimension_id})
            "inc", "dec":
                if not _is_number(effect.get("value")) or effect["value"] < 0:
                    return _set_error(RELATIONSHIP_EFFECT_INVALID, "Relationship increment/decrement requires a non-negative number", relationship_id, {"dimension_id": dimension_id})
                next = current + effect["value"] if operation == "inc" else current - effect["value"]
                next = clamp(next, bounds["min"], bounds["max"])
            "clamp":
                var minimum: Variant = effect.get("min", bounds["min"])
                var maximum: Variant = effect.get("max", bounds["max"])
                if not _is_number(minimum) or not _is_number(maximum) or minimum > maximum or minimum < bounds["min"] or maximum > bounds["max"]:
                    return _set_error(RELATIONSHIP_EFFECT_INVALID, "Relationship clamp bounds are invalid", relationship_id, {"dimension_id": dimension_id})
                next = clamp(current, minimum, maximum)
        if current is int and next is float and next == floor(next):
            next = int(next)
        overlay[key] = next
        if not changes_by_dimension.has(dimension_id):
            changes_by_dimension[dimension_id] = {"dimension_id": dimension_id, "old_value": _game_state.call("get_state", key)}
        changes_by_dimension[dimension_id]["new_value"] = next

    var previous_stage := str(_game_state.call("get_state", definition["stage_state_key"]))
    var current_stage := _select_stage(relationship_id, overlay)
    if current_stage.is_empty():
        return last_error.duplicate(true)
    overlay[definition["stage_state_key"]] = current_stage
    if not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    var changes: Array = []
    for dimension_id: Variant in changes_by_dimension.keys():
        var change: Dictionary = changes_by_dimension[dimension_id]
        change["delta"] = change["new_value"] - change["old_value"]
        change["source"] = source
        changes.append(change)
        if change["old_value"] != change["new_value"]:
            relationship_changed.emit(_result(true, "OK", "Relationship dimension changed", relationship_id, change))
    if previous_stage != current_stage:
        stage_changed.emit(relationship_id, previous_stage, current_stage, source)
    return _result(true, "OK", "Relationship effects applied", relationship_id, {
        "changes": changes,
        "changed": _has_actual_change(changes) or previous_stage != current_stage,
        "previous_stage": previous_stage,
        "current_stage": current_stage,
        "stage_changed": previous_stage != current_stage,
    })


func evaluate_condition(relationship_id: String, condition: Dictionary) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var evaluation := _condition_matches(relationship_id, condition, {})
    if evaluation < 0:
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship condition evaluated", relationship_id, {"matched": evaluation == 1})


func evaluate_conditions(relationship_id: String, conditions: Dictionary) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var evaluation := _condition_group_matches(relationship_id, conditions, {})
    if evaluation < 0:
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship condition group evaluated", relationship_id, {"matched": evaluation == 1})


func set_flag(relationship_id: String, flag_id: String, value: bool, source: String = "system") -> Dictionary:
    if not _require_flag(relationship_id, flag_id):
        return last_error.duplicate(true)
    var key: String = _flag_keys[relationship_id][flag_id]
    var old_value := bool(_game_state.call("get_state", key))
    var overlay := {}
    overlay[key] = value
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    if old_value != value:
        flag_changed.emit(relationship_id, flag_id, old_value, value, source)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return _result(true, "OK", "Relationship flag updated", relationship_id, {"flag_id": flag_id, "old_value": old_value, "new_value": value, "changed": old_value != value})


func get_flag(relationship_id: String, flag_id: String) -> Dictionary:
    if not _require_flag(relationship_id, flag_id):
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship flag returned", relationship_id, {"flag_id": flag_id, "value": _game_state.call("get_state", _flag_keys[relationship_id][flag_id])})


func set_boundary(relationship_id: String, boundary_id: String, value: bool, source: String = "system") -> Dictionary:
    if not _require_boundary(relationship_id, boundary_id):
        return last_error.duplicate(true)
    var key: String = _boundary_keys[relationship_id][boundary_id]
    var old_value := bool(_game_state.call("get_state", key))
    var overlay := {}
    overlay[key] = value
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    if old_value != value:
        boundary_changed.emit(relationship_id, boundary_id, old_value, value, source)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return _result(true, "OK", "Relationship boundary updated", relationship_id, {"boundary_id": boundary_id, "old_value": old_value, "new_value": value, "changed": old_value != value})


func get_boundary(relationship_id: String, boundary_id: String) -> Dictionary:
    if not _require_boundary(relationship_id, boundary_id):
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship boundary returned", relationship_id, {"boundary_id": boundary_id, "value": _game_state.call("get_state", _boundary_keys[relationship_id][boundary_id])})


func is_action_allowed(relationship_id: String, action_id: String) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    for raw_rule: Variant in _relationships[relationship_id].get("action_rules", []):
        var rule: Dictionary = raw_rule
        if str(rule.get("action_id", "")) != action_id:
            continue
        var evaluation := _condition_group_matches(relationship_id, rule["conditions"], {})
        if evaluation < 0:
            return last_error.duplicate(true)
        return _result(true, "OK", "Relationship action evaluated", relationship_id, {"action_id": action_id, "allowed": evaluation == 1})
    return _set_error(RELATIONSHIP_ACTION_NOT_FOUND, "Unknown relationship action '%s'" % action_id, relationship_id, {"action_id": action_id})


func reject_action(relationship_id: String, action_id: String, source: String = "story") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var rule := _rejection_rule(relationship_id, action_id)
    if rule.is_empty():
        return _set_error(RELATIONSHIP_ACTION_NOT_FOUND, "Relationship action has no rejection rule", relationship_id, {"action_id": action_id})
    var flag_id := str(rule["rejection_flag_id"])
    if not _require_flag(relationship_id, flag_id):
        return last_error.duplicate(true)
    if bool(_game_state.call("get_state", _flag_keys[relationship_id][flag_id])):
        return _result(true, "OK", "Relationship action was already rejected", relationship_id, {"action_id": action_id, "changed": false})
    var overlay := {}
    overlay[_flag_keys[relationship_id][flag_id]] = true
    var old_boundaries := {}
    for boundary_id: Variant in rule.get("boundary_updates", {}).keys():
        if not _require_boundary(relationship_id, str(boundary_id)):
            return last_error.duplicate(true)
        old_boundaries[str(boundary_id)] = _game_state.call("get_state", _boundary_keys[relationship_id][boundary_id])
        overlay[_boundary_keys[relationship_id][boundary_id]] = rule["boundary_updates"][boundary_id]
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    flag_changed.emit(relationship_id, flag_id, false, true, source)
    _emit_boundary_overlay_changes(relationship_id, old_boundaries, rule.get("boundary_updates", {}), source)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return _result(true, "OK", "Relationship action rejection recorded without dimension penalty", relationship_id, {"action_id": action_id, "changed": true, "reopen_action_id": rule["reopen_action_id"]})


func reopen_action(relationship_id: String, reopen_action_id: String, source: String = "story") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var rule := _reopen_rule(relationship_id, reopen_action_id)
    if rule.is_empty():
        return _set_error(RELATIONSHIP_ACTION_NOT_FOUND, "Unknown explicit relationship reopen action", relationship_id, {"action_id": reopen_action_id})
    var flag_id := str(rule["rejection_flag_id"])
    var old_flag := bool(_game_state.call("get_state", _flag_keys[relationship_id][flag_id]))
    var overlay := {}
    overlay[_flag_keys[relationship_id][flag_id]] = false
    var boundary_updates := {}
    var old_boundaries := {}
    for boundary_id: Variant in rule.get("boundary_updates", {}).keys():
        boundary_updates[str(boundary_id)] = not bool(rule["boundary_updates"][boundary_id])
        old_boundaries[str(boundary_id)] = _game_state.call("get_state", _boundary_keys[relationship_id][boundary_id])
        overlay[_boundary_keys[relationship_id][boundary_id]] = boundary_updates[str(boundary_id)]
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    if old_flag:
        flag_changed.emit(relationship_id, flag_id, true, false, source)
    _emit_boundary_overlay_changes(relationship_id, old_boundaries, boundary_updates, source)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return _result(true, "OK", "Relationship action explicitly reopened", relationship_id, {"action_id": reopen_action_id, "changed": old_flag})


func enter_conflict(relationship_id: String, reason: String, source: String = "story") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    if reason.strip_edges().is_empty():
        return _set_error(RELATIONSHIP_CONFLICT_INVALID, "Conflict reason cannot be empty", relationship_id)
    var conflict: Dictionary = _relationships[relationship_id]["conflict"]
    var old_active := bool(_game_state.call("get_state", conflict["active_state_key"]))
    var overlay := {}
    overlay[conflict["active_state_key"]] = true
    overlay[conflict["reason_state_key"]] = reason
    overlay[conflict["repair_progress_state_key"]] = 0
    if _boundary_keys[relationship_id].has("conflict_active"):
        overlay[_boundary_keys[relationship_id]["conflict_active"]] = true
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    var result := _result(true, "OK", "Relationship conflict entered", relationship_id, {"active": true, "reason": reason, "changed": not old_active})
    if not old_active:
        conflict_changed.emit(result)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return result


func get_conflict(relationship_id: String) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    return _result(true, "OK", "Relationship conflict returned", relationship_id, {"conflict": get_relationship_state(relationship_id)["relationship"]["conflict"]})


func repair_conflict(relationship_id: String, amount: Variant, source: String = "story") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    if not _is_number(amount) or amount <= 0:
        return _set_error(RELATIONSHIP_CONFLICT_INVALID, "Conflict repair amount must be positive", relationship_id)
    var conflict: Dictionary = _relationships[relationship_id]["conflict"]
    if not bool(_game_state.call("get_state", conflict["active_state_key"])):
        return _set_error(RELATIONSHIP_CONFLICT_INVALID, "Relationship has no active conflict", relationship_id)
    var old_progress: Variant = _game_state.call("get_state", conflict["repair_progress_state_key"])
    var new_progress: Variant = min(old_progress + amount, conflict["repair_threshold"])
    var overlay := {}
    overlay[conflict["repair_progress_state_key"]] = new_progress
    var cleared: bool = new_progress >= conflict["repair_threshold"]
    if cleared:
        overlay[conflict["active_state_key"]] = false
        overlay[conflict["reason_state_key"]] = ""
        if _boundary_keys[relationship_id].has("conflict_active"):
            overlay[_boundary_keys[relationship_id]["conflict_active"]] = false
    var stage_result := _append_stage_to_overlay(relationship_id, overlay)
    if not bool(stage_result.get("ok", false)) or not _commit_overlay(relationship_id, overlay):
        return last_error.duplicate(true)
    var result := _result(true, "OK", "Relationship conflict repaired", relationship_id, {"old_progress": old_progress, "repair_progress": new_progress, "cleared": cleared})
    conflict_changed.emit(result)
    _emit_stage_if_changed(relationship_id, str(stage_result["previous_stage"]), str(stage_result["current_stage"]), source)
    return result


func clear_conflict(relationship_id: String, source: String = "story") -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var conflict: Dictionary = _relationships[relationship_id]["conflict"]
    var progress: Variant = _game_state.call("get_state", conflict["repair_progress_state_key"])
    if progress < conflict["repair_threshold"]:
        return _set_error(RELATIONSHIP_CONFLICT_INVALID, "Conflict repair threshold has not been reached", relationship_id)
    return repair_conflict(relationship_id, conflict["repair_threshold"], source)


func select_text_version(relationship_id: String) -> Dictionary:
    if not _require_relationship(relationship_id):
        return last_error.duplicate(true)
    var versions: Array = _relationships[relationship_id].get("text_versions", []).duplicate(true)
    versions.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left.get("priority", 0)) > int(right.get("priority", 0)))
    for version: Dictionary in versions:
        var evaluation := _condition_group_matches(relationship_id, version["conditions"], {})
        if evaluation < 0:
            return last_error.duplicate(true)
        if evaluation == 1:
            return _result(true, "OK", "Relationship text version selected", relationship_id, {"tag": version["tag"]})
    return _set_error(RELATIONSHIP_CONDITION_INVALID, "No relationship text version matched", relationship_id)


func _validate_relationship_definition(relationship_id: String) -> bool:
    var definition: Dictionary = _relationships[relationship_id]
    if str(definition.get("actor_id", "")).is_empty() or str(definition.get("target_id", "")).is_empty():
        return _definition_fail("Relationship actor and target IDs are required", relationship_id)
    if definition["actor_id"] == definition["target_id"]:
        return _definition_fail("Relationship actor and target must be different", relationship_id)
    if not definition.get("dimensions") is Dictionary:
        return _definition_fail("Relationship dimensions must map IDs to GameState keys", relationship_id)
    for dimension_id: Variant in definition["dimensions"].keys():
        if not _dimensions.has(str(dimension_id)):
            return _definition_fail("Relationship references an unknown dimension", relationship_id)
        if not _validate_state_key(str(definition["dimensions"][dimension_id]), ["integer", "number"], relationship_id):
            return false
    if not _validate_state_key(str(definition.get("stage_state_key", "")), ["string"], relationship_id):
        return false
    _flag_keys[relationship_id] = {}
    for raw_flag: Variant in definition.get("flags", []):
        if not _register_named_state(raw_flag, _flag_keys[relationship_id], relationship_id, "flag"):
            return false
    _boundary_keys[relationship_id] = {}
    for raw_boundary: Variant in definition.get("boundaries", []):
        if not _register_named_state(raw_boundary, _boundary_keys[relationship_id], relationship_id, "boundary"):
            return false
    var conflict: Dictionary = definition.get("conflict", {})
    if not _validate_state_key(str(conflict.get("active_state_key", "")), ["boolean"], relationship_id):
        return false
    if not _validate_state_key(str(conflict.get("reason_state_key", "")), ["string"], relationship_id):
        return false
    if not _validate_state_key(str(conflict.get("repair_progress_state_key", "")), ["integer", "number"], relationship_id):
        return false
    if not _is_number(conflict.get("repair_threshold")) or conflict["repair_threshold"] <= 0:
        return _definition_fail("Relationship conflict repair threshold must be positive", relationship_id)
    var declared_rule_stages := {}
    for raw_rule: Variant in definition.get("stage_rules", []):
        if not raw_rule is Dictionary or not _stages.has(str(raw_rule.get("stage_id", ""))):
            return _definition_fail("Relationship stage rule references an unknown stage", relationship_id)
        if declared_rule_stages.has(raw_rule["stage_id"]):
            return _definition_fail("Relationship stage rule is duplicated", relationship_id)
        declared_rule_stages[raw_rule["stage_id"]] = true
        if not _validate_condition_group(relationship_id, raw_rule.get("conditions", {})):
            return false
    for raw_rule: Variant in definition.get("action_rules", []):
        if not _validate_condition_group(relationship_id, raw_rule.get("conditions", {})):
            return false
    for raw_rule: Variant in definition.get("rejection_rules", []):
        if not _flag_keys[relationship_id].has(str(raw_rule.get("rejection_flag_id", ""))):
            return _definition_fail("Rejection rule references an unknown flag", relationship_id)
        for boundary_id: Variant in raw_rule.get("boundary_updates", {}).keys():
            if not _boundary_keys[relationship_id].has(str(boundary_id)):
                return _definition_fail("Rejection rule references an unknown boundary", relationship_id)
    for raw_version: Variant in definition.get("text_versions", []):
        if not _validate_condition_group(relationship_id, raw_version.get("conditions", {})):
            return false
    return true


func _validate_state_key(key: String, expected_types: Array, relationship_id: String) -> bool:
    if key.is_empty() or not bool(_game_state.call("has_state", key)):
        return _definition_fail("Relationship references unknown GameState key '%s'" % key, relationship_id)
    if _content_loader.has_method("get_state_definition"):
        var state_definition: Variant = _content_loader.call("get_state_definition", key)
        if not state_definition is Dictionary or str(state_definition.get("type", "")) not in expected_types:
            return _definition_fail("Relationship state key '%s' has the wrong type" % key, relationship_id)
        var write_sources: Variant = state_definition.get("write_sources", [])
        if bool(state_definition.get("read_only", false)) or (write_sources is Array and not write_sources.is_empty() and "relationship" not in write_sources):
            return _definition_fail("Relationship state key '%s' does not allow relationship writes" % key, relationship_id)
    return true


func _register_named_state(raw_entry: Variant, destination: Dictionary, relationship_id: String, label: String) -> bool:
    if not raw_entry is Dictionary:
        return _definition_fail("Relationship %s definition must be an object" % label, relationship_id)
    var entry_id := str(raw_entry.get("id", ""))
    if entry_id.is_empty() or destination.has(entry_id):
        return _definition_fail("Relationship %s IDs must be non-empty and unique" % label, relationship_id)
    if not _validate_state_key(str(raw_entry.get("state_key", "")), ["boolean"], relationship_id):
        return false
    destination[entry_id] = raw_entry["state_key"]
    return true


func _validate_condition_group(relationship_id: String, group: Variant) -> bool:
    if not group is Dictionary:
        return _definition_fail("Relationship condition group must be an object", relationship_id)
    for group_name: String in ["all", "any"]:
        if group.has(group_name) and not group[group_name] is Array:
            return _definition_fail("Relationship condition group '%s' must be an array" % group_name, relationship_id)
        for raw_condition: Variant in group.get(group_name, []):
            if not raw_condition is Dictionary:
                return _definition_fail("Relationship condition must be an object", relationship_id)
            var condition: Dictionary = raw_condition
            var kind := str(condition.get("kind", ""))
            if kind not in CONDITION_KINDS:
                return _definition_fail("Unknown relationship condition kind '%s'" % kind, relationship_id)
            match kind:
                "dimension":
                    if not _relationships[relationship_id]["dimensions"].has(str(condition.get("dimension_id", ""))):
                        return _definition_fail("Condition references an unknown relationship dimension", relationship_id)
                "flag":
                    if not _flag_keys[relationship_id].has(str(condition.get("flag_id", ""))):
                        return _definition_fail("Condition references an unknown relationship flag", relationship_id)
                "boundary":
                    if not _boundary_keys[relationship_id].has(str(condition.get("boundary_id", ""))):
                        return _definition_fail("Condition references an unknown relationship boundary", relationship_id)
                "stage":
                    if not _stages.has(str(condition.get("stage_id", ""))):
                        return _definition_fail("Condition references an unknown relationship stage", relationship_id)
                "state":
                    if not bool(_game_state.call("has_state", str(condition.get("key", "")))):
                        return _definition_fail("Condition references an unknown GameState key", relationship_id)
    return true


func _condition_group_matches(relationship_id: String, group: Dictionary, overlay: Dictionary) -> int:
    for raw_condition: Variant in group.get("all", []):
        var matched := _condition_matches(relationship_id, raw_condition, overlay)
        if matched <= 0:
            return matched
    var any_conditions: Array = group.get("any", [])
    if any_conditions.is_empty():
        return 1
    for raw_condition: Variant in any_conditions:
        var matched := _condition_matches(relationship_id, raw_condition, overlay)
        if matched < 0:
            return -1
        if matched == 1:
            return 1
    return 0


func _condition_matches(relationship_id: String, condition: Dictionary, overlay: Dictionary) -> int:
    var kind := str(condition.get("kind", ""))
    match kind:
        "dimension":
            var dimension_id := str(condition.get("dimension_id", ""))
            if not _require_dimension(relationship_id, dimension_id):
                return -1
            var key: String = _relationships[relationship_id]["dimensions"][dimension_id]
            return 1 if _compare(overlay.get(key, _game_state.call("get_state", key)), str(condition.get("op", "eq")), condition.get("value")) else 0
        "flag":
            var flag_id := str(condition.get("flag_id", ""))
            if not _require_flag(relationship_id, flag_id):
                return -1
            var key: String = _flag_keys[relationship_id][flag_id]
            return 1 if overlay.get(key, _game_state.call("get_state", key)) == condition.get("value") else 0
        "boundary":
            var boundary_id := str(condition.get("boundary_id", ""))
            if not _require_boundary(relationship_id, boundary_id):
                return -1
            var key: String = _boundary_keys[relationship_id][boundary_id]
            return 1 if overlay.get(key, _game_state.call("get_state", key)) == condition.get("value") else 0
        "conflict":
            var key: String = _relationships[relationship_id]["conflict"]["active_state_key"]
            return 1 if overlay.get(key, _game_state.call("get_state", key)) == condition.get("active") else 0
        "stage":
            var expected_stage := str(condition.get("stage_id", ""))
            if not _stages.has(expected_stage):
                _set_error(RELATIONSHIP_CONDITION_INVALID, "Unknown relationship stage in condition", relationship_id)
                return -1
            var stage_key: String = _relationships[relationship_id]["stage_state_key"]
            var actual_stage := str(overlay.get(stage_key, _game_state.call("get_state", stage_key)))
            return 1 if _compare(int(_stages[actual_stage]["rank"]), str(condition.get("op", "eq")), int(_stages[expected_stage]["rank"])) else 0
        "state":
            var state_condition := {"key": condition.get("key"), "op": condition.get("op"), "value": condition.get("value")}
            return 1 if bool(_game_state.call("evaluate_condition", state_condition)) else 0
        _:
            _set_error(RELATIONSHIP_CONDITION_INVALID, "Unknown relationship condition kind '%s'" % kind, relationship_id)
            return -1


func _select_stage(relationship_id: String, overlay: Dictionary) -> String:
    var rules: Array = _relationships[relationship_id]["stage_rules"].duplicate(true)
    rules.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(_stages[left["stage_id"]]["rank"]) > int(_stages[right["stage_id"]]["rank"]))
    for rule: Dictionary in rules:
        var evaluation := _condition_group_matches(relationship_id, rule["conditions"], overlay)
        if evaluation < 0:
            return ""
        if evaluation == 1:
            return str(rule["stage_id"])
    _set_error(RELATIONSHIP_DEFINITION_INVALID, "No relationship stage rule matched", relationship_id)
    return ""


func _append_stage_to_overlay(relationship_id: String, overlay: Dictionary) -> Dictionary:
    var stage_key: String = _relationships[relationship_id]["stage_state_key"]
    var previous_stage := str(_game_state.call("get_state", stage_key))
    var current_stage := _select_stage(relationship_id, overlay)
    if current_stage.is_empty():
        return last_error.duplicate(true)
    overlay[stage_key] = current_stage
    return _result(true, "OK", "Relationship stage prepared", relationship_id, {"previous_stage": previous_stage, "current_stage": current_stage})


func _commit_overlay(relationship_id: String, overlay: Dictionary) -> bool:
    var effects: Array = []
    for key: Variant in overlay.keys():
        if _game_state.call("get_state", str(key)) != overlay[key]:
            effects.append({"op": "set", "key": str(key), "value": overlay[key]})
    if effects.is_empty():
        last_error = {}
        return true
    if not bool(_game_state.call("apply_effects", effects, "relationship")):
        var details: Variant = _game_state.get("last_error")
        _set_error(RELATIONSHIP_STATE_WRITE_FAILED, "GameState rejected an atomic relationship update", relationship_id, {"details": details})
        return false
    last_error = {}
    return true


func _compare(left: Variant, operation: String, right: Variant) -> bool:
    match operation:
        "eq": return left == right
        "neq", "ne": return left != right
        "gt": return left > right
        "gte": return left >= right
        "lt": return left < right
        "lte": return left <= right
        "in": return right is Array and left in right
        "not_in": return right is Array and left not in right
    return false


func _rejection_rule(relationship_id: String, action_id: String) -> Dictionary:
    for raw_rule: Variant in _relationships[relationship_id].get("rejection_rules", []):
        if str(raw_rule.get("action_id", "")) == action_id:
            return raw_rule
    return {}


func _reopen_rule(relationship_id: String, action_id: String) -> Dictionary:
    for raw_rule: Variant in _relationships[relationship_id].get("rejection_rules", []):
        if str(raw_rule.get("reopen_action_id", "")) == action_id:
            return raw_rule
    return {}


func _emit_boundary_overlay_changes(relationship_id: String, old_values: Dictionary, updates: Dictionary, source: String) -> void:
    for boundary_id: Variant in updates.keys():
        var new_value := bool(updates[boundary_id])
        var old_value := bool(old_values.get(boundary_id, new_value))
        if old_value != new_value:
            boundary_changed.emit(relationship_id, str(boundary_id), old_value, new_value, source)


func _emit_stage_if_changed(relationship_id: String, previous_stage: String, current_stage: String, source: String) -> void:
    if previous_stage != current_stage:
        stage_changed.emit(relationship_id, previous_stage, current_stage, source)


func _has_actual_change(changes: Array) -> bool:
    for change: Variant in changes:
        if change["old_value"] != change["new_value"]:
            return true
    return false


func _require_initialized() -> bool:
    if not _initialized:
        _set_error(RELATIONSHIP_NOT_INITIALIZED, "RelationshipManager has not been initialized")
        return false
    return true


func _require_relationship(relationship_id: String) -> bool:
    if not _require_initialized():
        return false
    if not _relationships.has(relationship_id):
        _set_error(RELATIONSHIP_NOT_FOUND, "Unknown relationship ID '%s'" % relationship_id, relationship_id)
        return false
    return true


func _require_dimension(relationship_id: String, dimension_id: String) -> bool:
    if not _require_relationship(relationship_id):
        return false
    if not _relationships[relationship_id]["dimensions"].has(dimension_id):
        _set_error(RELATIONSHIP_DIMENSION_NOT_FOUND, "Unknown relationship dimension '%s'" % dimension_id, relationship_id, {"dimension_id": dimension_id})
        return false
    return true


func _require_flag(relationship_id: String, flag_id: String) -> bool:
    if not _require_relationship(relationship_id):
        return false
    if not _flag_keys[relationship_id].has(flag_id):
        _set_error(RELATIONSHIP_FLAG_NOT_FOUND, "Unknown relationship flag '%s'" % flag_id, relationship_id, {"flag_id": flag_id})
        return false
    return true


func _require_boundary(relationship_id: String, boundary_id: String) -> bool:
    if not _require_relationship(relationship_id):
        return false
    if not _boundary_keys[relationship_id].has(boundary_id):
        _set_error(RELATIONSHIP_BOUNDARY_NOT_FOUND, "Unknown relationship boundary '%s'" % boundary_id, relationship_id, {"boundary_id": boundary_id})
        return false
    return true


func _initialize_fail(message: String, relationship_id: String = "") -> bool:
    _set_error(RELATIONSHIP_DEFINITION_INVALID, message, relationship_id)
    _clear_runtime(false)
    return false


func _definition_fail(message: String, relationship_id: String) -> bool:
    _set_error(RELATIONSHIP_DEFINITION_INVALID, message, relationship_id)
    return false


func _set_error(code: String, message: String, relationship_id: String = "", extra: Dictionary = {}) -> Dictionary:
    last_error = _result(false, code, message, relationship_id, extra)
    relationship_error.emit(last_error.duplicate(true))
    return last_error.duplicate(true)


func _result(ok: bool, code: String, message: String, relationship_id: String = "", extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "code": code, "message": message}
    if not relationship_id.is_empty():
        result["relationship_id"] = relationship_id
    result.merge(extra, true)
    return result


func _is_number(value: Variant) -> bool:
    return value is int or value is float


func _clear_runtime(clear_error: bool = true) -> void:
    _content_loader = null
    _game_state = null
    _dimensions.clear()
    _stages.clear()
    _relationships.clear()
    _flag_keys.clear()
    _boundary_keys.clear()
    _initialized = false
    if clear_error:
        last_error = {}
