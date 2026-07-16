extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")

const ITEM_FIXTURE := "res://content/tests/fixtures/inventory_manager/items.json"
const INVENTORY_STATE_FIXTURE := "res://content/tests/fixtures/inventory_manager/state_registry.json"
const QUEST_FIXTURE := "res://content/tests/fixtures/quest_manager/quests.json"
const QUEST_STATE_FIXTURE := "res://content/tests/fixtures/quest_manager/state_registry.json"
const BASE_STATE_FIXTURE := "res://content/tests/fixtures/game_state/state_registry.json"
const STORY_FIXTURE := "res://content/tests/fixtures/story_runner/minimal_story.json"

const PARALLEL_QUEST := "TEST_QUEST_PARALLEL"
const FIELD_TONIC := "TEST_ITEM_FIELD_TONIC"
const MATERIAL := "TEST_ITEM_MATERIAL_BUNDLE"
const CRITICAL_REWARD := "TEST_ITEM_CRITICAL_REWARD"
const ONE_HANDED_SWORD := "TEST_ITEM_ONE_HANDED_SWORD"
const BODY_ARMOR := "TEST_ITEM_BODY_ARMOR"


class FixtureContentLoader extends RefCounted:
    var state_definitions: Array
    var item_definitions: Array
    var quest_definitions: Array
    var story: Dictionary

    func _init(states: Array, items: Array, quests: Array, story_document: Dictionary) -> void:
        state_definitions = states
        item_definitions = items
        quest_definitions = quests
        story = story_document

    func get_state_definitions() -> Array:
        return state_definitions.duplicate(true)

    func get_item_definitions() -> Array:
        return item_definitions.duplicate(true)

    func get_quest_definitions() -> Array:
        return quest_definitions.duplicate(true)

    func get_quest_dependencies() -> Dictionary:
        return {"schema_version": "1.0.0", "quests": []}

    func get_story(story_id: String) -> Variant:
        if story_id != str(story.get("quest_id", "")):
            return null
        return story.duplicate(true)


class FailingCommitInventoryManager extends RefCounted:
    var inner: RefCounted
    var fail_next_checkpoint_restore := false
    var last_error: Dictionary = {}

    func _init(value: RefCounted) -> void:
        inner = value

    func export_snapshot() -> Dictionary:
        return inner.export_snapshot()

    func get_capacity() -> int:
        return inner.get_capacity()

    func validate_snapshot(snapshot: Dictionary) -> bool:
        var valid: bool = inner.validate_snapshot(snapshot)
        last_error = {} if valid else inner.last_error.duplicate(true)
        return valid

    func restore_snapshot(snapshot: Dictionary, source: String = "save_restore") -> bool:
        var restored: bool = inner.restore_snapshot(snapshot, source)
        last_error = {} if restored else inner.last_error.duplicate(true)
        return restored

    func create_runtime_checkpoint() -> Dictionary:
        return inner.create_runtime_checkpoint()

    func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
        if fail_next_checkpoint_restore:
            fail_next_checkpoint_restore = false
            last_error = {"code": "TEST_INVENTORY_COMMIT_FAILURE", "message": "injected inventory checkpoint failure"}
            return false
        var restored: bool = inner.restore_runtime_checkpoint(checkpoint)
        last_error = {} if restored else inner.last_error.duplicate(true)
        return restored

    func emit_changes_from_checkpoint(checkpoint: Dictionary, source: String = "save_restore") -> bool:
        return inner.emit_changes_from_checkpoint(checkpoint, source)


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
        var restored: bool = inner.restore_position(story_id, node_id, emit_restored_signal)
        last_error = {} if restored else inner.last_error.duplicate(true)
        return restored

    func create_runtime_checkpoint() -> Dictionary:
        return inner.create_runtime_checkpoint()

    func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:
        if fail_next_checkpoint_restore:
            fail_next_checkpoint_restore = false
            last_error = {"code": "TEST_STORY_COMMIT_FAILURE", "message": "injected story checkpoint failure"}
            return false
        var restored: bool = inner.restore_runtime_checkpoint(checkpoint)
        last_error = {} if restored else inner.last_error.duplicate(true)
        return restored

    func emit_position_restored() -> void:
        inner.emit_position_restored()


var _failures: Array[String] = []
var _quest_reward_events: Array[Dictionary] = []
var _inventory_reward_results: Array[Dictionary] = []
var _state_definitions: Array = []
var _item_definitions: Array = []
var _quest_definitions: Array = []
var _story_fixture: Dictionary = {}
var _base_root := ""
var _clock_tick := 0


func _init() -> void:
    var item_document := _read_json(ITEM_FIXTURE)
    var inventory_state_document := _read_json(INVENTORY_STATE_FIXTURE)
    var quest_document := _read_json(QUEST_FIXTURE)
    var quest_state_document := _read_json(QUEST_STATE_FIXTURE)
    var base_state_document := _read_json(BASE_STATE_FIXTURE)
    _story_fixture = _read_json(STORY_FIXTURE)
    if (
        item_document.is_empty()
        or inventory_state_document.is_empty()
        or quest_document.is_empty()
        or quest_state_document.is_empty()
        or base_state_document.is_empty()
        or _story_fixture.is_empty()
    ):
        quit(1)
        return
    _item_definitions = item_document.get("items", [])
    _quest_definitions = quest_document.get("quests", [])
    _state_definitions = _merge_state_definitions([
        inventory_state_document.get("states", []),
        quest_state_document.get("states", []),
        base_state_document.get("states", []),
    ])
    if _item_definitions.is_empty() or _quest_definitions.is_empty() or _state_definitions.is_empty():
        _failures.append("integration fixtures are incomplete")
        quit(1)
        return
    _base_root = OS.get_temp_dir().path_join("inventory_quest_save_tests_%d" % OS.get_process_id())
    _remove_tree(_base_root)

    _test_qualified_has_no_reward_and_completed_is_idempotent()
    _test_save_round_trip_and_invalid_inventory_are_atomic()
    _test_commit_failures_roll_back_all_runtime()

    _remove_tree(_base_root)
    if _failures.is_empty():
        print("INVENTORY_QUEST_SAVE_INTEGRATION_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("INVENTORY_QUEST_SAVE_INTEGRATION_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_qualified_has_no_reward_and_completed_is_idempotent() -> void:
    var context := _new_context("reward_idempotency", 3)
    if context.is_empty():
        return
    var quest_manager: RefCounted = context["quest_manager"]
    var inventory: RefCounted = context["inventory"]
    _expect_ok(quest_manager.activate_quest(PARALLEL_QUEST), "reward quest activation")
    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true}), "reward objective A")
    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true}), "reward objective B")
    _expect_status(quest_manager, "qualified", "two-of-three reward boundary")
    _expect(_quest_reward_count("reward_idempotency") == 0, "qualified quest emitted a reward")
    _expect_quantity(inventory, CRITICAL_REWARD, "all", 0, "qualified quest reward")

    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true}), "reward objective C")
    _expect_status(quest_manager, "completed", "three-of-three reward boundary")
    _expect(_quest_reward_count("reward_idempotency") == 1, "completed quest did not emit exactly one reward")
    _expect(_all_reward_routes_succeeded("reward_idempotency"), "InventoryManager rejected the completed quest reward")
    _expect_quantity(inventory, CRITICAL_REWARD, "all", 1, "completed quest reward")

    for call_index: int in range(2):
        var repeat_result: Dictionary = quest_manager.complete_quest(PARALLEL_QUEST)
        _expect_ok(repeat_result, "repeat quest completion %d" % call_index)
        _expect(not bool(repeat_result.get("changed", true)), "repeat completion %d changed quest state" % call_index)
        _expect(not bool(repeat_result.get("reward_emitted", true)), "repeat completion %d reported another reward" % call_index)
    _expect(_quest_reward_count("reward_idempotency") == 1, "repeat quest completion emitted duplicate rewards")
    _expect_quantity(inventory, CRITICAL_REWARD, "all", 1, "idempotent quest reward")


func _test_save_round_trip_and_invalid_inventory_are_atomic() -> void:
    var context := _new_context("save_round_trip", 4, true)
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var quest_manager: RefCounted = context["quest_manager"]
    var inventory: RefCounted = context["inventory"]
    var runner: RefCounted = context["runner"]
    var save_manager: RefCounted = context["save_manager"]

    _expect_ok(inventory.add_item(ONE_HANDED_SWORD, 1), "save equipment setup")
    _expect_ok(inventory.equip_item(ONE_HANDED_SWORD, "weapon"), "save equipped state setup")
    _expect_ok(inventory.add_item(MATERIAL, 7), "save stack setup")
    _expect_ok(inventory.add_item(FIELD_TONIC, 2), "save consumable setup")
    _expect_ok(inventory.use_item(FIELD_TONIC, "field"), "save consumable use setup")
    var expected_health_after_use := int(game_state.get_state("test.inventory.health"))
    while inventory.get_used_slots() < inventory.get_capacity():
        var fill_result: Dictionary = inventory.add_item(BODY_ARMOR, 1)
        if not bool(fill_result.get("ok", false)):
            _failures.append("could not fill backpack for custody save setup: %s" % str(fill_result))
            break

    _expect_ok(quest_manager.activate_quest(PARALLEL_QUEST), "save quest activation")
    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_a", {"value": true}), "save quest objective A")
    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_b", {"value": true}), "save quest objective B")
    _expect_status(quest_manager, "qualified", "save qualified setup")
    _expect(_quest_reward_count("save_round_trip") == 0, "qualified save setup emitted a reward")
    _expect_ok(quest_manager.update_objective(PARALLEL_QUEST, "commission_c", {"value": true}), "save quest objective C")
    _expect_status(quest_manager, "completed", "save completed setup")
    _expect_quantity(inventory, CRITICAL_REWARD, "custody", 1, "completed reward in custody before save")

    var expected_inventory: Dictionary = inventory.export_snapshot()
    var expected_state: Dictionary = game_state.export_snapshot()
    var expected_position: Dictionary = runner.get_current_position()
    var reward_events_before := _quest_reward_count("save_round_trip")
    _expect_ok(save_manager.save("manual_1"), "inventory round-trip save")
    var saved_document := _read_json(save_manager.get_save_path("manual_1"))
    var saved_inventory: Variant = saved_document.get("inventory_state")
    _expect(saved_inventory is Dictionary, "save file did not contain an InventoryManager snapshot object")
    if saved_inventory is Dictionary:
        _expect(inventory.validate_snapshot(saved_inventory), "save file contained an invalid InventoryManager snapshot")
        var normalized_expected: Variant = JSON.parse_string(JSON.stringify(expected_inventory))
        _expect(saved_inventory == normalized_expected, "save file InventoryManager snapshot differed after JSON normalization")

    _expect_ok(inventory.reset_inventory(), "inventory mutation before load")
    _expect(game_state.reset_all_states("system"), "GameState mutation before inventory load")
    _expect(runner.advance(), "StoryRunner mutation before inventory load")
    _expect_ok(save_manager.load("manual_1"), "inventory round-trip load")
    _expect(inventory.export_snapshot() == expected_inventory, "InventoryManager did not round trip exactly")
    _expect(game_state.export_snapshot() == expected_state, "GameState did not round trip with InventoryManager")
    _expect(runner.get_current_position() == expected_position, "StoryRunner did not round trip with InventoryManager")
    _expect_status(quest_manager, "completed", "completed quest after inventory load")
    _expect(_quest_reward_count("save_round_trip") == reward_events_before, "completed quest load re-emitted its reward")
    _expect_quantity(inventory, MATERIAL, "backpack", 7, "saved stack after load")
    _expect_quantity(inventory, FIELD_TONIC, "backpack", 1, "saved consumable remainder after load")
    _expect(
        int(game_state.get_state("test.inventory.health")) == expected_health_after_use,
        "consumable GameState effect did not round trip",
    )
    _expect(_equipped_item(inventory, "weapon") == ONE_HANDED_SWORD, "saved equipment was not restored")
    _expect_quantity(inventory, CRITICAL_REWARD, "custody", 1, "saved custody after load")

    var stable_inventory: Dictionary = inventory.export_snapshot()
    var stable_state: Dictionary = game_state.export_snapshot()
    var stable_position: Dictionary = runner.get_current_position()
    var stable_inventory_error: Dictionary = inventory.last_error.duplicate(true)
    var live_inventory_errors: Array = []
    var inventory_error_callback := func(error: Dictionary) -> void:
        live_inventory_errors.append(error.duplicate(true))
    inventory.inventory_error.connect(inventory_error_callback)
    var invalid_document := saved_document.duplicate(true)
    invalid_document["inventory_state"] = {
        "snapshot_version": 1,
        "capacity": inventory.get_capacity(),
        "backpack": [{"item_id": MATERIAL, "quantity": -1}],
        "quest_items": [],
        "custody": [],
        "equipment": {
            "weapon": null,
            "off_hand": null,
            "head": null,
            "body": null,
            "accessory_1": null,
            "accessory_2": null,
        },
    }
    _expect(_write_json(save_manager.get_save_path("manual_1"), invalid_document), "could not write invalid inventory save fixture")
    var failed_load: Dictionary = save_manager.load("manual_1")
    _expect_failure(failed_load, "invalid inventory snapshot load")
    _expect(
        str(failed_load.get("code", "")) == SaveManagerClass.SAVE_INVENTORY_INVALID,
        "invalid inventory snapshot returned %s instead of SAVE_INVENTORY_INVALID" % failed_load.get("code", ""),
    )
    _expect(inventory.export_snapshot() == stable_inventory, "invalid inventory load polluted InventoryManager")
    _expect(inventory.last_error == stable_inventory_error, "invalid inventory load polluted InventoryManager.last_error")
    _expect(live_inventory_errors.is_empty(), "invalid inventory load emitted a live InventoryManager error")
    _expect(game_state.export_snapshot() == stable_state, "invalid inventory load polluted GameState")
    _expect(runner.get_current_position() == stable_position, "invalid inventory load changed StoryRunner")
    _expect(_quest_reward_count("save_round_trip") == reward_events_before, "invalid inventory load emitted a quest reward")
    inventory.inventory_error.disconnect(inventory_error_callback)


func _test_commit_failures_roll_back_all_runtime() -> void:
    _exercise_commit_failure("inventory")
    _exercise_commit_failure("story")


func _exercise_commit_failure(failure_target: String) -> void:
    var case_name := "commit_failure_%s" % failure_target
    var context := _new_context(case_name, 4, true, failure_target)
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var inventory: RefCounted = context["inventory"]
    var runner: RefCounted = context["runner"]
    var save_manager: RefCounted = context["save_manager"]

    _expect(game_state.set_state("test.counter", 7, "debug"), "%s target GameState setup failed" % failure_target)
    _expect_ok(inventory.add_item(MATERIAL, 3), "%s target inventory setup" % failure_target)
    _expect(runner.advance(), "%s target story setup failed" % failure_target)
    _expect(save_manager.set_playtime_seconds(12.5), "%s target playtime setup failed" % failure_target)
    _expect(save_manager.set_random_state({"seed": 12345}), "%s target random setup failed" % failure_target)
    _expect_ok(save_manager.save("manual_2"), "%s target save" % failure_target)

    _expect(game_state.set_state("test.counter", 1, "debug"), "%s live GameState mutation failed" % failure_target)
    _expect_ok(inventory.add_item(BODY_ARMOR, 1), "%s live inventory mutation" % failure_target)
    _expect(runner.advance(), "%s live story mutation failed" % failure_target)
    _expect(save_manager.set_playtime_seconds(98.75), "%s live playtime mutation failed" % failure_target)
    _expect(save_manager.set_random_state({"seed": 98765}), "%s live random mutation failed" % failure_target)

    var live_state: Dictionary = game_state.create_runtime_checkpoint()
    var live_inventory: Dictionary = inventory.create_runtime_checkpoint()
    var live_story: Dictionary = runner.create_runtime_checkpoint()
    var live_playtime: float = float(save_manager.get_playtime_seconds())
    var live_random: Dictionary = save_manager.get_random_state()
    if failure_target == "inventory":
        context["save_inventory_adapter"].set("fail_next_checkpoint_restore", true)
    else:
        context["save_story_adapter"].set("fail_next_checkpoint_restore", true)

    var load_result: Dictionary = save_manager.load("manual_2")
    _expect_failure(load_result, "%s checkpoint commit failure" % failure_target)
    _expect(
        str(load_result.get("code", "")) == SaveManagerClass.SAVE_RESTORE_FAILED,
        "%s checkpoint failure returned %s instead of SAVE_RESTORE_FAILED" % [failure_target, load_result.get("code", "")],
    )
    _expect(bool(load_result.get("rollback_ok", false)), "%s checkpoint failure reported rollback failure" % failure_target)
    _expect(game_state.create_runtime_checkpoint() == live_state, "%s checkpoint failure did not roll back GameState" % failure_target)
    _expect(inventory.create_runtime_checkpoint() == live_inventory, "%s checkpoint failure did not roll back InventoryManager" % failure_target)
    _expect(runner.create_runtime_checkpoint() == live_story, "%s checkpoint failure did not roll back StoryRunner" % failure_target)
    _expect(is_equal_approx(save_manager.get_playtime_seconds(), live_playtime), "%s checkpoint failure changed playtime" % failure_target)
    _expect(save_manager.get_random_state() == live_random, "%s checkpoint failure changed random state" % failure_target)


func _new_context(
    case_name: String,
    capacity: int,
    initialize_save_manager: bool = false,
    failure_target: String = "",
) -> Dictionary:
    var loader := FixtureContentLoader.new(_state_definitions, _item_definitions, _quest_definitions, _story_fixture)
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState initialization failed for %s: %s" % [case_name, str(game_state.last_error)])
        return {}
    var inventory := InventoryManagerClass.new()
    if not inventory.initialize(loader, game_state, capacity):
        _failures.append("InventoryManager initialization failed for %s: %s" % [case_name, str(inventory.last_error)])
        return {}
    var quest_manager := QuestManagerClass.new()
    if not quest_manager.initialize(loader, game_state):
        _failures.append("QuestManager initialization failed for %s: %s" % [case_name, str(quest_manager.last_error)])
        return {}
    quest_manager.quest_reward_ready.connect(Callable(self, "_on_quest_reward").bind(inventory, case_name))
    var runner := StoryRunnerClass.new()
    if not runner.initialize(loader, game_state, quest_manager) or not runner.start_story("TEST_STORY_MINIMAL"):
        _failures.append("StoryRunner initialization failed for %s: %s" % [case_name, str(runner.last_error)])
        return {}
    var context := {
        "loader": loader,
        "game_state": game_state,
        "inventory": inventory,
        "quest_manager": quest_manager,
        "runner": runner,
    }
    if initialize_save_manager:
        var case_root := _base_root.path_join(case_name)
        _remove_tree(case_root)
        var save_manager := SaveManagerClass.new()
        var save_inventory_adapter: RefCounted = inventory
        var save_story_adapter: RefCounted = runner
        if failure_target == "inventory":
            save_inventory_adapter = FailingCommitInventoryManager.new(inventory)
        elif failure_target == "story":
            save_story_adapter = FailingCommitStoryRunner.new(runner)
        if not save_manager.initialize(
            loader,
            game_state,
            save_story_adapter,
            case_root.path_join("saves"),
            case_root.path_join("backups"),
            "inventory-test-version",
            Callable(self, "_next_timestamp"),
            save_inventory_adapter,
        ):
            _failures.append("SaveManager initialization failed for %s: %s" % [case_name, str(save_manager.last_result)])
            return {}
        context["save_manager"] = save_manager
        context["save_inventory_adapter"] = save_inventory_adapter
        context["save_story_adapter"] = save_story_adapter
    return context


func _merge_state_definitions(groups: Array) -> Array:
    var merged: Array = []
    var known := {}
    for raw_group: Variant in groups:
        if not raw_group is Array:
            continue
        for raw_definition: Variant in raw_group:
            if not raw_definition is Dictionary:
                continue
            var key := str(raw_definition.get("key", ""))
            if not key.is_empty() and not known.has(key):
                merged.append(raw_definition.duplicate(true))
                known[key] = true
    return merged


func _on_quest_reward(result: Dictionary, inventory: RefCounted, case_name: String) -> void:
    _quest_reward_events.append({"case_name": case_name, "result": result.duplicate(true)})
    var apply_result: Dictionary = inventory.apply_quest_reward(result)
    _inventory_reward_results.append({"case_name": case_name, "result": apply_result.duplicate(true)})


func _quest_reward_count(case_name: String) -> int:
    var count := 0
    for event: Dictionary in _quest_reward_events:
        if str(event.get("case_name", "")) == case_name:
            count += 1
    return count


func _all_reward_routes_succeeded(case_name: String) -> bool:
    var found := false
    for event: Dictionary in _inventory_reward_results:
        if str(event.get("case_name", "")) != case_name:
            continue
        found = true
        if not bool(event.get("result", {}).get("ok", false)):
            return false
    return found


func _expect_status(manager: RefCounted, expected: String, label: String) -> void:
    var result: Dictionary = manager.get_quest_status(PARALLEL_QUEST)
    _expect_ok(result, "%s status query" % label)
    _expect(str(result.get("status", "")) == expected, "%s status was %s instead of %s" % [label, result.get("status", ""), expected])


func _quantity(manager: RefCounted, item_id: String, scope: String) -> int:
    var result: Dictionary = manager.get_item_quantity(item_id, scope)
    _expect_ok(result, "quantity query for %s in %s" % [item_id, scope])
    return int(result.get("quantity", -1))


func _expect_quantity(manager: RefCounted, item_id: String, scope: String, expected: int, label: String) -> void:
    var actual := _quantity(manager, item_id, scope)
    _expect(actual == expected, "%s quantity was %d instead of %d" % [label, actual, expected])


func _equipped_item(manager: RefCounted, slot: String) -> String:
    var result: Dictionary = manager.get_equipment()
    _expect_ok(result, "equipment query")
    var value: Variant = result.get("equipment", {}).get(slot, null)
    if value is Dictionary:
        return str(value.get("item_id", ""))
    return "" if value == null else str(value)


func _next_timestamp() -> String:
    _clock_tick += 1
    return "2026-07-15T00:%02d:%02dZ" % [int(_clock_tick / 60), _clock_tick % 60]


func _read_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        _failures.append("could not read JSON fixture/file: %s" % path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        _failures.append("JSON root is not an object: %s" % path)
        return {}
    return parsed


func _write_json(path: String, document: Dictionary) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(document, "  ", false))
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


func _expect_ok(result: Dictionary, label: String) -> void:
    _expect(bool(result.get("ok", false)), "%s failed: %s" % [label, str(result)])


func _expect_failure(result: Dictionary, label: String) -> void:
    _expect(not bool(result.get("ok", true)), "%s unexpectedly succeeded" % label)
    _expect(not str(result.get("code", "")).is_empty(), "%s did not return an error code" % label)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
