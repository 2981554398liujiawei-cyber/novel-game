extends RefCounted

signal quest_status_changed(quest_id: String, old_status: String, new_status: String, source: String)
signal quest_objective_changed(quest_id: String, objective_id: String, old_value: Variant, new_value: Variant, source: String)
signal quest_reward_ready(result: Dictionary)
signal quest_error(error: Dictionary)

const STATUSES := [
    "not_started", "available", "active", "qualified", "completed", "failed", "suspended",
]
const OBJECTIVE_TYPES := ["boolean", "counter", "collection", "combat_result", "state_condition"]
const QUEST_COMPARISON_OPERATORS := ["eq", "ne", "neq", "in", "not_in"]

const QUEST_NOT_INITIALIZED := "QUEST_NOT_INITIALIZED"
const QUEST_NOT_FOUND := "QUEST_NOT_FOUND"
const QUEST_DEFINITION_INVALID := "QUEST_DEFINITION_INVALID"
const QUEST_DEPENDENCY_CYCLE := "QUEST_DEPENDENCY_CYCLE"
const QUEST_PREREQUISITES_UNMET := "QUEST_PREREQUISITES_UNMET"
const QUEST_TRANSITION_INVALID := "QUEST_TRANSITION_INVALID"
const QUEST_OBJECTIVE_NOT_FOUND := "QUEST_OBJECTIVE_NOT_FOUND"
const QUEST_OBJECTIVE_UPDATE_INVALID := "QUEST_OBJECTIVE_UPDATE_INVALID"
const QUEST_NOT_QUALIFIED := "QUEST_NOT_QUALIFIED"
const QUEST_NOT_COMPLETABLE := "QUEST_NOT_COMPLETABLE"
const QUEST_CONTINUATION_INVALID := "QUEST_CONTINUATION_INVALID"
const QUEST_STATE_WRITE_FAILED := "QUEST_STATE_WRITE_FAILED"

var last_error: Dictionary = {}

var _content_loader: RefCounted
var _game_state: RefCounted
var _definitions: Dictionary = {}
var _objectives: Dictionary = {}
var _dependency_map: Dictionary = {}
var _mutual_exclusion_map: Dictionary = {}
var _managed_state_keys: Dictionary = {}
var _watched_state_keys: Dictionary = {}
var _initialized := false
var _mutation_depth := 0


func initialize(content_loader: RefCounted, game_state: RefCounted) -> bool:
    _disconnect_game_state()
    _clear_runtime()
    if content_loader == null or not content_loader.has_method("get_quest_definitions"):
        return _initialize_fail(QUEST_DEFINITION_INVALID, "ContentLoader does not provide quest definitions")
    if (
        game_state == null
        or not game_state.has_method("has_state")
        or not game_state.has_method("get_state")
        or not game_state.has_method("apply_effects")
        or not game_state.has_method("evaluate_condition")
    ):
        return _initialize_fail(QUEST_DEFINITION_INVALID, "GameState does not provide the required state interfaces")

    _content_loader = content_loader
    _game_state = game_state
    var raw_definitions: Variant = content_loader.call("get_quest_definitions")
    if not raw_definitions is Array:
        return _initialize_fail(QUEST_DEFINITION_INVALID, "Quest definitions must be an array")

    for raw_definition: Variant in raw_definitions:
        if not raw_definition is Dictionary:
            return _initialize_fail(QUEST_DEFINITION_INVALID, "Every quest definition must be an object")
        var definition: Dictionary = raw_definition
        if not definition.has("runtime"):
            continue
        var quest_id := str(definition.get("quest_id", ""))
        if quest_id.is_empty():
            return _initialize_fail(QUEST_DEFINITION_INVALID, "Quest ID cannot be empty")
        if _definitions.has(quest_id):
            return _initialize_fail(QUEST_DEFINITION_INVALID, "Duplicate quest definition '%s'" % quest_id, quest_id)
        _definitions[quest_id] = definition.duplicate(true)

    for quest_id: Variant in _definitions.keys():
        if not _validate_definition(str(quest_id)):
            _initialized = false
            return false
    if not _load_dependency_map():
        _initialized = false
        return false
    if not _validate_cross_references() or not _validate_dependency_cycles():
        _initialized = false
        return false

    _initialized = true
    if _game_state.has_signal("state_changed"):
        var callback := Callable(self, "_on_game_state_changed")
        if not _game_state.is_connected("state_changed", callback):
            _game_state.connect("state_changed", callback)
    var refresh_result := refresh_availability("system")
    if not bool(refresh_result.get("ok", false)):
        _initialized = false
        return false
    last_error = {}
    return true


func is_initialized() -> bool:
    return _initialized


func has_quest(quest_id: String) -> bool:
    return _definitions.has(quest_id)


func get_quest_definition(quest_id: String) -> Dictionary:
    if not _definitions.has(quest_id):
        _set_error(QUEST_NOT_FOUND, "Unknown quest '%s'" % quest_id, quest_id)
        return {}
    last_error = {}
    return _definitions[quest_id].duplicate(true)


func get_quest_status(quest_id: String) -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var status := _status(quest_id)
    return _result(true, "OK", "Quest status queried", quest_id, {"status": status})


func list_quests() -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    var quests: Array = []
    var quest_ids: Array = _definitions.keys()
    quest_ids.sort()
    for raw_quest_id: Variant in quest_ids:
        var quest_id := str(raw_quest_id)
        quests.append({"quest_id": quest_id, "status": _status(quest_id)})
    return _result(true, "OK", "Quests listed", "", {"quests": quests})


func refresh_availability(source: String = "system") -> Dictionary:
    if not _require_initialized():
        return last_error.duplicate(true)
    var changed: Array[String] = []
    var max_passes := maxi(1, _definitions.size() + 1)
    for _pass: int in range(max_passes):
        var pass_changed := false
        var quest_ids: Array = _definitions.keys()
        quest_ids.sort()
        for raw_quest_id: Variant in quest_ids:
            var quest_id := str(raw_quest_id)
            var current := _status(quest_id)
            if current not in ["not_started", "available"]:
                continue
            var availability := _availability_met(quest_id)
            if availability < 0:
                return last_error.duplicate(true)
            var target := "available" if availability == 1 else "not_started"
            if target == current:
                continue
            if not _write_status(quest_id, target, source):
                return last_error.duplicate(true)
            changed.append(quest_id)
            pass_changed = true
        if not pass_changed:
            break
    return _result(true, "OK", "Quest availability refreshed", "", {"changed_quest_ids": changed})


func refresh_quest(quest_id: String, source: String = "system") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current in ["not_started", "available"]:
        var availability := _availability_met(quest_id)
        if availability < 0:
            return last_error.duplicate(true)
        var target := "available" if availability == 1 else "not_started"
        if target != current and not _write_status(quest_id, target, source):
            return last_error.duplicate(true)
        return _result(true, "OK", "Quest availability refreshed", quest_id, {"status": _status(quest_id), "changed": target != current})
    if current in ["active", "qualified"]:
        return _refresh_progress_status(quest_id, source)
    return _result(true, "OK", "Quest does not require refresh", quest_id, {"status": current, "changed": false})


func transition_quest(quest_id: String, target_status: String, source: String = "quest", continuation_id: String = "") -> Dictionary:
    match target_status:
        "active":
            var current := "" if not has_quest(quest_id) else _status(quest_id)
            if current in ["failed", "suspended"]:
                return resume_quest(quest_id, source)
            return activate_quest(quest_id, source)
        "qualified":
            return set_qualified(quest_id, source)
        "completed":
            return complete_quest(quest_id, source)
        "failed":
            return fail_quest(quest_id, continuation_id, source)
        "suspended":
            return suspend_quest(quest_id, continuation_id, source)
        "available":
            return reopen_quest(quest_id, source)
        _:
            return _set_error(QUEST_TRANSITION_INVALID, "Unsupported target quest status '%s'" % target_status, quest_id)


func activate_quest(quest_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current in ["active", "qualified"]:
        return _result(true, "OK", "Quest is already active", quest_id, {"status": current, "changed": false})
    if current != "available":
        if current == "not_started":
            var availability := _availability_met(quest_id)
            if availability < 0:
                return last_error.duplicate(true)
            if availability == 1 and not _write_status(quest_id, "available", source):
                return last_error.duplicate(true)
            current = _status(quest_id)
        if current != "available":
            return _set_error(QUEST_PREREQUISITES_UNMET, "Quest is not available for activation", quest_id, {"status": current})
    var availability_now := _availability_met(quest_id)
    if availability_now < 0:
        return last_error.duplicate(true)
    if availability_now == 0:
        if current == "available" and not _write_status(quest_id, "not_started", source):
            return last_error.duplicate(true)
        return _set_error(QUEST_PREREQUISITES_UNMET, "Quest prerequisites or mutual exclusions changed before activation", quest_id, {"status": _status(quest_id)})
    if not _write_status(quest_id, "active", source):
        return last_error.duplicate(true)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest activated", quest_id, {"status": "active", "changed": true})


func set_qualified(quest_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current == "qualified":
        return _result(true, "OK", "Quest is already qualified", quest_id, {"status": current, "changed": false})
    if current != "active":
        return _set_error(QUEST_TRANSITION_INVALID, "Only an active quest can become qualified", quest_id, {"status": current})
    if not _runtime(quest_id).has("qualification") or not _qualification_met(quest_id):
        return _set_error(QUEST_NOT_QUALIFIED, "Quest qualification conditions are not met", quest_id, {"status": current})
    if not _write_status(quest_id, "qualified", source):
        return last_error.duplicate(true)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest qualified", quest_id, {"status": "qualified", "changed": true})


func complete_quest(quest_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current == "completed":
        return _result(true, "OK", "Quest is already completed", quest_id, {
            "status": current,
            "changed": false,
            "reward_emitted": false,
        })
    if current not in ["active", "qualified"]:
        return _set_error(QUEST_TRANSITION_INVALID, "Only an active or qualified quest can be completed", quest_id, {"status": current})
    var runtime: Dictionary = _runtime(quest_id)
    if str(runtime.get("completion_mode", "automatic")) == "automatic" and not _all_required_objectives_complete(quest_id):
        return _set_error(QUEST_NOT_COMPLETABLE, "Required quest objectives are incomplete", quest_id)
    return _commit_completion(quest_id, source)


func fail_quest(quest_id: String, continuation_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current not in ["active", "qualified"]:
        return _set_error(QUEST_TRANSITION_INVALID, "Only an active or qualified quest can fail", quest_id, {"status": current})
    if not _validate_continuation(quest_id, continuation_id):
        return last_error.duplicate(true)
    var failure: Dictionary = _runtime(quest_id)["failure"]
    var effects: Array = [
        {"op": "set", "key": _status_key(quest_id), "value": "failed"},
        {"op": "set", "key": str(failure["continuation_state_key"]), "value": continuation_id},
    ]
    if not _apply_quest_effects(effects, quest_id):
        return last_error.duplicate(true)
    quest_status_changed.emit(quest_id, current, "failed", source)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest failed with a continuation", quest_id, {
        "status": "failed", "changed": true, "continuation_id": continuation_id,
    })


func suspend_quest(quest_id: String, continuation_id: String = "", source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current == "suspended":
        return _result(true, "OK", "Quest is already suspended", quest_id, {"status": current, "changed": false})
    if current not in ["active", "qualified"]:
        return _set_error(QUEST_TRANSITION_INVALID, "Only an active or qualified quest can be suspended", quest_id, {"status": current})
    var failure: Dictionary = _runtime(quest_id)["failure"]
    var effects: Array = [{"op": "set", "key": _status_key(quest_id), "value": "suspended"}]
    if not continuation_id.is_empty():
        if not _validate_continuation(quest_id, continuation_id):
            return last_error.duplicate(true)
        effects.append({"op": "set", "key": str(failure["continuation_state_key"]), "value": continuation_id})
    if not _apply_quest_effects(effects, quest_id):
        return last_error.duplicate(true)
    quest_status_changed.emit(quest_id, current, "suspended", source)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest suspended", quest_id, {"status": "suspended", "changed": true})


func resume_quest(quest_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current not in ["failed", "suspended"]:
        return _set_error(QUEST_TRANSITION_INVALID, "Only a failed or suspended quest can resume", quest_id, {"status": current})
    var failure: Dictionary = _runtime(quest_id)["failure"]
    var continuation_id := str(_game_state.call("get_state", str(failure["continuation_state_key"])))
    if current == "failed" and not _validate_continuation(quest_id, continuation_id):
        return last_error.duplicate(true)
    if current == "suspended" and not continuation_id.is_empty() and not _validate_continuation(quest_id, continuation_id):
        return last_error.duplicate(true)
    var target_field := "resume_from_failed" if current == "failed" else "resume_from_suspended"
    var target := str(failure[target_field])
    if target == "available":
        var availability := _availability_met(quest_id)
        if availability != 1:
            return _set_error(QUEST_PREREQUISITES_UNMET, "Quest continuation is not currently available", quest_id)
    if not _write_status(quest_id, target, source):
        return last_error.duplicate(true)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest resumed", quest_id, {
        "status": target, "changed": true, "continuation_id": continuation_id,
    })


func reopen_quest(quest_id: String, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var current := _status(quest_id)
    if current == "available":
        return _result(true, "OK", "Quest is already available", quest_id, {"status": current, "changed": false})
    if current != "failed" or not bool(_runtime(quest_id)["failure"].get("reopen_allowed", false)):
        return _set_error(QUEST_TRANSITION_INVALID, "Quest cannot be reopened from its current state", quest_id, {"status": current})
    var availability := _availability_met(quest_id)
    if availability != 1:
        return _set_error(QUEST_PREREQUISITES_UNMET, "Quest prerequisites are not met for reopen", quest_id)
    if not _write_status(quest_id, "available", source):
        return last_error.duplicate(true)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest reopened", quest_id, {"status": "available", "changed": true})


func update_objective(quest_id: String, objective_id: String, update: Dictionary, source: String = "quest") -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    if not _objectives[quest_id].has(objective_id):
        return _set_error(QUEST_OBJECTIVE_NOT_FOUND, "Unknown objective '%s'" % objective_id, quest_id, {"objective_id": objective_id})
    var current_status := _status(quest_id)
    if current_status == "completed":
        return _result(true, "OK", "Completed quest objective update was ignored", quest_id, {
            "objective_id": objective_id,
            "changed": false,
            "status": current_status,
            "reward_emitted": false,
        })
    if current_status not in ["active", "qualified"]:
        return _set_error(QUEST_TRANSITION_INVALID, "Quest objectives can only update while active or qualified", quest_id, {"status": current_status})
    var objective: Dictionary = _objectives[quest_id][objective_id]
    if str(objective["type"]) == "state_condition":
        return _set_error(QUEST_OBJECTIVE_UPDATE_INVALID, "State-condition objectives are derived from GameState", quest_id, {"objective_id": objective_id})
    if not update.has("value"):
        return _set_error(QUEST_OBJECTIVE_UPDATE_INVALID, "Objective update is missing an absolute value", quest_id, {"objective_id": objective_id})

    var progress_key := str(objective["progress_state_key"])
    var old_value: Variant = _game_state.call("get_state", progress_key)
    var normalized := _normalize_objective_update(objective, old_value, update["value"], quest_id)
    if not bool(normalized.get("ok", false)):
        return last_error.duplicate(true)
    var new_value: Variant = normalized["value"]
    var next_status := _suggest_progress_status(quest_id, objective_id, new_value)
    var reward_key := str(_runtime(quest_id)["reward_granted_state_key"])
    var reward_was_granted := bool(_game_state.call("get_state", reward_key))
    var effects: Array = []
    if old_value != new_value:
        effects.append({"op": "set", "key": progress_key, "value": new_value})
    if next_status != current_status:
        effects.append({"op": "set", "key": _status_key(quest_id), "value": next_status})
    if next_status == "completed" and not reward_was_granted:
        effects.append({"op": "set", "key": reward_key, "value": true})
    if not effects.is_empty() and not _apply_quest_effects(effects, quest_id):
        return last_error.duplicate(true)

    if old_value != new_value:
        quest_objective_changed.emit(quest_id, objective_id, old_value, new_value, source)
    if next_status != current_status:
        quest_status_changed.emit(quest_id, current_status, next_status, source)
    var reward_emitted := next_status == "completed" and not reward_was_granted
    if reward_emitted:
        _emit_reward(quest_id, source)
    if next_status != current_status:
        _refresh_dependents(source)
    return _result(true, "OK", "Quest objective updated", quest_id, {
        "objective_id": objective_id,
        "old_value": old_value,
        "new_value": new_value,
        "changed": old_value != new_value or next_status != current_status,
        "status": next_status,
        "reward_emitted": reward_emitted,
    })


func get_objective_progress(quest_id: String, objective_id: String) -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    if not _objectives[quest_id].has(objective_id):
        return _set_error(QUEST_OBJECTIVE_NOT_FOUND, "Unknown objective '%s'" % objective_id, quest_id, {"objective_id": objective_id})
    var objective: Dictionary = _objectives[quest_id][objective_id]
    var progress: Variant
    var target: Variant
    if str(objective["type"]) == "state_condition":
        progress = _state_condition_matches(objective["condition"])
        if progress == null:
            return last_error.duplicate(true)
        target = true
    else:
        progress = _game_state.call("get_state", str(objective["progress_state_key"]))
        target = objective["target"]
    return _result(true, "OK", "Quest objective queried", quest_id, {
        "objective_id": objective_id,
        "type": str(objective["type"]),
        "progress": progress,
        "target": target,
        "completed": _objective_value_completed(objective, progress),
    })


func get_quest_progress(quest_id: String) -> Dictionary:
    if not _require_quest(quest_id):
        return last_error.duplicate(true)
    var progress: Array = []
    var objective_ids: Array = _objectives[quest_id].keys()
    objective_ids.sort()
    for raw_objective_id: Variant in objective_ids:
        var objective_result := get_objective_progress(quest_id, str(raw_objective_id))
        if not bool(objective_result.get("ok", false)):
            return objective_result
        progress.append(objective_result)
    return _result(true, "OK", "Quest progress queried", quest_id, {
        "status": _status(quest_id),
        "objectives": progress,
    })


func _validate_definition(quest_id: String) -> bool:
    var definition: Dictionary = _definitions[quest_id]
    var runtime: Variant = definition.get("runtime")
    if not runtime is Dictionary:
        return _definition_fail("Quest runtime definition must be an object", quest_id)
    for field_name: String in ["status_state_key", "reward_granted_state_key"]:
        if not _register_managed_key(str(runtime.get(field_name, "")), quest_id, field_name):
            return false
    var status_value: Variant = _game_state.call("get_state", str(runtime["status_state_key"]))
    if not status_value is String or status_value not in STATUSES:
        return _definition_fail("Quest status state must contain a registered lifecycle status", quest_id)
    var reward_value: Variant = _game_state.call("get_state", str(runtime["reward_granted_state_key"]))
    if not reward_value is bool:
        return _definition_fail("Quest reward marker state must be boolean", quest_id)
    if str(runtime.get("completion_mode", "")) not in ["automatic", "manual"]:
        return _definition_fail("Quest completion_mode is invalid", quest_id)

    var failure: Variant = runtime.get("failure")
    if not failure is Dictionary:
        return _definition_fail("Quest failure policy must be an object", quest_id)
    var continuation_key := str(failure.get("continuation_state_key", ""))
    if not _register_managed_key(continuation_key, quest_id, "continuation_state_key"):
        return false
    var continuation_value: Variant = _game_state.call("get_state", continuation_key)
    if not continuation_value is String:
        return _definition_fail("Quest continuation state must be a string", quest_id)
    var allowed_continuations: Variant = failure.get("allowed_continuations", [])
    if not allowed_continuations is Array:
        return _definition_fail("Quest allowed_continuations must be an array", quest_id)
    if not str(continuation_value).is_empty() and continuation_value not in allowed_continuations:
        return _definition_fail("Quest continuation state contains an unregistered value", quest_id)

    var raw_objectives: Variant = runtime.get("objectives", [])
    if not raw_objectives is Array:
        return _definition_fail("Quest objectives must be an array", quest_id)
    var objective_index := {}
    for raw_objective: Variant in raw_objectives:
        if not raw_objective is Dictionary:
            return _definition_fail("Every quest objective must be an object", quest_id)
        var objective: Dictionary = raw_objective
        var objective_id := str(objective.get("objective_id", ""))
        var objective_type := str(objective.get("type", ""))
        if objective_id.is_empty() or objective_index.has(objective_id):
            return _definition_fail("Quest objective IDs must be non-empty and unique", quest_id)
        if objective_type not in OBJECTIVE_TYPES:
            return _definition_fail("Unsupported objective type '%s'" % objective_type, quest_id)
        if not objective.has("required") or not objective["required"] is bool:
            return _definition_fail("Quest objective required flag must be boolean", quest_id)
        if objective_type == "state_condition":
            var condition: Variant = objective.get("condition")
            if not condition is Dictionary or not _validate_state_condition(condition, quest_id):
                return false
        else:
            var progress_key := str(objective.get("progress_state_key", ""))
            if not _register_managed_key(progress_key, quest_id, "objective '%s'" % objective_id):
                return false
            if not _validate_objective_value_contract(objective, quest_id):
                return false
        objective_index[objective_id] = objective.duplicate(true)
    _objectives[quest_id] = objective_index

    var availability: Variant = runtime.get("availability")
    if not availability is Dictionary:
        return _definition_fail("Quest availability must be an object", quest_id)
    for group_name: String in ["all", "any"]:
        var conditions: Variant = availability.get(group_name)
        if not conditions is Array:
            return _definition_fail("Quest availability '%s' must be an array" % group_name, quest_id)
        for raw_condition: Variant in conditions:
            if not raw_condition is Dictionary or not _validate_availability_condition(raw_condition, quest_id):
                return false

    if runtime.has("qualification"):
        var qualification: Variant = runtime["qualification"]
        if not qualification is Dictionary:
            return _definition_fail("Quest qualification must be an object", quest_id)
        var qualification_ids: Variant = qualification.get("objective_ids")
        var required_count: Variant = qualification.get("required_count")
        if not qualification_ids is Array or not _is_integer_value(required_count) or int(required_count) < 1:
            return _definition_fail("Quest qualification threshold is invalid", quest_id)
        if int(required_count) > qualification_ids.size():
            return _definition_fail("Quest qualification threshold exceeds its objective count", quest_id)
        for raw_objective_id: Variant in qualification_ids:
            if not objective_index.has(str(raw_objective_id)):
                return _definition_fail("Quest qualification references an unknown objective", quest_id)
    return true


func _load_dependency_map() -> bool:
    for quest_id: Variant in _definitions.keys():
        _dependency_map[str(quest_id)] = []
    if not _content_loader.has_method("get_quest_dependencies"):
        return true
    var document: Variant = _content_loader.call("get_quest_dependencies")
    if document == null or (document is Dictionary and document.is_empty()):
        return true
    if not document is Dictionary or not document.get("quests", []) is Array:
        return _definition_fail("Quest dependency document is invalid", "")
    var seen_owners := {}
    for raw_entry: Variant in document.get("quests", []):
        if not raw_entry is Dictionary:
            return _definition_fail("Quest dependency entry must be an object", "")
        var owner_id := str(raw_entry.get("quest_id", ""))
        if not _definitions.has(owner_id):
            continue
        if seen_owners.has(owner_id):
            return _definition_fail("Quest dependency owner is duplicated", owner_id)
        seen_owners[owner_id] = true
        var dependencies: Array = []
        for raw_dependency: Variant in raw_entry.get("depends_on", []):
            var dependency_id := str(raw_dependency)
            if dependency_id in dependencies:
                return _definition_fail("Quest dependency is duplicated", owner_id)
            dependencies.append(dependency_id)
        _dependency_map[owner_id] = dependencies
    return true


func _validate_cross_references() -> bool:
    for raw_quest_id: Variant in _definitions.keys():
        _mutual_exclusion_map[str(raw_quest_id)] = {}
    for raw_quest_id: Variant in _definitions.keys():
        var quest_id := str(raw_quest_id)
        var definition: Dictionary = _definitions[quest_id]
        for raw_exclusion: Variant in definition.get("mutual_exclusions", []):
            var excluded_id := str(raw_exclusion)
            if not _definitions.has(excluded_id):
                return _definition_fail("Mutually exclusive quest '%s' is not managed" % excluded_id, quest_id)
            if excluded_id == quest_id:
                return _definition_fail("Quest cannot be mutually exclusive with itself", quest_id)
            _mutual_exclusion_map[quest_id][excluded_id] = true
            _mutual_exclusion_map[excluded_id][quest_id] = true
        var availability: Dictionary = _runtime(quest_id)["availability"]
        for group_name: String in ["all", "any"]:
            for raw_condition: Variant in availability[group_name]:
                var condition: Dictionary = raw_condition
                if str(condition.get("kind", "")) == "quest" and not _definitions.has(str(condition.get("quest_id", ""))):
                    return _definition_fail("Quest prerequisite references an unknown managed quest", quest_id)
        for raw_dependency: Variant in _dependency_map.get(quest_id, []):
            if not _definitions.has(str(raw_dependency)):
                return _definition_fail("Quest dependency references an unknown managed quest", quest_id)
    return true


func _validate_dependency_cycles() -> bool:
    var graph := {}
    for raw_quest_id: Variant in _definitions.keys():
        var quest_id := str(raw_quest_id)
        var edges := {}
        for raw_dependency: Variant in _dependency_map.get(quest_id, []):
            edges[str(raw_dependency)] = true
        var availability: Dictionary = _runtime(quest_id)["availability"]
        for group_name: String in ["all", "any"]:
            for raw_condition: Variant in availability[group_name]:
                var condition: Dictionary = raw_condition
                if str(condition.get("kind", "")) == "quest":
                    edges[str(condition["quest_id"])] = true
        graph[quest_id] = edges.keys()

    var indegree := {}
    for raw_quest_id: Variant in graph.keys():
        indegree[str(raw_quest_id)] = 0
    for raw_quest_id: Variant in graph.keys():
        for raw_target: Variant in graph[raw_quest_id]:
            var target := str(raw_target)
            if target == str(raw_quest_id):
                return _initialize_fail_result(QUEST_DEPENDENCY_CYCLE, "Quest dependency graph contains a self-cycle", str(raw_quest_id))
            indegree[target] = int(indegree[target]) + 1
    var queue: Array[String] = []
    for raw_quest_id: Variant in indegree.keys():
        if int(indegree[raw_quest_id]) == 0:
            queue.append(str(raw_quest_id))
    var visited := 0
    while not queue.is_empty():
        var quest_id: String = queue.pop_front()
        visited += 1
        for raw_target: Variant in graph[quest_id]:
            var target := str(raw_target)
            indegree[target] = int(indegree[target]) - 1
            if int(indegree[target]) == 0:
                queue.append(target)
    if visited != graph.size():
        return _initialize_fail_result(QUEST_DEPENDENCY_CYCLE, "Quest dependency graph contains a cycle")
    return true


func _validate_availability_condition(condition: Dictionary, quest_id: String) -> bool:
    var kind := str(condition.get("kind", ""))
    var operation := str(condition.get("op", ""))
    if not condition.has("value"):
        return _definition_fail("Quest availability condition is missing a value", quest_id)
    if kind == "state":
        return _validate_state_condition({
            "key": condition.get("key", ""), "op": operation, "value": condition["value"],
        }, quest_id)
    if kind == "quest":
        if str(condition.get("quest_id", "")).is_empty() or operation not in QUEST_COMPARISON_OPERATORS:
            return _definition_fail("Quest-status availability condition is invalid", quest_id)
        return true
    return _definition_fail("Quest availability condition kind is invalid", quest_id)


func _validate_state_condition(condition: Dictionary, quest_id: String) -> bool:
    var key := str(condition.get("key", ""))
    if key.is_empty() or not bool(_game_state.call("has_state", key)):
        return _definition_fail("Quest condition references unknown state '%s'" % key, quest_id)
    _watched_state_keys[key] = true
    var matched: bool = _game_state.call("evaluate_condition", condition)
    var state_error: Variant = _game_state.get("last_error")
    if not matched and state_error is Dictionary and not state_error.is_empty():
        return _definition_fail("Quest condition is invalid: %s" % str(state_error.get("message", "")), quest_id)
    return true


func _validate_objective_value_contract(objective: Dictionary, quest_id: String) -> bool:
    var objective_type := str(objective["type"])
    if not objective.has("target"):
        return _definition_fail("Quest objective is missing its target", quest_id)
    var progress: Variant = _game_state.call("get_state", str(objective["progress_state_key"]))
    var target: Variant = objective["target"]
    match objective_type:
        "boolean":
            if not progress is bool or not target is bool or target != true:
                return _definition_fail("Boolean objective must use boolean progress and target=true", quest_id)
        "counter", "collection":
            if not progress is int or not _is_integer_value(target) or int(target) < 1 or int(progress) < 0 or int(progress) > int(target):
                return _definition_fail("Counter and collection objectives require bounded integer state", quest_id)
        "combat_result":
            var allowed: Variant = objective.get("allowed_results", [])
            if not progress is String or not target is String or str(target).is_empty() or not allowed is Array:
                return _definition_fail("Combat-result objective requires string state, target, and allowed_results", quest_id)
            if target not in allowed or (not str(progress).is_empty() and progress not in allowed):
                return _definition_fail("Combat-result objective uses an unregistered result", quest_id)
    return true


func _register_managed_key(key: String, quest_id: String, label: String) -> bool:
    if key.is_empty() or not bool(_game_state.call("has_state", key)):
        return _definition_fail("Quest %s references unknown state '%s'" % [label, key], quest_id)
    if _managed_state_keys.has(key):
        return _definition_fail("Quest state key '%s' is assigned more than once" % key, quest_id)
    _managed_state_keys[key] = {"quest_id": quest_id, "label": label}
    _watched_state_keys[key] = true
    return true


func _availability_met(quest_id: String) -> int:
    for raw_dependency: Variant in _dependency_map.get(quest_id, []):
        if _status(str(raw_dependency)) != "completed":
            return 0
    for raw_exclusion: Variant in _mutual_exclusion_map.get(quest_id, {}).keys():
        if _status(str(raw_exclusion)) in ["active", "qualified", "completed"]:
            return 0
    var availability: Dictionary = _runtime(quest_id)["availability"]
    for raw_condition: Variant in availability["all"]:
        var outcome := _availability_condition_matches(raw_condition)
        if outcome <= 0:
            return outcome
    var any_conditions: Array = availability["any"]
    if any_conditions.is_empty():
        return 1
    for raw_condition: Variant in any_conditions:
        var outcome := _availability_condition_matches(raw_condition)
        if outcome < 0:
            return -1
        if outcome == 1:
            return 1
    return 0


func _availability_condition_matches(condition: Dictionary) -> int:
    if str(condition["kind"]) == "state":
        var state_condition := {"key": condition["key"], "op": condition["op"], "value": condition["value"]}
        var matched: bool = _game_state.call("evaluate_condition", state_condition)
        var state_error: Variant = _game_state.get("last_error")
        if not matched and state_error is Dictionary and not state_error.is_empty():
            _set_error(QUEST_DEFINITION_INVALID, "GameState rejected a quest availability condition", "", {"details": state_error})
            return -1
        return 1 if matched else 0
    var current := _status(str(condition["quest_id"]))
    var expected: Variant = condition["value"]
    match str(condition["op"]):
        "eq":
            return 1 if current == expected else 0
        "ne", "neq":
            return 1 if current != expected else 0
        "in", "not_in":
            if not expected is Array:
                _set_error(QUEST_DEFINITION_INVALID, "Quest status in/not_in condition requires an array")
                return -1
            var contains: bool = current in expected
            return 1 if (contains if str(condition["op"]) == "in" else not contains) else 0
    _set_error(QUEST_DEFINITION_INVALID, "Quest status condition uses an invalid operator")
    return -1


func _refresh_progress_status(quest_id: String, source: String) -> Dictionary:
    var current := _status(quest_id)
    var target := _suggest_progress_status(quest_id)
    if target == current:
        return _result(true, "OK", "Quest progress status is unchanged", quest_id, {"status": current, "changed": false})
    if target == "completed":
        return _commit_completion(quest_id, source)
    if not _write_status(quest_id, target, source):
        return last_error.duplicate(true)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest progress status refreshed", quest_id, {"status": target, "changed": true})


func _suggest_progress_status(quest_id: String, override_objective_id: String = "", override_value: Variant = null) -> String:
    var current := _status(quest_id)
    var runtime: Dictionary = _runtime(quest_id)
    if str(runtime.get("completion_mode", "automatic")) == "automatic" and _all_required_objectives_complete(quest_id, override_objective_id, override_value):
        return "completed"
    if current == "active" and runtime.has("qualification") and _qualification_met(quest_id, override_objective_id, override_value):
        return "qualified"
    return current


func _all_required_objectives_complete(quest_id: String, override_objective_id: String = "", override_value: Variant = null) -> bool:
    var found_required := false
    for raw_objective_id: Variant in _objectives[quest_id].keys():
        var objective_id := str(raw_objective_id)
        var objective: Dictionary = _objectives[quest_id][objective_id]
        if not bool(objective.get("required", true)):
            continue
        found_required = true
        if not _objective_completed(quest_id, objective_id, override_objective_id, override_value):
            return false
    return found_required


func _qualification_met(quest_id: String, override_objective_id: String = "", override_value: Variant = null) -> bool:
    var qualification: Dictionary = _runtime(quest_id)["qualification"]
    var completed_count := 0
    for raw_objective_id: Variant in qualification["objective_ids"]:
        var objective_id := str(raw_objective_id)
        if _objective_completed(quest_id, objective_id, override_objective_id, override_value):
            completed_count += 1
    return completed_count >= int(qualification["required_count"])


func _objective_completed(quest_id: String, objective_id: String, override_objective_id: String = "", override_value: Variant = null) -> bool:
    var objective: Dictionary = _objectives[quest_id][objective_id]
    var progress: Variant
    if objective_id == override_objective_id:
        progress = override_value
    elif str(objective["type"]) == "state_condition":
        progress = _state_condition_matches(objective["condition"])
        if progress == null:
            return false
    else:
        progress = _game_state.call("get_state", str(objective["progress_state_key"]))
    return _objective_value_completed(objective, progress)


func _objective_value_completed(objective: Dictionary, progress: Variant) -> bool:
    match str(objective["type"]):
        "boolean", "combat_result":
            return progress == objective["target"]
        "counter", "collection":
            return int(progress) >= int(objective["target"])
        "state_condition":
            return progress == true
    return false


func _state_condition_matches(condition: Dictionary) -> Variant:
    var matched: bool = _game_state.call("evaluate_condition", condition)
    var state_error: Variant = _game_state.get("last_error")
    if not matched and state_error is Dictionary and not state_error.is_empty():
        _set_error(QUEST_DEFINITION_INVALID, "GameState rejected an objective condition", "", {"details": state_error})
        return null
    return matched


func _normalize_objective_update(objective: Dictionary, current: Variant, reported: Variant, quest_id: String) -> Dictionary:
    match str(objective["type"]):
        "boolean":
            if not reported is bool:
                return _objective_update_fail("Boolean objective update must be boolean", quest_id)
            return {"ok": true, "value": bool(current) or bool(reported)}
        "counter", "collection":
            if not reported is int or int(reported) < 0:
                return _objective_update_fail("Counter and collection updates must report a non-negative absolute integer", quest_id)
            var monotonic_value := maxi(int(current), int(reported))
            return {"ok": true, "value": mini(monotonic_value, int(objective["target"]))}
        "combat_result":
            if not reported is String or (not str(reported).is_empty() and reported not in objective.get("allowed_results", [])):
                return _objective_update_fail("Combat result is not registered by the objective", quest_id)
            if current == objective["target"]:
                return {"ok": true, "value": current}
            return {"ok": true, "value": reported}
    return _objective_update_fail("Objective type cannot be updated", quest_id)


func _commit_completion(quest_id: String, source: String) -> Dictionary:
    var current := _status(quest_id)
    if current == "completed":
        return _result(true, "OK", "Quest is already completed", quest_id, {
            "status": current, "changed": false, "reward_emitted": false,
        })
    var reward_key := str(_runtime(quest_id)["reward_granted_state_key"])
    var reward_was_granted := bool(_game_state.call("get_state", reward_key))
    var effects: Array = [{"op": "set", "key": _status_key(quest_id), "value": "completed"}]
    if not reward_was_granted:
        effects.append({"op": "set", "key": reward_key, "value": true})
    if not _apply_quest_effects(effects, quest_id):
        return last_error.duplicate(true)
    quest_status_changed.emit(quest_id, current, "completed", source)
    if not reward_was_granted:
        _emit_reward(quest_id, source)
    _refresh_dependents(source)
    return _result(true, "OK", "Quest completed", quest_id, {
        "status": "completed", "changed": true, "reward_emitted": not reward_was_granted,
    })


func _write_status(quest_id: String, target: String, source: String) -> bool:
    var current := _status(quest_id)
    if current == target:
        return true
    if not _apply_quest_effects([{"op": "set", "key": _status_key(quest_id), "value": target}], quest_id):
        return false
    quest_status_changed.emit(quest_id, current, target, source)
    return true


func _apply_quest_effects(effects: Array, quest_id: String) -> bool:
    _mutation_depth += 1
    var applied: bool = _game_state.call("apply_effects", effects, "quest")
    _mutation_depth -= 1
    if not applied:
        var state_error: Variant = _game_state.get("last_error")
        _set_error(QUEST_STATE_WRITE_FAILED, "GameState rejected an atomic quest update", quest_id, {"details": state_error})
        return false
    last_error = {}
    return true


func _emit_reward(quest_id: String, source: String) -> void:
    quest_reward_ready.emit({
        "ok": true,
        "code": "OK",
        "quest_id": quest_id,
        "source": source,
        "rewards": _definitions[quest_id].get("rewards", []).duplicate(true),
    })


func _refresh_dependents(source: String) -> void:
    var refresh_result := refresh_availability(source)
    if not bool(refresh_result.get("ok", false)):
        quest_error.emit(last_error.duplicate(true))


func _validate_continuation(quest_id: String, continuation_id: String) -> bool:
    var allowed: Array = _runtime(quest_id)["failure"].get("allowed_continuations", [])
    if continuation_id.is_empty() or continuation_id not in allowed:
        _set_error(QUEST_CONTINUATION_INVALID, "Quest continuation is missing or not registered", quest_id, {"continuation_id": continuation_id})
        return false
    return true


func _on_game_state_changed(key: String, _old_value: Variant, _new_value: Variant, source: String) -> void:
    if not _initialized or _mutation_depth > 0 or source == "save_restore" or not _watched_state_keys.has(key):
        return
    var refresh_result := refresh_availability(source)
    if not bool(refresh_result.get("ok", false)):
        return
    for raw_quest_id: Variant in _definitions.keys():
        var quest_id := str(raw_quest_id)
        if _status(quest_id) in ["active", "qualified"]:
            _refresh_progress_status(quest_id, source)


func _runtime(quest_id: String) -> Dictionary:
    return _definitions[quest_id]["runtime"]


func _status_key(quest_id: String) -> String:
    return str(_runtime(quest_id)["status_state_key"])


func _status(quest_id: String) -> String:
    return str(_game_state.call("get_state", _status_key(quest_id)))


func _require_initialized() -> bool:
    if _initialized:
        last_error = {}
        return true
    _set_error(QUEST_NOT_INITIALIZED, "QuestManager has not been initialized")
    return false


func _require_quest(quest_id: String) -> bool:
    if not _require_initialized():
        return false
    if not _definitions.has(quest_id):
        _set_error(QUEST_NOT_FOUND, "Unknown quest '%s'" % quest_id, quest_id)
        return false
    return true


func _definition_fail(message: String, quest_id: String) -> bool:
    _set_error(QUEST_DEFINITION_INVALID, message, quest_id)
    return false


func _initialize_fail(code: String, message: String, quest_id: String = "") -> bool:
    _set_error(code, message, quest_id)
    _initialized = false
    return false


func _initialize_fail_result(code: String, message: String, quest_id: String = "") -> bool:
    return _initialize_fail(code, message, quest_id)


func _objective_update_fail(message: String, quest_id: String) -> Dictionary:
    return _set_error(QUEST_OBJECTIVE_UPDATE_INVALID, message, quest_id)


func _set_error(code: String, message: String, quest_id: String = "", extra: Dictionary = {}) -> Dictionary:
    last_error = _result(false, code, message, quest_id, extra)
    printerr("QUEST_ERROR:%s:%s:%s" % [code, quest_id, message])
    quest_error.emit(last_error.duplicate(true))
    return last_error.duplicate(true)


func _result(ok: bool, code: String, message: String, quest_id: String = "", extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "code": code, "message": message}
    if not quest_id.is_empty():
        result["quest_id"] = quest_id
    for key: Variant in extra.keys():
        result[key] = extra[key]
    return result


func _is_integer_value(value: Variant) -> bool:
    return value is int or (value is float and value == floor(value))


func _disconnect_game_state() -> void:
    if _game_state != null and _game_state.has_signal("state_changed"):
        var callback := Callable(self, "_on_game_state_changed")
        if _game_state.is_connected("state_changed", callback):
            _game_state.disconnect("state_changed", callback)


func _clear_runtime() -> void:
    last_error = {}
    _content_loader = null
    _game_state = null
    _definitions = {}
    _objectives = {}
    _dependency_map = {}
    _mutual_exclusion_map = {}
    _managed_state_keys = {}
    _watched_state_keys = {}
    _initialized = false
    _mutation_depth = 0
