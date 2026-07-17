extends RefCounted

const ACTION_PREFIX := "player_"
const ACTIONS := {
    "story_advance": {"name": "推进剧情", "category": "剧情操作"},
    "story_back": {"name": "查看上一条", "category": "剧情操作"},
    "story_next": {"name": "下一条或推进", "category": "剧情操作"},
    "choice_previous": {"name": "上一个选项", "category": "剧情操作"},
    "choice_next": {"name": "下一个选项", "category": "剧情操作"},
    "choice_confirm": {"name": "确认选择", "category": "剧情操作"},
    "open_quest": {"name": "打开任务", "category": "功能页面"},
    "open_inventory": {"name": "打开背包", "category": "功能页面"},
    "open_relationship": {"name": "打开关系", "category": "功能页面"},
    "open_history": {"name": "打开历史", "category": "功能页面"},
    "open_settings": {"name": "打开设置", "category": "功能页面"},
    "quick_save": {"name": "快速保存", "category": "存档"},
    "quick_load": {"name": "快速读取", "category": "存档"},
    "menu_back": {"name": "返回或关闭", "category": "通用"},
}
const DEFAULT_BINDINGS := {
    "story_advance": [{"type":"key", "code":KEY_SPACE}, {"type":"key", "code":KEY_ENTER}],
    "story_back": [{"type":"key", "code":KEY_PAGEUP}, {"type":"key", "code":KEY_UP}],
    "story_next": [{"type":"key", "code":KEY_PAGEDOWN}, {"type":"key", "code":KEY_DOWN}],
    "choice_previous": [{"type":"key", "code":KEY_UP}],
    "choice_next": [{"type":"key", "code":KEY_DOWN}],
    "choice_confirm": [{"type":"key", "code":KEY_ENTER}],
    "open_quest": [{"type":"key", "code":KEY_J}],
    "open_inventory": [{"type":"key", "code":KEY_I}],
    "open_relationship": [{"type":"key", "code":KEY_R}],
    "open_history": [{"type":"key", "code":KEY_L}],
    "open_settings": [{"type":"key", "code":KEY_O}],
    "quick_save": [{"type":"key", "code":KEY_F5}],
    "quick_load": [{"type":"key", "code":KEY_F9}],
    "menu_back": [{"type":"key", "code":KEY_ESCAPE}],
}
const CONTEXT_OVERLAPS := [
    ["story_advance", "choice_confirm"], ["story_back", "choice_previous"], ["story_next", "choice_next"],
]

var _settings_manager: RefCounted
var _bindings: Dictionary = DEFAULT_BINDINGS.duplicate(true)


func initialize(settings_manager: RefCounted) -> void:
    _settings_manager = settings_manager
    var saved: Variant = settings_manager.call("get_value", "key_bindings", {})
    if saved is Dictionary and not saved.is_empty():
        for action_id: String in ACTIONS:
            if saved.has(action_id) and saved[action_id] is Array:
                _bindings[action_id] = saved[action_id].duplicate(true)
    _apply_input_map()


func matches(event: InputEvent, action_id: String) -> bool:
    if not ACTIONS.has(action_id) or not event.is_pressed() or event.is_echo():
        return false
    for spec: Variant in _bindings.get(action_id, []):
        if spec is Dictionary and _event_matches_spec(event, spec):
            return true
    return false


func action_name(action_id: String) -> String:
    return str(ACTIONS.get(action_id, {}).get("name", "未知操作"))


func action_category(action_id: String) -> String:
    return str(ACTIONS.get(action_id, {}).get("category", "通用"))


func action_ids() -> Array[String]:
    var result: Array[String] = []
    for action_id: String in ACTIONS: result.append(action_id)
    return result


func binding_text(action_id: String) -> String:
    var names: Array[String] = []
    for spec: Variant in _bindings.get(action_id, []):
        if spec is Dictionary: names.append(_spec_text(spec))
    return " / ".join(names) if not names.is_empty() else "未设置"


func event_spec(event: InputEvent) -> Dictionary:
    if event is InputEventKey:
        return {"type": "key", "code": event.keycode if event.keycode != 0 else event.physical_keycode}
    if event is InputEventMouseButton:
        return {"type": "mouse", "code": event.button_index}
    return {}


func conflicts(action_id: String, spec: Dictionary) -> Array[String]:
    var result: Array[String] = []
    for other_id: String in ACTIONS:
        if other_id == action_id or _overlap_allowed(action_id, other_id): continue
        for other_spec: Variant in _bindings.get(other_id, []):
            if other_spec is Dictionary and other_spec == spec:
                result.append(other_id)
                break
    return result


func bind_event(action_id: String, spec: Dictionary, replace_conflicts: bool = false) -> Dictionary:
    if not ACTIONS.has(action_id) or spec.is_empty(): return _result(false, "INPUT_BINDING_INVALID", "无法识别这个按键。")
    var found := conflicts(action_id, spec)
    if not found.is_empty() and not replace_conflicts:
        return {"ok": false, "code": "INPUT_BINDING_CONFLICT", "conflicts": found, "message": "按键冲突"}
    if replace_conflicts:
        for other_id: String in found: _bindings[other_id] = _without_spec(_bindings[other_id], spec)
    var values: Array = _bindings.get(action_id, []).duplicate(true)
    if spec not in values: values.append(spec.duplicate(true))
    _bindings[action_id] = values
    return _persist()


func clear_action(action_id: String) -> Dictionary:
    if action_id in ["open_settings", "menu_back"]:
        return _result(false, "INPUT_CORE_ACTION_REQUIRED", "这个核心操作必须保留至少一个按键。")
    if not ACTIONS.has(action_id): return _result(false, "INPUT_ACTION_UNKNOWN", "未知操作。")
    _bindings[action_id] = []
    return _persist()


func reset_defaults() -> Dictionary:
    _bindings = DEFAULT_BINDINGS.duplicate(true)
    return _persist()


func _persist() -> Dictionary:
    _apply_input_map()
    if _settings_manager == null: return _result(true, "OK", "按键设置已更新。")
    return _settings_manager.call("set_value", "key_bindings", _bindings.duplicate(true), true)


func _apply_input_map() -> void:
    for action_id: String in ACTIONS:
        var input_name := StringName(ACTION_PREFIX + action_id)
        if not InputMap.has_action(input_name): InputMap.add_action(input_name)
        InputMap.action_erase_events(input_name)
        for spec: Variant in _bindings.get(action_id, []):
            if not spec is Dictionary: continue
            var event: InputEvent
            if str(spec.get("type", "")) == "key":
                var key_event := InputEventKey.new(); key_event.keycode = int(spec.get("code", 0)); event = key_event
            else:
                var mouse_event := InputEventMouseButton.new(); mouse_event.button_index = int(spec.get("code", 0)); event = mouse_event
            InputMap.action_add_event(input_name, event)


func _event_matches_spec(event: InputEvent, spec: Dictionary) -> bool:
    if event is InputEventKey and str(spec.get("type", "")) == "key":
        return int(spec.get("code", 0)) in [event.keycode, event.physical_keycode]
    return event is InputEventMouseButton and str(spec.get("type", "")) == "mouse" and int(spec.get("code", 0)) == event.button_index


func _spec_text(spec: Dictionary) -> String:
    if str(spec.get("type", "")) == "mouse":
        return {MOUSE_BUTTON_LEFT:"鼠标左键", MOUSE_BUTTON_RIGHT:"鼠标右键", MOUSE_BUTTON_MIDDLE:"鼠标中键", MOUSE_BUTTON_XBUTTON1:"鼠标侧键一", MOUSE_BUTTON_XBUTTON2:"鼠标侧键二"}.get(int(spec.get("code", 0)), "鼠标按键")
    return OS.get_keycode_string(int(spec.get("code", 0))).replace("Space", "空格").replace("Enter", "回车").replace("Escape", "Esc").replace("PageUp", "PageUp").replace("PageDown", "PageDown")


func _overlap_allowed(first: String, second: String) -> bool:
    return [first, second] in CONTEXT_OVERLAPS or [second, first] in CONTEXT_OVERLAPS


func _without_spec(values: Array, spec: Dictionary) -> Array:
    var result: Array = []
    for value: Variant in values:
        if value != spec: result.append(value)
    return result


func _result(ok: bool, code: String, message: String) -> Dictionary:
    return {"ok": ok, "code": code, "message": message}
