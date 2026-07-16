extends RefCounted

signal story_started(story_id: String, entry_node: String)
signal story_node_entered(story_id: String, node_id: String, node_type: String)
signal narrative_presented(presentation: Dictionary)
signal dialogue_presented(presentation: Dictionary)
signal choice_presented(presentation: Dictionary)
signal story_completed(result: Dictionary)
signal story_position_restored(position: Dictionary, presentation: Dictionary)
signal story_error(error: Dictionary)

const SUPPORTED_NODE_TYPES := ["narrative", "dialogue", "choice", "complete"]
const MAX_AUTOMATIC_TRANSITIONS := 32

var last_error: Dictionary = {}

var _content_loader: RefCounted
var _game_state: RefCounted
var _quest_manager: RefCounted
var _story: Dictionary = {}
var _nodes: Dictionary = {}
var _story_id := ""
var _current_node_id := ""
var _waiting_for := ""
var _selectable_choices: Dictionary = {}
var _choice_presentation: Dictionary = {}
var _completion_result: Dictionary = {}
var _running := false


func initialize(content_loader: RefCounted, game_state: RefCounted, quest_manager: RefCounted = null) -> bool:
    last_error = {}
    _quest_manager = null
    if content_loader == null or not content_loader.has_method("get_story"):
        return _fail("STORY_CONTENT_LOADER_INVALID", "ContentLoader does not provide get_story")
    if game_state == null or not game_state.has_method("evaluate_condition") or not game_state.has_method("apply_effects"):
        return _fail("STORY_GAME_STATE_INVALID", "GameState does not provide condition and effect interfaces")
    if quest_manager != null:
        for method_name: String in [
            "get_quest_status", "activate_quest", "update_objective", "set_qualified",
            "complete_quest", "fail_quest", "suspend_quest", "resume_quest", "reopen_quest",
        ]:
            if not quest_manager.has_method(method_name):
                return _fail("STORY_QUEST_MANAGER_INVALID", "QuestManager does not provide '%s'" % method_name)
    _content_loader = content_loader
    _game_state = game_state
    _quest_manager = quest_manager
    return true


func start_story(story_id: String, start_node: String = "") -> bool:
    last_error = {}
    _clear_runtime()
    if _content_loader == null or _game_state == null:
        return _fail("STORY_RUNNER_NOT_INITIALIZED", "StoryRunner has not been initialized")

    var loaded_story: Variant = _content_loader.call("get_story", story_id)
    if not loaded_story is Dictionary:
        return _fail("STORY_NOT_FOUND", "ContentLoader could not find story '%s'" % story_id, story_id)
    _story = loaded_story.duplicate(true)
    _story_id = story_id
    if not _build_node_index():
        return false

    var entry_node := start_node if not start_node.is_empty() else str(_story.get("entry_node", ""))
    if not _nodes.has(entry_node):
        return _fail("STORY_NODE_NOT_FOUND", "Story entry node does not exist", entry_node)

    _running = true
    story_started.emit(_story_id, entry_node)
    return _enter_node(entry_node, 0)


func resume_from_node(story_id: String, node_id: String) -> bool:
    return start_story(story_id, node_id)


func is_valid_position(story_id: String, node_id: String) -> bool:
    if _content_loader == null or story_id.is_empty() or node_id.is_empty():
        return false
    var loaded_story: Variant = _content_loader.call("get_story", story_id)
    if not loaded_story is Dictionary:
        return false
    var raw_nodes: Variant = loaded_story.get("nodes", [])
    if not raw_nodes is Array:
        return false
    for raw_node: Variant in raw_nodes:
        if raw_node is Dictionary and str(raw_node.get("node_id", "")) == node_id:
            return str(raw_node.get("type", "")) in SUPPORTED_NODE_TYPES
    return false


func restore_position(story_id: String, node_id: String, emit_restored_signal: bool = true) -> bool:
    last_error = {}
    var previous := create_runtime_checkpoint()
    if not is_valid_position(story_id, node_id):
        _fail("STORY_NODE_NOT_FOUND", "Saved story position does not exist", node_id)
        var position_error := last_error.duplicate(true)
        restore_runtime_checkpoint(previous)
        last_error = position_error
        return false
    var loaded_story: Dictionary = _content_loader.call("get_story", story_id)
    _clear_runtime()
    _story = loaded_story.duplicate(true)
    _story_id = story_id
    if not _build_node_index():
        var build_error := last_error.duplicate(true)
        restore_runtime_checkpoint(previous)
        last_error = build_error
        return false
    _running = true
    if not _restore_exact_node(node_id):
        var restore_error := last_error.duplicate(true)
        restore_runtime_checkpoint(previous)
        last_error = restore_error
        return false
    if emit_restored_signal:
        emit_position_restored()
    return true


func create_runtime_checkpoint() -> Dictionary:
    return {
        "story": _story.duplicate(true),
        "nodes": _nodes.duplicate(true),
        "story_id": _story_id,
        "current_node_id": _current_node_id,
        "waiting_for": _waiting_for,
        "selectable_choices": _selectable_choices.duplicate(true),
        "choice_presentation": _choice_presentation.duplicate(true),
        "completion_result": _completion_result.duplicate(true),
        "running": _running,
    }


func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
    var required := [
        "story", "nodes", "story_id", "current_node_id", "waiting_for",
        "selectable_choices", "choice_presentation", "completion_result", "running",
    ]
    for key: String in required:
        if not checkpoint.has(key):
            return _checkpoint_fail("Runtime checkpoint is missing '%s'" % key)
    if (
        not checkpoint["story"] is Dictionary
        or not checkpoint["nodes"] is Dictionary
        or not checkpoint["story_id"] is String
        or not checkpoint["current_node_id"] is String
        or not checkpoint["waiting_for"] is String
        or not checkpoint["selectable_choices"] is Dictionary
        or not checkpoint["choice_presentation"] is Dictionary
        or not checkpoint["completion_result"] is Dictionary
        or not checkpoint["running"] is bool
    ):
        return _checkpoint_fail("Runtime checkpoint contains invalid field types")
    _story = checkpoint["story"].duplicate(true)
    _nodes = checkpoint["nodes"].duplicate(true)
    _story_id = checkpoint["story_id"]
    _current_node_id = checkpoint["current_node_id"]
    _waiting_for = checkpoint["waiting_for"]
    _selectable_choices = checkpoint["selectable_choices"].duplicate(true)
    _choice_presentation = checkpoint["choice_presentation"].duplicate(true)
    _completion_result = checkpoint["completion_result"].duplicate(true)
    _running = checkpoint["running"]
    last_error = {}
    return true


func emit_position_restored() -> void:
    var presentation: Dictionary = {}
    if _nodes.has(_current_node_id):
        var node: Dictionary = _nodes[_current_node_id]
        match str(node.get("type", "")):
            "narrative", "dialogue":
                presentation = _presentation_payload(node)
            "choice":
                presentation = _choice_presentation.duplicate(true)
            "complete":
                presentation = _completion_result.duplicate(true)
    story_position_restored.emit(get_current_position(), presentation)


func advance() -> bool:
    last_error = {}
    if not _require_running():
        return false
    if _waiting_for == "choice":
        return _fail("STORY_INPUT_REQUIRED", "A choice must be selected before advancing", _current_node_id)
    if _waiting_for not in ["narrative", "dialogue"]:
        return _fail("STORY_INPUT_INVALID", "The current story node cannot be advanced", _current_node_id)
    var node: Dictionary = _nodes[_current_node_id]
    var next_node := str(node.get("next", ""))
    if next_node.is_empty():
        return _fail("STORY_NEXT_MISSING", "Story node does not declare a next node", _current_node_id)
    return _enter_node(next_node, 0)


func choose_choice(choice_id: String) -> bool:
    last_error = {}
    if not _require_running():
        return false
    if _waiting_for != "choice":
        return _fail("STORY_INPUT_INVALID", "The current node is not waiting for a choice", _current_node_id)
    if not _selectable_choices.has(choice_id):
        return _fail("STORY_CHOICE_UNAVAILABLE", "Choice is missing, hidden, or disabled", _current_node_id, choice_id)

    var choice: Dictionary = _selectable_choices[choice_id]
    var target := _choice_target(choice)
    if target.is_empty():
        return _fail("STORY_TARGET_MISSING", "Choice does not declare a target", _current_node_id, choice_id)
    if not _nodes.has(target):
        return _fail("STORY_NODE_NOT_FOUND", "Choice jump target does not exist", target, choice_id)
    if not _apply_effects(choice.get("effects", [])):
        return false
    return _enter_node(target, 0)


func get_current_position() -> Dictionary:
    return {
        "story_id": _story_id,
        "node_id": _current_node_id,
        "waiting_for": _waiting_for,
        "running": _running,
        "completed": not _completion_result.is_empty(),
    }


func get_completion_result() -> Dictionary:
    return _completion_result.duplicate(true)


func is_running() -> bool:
    return _running


func get_quest_status(quest_id: String) -> Dictionary:
    return _call_quest_manager("get_quest_status", [quest_id])


func activate_quest(quest_id: String) -> Dictionary:
    return _call_quest_manager("activate_quest", [quest_id, "story"])


func update_quest_objective(quest_id: String, objective_id: String, update: Dictionary) -> Dictionary:
    return _call_quest_manager("update_objective", [quest_id, objective_id, update, "story"])


func set_quest_qualified(quest_id: String) -> Dictionary:
    return _call_quest_manager("set_qualified", [quest_id, "story"])


func complete_quest(quest_id: String) -> Dictionary:
    return _call_quest_manager("complete_quest", [quest_id, "story"])


func fail_quest(quest_id: String, continuation_id: String) -> Dictionary:
    return _call_quest_manager("fail_quest", [quest_id, continuation_id, "story"])


func suspend_quest(quest_id: String, continuation_id: String = "") -> Dictionary:
    return _call_quest_manager("suspend_quest", [quest_id, continuation_id, "story"])


func resume_quest(quest_id: String) -> Dictionary:
    return _call_quest_manager("resume_quest", [quest_id, "story"])


func reopen_quest(quest_id: String) -> Dictionary:
    return _call_quest_manager("reopen_quest", [quest_id, "story"])


func _build_node_index() -> bool:
    var raw_nodes: Variant = _story.get("nodes", [])
    if not raw_nodes is Array:
        return _fail("STORY_DATA_INVALID", "Story nodes must be an array", _story_id)
    for raw_node: Variant in raw_nodes:
        if not raw_node is Dictionary:
            return _fail("STORY_DATA_INVALID", "Every story node must be an object", _story_id)
        var node_id := str(raw_node.get("node_id", ""))
        if node_id.is_empty():
            return _fail("STORY_DATA_INVALID", "Story node ID cannot be empty", _story_id)
        if _nodes.has(node_id):
            return _fail("STORY_DUPLICATE_NODE", "Story contains a duplicate node ID", node_id)
        _nodes[node_id] = raw_node.duplicate(true)
    return true


func _enter_node(node_id: String, automatic_transitions: int, apply_entry_effects: bool = true) -> bool:
    if automatic_transitions > MAX_AUTOMATIC_TRANSITIONS:
        return _fail("STORY_AUTO_LOOP_DETECTED", "Automatic story transitions exceeded the safety limit", node_id)
    if not _nodes.has(node_id):
        return _fail("STORY_NODE_NOT_FOUND", "Story jump target does not exist", node_id)

    var node: Dictionary = _nodes[node_id]
    var node_type := str(node.get("type", ""))
    _current_node_id = node_id
    _waiting_for = ""
    _selectable_choices.clear()
    _choice_presentation = {}
    story_node_entered.emit(_story_id, node_id, node_type)

    if node_type not in SUPPORTED_NODE_TYPES:
        return _fail("STORY_NODE_TYPE_UNSUPPORTED", "Unsupported story node type '%s'" % node_type, node_id)

    var conditions_result := _conditions_met(node.get("conditions", []))
    if conditions_result < 0:
        return false
    if conditions_result == 0:
        var skip_target := str(node.get("next", ""))
        if skip_target.is_empty():
            return _fail("STORY_CONDITION_NO_FALLBACK", "A hidden node has no next target", node_id)
        return _enter_node(skip_target, automatic_transitions + 1, apply_entry_effects)

    if apply_entry_effects and not _apply_effects(node.get("effects", [])):
        return false

    match node_type:
        "narrative":
            _waiting_for = "narrative"
            narrative_presented.emit(_presentation_payload(node))
            return true
        "dialogue":
            _waiting_for = "dialogue"
            dialogue_presented.emit(_presentation_payload(node))
            return true
        "choice":
            return _present_choices(node)
        "complete":
            _running = false
            _completion_result = {
                "story_id": _story_id,
                "node_id": node_id,
                "outcome": str(node.get("outcome", "completed")),
            }
            story_completed.emit(_completion_result.duplicate(true))
            return true
    return false


func _restore_exact_node(node_id: String) -> bool:
    var node: Dictionary = _nodes[node_id]
    var node_type := str(node.get("type", ""))
    _current_node_id = node_id
    _waiting_for = ""
    _selectable_choices.clear()
    _choice_presentation = {}
    _completion_result = {}

    match node_type:
        "narrative":
            _waiting_for = "narrative"
            return true
        "dialogue":
            _waiting_for = "dialogue"
            return true
        "choice":
            return _present_choices(node, false)
        "complete":
            _running = false
            _completion_result = {
                "story_id": _story_id,
                "node_id": node_id,
                "outcome": str(node.get("outcome", "completed")),
            }
            return true
    return _fail("STORY_NODE_TYPE_UNSUPPORTED", "Unsupported saved story node type '%s'" % node_type, node_id)


func _present_choices(node: Dictionary, emit_signal: bool = true) -> bool:
    var visible_choices: Array = []
    var raw_choices: Variant = node.get("choices", [])
    if not raw_choices is Array:
        return _fail("STORY_DATA_INVALID", "Choice node choices must be an array", _current_node_id)

    for raw_choice: Variant in raw_choices:
        if not raw_choice is Dictionary:
            return _fail("STORY_DATA_INVALID", "Every choice must be an object", _current_node_id)
        var choice: Dictionary = raw_choice
        var choice_id := str(choice.get("choice_id", ""))
        if choice_id.is_empty():
            return _fail("STORY_DATA_INVALID", "Choice ID cannot be empty", _current_node_id)
        var conditions_result := _conditions_met(choice.get("conditions", []))
        if conditions_result < 0:
            return false
        var enabled := conditions_result == 1
        if not enabled and bool(choice.get("hidden_when_locked", false)):
            continue
        var presentation := {
            "choice_id": choice_id,
            "text": str(choice.get("text", "")) if enabled else str(choice.get("locked_text", choice.get("text", ""))),
            "enabled": enabled,
            "intent": str(choice.get("intent", "")),
            "consequence_summary": str(choice.get("consequence_summary", "")),
        }
        visible_choices.append(presentation)
        if enabled:
            if _selectable_choices.has(choice_id):
                return _fail("STORY_DUPLICATE_CHOICE", "Choice node contains a duplicate choice ID", _current_node_id, choice_id)
            _selectable_choices[choice_id] = choice.duplicate(true)

    if _selectable_choices.is_empty():
        return _fail("STORY_NO_AVAILABLE_CHOICES", "Choice node has no selectable choices", _current_node_id)
    _waiting_for = "choice"
    _choice_presentation = {
        "story_id": _story_id,
        "node_id": _current_node_id,
        "choices": visible_choices,
    }
    if emit_signal:
        choice_presented.emit(_choice_presentation.duplicate(true))
    return true


func _conditions_met(raw_conditions: Variant) -> int:
    if not raw_conditions is Array:
        _fail("STORY_DATA_INVALID", "Story conditions must be an array", _current_node_id)
        return -1
    for raw_condition: Variant in raw_conditions:
        if not raw_condition is Dictionary:
            _fail("STORY_DATA_INVALID", "Every story condition must be an object", _current_node_id)
            return -1
        var matches: bool = _game_state.call("evaluate_condition", raw_condition)
        var state_error_value: Variant = _game_state.get("last_error")
        if state_error_value is Dictionary and not state_error_value.is_empty():
            _fail("STORY_CONDITION_FAILED", "GameState rejected a story condition", _current_node_id, "", state_error_value)
            return -1
        if not matches:
            return 0
    return 1


func _apply_effects(raw_effects: Variant) -> bool:
    if not raw_effects is Array:
        return _fail("STORY_DATA_INVALID", "Story effects must be an array", _current_node_id)
    if raw_effects.is_empty():
        return true
    if not bool(_game_state.call("apply_effects", raw_effects, "story")):
        var state_error_value: Variant = _game_state.get("last_error")
        var state_details: Dictionary = {}
        if state_error_value is Dictionary:
            state_details = state_error_value
        return _fail("STORY_EFFECT_FAILED", "GameState rejected story effects", _current_node_id, "", state_details)
    return true


func _presentation_payload(node: Dictionary) -> Dictionary:
    return {
        "story_id": _story_id,
        "node_id": _current_node_id,
        "text": _display_text(node.get("text", "")),
        "speaker_id": str(node.get("speaker_id", "")),
        "expression": str(node.get("expression", "")),
        "gesture": str(node.get("gesture", "")),
        "target": str(node.get("target", "")),
        "portrait_action": str(node.get("portrait_action", "")),
    }


func _display_text(raw_text: Variant) -> String:
    if raw_text is Array:
        var lines: PackedStringArray = []
        for line: Variant in raw_text:
            lines.append(str(line))
        return "\n".join(lines)
    return str(raw_text)


func _choice_target(choice: Dictionary) -> String:
    return str(choice.get("target", choice.get("goto", "")))


func _require_running() -> bool:
    if not _running:
        return _fail("STORY_NOT_RUNNING", "No story is currently running", _current_node_id)
    return true


func _call_quest_manager(method_name: String, arguments: Array) -> Dictionary:
    if _quest_manager == null:
        return _quest_call_failed("STORY_QUEST_MANAGER_UNAVAILABLE", "StoryRunner has no QuestManager binding")
    var raw_result: Variant = _quest_manager.callv(method_name, arguments)
    if not raw_result is Dictionary:
        return _quest_call_failed("STORY_QUEST_RESULT_INVALID", "QuestManager returned an invalid result")
    var result: Dictionary = raw_result
    if not bool(result.get("ok", false)):
        last_error = {
            "code": str(result.get("code", "STORY_QUEST_ACTION_FAILED")),
            "message": str(result.get("message", "Quest action failed")),
            "story_id": _story_id,
            "node_id": _current_node_id,
            "choice_id": "",
            "details": result.duplicate(true),
        }
        story_error.emit(last_error.duplicate(true))
    else:
        last_error = {}
    return result.duplicate(true)


func _quest_call_failed(code: String, message: String) -> Dictionary:
    last_error = {
        "code": code,
        "message": message,
        "story_id": _story_id,
        "node_id": _current_node_id,
        "choice_id": "",
        "details": {},
    }
    story_error.emit(last_error.duplicate(true))
    return {"ok": false, "code": code, "message": message}


func _clear_runtime() -> void:
    _story = {}
    _nodes.clear()
    _story_id = ""
    _current_node_id = ""
    _waiting_for = ""
    _selectable_choices.clear()
    _choice_presentation = {}
    _completion_result = {}
    _running = false


func _checkpoint_fail(message: String) -> bool:
    last_error = {
        "code": "STORY_CHECKPOINT_INVALID",
        "message": message,
        "story_id": _story_id,
        "node_id": _current_node_id,
        "choice_id": "",
        "details": {},
    }
    printerr("STORY_ERROR:STORY_CHECKPOINT_INVALID:%s:%s" % [_current_node_id, message])
    return false


func _fail(
    code: String,
    message: String,
    node_id: String = "",
    choice_id: String = "",
    details: Dictionary = {},
) -> bool:
    _running = false
    _waiting_for = ""
    last_error = {
        "code": code,
        "message": message,
        "story_id": _story_id,
        "node_id": node_id,
        "choice_id": choice_id,
        "details": details.duplicate(true),
    }
    printerr("STORY_ERROR:%s:%s:%s" % [code, node_id, message])
    story_error.emit(last_error.duplicate(true))
    return false
