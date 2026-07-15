extends Control

const GameStateClass = preload("res://src/core/game_state.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"

class FixtureStateLoader extends RefCounted:
    var definitions: Array

    func _init(value: Array) -> void:
        definitions = value

    func get_state_definitions() -> Array:
        return definitions.duplicate(true)


class FixtureContentLoader extends RefCounted:
    var story: Dictionary

    func _init(value: Dictionary) -> void:
        story = value

    func get_story(story_id: String) -> Variant:
        return story.duplicate(true) if story_id == story.get("quest_id", "") else null


var _runner: RefCounted

@onready var _speaker: Label = $Margin/VBox/Speaker
@onready var _text: Label = $Margin/VBox/Text
@onready var _choices: VBoxContainer = $Margin/VBox/Choices
@onready var _continue_button: Button = $Margin/VBox/Continue


func _ready() -> void:
    var state_document := _read_json(STATE_FIXTURE)
    var story_document := _read_json(STORY_FIXTURE)
    if state_document.is_empty() or story_document.is_empty():
        _show_error({"code": "FIXTURE_READ_FAILED", "message": "无法读取测试数据"})
        return

    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(FixtureStateLoader.new(state_document["states"])):
        _show_error(game_state.last_error)
        return
    _runner = StoryRunnerClass.new()
    if not _runner.initialize(FixtureContentLoader.new(story_document), game_state):
        _show_error(_runner.last_error)
        return

    _runner.narrative_presented.connect(_show_narrative)
    _runner.dialogue_presented.connect(_show_dialogue)
    _runner.choice_presented.connect(_show_choices)
    _runner.story_completed.connect(_show_completed)
    _runner.story_error.connect(_show_error)
    _continue_button.pressed.connect(_on_continue_pressed)
    _runner.start_story("TEST_STORY_MINIMAL")


func _show_narrative(presentation: Dictionary) -> void:
    _speaker.text = "旁白"
    _text.text = str(presentation.get("text", ""))
    _clear_choices()
    _continue_button.visible = true


func _show_dialogue(presentation: Dictionary) -> void:
    _speaker.text = str(presentation.get("speaker_id", ""))
    _text.text = str(presentation.get("text", ""))
    _clear_choices()
    _continue_button.visible = true


func _show_choices(presentation: Dictionary) -> void:
    _speaker.text = "请选择"
    _text.text = "选择一个测试分支"
    _clear_choices()
    _continue_button.visible = false
    for choice: Variant in presentation.get("choices", []):
        var button := Button.new()
        button.text = str(choice.get("text", ""))
        button.disabled = not bool(choice.get("enabled", false))
        button.pressed.connect(_on_choice_pressed.bind(str(choice.get("choice_id", ""))))
        _choices.add_child(button)


func _show_completed(result: Dictionary) -> void:
    _speaker.text = "技术测试完成"
    _text.text = "结果：%s" % result.get("outcome", "")
    _clear_choices()
    _continue_button.visible = false


func _show_error(error: Dictionary) -> void:
    _speaker.text = "StoryRunner错误"
    _text.text = "%s\n%s" % [error.get("code", "UNKNOWN"), error.get("message", "")]
    _clear_choices()
    _continue_button.visible = false


func _on_continue_pressed() -> void:
    _runner.advance()


func _on_choice_pressed(choice_id: String) -> void:
    _runner.choose_choice(choice_id)


func _clear_choices() -> void:
    for child: Node in _choices.get_children():
        child.queue_free()


func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}
