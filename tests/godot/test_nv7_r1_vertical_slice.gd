extends SceneTree

const ContentLoaderClass = preload("res://src/core/content_loader.gd")
const GameStateClass = preload("res://src/core/game_state.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")
const RelationshipManagerClass = preload("res://src/core/relationship_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const CombatRunnerClass = preload("res://src/core/combat_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")

var _failures: Array[String] = []
var _last_choice: Dictionary = {}
var _loader := ContentLoaderClass.new()
var _state := GameStateClass.new()
var _inventory := InventoryManagerClass.new()
var _quests := QuestManagerClass.new()
var _relationships := RelationshipManagerClass.new()
var _story := StoryRunnerClass.new()
var _combat := CombatRunnerClass.new()
var _save := SaveManagerClass.new()
var _save_root := ""
var _backup_root := ""
var _combat_count := 0
var _reward_count := 0
var _route_variant := 0
var _defeat_mode := false
var _hanshi_attempted := false
var _verify_save_round_trip := true


func _init() -> void:
    _save_root = "user://nv7_r1_vertical_slice_%d/saves" % OS.get_process_id()
    _backup_root = "user://nv7_r1_vertical_slice_%d/backups" % OS.get_process_id()
    if not _initialize_services():
        _finish()
        return
    _run_primary_route()
    _verify_third_commission_completion()
    _verify_repeated_restore_is_idempotent()
    _verify_r2_entry_snapshot()
    _verify_new_game_reset()
    _route_variant = 1
    _defeat_mode = true
    _hanshi_attempted = false
    _verify_save_round_trip = false
    _combat_count = 0
    _reward_count = 0
    _run_primary_route()
    _verify_new_game_reset()
    _route_variant = 2
    _defeat_mode = false
    _hanshi_attempted = false
    _combat_count = 0
    _reward_count = 0
    _run_primary_route()
    _finish()


func _initialize_services() -> bool:
    if not _loader.load_content("res://content"):
        _failures.append("ContentLoader: %s" % _loader.last_error)
        return false
    if _loader.get_default_story_id() != "NV_MAIN_001":
        _failures.append("formal default story is not NV_MAIN_001")
    if not _state.initialize_from_content_loader(_loader):
        _failures.append("GameState: %s" % _state.last_error)
        return false
    if not _inventory.initialize(_loader, _state):
        _failures.append("InventoryManager: %s" % _inventory.last_error)
        return false
    if not _quests.initialize(_loader, _state):
        _failures.append("QuestManager: %s" % _quests.last_error)
        return false
    if not _relationships.initialize(_loader, _state):
        _failures.append("RelationshipManager: %s" % _relationships.last_error)
        return false
    if not bool(_quests.bind_relationship_manager(_relationships).get("ok", false)):
        _failures.append("QuestManager relationship binding failed")
        return false
    if not _story.initialize(_loader, _state, _quests):
        _failures.append("StoryRunner: %s" % _story.last_error)
        return false
    if not bool(_story.bind_relationship_manager(_relationships).get("ok", false)):
        _failures.append("StoryRunner relationship binding failed")
        return false
    _story.choice_presented.connect(_on_choice_presented)
    if not _save.initialize(_loader, _state, _story, _save_root, _backup_root, "0.1.0", Callable(), _inventory):
        _failures.append("SaveManager: %s" % _save.last_result)
        return false
    if not _combat.initialize(_loader, _state, _inventory):
        _failures.append("CombatRunner: %s" % _combat.last_error)
        return false
    if not _combat.bind_save_manager(_save):
        _failures.append("CombatRunner SaveManager binding failed: %s" % _combat.last_error)
        return false
    return true


func _run_primary_route() -> void:
    print("NV7_R1_ROUTE_BEGIN:variant=%d:defeat=%s:objectives=%s/%s/%s" % [_route_variant, _defeat_mode, _state.get_state("quest.nv_main_002.objective.hanshi"), _state.get_state("quest.nv_main_002.objective.suzhi"), _state.get_state("quest.nv_main_002.objective.guchangchuan")])
    var story_id := "NV_MAIN_001"
    var safety := 0
    while not story_id.is_empty() and safety < 3000:
        safety += 1
        _last_choice = {}
        if not _story.start_story(story_id):
            _failures.append("could not start %s: %s" % [story_id, _story.last_error])
            return
        var result := _drive_current_story(story_id)
        if result.is_empty():
            return
        if story_id == "NV_MAIN_002" and _verify_save_round_trip:
            _verify_qualified_save_round_trip()
        story_id = str(result.get("next_story_id", ""))
    if safety >= 3000:
        _failures.append("continuous R1 route exceeded safety limit")
        return
    _expect_status("NV_MAIN_001", "completed")
    _expect_status("NV_MAIN_002", "qualified")
    _expect_status("NV_MAIN_003", "completed")
    _expect_status("NV_MAIN_004", "completed")
    print("NV7_R1_ROUTE_END:variant=%d:status2=%s:sword=%d:shield=%d:hook=%d" % [_route_variant, _state.get_state("quest.nv_main_002.status"), _item_quantity("NV7_ITEM_NOVICE_SWORD"), _item_quantity("NV7_ITEM_NOVICE_SHIELD"), _item_quantity("NV7_ITEM_NOVICE_HOOK_STAFF")])
    _expect(_combat_count >= 3, "formal route did not cross the expected combat nodes")
    _expect(_reward_count >= 2, "formal route did not cross equipment/evidence reward nodes")
    var equipment_by_route: Array[String] = [
        "NV7_ITEM_NOVICE_SWORD",
        "NV7_ITEM_NOVICE_SHIELD",
        "NV7_ITEM_NOVICE_HOOK_STAFF",
    ]
    var expected_equipment: String = equipment_by_route[_route_variant]
    _expect(_item_quantity(expected_equipment) == 1, "selected starter equipment was not granted exactly once")
    var evidence_item := "NV7_ITEM_BOUNDARY_RUBBING" if _route_variant == 2 else "NV7_ITEM_BLUE_POWDER_SAMPLE"
    _expect(_item_quantity(evidence_item) == 1, "selected commission evidence was not granted")
    _expect(_state.get_state("world.nv7.adventurers_trapped_confirmed") == true, "trapped-player world fact was not persisted")
    var expected_rabbit_outcome := "injured" if _defeat_mode else ("dead" if _route_variant == 2 else "alive")
    _expect(_state.get_state("world.nv7.rabbit_king_outcome") == expected_rabbit_outcome, "rabbit route outcome is wrong")
    _expect(_state.get_state("world.nv7.wolf_king_outcome") == ("escaped" if _defeat_mode else "controlled"), "wolf route outcome is wrong")
    if _route_variant < 2:
        var chief_flag_id := "remembers_fengyue_candor" if _route_variant == 0 else "cautious_about_fengyue"
        var chief_flag: Dictionary = _relationships.get_flag("NV7_REL_FENGYUE_GUCHANGCHUAN", chief_flag_id)
        _expect(bool(chief_flag.get("ok", false)), "chief relationship flag cannot be queried")
        _expect(bool(chief_flag.get("value", false)), "reviewed relationship flag was not set")


func _drive_current_story(story_id: String) -> Dictionary:
    var definition: Dictionary = _loader.get_story(story_id)
    var nodes := {}
    for raw_node: Variant in definition.get("nodes", []):
        nodes[str(raw_node.get("node_id", ""))] = raw_node
    var steps := 0
    while _story.is_running() and steps < 2500:
        steps += 1
        var position: Dictionary = _story.get_current_position()
        var node_id := str(position.get("node_id", ""))
        var node: Dictionary = nodes.get(node_id, {})
        if node.is_empty():
            _failures.append("%s reached unknown node %s" % [story_id, node_id])
            return {}
        match str(node.get("type", "")):
            "narrative", "dialogue":
                if not _story.advance():
                    _failures.append("%s advance failed at %s: %s" % [story_id, node_id, _story.last_error])
                    return {}
            "choice":
                var choice_id := _select_choice(story_id, node_id)
                if choice_id.is_empty() or not _story.choose_choice(choice_id):
                    _failures.append("%s choice failed at %s (%s): %s" % [story_id, node_id, choice_id, _story.last_error])
                    return {}
            "reward":
                var grants: Array = node.get("reward_items", [])
                var reward_result: Dictionary = _inventory.grant_items(grants, "story")
                if not bool(reward_result.get("ok", false)):
                    _failures.append("%s reward failed at %s: %s" % [story_id, node_id, reward_result])
                    return {}
                _reward_count += 1
                if not _story.resolve_external_node("success"):
                    _failures.append("reward continuation failed at %s" % node_id)
                    return {}
            "combat":
                var start_result: Dictionary = _combat.start_combat(str(node.get("combat_ref", "")), 7000 + _combat_count)
                if not bool(start_result.get("ok", false)):
                    _failures.append("combat start failed at %s: %s" % [node_id, start_result])
                    return {}
                var result_type := "defeat" if _defeat_mode else "victory"
                var finish_result: Dictionary = _combat.abort_combat(result_type, "vertical_slice_test")
                if not bool(finish_result.get("ok", false)):
                    _failures.append("combat resolution failed at %s: %s" % [node_id, finish_result])
                    return {}
                _combat_count += 1
                if str(node.get("combat_ref", "")) == "NV7_COMBAT_GREY_BADGERS":
                    _hanshi_attempted = true
                if not _story.resolve_external_node(result_type):
                    _failures.append("combat continuation failed at %s" % node_id)
                    return {}
            _:
                _failures.append("unsupported formal node type at %s: %s" % [node_id, node.get("type")])
                return {}
    if steps >= 2500:
        _failures.append("%s exceeded story step safety limit" % story_id)
        return {}
    var result: Dictionary = _story.get_completion_result()
    if result.is_empty():
        _failures.append("%s ended without completion result" % story_id)
    return result


func _select_choice(story_id: String, node_id: String) -> String:
    var choices: Array = _last_choice.get("choices", [])
    if choices.is_empty():
        return ""
    if story_id == "NV_MAIN_002" and node_id == "commission_hub":
        var preferred := "continue_main_story"
        if _defeat_mode and not _hanshi_attempted:
            preferred = "commission_hanshi"
        elif _route_variant == 2 and _state.get_state("quest.nv_main_002.objective.hanshi") == false:
            preferred = "commission_hanshi"
        elif _route_variant == 2 and _state.get_state("quest.nv_main_002.objective.guchangchuan") == false:
            preferred = "commission_guchangchuan"
        elif _state.get_state("quest.nv_main_002.status") in ["qualified", "completed"]:
            preferred = "continue_main_story"
        elif _state.get_state("quest.nv_main_002.objective.suzhi") == false:
            preferred = "commission_suzhi"
        elif _defeat_mode and _state.get_state("quest.nv_main_002.objective.guchangchuan") == false:
            preferred = "commission_guchangchuan"
        for choice: Variant in choices:
            if str(choice.get("choice_id", "")) == preferred and bool(choice.get("enabled", true)):
                return preferred
    var choice_index := mini(_route_variant, choices.size() - 1)
    return str(choices[choice_index].get("choice_id", ""))


func _verify_qualified_save_round_trip() -> void:
    _expect_status("NV_MAIN_002", "qualified")
    var saved: Dictionary = _save.save("manual_1")
    _expect(bool(saved.get("ok", false)), "qualified R1 save failed: %s" % saved)
    var mutate: Dictionary = _quests.update_objective("NV_MAIN_002", "guchangchuan", {"value": true})
    _expect(bool(mutate.get("ok", false)), "could not mutate third commission before load")
    _expect_status("NV_MAIN_002", "completed")
    _inventory.grant_items([{"item_id": "NV7_ITEM_RABBIT_HIDE", "quantity": 2}], "debug")
    var loaded: Dictionary = _save.load("manual_1")
    _expect(bool(loaded.get("ok", false)), "qualified R1 load failed: %s" % loaded)
    _expect_status("NV_MAIN_002", "qualified")
    _expect(_state.get_state("quest.nv_main_002.objective.guchangchuan") == false, "third commission leaked across load")
    _expect(_item_quantity("NV7_ITEM_RABBIT_HIDE") == 0, "inventory mutation leaked across load")
    _expect(str(_story.get_current_position().get("story_id", "")) == "NV_MAIN_002", "StoryRunner position was not restored")


func _verify_third_commission_completion() -> void:
    _expect_status("NV_MAIN_002", "qualified")
    var incomplete_objective := ""
    for objective_id: String in ["hanshi", "suzhi", "guchangchuan"]:
        var progress: Dictionary = _quests.get_objective_progress("NV_MAIN_002", objective_id)
        if bool(progress.get("ok", false)) and not bool(progress.get("completed", false)):
            incomplete_objective = objective_id
            break
    _expect(not incomplete_objective.is_empty(), "qualified commission set did not retain a third objective")
    if incomplete_objective.is_empty():
        return
    var completed: Dictionary = _quests.update_objective("NV_MAIN_002", incomplete_objective, {"value": true}, "story")
    _expect(bool(completed.get("ok", false)), "third commission could not be completed after qualified")
    _expect_status("NV_MAIN_002", "completed")
    _expect(_state.get_state("quest.nv_main_002.reward_granted") == true, "full commission reward marker was not set")
    var repeated: Dictionary = _quests.update_objective("NV_MAIN_002", incomplete_objective, {"value": true}, "story")
    _expect(bool(repeated.get("ok", false)), "repeating an already complete objective returned an error")
    _expect(not bool(repeated.get("changed", true)), "repeating the third objective changed completed quest state")


func _verify_repeated_restore_is_idempotent() -> void:
    var equipment_before := _item_quantity("NV7_ITEM_NOVICE_SWORD")
    var trust_before: Dictionary = _relationships.get_dimension("NV7_REL_FENGYUE_GUCHANGCHUAN", "trust")
    var saved: Dictionary = _save.save("manual_2")
    _expect(bool(saved.get("ok", false)), "completed R1 checkpoint could not be saved")
    var first_load: Dictionary = _save.load("manual_2")
    var second_load: Dictionary = _save.load("manual_2")
    _expect(bool(first_load.get("ok", false)) and bool(second_load.get("ok", false)), "repeated R1 restore failed")
    _expect(_item_quantity("NV7_ITEM_NOVICE_SWORD") == equipment_before, "repeated restore duplicated equipment reward")
    var trust_after: Dictionary = _relationships.get_dimension("NV7_REL_FENGYUE_GUCHANGCHUAN", "trust")
    _expect(trust_after.get("value") == trust_before.get("value"), "repeated restore duplicated relationship effects")
    _expect(_state.get_state("quest.nv_main_002.reward_granted") == true, "repeated restore cleared reward idempotency marker")


func _verify_r2_entry_snapshot() -> void:
    _expect_status("NV_MAIN_001", "completed")
    _expect_status("NV_MAIN_002", "completed")
    _expect_status("NV_MAIN_003", "completed")
    _expect_status("NV_MAIN_004", "completed")
    for objective_id: String in ["hanshi", "suzhi", "guchangchuan"]:
        var progress: Dictionary = _quests.get_objective_progress("NV_MAIN_002", objective_id)
        _expect(bool(progress.get("ok", false)) and bool(progress.get("completed", false)), "R2 snapshot lost commission %s" % objective_id)
    _expect(_state.get_state("world.nv7.rabbit_king_outcome") == "alive", "R2 snapshot lost protected rabbit outcome")
    _expect(_state.get_state("world.nv7.wolf_king_outcome") == "controlled", "R2 snapshot lost wolf outcome")
    _expect(_state.get_state("world.nv7.adventurers_trapped_confirmed") == true, "R2 snapshot lost trapped-player fact")
    _expect(_item_quantity("NV7_ITEM_NOVICE_SWORD") == 1, "R2 snapshot lost selected starter item")


func _verify_new_game_reset() -> void:
    var state_reset: bool = _state.reset_all_states("system")
    var inventory_reset: Dictionary = _inventory.reset_inventory("system")
    _expect(state_reset, "GameState new-game reset failed")
    _expect(bool(inventory_reset.get("ok", false)), "Inventory new-game reset failed")
    _expect(_state.get_state("quest.nv_main_001.status") == "available", "new game did not restore first quest availability")
    _expect(_state.get_state("quest.nv_main_002.status") == "not_started", "new game inherited R1 quest progress")
    _expect(_item_quantity("NV7_ITEM_NOVICE_SWORD") == 0, "new game inherited R1 inventory")
    _expect(_state.get_state("relation.nv7.fengyue_guchangchuan.trust") == 0, "new game inherited R1 relationship values")


func _on_choice_presented(presentation: Dictionary) -> void:
    _last_choice = presentation.duplicate(true)


func _item_quantity(item_id: String) -> int:
    var result: Dictionary = _inventory.get_item_quantity(item_id, "all")
    return int(result.get("quantity", -1)) if bool(result.get("ok", false)) else -1


func _expect_status(quest_id: String, expected: String) -> void:
    var result: Dictionary = _quests.get_quest_status(quest_id)
    _expect(bool(result.get("ok", false)) and str(result.get("status", "")) == expected,
            "%s status expected %s, got %s" % [quest_id, expected, result])


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    if _failures.is_empty():
        print("NV7_R1_VERTICAL_SLICE_TESTS_OK:combats=%d:rewards=%d" % [_combat_count, _reward_count])
        quit(0)
        return
    for failure: String in _failures:
        printerr("NV7_R1_VERTICAL_SLICE_TEST_FAILURE:%s" % failure)
    quit(1)
