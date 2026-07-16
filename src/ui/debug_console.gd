extends Control

signal command_completed(result: Dictionary)

var _services: Dictionary = {}
var _enabled := false
var _output := RichTextLabel.new()


static func is_available(debug_build: bool, explicit_debug_tools: bool, release_build: bool) -> bool:
    if release_build:
        return false
    return debug_build or explicit_debug_tools


func configure(services: Dictionary, debug_build: bool = OS.is_debug_build(), explicit_debug_tools: bool = false, release_build: bool = false) -> Dictionary:
    _services = services.duplicate()
    _enabled = is_available(debug_build, explicit_debug_tools, release_build)
    visible = false
    if get_child_count() == 0:
        _build_console()
    return {"ok": true, "code": "OK", "enabled": _enabled}


func can_open() -> bool:
    return _enabled


func open_console() -> Dictionary:
    if not _enabled:
        visible = false
        return {"ok": false, "code": "DEBUG_CONSOLE_DISABLED", "message": "Debug console is unavailable in this build"}
    visible = true
    return {"ok": true, "code": "OK"}


func execute(command_line: String) -> Dictionary:
    if not _enabled:
        return _complete({"ok": false, "code": "DEBUG_CONSOLE_DISABLED", "message": "Debug console is unavailable"})
    var parts := command_line.strip_edges().split(" ", false)
    if parts.is_empty():
        return _complete({"ok": false, "code": "DEBUG_COMMAND_EMPTY", "message": "Command is empty"})
    var result: Dictionary
    match str(parts[0]):
        "state.list":
            result = {"ok": true, "code": "OK", "snapshot": _services["game_state"].call("export_snapshot")}
        "state.get":
            result = _require_args(parts, 2)
            if bool(result.get("ok", false)):
                var key := str(parts[1])
                result = {"ok": _services["game_state"].call("has_state", key), "code": "OK", "key": key, "value": _services["game_state"].call("get_state", key)}
        "state.set":
            result = _require_args(parts, 3)
            if bool(result.get("ok", false)):
                var parsed: Variant = JSON.parse_string(" ".join(parts.slice(2)))
                result = _services["game_state"].call("set_state", str(parts[1]), parsed, "debug")
        "story.position":
            result = {"ok": true, "code": "OK", "position": _services["story_runner"].call("get_current_position")}
        "story.jump":
            result = _require_args(parts, 3)
            if bool(result.get("ok", false)):
                result = {"ok": bool(_services["story_runner"].call("resume_from_node", str(parts[1]), str(parts[2]))), "code": "OK"}
        "quest.list":
            result = _services["quest_manager"].call("list_quests")
        "quest.activate":
            result = _require_args(parts, 2)
            if bool(result.get("ok", false)): result = _services["quest_manager"].call("activate_quest", str(parts[1]), "debug")
        "quest.update":
            result = _require_args(parts, 4)
            if bool(result.get("ok", false)):
                result = _services["quest_manager"].call("update_objective", str(parts[1]), str(parts[2]), {"value": JSON.parse_string(" ".join(parts.slice(3)))}, "debug")
        "inventory.list":
            result = _services["inventory_manager"].call("get_backpack_contents")
        "inventory.add":
            result = _require_args(parts, 2)
            if bool(result.get("ok", false)): result = _services["inventory_manager"].call("add_item", str(parts[1]), int(parts[2]) if parts.size() > 2 else 1, "debug")
        "relationship.list":
            result = _services["relationship_manager"].call("list_relationships")
        "relationship.effect":
            result = _require_args(parts, 4)
            if bool(result.get("ok", false)):
                result = _services["relationship_manager"].call("apply_effect", str(parts[1]), {"dimension": str(parts[2]), "op": "inc", "value": float(parts[3])}, "debug")
        "combat.start":
            result = _require_args(parts, 2)
            if bool(result.get("ok", false)): result = _services["combat_runner"].call("start_combat", str(parts[1]), int(parts[2]) if parts.size() > 2 else 1)
        "random.seed":
            result = {"ok": true, "code": "OK", "random_state": _services["save_manager"].call("get_random_state")}
        "diagnostics.export":
            result = _export_diagnostics()
        _:
            result = {"ok": false, "code": "DEBUG_COMMAND_UNKNOWN", "message": "Unknown debug command"}
    return _complete(result)


func _build_console() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var title := Label.new()
    title.text = "Debug Console (development only)"
    box.add_child(title)
    _output.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(_output)
    var input := LineEdit.new()
    input.placeholder_text = "state.list / quest.list / inventory.list / diagnostics.export"
    input.text_submitted.connect(func(value: String): execute(value); input.clear())
    box.add_child(input)
    var close := Button.new()
    close.text = "Close"
    close.pressed.connect(func(): visible = false)
    box.add_child(close)


func _require_args(parts: PackedStringArray, count: int) -> Dictionary:
    if parts.size() < count:
        return {"ok": false, "code": "DEBUG_ARGUMENT_MISSING", "message": "Command arguments are missing"}
    return {"ok": true, "code": "OK"}


func _export_diagnostics() -> Dictionary:
    var document := {
        "state": _services["game_state"].call("export_snapshot"),
        "story": _services["story_runner"].call("get_current_position"),
        "quests": _services["quest_manager"].call("list_quests"),
        "inventory": _services["inventory_manager"].call("export_snapshot"),
        "relationships": _services["relationship_manager"].call("list_relationships"),
        "combat": {"active": _services["combat_runner"].call("is_active"), "round": _services["combat_runner"].call("get_round")},
        "random_state": _services["save_manager"].call("get_random_state"),
    }
    var path := "user://debug/diagnostics.json"
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "code": "DEBUG_EXPORT_FAILED", "message": "Could not write diagnostics"}
    file.store_string(JSON.stringify(document, "  "))
    return {"ok": true, "code": "OK", "path": path, "diagnostics": document}


func _complete(result: Dictionary) -> Dictionary:
    _output.append_text("%s\n" % JSON.stringify(result))
    command_completed.emit(result.duplicate(true))
    return result
