extends SceneTree

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
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


class FixtureQuestManager extends RefCounted:
    var calls: Array[Dictionary] = []
    var reject_activate := false

    func get_quest_status(quest_id: String) -> Dictionary: return {"ok": true, "quest_id": quest_id}
    func activate_quest(quest_id: String, source: String) -> Dictionary:
        calls.append({"action": "activate", "quest_id": quest_id, "source": source})
        return {"ok": not reject_activate, "code": "QUEST_REJECTED" if reject_activate else "OK", "message": "fixture"}
    func update_objective(_quest_id: String, _objective_id: String, _update: Dictionary, _source: String) -> Dictionary: return {"ok": true}
    func set_qualified(_quest_id: String, _source: String) -> Dictionary: return {"ok": true}
    func complete_quest(quest_id: String, source: String) -> Dictionary:
        calls.append({"action": "complete", "quest_id": quest_id, "source": source})
        return {"ok": true}
    func fail_quest(_quest_id: String, _continuation_id: String, _source: String) -> Dictionary: return {"ok": true}
    func suspend_quest(_quest_id: String, _continuation_id: String, _source: String) -> Dictionary: return {"ok": true}
    func resume_quest(_quest_id: String, _source: String) -> Dictionary: return {"ok": true}
    func reopen_quest(_quest_id: String, _source: String) -> Dictionary: return {"ok": true}


class FixtureRelationshipManager extends RefCounted:
    var calls: Array[Dictionary] = []
    var reject_effect := false
    func evaluate_condition(_relationship_id: String, _condition: Dictionary) -> Dictionary: return {"ok": true, "matched": true}
    func apply_effects(relationship_id: String, effects: Array, source: String) -> Dictionary:
        calls.append({"relationship_id": relationship_id, "effects": effects.duplicate(true), "source": source})
        return {"ok": not reject_effect, "code": "RELATIONSHIP_REJECTED" if reject_effect else "OK", "message": "fixture"}


var _failures: Array[String] = []
var _narratives: Array[Dictionary] = []
var _dialogues: Array[Dictionary] = []
var _choice_presentations: Array[Dictionary] = []
var _completions: Array[Dictionary] = []
var _errors: Array[Dictionary] = []
var _entered_nodes: Array[String] = []
var _state_events: Array[Dictionary] = []
var _starts: Array[Dictionary] = []
var _rewards: Array[Dictionary] = []
var _story_fixture: Dictionary
var _state_definitions: Array


func _init() -> void:
    _story_fixture = _read_json(STORY_FIXTURE)
    var state_document: Dictionary = _read_json(STATE_FIXTURE)
    if _story_fixture.is_empty() or state_document.is_empty():
        quit(1)
        return
    _state_definitions = state_document["states"]

    _test_branch_a()
    _test_branch_b()
    _test_resume_from_legal_node()
    _test_missing_node_error()
    _test_no_available_choice_error()
    _test_unknown_node_type_error()
    _test_automatic_loop_guard()
    _test_runtime_manager_actions_and_reward_quantity()
    _test_manager_failure_stops_entry()
    _test_relationship_failure_emits_story_error()

    if _failures.is_empty():
        print("STORY_RUNNER_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("STORY_RUNNER_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_branch_a() -> void:
    var context := _new_context(_story_fixture)
    var runner: RefCounted = context["runner"]
    var game_state: RefCounted = context["game_state"]
    _expect(runner.start_story("TEST_STORY_MINIMAL"), "分支A无法从entry_node启动")
    _expect(_starts == [{"story_id": "TEST_STORY_MINIMAL", "entry_node": "opening"}], "story_started信号错误")
    _expect(not _entered_nodes.is_empty() and _entered_nodes[0] == "opening", "story_node_entered信号错误")
    _expect(_last_text(_narratives) == "【技术测试】一段开场叙事。", "narrative没有正确输出")
    _expect(game_state.get_state("test.note") == "story_started", "narrative进入效果未通过GameState生效")
    _expect(runner.get_current_position()["node_id"] == "opening", "当前位置查询错误")

    _expect(runner.advance(), "无法从narrative推进到dialogue")
    _expect(_last_text(_dialogues) == "这是测试对白，请选择一条技术分支。", "dialogue文本错误")
    if not _dialogues.is_empty():
        _expect(_dialogues[-1]["speaker_id"] == "NV7_NPC_LANYIN", "dialogue speaker_id错误")
        _expect(_dialogues[-1]["expression"] == "neutral", "dialogue expression错误")
        _expect(_dialogues[-1]["gesture"] == "none", "dialogue gesture错误")
        _expect(_dialogues[-1]["target"] == "player", "dialogue target错误")
        _expect(_dialogues[-1]["portrait_action"] == "show", "dialogue portrait_action错误")

    _expect(runner.advance(), "无法推进到choice")
    var choice_ids := _presented_choice_ids()
    _expect(choice_ids == ["choose_a", "choose_b"], "choice条件过滤结果错误")
    _expect(runner.choose_choice("choose_a"), "无法选择分支A")
    _expect(game_state.get_state("test.mode") == "active", "分支A效果未通过GameState生效")
    _expect(_last_text(_narratives) == "分支A立即给出了不同回应。", "分支A即时回应错误")
    _expect(_has_state_event("test.mode", "story"), "分支A没有产生source=story的状态信号")

    _expect(runner.advance(), "分支A无法进入汇流节点")
    _expect(_last_text(_narratives) == "两条技术分支在这里汇流。", "分支A汇流错误")
    _expect(runner.advance(), "分支A条件对白无法显示")
    _expect(_last_text(_dialogues) == "检测到分支A状态。", "分支A条件对白错误")
    _expect(runner.advance(), "分支A无法完成")
    _expect(not runner.is_running(), "complete后StoryRunner仍在运行")
    _expect(runner.get_completion_result()["outcome"] == "fixture_complete", "complete结果错误")
    _expect(_completions.size() == 1, "story_completed信号数量错误")


func _test_branch_b() -> void:
    var context := _new_context(_story_fixture)
    var runner: RefCounted = context["runner"]
    var game_state: RefCounted = context["game_state"]
    _expect(runner.start_story("TEST_STORY_MINIMAL"), "分支B无法启动")
    _expect(runner.advance() and runner.advance(), "分支B无法推进到choice")
    _expect(runner.choose_choice("choose_b"), "无法选择分支B")
    _expect(game_state.get_state("test.flag") == true, "分支B效果未通过GameState生效")
    _expect(_last_text(_dialogues) == "分支B立即给出了另一条回应。", "分支B即时回应错误")
    _expect(runner.advance(), "分支B无法进入汇流节点")
    _expect(_last_text(_narratives) == "两条技术分支在这里汇流。", "分支B汇流错误")
    _expect(runner.advance(), "分支B条件对白无法显示")
    _expect(_last_text(_dialogues) == "检测到分支B状态。", "分支B条件对白错误")
    _expect(runner.advance(), "分支B无法完成")
    _expect(runner.get_completion_result()["outcome"] == "fixture_complete", "分支B完成结果错误")


func _test_resume_from_legal_node() -> void:
    var context := _new_context(_story_fixture)
    var runner: RefCounted = context["runner"]
    _expect(runner.resume_from_node("TEST_STORY_MINIMAL", "merge"), "无法从合法节点重新进入")
    _expect(runner.get_current_position()["node_id"] == "merge", "重新进入后位置错误")


func _test_missing_node_error() -> void:
    var story: Dictionary = _story_fixture.duplicate(true)
    story["nodes"][0]["next"] = "missing_node"
    var runner: RefCounted = _new_context(story)["runner"]
    _expect(runner.start_story("TEST_STORY_MINIMAL"), "非法跳转测试无法启动")
    _expect(not runner.advance(), "不存在节点没有报错")
    _expect(_error_code(runner) == "STORY_NODE_NOT_FOUND", "不存在节点错误码错误")
    _expect(_errors.size() == 1, "story_error信号数量错误")


func _test_no_available_choice_error() -> void:
    var story: Dictionary = _story_fixture.duplicate(true)
    var decision: Dictionary = _find_node(story, "decision")
    for choice: Variant in decision["choices"]:
        choice["conditions"] = [{"key": "test.counter", "op": "gte", "value": 99}]
        choice["hidden_when_locked"] = true
    var runner: RefCounted = _new_context(story)["runner"]
    _expect(runner.start_story("TEST_STORY_MINIMAL"), "无可用选项测试无法启动")
    _expect(runner.advance(), "无可用选项测试无法到达对白")
    _expect(not runner.advance(), "无可用选项没有报错")
    _expect(_error_code(runner) == "STORY_NO_AVAILABLE_CHOICES", "无可用选项错误码错误")


func _test_unknown_node_type_error() -> void:
    var story: Dictionary = _story_fixture.duplicate(true)
    story["nodes"][0]["type"] = "mystery"
    var runner: RefCounted = _new_context(story)["runner"]
    _expect(not runner.start_story("TEST_STORY_MINIMAL"), "未知节点类型没有报错")
    _expect(_error_code(runner) == "STORY_NODE_TYPE_UNSUPPORTED", "未知节点类型错误码错误")


func _test_automatic_loop_guard() -> void:
    var story: Dictionary = _story_fixture.duplicate(true)
    var opening: Dictionary = _find_node(story, "opening")
    var greeting: Dictionary = _find_node(story, "greeting")
    opening["conditions"] = [{"key": "test.counter", "op": "gte", "value": 99}]
    opening["next"] = "greeting"
    greeting["conditions"] = [{"key": "test.counter", "op": "gte", "value": 99}]
    greeting["next"] = "opening"
    var runner: RefCounted = _new_context(story)["runner"]
    _expect(not runner.start_story("TEST_STORY_MINIMAL"), "自动跳转循环没有被拦截")
    _expect(_error_code(runner) == "STORY_AUTO_LOOP_DETECTED", "自动跳转循环错误码错误")


func _test_runtime_manager_actions_and_reward_quantity() -> void:
    var story := _manager_action_story()
    var quest_manager := FixtureQuestManager.new()
    var relationship_manager := FixtureRelationshipManager.new()
    var context := _new_context(story, quest_manager, relationship_manager)
    var runner: RefCounted = context["runner"]
    _expect(runner.start_story("TEST_MANAGER_ACTIONS"), "Manager动作剧情无法启动")
    _expect(quest_manager.calls.size() == 1 and quest_manager.calls[0]["action"] == "activate", "QuestManager公开wrapper未被调用")
    _expect(relationship_manager.calls.size() == 1, "RelationshipManager公开wrapper未被调用")
    if not relationship_manager.calls.is_empty():
        var effect: Dictionary = relationship_manager.calls[0]["effects"][0]
        _expect(effect.get("dimension_id") == "trust" and not effect.has("relationship_id"), "关系动作运行时payload错误")
    _expect(runner.advance(), "无法进入Manager动作选择节点")
    _expect(runner.choose_choice("continue"), "选择项Manager动作无法执行")
    _expect(quest_manager.calls.size() == 2 and quest_manager.calls[1]["action"] == "complete", "选择项QuestManager动作未执行")
    _expect(relationship_manager.calls.size() == 2, "选择项RelationshipManager动作未执行")
    _expect(_rewards.size() == 1 and _rewards[0]["reward_items"][0]["quantity"] == 3, "奖励数量未保留到可执行payload")


func _test_manager_failure_stops_entry() -> void:
    var quest_manager := FixtureQuestManager.new()
    quest_manager.reject_activate = true
    var context := _new_context(_manager_action_story(), quest_manager, FixtureRelationshipManager.new())
    var runner: RefCounted = context["runner"]
    _expect(not runner.start_story("TEST_MANAGER_ACTIONS"), "Manager动作失败后剧情仍继续")
    _expect(_error_code(runner) == "QUEST_REJECTED", "Manager动作失败错误未透传")


func _test_relationship_failure_emits_story_error() -> void:
    var relationship_manager := FixtureRelationshipManager.new()
    relationship_manager.reject_effect = true
    var context := _new_context(_manager_action_story(), FixtureQuestManager.new(), relationship_manager)
    var runner: RefCounted = context["runner"]
    _expect(not runner.start_story("TEST_MANAGER_ACTIONS"), "RelationshipManager失败后剧情仍继续")
    _expect(_error_code(runner) == "STORY_RELATIONSHIP_ACTION_FAILED", "关系动作失败错误码不明确")
    _expect(_errors.size() == 1, "关系动作失败未发出story_error")


func _manager_action_story() -> Dictionary:
    return {
        "quest_id": "TEST_MANAGER_ACTIONS", "entry_node": "opening",
        "nodes": [
            {"node_id": "opening", "type": "narrative", "text": ["fixture"], "effects": [],
             "quest_actions": [{"action": "activate", "quest_id": "TEST_QUEST"}],
             "relationship_actions": [{"relationship_id": "TEST_REL", "dimension": "trust", "op": "inc", "value": 1}], "next": "decision"},
            {"node_id": "decision", "type": "choice", "choices": [
                {"choice_id": "continue", "text": "fixture", "goto": "reward",
                 "quest_actions": [{"action": "complete", "quest_id": "TEST_QUEST"}],
                 "relationship_actions": [{"relationship_id": "TEST_REL", "dimension": "respect", "op": "inc", "value": 1}]}
            ]},
            {"node_id": "reward", "type": "reward", "reward_items": [{"item_id": "TEST_ITEM", "quantity": 3}], "next": "done"},
            {"node_id": "done", "type": "complete", "terminal": true, "outcome": "done"},
        ],
    }


func _new_context(story: Dictionary, quest_manager: RefCounted = null, relationship_manager: RefCounted = null) -> Dictionary:
    _clear_captured_events()
    var game_state := GameStateClass.new()
    _expect(game_state.initialize_from_content_loader(FixtureStateLoader.new(_state_definitions)), "测试GameState初始化失败")
    game_state.state_changed.connect(_on_state_changed)
    var runner := StoryRunnerClass.new()
    _expect(runner.initialize(FixtureContentLoader.new(story), game_state, quest_manager), "StoryRunner初始化失败")
    if relationship_manager != null:
        _expect(bool(runner.bind_relationship_manager(relationship_manager).get("ok", false)), "RelationshipManager绑定失败")
    runner.story_node_entered.connect(_on_story_node_entered)
    runner.story_started.connect(_on_story_started)
    runner.narrative_presented.connect(_on_narrative_presented)
    runner.dialogue_presented.connect(_on_dialogue_presented)
    runner.choice_presented.connect(_on_choice_presented)
    runner.reward_requested.connect(_on_reward_requested)
    runner.story_completed.connect(_on_story_completed)
    runner.story_error.connect(_on_story_error)
    return {"runner": runner, "game_state": game_state}


func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _failures.append("无法读取fixture：%s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        _failures.append("fixture不是有效JSON：%s" % path)
        return {}
    return parsed


func _find_node(story: Dictionary, node_id: String) -> Dictionary:
    for node: Variant in story["nodes"]:
        if node["node_id"] == node_id:
            return node
    return {}


func _last_text(events: Array[Dictionary]) -> String:
    return "" if events.is_empty() else str(events[-1].get("text", ""))


func _presented_choice_ids() -> Array[String]:
    var result: Array[String] = []
    if _choice_presentations.is_empty():
        return result
    for choice: Variant in _choice_presentations[-1]["choices"]:
        result.append(str(choice["choice_id"]))
    return result


func _has_state_event(key: String, source: String) -> bool:
    for event: Dictionary in _state_events:
        if event["key"] == key and event["source"] == source:
            return true
    return false


func _error_code(runner: RefCounted) -> String:
    return str(runner.get("last_error").get("code", ""))


func _clear_captured_events() -> void:
    _narratives.clear()
    _dialogues.clear()
    _choice_presentations.clear()
    _completions.clear()
    _errors.clear()
    _entered_nodes.clear()
    _state_events.clear()
    _starts.clear()
    _rewards.clear()


func _on_narrative_presented(value: Dictionary) -> void:
    _narratives.append(value)


func _on_dialogue_presented(value: Dictionary) -> void:
    _dialogues.append(value)


func _on_choice_presented(value: Dictionary) -> void:
    _choice_presentations.append(value)


func _on_reward_requested(value: Dictionary) -> void:
    _rewards.append(value)


func _on_story_completed(value: Dictionary) -> void:
    _completions.append(value)


func _on_story_error(value: Dictionary) -> void:
    _errors.append(value)


func _on_story_node_entered(_story_id: String, node_id: String, _node_type: String) -> void:
    _entered_nodes.append(node_id)


func _on_story_started(story_id: String, entry_node: String) -> void:
    _starts.append({"story_id": story_id, "entry_node": entry_node})


func _on_state_changed(key: String, old_value: Variant, new_value: Variant, source: String) -> void:
    _state_events.append({"key": key, "old_value": old_value, "new_value": new_value, "source": source})


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
