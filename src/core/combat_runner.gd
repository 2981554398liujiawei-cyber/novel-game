extends RefCounted

signal precombat_checkpoint_requested(request: Dictionary)
signal combat_started(payload: Dictionary)
signal round_started(payload: Dictionary)
signal turn_started(payload: Dictionary)
signal action_resolved(result: Dictionary)
signal unit_damaged(payload: Dictionary)
signal unit_healed(payload: Dictionary)
signal status_applied(payload: Dictionary)
signal unit_defeated(payload: Dictionary)
signal phase_changed(payload: Dictionary)
signal combat_finished(result: Dictionary)
signal combat_error(error: Dictionary)

const CombatRngClass = preload("res://src/core/combat_rng.gd")
const CombatAiControllerClass = preload("res://src/core/combat_ai_controller.gd")

const SNAPSHOT_VERSION := 1
const ACTION_TYPES := ["attack", "defend", "skill", "item", "inspect", "retreat"]
const RESULT_TYPES := ["victory", "defeat", "retreat", "partial_success"]
const COMPANION_TENDENCIES := ["offensive", "defensive", "support"]

const COMBAT_NOT_INITIALIZED := "COMBAT_NOT_INITIALIZED"
const COMBAT_ALREADY_ACTIVE := "COMBAT_ALREADY_ACTIVE"
const COMBAT_NOT_ACTIVE := "COMBAT_NOT_ACTIVE"
const COMBAT_NOT_FOUND := "COMBAT_NOT_FOUND"
const COMBAT_NOT_RUNTIME_READY := "COMBAT_NOT_RUNTIME_READY"
const COMBAT_DEFINITION_INVALID := "COMBAT_DEFINITION_INVALID"
const COMBAT_CHECKPOINT_FAILED := "COMBAT_CHECKPOINT_FAILED"
const COMBAT_ACTION_INVALID := "COMBAT_ACTION_INVALID"
const COMBAT_ACTOR_INVALID := "COMBAT_ACTOR_INVALID"
const COMBAT_ACTOR_CONTROL_FORBIDDEN := "COMBAT_ACTOR_CONTROL_FORBIDDEN"
const COMBAT_TARGET_INVALID := "COMBAT_TARGET_INVALID"
const COMBAT_TURN_LIMIT := "COMBAT_TURN_LIMIT"
const COMBAT_SNAPSHOT_INVALID := "COMBAT_SNAPSHOT_INVALID"
const COMBAT_PERSISTENCE_FORBIDDEN := "COMBAT_PERSISTENCE_FORBIDDEN"
const COMBAT_STATE_EFFECT_FAILED := "COMBAT_STATE_EFFECT_FAILED"
const SKILL_NOT_FOUND := "SKILL_NOT_FOUND"
const SKILL_UNAVAILABLE := "SKILL_UNAVAILABLE"
const SKILL_COOLDOWN := "SKILL_COOLDOWN"
const SKILL_USES_EXHAUSTED := "SKILL_USES_EXHAUSTED"
const ITEM_USE_FAILED := "ITEM_USE_FAILED"
const INSPECT_TARGET_INVALID := "INSPECT_TARGET_INVALID"
const RETREAT_FORBIDDEN := "RETREAT_FORBIDDEN"
const COMPANION_TENDENCY_INVALID := "COMPANION_TENDENCY_INVALID"

const DEFAULT_RULES := {
    "initiative_random_min": 0,
    "initiative_random_max": 3,
    "damage_variance_min": 0.85,
    "damage_variance_max": 1.15,
    "defense_multiplier": 0.6,
    "minimum_damage": 1,
    "critical_multiplier": 1.5,
    "guard_status_id": "guard",
    "guard_damage_reduction": 0.4,
    "max_rounds": 100,
    "retreat_base_chance": 0.5,
    "retreat_agility_factor": 0.05,
    "retreat_min_chance": 0.1,
    "retreat_max_chance": 0.9,
    "retreat_boss_penalty": 0.25,
}

var last_error: Dictionary = {}

var _content_loader: RefCounted
var _game_state: RefCounted
var _inventory_manager: RefCounted
var _save_manager: RefCounted
var _combats: Dictionary = {}
var _enemies: Dictionary = {}
var _skills: Dictionary = {}
var _status_definitions: Dictionary = {}
var _rules: Dictionary = DEFAULT_RULES.duplicate(true)
var _runtime: Dictionary = {}
var _last_result: Dictionary = {}
var _initialized := false
var _active := false
var _rng := CombatRngClass.new()
var _ai_controller := CombatAiControllerClass.new()


func initialize(
    content_loader: RefCounted,
    game_state: RefCounted,
    inventory_manager: RefCounted = null,
) -> bool:
    _clear_all()
    if content_loader == null:
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "ContentLoader is required")
    for method_name: String in [
        "get_combat_definitions", "get_enemy_definitions", "get_skill_definitions",
        "get_combat_runtime_registry",
    ]:
        if not content_loader.has_method(method_name):
            return _initialize_fail(
                COMBAT_DEFINITION_INVALID,
                "ContentLoader does not provide '%s'" % method_name,
            )
    if game_state == null:
        return _initialize_fail(COMBAT_STATE_EFFECT_FAILED, "GameState is required")
    for method_name: String in [
        "evaluate_condition", "apply_effects", "create_runtime_checkpoint",
        "restore_runtime_checkpoint",
    ]:
        if not game_state.has_method(method_name):
            return _initialize_fail(
                COMBAT_STATE_EFFECT_FAILED,
                "GameState does not provide '%s'" % method_name,
            )
    if inventory_manager != null:
        for method_name: String in [
            "get_stat_modifiers", "get_item_definition", "use_item",
            "create_runtime_checkpoint", "restore_runtime_checkpoint",
        ]:
            if not inventory_manager.has_method(method_name):
                return _initialize_fail(
                    COMBAT_DEFINITION_INVALID,
                    "InventoryManager does not provide '%s'" % method_name,
                )

    _content_loader = content_loader
    _game_state = game_state
    _inventory_manager = inventory_manager
    if not _index_definitions(content_loader.call("get_combat_definitions"), "combat_id", _combats):
        return false
    if not _index_definitions(content_loader.call("get_enemy_definitions"), "enemy_id", _enemies):
        return false
    if not _index_definitions(content_loader.call("get_skill_definitions"), "skill_id", _skills):
        return false

    var registry: Variant = content_loader.call("get_combat_runtime_registry")
    if registry is Dictionary:
        _rules = _merged_dictionary(DEFAULT_RULES, registry.get("rules", {}))
        for raw_status: Variant in registry.get("status_definitions", []):
            if not raw_status is Dictionary:
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Combat status definition must be an object")
            var status_id := str(raw_status.get("status_id", ""))
            if status_id.is_empty() or _status_definitions.has(status_id):
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Combat status IDs must be non-empty and unique")
            _status_definitions[status_id] = raw_status.duplicate(true)
    if not _validate_rule_values():
        return false
    if not _validate_runtime_definitions():
        return false
    _initialized = true
    last_error = {}
    return true


func bind_save_manager(save_manager: RefCounted) -> bool:
    if not _require_initialized_bool():
        return false
    if save_manager == null:
        if _save_manager != null and _save_manager.has_method("set_runtime_guard"):
            _save_manager.call("set_runtime_guard", null)
        _save_manager = null
        return true
    for method_name: String in [
        "get_random_state", "set_random_state", "create_precombat_checkpoint", "set_runtime_guard",
    ]:
        if not save_manager.has_method(method_name):
            _record_error(COMBAT_CHECKPOINT_FAILED, "SaveManager does not provide '%s'" % method_name)
            return false
    var guard_result: Variant = save_manager.call("set_runtime_guard", self)
    if not guard_result is Dictionary or not bool(guard_result.get("ok", false)):
        _record_error(COMBAT_CHECKPOINT_FAILED, "SaveManager rejected the CombatRunner persistence guard")
        return false
    if _save_manager != null and _save_manager != save_manager:
        _save_manager.call("set_runtime_guard", null)
    _save_manager = save_manager
    return true


func start_combat(combat_id: String, seed: int) -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    if _active:
        return _fail(COMBAT_ALREADY_ACTIVE, "A combat is already active", combat_id)
    if not _combats.has(combat_id):
        return _fail(COMBAT_NOT_FOUND, "Unknown combat ID", combat_id)
    var combat: Dictionary = _combats[combat_id]
    if not combat.get("runtime") is Dictionary:
        return _fail(
            COMBAT_NOT_RUNTIME_READY,
            "Combat definition has no executable runtime contract",
            combat_id,
        )
    var candidate_result := _build_runtime(combat, seed)
    if not bool(candidate_result.get("ok", false)):
        return candidate_result
    var checkpoint_result := _create_precombat_checkpoint(combat_id, seed)
    if not bool(checkpoint_result.get("ok", false)):
        return checkpoint_result

    _runtime = candidate_result["runtime"]
    if not _rng.restore_state(_runtime["rng"]):
        _runtime = {}
        return _fail(COMBAT_DEFINITION_INVALID, "Initial random state could not be restored", combat_id)
    _active = true
    _last_result = {}
    last_error = {}
    combat_started.emit({
        "combat_id": combat_id,
        "seed": int(_runtime["rng"]["seed"]),
        "units": _public_units(),
    })
    _activate_start_phase()
    if not _active:
        return _last_result.duplicate(true)
    _begin_round()
    if not _active and not _last_result.is_empty():
        return _result(true, "OK", "Combat finished during initialization", combat_id, {
            "combat_result": _last_result.duplicate(true),
        })
    return _result(true, "OK", "Combat started", combat_id, {
        "current_actor": get_current_actor(),
        "round": get_round(),
    })


func is_active() -> bool:
    return _active


func get_round() -> int:
    return int(_runtime.get("round", 0)) if _active else 0


func get_current_actor() -> Dictionary:
    if not _active:
        return {}
    var order: Array = _runtime.get("turn_order", [])
    var index := int(_runtime.get("turn_index", -1))
    if index < 0 or index >= order.size():
        return {}
    var unit_id := str(order[index])
    return get_unit_state(unit_id)


func get_next_actor() -> Dictionary:
    if not _active:
        return {}
    var order: Array = _runtime.get("turn_order", [])
    var start := int(_runtime.get("turn_index", -1)) + 1
    for index: int in range(start, order.size()):
        var unit_id := str(order[index])
        if _unit_can_take_turn(unit_id):
            return get_unit_state(unit_id)
    return {}


func get_action_order() -> Array:
    return _runtime.get("turn_order", []).duplicate(true) if _active else []


func get_unit_state(unit_id: String) -> Dictionary:
    if not _active or not _runtime.get("units", {}).has(unit_id):
        return {}
    return _runtime["units"][unit_id].duplicate(true)


func get_last_result() -> Dictionary:
    return _last_result.duplicate(true)


func get_persistence_policy(operation: String) -> Dictionary:
    if _active and operation in ["save", "auto_save", "quick_save", "load", "restore_backup"]:
        return {
            "allowed": false,
            "code": COMBAT_PERSISTENCE_FORBIDDEN,
            "message": "Persistence is disabled while combat is active; use the precombat checkpoint",
            "operation": operation,
            "combat_id": str(_runtime.get("combat_id", "")),
        }
    return {"allowed": true, "code": "OK", "message": "Persistence is allowed", "operation": operation}


func set_companion_tendency(tendency: String) -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    if tendency not in COMPANION_TENDENCIES:
        return _fail(COMPANION_TENDENCY_INVALID, "Unknown companion tendency '%s'" % tendency)
    var actor := get_current_actor()
    if str(actor.get("role", "")) != "player":
        return _fail(COMPANION_TENDENCY_INVALID, "Companion tendency can only be set during the player turn")
    var round_number := int(_runtime["round"])
    if int(_runtime.get("tendency_set_round", -1)) == round_number:
        return _fail(COMPANION_TENDENCY_INVALID, "Companion tendency was already set this round")
    _runtime["companion_tendency"] = tendency
    _runtime["tendency_set_round"] = round_number
    return _result(true, "OK", "Companion tendency updated", "", {
        "tendency": tendency,
        "round": round_number,
    })


func get_companion_action_weights(unit_id: String, tendency: String) -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    if tendency not in COMPANION_TENDENCIES:
        return _fail(COMPANION_TENDENCY_INVALID, "Unknown companion tendency '%s'" % tendency)
    var unit: Variant = _runtime["units"].get(unit_id)
    if not unit is Dictionary or str(unit.get("role", "")) != "companion":
        return _fail(COMBAT_ACTOR_INVALID, "Unit is not an active companion", unit_id)
    var filter := func(action: Dictionary) -> bool:
        return _ai_action_conditions_met(unit_id, action) and _ai_action_is_usable(unit_id, action)
    var weights: Dictionary = _ai_controller.build_weights(_ai_actions_with_phase_weights(unit_id), tendency, filter)
    return _result(true, "OK", "Companion action weights queried", unit_id, {"weights": weights})


func perform_action(command: Dictionary) -> Dictionary:
    return _perform_action_internal(command, false)


func _perform_action_internal(command: Dictionary, automatic_control: bool) -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    var action_type := str(command.get("type", ""))
    if action_type not in ACTION_TYPES:
        return _fail(COMBAT_ACTION_INVALID, "Unknown combat action '%s'" % action_type)
    var current := get_current_actor()
    var actor_id := str(command.get("actor_id", current.get("unit_id", "")))
    if actor_id.is_empty() or actor_id != str(current.get("unit_id", "")):
        return _fail(COMBAT_ACTOR_INVALID, "Action actor is not the current unit", actor_id)
    var role := str(current.get("role", ""))
    if not automatic_control and role != "player":
        return _fail(
            COMBAT_ACTOR_CONTROL_FORBIDDEN,
            "Companion and enemy turns must be resolved by the data-driven AI controller",
            actor_id,
        )
    if automatic_control and role not in ["companion", "enemy"]:
        return _fail(COMBAT_ACTOR_CONTROL_FORBIDDEN, "Player turns cannot be resolved as automatic AI turns", actor_id)
    if not _unit_can_act(actor_id):
        return _fail(COMBAT_ACTOR_INVALID, "Current unit cannot act", actor_id)

    var runtime_checkpoint: Dictionary = _runtime.duplicate(true)
    var rng_checkpoint: Dictionary = _rng.export_state()
    var state_checkpoint: Dictionary = _game_state.call("create_runtime_checkpoint")
    var resolution: Dictionary
    match action_type:
        "attack":
            resolution = _resolve_attack(actor_id, str(command.get("target_id", "")), 1.0, 0.0)
        "defend":
            resolution = _resolve_defend(actor_id)
        "skill":
            resolution = _resolve_skill(actor_id, str(command.get("skill_id", "")), str(command.get("target_id", "")))
        "item":
            resolution = _resolve_item(actor_id, str(command.get("item_id", "")), str(command.get("target_id", actor_id)))
        "inspect":
            resolution = _resolve_inspect(actor_id, str(command.get("target_id", "")))
        "retreat":
            resolution = _resolve_retreat(actor_id)
        _:
            resolution = _fail(COMBAT_ACTION_INVALID, "Unsupported combat action")
    if not bool(resolution.get("ok", false)):
        _runtime = runtime_checkpoint
        _rng.restore_state(rng_checkpoint)
        _game_state.call("restore_runtime_checkpoint", state_checkpoint)
        return resolution

    var pending_finish: Dictionary = resolution.get("_pending_finish", {}).duplicate(true)
    resolution.erase("_pending_finish")
    _runtime["rng"] = _rng.export_state()
    _runtime["actions_elapsed"] = int(_runtime.get("actions_elapsed", 0)) + 1
    resolution["action_type"] = action_type
    resolution["actor_id"] = actor_id
    resolution["round"] = int(_runtime["round"])
    action_resolved.emit(resolution.duplicate(true))

    if not pending_finish.is_empty():
        _finish_combat(
            str(pending_finish.get("result_type", "retreat")),
            str(pending_finish.get("continuation_tag", "")),
            str(pending_finish.get("event_tag", "retreat_success")),
        )
    if _active:
        _check_end_conditions()
    if _active:
        _check_phase_transitions("")
    if _active:
        _advance_turn()
    if not _active and not _last_result.is_empty():
        resolution["combat_result"] = _last_result.duplicate(true)
    return resolution


func run_auto_turn() -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    var actor := get_current_actor()
    var role := str(actor.get("role", ""))
    if role not in ["companion", "enemy"]:
        return _fail(COMBAT_ACTOR_INVALID, "Current actor is controlled by the player", str(actor.get("unit_id", "")))
    var rng_checkpoint := _rng.export_state()
    var runtime_rng_checkpoint: Dictionary = _runtime.get("rng", {}).duplicate(true)
    var command := _choose_ai_command(str(actor["unit_id"]))
    if command.is_empty():
        return _fail(COMBAT_ACTION_INVALID, "No legal AI action is available", str(actor.get("unit_id", "")))
    var result := _perform_action_internal(command, true)
    if not bool(result.get("ok", false)):
        _rng.restore_state(rng_checkpoint)
        _runtime["rng"] = runtime_rng_checkpoint
    return result


func run_until_player_turn(max_actions: int = 64) -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    var resolved := 0
    while _active and str(get_current_actor().get("role", "")) != "player" and resolved < max_actions:
        var result := run_auto_turn()
        if not bool(result.get("ok", false)):
            return result
        resolved += 1
    if _active and resolved >= max_actions and str(get_current_actor().get("role", "")) != "player":
        return _fail(COMBAT_TURN_LIMIT, "Automatic turn safety limit reached")
    return _result(true, "OK", "Automatic turns resolved", "", {
        "resolved_actions": resolved,
        "current_actor": get_current_actor(),
        "combat_result": _last_result.duplicate(true),
    })


func trigger_phase_event(event_tag: String) -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    if event_tag.is_empty():
        return _fail(COMBAT_ACTION_INVALID, "Phase event tag cannot be empty")
    var before: Array = _runtime.get("triggered_phases", []).duplicate(true)
    _check_phase_transitions(event_tag)
    return _result(true, "OK", "Phase event processed", "", {
        "event_tag": event_tag,
        "changed": before != _runtime.get("triggered_phases", []),
        "current_phase_id": str(_runtime.get("current_phase_id", "")),
    })


func abort_combat(result_type: String = "defeat", continuation_tag: String = "") -> Dictionary:
    if not _require_active():
        return last_error.duplicate(true)
    if result_type not in RESULT_TYPES:
        return _fail(COMBAT_ACTION_INVALID, "Unknown combat result type '%s'" % result_type)
    _finish_combat(result_type, continuation_tag, "aborted")
    return _last_result.duplicate(true)


func export_runtime_snapshot() -> Dictionary:
    return {
        "snapshot_version": SNAPSHOT_VERSION,
        "active": _active,
        "runtime": _runtime.duplicate(true),
        "rng": _rng.export_state(),
        "last_result": _last_result.duplicate(true),
    }


func validate_runtime_snapshot(snapshot: Dictionary) -> bool:
    if int(snapshot.get("snapshot_version", -1)) != SNAPSHOT_VERSION:
        return _snapshot_fail("Unsupported combat snapshot version")
    if not snapshot.get("active") is bool:
        return _snapshot_fail("Combat snapshot active flag must be boolean")
    if not snapshot.get("runtime") is Dictionary or not snapshot.get("rng") is Dictionary:
        return _snapshot_fail("Combat snapshot runtime and RNG must be objects")
    if not snapshot.get("last_result", {}) is Dictionary:
        return _snapshot_fail("Combat snapshot last_result must be an object")
    var shadow_rng := CombatRngClass.new()
    if not shadow_rng.restore_state(snapshot["rng"]):
        return _snapshot_fail("Combat snapshot RNG is invalid")
    if bool(snapshot["active"]):
        var runtime: Dictionary = snapshot["runtime"]
        if not _validate_active_runtime_snapshot(runtime, snapshot["rng"]):
            return false
    elif not snapshot["runtime"].is_empty():
        return _snapshot_fail("Inactive combat snapshot must not retain temporary runtime")
    last_error = {}
    return true


func _validate_active_runtime_snapshot(runtime: Dictionary, snapshot_rng: Dictionary) -> bool:
    var combat_id := str(runtime.get("combat_id", ""))
    if not _combats.has(combat_id) or not _combats[combat_id].get("runtime") is Dictionary:
        return _snapshot_fail("Combat snapshot references an unknown runtime combat")
    var combat_definition: Dictionary = _combats[combat_id]
    var canonical_definition: Dictionary = combat_definition["runtime"]
    var canonical_rules := _merged_dictionary(_rules, canonical_definition.get("rules", {}))
    var canonical_outcomes := {
        "victory": combat_definition.get("victory", {}).duplicate(true),
        "defeat": combat_definition.get("defeat", {}).duplicate(true),
        "retreat": combat_definition.get("retreat", {}).duplicate(true),
    }
    for key: String in [
        "round", "turn_index", "turn_order", "units", "stable_unit_ids", "rules",
        "rng", "definition", "actions_elapsed", "inspect_cache", "consumed_items",
        "outcomes",
    ]:
        if not runtime.has(key):
            return _snapshot_fail("Combat snapshot runtime is missing '%s'" % key)
    if (
        not _is_integer_value(runtime["round"])
        or int(runtime["round"]) < 1
        or not _is_integer_value(runtime["turn_index"])
        or not _is_integer_value(runtime["actions_elapsed"])
        or int(runtime["actions_elapsed"]) < 0
    ):
        return _snapshot_fail("Combat snapshot counters are invalid")
    if (
        not runtime["units"] is Dictionary
        or not runtime["turn_order"] is Array
        or not runtime["stable_unit_ids"] is Array
        or not runtime["rules"] is Dictionary
        or not runtime["definition"] is Dictionary
        or not runtime["outcomes"] is Dictionary
        or not runtime["inspect_cache"] is Dictionary
        or not runtime["consumed_items"] is Dictionary
    ):
        return _snapshot_fail("Combat snapshot runtime collection shape is invalid")
    if runtime["definition"] != canonical_definition:
        return _snapshot_fail("Combat snapshot runtime definition differs from ContentLoader authority")
    if runtime["rules"] != canonical_rules:
        return _snapshot_fail("Combat snapshot rules differ from ContentLoader authority")
    if runtime["outcomes"] != canonical_outcomes:
        return _snapshot_fail("Combat snapshot outcomes differ from ContentLoader authority")
    if runtime["rng"] != snapshot_rng:
        return _snapshot_fail("Combat snapshot RNG copies disagree")

    var units: Dictionary = runtime["units"]
    var stable_seen := {}
    for raw_unit_id: Variant in runtime["stable_unit_ids"]:
        var unit_id := str(raw_unit_id)
        if unit_id.is_empty() or stable_seen.has(unit_id) or not units.has(unit_id):
            return _snapshot_fail("Combat snapshot stable unit IDs are invalid")
        stable_seen[unit_id] = true
        if not _validate_snapshot_unit(unit_id, units[unit_id]):
            return false
    if stable_seen.size() != units.size():
        return _snapshot_fail("Combat snapshot stable unit IDs do not cover every unit")

    var order_seen := {}
    for raw_unit_id: Variant in runtime["turn_order"]:
        var unit_id := str(raw_unit_id)
        if order_seen.has(unit_id) or not units.has(unit_id):
            return _snapshot_fail("Combat snapshot turn order contains an invalid unit")
        order_seen[unit_id] = true
    var index := int(runtime["turn_index"])
    if runtime["turn_order"].is_empty() or index < 0 or index >= runtime["turn_order"].size():
        return _snapshot_fail("Combat snapshot turn cursor is invalid")
    return true


func _validate_snapshot_unit(unit_id: String, raw_unit: Variant) -> bool:
    if not raw_unit is Dictionary:
        return _snapshot_fail("Combat snapshot unit '%s' is not an object" % unit_id)
    var unit: Dictionary = raw_unit
    for key: String in [
        "unit_id", "role", "team", "max_hp", "hp", "attack", "defense", "agility",
        "skill_ids", "cooldowns", "skill_uses", "statuses", "status_immunities",
        "alive", "withdrawn",
    ]:
        if not unit.has(key):
            return _snapshot_fail("Combat snapshot unit '%s' is missing '%s'" % [unit_id, key])
    if str(unit["unit_id"]) != unit_id or str(unit["role"]) not in ["player", "companion", "enemy"]:
        return _snapshot_fail("Combat snapshot unit identity or role is invalid")
    if not unit["alive"] is bool or not unit["withdrawn"] is bool:
        return _snapshot_fail("Combat snapshot unit life flags are invalid")
    for stat_name: String in ["max_hp", "hp", "attack", "defense", "agility"]:
        if not _is_number(unit[stat_name]):
            return _snapshot_fail("Combat snapshot unit '%s' has invalid %s" % [unit_id, stat_name])
    var max_hp := float(unit["max_hp"])
    var hp := float(unit["hp"])
    if max_hp <= 0.0 or hp < 0.0 or hp > max_hp or bool(unit["alive"]) != (hp > 0.0):
        return _snapshot_fail("Combat snapshot unit '%s' has inconsistent HP/life state" % unit_id)
    if (
        not unit["skill_ids"] is Array
        or unit["skill_ids"].size() > 4
        or not unit["cooldowns"] is Dictionary
        or not unit["skill_uses"] is Dictionary
        or not unit["statuses"] is Dictionary
        or not unit["status_immunities"] is Array
    ):
        return _snapshot_fail("Combat snapshot unit '%s' collections are invalid" % unit_id)
    for raw_skill_id: Variant in unit["skill_ids"]:
        if not _skills.has(str(raw_skill_id)):
            return _snapshot_fail("Combat snapshot unit references an unknown skill")
    for raw_skill_id: Variant in unit["cooldowns"].keys():
        var value: Variant = unit["cooldowns"][raw_skill_id]
        if not _skills.has(str(raw_skill_id)) or not _is_integer_value(value) or int(value) < 0:
            return _snapshot_fail("Combat snapshot cooldown is invalid")
    for raw_skill_id: Variant in unit["skill_uses"].keys():
        var value: Variant = unit["skill_uses"][raw_skill_id]
        if not _skills.has(str(raw_skill_id)) or not _is_integer_value(value) or int(value) < 0:
            return _snapshot_fail("Combat snapshot skill use count is invalid")
    for raw_status_id: Variant in unit["statuses"].keys():
        var status_id := str(raw_status_id)
        var instance: Variant = unit["statuses"][raw_status_id]
        if not _status_definitions.has(status_id) or not instance is Dictionary:
            return _snapshot_fail("Combat snapshot status is unknown or malformed")
        var max_stacks := maxi(1, int(_status_definitions[status_id].get("max_stacks", 1)))
        if (
            not _is_integer_value(instance.get("duration"))
            or int(instance.get("duration", 0)) < 1
            or not _is_integer_value(instance.get("stacks"))
            or int(instance.get("stacks", 0)) < 1
            or int(instance.get("stacks", 0)) > max_stacks
        ):
            return _snapshot_fail("Combat snapshot status duration or stacks are invalid")
    for raw_status_id: Variant in unit["status_immunities"]:
        if not _status_definitions.has(str(raw_status_id)):
            return _snapshot_fail("Combat snapshot immunity references an unknown status")
    return true


func restore_runtime_snapshot(snapshot: Dictionary) -> bool:
    if not _require_initialized_bool():
        return false
    if not validate_runtime_snapshot(snapshot):
        return false
    var candidate_runtime: Dictionary = snapshot["runtime"].duplicate(true)
    var candidate_result: Dictionary = snapshot.get("last_result", {}).duplicate(true)
    var candidate_rng := CombatRngClass.new()
    if not candidate_rng.restore_state(snapshot["rng"]):
        return _snapshot_fail("Combat snapshot RNG restore failed")
    _runtime = candidate_runtime
    _last_result = candidate_result
    _rng = candidate_rng
    _active = bool(snapshot["active"])
    last_error = {}
    return true


func _build_runtime(combat: Dictionary, seed: int) -> Dictionary:
    var runtime_definition: Dictionary = combat["runtime"]
    var runtime_rules := _merged_dictionary(_rules, runtime_definition.get("rules", {}))
    var units := {}
    var stable_unit_ids: Array[String] = []
    var player_definition: Variant = runtime_definition.get("player_unit")
    if not player_definition is Dictionary:
        return _fail(COMBAT_DEFINITION_INVALID, "Runtime combat must define one player unit", str(combat.get("combat_id", "")))
    var player_result := _build_unit(player_definition, "player", "")
    if not bool(player_result.get("ok", false)):
        return player_result
    var player: Dictionary = player_result["unit"]
    if bool(player_definition.get("use_equipment_modifiers", true)):
        _apply_equipment_modifiers(player)
    if not _insert_unit(units, stable_unit_ids, player):
        return last_error.duplicate(true)

    for raw_companion: Variant in runtime_definition.get("companion_units", []):
        if not raw_companion is Dictionary:
            return _fail(COMBAT_DEFINITION_INVALID, "Companion unit must be an object", str(combat.get("combat_id", "")))
        var companion_result := _build_unit(raw_companion, "companion", "")
        if not bool(companion_result.get("ok", false)):
            return companion_result
        if not _insert_unit(units, stable_unit_ids, companion_result["unit"]):
            return last_error.duplicate(true)

    for raw_instance: Variant in runtime_definition.get("enemy_instances", []):
        if not raw_instance is Dictionary:
            return _fail(COMBAT_DEFINITION_INVALID, "Enemy instance must be an object", str(combat.get("combat_id", "")))
        var enemy_id := str(raw_instance.get("enemy_id", ""))
        if not _enemies.has(enemy_id):
            return _fail(COMBAT_DEFINITION_INVALID, "Enemy instance references an unknown enemy", enemy_id)
        var enemy_source: Dictionary = _enemies[enemy_id].duplicate(true)
        for field: String in ["unit_id", "name", "max_hp", "attack", "defense", "agility", "skill_ids"]:
            if raw_instance.has(field):
                enemy_source[field] = raw_instance[field]
        if raw_instance.has("unit_id"):
            enemy_source["unit_id"] = raw_instance["unit_id"]
        var enemy_result := _build_unit(enemy_source, "enemy", enemy_id)
        if not bool(enemy_result.get("ok", false)):
            return enemy_result
        if not _insert_unit(units, stable_unit_ids, enemy_result["unit"]):
            return last_error.duplicate(true)

    if units.size() < 2 or not _has_living_role_in(units, "enemy"):
        return _fail(COMBAT_DEFINITION_INVALID, "Runtime combat must contain a player and at least one enemy")
    var rng := CombatRngClass.new()
    rng.initialize(seed)
    var runtime := {
        "combat_id": str(combat["combat_id"]),
        "round": 0,
        "turn_index": 0,
        "turn_order": [],
        "initiative_scores": {},
        "units": units,
        "stable_unit_ids": stable_unit_ids,
        "rules": runtime_rules,
        "rng": rng.export_state(),
        "actions_elapsed": 0,
        "companion_tendency": "offensive",
        "tendency_set_round": -1,
        "inspect_cache": {},
        "consumed_items": {},
        "important_events": [],
        "current_phase_id": "",
        "triggered_phases": [],
        "phase_modifiers": {},
        "phase_skill_ids": {},
        "phase_ai_weight_modifiers": {},
        "definition": runtime_definition.duplicate(true),
        "outcomes": {
            "victory": combat.get("victory", {}).duplicate(true),
            "defeat": combat.get("defeat", {}).duplicate(true),
            "retreat": combat.get("retreat", {}).duplicate(true),
        },
    }
    return _result(true, "OK", "Combat runtime prepared", str(combat["combat_id"]), {"runtime": runtime})


func _build_unit(source: Dictionary, role: String, definition_id: String) -> Dictionary:
    var unit_id := str(source.get("unit_id", source.get("enemy_id", "")))
    if unit_id.is_empty():
        return _fail(COMBAT_DEFINITION_INVALID, "Combat unit has no stable unit_id")
    for stat_name: String in ["max_hp", "attack", "defense", "agility"]:
        if not _is_number(source.get(stat_name)):
            return _fail(COMBAT_DEFINITION_INVALID, "Combat unit '%s' has invalid %s" % [unit_id, stat_name], unit_id)
    var max_hp := maxf(1.0, float(source["max_hp"]))
    var skills: Array = source.get("skill_ids", []).duplicate(true)
    if skills.size() > 4:
        return _fail(COMBAT_DEFINITION_INVALID, "Combat unit cannot equip more than four skills", unit_id)
    for raw_skill_id: Variant in skills:
        var skill_id := str(raw_skill_id)
        if not _skills.has(skill_id):
            return _fail(COMBAT_DEFINITION_INVALID, "Combat unit references unknown skill '%s'" % skill_id, unit_id)
    var runtime_data: Dictionary = source.get("runtime", {}) if source.get("runtime") is Dictionary else {}
    var ai_actions: Array = source.get("ai_actions", runtime_data.get("ai_actions", [])).duplicate(true)
    var immunities: Array = source.get("status_immunities", runtime_data.get("status_immunities", [])).duplicate(true)
    var unit := {
        "unit_id": unit_id,
        "definition_id": definition_id,
        "name": str(source.get("name", unit_id)),
        "role": role,
        "team": "enemy" if role == "enemy" else "ally",
        "max_hp": max_hp,
        "hp": max_hp,
        "attack": float(source["attack"]),
        "defense": float(source["defense"]),
        "agility": float(source["agility"]),
        "critical_chance": clampf(float(source.get("critical_chance", 0.0)), 0.0, 1.0),
        "insight": float(source.get("insight", 0.0)),
        "skill_ids": skills,
        "cooldowns": {},
        "skill_uses": {},
        "statuses": {},
        "status_immunities": immunities,
        "ai_actions": ai_actions,
        "alive": true,
        "withdrawn": false,
        "equipment_modifiers": {},
    }
    return _result(true, "OK", "Combat unit prepared", unit_id, {"unit": unit})


func _insert_unit(units: Dictionary, stable_unit_ids: Array[String], unit: Dictionary) -> bool:
    var unit_id := str(unit["unit_id"])
    if units.has(unit_id):
        _record_error(COMBAT_DEFINITION_INVALID, "Duplicate combat unit instance ID", unit_id)
        return false
    units[unit_id] = unit
    stable_unit_ids.append(unit_id)
    return true


func _apply_equipment_modifiers(player: Dictionary) -> void:
    if _inventory_manager == null:
        return
    var modifier_result: Variant = _inventory_manager.call("get_stat_modifiers")
    if not modifier_result is Dictionary or not bool(modifier_result.get("ok", false)):
        return
    var modifiers: Dictionary = modifier_result.get("modifiers", {})
    player["equipment_modifiers"] = modifiers.duplicate(true)
    for raw_stat_name: Variant in modifiers.keys():
        var stat_name := str(raw_stat_name)
        if not _is_number(modifiers[raw_stat_name]):
            continue
        player[stat_name] = float(player.get(stat_name, 0.0)) + float(modifiers[raw_stat_name])
    player["max_hp"] = maxf(1.0, float(player["max_hp"]))
    player["hp"] = float(player["max_hp"])
    player["critical_chance"] = clampf(float(player["critical_chance"]), 0.0, 1.0)


func _create_precombat_checkpoint(combat_id: String, seed: int) -> Dictionary:
    var request := {
        "combat_id": combat_id,
        "seed": seed,
        "slot_id": "auto",
    }
    precombat_checkpoint_requested.emit(request.duplicate(true))
    if _save_manager == null:
        return _fail(
            COMBAT_CHECKPOINT_FAILED,
            "Combat cannot start until a SaveManager is bound for the precombat checkpoint",
            combat_id,
        )
    var previous_random: Dictionary = _save_manager.call("get_random_state")
    var random_state := {
        "seed": seed,
        "scope": "precombat",
        "combat_id": combat_id,
    }
    if not bool(_save_manager.call("set_random_state", random_state)):
        return _fail(COMBAT_CHECKPOINT_FAILED, "SaveManager rejected the precombat random state", combat_id)
    var save_result: Variant = _save_manager.call("create_precombat_checkpoint")
    if not save_result is Dictionary or not bool(save_result.get("ok", false)):
        _save_manager.call("set_random_state", previous_random)
        return _fail(COMBAT_CHECKPOINT_FAILED, "Precombat automatic checkpoint failed", combat_id, {
            "details": save_result,
        })
    return _result(true, "OK", "Precombat checkpoint created", combat_id, {
        "checkpoint_bound": true,
        "save_result": save_result,
    })


func _begin_round() -> void:
    if not _active:
        return
    var max_rounds := int(_runtime["rules"].get("max_rounds", DEFAULT_RULES["max_rounds"]))
    if int(_runtime["round"]) >= max_rounds:
        _record_error(COMBAT_TURN_LIMIT, "Combat reached the configured round safety limit", str(_runtime["combat_id"]))
        _finish_combat(_safety_result_type(), _safety_continuation_tag(), "round_limit")
        return
    _runtime["round"] = int(_runtime["round"]) + 1
    _process_status_timing("round_start")
    if not _active:
        return
    _check_end_conditions()
    if _active:
        _check_phase_transitions("")
    if not _active:
        return
    _build_turn_order()
    _runtime["turn_index"] = 0
    round_started.emit({
        "combat_id": str(_runtime["combat_id"]),
        "round": int(_runtime["round"]),
        "turn_order": _runtime["turn_order"].duplicate(true),
        "initiative_scores": _runtime["initiative_scores"].duplicate(true),
    })
    _seek_current_turn()


func _build_turn_order() -> void:
    var entries: Array = []
    var random_min := int(_runtime["rules"].get("initiative_random_min", 0))
    var random_max := int(_runtime["rules"].get("initiative_random_max", 3))
    for raw_unit_id: Variant in _runtime["stable_unit_ids"]:
        var unit_id := str(raw_unit_id)
        if not _unit_can_take_turn(unit_id):
            continue
        var score := _effective_stat(unit_id, "agility") + float(_rng.range_int(random_min, random_max))
        entries.append({
            "unit_id": unit_id,
            "score": score,
            "player_priority": 0 if str(_runtime["units"][unit_id]["role"]) == "player" else 1,
        })
    entries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
        var left_score := float(left["score"])
        var right_score := float(right["score"])
        if not is_equal_approx(left_score, right_score):
            return left_score > right_score
        if int(left["player_priority"]) != int(right["player_priority"]):
            return int(left["player_priority"]) < int(right["player_priority"])
        return str(left["unit_id"]) < str(right["unit_id"])
    )
    var order: Array = []
    var scores := {}
    for entry: Dictionary in entries:
        order.append(entry["unit_id"])
        scores[entry["unit_id"]] = entry["score"]
    _runtime["turn_order"] = order
    _runtime["initiative_scores"] = scores
    _runtime["rng"] = _rng.export_state()


func _seek_current_turn() -> void:
    while _active:
        var order: Array = _runtime["turn_order"]
        var index := int(_runtime["turn_index"])
        if index >= order.size():
            _end_round()
            return
        var unit_id := str(order[index])
        if not _unit_can_take_turn(unit_id):
            _runtime["turn_index"] = index + 1
            continue
        _prepare_actor_turn(unit_id)
        return


func _prepare_actor_turn(unit_id: String) -> void:
    _decrement_cooldowns(unit_id)
    _process_unit_status_timing(unit_id, "action_start")
    _expire_owner_turn_start_statuses(unit_id)
    _check_end_conditions()
    if not _active:
        return
    _check_phase_transitions("")
    if not _active:
        return
    if not _unit_can_take_turn(unit_id):
        _advance_turn()
        return
    var blocked_status := _blocking_status(unit_id)
    turn_started.emit({
        "combat_id": str(_runtime["combat_id"]),
        "round": int(_runtime["round"]),
        "unit": get_unit_state(unit_id),
        "blocked_by": blocked_status,
    })
    if blocked_status.is_empty():
        return
    var definition: Dictionary = _status_definitions.get(blocked_status, {})
    if bool(definition.get("consume_on_block", true)):
        _remove_status(unit_id, blocked_status)
    var result := _result(true, "OK", "Unit action was blocked by a status", unit_id, {
        "action_type": "status_skip",
        "actor_id": unit_id,
        "status_id": blocked_status,
        "round": int(_runtime["round"]),
    })
    _runtime["actions_elapsed"] = int(_runtime["actions_elapsed"]) + 1
    action_resolved.emit(result)
    _advance_turn()


func _advance_turn() -> void:
    if not _active:
        return
    _runtime["turn_index"] = int(_runtime["turn_index"]) + 1
    _seek_current_turn()


func _end_round() -> void:
    _process_status_timing("round_end")
    if not _active:
        return
    _check_end_conditions()
    if _active:
        _check_phase_transitions("")
    if _active:
        _begin_round()


func _resolve_attack(actor_id: String, target_id: String, power: float, flat_bonus: float) -> Dictionary:
    if not _is_legal_opponent(actor_id, target_id):
        return _fail(COMBAT_TARGET_INVALID, "Attack target is not a living opponent", target_id)
    var damage_result := _calculate_direct_damage(actor_id, target_id, power, flat_bonus)
    _apply_damage(target_id, int(damage_result["damage"]), actor_id, "attack", true)
    return _result(true, "OK", "Attack resolved", actor_id, {
        "target_id": target_id,
        "damage": int(damage_result["damage"]),
        "critical": bool(damage_result["critical"]),
        "variance": float(damage_result["variance"]),
    })


func _resolve_defend(actor_id: String) -> Dictionary:
    var guard_status_id := str(_runtime["rules"].get("guard_status_id", "guard"))
    if not _status_definitions.has(guard_status_id):
        return _fail(COMBAT_DEFINITION_INVALID, "Configured guard status is not registered", guard_status_id)
    _apply_status(actor_id, guard_status_id, 1, 1.0, actor_id)
    return _result(true, "OK", "Defend resolved", actor_id, {"status_id": guard_status_id})


func _resolve_skill(actor_id: String, skill_id: String, target_id: String) -> Dictionary:
    if not _skills.has(skill_id):
        return _fail(SKILL_NOT_FOUND, "Unknown skill ID", skill_id)
    var unit: Dictionary = _runtime["units"][actor_id]
    var available_skills: Array = _available_skills(actor_id)
    if skill_id not in available_skills:
        return _fail(SKILL_UNAVAILABLE, "Skill is not equipped or available in the current phase", skill_id)
    var skill: Dictionary = _skills[skill_id]
    if str(skill.get("kind", "")) not in ["active", "companion"]:
        return _fail(SKILL_UNAVAILABLE, "Passive or noncombat skill cannot be used as a battle action", skill_id)
    if int(unit["cooldowns"].get(skill_id, 0)) > 0:
        return _fail(SKILL_COOLDOWN, "Skill is still cooling down", skill_id, {
            "remaining": int(unit["cooldowns"][skill_id]),
        })
    var uses_limit: Variant = skill.get("uses_per_battle")
    var used := int(unit["skill_uses"].get(skill_id, 0))
    if uses_limit != null and used >= int(uses_limit):
        return _fail(SKILL_USES_EXHAUSTED, "Skill has no uses remaining this battle", skill_id)
    var targets_result := _resolve_targets(actor_id, str(skill.get("target", "")), target_id)
    if not bool(targets_result.get("ok", false)):
        return targets_result
    var targets: Array = targets_result["targets"]
    var condition_target := str(targets[0]) if not targets.is_empty() else ""
    if not _skill_conditions_met(actor_id, skill, condition_target):
        return _fail(SKILL_UNAVAILABLE, "Skill conditions are not satisfied", skill_id)
    if not _validate_effects(skill.get("effects", [])):
        return last_error.duplicate(true)

    var effect_results: Array = []
    for raw_effect: Variant in skill.get("effects", []):
        var effect: Dictionary = raw_effect
        var effect_type := str(effect.get("effect", effect.get("type", "")))
        match effect_type:
            "damage":
                for raw_target_id: Variant in targets:
                    var affected_id := str(raw_target_id)
                    var power := float(effect.get("power", 1.0))
                    var flat_bonus := float(effect.get("value", effect.get("flat_bonus", 0.0)))
                    var direct := str(effect.get("damage_type", "direct")) == "direct"
                    var damage := _calculate_direct_damage(actor_id, affected_id, power, flat_bonus, direct)
                    _apply_damage(affected_id, int(damage["damage"]), actor_id, skill_id, direct)
                    effect_results.append({
                        "effect": "damage",
                        "target_id": affected_id,
                        "value": int(damage["damage"]),
                        "damage_type": "direct" if direct else "periodic",
                    })
            "heal":
                for raw_target_id: Variant in targets:
                    var affected_id := str(raw_target_id)
                    var amount := _healing_amount(actor_id, effect)
                    var healed := _apply_heal(affected_id, amount, actor_id, skill_id)
                    effect_results.append({"effect": "heal", "target_id": affected_id, "value": healed})
            "apply_status":
                var status_id := str(effect.get("status_id", ""))
                for raw_target_id: Variant in targets:
                    var affected_id := str(raw_target_id)
                    var chance := clampf(float(effect.get("chance", 1.0)), 0.0, 1.0)
                    if chance < 1.0 and not _rng.chance(chance):
                        effect_results.append({"effect": "apply_status", "target_id": affected_id, "status_id": status_id, "applied": false})
                        continue
                    var applied := _apply_status(
                        affected_id,
                        status_id,
                        int(effect.get("duration", _status_definitions[status_id].get("default_duration", 1))),
                        float(effect.get("magnitude", 1.0)),
                        actor_id,
                        int(effect.get("stacks", 1)),
                    )
                    effect_results.append({
                        "effect": "apply_status",
                        "target_id": affected_id,
                        "status_id": status_id,
                        "applied": applied,
                    })
            "remove_status":
                var status_id := str(effect.get("status_id", ""))
                for raw_target_id: Variant in targets:
                    var affected_id := str(raw_target_id)
                    var removed := _remove_status(affected_id, status_id)
                    effect_results.append({"effect": "remove_status", "target_id": affected_id, "status_id": status_id, "removed": removed})
            "reveal", "reveal_mechanic":
                for raw_target_id: Variant in targets:
                    var affected_id := str(raw_target_id)
                    var reveal_id := str(effect.get("reveal", "mechanic_revealed"))
                    _runtime["inspect_cache"][affected_id] = {
                        "outcome": "success",
                        "reveal": reveal_id,
                        "power": float(effect.get("power", 0.0)),
                        "source": skill_id,
                    }
                    _append_important_event("inspect:%s:%s" % [affected_id, reveal_id])
                    effect_results.append({
                        "effect": effect_type,
                        "target_id": affected_id,
                        "reveal": reveal_id,
                    })
            "state_effect":
                var state_effects: Array = []
                if effect.get("effects") is Array:
                    state_effects = effect["effects"].duplicate(true)
                elif effect.has("key") and effect.has("op") and effect.has("value"):
                    state_effects = [{
                        "key": effect["key"],
                        "op": effect["op"],
                        "value": effect["value"],
                    }]
                if state_effects.is_empty():
                    return _fail(COMBAT_STATE_EFFECT_FAILED, "Combat state effect has no operations", skill_id)
                if not bool(_game_state.call("apply_effects", state_effects, "combat")):
                    return _fail(COMBAT_STATE_EFFECT_FAILED, "GameState rejected a combat skill effect", skill_id, {
                        "details": _game_state.get("last_error"),
                    })
                effect_results.append({"effect": "state_effect", "count": state_effects.size()})

    unit["skill_uses"][skill_id] = used + 1
    var cooldown := int(skill.get("cooldown_rounds", 0))
    if cooldown > 0:
        # +1 keeps the skill blocked for exactly N future owner turns.
        unit["cooldowns"][skill_id] = cooldown + 1
    _runtime["units"][actor_id] = unit
    return _result(true, "OK", "Skill resolved", actor_id, {
        "skill_id": skill_id,
        "targets": targets,
        "effects": effect_results,
        "uses": used + 1,
        "cooldown": cooldown,
    })


func _resolve_item(actor_id: String, item_id: String, target_id: String) -> Dictionary:
    if _inventory_manager == null:
        return _fail(ITEM_USE_FAILED, "InventoryManager is not bound", item_id)
    if not _runtime["units"].has(target_id) or not _same_team(actor_id, target_id) or not _unit_is_alive(target_id):
        return _fail(COMBAT_TARGET_INVALID, "Item target must be a living ally", target_id)
    var definition: Variant = _inventory_manager.call("get_item_definition", item_id)
    if not definition is Dictionary or not bool(definition.get("ok", false)):
        return _fail(ITEM_USE_FAILED, "InventoryManager rejected the item definition", item_id, {"details": definition})
    var item: Dictionary = definition.get("item", {})
    var combat_effects: Array = item.get("combat_effects", [])
    if combat_effects.is_empty():
        return _fail(ITEM_USE_FAILED, "Item has no registered combat effect", item_id)
    if not _validate_effects(combat_effects):
        return last_error.duplicate(true)

    # Resolve local changes on a copy. Inventory consumption is the last fallible step.
    var target_copy: Dictionary = _runtime["units"][target_id].duplicate(true)
    var preview: Array = []
    for raw_effect: Variant in combat_effects:
        var effect: Dictionary = raw_effect
        var effect_type := str(effect.get("effect", effect.get("type", "")))
        match effect_type:
            "heal":
                var amount := int(maxf(0.0, float(effect.get("value", 0.0))))
                var old_hp := float(target_copy["hp"])
                target_copy["hp"] = minf(float(target_copy["max_hp"]), old_hp + float(amount))
                preview.append({"effect": "heal", "value": int(float(target_copy["hp"]) - old_hp)})
            "apply_status":
                var status_id := str(effect.get("status_id", ""))
                var status_preview := _preview_status(target_copy, status_id, effect)
                if not bool(status_preview.get("ok", false)):
                    return status_preview
                target_copy = status_preview["unit"]
                preview.append({"effect": "apply_status", "status_id": status_id})
            "remove_status":
                var status_id := str(effect.get("status_id", ""))
                target_copy["statuses"].erase(status_id)
                preview.append({"effect": "remove_status", "status_id": status_id})
            _:
                return _fail(ITEM_USE_FAILED, "Unsupported item combat effect '%s'" % effect_type, item_id)

    var consume_result: Variant = _inventory_manager.call("use_item", item_id, "battle", "combat")
    if not consume_result is Dictionary or not bool(consume_result.get("ok", false)):
        return _fail(ITEM_USE_FAILED, "InventoryManager rejected battle item use", item_id, {
            "details": consume_result,
        })
    var before: Dictionary = _runtime["units"][target_id]
    _runtime["units"][target_id] = target_copy
    _emit_item_effect_changes(before, target_copy, actor_id, item_id)
    _runtime["consumed_items"][item_id] = int(_runtime["consumed_items"].get(item_id, 0)) + 1
    return _result(true, "OK", "Battle item used", actor_id, {
        "item_id": item_id,
        "target_id": target_id,
        "effects": preview,
    })


func _resolve_inspect(actor_id: String, target_id: String) -> Dictionary:
    if not _is_legal_opponent(actor_id, target_id):
        return _fail(INSPECT_TARGET_INVALID, "Inspect target is not a living opponent", target_id)
    var rules: Array = _runtime["definition"].get("inspect_rules", [])
    var chosen: Dictionary = {}
    for raw_rule: Variant in rules:
        if not raw_rule is Dictionary:
            continue
        var rule: Dictionary = raw_rule
        var configured_target := str(rule.get("target_unit_id", ""))
        if not configured_target.is_empty() and configured_target != target_id:
            continue
        if _conditions_met(rule.get("conditions", []), actor_id, target_id):
            chosen = rule
            break
    var inspect_id := str(chosen.get("inspect_id", "public"))
    var cache_key := _inspect_cache_key(target_id, inspect_id)
    var public_info := _public_inspect_info(target_id)
    if _runtime["inspect_cache"].has(cache_key):
        var cached: Dictionary = _runtime["inspect_cache"][cache_key]
        return _result(true, "OK", "Inspect found no new information", actor_id, {
            "target_id": target_id,
            "outcome": "no_new_findings",
            "public_info": public_info,
            "cached_result": cached.duplicate(true),
        })
    var outcome := "no_new_findings"
    var registered_reveal := ""
    var roll := -1
    if not chosen.is_empty():
        outcome = str(chosen.get("outcome", "success"))
        registered_reveal = str(chosen.get("reveal", ""))
        if bool(chosen.get("seeded", false)):
            roll = _rng.range_int(1, 20)
            var total := roll + int(round(_effective_stat(actor_id, "agility")))
            var difficulty := int(chosen.get("difficulty", 10))
            if total >= difficulty:
                outcome = "success"
            elif total >= difficulty - 4:
                outcome = "partial_success"
            else:
                outcome = "no_new_findings"
    var reveal := registered_reveal if outcome in ["success", "partial_success"] else ""
    var inspect_result := {
        "inspect_id": inspect_id,
        "outcome": outcome,
        "reveal": reveal,
        "roll": roll,
        "round": int(_runtime["round"]),
        "phase_id": str(_runtime.get("current_phase_id", "")),
        "public_info": public_info,
    }
    _runtime["inspect_cache"][cache_key] = inspect_result
    if not reveal.is_empty() and outcome != "no_new_findings":
        _append_important_event("inspect:%s:%s" % [target_id, reveal])
    return _result(true, "OK", "Inspect resolved", actor_id, {
        "target_id": target_id,
        "outcome": outcome,
        "reveal": reveal,
        "roll": roll,
        "public_info": public_info,
    })


func _inspect_cache_key(target_id: String, inspect_id: String) -> String:
    return "%s::%s::%s" % [
        target_id,
        str(_runtime.get("current_phase_id", "")),
        inspect_id,
    ]


func _public_inspect_info(target_id: String) -> String:
    var unit: Variant = _runtime.get("units", {}).get(target_id)
    if not unit is Dictionary:
        return ""
    var definition: Variant = _enemies.get(str(unit.get("definition_id", "")))
    if not definition is Dictionary:
        return ""
    var runtime: Variant = definition.get("runtime")
    if not runtime is Dictionary or not runtime.get("inspect") is Dictionary:
        return ""
    return str(runtime["inspect"].get("public_info", ""))


func _resolve_retreat(actor_id: String) -> Dictionary:
    var retreat: Dictionary = _runtime["definition"].get("retreat", {})
    if retreat.is_empty():
        retreat = _runtime.get("outcomes", {}).get("retreat", {})
    var allowed := bool(retreat.get("allowed", false))
    var mode := str(retreat.get("mode", "formula"))
    if not allowed or mode == "disabled":
        return _fail(RETREAT_FORBIDDEN, "Retreat is forbidden for this combat", str(_runtime["combat_id"]))
    var success := false
    var chance := 1.0
    var roll := 0.0
    if mode == "guaranteed":
        success = true
    else:
        var player_agility := _effective_stat(actor_id, "agility")
        var enemy_agility := 0.0
        var boss_present := false
        for raw_unit_id: Variant in _runtime["stable_unit_ids"]:
            var unit_id := str(raw_unit_id)
            var unit: Dictionary = _runtime["units"][unit_id]
            if str(unit["role"]) != "enemy" or not _unit_is_alive(unit_id):
                continue
            enemy_agility = maxf(enemy_agility, _effective_stat(unit_id, "agility"))
            var definition_id := str(unit.get("definition_id", ""))
            if _enemies.has(definition_id) and bool(_enemies[definition_id].get("boss", false)):
                boss_present = true
        chance = float(_runtime["rules"].get("retreat_base_chance", 0.5))
        chance += (player_agility - enemy_agility) * float(_runtime["rules"].get("retreat_agility_factor", 0.05))
        chance += float(retreat.get("chance_modifier", 0.0))
        if boss_present:
            chance -= float(_runtime["rules"].get("retreat_boss_penalty", 0.25))
        chance = clampf(
            chance,
            float(_runtime["rules"].get("retreat_min_chance", 0.1)),
            float(_runtime["rules"].get("retreat_max_chance", 0.9)),
        )
        roll = _rng.next_float()
        success = roll < chance
    var result := _result(true, "OK", "Retreat resolved", actor_id, {
        "success": success,
        "chance": chance,
        "roll": roll,
        "consumed_turn": not success,
    })
    if success:
        result["_pending_finish"] = {
            "result_type": "retreat",
            "continuation_tag": str(retreat.get("continuation_tag", "")),
            "event_tag": "retreat_success",
        }
    return result


func _calculate_direct_damage(
    actor_id: String,
    target_id: String,
    power: float,
    flat_bonus: float,
    direct: bool = true,
) -> Dictionary:
    var attack_value := _effective_stat(actor_id, "attack") * maxf(0.0, power) + flat_bonus
    var defense_value := _effective_stat(target_id, "defense")
    var variance := lerpf(
        float(_runtime["rules"].get("damage_variance_min", 0.85)),
        float(_runtime["rules"].get("damage_variance_max", 1.15)),
        _rng.next_float(),
    )
    var raw_damage := attack_value * variance - defense_value * float(
        _runtime["rules"].get("defense_multiplier", 0.6)
    )
    var critical := false
    var critical_chance := clampf(_effective_stat(actor_id, "critical_chance"), 0.0, 1.0)
    if critical_chance > 0.0 and _rng.chance(critical_chance):
        raw_damage *= float(_runtime["rules"].get("critical_multiplier", 1.5))
        critical = true
    var direct_multiplier := _direct_damage_multiplier(target_id) if direct else 1.0
    var minimum_damage := int(_runtime["rules"].get("minimum_damage", 1))
    var damage := maxi(minimum_damage, int(floor(raw_damage * direct_multiplier)))
    return {"damage": damage, "critical": critical, "variance": variance}


func _healing_amount(actor_id: String, effect: Dictionary) -> int:
    var flat := float(effect.get("value", 0.0))
    var power := float(effect.get("power", 0.0))
    return maxi(0, int(floor(flat + _effective_stat(actor_id, "attack") * power)))


func _apply_damage(
    target_id: String,
    amount: int,
    source_id: String,
    source_kind: String,
    direct: bool,
) -> int:
    if not _runtime["units"].has(target_id) or not _unit_is_alive(target_id):
        return 0
    var unit: Dictionary = _runtime["units"][target_id]
    var old_hp := float(unit["hp"])
    var applied := mini(maxi(0, amount), int(ceil(old_hp)))
    unit["hp"] = maxf(0.0, old_hp - float(applied))
    if float(unit["hp"]) <= 0.0:
        unit["alive"] = false
    _runtime["units"][target_id] = unit
    unit_damaged.emit({
        "unit_id": target_id,
        "source_id": source_id,
        "source_kind": source_kind,
        "amount": applied,
        "old_hp": old_hp,
        "new_hp": float(unit["hp"]),
        "direct": direct,
    })
    if not bool(unit["alive"]):
        _on_unit_defeated(target_id, source_id)
    return applied


func _apply_heal(target_id: String, amount: int, source_id: String, source_kind: String) -> int:
    if not _runtime["units"].has(target_id) or not _unit_is_alive(target_id):
        return 0
    var unit: Dictionary = _runtime["units"][target_id]
    var old_hp := float(unit["hp"])
    unit["hp"] = minf(float(unit["max_hp"]), old_hp + float(maxi(0, amount)))
    var applied := int(floor(float(unit["hp"]) - old_hp))
    _runtime["units"][target_id] = unit
    if applied > 0:
        unit_healed.emit({
            "unit_id": target_id,
            "source_id": source_id,
            "source_kind": source_kind,
            "amount": applied,
            "old_hp": old_hp,
            "new_hp": float(unit["hp"]),
        })
    return applied


func _apply_status(
    target_id: String,
    status_id: String,
    duration: int,
    magnitude: float,
    source_id: String,
    stacks_to_add: int = 1,
) -> bool:
    if not _status_definitions.has(status_id) or not _runtime["units"].has(target_id) or not _unit_is_alive(target_id):
        return false
    var unit: Dictionary = _runtime["units"][target_id]
    if status_id in unit.get("status_immunities", []):
        return false
    var definition: Dictionary = _status_definitions[status_id]
    var statuses: Dictionary = unit["statuses"]
    var max_stacks := maxi(1, int(definition.get("max_stacks", 1)))
    var policy := str(definition.get("stack_policy", "refresh"))
    var instance := {
        "status_id": status_id,
        "duration": maxi(1, duration),
        "stacks": mini(max_stacks, maxi(1, stacks_to_add)),
        "magnitude": magnitude,
        "source_id": source_id,
        "applied_round": int(_runtime.get("round", 0)),
    }
    if statuses.has(status_id):
        var existing: Dictionary = statuses[status_id]
        match policy:
            "stack":
                instance["stacks"] = mini(
                    max_stacks,
                    int(existing.get("stacks", 1)) + maxi(1, stacks_to_add),
                )
                instance["duration"] = maxi(int(existing.get("duration", 1)), maxi(1, duration))
            "refresh":
                instance["stacks"] = int(existing.get("stacks", 1))
                instance["duration"] = maxi(int(existing.get("duration", 1)), maxi(1, duration))
            "replace":
                pass
            "ignore":
                return false
            _:
                return false
    statuses[status_id] = instance
    unit["statuses"] = statuses
    _runtime["units"][target_id] = unit
    status_applied.emit({
        "unit_id": target_id,
        "status_id": status_id,
        "duration": int(instance["duration"]),
        "stacks": int(instance["stacks"]),
        "source_id": source_id,
    })
    return true


func _preview_status(unit: Dictionary, status_id: String, effect: Dictionary) -> Dictionary:
    if not _status_definitions.has(status_id):
        return _fail(ITEM_USE_FAILED, "Item references an unknown combat status", status_id)
    if status_id in unit.get("status_immunities", []):
        return _fail(ITEM_USE_FAILED, "Item target is immune to the combat status", status_id)
    var copy := unit.duplicate(true)
    var definition: Dictionary = _status_definitions[status_id]
    var statuses: Dictionary = copy["statuses"]
    var duration := maxi(1, int(effect.get("duration", definition.get("default_duration", 1))))
    var max_stacks := maxi(1, int(definition.get("max_stacks", 1)))
    var policy := str(definition.get("stack_policy", "refresh"))
    var instance := {
        "status_id": status_id,
        "duration": duration,
        "stacks": mini(max_stacks, maxi(1, int(effect.get("stacks", 1)))),
        "magnitude": float(effect.get("magnitude", 1.0)),
        "source_id": "item",
        "applied_round": int(_runtime.get("round", 0)),
    }
    if statuses.has(status_id):
        var old: Dictionary = statuses[status_id]
        if policy == "ignore":
            return _fail(ITEM_USE_FAILED, "Item status cannot be applied again", status_id)
        if policy == "stack":
            instance["stacks"] = mini(
                max_stacks,
                int(old.get("stacks", 1)) + maxi(1, int(effect.get("stacks", 1))),
            )
        elif policy == "refresh":
            instance["stacks"] = int(old.get("stacks", 1))
            instance["duration"] = maxi(duration, int(old.get("duration", 1)))
    statuses[status_id] = instance
    copy["statuses"] = statuses
    return _result(true, "OK", "Status preview prepared", status_id, {"unit": copy})


func _emit_item_effect_changes(before: Dictionary, after: Dictionary, actor_id: String, item_id: String) -> void:
    var old_hp := float(before.get("hp", 0.0))
    var new_hp := float(after.get("hp", 0.0))
    if new_hp > old_hp:
        unit_healed.emit({
            "unit_id": str(after["unit_id"]),
            "source_id": actor_id,
            "source_kind": item_id,
            "amount": int(floor(new_hp - old_hp)),
            "old_hp": old_hp,
            "new_hp": new_hp,
        })
    var old_statuses: Dictionary = before.get("statuses", {})
    var new_statuses: Dictionary = after.get("statuses", {})
    for status_id: Variant in new_statuses.keys():
        if not old_statuses.has(status_id) or old_statuses[status_id] != new_statuses[status_id]:
            var instance: Dictionary = new_statuses[status_id]
            status_applied.emit({
                "unit_id": str(after["unit_id"]),
                "status_id": str(status_id),
                "duration": int(instance.get("duration", 1)),
                "stacks": int(instance.get("stacks", 1)),
                "source_id": actor_id,
            })


func _remove_status(unit_id: String, status_id: String) -> bool:
    if not _runtime["units"].has(unit_id):
        return false
    var unit: Dictionary = _runtime["units"][unit_id]
    if not unit["statuses"].has(status_id):
        return false
    unit["statuses"].erase(status_id)
    _runtime["units"][unit_id] = unit
    return true


func _process_status_timing(timing: String) -> void:
    var unit_ids: Array = _runtime.get("stable_unit_ids", []).duplicate(true)
    for raw_unit_id: Variant in unit_ids:
        if not _active:
            return
        var unit_id := str(raw_unit_id)
        if not _unit_is_alive(unit_id):
            continue
        _process_unit_status_timing(unit_id, timing)


func _process_unit_status_timing(unit_id: String, timing: String) -> void:
    if not _active or not _unit_is_alive(unit_id):
        return
    var status_ids: Array = _runtime["units"][unit_id]["statuses"].keys()
    status_ids.sort()
    for raw_status_id: Variant in status_ids:
        var status_id := str(raw_status_id)
        if not _runtime["units"][unit_id]["statuses"].has(status_id):
            continue
        var definition: Dictionary = _status_definitions.get(status_id, {})
        var instance: Dictionary = _runtime["units"][unit_id]["statuses"][status_id]
        if str(definition.get("tick_timing", definition.get("duration_tick", "none"))) == timing:
            var tick: Dictionary = definition.get("tick_effect", {})
            var tick_type := str(tick.get("type", ""))
            if tick_type.is_empty() and str(tick.get("effect", "")) == "damage":
                tick_type = "max_hp_damage" if str(tick.get("mode", "")) == "max_hp_ratio" else "flat_damage"
            elif tick_type.is_empty() and str(tick.get("effect", "")) == "heal":
                tick_type = "max_hp_heal" if str(tick.get("mode", "")) == "max_hp_ratio" else "flat_heal"
            var stacks := int(instance.get("stacks", 1))
            match tick_type:
                "max_hp_damage":
                    var amount := maxi(1, int(floor(
                        float(_runtime["units"][unit_id]["max_hp"])
                        * float(tick.get("value", 0.0))
                        * float(stacks)
                    )))
                    _apply_damage(unit_id, amount, str(instance.get("source_id", status_id)), status_id, false)
                "flat_damage":
                    _apply_damage(
                        unit_id,
                        maxi(0, int(float(tick.get("value", 0.0)) * stacks)),
                        str(instance.get("source_id", status_id)),
                        status_id,
                        false,
                    )
                "max_hp_heal":
                    var amount := maxi(0, int(floor(
                        float(_runtime["units"][unit_id]["max_hp"])
                        * float(tick.get("value", 0.0))
                        * float(stacks)
                    )))
                    _apply_heal(unit_id, amount, str(instance.get("source_id", status_id)), status_id)
                "flat_heal":
                    _apply_heal(
                        unit_id,
                        maxi(0, int(float(tick.get("value", 0.0)) * stacks)),
                        str(instance.get("source_id", status_id)),
                        status_id,
                    )
        if not _unit_is_alive(unit_id):
            break
        if (
            str(definition.get("duration_timing", definition.get("duration_tick", "round_end"))) == timing
            and str(definition.get("expiry", "duration")) != "next_action"
        ):
            var current: Dictionary = _runtime["units"][unit_id]["statuses"].get(status_id, {})
            if current.is_empty():
                continue
            current["duration"] = int(current.get("duration", 1)) - 1
            if int(current["duration"]) <= 0:
                _remove_status(unit_id, status_id)
            else:
                _runtime["units"][unit_id]["statuses"][status_id] = current


func _expire_owner_turn_start_statuses(unit_id: String) -> void:
    var unit: Dictionary = _runtime["units"][unit_id]
    var status_ids: Array = unit["statuses"].keys()
    for raw_status_id: Variant in status_ids:
        var status_id := str(raw_status_id)
        var definition: Dictionary = _status_definitions.get(status_id, {})
        if (
            bool(definition.get("expires_on_owner_turn_start", false))
            or str(definition.get("expiry", "")) == "next_action"
        ) and not bool(definition.get("prevents_action", definition.get("block_action", false))):
            _remove_status(unit_id, status_id)


func _blocking_status(unit_id: String) -> String:
    var status_ids: Array = _runtime["units"][unit_id]["statuses"].keys()
    status_ids.sort()
    for raw_status_id: Variant in status_ids:
        var status_id := str(raw_status_id)
        var definition: Dictionary = _status_definitions.get(status_id, {})
        if bool(definition.get("prevents_action", definition.get("block_action", false))):
            return status_id
    return ""


func _effective_stat(unit_id: String, stat_name: String) -> float:
    if not _runtime.get("units", {}).has(unit_id):
        return 0.0
    var unit: Dictionary = _runtime["units"][unit_id]
    var value := float(unit.get(stat_name, 0.0))
    var raw_phase_modifiers: Variant = _runtime.get("phase_modifiers", {}).get(unit_id, [])
    if raw_phase_modifiers is Dictionary:
        value += float(raw_phase_modifiers.get(stat_name, 0.0))
    elif raw_phase_modifiers is Array:
        for raw_modifier: Variant in raw_phase_modifiers:
            if not raw_modifier is Dictionary or str(raw_modifier.get("stat", "")) != stat_name:
                continue
            var modifier_value := float(raw_modifier.get("value", 0.0))
            match str(raw_modifier.get("operation", "flat")):
                "add_percent":
                    value += float(unit.get(stat_name, 0.0)) * modifier_value
                "multiply":
                    value *= modifier_value
                _:
                    value += modifier_value
    for raw_status_id: Variant in unit["statuses"].keys():
        var status_id := str(raw_status_id)
        var definition: Dictionary = _status_definitions.get(status_id, {})
        var instance: Dictionary = unit["statuses"][status_id]
        var stacks := int(instance.get("stacks", 1))
        var magnitude := float(instance.get("magnitude", 1.0))
        for raw_modifier: Variant in definition.get("stat_modifiers", []):
            if not raw_modifier is Dictionary or str(raw_modifier.get("stat", "")) != stat_name:
                continue
            var modifier_value := float(raw_modifier.get("value", 0.0)) * float(stacks) * magnitude
            match str(raw_modifier.get("operation", "flat")):
                "add_percent":
                    value += float(unit.get(stat_name, 0.0)) * modifier_value
                "multiply":
                    value *= modifier_value
                _:
                    value += modifier_value
            value *= float(raw_modifier.get("multiplier", 1.0))
    return value


func _direct_damage_multiplier(unit_id: String) -> float:
    var multiplier := 1.0
    var unit: Dictionary = _runtime["units"][unit_id]
    for raw_status_id: Variant in unit["statuses"].keys():
        var definition: Dictionary = _status_definitions.get(str(raw_status_id), {})
        var reduction := float(definition.get("direct_damage_reduction", 0.0))
        multiplier *= 1.0 - clampf(reduction, 0.0, 1.0)
        multiplier *= maxf(0.0, float(definition.get("direct_damage_multiplier", 1.0)))
    return multiplier


func _decrement_cooldowns(unit_id: String) -> void:
    var unit: Dictionary = _runtime["units"][unit_id]
    var skill_ids: Array = unit["cooldowns"].keys()
    for raw_skill_id: Variant in skill_ids:
        var skill_id := str(raw_skill_id)
        var remaining := maxi(0, int(unit["cooldowns"][skill_id]) - 1)
        if remaining <= 0:
            unit["cooldowns"].erase(skill_id)
        else:
            unit["cooldowns"][skill_id] = remaining
    _runtime["units"][unit_id] = unit


func _choose_ai_command(actor_id: String) -> Dictionary:
    var unit: Dictionary = _runtime["units"][actor_id]
    var actions: Array = _ai_actions_with_phase_weights(actor_id)
    if actions.is_empty():
        actions = [{
            "action_id": "fallback_attack",
            "mode": "weighted_action",
            "action_type": "attack",
            "weight": 1.0,
            "target_priority": "lowest_hp",
        }]
    var targets_by_action_id := {}
    for raw_action: Variant in actions:
        if not raw_action is Dictionary:
            continue
        var action: Dictionary = raw_action
        var action_id := str(action.get("action_id", ""))
        if action_id.is_empty():
            continue
        targets_by_action_id[action_id] = _preselect_ai_target(actor_id, action, true)
    var filter := func(action: Dictionary) -> bool:
        var target_id := str(targets_by_action_id.get(str(action.get("action_id", "")), ""))
        return (
            _ai_action_conditions_met(actor_id, action, target_id)
            and _ai_action_is_usable(actor_id, action, target_id)
        )
    var tendency := str(_runtime.get("companion_tendency", "offensive")) if str(unit["role"]) == "companion" else ""
    var action: Dictionary = _ai_controller.choose_action(actions, tendency, filter, _rng)
    if action.is_empty():
        var fallback_target := _select_target(actor_id, "lowest_hp", "enemy_single")
        if fallback_target.is_empty():
            return {}
        return {"type": "attack", "actor_id": actor_id, "target_id": fallback_target}
    var action_type := str(action.get("action_type", "attack"))
    var command := {"type": action_type, "actor_id": actor_id}
    if action_type == "skill":
        command["skill_id"] = str(action.get("skill_id", ""))
        command["target_id"] = str(targets_by_action_id.get(str(action.get("action_id", "")), ""))
    elif action_type in ["attack", "inspect"]:
        command["target_id"] = str(targets_by_action_id.get(str(action.get("action_id", "")), ""))
    return command


func _ai_actions_with_phase_weights(actor_id: String) -> Array:
    var unit: Dictionary = _runtime["units"][actor_id]
    var actions: Array = unit.get("ai_actions", []).duplicate(true)
    var phase_weights: Dictionary = _runtime.get("phase_ai_weight_modifiers", {}).get(actor_id, {})
    for raw_action: Variant in actions:
        if not raw_action is Dictionary:
            continue
        var action_id := str(raw_action.get("action_id", ""))
        if phase_weights.has(action_id):
            raw_action["weight"] = float(raw_action.get("weight", 0.0)) * float(phase_weights[action_id])
    return actions


func _preselect_ai_target(actor_id: String, action: Dictionary, consume_random: bool) -> String:
    var action_type := str(action.get("action_type", ""))
    if action_type == "defend":
        return actor_id
    var target_type := "enemy_single"
    if action_type == "skill":
        var skill: Dictionary = _skills.get(str(action.get("skill_id", "")), {})
        target_type = str(skill.get("target", "enemy_single"))
    return _select_target(
        actor_id,
        str(action.get("target_priority", "lowest_hp")),
        target_type,
        consume_random,
    )


func _ai_action_conditions_met(actor_id: String, action: Dictionary, target_id: String = "") -> bool:
    if target_id.is_empty():
        target_id = _preselect_ai_target(actor_id, action, false)
    return _conditions_met(action.get("conditions", []), actor_id, target_id)


func _ai_action_is_usable(actor_id: String, action: Dictionary, target_id: String = "") -> bool:
    var action_type := str(action.get("action_type", ""))
    if action_type not in ["attack", "defend", "skill", "inspect"]:
        return false
    if action_type == "defend":
        return true
    if action_type in ["attack", "inspect"]:
        return not (target_id if not target_id.is_empty() else _preselect_ai_target(
            actor_id,
            action,
            false,
        )).is_empty()
    var skill_id := str(action.get("skill_id", ""))
    if not _skills.has(skill_id) or skill_id not in _available_skills(actor_id):
        return false
    if str(_skills[skill_id].get("kind", "")) not in ["active", "companion"]:
        return false
    var unit: Dictionary = _runtime["units"][actor_id]
    if int(unit["cooldowns"].get(skill_id, 0)) > 0:
        return false
    var limit: Variant = _skills[skill_id].get("uses_per_battle")
    if limit != null and int(unit["skill_uses"].get(skill_id, 0)) >= int(limit):
        return false
    var skill: Dictionary = _skills[skill_id]
    if target_id.is_empty():
        target_id = _preselect_ai_target(actor_id, action, false)
    return _skill_conditions_met(actor_id, skill, target_id)


func _conditions_met(raw_conditions: Variant, actor_id: String, target_id: String) -> bool:
    if not raw_conditions is Array:
        return false
    for raw_condition: Variant in raw_conditions:
        if not raw_condition is Dictionary:
            return false
        var condition: Dictionary = raw_condition
        var kind := str(condition.get("type", condition.get("kind", "")))
        match kind:
            "hp_threshold", "actor_hp_lte":
                var subject := str(condition.get("subject", "self"))
                var subject_id := actor_id
                if subject == "target":
                    subject_id = target_id
                elif subject == "player":
                    subject_id = _first_living_role("player")
                elif subject == "companion":
                    subject_id = _first_living_role("companion")
                if subject_id.is_empty():
                    return false
                var ratio := _hp_ratio(subject_id)
                var operator := str(condition.get("operator", condition.get("op", "lte")))
                var value := float(condition.get("value", 0.0))
                if not _compare_number(ratio, operator, value):
                    return false
            "actor_stat":
                var stat_value := _effective_stat(actor_id, str(condition.get("stat", "")))
                if not _compare_number(
                    stat_value,
                    str(condition.get("operator", condition.get("op", "gte"))),
                    float(condition.get("value", 0.0)),
                ):
                    return false
            "status":
                var subject := str(condition.get("subject", "self"))
                var subject_id := actor_id if subject in ["self", "actor"] else target_id
                if condition.has("target_unit_id"):
                    subject_id = str(condition.get("target_unit_id", ""))
                elif subject == "player":
                    subject_id = _first_living_role("player")
                elif subject == "companion":
                    subject_id = _first_living_role("companion")
                var present := not subject_id.is_empty() and _unit_has_status(subject_id, str(condition.get("status_id", "")))
                if present != bool(condition.get("present", true)):
                    return false
            "actor_has_status":
                if not _unit_has_status(actor_id, str(condition.get("status_id", ""))):
                    return false
            "actor_missing_status":
                if _unit_has_status(actor_id, str(condition.get("status_id", ""))):
                    return false
            "target_has_status":
                var resolved_target := target_id
                if resolved_target.is_empty():
                    resolved_target = _select_target(actor_id, str(condition.get("target_priority", "player")), "enemy_single")
                if resolved_target.is_empty() or not _unit_has_status(resolved_target, str(condition.get("status_id", ""))):
                    return false
            "target_guarded":
                var resolved_target := target_id
                if resolved_target.is_empty():
                    resolved_target = _select_target(actor_id, "player", "enemy_single")
                var guard_id := str(_runtime["rules"].get("guard_status_id", "guard"))
                if resolved_target.is_empty() or not _unit_has_status(resolved_target, guard_id):
                    return false
            "target_guarding":
                var resolved_target := target_id
                if resolved_target.is_empty():
                    resolved_target = _select_target(actor_id, "player", "enemy_single")
                var guard_id := str(_runtime["rules"].get("guard_status_id", "guard"))
                var guarded := not resolved_target.is_empty() and _unit_has_status(resolved_target, guard_id)
                if guarded != bool(condition.get("expected", true)):
                    return false
            "phase":
                if str(_runtime.get("current_phase_id", "")) != str(
                    condition.get("phase_id", condition.get("value", ""))
                ):
                    return false
            "companion_alive":
                if _has_living_role("companion") != bool(
                    condition.get("expected", condition.get("value", true))
                ):
                    return false
            "game_state":
                var state_condition: Variant = condition.get("condition")
                if not state_condition is Dictionary or not bool(_game_state.call("evaluate_condition", state_condition)):
                    return false
            "always", "":
                pass
            _:
                return false
    return true


func _skill_conditions_met(actor_id: String, skill: Dictionary, target_id: String = "") -> bool:
    var runtime: Variant = skill.get("runtime")
    if not runtime is Dictionary:
        return true
    return _conditions_met(runtime.get("conditions", []), actor_id, target_id)


func _select_target(
    actor_id: String,
    priority: String,
    target_type: String,
    consume_random: bool = true,
) -> String:
    if target_type == "self":
        return actor_id
    var wants_allies := target_type in ["ally_single", "ally_all", "all_allies"]
    var allows_any := target_type == "any_single"
    var candidates: Array[String] = []
    for raw_unit_id: Variant in _runtime["stable_unit_ids"]:
        var unit_id := str(raw_unit_id)
        if not _unit_is_alive(unit_id):
            continue
        if allows_any:
            candidates.append(unit_id)
        elif wants_allies and _same_team(actor_id, unit_id):
            candidates.append(unit_id)
        elif not wants_allies and not _same_team(actor_id, unit_id):
            candidates.append(unit_id)
    if candidates.is_empty():
        return ""
    match priority:
        "self":
            if actor_id in candidates:
                return actor_id
        "player":
            for unit_id: String in candidates:
                if str(_runtime["units"][unit_id]["role"]) == "player":
                    return unit_id
        "companion":
            for unit_id: String in candidates:
                if str(_runtime["units"][unit_id]["role"]) == "companion":
                    return unit_id
        "lowest_hp":
            candidates.sort_custom(func(left: String, right: String) -> bool:
                var left_ratio := _hp_ratio(left)
                var right_ratio := _hp_ratio(right)
                return left_ratio < right_ratio if not is_equal_approx(left_ratio, right_ratio) else left < right
            )
        "highest_attack":
            candidates.sort_custom(func(left: String, right: String) -> bool:
                var left_attack := _effective_stat(left, "attack")
                var right_attack := _effective_stat(right, "attack")
                return left_attack > right_attack if not is_equal_approx(left_attack, right_attack) else left < right
            )
        "highest_hp":
            candidates.sort_custom(func(left: String, right: String) -> bool:
                var left_ratio := _hp_ratio(left)
                var right_ratio := _hp_ratio(right)
                return left_ratio > right_ratio if not is_equal_approx(left_ratio, right_ratio) else left < right
            )
        "random", "random_opponent":
            if consume_random:
                return candidates[_rng.range_int(0, candidates.size() - 1)]
            candidates.sort()
        _:
            candidates.sort()
    return candidates[0]


func _resolve_targets(actor_id: String, target_type: String, requested_target: String) -> Dictionary:
    match target_type:
        "self":
            return _result(true, "OK", "Skill target resolved", actor_id, {"targets": [actor_id]})
        "enemy_single":
            if not _is_legal_opponent(actor_id, requested_target):
                return _fail(COMBAT_TARGET_INVALID, "Skill target must be a living opponent", requested_target)
            return _result(true, "OK", "Skill target resolved", actor_id, {"targets": [requested_target]})
        "ally_single":
            if not _runtime["units"].has(requested_target) or not _same_team(actor_id, requested_target) or not _unit_is_alive(requested_target):
                return _fail(COMBAT_TARGET_INVALID, "Skill target must be a living ally", requested_target)
            return _result(true, "OK", "Skill target resolved", actor_id, {"targets": [requested_target]})
        "any_single":
            if not _runtime["units"].has(requested_target) or not _unit_is_alive(requested_target):
                return _fail(COMBAT_TARGET_INVALID, "Skill target must be a living combat unit", requested_target)
            return _result(true, "OK", "Skill target resolved", actor_id, {"targets": [requested_target]})
        "enemy_all", "ally_all", "all_enemies", "all_allies":
            var targets: Array = []
            var allies := target_type in ["ally_all", "all_allies"]
            for raw_unit_id: Variant in _runtime["stable_unit_ids"]:
                var unit_id := str(raw_unit_id)
                if not _unit_is_alive(unit_id):
                    continue
                if _same_team(actor_id, unit_id) == allies:
                    targets.append(unit_id)
            if targets.is_empty():
                return _fail(COMBAT_TARGET_INVALID, "Skill has no legal targets")
            return _result(true, "OK", "Skill targets resolved", actor_id, {"targets": targets})
        _:
            return _fail(COMBAT_TARGET_INVALID, "Unknown skill target type '%s'" % target_type)


func _validate_effects(raw_effects: Variant) -> bool:
    if not raw_effects is Array or raw_effects.is_empty():
        _record_error(COMBAT_DEFINITION_INVALID, "Combat effect list must be a non-empty array")
        return false
    for raw_effect: Variant in raw_effects:
        if not raw_effect is Dictionary:
            _record_error(COMBAT_DEFINITION_INVALID, "Combat effect must be an object")
            return false
        var effect_type := str(raw_effect.get("effect", raw_effect.get("type", "")))
        if effect_type not in [
            "damage", "heal", "apply_status", "remove_status", "reveal",
            "reveal_mechanic", "state_effect",
        ]:
            _record_error(COMBAT_DEFINITION_INVALID, "Unknown combat effect '%s'" % effect_type)
            return false
        if effect_type in ["apply_status", "remove_status"]:
            var status_id := str(raw_effect.get("status_id", ""))
            if not _status_definitions.has(status_id):
                _record_error(COMBAT_DEFINITION_INVALID, "Combat effect references unknown status", status_id)
                return false
    return true


func _activate_start_phase() -> void:
    var phases: Array = _runtime["definition"].get("phases", [])
    for raw_phase: Variant in phases:
        if not raw_phase is Dictionary:
            continue
        var trigger: Variant = raw_phase.get("trigger")
        if trigger is Dictionary and str(trigger.get("type", "")) == "combat_start":
            _activate_phase(raw_phase)
            return
        if trigger is String and str(trigger) == "combat_start":
            _activate_phase(raw_phase)
            return


func _check_phase_transitions(event_tag: String) -> void:
    if not _active:
        return
    var phases: Array = _runtime["definition"].get("phases", [])
    for raw_phase: Variant in phases:
        if not raw_phase is Dictionary:
            continue
        var phase: Dictionary = raw_phase
        var phase_id := str(phase.get("phase_id", ""))
        if phase_id.is_empty() or phase_id in _runtime["triggered_phases"]:
            continue
        if _phase_trigger_matches(phase.get("trigger"), phase, event_tag):
            _activate_phase(phase)


func _phase_trigger_matches(trigger: Variant, phase: Dictionary, event_tag: String) -> bool:
    if trigger is String:
        var text := str(trigger)
        if text.begins_with("hp_lte_"):
            var threshold := float(text.trim_prefix("hp_lte_")) / 100.0
            return _hp_ratio(_phase_unit_id(phase)) <= threshold
        return false
    if not trigger is Dictionary:
        return false
    var trigger_type := str(trigger.get("type", ""))
    match trigger_type:
        "hp_threshold":
            return _compare_number(
                _hp_ratio(str(trigger.get("unit_id", _phase_unit_id(phase)))),
                str(trigger.get("operator", trigger.get("op", "lte"))),
                float(trigger.get("value", 0.0)),
            )
        "status":
            var present := _unit_has_status(
                str(trigger.get("unit_id", _phase_unit_id(phase))),
                str(trigger.get("status_id", "")),
            )
            return present == bool(trigger.get("present", true))
        "event":
            return not event_tag.is_empty() and event_tag == str(trigger.get("event_tag", ""))
        _:
            return false


func _activate_phase(phase: Dictionary) -> void:
    var phase_id := str(phase.get("phase_id", ""))
    if phase_id.is_empty() or phase_id in _runtime["triggered_phases"]:
        return
    var old_phase := str(_runtime.get("current_phase_id", ""))
    _runtime["triggered_phases"].append(phase_id)
    _runtime["current_phase_id"] = phase_id
    var unit_id := _phase_unit_id(phase)
    if not unit_id.is_empty():
        _runtime["phase_modifiers"][unit_id] = phase.get("stat_modifiers", []).duplicate(true)
        if phase.has("skill_ids"):
            _runtime["phase_skill_ids"][unit_id] = phase["skill_ids"].duplicate(true)
        if phase.get("ai_weight_modifiers") is Dictionary:
            _runtime["phase_ai_weight_modifiers"][unit_id] = phase["ai_weight_modifiers"].duplicate(true)
    var event_tag := str(phase.get("event_tag", ""))
    if not event_tag.is_empty():
        _append_important_event("phase:%s" % event_tag)
    phase_changed.emit({
        "combat_id": str(_runtime["combat_id"]),
        "old_phase_id": old_phase,
        "new_phase_id": phase_id,
        "unit_id": unit_id,
        "event_tag": event_tag,
    })


func _phase_unit_id(phase: Dictionary) -> String:
    var configured := str(phase.get("unit_id", phase.get("target_unit_id", "")))
    if not configured.is_empty():
        return configured
    for raw_unit_id: Variant in _runtime.get("stable_unit_ids", []):
        var unit_id := str(raw_unit_id)
        if str(_runtime["units"][unit_id]["role"]) != "enemy":
            continue
        var definition_id := str(_runtime["units"][unit_id].get("definition_id", ""))
        if _enemies.has(definition_id) and bool(_enemies[definition_id].get("boss", false)):
            return unit_id
    for raw_unit_id: Variant in _runtime.get("stable_unit_ids", []):
        var unit_id := str(raw_unit_id)
        if str(_runtime["units"][unit_id]["role"]) == "enemy":
            return unit_id
    return ""


func _check_end_conditions() -> void:
    if not _active:
        return
    if not _has_living_role("player"):
        var rules: Dictionary = _runtime["definition"].get("result_rules", {})
        var defeat: Dictionary = rules.get("defeat", _runtime["outcomes"].get("defeat", {}))
        var result_type := str(defeat.get("result_type", "defeat"))
        if result_type not in RESULT_TYPES:
            result_type = "defeat"
        _finish_combat(result_type, str(defeat.get("continuation_tag", "")), "player_defeated")
        return
    if not _has_living_role("enemy"):
        var rules: Dictionary = _runtime["definition"].get("result_rules", {})
        var victory: Dictionary = rules.get("victory", _runtime["outcomes"].get("victory", {}))
        _finish_combat("victory", str(victory.get("continuation_tag", "")), "enemies_defeated")


func _finish_combat(result_type: String, continuation_tag: String, event_tag: String) -> void:
    if not _active:
        return
    var units: Dictionary = _runtime["units"]
    var stable_ids: Array = _runtime["stable_unit_ids"]
    var defeated: Array = []
    var surviving: Array = []
    for raw_unit_id: Variant in stable_ids:
        var unit_id := str(raw_unit_id)
        if bool(units[unit_id].get("alive", false)) and not bool(units[unit_id].get("withdrawn", false)):
            surviving.append(unit_id)
        else:
            defeated.append(unit_id)
    var consumed: Array = []
    var item_ids: Array = _runtime["consumed_items"].keys()
    item_ids.sort()
    for raw_item_id: Variant in item_ids:
        var item_id := str(raw_item_id)
        consumed.append({"item_id": item_id, "quantity": int(_runtime["consumed_items"][item_id])})
    var final_rng := _rng.export_state()
    var result := {
        "ok": true,
        "code": "OK",
        "message": "Combat finished",
        "combat_id": str(_runtime["combat_id"]),
        "result_type": result_type,
        "defeated_units": defeated,
        "surviving_units": surviving,
        "turns_elapsed": int(_runtime["actions_elapsed"]),
        "rounds_elapsed": int(_runtime["round"]),
        "consumed_items": consumed,
        "important_events": _runtime["important_events"].duplicate(true),
        "continuation_tag": continuation_tag,
        "random_state": final_rng,
        "finish_event": event_tag,
    }
    if _save_manager != null:
        var persistent_random := final_rng.duplicate(true)
        persistent_random["scope"] = "postcombat"
        persistent_random["combat_id"] = str(_runtime["combat_id"])
        _save_manager.call("set_random_state", persistent_random)
    _last_result = result.duplicate(true)
    _active = false
    _runtime = {}
    combat_finished.emit(result.duplicate(true))


func _on_unit_defeated(unit_id: String, source_id: String) -> void:
    _append_important_event("defeated:%s" % unit_id)
    unit_defeated.emit({
        "unit_id": unit_id,
        "source_id": source_id,
        "round": int(_runtime.get("round", 0)),
    })


func _append_important_event(event_text: String) -> void:
    if not event_text.is_empty() and event_text not in _runtime["important_events"]:
        _runtime["important_events"].append(event_text)


func _available_skills(unit_id: String) -> Array:
    if _runtime.get("phase_skill_ids", {}).has(unit_id):
        return _runtime["phase_skill_ids"][unit_id].duplicate(true)
    return _runtime["units"][unit_id]["skill_ids"].duplicate(true)


func _unit_can_take_turn(unit_id: String) -> bool:
    return _runtime.get("units", {}).has(unit_id) and _unit_is_alive(unit_id) and not bool(
        _runtime["units"][unit_id].get("withdrawn", false)
    )


func _unit_can_act(unit_id: String) -> bool:
    return _unit_can_take_turn(unit_id) and _blocking_status(unit_id).is_empty()


func _unit_is_alive(unit_id: String) -> bool:
    return _runtime.get("units", {}).has(unit_id) and bool(_runtime["units"][unit_id].get("alive", false)) and float(
        _runtime["units"][unit_id].get("hp", 0.0)
    ) > 0.0


func _unit_has_status(unit_id: String, status_id: String) -> bool:
    return _runtime.get("units", {}).has(unit_id) and _runtime["units"][unit_id]["statuses"].has(status_id)


func _same_team(left_id: String, right_id: String) -> bool:
    return (
        _runtime.get("units", {}).has(left_id)
        and _runtime.get("units", {}).has(right_id)
        and str(_runtime["units"][left_id]["team"]) == str(_runtime["units"][right_id]["team"])
    )


func _is_legal_opponent(actor_id: String, target_id: String) -> bool:
    return (
        _runtime.get("units", {}).has(actor_id)
        and _runtime.get("units", {}).has(target_id)
        and not _same_team(actor_id, target_id)
        and _unit_is_alive(target_id)
    )


func _has_living_role(role: String) -> bool:
    return _has_living_role_in(_runtime.get("units", {}), role)


func _first_living_role(role: String) -> String:
    for raw_unit_id: Variant in _runtime.get("stable_unit_ids", []):
        var unit_id := str(raw_unit_id)
        if str(_runtime["units"][unit_id].get("role", "")) == role and _unit_is_alive(unit_id):
            return unit_id
    return ""


func _has_living_role_in(units: Dictionary, role: String) -> bool:
    for raw_unit: Variant in units.values():
        if raw_unit is Dictionary and str(raw_unit.get("role", "")) == role and bool(raw_unit.get("alive", false)) and float(raw_unit.get("hp", 0.0)) > 0.0:
            return true
    return false


func _hp_ratio(unit_id: String) -> float:
    if not _runtime.get("units", {}).has(unit_id):
        return 0.0
    var unit: Dictionary = _runtime["units"][unit_id]
    return clampf(float(unit.get("hp", 0.0)) / maxf(1.0, float(unit.get("max_hp", 1.0))), 0.0, 1.0)


func _compare_number(left: float, operator: String, right: float) -> bool:
    match operator:
        "lt":
            return left < right
        "lte":
            return left <= right
        "gt":
            return left > right
        "gte":
            return left >= right
        "eq":
            return is_equal_approx(left, right)
        "neq", "ne":
            return not is_equal_approx(left, right)
        _:
            return false


func _public_units() -> Array:
    var units: Array = []
    for raw_unit_id: Variant in _runtime.get("stable_unit_ids", []):
        units.append(_runtime["units"][str(raw_unit_id)].duplicate(true))
    return units


func _safety_result_type() -> String:
    var rules: Dictionary = _runtime["definition"].get("result_rules", {})
    var safety: Dictionary = rules.get("safety_limit", {})
    if safety.is_empty():
        var partial: Dictionary = rules.get("partial_success", {})
        if str(partial.get("condition", "")) == "turn_limit":
            return "partial_success"
    var result_type := str(safety.get("result_type", "partial_success"))
    return result_type if result_type in RESULT_TYPES else "partial_success"


func _safety_continuation_tag() -> String:
    var rules: Dictionary = _runtime["definition"].get("result_rules", {})
    var safety: Dictionary = rules.get("safety_limit", {})
    if safety.is_empty():
        var partial: Dictionary = rules.get("partial_success", {})
        if str(partial.get("condition", "")) == "turn_limit":
            return str(partial.get("continuation_tag", "round_limit"))
    return str(safety.get("continuation_tag", "round_limit"))


func _validate_rule_values() -> bool:
    if int(_rules.get("initiative_random_max", 3)) < int(_rules.get("initiative_random_min", 0)):
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "Initiative random range is reversed")
    if float(_rules.get("damage_variance_max", 1.15)) < float(_rules.get("damage_variance_min", 0.85)):
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "Damage variance range is reversed")
    if int(_rules.get("minimum_damage", 1)) < 0 or int(_rules.get("max_rounds", 100)) < 1:
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "Combat minimum damage or round limit is invalid")
    return true


func _validate_runtime_definitions() -> bool:
    for raw_enemy_id: Variant in _enemies.keys():
        var enemy: Dictionary = _enemies[raw_enemy_id]
        var runtime: Variant = enemy.get("runtime")
        if runtime is Dictionary and not _validate_ai_skill_references(
            str(raw_enemy_id),
            enemy.get("skill_ids", []),
            runtime.get("ai_actions", []),
        ):
            return false
    for raw_combat_id: Variant in _combats.keys():
        var combat_id := str(raw_combat_id)
        var combat: Dictionary = _combats[combat_id]
        if not combat.get("runtime") is Dictionary:
            continue
        var runtime: Dictionary = combat["runtime"]
        if not runtime.get("player_unit") is Dictionary:
            return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime combat '%s' has no player unit" % combat_id, combat_id)
        if not runtime.get("enemy_instances") is Array or runtime["enemy_instances"].is_empty():
            return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime combat '%s' has no enemy instances" % combat_id, combat_id)
        var unit_ids := {}
        var all_units: Array = [runtime["player_unit"]]
        all_units.append_array(runtime.get("companion_units", []))
        all_units.append_array(runtime.get("enemy_instances", []))
        for raw_unit: Variant in all_units:
            if not raw_unit is Dictionary:
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime combat unit must be an object", combat_id)
            var unit_id := str(raw_unit.get("unit_id", ""))
            if unit_id.is_empty() or unit_ids.has(unit_id):
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime combat unit IDs must be unique", combat_id)
            unit_ids[unit_id] = true
            if not _validate_ai_skill_references(
                unit_id,
                raw_unit.get("skill_ids", []),
                raw_unit.get("ai_actions", []),
            ):
                return false
            for raw_skill_id: Variant in raw_unit.get("skill_ids", []):
                if not _skills.has(str(raw_skill_id)):
                    return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime unit references unknown skill", str(raw_skill_id))
            if raw_unit.has("enemy_id") and not _enemies.has(str(raw_unit["enemy_id"])):
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Runtime unit references unknown enemy", str(raw_unit["enemy_id"]))
        var phase_ids := {}
        for raw_phase: Variant in runtime.get("phases", []):
            if not raw_phase is Dictionary:
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Combat phase must be an object", combat_id)
            var phase_id := str(raw_phase.get("phase_id", ""))
            if phase_id.is_empty() or phase_ids.has(phase_id):
                return _initialize_fail(COMBAT_DEFINITION_INVALID, "Combat phase IDs must be unique", combat_id)
            phase_ids[phase_id] = true
    return true


func _validate_ai_skill_references(owner_id: String, raw_skill_ids: Variant, raw_actions: Variant) -> bool:
    if not raw_skill_ids is Array or not raw_actions is Array:
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "AI skill/action collections must be arrays", owner_id)
    var equipped := {}
    for raw_skill_id: Variant in raw_skill_ids:
        equipped[str(raw_skill_id)] = true
    for raw_action: Variant in raw_actions:
        if not raw_action is Dictionary:
            return _initialize_fail(COMBAT_DEFINITION_INVALID, "AI action must be an object", owner_id)
        if str(raw_action.get("action_type", "")) != "skill":
            continue
        var skill_id := str(raw_action.get("skill_id", ""))
        if not equipped.has(skill_id):
            return _initialize_fail(
                COMBAT_DEFINITION_INVALID,
                "AI action references unequipped skill '%s'" % skill_id,
                owner_id,
            )
    return true


func _index_definitions(raw_definitions: Variant, id_field: String, destination: Dictionary) -> bool:
    if not raw_definitions is Array:
        return _initialize_fail(COMBAT_DEFINITION_INVALID, "Content definition collection must be an array")
    for raw_definition: Variant in raw_definitions:
        if not raw_definition is Dictionary:
            return _initialize_fail(COMBAT_DEFINITION_INVALID, "Content definition must be an object")
        var global_id := str(raw_definition.get(id_field, ""))
        if global_id.is_empty() or destination.has(global_id):
            return _initialize_fail(COMBAT_DEFINITION_INVALID, "Content definition IDs must be non-empty and unique", global_id)
        destination[global_id] = raw_definition.duplicate(true)
    return true


func _merged_dictionary(base: Dictionary, overrides: Variant) -> Dictionary:
    var merged := base.duplicate(true)
    if overrides is Dictionary:
        for key: Variant in overrides.keys():
            merged[key] = overrides[key]
    return merged


func _is_number(value: Variant) -> bool:
    return value is int or value is float


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and is_equal_approx(value, floor(value)))


func _require_initialized() -> bool:
    if _initialized:
        return true
    _record_error(COMBAT_NOT_INITIALIZED, "CombatRunner is not initialized")
    return false


func _require_initialized_bool() -> bool:
    return _require_initialized()


func _require_active() -> bool:
    if not _require_initialized():
        return false
    if _active:
        return true
    _record_error(COMBAT_NOT_ACTIVE, "No combat is active")
    return false


func _initialize_fail(code: String, message: String, subject_id: String = "") -> bool:
    _record_error(code, message, subject_id)
    _clear_runtime_only()
    _initialized = false
    return false


func _snapshot_fail(message: String) -> bool:
    _record_error(COMBAT_SNAPSHOT_INVALID, message)
    return false


func _fail(
    code: String,
    message: String,
    subject_id: String = "",
    extra: Dictionary = {},
) -> Dictionary:
    return _record_error(code, message, subject_id, extra)


func _record_error(
    code: String,
    message: String,
    subject_id: String = "",
    extra: Dictionary = {},
) -> Dictionary:
    last_error = _result(false, code, message, subject_id, extra)
    combat_error.emit(last_error.duplicate(true))
    return last_error.duplicate(true)


func _result(
    ok: bool,
    code: String,
    message: String,
    subject_id: String = "",
    extra: Dictionary = {},
) -> Dictionary:
    var result := {"ok": ok, "code": code, "message": message}
    if not subject_id.is_empty():
        result["subject_id"] = subject_id
    for key: Variant in extra.keys():
        result[key] = extra[key]
    return result


func _clear_runtime_only() -> void:
    _runtime = {}
    _last_result = {}
    _active = false
    _rng = CombatRngClass.new()


func _clear_all() -> void:
    if _save_manager != null and _save_manager.has_method("set_runtime_guard"):
        _save_manager.call("set_runtime_guard", null)
    _content_loader = null
    _game_state = null
    _inventory_manager = null
    _save_manager = null
    _combats = {}
    _enemies = {}
    _skills = {}
    _status_definitions = {}
    _rules = DEFAULT_RULES.duplicate(true)
    _initialized = false
    last_error = {}
    _clear_runtime_only()
