extends Control

const ContentLoaderClass = preload("res://src/core/content_loader.gd")
const GameStateClass = preload("res://src/core/game_state.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")

var _content_loader := ContentLoaderClass.new()
var _game_state := GameStateClass.new()
var _quest_manager := QuestManagerClass.new()
var _content_ready := false


func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var content_root := _argument_value(args, "--content-root=", "res://content")
    var expected_error := _argument_value(args, "--expect-content-error=", "")
    var expected_content_id := _argument_value(args, "--expect-content-id=", "")
    var expected_story_id := _argument_value(args, "--expect-story-id=", "")
    _content_loader.content_error.connect(_on_content_error)

    if not _content_loader.load_content(content_root):
        var actual_error := str(_content_loader.last_error.get("code", "UNKNOWN_CONTENT_ERROR"))
        if not expected_error.is_empty() and actual_error == expected_error:
            print("EXPECTED_CONTENT_ERROR_OK:%s" % actual_error)
            get_tree().quit(0)
            return
        printerr("CONTENT_LOAD_FAILED:%s:%s" % [actual_error, _content_loader.last_error.get("message", "")])
        if "--smoke-test" in args or not expected_error.is_empty():
            get_tree().quit(1)
        return

    if not expected_error.is_empty():
        printerr("EXPECTED_CONTENT_ERROR_NOT_RAISED:%s" % expected_error)
        get_tree().quit(1)
        return

    _game_state.state_error.connect(_on_state_error)
    if not _game_state.initialize_from_content_loader(_content_loader):
        _show_game_state_error(_game_state.last_error)
        if "--smoke-test" in args:
            get_tree().quit(1)
        return

    _quest_manager.quest_error.connect(_on_quest_error)
    if not _quest_manager.initialize(_content_loader, _game_state):
        _show_quest_error(_quest_manager.last_error)
        if "--smoke-test" in args:
            get_tree().quit(1)
        return

    _content_ready = true
    if not expected_content_id.is_empty():
        if not _content_loader.has_id(expected_content_id) or _content_loader.get_by_id(expected_content_id) == null:
            printerr("EXPECTED_CONTENT_ID_NOT_FOUND:%s" % expected_content_id)
            get_tree().quit(1)
            return
        print("CONTENT_ID_QUERY_OK:%s" % expected_content_id)
    if not expected_story_id.is_empty():
        if _content_loader.get_story(expected_story_id) == null:
            printerr("EXPECTED_STORY_NOT_FOUND:%s" % expected_story_id)
            get_tree().quit(1)
            return
        print("STORY_QUERY_OK:%s" % expected_story_id)
    $Center/VBox/Status.text = "内容索引加载完成\n技术骨架已就绪，正式剧情数据尚未导入"
    if "--smoke-test" in args:
        print("CONTENT_LOADER_OK:%d" % _content_loader.get_index_size())
        print("GAME_STATE_OK:%d" % _game_state.get_state_count())
        print("QUEST_MANAGER_OK:%d" % _quest_manager.list_quests().get("quests", []).size())
        print("SMOKE_TEST_OK")
        get_tree().quit(0)


func _on_content_error(error: Dictionary) -> void:
    _content_ready = false
    $Center/VBox/Title.text = "内容加载失败"
    $Center/VBox/Status.text = "%s\n%s\n%s" % [
        error.get("code", "UNKNOWN_CONTENT_ERROR"),
        error.get("message", "未知内容错误"),
        error.get("path", ""),
    ]


func _on_state_error(error: Dictionary) -> void:
    if not _content_ready:
        _show_game_state_error(error)


func _show_game_state_error(error: Dictionary) -> void:
    _content_ready = false
    $Center/VBox/Title.text = "状态初始化失败"
    $Center/VBox/Status.text = "%s\n%s\n%s" % [
        error.get("code", "UNKNOWN_STATE_ERROR"),
        error.get("message", "未知状态错误"),
        error.get("key", ""),
    ]


func _on_quest_error(error: Dictionary) -> void:
    if not _content_ready:
        _show_quest_error(error)


func _show_quest_error(error: Dictionary) -> void:
    _content_ready = false
    $Center/VBox/Title.text = "任务系统初始化失败"
    $Center/VBox/Status.text = "%s\n%s\n%s" % [
        error.get("code", "UNKNOWN_QUEST_ERROR"),
        error.get("message", "未知任务系统错误"),
        error.get("quest_id", ""),
    ]


func _argument_value(args: PackedStringArray, prefix: String, default_value: String) -> String:
    for argument: String in args:
        if argument.begins_with(prefix):
            return argument.trim_prefix(prefix)
    return default_value
