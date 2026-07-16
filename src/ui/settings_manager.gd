extends RefCounted

signal settings_changed(settings: Dictionary)

const DEFAULT_PATH := "user://settings.json"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1920, 1080)]
const DEFAULTS := {
    "master_volume": 1.0,
    "music_volume": 0.8,
    "sfx_volume": 0.8,
    "text_speed": 30.0,
    "typewriter_enabled": true,
    "font_size": 22,
    "fullscreen": false,
    "resolution": "1280x720",
    "autoplay": false,
}

var last_result: Dictionary = {}
var _settings: Dictionary = DEFAULTS.duplicate(true)
var _path := DEFAULT_PATH


func initialize(path: String = DEFAULT_PATH) -> Dictionary:
    _path = path
    _settings = DEFAULTS.duplicate(true)
    if not FileAccess.file_exists(_path):
        return _result(true, "OK", "Using default settings")
    var file := FileAccess.open(_path, FileAccess.READ)
    if file == null:
        return _result(false, "SETTINGS_READ_FAILED", "Could not open settings file")
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return _result(false, "SETTINGS_JSON_INVALID", "Settings file is not valid JSON")
    var validation := validate_settings(parsed)
    if not bool(validation.get("ok", false)):
        return validation
    _settings = parsed.duplicate(true)
    settings_changed.emit(get_settings())
    return _result(true, "OK", "Settings loaded")


func get_settings() -> Dictionary:
    return _settings.duplicate(true)


func get_value(key: String, fallback: Variant = null) -> Variant:
    return _settings.get(key, fallback)


func set_value(key: String, value: Variant, persist: bool = true) -> Dictionary:
    var candidate := _settings.duplicate(true)
    if not candidate.has(key):
        return _result(false, "SETTINGS_KEY_UNKNOWN", "Unknown setting '%s'" % key)
    candidate[key] = value
    var validation := validate_settings(candidate)
    if not bool(validation.get("ok", false)):
        return validation
    if candidate == _settings:
        return _result(true, "OK", "Setting unchanged")
    _settings = candidate
    if persist:
        var saved := save()
        if not bool(saved.get("ok", false)):
            return saved
    settings_changed.emit(get_settings())
    return _result(true, "OK", "Setting updated")


func replace_settings(candidate: Dictionary, persist: bool = true) -> Dictionary:
    var validation := validate_settings(candidate)
    if not bool(validation.get("ok", false)):
        return validation
    _settings = candidate.duplicate(true)
    if persist:
        var saved := save()
        if not bool(saved.get("ok", false)):
            return saved
    settings_changed.emit(get_settings())
    return _result(true, "OK", "Settings updated")


func reset_defaults(persist: bool = true) -> Dictionary:
    return replace_settings(DEFAULTS.duplicate(true), persist)


func validate_settings(candidate: Dictionary) -> Dictionary:
    for key: String in DEFAULTS:
        if not candidate.has(key):
            return _result(false, "SETTINGS_SCHEMA_INVALID", "Missing setting '%s'" % key)
    for key: String in ["master_volume", "music_volume", "sfx_volume"]:
        var value: Variant = candidate[key]
        if not value is float and not value is int:
            return _result(false, "SETTINGS_TYPE_INVALID", "Volume must be numeric")
        if float(value) < 0.0 or float(value) > 1.0:
            return _result(false, "SETTINGS_RANGE_INVALID", "Volume must be between 0 and 1")
    if not candidate["text_speed"] is float and not candidate["text_speed"] is int:
        return _result(false, "SETTINGS_TYPE_INVALID", "Text speed must be numeric")
    if float(candidate["text_speed"]) < 0.0:
        return _result(false, "SETTINGS_RANGE_INVALID", "Text speed cannot be negative")
    var font_value: Variant = candidate["font_size"]
    if (
        (not font_value is int and not font_value is float)
        or not is_equal_approx(float(font_value), floorf(float(font_value)))
        or int(font_value) < 18
        or int(font_value) > 32
    ):
        return _result(false, "SETTINGS_RANGE_INVALID", "Font size must be 18 to 32")
    for key: String in ["typewriter_enabled", "fullscreen", "autoplay"]:
        if not candidate[key] is bool:
            return _result(false, "SETTINGS_TYPE_INVALID", "Setting '%s' must be boolean" % key)
    if str(candidate["resolution"]) not in ["1280x720", "1920x1080"]:
        return _result(false, "SETTINGS_RESOLUTION_INVALID", "Unsupported resolution")
    return _result(true, "OK", "Settings are valid")


func save() -> Dictionary:
    var base_dir := _path.get_base_dir()
    if not DirAccess.dir_exists_absolute(base_dir):
        if DirAccess.make_dir_recursive_absolute(base_dir) != OK:
            return _result(false, "SETTINGS_WRITE_FAILED", "Could not create settings directory")
    var temporary := "%s.tmp" % _path
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return _result(false, "SETTINGS_WRITE_FAILED", "Could not write temporary settings file")
    file.store_string(JSON.stringify(_settings, "  "))
    file.flush()
    file.close()
    var verify := FileAccess.open(temporary, FileAccess.READ)
    if verify == null:
        DirAccess.remove_absolute(temporary)
        return _result(false, "SETTINGS_WRITE_FAILED", "Temporary settings verification failed")
    var verified_value: Variant = JSON.parse_string(verify.get_as_text())
    verify.close()
    if not verified_value is Dictionary:
        DirAccess.remove_absolute(temporary)
        return _result(false, "SETTINGS_WRITE_FAILED", "Temporary settings verification failed")
    if FileAccess.file_exists(_path):
        DirAccess.remove_absolute(_path)
    if DirAccess.rename_absolute(temporary, _path) != OK:
        return _result(false, "SETTINGS_WRITE_FAILED", "Could not replace settings file")
    return _result(true, "OK", "Settings saved")


func apply_window_settings() -> void:
    if DisplayServer.get_name() == "headless":
        return
    var size := Vector2i(1280, 720) if str(_settings["resolution"]) == "1280x720" else Vector2i(1920, 1080)
    DisplayServer.window_set_mode(
        DisplayServer.WINDOW_MODE_FULLSCREEN if bool(_settings["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED
    )
    if not bool(_settings["fullscreen"]):
        DisplayServer.window_set_size(size)


func _result(ok: bool, code: String, message: String) -> Dictionary:
    last_result = {"ok": ok, "code": code, "message": message}
    return last_result.duplicate(true)
