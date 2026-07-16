extends RefCounted

signal inventory_changed(change: Dictionary)
signal item_added(result: Dictionary)
signal item_removed(result: Dictionary)
signal item_used(result: Dictionary)
signal equipment_changed(result: Dictionary)
signal custody_changed(result: Dictionary)
signal inventory_restored(snapshot: Dictionary)
signal inventory_error(error: Dictionary)

const SNAPSHOT_VERSION := 1
const DEFAULT_CAPACITY := 30
const MAX_SUPPORTED_CAPACITY := 60
const EQUIPMENT_SLOTS := [
    "weapon", "off_hand", "head", "body", "accessory_1", "accessory_2",
]
const ITEM_TYPES := ["consumable", "equipment", "quest", "material", "key_item"]
const USE_CONTEXTS := ["battle_only", "field_only", "both"]
const QUANTITY_SCOPES := ["all", "backpack", "quest", "custody", "equipped"]

const INVENTORY_NOT_INITIALIZED := "INVENTORY_NOT_INITIALIZED"
const INVENTORY_DEFINITION_INVALID := "INVENTORY_DEFINITION_INVALID"
const INVENTORY_STATE_WRITE_FAILED := "INVENTORY_STATE_WRITE_FAILED"
const INVENTORY_FULL := "INVENTORY_FULL"
const INVENTORY_SNAPSHOT_INVALID := "INVENTORY_SNAPSHOT_INVALID"
const INVENTORY_RESTORE_FAILED := "INVENTORY_RESTORE_FAILED"
const INVENTORY_MUTATION_IN_PROGRESS := "INVENTORY_MUTATION_IN_PROGRESS"
const ITEM_NOT_FOUND := "ITEM_NOT_FOUND"
const ITEM_QUANTITY_INVALID := "ITEM_QUANTITY_INVALID"
const ITEM_UNIQUE_DUPLICATE := "ITEM_UNIQUE_DUPLICATE"
const ITEM_INSUFFICIENT := "ITEM_INSUFFICIENT"
const ITEM_DISCARD_FORBIDDEN := "ITEM_DISCARD_FORBIDDEN"
const ITEM_NOT_USABLE := "ITEM_NOT_USABLE"
const ITEM_USE_CONTEXT_INVALID := "ITEM_USE_CONTEXT_INVALID"
const ITEM_EFFECT_FAILED := "ITEM_EFFECT_FAILED"
const CUSTODY_INSUFFICIENT := "CUSTODY_INSUFFICIENT"
const EQUIPMENT_SLOT_INVALID := "EQUIPMENT_SLOT_INVALID"
const EQUIPMENT_ITEM_INVALID := "EQUIPMENT_ITEM_INVALID"
const EQUIPMENT_SLOT_MISMATCH := "EQUIPMENT_SLOT_MISMATCH"
const EQUIPMENT_SLOT_EMPTY := "EQUIPMENT_SLOT_EMPTY"
const EQUIPMENT_RETURN_BLOCKED := "EQUIPMENT_RETURN_BLOCKED"
const QUEST_REWARD_INVALID := "QUEST_REWARD_INVALID"

var last_error: Dictionary = {}

var _content_loader: RefCounted
var _game_state: RefCounted
var _definitions: Dictionary = {}
var _state_definitions: Dictionary = {}
var _capacity := DEFAULT_CAPACITY
var _backpack: Array = []
var _quest_items: Array = []
var _custody: Array = []
var _equipment: Dictionary = {}
var _initialized := false
var _mutation_in_progress := false


func initialize(content_loader: RefCounted, game_state: RefCounted, capacity: int = DEFAULT_CAPACITY) -> bool:
    _clear_runtime()
    if (
        content_loader == null
        or not content_loader.has_method("get_item_definitions")
        or not content_loader.has_method("get_state_definitions")
    ):
        return _initialize_fail("ContentLoader does not provide item and state definitions")
    if (
        game_state == null
        or not game_state.has_method("has_state")
        or not game_state.has_method("get_state")
        or not game_state.has_method("apply_effects")
    ):
        return _initialize_fail("GameState does not provide the required inventory interfaces")
    if capacity < 1 or capacity > MAX_SUPPORTED_CAPACITY:
        return _initialize_fail("Inventory capacity must be between 1 and %d" % MAX_SUPPORTED_CAPACITY)

    _content_loader = content_loader
    _game_state = game_state
    _capacity = capacity
    _equipment = _empty_equipment()
    var raw_state_definitions: Variant = content_loader.call("get_state_definitions")
    if not raw_state_definitions is Array:
        return _initialize_fail("State definitions must be an array")
    for raw_state_definition: Variant in raw_state_definitions:
        if not raw_state_definition is Dictionary:
            return _initialize_fail("Every state definition must be an object")
        var state_key := str(raw_state_definition.get("key", ""))
        if not state_key.is_empty():
            _state_definitions[state_key] = raw_state_definition.duplicate(true)
    var raw_definitions: Variant = content_loader.call("get_item_definitions")
    if not raw_definitions is Array:
        return _initialize_fail("Item definitions must be an array")
    for raw_definition: Variant in raw_definitions:
        if not raw_definition is Dictionary:
            return _initialize_fail("Every item definition must be an object")
        var normalized := _normalize_definition(raw_definition)
        if normalized.is_empty():
            return false
        var item_id := str(normalized.get("item_id", ""))
        if _definitions.has(item_id):
            return _initialize_fail("Duplicate item definition '%s'" % item_id, item_id)
        _definitions[item_id] = normalized

    var ownership_keys := {}
    for raw_definition: Variant in _definitions.values():
        var definition: Dictionary = raw_definition
        var ownership_key := str(definition.get("ownership_state_key", ""))
        if ownership_key.is_empty():
            continue
        if ownership_keys.has(ownership_key):
            return _initialize_fail(
                "Ownership state key '%s' is assigned to more than one item" % ownership_key,
                str(definition["item_id"]),
            )
        ownership_keys[ownership_key] = definition["item_id"]
    for raw_definition: Variant in _definitions.values():
        var definition: Dictionary = raw_definition
        for raw_effect: Variant in definition.get("use_effects", []):
            var effect: Dictionary = raw_effect
            var effect_key := str(effect.get("key", ""))
            if ownership_keys.has(effect_key):
                return _initialize_fail(
                    "Use effects cannot modify inventory ownership projection '%s'" % effect_key,
                    str(definition["item_id"]),
                )

    _initialized = true
    _mutation_in_progress = true
    var ownership_synced := _sync_ownership_flags(export_snapshot(), "inventory")
    _mutation_in_progress = false
    if not ownership_synced:
        _initialized = false
        return false
    last_error = {}
    return true


func is_initialized() -> bool:
    return _initialized


func get_capacity() -> int:
    return _capacity if _initialized else 0


func get_used_slots() -> int:
    return _backpack.size() if _initialized else 0


func get_item_definition(item_id: String) -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    return _result(true, "OK", "Item definition queried", item_id, {
        "item": _definitions[item_id].duplicate(true),
    })


func get_item_quantity(item_id: String, scope: String = "all") -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    if scope not in QUANTITY_SCOPES:
        return _fail(ITEM_QUANTITY_INVALID, "Unknown item quantity scope '%s'" % scope, item_id, {
            "scope": scope,
        })
    return _result(true, "OK", "Item quantity queried", item_id, {
        "scope": scope,
        "quantity": _quantity_in_runtime(item_id, scope),
    })


func get_backpack_contents() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    return _result(true, "OK", "Backpack contents queried", "", {
        "items": _backpack.duplicate(true),
        "used_slots": _backpack.size(),
        "capacity": _capacity,
    })


func get_quest_item_contents() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    return _result(true, "OK", "Quest item contents queried", "", {
        "items": _quest_items.duplicate(true),
    })


func get_custody_contents() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    return _result(true, "OK", "Custody contents queried", "", {
        "items": _custody.duplicate(true),
    })


func get_equipment() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    return _result(true, "OK", "Equipment queried", "", {
        "equipment": _equipment.duplicate(true),
    })


func add_item(item_id: String, quantity: int = 1, source: String = "system") -> Dictionary:
    return grant_items([{"item_id": item_id, "quantity": quantity}], source)


func grant_items(grants: Array, source: String = "system") -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    if grants.is_empty():
        return _fail(ITEM_QUANTITY_INVALID, "An item grant must contain at least one entry")
    var candidate := export_snapshot()
    var placements := {"backpack": [], "quest": [], "custody": []}
    for raw_grant: Variant in grants:
        if not raw_grant is Dictionary:
            return _fail(ITEM_QUANTITY_INVALID, "Every item grant must be an object")
        var item_id := str(raw_grant.get("item_id", ""))
        if not _require_item(item_id):
            return last_error.duplicate(true)
        var raw_quantity: Variant = raw_grant.get("quantity", 0)
        if not _is_integer_value(raw_quantity) or int(raw_quantity) <= 0:
            return _fail(ITEM_QUANTITY_INVALID, "Item quantity must be a positive integer", item_id)
        var quantity := int(raw_quantity)
        var definition: Dictionary = _definitions[item_id]
        if bool(definition["unique"]) and _quantity_in_snapshot(candidate, item_id, "all") + quantity > 1:
            return _fail(ITEM_UNIQUE_DUPLICATE, "Unique item already exists in inventory", item_id)
        var placement := _grant_to_candidate(candidate, definition, quantity)
        if not bool(placement.get("ok", false)):
            return _fail(
                str(placement.get("code", INVENTORY_FULL)),
                str(placement.get("message", "Item grant could not fit in inventory")),
                item_id,
            )
        _append_placement(placements["backpack"], item_id, int(placement.get("backpack", 0)))
        _append_placement(placements["quest"], item_id, int(placement.get("quest", 0)))
        _append_placement(placements["custody"], item_id, int(placement.get("custody", 0)))

    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Items granted", "", {
        "changed": bool(commit.get("changed", false)),
        "placements": placements,
    })
    item_added.emit(result.duplicate(true))
    if not placements["custody"].is_empty():
        custody_changed.emit(result.duplicate(true))
    return result


func apply_quest_reward(reward_result: Dictionary) -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    if not bool(reward_result.get("ok", false)) or not reward_result.get("rewards", []) is Array:
        return _fail(QUEST_REWARD_INVALID, "Quest reward request is invalid", str(reward_result.get("quest_id", "")))
    var grants: Array = []
    for raw_reward: Variant in reward_result.get("rewards", []):
        if not raw_reward is Dictionary:
            return _fail(QUEST_REWARD_INVALID, "Quest reward entry must be an object", str(reward_result.get("quest_id", "")))
        var reward_type := str(raw_reward.get("type", ""))
        if reward_type == "signal_only":
            continue
        if reward_type != "items":
            return _fail(
                QUEST_REWARD_INVALID,
                "Quest reward type '%s' is not supported" % reward_type,
                str(reward_result.get("quest_id", "")),
            )
        var raw_items: Variant = raw_reward.get("items", [])
        if not raw_items is Array:
            return _fail(QUEST_REWARD_INVALID, "Quest item reward must contain an items array", str(reward_result.get("quest_id", "")))
        for raw_grant: Variant in raw_items:
            if not raw_grant is Dictionary:
                return _fail(QUEST_REWARD_INVALID, "Quest item reward entry must be an object", str(reward_result.get("quest_id", "")))
            grants.append(raw_grant.duplicate(true))
    if grants.is_empty():
        return _result(true, "OK", "Quest reward contains no inventory items", str(reward_result.get("quest_id", "")), {
            "changed": false,
            "placements": {"backpack": [], "quest": [], "custody": []},
        })
    return grant_items(grants, "quest_reward")


func remove_item(item_id: String, quantity: int = 1, source: String = "system") -> Dictionary:
    return _remove_item_internal(item_id, quantity, source, false)


func discard_item(item_id: String, quantity: int = 1, source: String = "system") -> Dictionary:
    return _remove_item_internal(item_id, quantity, source, true)


func claim_custody_item(item_id: String, quantity: int = 1, source: String = "system") -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    if quantity <= 0:
        return _fail(ITEM_QUANTITY_INVALID, "Custody claim quantity must be positive", item_id)
    var candidate := export_snapshot()
    var custody: Array = candidate["custody"]
    if _sum_container(custody, item_id) < quantity:
        return _fail(CUSTODY_INSUFFICIENT, "Custody does not contain the requested quantity", item_id)
    _remove_from_container(custody, item_id, quantity)
    var definition: Dictionary = _definitions[item_id]
    var target_name := "quest_items" if str(definition["storage"]) == "quest" else "backpack"
    var target: Array = candidate[target_name]
    var max_slots := -1 if target_name == "quest_items" else int(candidate["capacity"])
    var add_result := _add_to_container(target, definition, quantity, max_slots)
    if not bool(add_result.get("ok", false)):
        return _fail(INVENTORY_FULL, "Backpack is full; custody item was retained", item_id)
    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Custody item claimed", item_id, {
        "quantity": quantity,
        "destination": "quest" if target_name == "quest_items" else "backpack",
        "changed": true,
    })
    custody_changed.emit(result.duplicate(true))
    item_added.emit(result.duplicate(true))
    return result


func equip_item(item_id: String, target_slot: String = "", source: String = "system") -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    var definition: Dictionary = _definitions[item_id]
    if str(definition["type"]) != "equipment":
        return _fail(EQUIPMENT_ITEM_INVALID, "Only equipment items can be equipped", item_id)
    var slot := target_slot if not target_slot.is_empty() else str(definition["equipment_slot"])
    if slot not in EQUIPMENT_SLOTS:
        return _fail(EQUIPMENT_SLOT_INVALID, "Unknown equipment slot '%s'" % slot, item_id, {"slot": slot})
    if slot not in definition["compatible_slots"]:
        return _fail(EQUIPMENT_SLOT_MISMATCH, "Item is not compatible with equipment slot '%s'" % slot, item_id, {"slot": slot})
    if _sum_container(_backpack, item_id) < 1:
        return _fail(ITEM_INSUFFICIENT, "Equipment item is not present in the backpack", item_id)

    var candidate := export_snapshot()
    var desired_slots := _occupied_slots_for(definition, slot)
    var old_by_anchor := {}
    for occupied_slot: String in desired_slots:
        var occupied: Variant = candidate["equipment"].get(occupied_slot)
        if occupied is Dictionary:
            old_by_anchor[str(occupied.get("anchor_slot", occupied_slot))] = str(occupied.get("item_id", ""))
    _remove_from_container(candidate["backpack"], item_id, 1)
    for old_item_id: Variant in old_by_anchor.values():
        var old_definition: Dictionary = _definitions[str(old_item_id)]
        var return_result := _add_to_container(candidate["backpack"], old_definition, 1, int(candidate["capacity"]))
        if not bool(return_result.get("ok", false)):
            return _fail(EQUIPMENT_RETURN_BLOCKED, "Old equipment cannot return to the full backpack", item_id, {
                "slot": slot,
                "blocked_item_id": str(old_item_id),
            })
    for old_anchor: Variant in old_by_anchor.keys():
        _clear_equipped_anchor(candidate["equipment"], str(old_anchor))
    for occupied_slot: String in desired_slots:
        candidate["equipment"][occupied_slot] = {"item_id": item_id, "anchor_slot": slot}

    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Item equipped", item_id, {
        "slot": slot,
        "occupied_slots": desired_slots.duplicate(),
        "returned_item_ids": old_by_anchor.values().duplicate(),
        "changed": true,
    })
    equipment_changed.emit(result.duplicate(true))
    return result


func unequip_item(slot: String, source: String = "system") -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    if slot not in EQUIPMENT_SLOTS:
        return _fail(EQUIPMENT_SLOT_INVALID, "Unknown equipment slot '%s'" % slot, "", {"slot": slot})
    var current: Variant = _equipment.get(slot)
    if not current is Dictionary:
        return _fail(EQUIPMENT_SLOT_EMPTY, "Equipment slot is already empty", "", {"slot": slot})
    var item_id := str(current.get("item_id", ""))
    var anchor := str(current.get("anchor_slot", slot))
    var candidate := export_snapshot()
    var add_result := _add_to_container(candidate["backpack"], _definitions[item_id], 1, int(candidate["capacity"]))
    if not bool(add_result.get("ok", false)):
        return _fail(EQUIPMENT_RETURN_BLOCKED, "Unequipped item cannot return to the full backpack", item_id, {"slot": slot})
    _clear_equipped_anchor(candidate["equipment"], anchor)
    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Item unequipped", item_id, {
        "slot": slot,
        "anchor_slot": anchor,
        "changed": true,
    })
    equipment_changed.emit(result.duplicate(true))
    return result


func get_stat_modifiers() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    var modifiers := {}
    for slot: String in EQUIPMENT_SLOTS:
        var equipped: Variant = _equipment.get(slot)
        if not equipped is Dictionary or str(equipped.get("anchor_slot", "")) != slot:
            continue
        var item_id := str(equipped.get("item_id", ""))
        for raw_modifier: Variant in _definitions[item_id].get("stat_modifiers", []):
            var modifier: Dictionary = raw_modifier
            var stat := str(modifier.get("stat", ""))
            modifiers[stat] = float(modifiers.get(stat, 0.0)) + float(modifier.get("value", 0.0))
    return _result(true, "OK", "Equipment stat modifiers queried", "", {"modifiers": modifiers})


func use_item(item_id: String, context: String = "field", source: String = "system") -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    var definition: Dictionary = _definitions[item_id]
    if str(definition["type"]) != "consumable":
        return _fail(ITEM_NOT_USABLE, "Item is not a consumable", item_id)
    if context not in ["field", "battle"]:
        return _fail(ITEM_USE_CONTEXT_INVALID, "Unknown item use context '%s'" % context, item_id)
    var declared_context := str(definition["use_context"])
    if (
        (declared_context == "field_only" and context != "field")
        or (declared_context == "battle_only" and context != "battle")
    ):
        return _fail(ITEM_USE_CONTEXT_INVALID, "Item cannot be used in the current context", item_id, {"context": context})
    var container_name := "quest_items" if str(definition["storage"]) == "quest" else "backpack"
    var current_container: Array = _quest_items if container_name == "quest_items" else _backpack
    if _sum_container(current_container, item_id) < 1:
        return _fail(ITEM_INSUFFICIENT, "Consumable quantity is insufficient", item_id)
    var candidate := export_snapshot()
    _remove_from_container(candidate[container_name], item_id, 1)
    var commit := _commit_candidate(candidate, source, definition.get("use_effects", []), ITEM_EFFECT_FAILED)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Consumable used", item_id, {
        "context": context,
        "quantity": 1,
        "effects": definition.get("use_effects", []).duplicate(true),
        "changed": true,
    })
    item_used.emit(result.duplicate(true))
    item_removed.emit(result.duplicate(true))
    return result


func reset_inventory(source: String = "system") -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    var candidate := _empty_snapshot()
    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    return _result(true, "OK", "Inventory reset", "", {
        "changed": bool(commit.get("changed", false)),
    })


func export_snapshot() -> Dictionary:
    return {
        "snapshot_version": SNAPSHOT_VERSION,
        "capacity": _capacity,
        "backpack": _backpack.duplicate(true),
        "quest_items": _quest_items.duplicate(true),
        "equipment": _equipment.duplicate(true),
        "custody": _custody.duplicate(true),
    }


func validate_snapshot(snapshot: Dictionary) -> bool:
    if not _require_initialized_bool():
        return false
    return _validate_snapshot_data(snapshot)


func restore_snapshot(snapshot: Dictionary, source: String = "save_restore") -> bool:
    if _mutation_in_progress:
        _record_error(INVENTORY_MUTATION_IN_PROGRESS, "Inventory mutation is already in progress")
        return false
    if not validate_snapshot(snapshot):
        return false
    var normalized := _normalize_snapshot(snapshot)
    var effects := _ownership_effects_for_snapshot(normalized)
    _mutation_in_progress = true
    if not effects.is_empty() and not bool(_game_state.call("apply_effects", effects, _state_source(source))):
        _mutation_in_progress = false
        _record_error(INVENTORY_RESTORE_FAILED, "GameState rejected inventory ownership restoration", "", {
            "details": _game_state.get("last_error"),
        })
        return false
    _load_snapshot_unchecked(normalized)
    _mutation_in_progress = false
    last_error = {}
    inventory_restored.emit(export_snapshot())
    return true


func create_runtime_checkpoint() -> Dictionary:
    return {
        "snapshot": export_snapshot(),
        "last_error": last_error.duplicate(true),
    }


func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
    if _mutation_in_progress:
        _record_error(INVENTORY_MUTATION_IN_PROGRESS, "Inventory mutation is already in progress")
        return false
    if not checkpoint.has("snapshot") or not checkpoint["snapshot"] is Dictionary:
        return _checkpoint_fail("Inventory checkpoint is missing its snapshot")
    if not checkpoint.has("last_error") or not checkpoint["last_error"] is Dictionary:
        return _checkpoint_fail("Inventory checkpoint is missing its error state")
    if not _validate_snapshot_data(checkpoint["snapshot"]):
        return false
    _mutation_in_progress = true
    _load_snapshot_unchecked(_normalize_snapshot(checkpoint["snapshot"]))
    last_error = checkpoint["last_error"].duplicate(true)
    _mutation_in_progress = false
    return true


func emit_changes_from_checkpoint(checkpoint: Dictionary, source: String = "save_restore") -> bool:
    if not checkpoint.has("snapshot") or not checkpoint["snapshot"] is Dictionary:
        return _checkpoint_fail("Inventory checkpoint is missing its snapshot")
    var previous: Dictionary = checkpoint["snapshot"]
    var current := export_snapshot()
    if previous != current:
        inventory_changed.emit({
            "ok": true,
            "code": "OK",
            "message": "Inventory restored from checkpoint",
            "source": source,
            "old_snapshot": previous.duplicate(true),
            "new_snapshot": current.duplicate(true),
        })
    inventory_restored.emit(current.duplicate(true))
    return true


func _remove_item_internal(item_id: String, quantity: int, source: String, discard: bool) -> Dictionary:
    if not _require_item(item_id):
        return last_error.duplicate(true)
    if quantity <= 0:
        return _fail(ITEM_QUANTITY_INVALID, "Item removal quantity must be positive", item_id)
    var definition: Dictionary = _definitions[item_id]
    if discard and (bool(definition["quest_critical"]) or not bool(definition["discardable"])):
        return _fail(ITEM_DISCARD_FORBIDDEN, "This item cannot be discarded", item_id)
    var container_name := "quest_items" if str(definition["storage"]) == "quest" else "backpack"
    var active_container: Array = _quest_items if container_name == "quest_items" else _backpack
    if _sum_container(active_container, item_id) < quantity:
        return _fail(ITEM_INSUFFICIENT, "Item quantity is insufficient", item_id)
    var candidate := export_snapshot()
    _remove_from_container(candidate[container_name], item_id, quantity)
    var commit := _commit_candidate(candidate, source)
    if not bool(commit.get("ok", false)):
        return commit
    var result := _result(true, "OK", "Item discarded" if discard else "Item removed", item_id, {
        "quantity": quantity,
        "discarded": discard,
        "changed": true,
    })
    item_removed.emit(result.duplicate(true))
    return result


func _normalize_definition(raw_definition: Dictionary) -> Dictionary:
    var item_id := str(raw_definition.get("item_id", ""))
    if item_id.is_empty():
        _definition_fail("Item ID cannot be empty")
        return {}
    var runtime_value: Variant = raw_definition.get("runtime")
    var runtime: Dictionary = runtime_value if runtime_value is Dictionary else {}
    var has_runtime := runtime_value is Dictionary
    var legacy_kind := str(raw_definition.get("kind", ""))
    var legacy_key_item := bool(raw_definition.get("key_item", false))
    var legacy_stack: Variant = raw_definition.get("stack_limit", 1)
    var legacy_slot: Variant = raw_definition.get("equip_slot")
    var inferred_type := legacy_kind
    var inferred_stackable := _is_integer_value(legacy_stack) and int(legacy_stack) > 1 and legacy_kind != "equipment"
    var inferred_slot: Variant = legacy_slot if legacy_kind == "equipment" else null
    var inferred_slots: Array = [inferred_slot] if inferred_slot is String and not str(inferred_slot).is_empty() else []
    var definition := {
        "item_id": item_id,
        "name": str(raw_definition.get("name", item_id)),
        "type": runtime.get("type", inferred_type),
        "stackable": runtime.get("stackable", inferred_stackable),
        "max_stack": runtime.get("max_stack", legacy_stack),
        "sellable": runtime.get("sellable", int(raw_definition.get("base_price", 0)) > 0 and not legacy_key_item),
        "discardable": runtime.get("discardable", not legacy_key_item),
        "unique": runtime.get("unique", legacy_key_item),
        "quest_critical": runtime.get("quest_critical", legacy_key_item),
        "storage": runtime.get("storage", "quest" if legacy_kind == "quest" else "normal"),
        "overflow_policy": runtime.get("overflow_policy", "custody" if legacy_key_item else "reject"),
        "equipment_slot": runtime.get("equipment_slot", inferred_slot),
        "compatible_slots": runtime.get("compatible_slots", inferred_slots),
        "occupies_slots": runtime.get("occupies_slots", inferred_slots),
        "stat_modifiers": runtime.get("stat_modifiers", []),
        "use_effects": runtime.get("use_effects", []),
        "use_context": runtime.get("use_context", "both"),
        "ownership_state_key": str(runtime.get("ownership_state_key", "")),
        "source": raw_definition.duplicate(true),
        "has_runtime": has_runtime,
    }
    if not _validate_definition(definition):
        return {}
    definition["max_stack"] = int(definition["max_stack"])
    definition["compatible_slots"] = definition["compatible_slots"].duplicate(true)
    definition["occupies_slots"] = definition["occupies_slots"].duplicate(true)
    definition["stat_modifiers"] = definition["stat_modifiers"].duplicate(true)
    definition["use_effects"] = definition["use_effects"].duplicate(true)
    return definition


func _validate_definition(definition: Dictionary) -> bool:
    var item_id := str(definition.get("item_id", ""))
    var item_type := str(definition.get("type", ""))
    if item_type not in ITEM_TYPES:
        return _definition_fail("Item type '%s' is not supported" % item_type, item_id)
    for boolean_field: String in ["stackable", "sellable", "discardable", "unique", "quest_critical"]:
        if not definition.get(boolean_field) is bool:
            return _definition_fail("Item field '%s' must be boolean" % boolean_field, item_id)
    if not _is_integer_value(definition.get("max_stack")) or int(definition["max_stack"]) < 1:
        return _definition_fail("Item max_stack must be a positive integer", item_id)
    if not bool(definition["stackable"]) and int(definition["max_stack"]) != 1:
        return _definition_fail("Non-stackable items must use max_stack=1", item_id)
    if bool(definition["unique"]) and int(definition["max_stack"]) != 1:
        return _definition_fail("Unique items must use max_stack=1", item_id)
    if item_type == "consumable" and int(definition["max_stack"]) > 20:
        return _definition_fail("Consumable max_stack cannot exceed 20", item_id)
    if item_type == "material" and int(definition["max_stack"]) > 99:
        return _definition_fail("Material max_stack cannot exceed 99", item_id)
    if str(definition.get("storage", "")) not in ["normal", "quest"]:
        return _definition_fail("Item storage must be normal or quest", item_id)
    if str(definition.get("overflow_policy", "")) not in ["reject", "custody"]:
        return _definition_fail("Item overflow policy is invalid", item_id)
    if bool(definition["quest_critical"]):
        if bool(definition["sellable"]) or bool(definition["discardable"]):
            return _definition_fail("Quest-critical items cannot be sold or discarded", item_id)
        if str(definition["overflow_policy"]) != "custody":
            return _definition_fail("Quest-critical items must use custody overflow", item_id)
    if not definition.get("compatible_slots") is Array or not definition.get("occupies_slots") is Array:
        return _definition_fail("Equipment slot declarations must be arrays", item_id)
    var compatible_slots: Array = definition["compatible_slots"]
    var occupies_slots: Array = definition["occupies_slots"]
    if compatible_slots.size() != _unique_strings(compatible_slots).size() or occupies_slots.size() != _unique_strings(occupies_slots).size():
        return _definition_fail("Equipment slot declarations cannot contain duplicates", item_id)
    for slot: Variant in compatible_slots + occupies_slots:
        if not slot is String or str(slot) not in EQUIPMENT_SLOTS:
            return _definition_fail("Equipment slot declaration is invalid", item_id)
    if item_type == "equipment":
        var primary: Variant = definition.get("equipment_slot")
        if not primary is String or str(primary) not in EQUIPMENT_SLOTS:
            return _definition_fail("Equipment item must declare a valid primary slot", item_id)
        if str(primary) not in compatible_slots or str(primary) not in occupies_slots:
            return _definition_fail("Equipment primary slot must be compatible and occupied", item_id)
        if occupies_slots.size() > 1 and _string_set(occupies_slots) != {"weapon": true, "off_hand": true}:
            return _definition_fail("Multi-slot equipment may only occupy weapon and off_hand", item_id)
        if bool(definition["stackable"]) or int(definition["max_stack"]) != 1:
            return _definition_fail("Equipment must be non-stackable", item_id)
        if str(definition["storage"]) != "normal":
            return _definition_fail("Equipment must use normal storage", item_id)
    else:
        if definition.get("equipment_slot") != null or not compatible_slots.is_empty() or not occupies_slots.is_empty():
            return _definition_fail("Non-equipment items cannot declare equipment slots", item_id)
    if item_type == "quest" and str(definition["storage"]) != "quest":
        return _definition_fail("Quest items must use quest storage", item_id)
    if not definition.get("stat_modifiers") is Array:
        return _definition_fail("stat_modifiers must be an array", item_id)
    for raw_modifier: Variant in definition["stat_modifiers"]:
        if (
            not raw_modifier is Dictionary
            or str(raw_modifier.get("stat", "")).is_empty()
            or not _is_number(raw_modifier.get("value"))
        ):
            return _definition_fail("Every stat modifier needs a stat and numeric value", item_id)
    if not definition.get("use_effects") is Array:
        return _definition_fail("use_effects must be an array", item_id)
    for raw_effect: Variant in definition["use_effects"]:
        if not raw_effect is Dictionary:
            return _definition_fail("Every use effect must be an object", item_id)
        var key := str(raw_effect.get("key", ""))
        if str(raw_effect.get("op", "")) not in ["set", "inc", "dec"] or key.is_empty():
            return _definition_fail("Use effect is missing a supported op or key", item_id)
        if not bool(_game_state.call("has_state", key)):
            return _definition_fail("Use effect references unknown GameState key '%s'" % key, item_id)
        if not _state_allows_inventory_write(key):
            return _definition_fail("Use effect state '%s' does not allow inventory writes" % key, item_id)
    if str(definition.get("use_context", "")) not in USE_CONTEXTS:
        return _definition_fail("Item use_context is invalid", item_id)
    var ownership_key := str(definition.get("ownership_state_key", ""))
    if not ownership_key.is_empty():
        if not bool(_game_state.call("has_state", ownership_key)):
            return _definition_fail("Item ownership state key is not registered", item_id)
        if not _game_state.call("get_state", ownership_key) is bool:
            return _definition_fail("Item ownership state key must be boolean", item_id)
        if not _state_allows_inventory_write(ownership_key):
            return _definition_fail("Item ownership state key does not allow inventory writes", item_id)
    return true


func _validate_snapshot_data(snapshot: Dictionary) -> bool:
    var required := ["snapshot_version", "capacity", "backpack", "quest_items", "equipment", "custody"]
    if snapshot.size() != required.size():
        return _snapshot_fail("Inventory snapshot contains missing or unknown fields")
    for key: String in required:
        if not snapshot.has(key):
            return _snapshot_fail("Inventory snapshot is missing '%s'" % key)
    if not _is_integer_value(snapshot["snapshot_version"]) or int(snapshot["snapshot_version"]) != SNAPSHOT_VERSION:
        return _snapshot_fail("Inventory snapshot version is unsupported")
    if not _is_integer_value(snapshot["capacity"]):
        return _snapshot_fail("Inventory snapshot capacity must be an integer")
    var snapshot_capacity := int(snapshot["capacity"])
    if snapshot_capacity < 1 or snapshot_capacity > MAX_SUPPORTED_CAPACITY or snapshot_capacity != _capacity:
        return _snapshot_fail("Inventory snapshot capacity does not match the configured fixed capacity")
    for container_name: String in ["backpack", "quest_items", "custody"]:
        if not snapshot[container_name] is Array:
            return _snapshot_fail("Inventory snapshot '%s' must be an array" % container_name)
    if snapshot["backpack"].size() > snapshot_capacity:
        return _snapshot_fail("Inventory snapshot exceeds backpack capacity")

    var total_counts := {}
    for container_name: String in ["backpack", "quest_items", "custody"]:
        var container: Array = snapshot[container_name]
        for raw_entry: Variant in container:
            if not raw_entry is Dictionary or raw_entry.size() != 2 or not raw_entry.has("item_id") or not raw_entry.has("quantity"):
                return _snapshot_fail("Inventory container entry has an invalid shape")
            var item_id := str(raw_entry.get("item_id", ""))
            if not _definitions.has(item_id):
                return _snapshot_fail("Inventory snapshot references unknown item '%s'" % item_id, item_id)
            var raw_quantity: Variant = raw_entry.get("quantity")
            if not _is_integer_value(raw_quantity) or int(raw_quantity) <= 0:
                return _snapshot_fail("Inventory stack quantity must be a positive integer", item_id)
            var quantity := int(raw_quantity)
            var definition: Dictionary = _definitions[item_id]
            if quantity > int(definition["max_stack"]) or (not bool(definition["stackable"]) and quantity != 1):
                return _snapshot_fail("Inventory stack exceeds its item definition", item_id)
            if container_name == "backpack" and str(definition["storage"]) != "normal":
                return _snapshot_fail("Quest-storage item cannot appear in the normal backpack", item_id)
            if container_name == "quest_items" and str(definition["storage"]) != "quest":
                return _snapshot_fail("Normal-storage item cannot appear in quest storage", item_id)
            if container_name == "custody" and not bool(definition["quest_critical"]):
                return _snapshot_fail("Only quest-critical items may appear in custody", item_id)
            total_counts[item_id] = int(total_counts.get(item_id, 0)) + quantity

    if not snapshot["equipment"] is Dictionary:
        return _snapshot_fail("Inventory equipment snapshot must be an object")
    var equipment: Dictionary = snapshot["equipment"]
    if equipment.size() != EQUIPMENT_SLOTS.size():
        return _snapshot_fail("Inventory equipment snapshot must contain exactly six slots")
    var equipped_anchors := {}
    for slot: String in EQUIPMENT_SLOTS:
        if not equipment.has(slot):
            return _snapshot_fail("Inventory equipment snapshot is missing slot '%s'" % slot)
        var raw_equipped: Variant = equipment[slot]
        if raw_equipped == null:
            continue
        if (
            not raw_equipped is Dictionary
            or raw_equipped.size() != 2
            or not raw_equipped.has("item_id")
            or not raw_equipped.has("anchor_slot")
        ):
            return _snapshot_fail("Equipped item entry has an invalid shape")
        var item_id := str(raw_equipped.get("item_id", ""))
        var anchor := str(raw_equipped.get("anchor_slot", ""))
        if not _definitions.has(item_id) or str(_definitions[item_id]["type"]) != "equipment":
            return _snapshot_fail("Equipment snapshot references a non-equipment item", item_id)
        var definition: Dictionary = _definitions[item_id]
        if anchor not in EQUIPMENT_SLOTS or anchor not in definition["compatible_slots"]:
            return _snapshot_fail("Equipped item anchor is incompatible", item_id)
        if slot not in _occupied_slots_for(definition, anchor):
            return _snapshot_fail("Equipped item occupies an undeclared slot", item_id)
        if equipped_anchors.has(anchor) and str(equipped_anchors[anchor]) != item_id:
            return _snapshot_fail("Equipment anchor contains conflicting items", item_id)
        equipped_anchors[anchor] = item_id
    for raw_anchor: Variant in equipped_anchors.keys():
        var anchor := str(raw_anchor)
        var item_id := str(equipped_anchors[anchor])
        for occupied_slot: String in _occupied_slots_for(_definitions[item_id], anchor):
            var entry: Variant = equipment.get(occupied_slot)
            if (
                not entry is Dictionary
                or str(entry.get("item_id", "")) != item_id
                or str(entry.get("anchor_slot", "")) != anchor
            ):
                return _snapshot_fail("Multi-slot equipment snapshot is incomplete", item_id)
        total_counts[item_id] = int(total_counts.get(item_id, 0)) + 1
    for raw_item_id: Variant in total_counts.keys():
        var item_id := str(raw_item_id)
        if bool(_definitions[item_id]["unique"]) and int(total_counts[item_id]) > 1:
            return _snapshot_fail("Unique item appears more than once", item_id)
    last_error = {}
    return true


func _normalize_snapshot(snapshot: Dictionary) -> Dictionary:
    var normalized := snapshot.duplicate(true)
    normalized["snapshot_version"] = int(normalized["snapshot_version"])
    normalized["capacity"] = int(normalized["capacity"])
    for container_name: String in ["backpack", "quest_items", "custody"]:
        for index: int in range(normalized[container_name].size()):
            normalized[container_name][index]["quantity"] = int(normalized[container_name][index]["quantity"])
    return normalized


func _load_snapshot_unchecked(snapshot: Dictionary) -> void:
    _capacity = int(snapshot["capacity"])
    _backpack = snapshot["backpack"].duplicate(true)
    _quest_items = snapshot["quest_items"].duplicate(true)
    _equipment = snapshot["equipment"].duplicate(true)
    _custody = snapshot["custody"].duplicate(true)


func _commit_candidate(
    candidate: Dictionary,
    source: String,
    extra_effects: Array = [],
    failure_code: String = INVENTORY_STATE_WRITE_FAILED,
) -> Dictionary:
    if _mutation_in_progress:
        return _fail(INVENTORY_MUTATION_IN_PROGRESS, "Inventory mutation is already in progress")
    _mutation_in_progress = true
    if not _validate_snapshot_data(candidate):
        _mutation_in_progress = false
        return last_error.duplicate(true)
    var normalized := _normalize_snapshot(candidate)
    var previous := export_snapshot()
    var effects: Array = extra_effects.duplicate(true)
    effects.append_array(_ownership_effects_for_snapshot(normalized))
    if not effects.is_empty() and not bool(_game_state.call("apply_effects", effects, _state_source(source))):
        _mutation_in_progress = false
        return _fail(failure_code, "GameState rejected an atomic inventory update", "", {
            "details": _game_state.get("last_error"),
        })
    _load_snapshot_unchecked(normalized)
    var changed := previous != normalized
    _mutation_in_progress = false
    last_error = {}
    if changed:
        inventory_changed.emit({
            "ok": true,
            "code": "OK",
            "message": "Inventory changed",
            "source": source,
            "old_snapshot": previous,
            "new_snapshot": normalized.duplicate(true),
        })
    return _result(true, "OK", "Inventory transaction committed", "", {"changed": changed})


func _grant_to_candidate(candidate: Dictionary, definition: Dictionary, quantity: int) -> Dictionary:
    if str(definition["storage"]) == "quest":
        var quest_result := _add_to_container(candidate["quest_items"], definition, quantity, -1)
        return {
            "ok": bool(quest_result.get("ok", false)),
            "code": INVENTORY_FULL,
            "message": "Quest storage rejected an item",
            "backpack": 0,
            "quest": quantity - int(quest_result.get("remaining", 0)),
            "custody": 0,
        }
    var backpack_result := _add_to_container(candidate["backpack"], definition, quantity, int(candidate["capacity"]))
    var remaining := int(backpack_result.get("remaining", 0))
    if remaining == 0:
        return {"ok": true, "backpack": quantity, "quest": 0, "custody": 0}
    if bool(definition["quest_critical"]) and str(definition["overflow_policy"]) == "custody":
        var custody_result := _add_to_container(candidate["custody"], definition, remaining, -1)
        if not bool(custody_result.get("ok", false)):
            return {"ok": false, "code": INVENTORY_FULL, "message": "Critical item could not enter custody"}
        return {
            "ok": true,
            "backpack": quantity - remaining,
            "quest": 0,
            "custody": remaining,
        }
    return {"ok": false, "code": INVENTORY_FULL, "message": "Backpack does not have enough free slots"}


func _add_to_container(container: Array, definition: Dictionary, quantity: int, max_slots: int) -> Dictionary:
    var item_id := str(definition["item_id"])
    var remaining := quantity
    if bool(definition["stackable"]):
        for index: int in range(container.size()):
            var entry: Dictionary = container[index]
            if str(entry.get("item_id", "")) != item_id:
                continue
            var space := int(definition["max_stack"]) - int(entry.get("quantity", 0))
            if space <= 0:
                continue
            var added := mini(space, remaining)
            entry["quantity"] = int(entry.get("quantity", 0)) + added
            container[index] = entry
            remaining -= added
            if remaining == 0:
                break
    while remaining > 0:
        if max_slots >= 0 and container.size() >= max_slots:
            return {"ok": false, "remaining": remaining}
        var stack_quantity := mini(int(definition["max_stack"]), remaining) if bool(definition["stackable"]) else 1
        container.append({"item_id": item_id, "quantity": stack_quantity})
        remaining -= stack_quantity
    return {"ok": true, "remaining": 0}


func _remove_from_container(container: Array, item_id: String, quantity: int) -> void:
    var remaining := quantity
    for index: int in range(container.size() - 1, -1, -1):
        if str(container[index].get("item_id", "")) != item_id:
            continue
        var available := int(container[index].get("quantity", 0))
        var removed := mini(available, remaining)
        available -= removed
        remaining -= removed
        if available == 0:
            container.remove_at(index)
        else:
            container[index]["quantity"] = available
        if remaining == 0:
            return


func _sum_container(container: Array, item_id: String) -> int:
    var quantity := 0
    for raw_entry: Variant in container:
        if raw_entry is Dictionary and str(raw_entry.get("item_id", "")) == item_id:
            quantity += int(raw_entry.get("quantity", 0))
    return quantity


func _quantity_in_runtime(item_id: String, scope: String) -> int:
    var quantity := 0
    if scope in ["all", "backpack"]:
        quantity += _sum_container(_backpack, item_id)
    if scope in ["all", "quest"]:
        quantity += _sum_container(_quest_items, item_id)
    if scope in ["all", "custody"]:
        quantity += _sum_container(_custody, item_id)
    if scope in ["all", "equipped"]:
        quantity += _equipped_instance_count(_equipment, item_id)
    return quantity


func _quantity_in_snapshot(snapshot: Dictionary, item_id: String, scope: String) -> int:
    var quantity := 0
    if scope in ["all", "backpack"]:
        quantity += _sum_container(snapshot["backpack"], item_id)
    if scope in ["all", "quest"]:
        quantity += _sum_container(snapshot["quest_items"], item_id)
    if scope in ["all", "custody"]:
        quantity += _sum_container(snapshot["custody"], item_id)
    if scope in ["all", "equipped"]:
        quantity += _equipped_instance_count(snapshot["equipment"], item_id)
    return quantity


func _equipped_instance_count(equipment: Dictionary, item_id: String) -> int:
    var anchors := {}
    for raw_entry: Variant in equipment.values():
        if raw_entry is Dictionary and str(raw_entry.get("item_id", "")) == item_id:
            anchors[str(raw_entry.get("anchor_slot", ""))] = true
    return anchors.size()


func _occupied_slots_for(definition: Dictionary, target_slot: String) -> Array[String]:
    var declared: Array = definition.get("occupies_slots", [])
    if declared.size() <= 1:
        return [target_slot]
    var result: Array[String] = []
    for raw_slot: Variant in declared:
        result.append(str(raw_slot))
    return result


func _clear_equipped_anchor(equipment: Dictionary, anchor_slot: String) -> void:
    for slot: String in EQUIPMENT_SLOTS:
        var entry: Variant = equipment.get(slot)
        if entry is Dictionary and str(entry.get("anchor_slot", "")) == anchor_slot:
            equipment[slot] = null


func _ownership_effects_for_snapshot(snapshot: Dictionary) -> Array:
    var effects: Array = []
    for raw_definition: Variant in _definitions.values():
        var definition: Dictionary = raw_definition
        var ownership_key := str(definition.get("ownership_state_key", ""))
        if ownership_key.is_empty():
            continue
        var desired := _quantity_in_snapshot(snapshot, str(definition["item_id"]), "all") > 0
        if _game_state.call("get_state", ownership_key) != desired:
            effects.append({"op": "set", "key": ownership_key, "value": desired})
    return effects


func _sync_ownership_flags(snapshot: Dictionary, source: String) -> bool:
    var effects := _ownership_effects_for_snapshot(snapshot)
    if effects.is_empty():
        return true
    if bool(_game_state.call("apply_effects", effects, _state_source(source))):
        return true
    _record_error(INVENTORY_STATE_WRITE_FAILED, "GameState rejected inventory ownership synchronization", "", {
        "details": _game_state.get("last_error"),
    })
    return false


func _state_source(source: String) -> String:
    return "save_restore" if source == "save_restore" else "inventory"


func _state_allows_inventory_write(key: String) -> bool:
    if not _state_definitions.has(key):
        return false
    var definition: Dictionary = _state_definitions[key]
    if bool(definition.get("read_only", false)):
        return false
    var write_sources: Variant = definition.get("write_sources", [])
    return write_sources is Array and (write_sources.is_empty() or "inventory" in write_sources)


func _append_placement(target: Array, item_id: String, quantity: int) -> void:
    if quantity > 0:
        target.append({"item_id": item_id, "quantity": quantity})


func _empty_snapshot() -> Dictionary:
    return {
        "snapshot_version": SNAPSHOT_VERSION,
        "capacity": _capacity,
        "backpack": [],
        "quest_items": [],
        "equipment": _empty_equipment(),
        "custody": [],
    }


func _empty_equipment() -> Dictionary:
    var equipment := {}
    for slot: String in EQUIPMENT_SLOTS:
        equipment[slot] = null
    return equipment


func _unique_strings(values: Array) -> Array[String]:
    var seen := {}
    var result: Array[String] = []
    for value: Variant in values:
        var text := str(value)
        if not seen.has(text):
            seen[text] = true
            result.append(text)
    return result


func _string_set(values: Array) -> Dictionary:
    var result := {}
    for value: Variant in values:
        result[str(value)] = true
    return result


func _is_number(value: Variant) -> bool:
    return value is int or value is float


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and value == floor(value))


func _require_initialized() -> bool:
    if _initialized:
        return true
    _record_error(INVENTORY_NOT_INITIALIZED, "InventoryManager has not been initialized")
    return false


func _require_initialized_bool() -> bool:
    return _require_initialized()


func _require_item(item_id: String) -> bool:
    if not _require_initialized():
        return false
    if _definitions.has(item_id):
        last_error = {}
        return true
    _record_error(ITEM_NOT_FOUND, "Unknown item '%s'" % item_id, item_id)
    return false


func _initialize_fail(message: String, item_id: String = "") -> bool:
    _record_error(INVENTORY_DEFINITION_INVALID, message, item_id)
    _initialized = false
    return false


func _definition_fail(message: String, item_id: String = "") -> bool:
    _record_error(INVENTORY_DEFINITION_INVALID, message, item_id)
    return false


func _snapshot_fail(message: String, item_id: String = "") -> bool:
    _record_error(INVENTORY_SNAPSHOT_INVALID, message, item_id)
    return false


func _checkpoint_fail(message: String) -> bool:
    _record_error(INVENTORY_RESTORE_FAILED, message)
    return false


func _fail(code: String, message: String, item_id: String = "", extra: Dictionary = {}) -> Dictionary:
    return _record_error(code, message, item_id, extra)


func _record_error(code: String, message: String, item_id: String = "", extra: Dictionary = {}) -> Dictionary:
    var error := _result(false, code, message, item_id, extra)
    last_error = error.duplicate(true)
    printerr("INVENTORY_ERROR:%s:%s:%s" % [code, item_id, message])
    inventory_error.emit(error.duplicate(true))
    return error


func _result(ok: bool, code: String, message: String, item_id: String = "", extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "code": code, "message": message, "item_id": item_id}
    result.merge(extra, true)
    return result


func _clear_runtime() -> void:
    _content_loader = null
    _game_state = null
    _definitions = {}
    _state_definitions = {}
    _capacity = DEFAULT_CAPACITY
    _backpack = []
    _quest_items = []
    _custody = []
    _equipment = {}
    _initialized = false
    _mutation_in_progress = false
    last_error = {}
