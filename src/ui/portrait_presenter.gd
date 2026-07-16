extends TextureRect

signal portrait_changed(payload: Dictionary)

const FALLBACK_PATH := "res://assets/portraits/fallback/npc_missing.png"

var _content_loader: RefCounted
var _current_speaker_id := ""
var _current_expression := ""
var _using_fallback := false


func bind_content_loader(content_loader: RefCounted) -> void:
    _content_loader = content_loader
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func present(presentation: Dictionary) -> Dictionary:
    var action := str(presentation.get("portrait_action", "show"))
    if action == "keep":
        return _result(true, "OK", action)
    if action == "hide":
        visible = false
        return _result(true, "OK", action)
    if action != "show":
        return _result(false, "PORTRAIT_ACTION_INVALID", action)

    _current_speaker_id = str(presentation.get("speaker_id", ""))
    _current_expression = str(presentation.get("expression", ""))
    var asset_path := _resolve_portrait_path(_current_speaker_id, _current_expression)
    _using_fallback = asset_path == FALLBACK_PATH
    texture = load(asset_path) as Texture2D
    if texture == null and asset_path != FALLBACK_PATH:
        _using_fallback = true
        texture = load(FALLBACK_PATH) as Texture2D
    visible = true
    var result := _result(true, "PORTRAIT_FALLBACK" if _using_fallback else "OK", action)
    portrait_changed.emit(result.duplicate(true))
    return result


func get_presentation_state() -> Dictionary:
    return {
        "speaker_id": _current_speaker_id,
        "expression": _current_expression,
        "visible": visible,
        "using_fallback": _using_fallback,
    }


func _resolve_portrait_path(speaker_id: String, expression: String) -> String:
    if _content_loader == null or speaker_id.is_empty() or not _content_loader.has_method("get_by_id"):
        return FALLBACK_PATH
    var raw_npc: Variant = _content_loader.call("get_by_id", speaker_id)
    if not raw_npc is Dictionary:
        return FALLBACK_PATH
    var portrait_set: Variant = raw_npc.get("portrait_set", {})
    if not portrait_set is Dictionary:
        return FALLBACK_PATH
    var base_path := str(portrait_set.get("base_path", ""))
    var selected := expression
    if selected.is_empty():
        selected = str(portrait_set.get("default_expression", "neutral"))
    var expressions: Variant = portrait_set.get("expressions", {})
    var relative_path := ""
    if expressions is Dictionary:
        relative_path = str(expressions.get(selected, expressions.get(str(portrait_set.get("default_expression", "neutral")), "")))
    var candidate := relative_path
    if not base_path.is_empty() and not relative_path.begins_with("res://"):
        candidate = base_path.path_join(relative_path)
    if candidate.is_empty() or not ResourceLoader.exists(candidate):
        return FALLBACK_PATH
    _current_expression = selected
    return candidate


func _result(ok: bool, code: String, action: String) -> Dictionary:
    return {
        "ok": ok,
        "code": code,
        "action": action,
        "speaker_id": _current_speaker_id,
        "expression": _current_expression,
        "using_fallback": _using_fallback,
    }
