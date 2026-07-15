extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"

class FixtureContentLoader extends RefCounted:
    var definitions: Array
    var story: Dictionary

    func _init(state_definitions: Array, story_document: Dictionary) -> void:
        definitions = state_definitions
        story = story_document

    func get_state_definitions() -> Array:
        return definitions.duplicate(true)

    func get_story(story_id: String) -> Variant:
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


class FailingCommitStoryRunner extends RefCounted:
    var inner: RefCounted
    var fail_next_checkpoint_restore := false
    var last_error: Dictionary = {}

    func _init(value: RefCounted) -> void:
        inner = value

    func get_current_position() -> Dictionary:
        return inner.get_current_position()

    func is_valid_position(story_id: String, node_id: String) -> bool:
        return inner.is_valid_position(story_id, node_id)

    func restore_position(story_id: String, node_id: String, emit_restored_signal: bool = true) -> bool:
        return inner.restore_position(story_id, node_id, emit_restored_signal)

    func create_runtime_checkpoint() -> Dictionary:
        return inner.create_runtime_checkpoint()

    func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
        if fail_next_checkpoint_restore:
            fail_next_checkpoint_restore = false
            last_error = {"code": "TEST_COMMIT_FAILURE", "message": "injected StoryRunner commit failure"}
            return false
        last_error = {}
        return inner.restore_runtime_checkpoint(checkpoint)

    func emit_position_restored() -> void:
        inner.emit_position_restored()


var _failures: Array[String] = []
var _save_events: Array[Dictionary] = []
var _load_events: Array[Dictionary] = []
var _restore_events: Array[Dictionary] = []
var _story_completion_events: Array[Dictionary] = []
var _state_definitions: Array = []
var _story_fixture: Dictionary = {}
var _base_root := ""
var _clock_tick := 0


func _init() -> void:
    var state_document := _read_json(STATE_FIXTURE)
    _story_fixture = _read_json(STORY_FIXTURE)
    if state_document.is_empty() or _story_fixture.is_empty():
        quit(1)
        return
    _state_definitions = state_document["states"]
    _base_root = OS.get_temp_dir().path_join(
        "王者存档测试_%d" % OS.get_process_id()
    ).path_join("含 空格")
    _remove_tree(_base_root)

    _test_manual_round_trip_and_signals()
    _test_backup_and_restore()
    _test_invalid_loads_are_atomic()
    _test_commit_failure_rolls_back_full_runtime()
    _test_write_failure_preserves_main_save()
    _test_slots_listing_and_delete()
    _test_complete_node_restore_uses_dedicated_signal()
    _test_paths_and_version_placeholder()

    _remove_tree(_base_root)
    if _failures.is_empty():
        print("SAVE_MANAGER_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("SAVE_MANAGER_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_manual_round_trip_and_signals() -> void:
    var context := _new_context("round_trip")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    var runner: RefCounted = context["runner"]
    if manager == null:
        return

    _expect(game_state.set_state("test.counter", 7, "debug"), "round trip setup state failed")
    _expect(runner.advance(), "round trip could not reach dialogue node")
    _expect(manager.set_playtime_seconds(42.5), "valid playtime was rejected")
    _expect(manager.set_random_state({"seed": 12345}), "valid random state was rejected")
    var expected_snapshot: Dictionary = game_state.export_snapshot()
    var expected_position: Dictionary = runner.get_current_position()
    var save_result: Dictionary = manager.save("manual_1")
    _expect(save_result.get("ok", false), "manual save failed")
    _expect(_save_events.size() == 1 and _save_events[-1].get("ok", false), "save_completed signal missing")
    var first_document := _read_json(manager.get_save_path("manual_1"))
    _expect(first_document.get("game_version") == "test-version", "injected game version was not saved")
    _expect(first_document.get("development_save") == true, "development save marker missing")

    _expect(game_state.set_state("test.counter", 1, "debug"), "round trip state mutation failed")
    _expect(game_state.set_state("test.note", "live_only", "debug"), "non-persistent mutation failed")
    _expect(runner.advance(), "round trip could not move away from saved story node")
    manager.set_playtime_seconds(99.0)
    manager.set_random_state({"seed": 999})

    var load_result: Dictionary = manager.load("manual_1")
    _expect(load_result.get("ok", false), "manual load failed")
    _expect(_load_events.size() == 1 and _load_events[-1].get("ok", false), "load_completed signal missing")
    _expect(game_state.export_snapshot() == expected_snapshot, "GameState did not round trip exactly")
    _expect(game_state.get_state("test.note") == "", "non-persistent state was saved or entry effects replayed")
    _expect(runner.get_current_position() == expected_position, "StoryRunner position did not restore exactly")
    _expect(is_equal_approx(manager.get_playtime_seconds(), 42.5), "playtime did not restore")
    _expect(manager.get_random_state().get("seed") == 12345, "random seed did not restore")

    var second_save: Dictionary = manager.save("manual_1")
    _expect(second_save.get("ok", false), "manual overwrite failed")
    var second_document := _read_json(manager.get_save_path("manual_1"))
    _expect(first_document.get("created_at") == second_document.get("created_at"), "created_at changed during overwrite")
    _expect(first_document.get("updated_at") != second_document.get("updated_at"), "updated_at did not change during overwrite")


func _test_backup_and_restore() -> void:
    var context := _new_context("backup_restore")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    var runner: RefCounted = context["runner"]
    if manager == null:
        return

    game_state.set_state("test.counter", 3, "debug")
    _expect(manager.save("manual_1").get("ok", false), "first backup source save failed")
    runner.advance()
    game_state.set_state("test.counter", 8, "debug")
    _expect(manager.save("manual_1").get("ok", false), "second backup source save failed")
    _expect(FileAccess.file_exists(manager.get_backup_path("manual_1")), "overwrite did not create backup")
    var backup_document := _read_json(manager.get_backup_path("manual_1"))
    _expect(backup_document.get("game_state", {}).get("test.counter") == 3, "backup does not contain previous state")
    _expect(backup_document.get("current_story_node_id") == "opening", "backup does not contain previous story position")

    runner.advance()
    game_state.set_state("test.counter", 9, "debug")
    _expect(manager.save("manual_1").get("ok", false), "third save could not rotate existing backup")
    backup_document = _read_json(manager.get_backup_path("manual_1"))
    _expect(backup_document.get("game_state", {}).get("test.counter") == 8, "backup rotation did not keep the immediately previous state")
    _expect(backup_document.get("current_story_node_id") == "greeting", "backup rotation kept the wrong story position")

    _expect(_write_text(manager.get_save_path("manual_1"), "{broken"), "could not corrupt main save for recovery test")
    var failed_load: Dictionary = manager.load("manual_1")
    _expect_code(failed_load, SaveManagerClass.SAVE_JSON_INVALID, "corrupt main before backup restore")
    _expect(failed_load.get("backup_available", false), "corrupt main result did not advertise its valid backup")
    var restore_result: Dictionary = manager.restore_backup("manual_1")
    _expect(restore_result.get("ok", false), "valid backup could not be restored")
    _expect(game_state.get_state("test.counter") == 8, "backup restore did not restore GameState")
    _expect(runner.get_current_position().get("node_id") == "greeting", "backup restore did not restore StoryRunner")
    _expect(game_state.get_state("test.note") == "", "backup restore replayed story entry effects")
    var restored_main := _read_json(manager.get_save_path("manual_1"))
    _expect(restored_main == backup_document, "restored main file differs from validated backup")


func _test_invalid_loads_are_atomic() -> void:
    var context := _new_context("invalid_loads")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    var runner: RefCounted = context["runner"]
    if manager == null:
        return

    game_state.set_state("test.counter", 4, "debug")
    _expect(manager.save("manual_1").get("ok", false), "invalid-load source save failed")
    var valid_document := _read_json(manager.get_save_path("manual_1"))

    game_state.set_state("test.counter", 8, "debug")
    game_state.set_state("test.note", "must_survive_failure", "debug")
    runner.resume_from_node("TEST_STORY_MINIMAL", "greeting")
    manager.set_playtime_seconds(88.0)
    manager.set_random_state({"seed": 8080})
    var live_snapshot: Dictionary = game_state.export_snapshot()
    var live_position: Dictionary = runner.get_current_position()

    _write_text(manager.get_save_path("manual_1"), "{invalid")
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_JSON_INVALID, "invalid JSON")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "invalid JSON")

    _write_text(manager.get_save_path("manual_1"), "[]")
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_SCHEMA_INVALID, "non-object JSON")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "non-object JSON")

    var missing_field: Dictionary = valid_document.duplicate(true)
    missing_field.erase("updated_at")
    _write_json(manager.get_save_path("manual_1"), missing_field)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_SCHEMA_INVALID, "missing required field")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "missing required field")

    var invalid_state: Dictionary = valid_document.duplicate(true)
    invalid_state["game_state"]["test.counter"] = "bad"
    _write_json(manager.get_save_path("manual_1"), invalid_state)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_STATE_INVALID, "invalid state snapshot")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "invalid state snapshot")

    var non_object_state: Dictionary = valid_document.duplicate(true)
    non_object_state["game_state"] = []
    _write_json(manager.get_save_path("manual_1"), non_object_state)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_STATE_INVALID, "non-object state snapshot")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "non-object state snapshot")

    var invalid_story: Dictionary = valid_document.duplicate(true)
    invalid_story["current_story_node_id"] = "missing_node"
    _write_json(manager.get_save_path("manual_1"), invalid_story)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_STORY_INVALID, "missing story node")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "missing story node")

    var missing_story: Dictionary = valid_document.duplicate(true)
    missing_story["current_story_id"] = "TEST_STORY_MISSING"
    _write_json(manager.get_save_path("manual_1"), missing_story)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_STORY_INVALID, "missing story")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "missing story")

    var unsupported: Dictionary = valid_document.duplicate(true)
    unsupported["save_version"] = 99
    _write_json(manager.get_save_path("manual_1"), unsupported)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_VERSION_UNSUPPORTED, "unsupported version")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "unsupported version")

    unsupported["save_version"] = 0
    _write_json(manager.get_save_path("manual_1"), unsupported)
    _expect_code(manager.load("manual_1"), SaveManagerClass.SAVE_VERSION_UNSUPPORTED, "zero save version")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "zero save version")

    _expect_code(manager.load("manual_2"), SaveManagerClass.SAVE_NOT_FOUND, "missing save")
    _expect_runtime_unchanged(context, live_snapshot, live_position, "missing save")
    _expect(game_state.get_state("test.note") == "must_survive_failure", "failed load polluted non-persistent state")
    _expect(is_equal_approx(manager.get_playtime_seconds(), 88.0), "failed load changed playtime")
    _expect(manager.get_random_state().get("seed") == 8080, "failed load changed random state")


func _test_commit_failure_rolls_back_full_runtime() -> void:
    var context := _new_context("commit_rollback")
    var source_manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    var runner: RefCounted = context["runner"]
    if source_manager == null:
        return
    game_state.set_state("test.counter", 4, "debug")
    _expect(source_manager.save("manual_1").get("ok", false), "commit-rollback source save failed")

    game_state.set_state("test.counter", 8, "debug")
    game_state.set_state("test.note", "rollback_must_keep_me", "debug")
    runner.resume_from_node("TEST_STORY_MINIMAL", "greeting")
    var expected_snapshot: Dictionary = game_state.export_snapshot()
    var expected_position: Dictionary = runner.get_current_position()

    var failing_runner := FailingCommitStoryRunner.new(runner)
    var manager := SaveManagerClass.new()
    _expect(manager.initialize(
        context["loader"],
        game_state,
        failing_runner,
        source_manager.get_save_root(),
        source_manager.get_backup_root(),
        "test-version",
        Callable(self, "_next_timestamp")
    ), "failing-runner SaveManager initialization failed")
    manager.set_playtime_seconds(88.0)
    manager.set_random_state({"seed": 8080})
    failing_runner.fail_next_checkpoint_restore = true
    var result: Dictionary = manager.load("manual_1")
    _expect_code(result, SaveManagerClass.SAVE_RESTORE_FAILED, "injected commit failure")
    _expect(result.get("rollback_ok", false), "injected commit failure did not report a complete rollback")
    _expect(game_state.export_snapshot() == expected_snapshot, "commit failure polluted persistent GameState")
    _expect(game_state.get_state("test.note") == "rollback_must_keep_me", "commit failure polluted non-persistent GameState")
    _expect(runner.get_current_position() == expected_position, "commit failure changed StoryRunner position")
    _expect(is_equal_approx(manager.get_playtime_seconds(), 88.0), "commit failure changed playtime")
    _expect(manager.get_random_state().get("seed") == 8080, "commit failure changed random state")


func _test_write_failure_preserves_main_save() -> void:
    var context := _new_context("write_failure")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    if manager == null:
        return
    _expect(manager.save("manual_1").get("ok", false), "write-failure source save failed")
    var main_path: String = manager.get_save_path("manual_1")
    var original_text := _read_text(main_path)
    var blocker_dir := "%s.tmp" % main_path
    _expect(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocker_dir)) == OK, "could not create temp-path blocker directory")
    _expect(_write_text(blocker_dir.path_join("blocker.txt"), "block"), "could not populate temp-path blocker")
    game_state.set_state("test.counter", 9, "debug")
    var failed_save: Dictionary = manager.save("manual_1")
    _expect_code(failed_save, SaveManagerClass.SAVE_WRITE_FAILED, "blocked temporary write")
    _expect(_read_text(main_path) == original_text, "failed write changed the existing main save")
    _expect(manager.load("manual_1").get("ok", false), "existing main save became unreadable after write failure")
    _expect(game_state.get_state("test.counter") == 2, "failed write did not preserve prior save contents")


func _test_slots_listing_and_delete() -> void:
    var context := _new_context("slot_listing")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    if manager == null:
        return

    manager.set_playtime_seconds(12.5)
    _expect(manager.save("manual_1").get("ok", false), "manual_1 save failed")
    game_state.set_state("test.counter", 3, "debug")
    _expect(manager.request_auto_save().get("ok", false), "auto save failed")
    game_state.set_state("test.counter", 4, "debug")
    _expect(manager.request_quick_save().get("ok", false), "quick save failed")
    game_state.set_state("test.counter", 5, "debug")
    _expect(manager.save("manual_2").get("ok", false), "manual_2 save failed")
    game_state.set_state("test.counter", 6, "debug")
    _expect(manager.save("manual_2").get("ok", false), "manual_2 overwrite failed")
    game_state.set_state("test.counter", 7, "debug")
    _expect(manager.save("manual_3").get("ok", false), "manual_3 save failed")

    for slot_id: String in ["manual_1", "manual_2", "manual_3", "auto", "quick"]:
        _expect(manager.has_save(slot_id), "slot was not isolated: %s" % slot_id)
    var expected_values := {
        "manual_1": 2,
        "manual_2": 6,
        "manual_3": 7,
        "auto": 3,
        "quick": 4,
    }
    for slot_id: String in expected_values:
        var document := _read_json(manager.get_save_path(slot_id))
        _expect(document.get("slot_id") == slot_id, "slot document ID is wrong: %s" % slot_id)
        _expect(document.get("game_state", {}).get("test.counter") == expected_values[slot_id], "slot contents were overwritten: %s" % slot_id)
    var list_result: Dictionary = manager.list_saves()
    _expect(list_result.get("ok", false), "list_saves failed")
    var saves: Array = list_result.get("saves", [])
    _expect(saves.size() == 5, "list_saves did not return all five slots")
    var listed_slots: Array[String] = []
    for metadata: Variant in saves:
        listed_slots.append(str(metadata.get("slot_id", "")))
        _expect(metadata.get("valid", false), "list_saves marked a valid slot invalid")
        _expect(not metadata.has("game_state"), "list_saves leaked full save payload")
        if metadata.get("slot_id") == "manual_1":
            _expect(metadata.get("save_version") == 1, "list metadata save_version is wrong")
            _expect(metadata.get("game_version") == "test-version", "list metadata game_version is wrong")
            _expect(not str(metadata.get("created_at", "")).is_empty(), "list metadata created_at is missing")
            _expect(not str(metadata.get("updated_at", "")).is_empty(), "list metadata updated_at is missing")
            _expect(is_equal_approx(float(metadata.get("playtime_seconds", -1.0)), 12.5), "list metadata playtime is wrong")
            _expect(metadata.get("current_story_id") == "TEST_STORY_MINIMAL", "list metadata story ID is wrong")
            _expect(metadata.get("current_story_node_id") == "opening", "list metadata story node is wrong")
    _expect(listed_slots == ["manual_1", "manual_2", "manual_3", "auto", "quick"], "list_saves slot order or IDs are wrong")

    _expect(manager.delete_save("manual_2").get("ok", false), "delete_save failed")
    _expect(not manager.has_save("manual_2"), "deleted save still exists")
    _expect(not FileAccess.file_exists(manager.get_backup_path("manual_2")), "delete_save left the slot backup behind")
    _expect(not FileAccess.file_exists("%s.tmp" % manager.get_save_path("manual_2")), "delete_save left the slot temp file behind")
    _expect(manager.has_save("auto") and manager.has_save("quick"), "deleting manual slot affected reserved slots")
    _expect_code(manager.delete_save("manual_2"), SaveManagerClass.SAVE_NOT_FOUND, "delete missing save")
    _expect_code(manager.save("../escape"), SaveManagerClass.SAVE_SCHEMA_INVALID, "invalid slot ID")


func _test_complete_node_restore_uses_dedicated_signal() -> void:
    var context := _new_context("complete_restore")
    var manager: RefCounted = context["manager"]
    var runner: RefCounted = context["runner"]
    if manager == null:
        return
    _expect(runner.resume_from_node("TEST_STORY_MINIMAL", "finished"), "could not reach complete node for save")
    _story_completion_events.clear()
    _restore_events.clear()
    _expect(manager.save("manual_1").get("ok", false), "complete-node save failed")
    _expect(runner.resume_from_node("TEST_STORY_MINIMAL", "opening"), "could not leave complete node")
    _story_completion_events.clear()
    var result: Dictionary = manager.load("manual_1")
    _expect(result.get("ok", false), "complete-node load failed")
    _expect(runner.get_current_position().get("node_id") == "finished", "complete-node position was not restored")
    _expect(runner.get_current_position().get("completed") == true, "complete-node completion state was not restored")
    _expect(_story_completion_events.is_empty(), "loading a complete node replayed story_completed")
    _expect(_restore_events.size() == 1, "loading a complete node did not emit the dedicated restore signal")


func _test_paths_and_version_placeholder() -> void:
    var context := _new_context("中文 用户路径")
    var manager: RefCounted = context["manager"]
    var game_state: RefCounted = context["game_state"]
    if manager == null:
        return
    _expect(manager.save("manual_1").get("ok", false), "save failed in Chinese Windows path")
    _expect(FileAccess.file_exists(manager.get_save_path("manual_1")), "Chinese-path save file was not created")
    _expect(manager.get_save_path("manual_1").contains("中文 用户路径"), "Chinese path was not used")
    game_state.set_state("test.counter", 9, "debug")
    _expect(manager.load("manual_1").get("ok", false), "load failed in Chinese Windows path")
    _expect(game_state.get_state("test.counter") == 2, "Chinese-path load did not restore state")
    _expect(not manager.set_playtime_seconds(-1.0), "negative playtime was accepted")
    _expect(not manager.set_random_state({}), "random state without seed was accepted")
    _expect(not manager.set_random_state({"seed": 1.5}), "non-integral random seed was accepted")

    var migration: Dictionary = manager.migrate_save({}, 999)
    _expect_code(migration, SaveManagerClass.SAVE_VERSION_UNSUPPORTED, "migration placeholder")
    var current_migration: Dictionary = manager.migrate_save({"slot_id": "manual_1"}, SaveManagerClass.CURRENT_SAVE_VERSION)
    _expect(current_migration.get("ok", false), "current-version migration pass-through failed")

    var user_root := ProjectSettings.globalize_path("user://").replace("\\", "/").to_lower()
    var install_root := ProjectSettings.globalize_path("res://").replace("\\", "/").to_lower()
    _expect(not user_root.begins_with(install_root), "user:// resolves inside the installation directory")
    _expect(ProjectSettings.get_setting("application/config/custom_user_dir_name") == "WangZheTextRPG", "custom Windows user directory is not configured")

    var forbidden := SaveManagerClass.new()
    var initialized: bool = forbidden.initialize(
        context["loader"], context["game_state"], context["runner"],
        "res://save_manager_forbidden", "res://backup_manager_forbidden"
    )
    _expect(not initialized, "SaveManager accepted installation-directory paths")
    _expect(str(forbidden.last_result.get("code", "")) == SaveManagerClass.SAVE_WRITE_FAILED, "installation-path rejection code is wrong")

    var relative := SaveManagerClass.new()
    initialized = relative.initialize(
        context["loader"], context["game_state"], context["runner"],
        "saves", "backups"
    )
    _expect(not initialized, "SaveManager accepted relative storage paths")
    _expect(str(relative.last_result.get("code", "")) == SaveManagerClass.SAVE_WRITE_FAILED, "relative-path rejection code is wrong")

    var uninitialized := SaveManagerClass.new()
    _expect_code(uninitialized.save("manual_1"), SaveManagerClass.SAVE_NOT_INITIALIZED, "save before initialize")
    _expect_code(uninitialized.load("manual_1"), SaveManagerClass.SAVE_NOT_INITIALIZED, "load before initialize")
    _expect_code(uninitialized.list_saves(), SaveManagerClass.SAVE_NOT_INITIALIZED, "list before initialize")

    initialized = manager.initialize(
        context["loader"], context["game_state"], context["runner"],
        "res://failed_reinitialize", "res://failed_reinitialize_backup"
    )
    _expect(not initialized, "failed reinitialization unexpectedly succeeded")
    _expect_code(manager.save("manual_1"), SaveManagerClass.SAVE_NOT_INITIALIZED, "save after failed reinitialize")


func _new_context(case_name: String) -> Dictionary:
    _save_events.clear()
    _load_events.clear()
    _restore_events.clear()
    _story_completion_events.clear()
    var case_root := _base_root.path_join(case_name)
    _remove_tree(case_root)
    var loader := FixtureContentLoader.new(_state_definitions, _story_fixture)
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState initialization failed for %s" % case_name)
        return {"manager": null}
    var runner := StoryRunnerClass.new()
    if not runner.initialize(loader, game_state) or not runner.start_story("TEST_STORY_MINIMAL"):
        _failures.append("StoryRunner initialization failed for %s" % case_name)
        return {"manager": null}
    runner.story_position_restored.connect(_on_story_position_restored)
    runner.story_completed.connect(_on_story_completed)
    var manager := SaveManagerClass.new()
    manager.save_completed.connect(_on_save_completed)
    manager.load_completed.connect(_on_load_completed)
    var initialized: bool = manager.initialize(
        loader,
        game_state,
        runner,
        case_root.path_join("saves"),
        case_root.path_join("backups"),
        "test-version",
        Callable(self, "_next_timestamp")
    )
    if not initialized:
        _failures.append("SaveManager initialization failed for %s: %s" % [case_name, str(manager.last_result)])
        return {"manager": null}
    return {
        "manager": manager,
        "game_state": game_state,
        "runner": runner,
        "loader": loader,
    }


func _expect_runtime_unchanged(context: Dictionary, snapshot: Dictionary, position: Dictionary, label: String) -> void:
    var game_state: RefCounted = context["game_state"]
    var runner: RefCounted = context["runner"]
    _expect(game_state.export_snapshot() == snapshot, "%s polluted persistent state" % label)
    _expect(game_state.get_state("test.note") == "must_survive_failure", "%s polluted non-persistent state" % label)
    _expect(runner.get_current_position() == position, "%s changed StoryRunner position" % label)


func _next_timestamp() -> String:
    _clock_tick += 1
    return "2026-07-15T00:%02d:%02dZ" % [int(_clock_tick / 60), _clock_tick % 60]


func _on_save_completed(result: Dictionary) -> void:
    _save_events.append(result)


func _on_load_completed(result: Dictionary) -> void:
    _load_events.append(result)


func _on_story_position_restored(position: Dictionary, presentation: Dictionary) -> void:
    _restore_events.append({"position": position, "presentation": presentation})


func _on_story_completed(result: Dictionary) -> void:
    _story_completion_events.append(result)


func _expect_code(result: Dictionary, expected: String, label: String) -> void:
    _expect(not bool(result.get("ok", true)), "%s unexpectedly succeeded" % label)
    _expect(str(result.get("code", "")) == expected, "%s returned %s instead of %s" % [label, result.get("code", ""), expected])


func _read_json(path: String) -> Dictionary:
    var text := _read_text(path)
    if text.is_empty():
        _failures.append("could not read JSON fixture/file: %s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(text)
    if not parsed is Dictionary:
        _failures.append("JSON root is not an object: %s" % path)
        return {}
    return parsed


func _read_text(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    var text := file.get_as_text()
    file.close()
    return text


func _write_json(path: String, document: Dictionary) -> bool:
    return _write_text(path, JSON.stringify(document, "  ", false))


func _write_text(path: String, text: String) -> bool:
    var parent := path.get_base_dir()
    var parent_absolute := ProjectSettings.globalize_path(parent)
    if not DirAccess.dir_exists_absolute(parent_absolute):
        if DirAccess.make_dir_recursive_absolute(parent_absolute) != OK:
            return false
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(text)
    file.flush()
    var error := file.get_error()
    file.close()
    return error == OK


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
