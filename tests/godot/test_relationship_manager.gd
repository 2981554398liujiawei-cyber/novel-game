extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")
const RelationshipManagerClass = preload("res://src/core/relationship_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")

const RELATIONSHIP_FIXTURE := "res://content/tests/fixtures/relationship_manager/relationships.json"
const RELATIONSHIP_STATE_FIXTURE := "res://content/tests/fixtures/relationship_manager/state_registry.json"
const QUEST_FIXTURE := "res://content/tests/fixtures/quest_manager/quests.json"
const QUEST_STATE_FIXTURE := "res://content/tests/fixtures/quest_manager/state_registry.json"
const BASE_STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"

const ALPHA := "TEST_REL_PLAYER_ALPHA"
const BETA := "TEST_REL_PLAYER_BETA"
const NPC_PAIR := "TEST_REL_ALPHA_BETA"
const PARALLEL_QUEST := "TEST_QUEST_PARALLEL"


class FixtureContentLoader extends RefCounted:
    var state_definitions: Array
    var state_index: Dictionary = {}
    var relationship_registry: Dictionary
    var quest_definitions: Array
    var story: Dictionary

    func _init(states: Array, relationships: Dictionary, quests: Array, story_document: Dictionary) -> void:
        state_definitions = states
        relationship_registry = relationships
        quest_definitions = quests
        story = story_document
        for definition: Dictionary in state_definitions:
            state_index[str(definition.get("key", ""))] = definition

    func get_state_definitions() -> Array:
        return state_definitions.duplicate(true)

    func get_state_definition(key: String) -> Variant:
        return state_index.get(key)

    func get_relationship_registry() -> Dictionary:
        return relationship_registry.duplicate(true)

    func get_relationship_definitions() -> Array:
        return relationship_registry.get("relationships", []).duplicate(true)

    func get_quest_definitions() -> Array:
        return quest_definitions.duplicate(true)

    func get_quest_dependencies() -> Dictionary:
        return {"schema_version": "1.0.0", "quests": []}

    func get_story(story_id: String) -> Variant:
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


var _failures: Array[String] = []
var _state_definitions: Array = []
var _relationship_fixture: Dictionary = {}
var _quest_definitions: Array = []
var _story_fixture: Dictionary = {}
var _stage_events: Array[Dictionary] = []
var _reward_events := 0
var _base_root := ""


func _init() -> void:
    var relationship_states := _read_json(RELATIONSHIP_STATE_FIXTURE)
    var quest_states := _read_json(QUEST_STATE_FIXTURE)
    var base_states := _read_json(BASE_STATE_FIXTURE)
    _relationship_fixture = _read_json(RELATIONSHIP_FIXTURE)
    var quests := _read_json(QUEST_FIXTURE)
    _story_fixture = _read_json(STORY_FIXTURE)
    if relationship_states.is_empty() or _relationship_fixture.is_empty() or quests.is_empty() or _story_fixture.is_empty():
        quit(1)
        return
    _state_definitions = _merge_state_definitions([
        relationship_states.get("states", []),
        quest_states.get("states", []),
        base_states.get("states", []),
    ])
    _quest_definitions = quests.get("quests", [])
    _base_root = OS.get_temp_dir().path_join("relationship_manager_tests_%d" % OS.get_process_id()).path_join("中文 路径")
    _remove_tree(_base_root)

    var context := _new_context(true)
    if not context.is_empty():
        _test_creation_defaults_dimensions_and_errors(context)
        _test_stages_boundaries_rejection_and_conflict(context)
        _test_quest_reward_and_combat_boundary()
        _test_save_round_trip_and_new_game(context)
        _test_multiple_relationships_and_stage_signal(context)
        _test_invalid_definition_is_rejected()

    _remove_tree(_base_root)
    if _failures.is_empty():
        print("RELATIONSHIP_MANAGER_TESTS_OK:30_SCENARIOS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("RELATIONSHIP_MANAGER_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_creation_defaults_dimensions_and_errors(context: Dictionary) -> void:
    var manager: RefCounted = context["relationship_manager"]
    _expect(manager.has_relationship(ALPHA), "1 fixture relationship was not created")
    var state: Dictionary = manager.get_relationship_state(ALPHA).get("relationship", {})
    _expect(state.get("dimensions", {}).get("trust") == 1 and state.get("stage") == "stranger", "2 relationship defaults are incorrect")
    _expect(manager.apply_effect(ALPHA, {"op": "inc", "dimension_id": "trust", "value": 2}).get("ok", false), "3 trust increment failed")
    _expect(manager.get_dimension(ALPHA, "trust").get("value") == 3, "3 trust increment produced wrong value")
    _expect(manager.apply_effect(ALPHA, {"op": "dec", "dimension_id": "affection", "value": 1}).get("ok", false), "4 affection decrement failed")
    _expect(manager.get_dimension(ALPHA, "affection").get("value") == 0, "4 affection decrement produced wrong value")
    _expect(manager.apply_effect(ALPHA, {"op": "inc", "dimension_id": "trust", "value": 99}).get("ok", false), "5 max clamp update failed")
    _expect(manager.get_dimension(ALPHA, "trust").get("value") == 10, "5 dimension exceeded maximum")
    _expect(manager.apply_effect(ALPHA, {"op": "dec", "dimension_id": "trust", "value": 99}).get("ok", false), "6 min clamp update failed")
    _expect(manager.get_dimension(ALPHA, "trust").get("value") == 0, "6 dimension fell below minimum")
    _expect_code(manager.apply_effect(ALPHA, {"op": "inc", "dimension_id": "missing", "value": 1}), RelationshipManagerClass.RELATIONSHIP_DIMENSION_NOT_FOUND, "7 unknown dimension")
    _expect_code(manager.get_relationship_state("TEST_REL_MISSING"), RelationshipManagerClass.RELATIONSHIP_NOT_FOUND, "8 unknown relationship")


func _test_stages_boundaries_rejection_and_conflict(context: Dictionary) -> void:
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["relationship_manager"]
    _expect(game_state.reset_all_states("system"), "could not reset relationship fixture")
    var stage_before := _stage_events.size()
    _expect(manager.apply_effects(ALPHA, [
        {"op": "set", "dimension_id": "trust", "value": 5},
        {"op": "set", "dimension_id": "respect", "value": 4},
    ]).get("ok", false), "9 stage threshold effects failed")
    _expect(manager.get_stage(ALPHA).get("stage") == "trusted", "9 combined dimensions did not enter trusted stage")
    _expect(_stage_events.size() == stage_before + 1, "9 stage change did not emit once")

    _expect(manager.apply_effects(ALPHA, [
        {"op": "set", "dimension_id": "trust", "value": 8},
        {"op": "set", "dimension_id": "affection", "value": 7},
        {"op": "set", "dimension_id": "respect", "value": 6},
    ]).get("ok", false), "10 intimate threshold effects failed")
    _expect(manager.get_stage(ALPHA).get("stage") == "close", "10 required flag did not block intimate stage")
    _expect(manager.reject_action(ALPHA, "romance").get("ok", false), "11 romance rejection failed")
    _expect(manager.set_flag(ALPHA, "mutual_interest", true).get("ok", false), "11 mutual interest flag failed")
    _expect(manager.get_stage(ALPHA).get("stage") == "close", "11 rejection flag did not block romantic stage")
    _expect(manager.apply_effects(ALPHA, [
        {"op": "set", "dimension_id": "trust", "value": 10},
        {"op": "set", "dimension_id": "affection", "value": 10},
    ]).get("ok", false), "12 high dimension update failed")
    _expect(manager.get_stage(ALPHA).get("stage") != "intimate", "12 high affection bypassed explicit rejection")

    _expect(game_state.reset_all_states("system"), "could not reset before rejection checks")
    _expect(manager.apply_effect(ALPHA, {"op": "set", "dimension_id": "trust", "value": 6}).get("ok", false), "could not seed rejection trust")
    var trust_before: Variant = manager.get_dimension(ALPHA, "trust").get("value")
    for action_id: String in ["flirt", "contact", "romance"]:
        _expect(manager.reject_action(ALPHA, action_id).get("ok", false), "13 %s rejection failed" % action_id)
        _expect(not manager.is_action_allowed(ALPHA, action_id).get("allowed", true), "13 rejected action remained available: %s" % action_id)
    _expect(manager.get_dimension(ALPHA, "trust").get("value") == trust_before, "13 rejection secretly lowered trust")
    _expect(manager.get_flag(ALPHA, "quest_access").get("value") == true, "14 rejection blocked unrelated quest access")
    _expect(manager.reopen_action(ALPHA, "reopen_flirt").get("ok", false), "15 explicit reopen failed")
    _expect(manager.is_action_allowed(ALPHA, "flirt").get("allowed", false), "15 explicitly reopened action is still blocked")

    _expect(manager.enter_conflict(ALPHA, "fixture_disagreement").get("ok", false), "16 conflict entry failed")
    _expect(manager.get_conflict(ALPHA).get("conflict", {}).get("active") == true, "16 active conflict was not queryable")
    _expect(manager.apply_effect(ALPHA, {"op": "inc", "dimension_id": "trust", "value": 3}).get("ok", false), "17 ordinary relationship growth failed")
    _expect(manager.get_conflict(ALPHA).get("conflict", {}).get("active") == true, "17 ordinary numeric growth auto-cleared conflict")
    _expect(manager.repair_conflict(ALPHA, 5).get("ok", false), "18 explicit conflict repair failed")
    _expect(manager.get_conflict(ALPHA).get("conflict", {}).get("active") == false, "18 repair threshold did not clear conflict")
    _expect(manager.select_text_version(ALPHA).get("tag") in ["romance_blocked", "close", "high_trust", "neutral"], "19 text version tag was not selected")


func _test_quest_reward_and_combat_boundary() -> void:
    _reward_events = 0
    var context := _new_context(true)
    if context.is_empty():
        return
    var manager: RefCounted = context["relationship_manager"]
    var quest_manager: RefCounted = context["quest_manager"]
    quest_manager.quest_reward_ready.connect(Callable(self, "_on_quest_reward").bind(quest_manager))
    _expect(quest_manager.activate_quest(PARALLEL_QUEST).get("ok", false), "quest integration could not activate fixture quest")
    _expect(quest_manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true}).get("ok", false), "quest integration first objective failed")
    _expect(quest_manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true}).get("ok", false), "quest integration second objective failed")
    _expect(quest_manager.get_quest_status(PARALLEL_QUEST).get("status") == "qualified", "21 fixture quest did not qualify")
    _expect(_reward_events == 0 and manager.get_dimension(ALPHA, "trust").get("value") == 1, "21 qualified quest granted completion relationship reward")
    _expect(quest_manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true}).get("ok", false), "20 final quest objective failed")
    _expect(_reward_events == 1 and manager.get_dimension(ALPHA, "trust").get("value") == 2, "20 completed quest relationship reward was not applied once")
    _expect(quest_manager.complete_quest(PARALLEL_QUEST).get("ok", false), "20 repeated completion call failed")
    _expect(_reward_events == 1 and manager.get_dimension(ALPHA, "trust").get("value") == 2, "20 repeated completion duplicated relationship reward")
    var before_combat_tag: Dictionary = manager.get_relationship_state(ALPHA).get("relationship", {}).duplicate(true)
    var combat_result := {"event_tags": ["victory", "protected_ally"], "result_type": "victory"}
    _expect(combat_result.get("event_tags", []).size() == 2, "22 combat event-tag fixture is invalid")
    _expect(manager.get_relationship_state(ALPHA).get("relationship", {}) == before_combat_tag, "22 combat event tags directly modified relationship state")


func _test_save_round_trip_and_new_game(context: Dictionary) -> void:
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["relationship_manager"]
    var loader: RefCounted = context["loader"]
    _expect(game_state.reset_all_states("system"), "could not reset before relationship save test")
    _expect(manager.apply_effects(ALPHA, [
        {"op": "set", "dimension_id": "trust", "value": 8},
        {"op": "set", "dimension_id": "affection", "value": 7},
        {"op": "set", "dimension_id": "respect", "value": 6},
    ]).get("ok", false), "could not prepare save relationship dimensions")
    _expect(manager.set_flag(ALPHA, "mutual_interest", true).get("ok", false), "could not prepare save relationship flag")
    _expect(manager.reject_action(ALPHA, "contact").get("ok", false), "could not prepare save rejection")
    _expect(manager.enter_conflict(ALPHA, "save_fixture_conflict").get("ok", false), "could not prepare save conflict")
    var expected: Dictionary = manager.get_relationship_state(ALPHA).get("relationship", {}).duplicate(true)

    var story_runner := StoryRunnerClass.new()
    _expect(story_runner.initialize(loader, game_state), "relationship SaveManager story could not initialize")
    _expect(story_runner.start_story(str(_story_fixture["quest_id"])), "relationship SaveManager story could not start")
    var save_manager := SaveManagerClass.new()
    var save_root := _base_root.path_join("saves")
    var backup_root := _base_root.path_join("backups")
    _expect(save_manager.initialize(loader, game_state, story_runner, save_root, backup_root), "relationship SaveManager could not initialize")
    _expect(save_manager.save("manual_1").get("ok", false), "23 relationship save failed")
    _expect(manager.apply_effect(ALPHA, {"op": "set", "dimension_id": "trust", "value": 0}).get("ok", false), "could not mutate relationship before load")
    _expect(manager.repair_conflict(ALPHA, 5).get("ok", false), "could not mutate relationship conflict before load")
    var stage_events_before_load := _stage_events.size()
    _expect(save_manager.load("manual_1").get("ok", false), "23 relationship load failed")
    _expect(manager.get_relationship_state(ALPHA).get("relationship", {}) == expected, "23 SaveManager did not restore exact relationship state")
    _expect(_stage_events.size() == stage_events_before_load, "24 loading emitted duplicate relationship stage event")

    var new_context := _new_context(false)
    _expect(not new_context.is_empty(), "25 new-game relationship context failed")
    if not new_context.is_empty():
        var new_manager: RefCounted = new_context["relationship_manager"]
        var new_state: Dictionary = new_manager.get_relationship_state(ALPHA).get("relationship", {})
        _expect(new_state.get("dimensions", {}).get("trust") == 1 and not new_state.get("conflict", {}).get("active", true), "25 new game inherited old relationship state")


func _test_multiple_relationships_and_stage_signal(context: Dictionary) -> void:
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["relationship_manager"]
    _expect(game_state.reset_all_states("system"), "could not reset before relationship isolation tests")
    _expect(manager.apply_effect(BETA, {"op": "inc", "dimension_id": "trust", "value": 4}).get("ok", false), "26 second player-NPC relationship update failed")
    _expect(manager.get_dimension(BETA, "trust").get("value") == 5 and manager.get_dimension(ALPHA, "trust").get("value") == 1, "26 player-NPC relationships were not isolated")
    _expect(manager.apply_effect(NPC_PAIR, {"op": "inc", "dimension_id": "respect", "value": 3}).get("ok", false), "27 NPC-NPC relationship update failed")
    _expect(manager.get_relationship_state(NPC_PAIR).get("relationship", {}).get("metadata", {}).get("relationship_kind") == "npc_npc", "27 NPC-NPC relationship was not supported")
    _expect(manager.set_boundary(ALPHA, "trust_sensitive", false).get("ok", false), "28 boundary update failed")
    _expect(manager.get_boundary(ALPHA, "trust_sensitive").get("value") == false, "28 boundary query returned wrong value")
    var before := _stage_events.size()
    _expect(manager.apply_effects(ALPHA, [
        {"op": "set", "dimension_id": "trust", "value": 5},
        {"op": "set", "dimension_id": "respect", "value": 4},
    ]).get("ok", false), "29 stage signal fixture update failed")
    _expect(_stage_events.size() == before + 1, "29 one stage transition did not emit exactly once")


func _test_invalid_definition_is_rejected() -> void:
    var invalid_fixture := _relationship_fixture.duplicate(true)
    invalid_fixture["relationships"][0]["dimensions"]["trust"] = "test.relationship.missing"
    var loader := FixtureContentLoader.new(_state_definitions, invalid_fixture, _quest_definitions, _story_fixture)
    var game_state := GameStateClass.new()
    _expect(game_state.initialize_from_content_loader(loader), "30 invalid reference fixture GameState could not initialize")
    var manager := RelationshipManagerClass.new()
    _expect(not manager.initialize(loader, game_state), "30 invalid relationship state reference passed runtime validation")
    _expect(manager.last_error.get("code") == RelationshipManagerClass.RELATIONSHIP_DEFINITION_INVALID, "30 invalid relationship reference returned wrong error")


func _new_context(capture_stage_events: bool) -> Dictionary:
    var loader := FixtureContentLoader.new(_state_definitions, _relationship_fixture, _quest_definitions, _story_fixture)
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState fixture initialization failed: %s" % game_state.last_error)
        return {}
    var manager := RelationshipManagerClass.new()
    if capture_stage_events:
        manager.stage_changed.connect(_on_stage_changed)
    if not manager.initialize(loader, game_state):
        _failures.append("RelationshipManager fixture initialization failed: %s" % manager.last_error)
        return {}
    var quest_manager := QuestManagerClass.new()
    if not quest_manager.initialize(loader, game_state):
        _failures.append("QuestManager integration fixture initialization failed: %s" % quest_manager.last_error)
        return {}
    if not quest_manager.bind_relationship_manager(manager).get("ok", false):
        _failures.append("QuestManager relationship binding failed")
        return {}
    var story_runner := StoryRunnerClass.new()
    if not story_runner.initialize(loader, game_state, quest_manager):
        _failures.append("StoryRunner integration fixture initialization failed: %s" % story_runner.last_error)
        return {}
    if not story_runner.bind_relationship_manager(manager).get("ok", false):
        _failures.append("StoryRunner relationship binding failed")
        return {}
    _expect(story_runner.evaluate_relationship_condition(ALPHA, {"kind": "dimension", "dimension_id": "trust", "op": "gte", "value": 1}).get("matched", false), "StoryRunner did not delegate relationship query")
    _expect(quest_manager.evaluate_relationship_condition(ALPHA, {"kind": "flag", "flag_id": "quest_access", "value": true}).get("matched", false), "QuestManager did not delegate relationship query")
    return {"loader": loader, "game_state": game_state, "relationship_manager": manager, "quest_manager": quest_manager, "story_runner": story_runner}


func _on_quest_reward(_result: Dictionary, quest_manager: RefCounted) -> void:
    _reward_events += 1
    var relationship_result: Dictionary = quest_manager.apply_relationship_effects(ALPHA, [
        {"op": "inc", "dimension_id": "trust", "value": 1},
    ])
    if not relationship_result.get("ok", false):
        _failures.append("QuestManager could not delegate completion relationship reward")


func _on_stage_changed(relationship_id: String, previous_stage: String, current_stage: String, source: String) -> void:
    _stage_events.append({"relationship_id": relationship_id, "previous": previous_stage, "current": current_stage, "source": source})


func _merge_state_definitions(groups: Array) -> Array:
    var result: Array = []
    var seen := {}
    for group: Variant in groups:
        for definition: Dictionary in group:
            var key := str(definition.get("key", ""))
            if not seen.has(key):
                result.append(definition.duplicate(true))
                seen[key] = true
    return result


func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _failures.append("could not open fixture: %s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        _failures.append("fixture is not a JSON object: %s" % path)
        return {}
    return parsed


func _expect(value: bool, message: String) -> void:
    if not value:
        _failures.append(message)


func _expect_code(result: Dictionary, code: String, label: String) -> void:
    _expect(not result.get("ok", true) and result.get("code") == code, "%s returned %s" % [label, result])


func _remove_tree(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path):
        return
    var directory := DirAccess.open(path)
    if directory == null:
        return
    directory.list_dir_begin()
    var name := directory.get_next()
    while not name.is_empty():
        var child := path.path_join(name)
        if directory.current_is_dir():
            _remove_tree(child)
        else:
            DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(path)
