extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")

const STATE_FIXTURE := "res://content/tests/fixtures/quest_manager/state_registry.json"
const BASE_STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const QUEST_FIXTURE := "res://content/tests/fixtures/quest_manager/quests.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"
const PARALLEL_QUEST := "TEST_QUEST_PARALLEL"
const UNLOCKED_QUEST := "TEST_QUEST_UNLOCKED"
const RECOVERY_QUEST := "TEST_QUEST_RECOVERY"


class FixtureContentLoader extends RefCounted:
    var state_definitions: Array
    var quest_definitions: Array
    var quest_dependencies: Dictionary
    var story: Dictionary

    func _init(
        states: Array,
        quests: Array,
        dependencies: Dictionary,
        story_document: Dictionary,
    ) -> void:
        state_definitions = states
        quest_definitions = quests
        quest_dependencies = dependencies
        story = story_document

    func get_state_definitions() -> Array:
        return state_definitions.duplicate(true)

    func get_quest_definitions() -> Array:
        return quest_definitions.duplicate(true)

    func get_quest_dependencies() -> Dictionary:
        return quest_dependencies.duplicate(true)

    func get_story(story_id: String) -> Variant:
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


var _failures: Array[String] = []
var _reward_events: Array[Dictionary] = []
var _status_events: Array[Dictionary] = []
var _state_definitions: Array = []
var _quest_definitions: Array = []
var _story_fixture: Dictionary = {}
var _base_root := ""
var _clock_tick := 0


func _init() -> void:
    var state_document := _read_json(STATE_FIXTURE)
    var base_state_document := _read_json(BASE_STATE_FIXTURE)
    var quest_document := _read_json(QUEST_FIXTURE)
    _story_fixture = _read_json(STORY_FIXTURE)
    if (
        state_document.is_empty()
        or base_state_document.is_empty()
        or quest_document.is_empty()
        or _story_fixture.is_empty()
        or not state_document.get("states") is Array
        or not quest_document.get("quests") is Array
    ):
        quit(1)
        return
    _state_definitions = state_document["states"]
    var known_state_keys := {}
    for definition: Dictionary in _state_definitions:
        known_state_keys[str(definition.get("key", ""))] = true
    for definition: Dictionary in base_state_document.get("states", []):
        var key := str(definition.get("key", ""))
        if not known_state_keys.has(key):
            _state_definitions.append(definition.duplicate(true))
            known_state_keys[key] = true
    _quest_definitions = quest_document["quests"]
    _base_root = OS.get_temp_dir().path_join("quest_manager_tests_%d" % OS.get_process_id())
    _remove_tree(_base_root)

    _test_prerequisites_and_reversible_availability()
    _test_parallel_qualification_and_idempotent_completion()
    _test_all_objective_types_and_mutual_exclusion()
    _test_mutual_exclusion_is_symmetric_and_terminal()
    _test_failure_suspend_resume_and_reopen()
    _test_invalid_ids_and_transitions()
    _test_dependency_cycle_is_rejected()
    _test_story_runner_delegates_quest_actions()
    _test_game_state_checkpoint_is_the_single_truth()
    _test_save_manager_round_trips_every_lifecycle_state()
    _test_new_game_does_not_inherit_quest_state()

    _remove_tree(_base_root)
    if _failures.is_empty():
        print("QUEST_MANAGER_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("QUEST_MANAGER_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_prerequisites_and_reversible_availability() -> void:
    var context := _new_context("availability")
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["quest_manager"]

    _expect_status(manager, PARALLEL_QUEST, "available", "default AND/OR prerequisites")
    _expect_status(manager, RECOVERY_QUEST, "available", "second independent quest")
    _expect_status(manager, UNLOCKED_QUEST, "not_started", "quest prerequisite is still locked")
    _expect_code(
        manager.activate_quest(UNLOCKED_QUEST),
        QuestManagerClass.QUEST_PREREQUISITES_UNMET,
        "activation with unmet quest prerequisite",
    )

    _expect(game_state.set_state("test.flag", false, "debug"), "could not disable the AND prerequisite")
    _expect_status(manager, PARALLEL_QUEST, "not_started", "failed AND prerequisite returns to not_started")
    _expect_code(
        manager.activate_quest(PARALLEL_QUEST),
        QuestManagerClass.QUEST_PREREQUISITES_UNMET,
        "activation with failed state prerequisite",
    )
    _expect(game_state.set_state("test.flag", true, "debug"), "could not restore the AND prerequisite")
    _expect(game_state.set_state("test.counter", 0, "debug"), "could not disable the first OR branch")
    _expect(game_state.set_state("test.mode", "idle", "debug"), "could not disable the second OR branch")
    _expect_status(manager, PARALLEL_QUEST, "not_started", "both failed OR branches keep a quest locked")
    _expect(game_state.set_state("test.mode", "active", "debug"), "could not satisfy the second OR branch")
    _expect_status(manager, PARALLEL_QUEST, "available", "availability is reversible after conditions recover")


func _test_parallel_qualification_and_idempotent_completion() -> void:
    var context := _new_context("parallel")
    if context.is_empty():
        return
    var manager: RefCounted = context["quest_manager"]
    var initial_progress: Dictionary = manager.get_quest_progress(PARALLEL_QUEST)

    _expect(manager.activate_quest(PARALLEL_QUEST).get("ok", false), "available quest could not activate")
    var second_activation: Dictionary = manager.activate_quest(PARALLEL_QUEST)
    _expect(second_activation.get("ok", false) and not second_activation.get("changed", true), "repeat activation was not idempotent")
    _expect(
        manager.get_quest_progress(PARALLEL_QUEST).get("objectives") == initial_progress.get("objectives"),
        "repeat activation reinitialized objective progress",
    )

    var first: Dictionary = manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true, "event_id": "event_a"})
    _expect(first.get("ok", false), "first parallel objective update failed")
    var duplicate: Dictionary = manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true, "event_id": "event_a"})
    _expect(duplicate.get("ok", false) and not duplicate.get("changed", true), "duplicate boolean event changed progress")
    _expect_status(manager, PARALLEL_QUEST, "active", "one of three objectives")

    _expect(manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true}).get("ok", false), "second parallel objective update failed")
    _expect_status(manager, PARALLEL_QUEST, "qualified", "two of three objectives")
    _expect_status(manager, UNLOCKED_QUEST, "available", "qualified quest unlocks its dependent")
    _expect(manager.get_objective_progress(PARALLEL_QUEST, "commission_c").get("progress") == false, "qualified state incorrectly completed the third objective")

    _expect(manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true}).get("ok", false), "third objective could not finish after qualification")
    _expect_status(manager, PARALLEL_QUEST, "completed", "three of three objectives")
    _expect(_has_status_event("parallel", PARALLEL_QUEST, "active", "qualified"), "qualified status signal was not emitted")
    _expect(_has_status_event("parallel", PARALLEL_QUEST, "qualified", "completed"), "completed status signal was not emitted")
    _expect(_reward_count("parallel") == 1, "completion reward signal was not emitted exactly once")
    var repeated_completion: Dictionary = manager.complete_quest(PARALLEL_QUEST)
    _expect(
        repeated_completion.get("ok", false)
        and not repeated_completion.get("changed", true)
        and not repeated_completion.get("reward_emitted", true),
        "repeat completion was not idempotent",
    )
    _expect(_reward_count("parallel") == 1, "repeat completion emitted the reward twice")
    var post_complete_update: Dictionary = manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true})
    _expect(post_complete_update.get("ok", false) and not post_complete_update.get("changed", true), "completed quest accepted a changing objective update")


func _test_all_objective_types_and_mutual_exclusion() -> void:
    var context := _new_context("objective_types")
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["quest_manager"]
    _qualify_parallel(manager)
    _expect(manager.activate_quest(UNLOCKED_QUEST).get("ok", false), "qualified dependent quest could not activate")
    _expect_status(manager, RECOVERY_QUEST, "not_started", "mutually exclusive active quest did not block availability")

    _expect(manager.update_objective(UNLOCKED_QUEST, "boolean_task", {"value": true}).get("ok", false), "boolean objective update failed")
    _expect(manager.update_objective(UNLOCKED_QUEST, "counter_task", {"value": 1, "event_id": "count_1"}).get("ok", false), "first counter objective update failed")
    _expect(manager.get_objective_progress(UNLOCKED_QUEST, "counter_task").get("progress") == 1, "counter objective did not grow to one")
    _expect(manager.update_objective(UNLOCKED_QUEST, "counter_task", {"value": 2, "event_id": "count_2"}).get("ok", false), "second counter objective update failed")
    _expect(manager.update_objective(UNLOCKED_QUEST, "counter_task", {"value": 1, "event_id": "old_count"}).get("ok", false), "lower repeated counter report was rejected")
    _expect(manager.get_objective_progress(UNLOCKED_QUEST, "counter_task").get("progress") == 2, "counter objective was not monotonic")
    _expect(manager.update_objective(UNLOCKED_QUEST, "counter_task", {"value": 99}).get("ok", false), "counter cap update failed")
    _expect(manager.get_objective_progress(UNLOCKED_QUEST, "counter_task").get("progress") == 3, "counter objective exceeded or missed its cap")

    _expect(manager.update_objective(UNLOCKED_QUEST, "collection_task", {"value": 99}).get("ok", false), "collection objective cap update failed")
    _expect(manager.get_objective_progress(UNLOCKED_QUEST, "collection_task").get("progress") == 2, "collection objective exceeded its cap")
    _expect(manager.update_objective(UNLOCKED_QUEST, "collection_task", {"value": 2}).get("ok", false), "duplicate collection report failed")
    _expect(manager.update_objective(UNLOCKED_QUEST, "combat_task", {"value": "retreat"}).get("ok", false), "registered non-target combat result failed")
    _expect(not manager.get_objective_progress(UNLOCKED_QUEST, "combat_task").get("completed", true), "non-target combat result completed the objective")
    _expect(manager.update_objective(UNLOCKED_QUEST, "combat_task", {"value": "victory"}).get("ok", false), "target combat result failed")
    _expect_status(manager, UNLOCKED_QUEST, "active", "derived state objective completed too early")
    _expect(game_state.set_state("test.mode", "active", "debug"), "could not satisfy the state-condition objective")
    _expect(manager.get_objective_progress(UNLOCKED_QUEST, "state_gate_task").get("completed", false), "state-condition objective did not query GameState")
    _expect_status(manager, UNLOCKED_QUEST, "completed", "all supported objective types")


func _test_mutual_exclusion_is_symmetric_and_terminal() -> void:
    var active_context := _new_context("mutual_reverse")
    if active_context.is_empty():
        return
    var active_manager: RefCounted = active_context["quest_manager"]
    _expect(active_manager.activate_quest(RECOVERY_QUEST).get("ok", false), "single-sided exclusion owner could not activate")
    _qualify_parallel(active_manager)
    _expect_status(active_manager, UNLOCKED_QUEST, "not_started", "single-sided mutual exclusion did not block the reverse direction")
    _expect_code(
        active_manager.activate_quest(UNLOCKED_QUEST),
        QuestManagerClass.QUEST_PREREQUISITES_UNMET,
        "reverse-direction mutually exclusive activation",
    )

    var completed_context := _new_context("mutual_completed")
    if completed_context.is_empty():
        return
    var completed_manager: RefCounted = completed_context["quest_manager"]
    _expect(completed_manager.activate_quest(RECOVERY_QUEST).get("ok", false), "completed exclusion owner could not activate")
    _expect(
        completed_manager.update_objective(RECOVERY_QUEST, "recovery_goal", {"value": true}).get("ok", false),
        "completed exclusion owner could not complete",
    )
    _expect_status(completed_manager, RECOVERY_QUEST, "completed", "mutual exclusion completion setup")
    _qualify_parallel(completed_manager)
    _expect_status(completed_manager, UNLOCKED_QUEST, "not_started", "completed mutually exclusive quest released its branch")


func _test_failure_suspend_resume_and_reopen() -> void:
    var context := _new_context("continuations")
    if context.is_empty():
        return
    var manager: RefCounted = context["quest_manager"]
    _expect(manager.activate_quest(RECOVERY_QUEST).get("ok", false), "recovery quest could not activate")
    _expect(manager.fail_quest(RECOVERY_QUEST, "retry_route").get("ok", false), "active quest could not fail into a continuation")
    _expect_status(manager, RECOVERY_QUEST, "failed", "failed lifecycle")
    _expect(manager.resume_quest(RECOVERY_QUEST).get("ok", false), "failed quest could not resume")
    _expect_status(manager, RECOVERY_QUEST, "active", "resume from failed")

    _expect(manager.fail_quest(RECOVERY_QUEST, "alternate_route").get("ok", false), "alternate failure continuation failed")
    _expect(manager.reopen_quest(RECOVERY_QUEST).get("ok", false), "data-driven failed quest could not reopen")
    _expect_status(manager, RECOVERY_QUEST, "available", "reopen from failed")
    _expect(manager.activate_quest(RECOVERY_QUEST).get("ok", false), "reopened quest could not activate")
    _expect(manager.suspend_quest(RECOVERY_QUEST, "retry_route").get("ok", false), "active quest could not suspend")
    _expect_status(manager, RECOVERY_QUEST, "suspended", "suspended lifecycle")
    _expect(manager.resume_quest(RECOVERY_QUEST).get("ok", false), "suspended quest could not resume")
    _expect_status(manager, RECOVERY_QUEST, "active", "resume from suspended")
    _expect(manager.suspend_quest(RECOVERY_QUEST).get("ok", false), "active quest could not suspend without replacing its continuation")
    _expect(manager.resume_quest(RECOVERY_QUEST).get("ok", false), "suspended quest with an existing data-driven continuation could not resume")
    _expect_status(manager, RECOVERY_QUEST, "active", "resume from suspension without a new continuation")


func _test_invalid_ids_and_transitions() -> void:
    var context := _new_context("errors")
    if context.is_empty():
        return
    var manager: RefCounted = context["quest_manager"]
    _expect_code(manager.get_quest_status("TEST_QUEST_UNKNOWN"), QuestManagerClass.QUEST_NOT_FOUND, "unknown quest ID")
    _expect_code(manager.set_qualified(PARALLEL_QUEST), QuestManagerClass.QUEST_TRANSITION_INVALID, "qualified before activation")
    _expect_code(manager.transition_quest(PARALLEL_QUEST, "invalid_status"), QuestManagerClass.QUEST_TRANSITION_INVALID, "unknown lifecycle transition")
    _expect(manager.activate_quest(PARALLEL_QUEST).get("ok", false), "qualification threshold fixture could not activate")
    _expect(manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true}).get("ok", false), "qualification threshold fixture objective failed")
    _expect_code(manager.set_qualified(PARALLEL_QUEST), QuestManagerClass.QUEST_NOT_QUALIFIED, "qualified before objective threshold")
    _expect_status(manager, PARALLEL_QUEST, "active", "failed qualification request changed lifecycle")
    _expect(manager.activate_quest(RECOVERY_QUEST).get("ok", false), "error fixture recovery activation failed")
    _expect_code(
        manager.fail_quest(RECOVERY_QUEST, "missing_variant"),
        QuestManagerClass.QUEST_CONTINUATION_INVALID,
        "unregistered failure variant",
    )
    _expect_status(manager, RECOVERY_QUEST, "active", "invalid failure transition was not atomic")


func _test_dependency_cycle_is_rejected() -> void:
    var dependencies := {
        "schema_version": "1.0.0",
        "quests": [
            {"quest_id": PARALLEL_QUEST, "depends_on": [UNLOCKED_QUEST]},
            {"quest_id": UNLOCKED_QUEST, "depends_on": [PARALLEL_QUEST]},
        ],
    }
    var loader := FixtureContentLoader.new(_state_definitions, _quest_definitions, dependencies, _story_fixture)
    var game_state := GameStateClass.new()
    _expect(game_state.initialize_from_content_loader(loader), "cycle test GameState initialization failed")
    var manager := QuestManagerClass.new()
    _expect(not manager.initialize(loader, game_state), "cyclic quest dependencies initialized successfully")
    _expect(str(manager.last_error.get("code", "")) == QuestManagerClass.QUEST_DEPENDENCY_CYCLE, "dependency cycle returned the wrong error code")


func _test_story_runner_delegates_quest_actions() -> void:
    var context := _new_context("story_delegation")
    if context.is_empty():
        return
    var runner: RefCounted = context["runner"]
    var manager: RefCounted = context["quest_manager"]
    _expect(runner.get_quest_status(PARALLEL_QUEST).get("status") == "available", "StoryRunner could not query QuestManager")
    _expect(runner.activate_quest(PARALLEL_QUEST).get("ok", false), "StoryRunner could not activate a quest")
    _expect(runner.update_quest_objective(PARALLEL_QUEST, "commission_a", {"value": true}).get("ok", false), "StoryRunner could not update an objective")
    _expect(runner.update_quest_objective(PARALLEL_QUEST, "commission_b", {"value": true}).get("ok", false), "StoryRunner second objective proxy failed")
    _expect(runner.set_quest_qualified(PARALLEL_QUEST).get("ok", false), "StoryRunner could not preserve qualified through its proxy")
    _expect(runner.update_quest_objective(PARALLEL_QUEST, "commission_c", {"value": true}).get("ok", false), "StoryRunner third objective proxy failed")
    _expect(runner.complete_quest(PARALLEL_QUEST).get("ok", false), "StoryRunner repeated complete proxy failed")
    _expect_status(manager, PARALLEL_QUEST, "completed", "StoryRunner completion proxy")

    _expect(runner.activate_quest(RECOVERY_QUEST).get("ok", false), "StoryRunner could not activate recovery quest")
    _expect(runner.fail_quest(RECOVERY_QUEST, "retry_route").get("ok", false), "StoryRunner could not fail a quest")
    _expect(runner.reopen_quest(RECOVERY_QUEST).get("ok", false), "StoryRunner could not reopen a failed quest")
    _expect(runner.activate_quest(RECOVERY_QUEST).get("ok", false), "StoryRunner could not reactivate a reopened quest")
    _expect(runner.suspend_quest(RECOVERY_QUEST, "retry_route").get("ok", false), "StoryRunner could not suspend a quest")
    _expect(runner.resume_quest(RECOVERY_QUEST).get("ok", false), "StoryRunner could not resume a quest")


func _test_game_state_checkpoint_is_the_single_truth() -> void:
    var context := _new_context("checkpoint")
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["quest_manager"]
    _expect(manager.activate_quest(PARALLEL_QUEST).get("ok", false), "checkpoint quest activation failed")
    var checkpoint: Dictionary = game_state.create_runtime_checkpoint()
    _qualify_parallel(manager)
    _expect_status(manager, PARALLEL_QUEST, "qualified", "checkpoint mutation setup")
    _expect(game_state.restore_runtime_checkpoint(checkpoint), "GameState checkpoint rollback failed")
    _expect_status(manager, PARALLEL_QUEST, "active", "QuestManager did not synchronize after GameState rollback")
    _expect(manager.get_objective_progress(PARALLEL_QUEST, "commission_a").get("progress") == false, "objective A survived checkpoint rollback")
    _expect(manager.get_objective_progress(PARALLEL_QUEST, "commission_b").get("progress") == false, "objective B survived checkpoint rollback")


func _test_save_manager_round_trips_every_lifecycle_state() -> void:
    for expected_status: String in ["active", "qualified", "completed", "failed", "suspended"]:
        var case_name := "save_%s" % expected_status
        var context := _new_context(case_name, true)
        if context.is_empty():
            continue
        var game_state: RefCounted = context["game_state"]
        var quest_manager: RefCounted = context["quest_manager"]
        var save_manager: RefCounted = context["save_manager"]
        _prepare_saved_status(quest_manager, expected_status)
        _expect_status(quest_manager, _quest_for_status(expected_status), expected_status, "save setup %s" % expected_status)
        var expected_snapshot: Dictionary = game_state.export_snapshot()
        var expected_progress: Dictionary = quest_manager.get_quest_progress(_quest_for_status(expected_status))
        var rewards_before := _reward_count(case_name)
        _expect(save_manager.save("manual_1").get("ok", false), "SaveManager could not save %s quest" % expected_status)
        _expect(game_state.reset_all_states("system"), "could not mutate quest runtime before loading %s" % expected_status)
        _expect(save_manager.load("manual_1").get("ok", false), "SaveManager could not load %s quest" % expected_status)
        _expect(game_state.export_snapshot() == expected_snapshot, "SaveManager did not exactly restore %s GameState" % expected_status)
        _expect(
            quest_manager.get_quest_progress(_quest_for_status(expected_status)) == expected_progress,
            "SaveManager did not exactly restore %s objective progress" % expected_status,
        )
        _expect_status(quest_manager, _quest_for_status(expected_status), expected_status, "loaded %s status" % expected_status)
        _expect(_reward_count(case_name) == rewards_before, "loading %s emitted a duplicate reward" % expected_status)


func _test_new_game_does_not_inherit_quest_state() -> void:
    var old_context := _new_context("old_game")
    if old_context.is_empty():
        return
    var old_manager: RefCounted = old_context["quest_manager"]
    _complete_parallel(old_manager)
    _expect_status(old_manager, PARALLEL_QUEST, "completed", "old game completion setup")

    var new_context := _new_context("new_game")
    if new_context.is_empty():
        return
    var new_state: RefCounted = new_context["game_state"]
    var new_manager: RefCounted = new_context["quest_manager"]
    _expect_status(new_manager, PARALLEL_QUEST, "available", "new game default quest lifecycle")
    _expect(new_state.get_state("quest.test.parallel.reward_granted") == false, "new game inherited an old reward marker")
    _expect(new_manager.get_objective_progress(PARALLEL_QUEST, "commission_a").get("progress") == false, "new game inherited old objective progress")


func _new_context(case_name: String, initialize_save_manager: bool = false) -> Dictionary:
    var loader := FixtureContentLoader.new(
        _state_definitions,
        _quest_definitions,
        {"schema_version": "1.0.0", "quests": []},
        _story_fixture,
    )
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState initialization failed for %s: %s" % [case_name, str(game_state.last_error)])
        return {}
    var quest_manager := QuestManagerClass.new()
    quest_manager.quest_reward_ready.connect(Callable(self, "_on_reward_ready").bind(case_name))
    quest_manager.quest_status_changed.connect(Callable(self, "_on_status_changed").bind(case_name))
    if not quest_manager.initialize(loader, game_state):
        _failures.append("QuestManager initialization failed for %s: %s" % [case_name, str(quest_manager.last_error)])
        return {}
    var runner := StoryRunnerClass.new()
    if not runner.initialize(loader, game_state, quest_manager) or not runner.start_story("TEST_STORY_MINIMAL"):
        _failures.append("StoryRunner initialization failed for %s: %s" % [case_name, str(runner.last_error)])
        return {}

    var context := {
        "loader": loader,
        "game_state": game_state,
        "quest_manager": quest_manager,
        "runner": runner,
    }
    if initialize_save_manager:
        var case_root := _base_root.path_join(case_name)
        _remove_tree(case_root)
        var save_manager := SaveManagerClass.new()
        if not save_manager.initialize(
            loader,
            game_state,
            runner,
            case_root.path_join("saves"),
            case_root.path_join("backups"),
            "quest-test-version",
            Callable(self, "_next_timestamp"),
        ):
            _failures.append("SaveManager initialization failed for %s: %s" % [case_name, str(save_manager.last_result)])
            return {}
        context["save_manager"] = save_manager
    return context


func _prepare_saved_status(manager: RefCounted, expected_status: String) -> void:
    if expected_status in ["active", "qualified", "completed"]:
        manager.activate_quest(PARALLEL_QUEST)
        manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true})
        if expected_status in ["qualified", "completed"]:
            manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true})
        if expected_status == "completed":
            manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true})
        return
    manager.activate_quest(RECOVERY_QUEST)
    if expected_status == "failed":
        manager.fail_quest(RECOVERY_QUEST, "retry_route")
    else:
        manager.suspend_quest(RECOVERY_QUEST, "retry_route")


func _quest_for_status(status: String) -> String:
    return RECOVERY_QUEST if status in ["failed", "suspended"] else PARALLEL_QUEST


func _qualify_parallel(manager: RefCounted) -> void:
    if manager.get_quest_status(PARALLEL_QUEST).get("status") == "available":
        manager.activate_quest(PARALLEL_QUEST)
    manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true})
    manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true})


func _complete_parallel(manager: RefCounted) -> void:
    _qualify_parallel(manager)
    manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true})


func _expect_status(manager: RefCounted, quest_id: String, expected: String, label: String) -> void:
    var result: Dictionary = manager.get_quest_status(quest_id)
    _expect(result.get("ok", false), "%s status query failed: %s" % [label, str(result)])
    _expect(str(result.get("status", "")) == expected, "%s status was %s instead of %s" % [label, result.get("status", ""), expected])


func _expect_code(result: Dictionary, expected: String, label: String) -> void:
    _expect(not bool(result.get("ok", true)), "%s unexpectedly succeeded" % label)
    _expect(str(result.get("code", "")) == expected, "%s returned %s instead of %s" % [label, result.get("code", ""), expected])


func _on_reward_ready(result: Dictionary, case_name: String) -> void:
    _reward_events.append({"case_name": case_name, "result": result.duplicate(true)})


func _on_status_changed(
    quest_id: String,
    old_status: String,
    new_status: String,
    source: String,
    case_name: String,
) -> void:
    _status_events.append({
        "case_name": case_name,
        "quest_id": quest_id,
        "old_status": old_status,
        "new_status": new_status,
        "source": source,
    })


func _reward_count(case_name: String) -> int:
    var count := 0
    for event: Dictionary in _reward_events:
        if str(event.get("case_name", "")) == case_name:
            count += 1
    return count


func _has_status_event(case_name: String, quest_id: String, old_status: String, new_status: String) -> bool:
    for event: Dictionary in _status_events:
        if (
            str(event.get("case_name", "")) == case_name
            and str(event.get("quest_id", "")) == quest_id
            and str(event.get("old_status", "")) == old_status
            and str(event.get("new_status", "")) == new_status
            and not str(event.get("source", "")).is_empty()
        ):
            return true
    return false


func _next_timestamp() -> String:
    _clock_tick += 1
    return "2026-07-15T00:%02d:%02dZ" % [int(_clock_tick / 60), _clock_tick % 60]


func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _failures.append("could not read JSON fixture: %s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        _failures.append("fixture JSON root is not an object: %s" % path)
        return {}
    return parsed


func _remove_tree(path: String) -> void:
    var absolute := ProjectSettings.globalize_path(path)
    if not DirAccess.dir_exists_absolute(absolute):
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(absolute)
        return
    var directory := DirAccess.open(absolute)
    if directory == null:
        return
    directory.list_dir_begin()
    var name := directory.get_next()
    while not name.is_empty():
        if name != "." and name != "..":
            var child := absolute.path_join(name)
            if directory.current_is_dir():
                _remove_tree(child)
            else:
                DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(absolute)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
