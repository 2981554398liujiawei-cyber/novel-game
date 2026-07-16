extends TextureRect

signal background_changed(payload: Dictionary)

const BACKGROUNDS := {
    "BG_NV7_ALTAR": "res://assets/backgrounds/nv7/nv7_exit_road.png",
    "BG_NV7_SQUARE": "res://assets/backgrounds/nv7/nv7_square.png",
    "BG_NV7_FORGE": "res://assets/backgrounds/nv7/nv7_smithy.png",
    "BG_NV7_APOTHECARY": "res://assets/backgrounds/nv7/nv7_apothecary.png",
    "BG_NV7_FIELDS": "res://assets/backgrounds/nv7/nv7_fields.png",
    "BG_NV7_WOLF_PATH": "res://assets/backgrounds/nv7/nv7_wolf_trail.png",
    "BG_NV7_CLIFF_CAVE": "res://assets/backgrounds/nv7/nv7_treasure_cave.png",
    "BG_NV7_TIANSHU": "res://assets/backgrounds/nv7/nv7_tianshu_spring.png",
}

var _content_loader: RefCounted
var _location_id := ""
var _background_id := ""
var _using_fallback := false


func bind_content_loader(content_loader: RefCounted) -> void:
    _content_loader = content_loader
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    modulate = Color(0.62, 0.62, 0.62, 1.0)


func show_location(location_id: String) -> Dictionary:
    _location_id = location_id
    _background_id = ""
    if _content_loader != null and _content_loader.has_method("get_by_id"):
        var raw_location: Variant = _content_loader.call("get_by_id", location_id)
        if raw_location is Dictionary:
            _background_id = str(raw_location.get("background_id", ""))
    return show_background(_background_id)


func show_background(background_id: String) -> Dictionary:
    _background_id = background_id
    var path := str(BACKGROUNDS.get(background_id, ""))
    _using_fallback = path.is_empty() or not ResourceLoader.exists(path)
    texture = null if _using_fallback else load(path) as Texture2D
    modulate = Color(0.12, 0.13, 0.16, 1.0) if _using_fallback else Color(0.62, 0.62, 0.62, 1.0)
    var result := get_presentation_state()
    result["ok"] = true
    result["code"] = "BACKGROUND_FALLBACK" if _using_fallback else "OK"
    background_changed.emit(result.duplicate(true))
    return result


func get_presentation_state() -> Dictionary:
    return {"location_id": _location_id, "background_id": _background_id, "using_fallback": _using_fallback}


func get_supported_background_count() -> int:
    return BACKGROUNDS.size()
