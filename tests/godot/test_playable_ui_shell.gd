extends Node

const GameStateClass = preload("res://src/core/game_state.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")
const QuestManagerClass = preload("res://src/core/quest_manager.gd")
const RelationshipManagerClass = preload("res://src/core/relationship_manager.gd")
const StoryRunnerClass = preload("res://src/core/story_runner.gd")
const SaveManagerClass = preload("res://src/core/save_manager.gd")
const CombatRunnerClass = preload("res://src/core/combat_runner.gd")
const DebugConsoleClass = preload("res://src/ui/debug_console.gd")
const SettingsManagerClass = preload("res://src/ui/settings_manager.gd")
const MainUIScene = preload("res://scenes/ui/main_ui.tscn")

const BASE_STATE := "res://content/tests/fixtures/quest_manager/state_registry.json"
const STORY_STATE := "res://content/tests/fixtures/game_state/state_registry.json"
const INVENTORY_STATE := "res://content/tests/fixtures/inventory_manager/state_registry.json"
const RELATIONSHIP_STATE := "res://content/tests/fixtures/relationship_manager/state_registry.json"
const ITEMS := "res://content/tests/fixtures/inventory_manager/items.json"
const QUESTS := "res://content/tests/fixtures/quest_manager/quests.json"
const RELATIONSHIPS := "res://content/tests/fixtures/relationship_manager/relationships.json"
const COMBATS := "res://content/tests/fixtures/combat_runner/combats.json"
const ENEMIES := "res://content/tests/fixtures/combat_runner/enemies.json"
const SKILLS := "res://content/tests/fixtures/combat_runner/skills.json"
const STORY := "res://content/tests/fixtures/playable_ui_shell/technical_story.json"

const STORY_ID := "TEST_UI_TECHNICAL_SLICE"
const QUEST_ID := "TEST_QUEST_PARALLEL"
const RELATIONSHIP_ID := "TEST_REL_PLAYER_ALPHA"
const FIELD_TONIC := "TEST_ITEM_FIELD_TONIC"
const BATTLE_TONIC := "TEST_ITEM_BATTLE_TONIC"
const SWORD := "TEST_ITEM_ONE_HANDED_SWORD"
const PLAYER := "TEST_UNIT_BOSS_PLAYER"
const ENEMY := "TEST_UNIT_BOSS_A"
const SKILL := "TEST_SKILL_POWER_STRIKE"


class FixtureContentLoader extends RefCounted:
    var states: Array
    var state_index := {}
    var items: Array
    var quests: Array
    var relationships: Dictionary
    var combats: Dictionary
    var enemies: Array
    var skills: Array
    var story: Dictionary

    func _init(state_values: Array, item_values: Array, quest_values: Array, relationship_values: Dictionary, combat_values: Dictionary, enemy_values: Array, skill_values: Array, story_value: Dictionary) -> void:
        states = state_values
        items = item_values
        quests = quest_values
        relationships = relationship_values
        combats = combat_values
        enemies = enemy_values
        skills = skill_values
        story = story_value
        for definition: Dictionary in states:
            state_index[str(definition.get("key", ""))] = definition

    func get_state_definitions() -> Array: return states.duplicate(true)
    func get_state_definition(key: String) -> Variant: return state_index.get(key)
    func get_item_definitions() -> Array: return items.duplicate(true)
    func get_quest_definitions() -> Array: return quests.duplicate(true)
    func get_quest_dependencies() -> Dictionary: return {"schema_version": "1.0.0", "quests": []}
    func get_relationship_registry() -> Dictionary: return relationships.duplicate(true)
    func get_relationship_definitions() -> Array: return relationships.get("relationships", []).duplicate(true)
    func get_combat_definitions() -> Array: return combats.get("combats", []).duplicate(true)
    func get_combat_runtime_registry() -> Dictionary: return combats.get("runtime", {}).duplicate(true)
    func get_enemy_definitions() -> Array: return enemies.duplicate(true)
    func get_skill_definitions() -> Array: return skills.duplicate(true)

    func get_story(story_id: String) -> Variant:
        return story.duplicate(true) if story_id == str(story.get("quest_id", "")) else null

    func get_by_id(global_id: String) -> Variant:
        if global_id == "TEST_UI_NPC":
            return {
                "npc_id": "TEST_UI_NPC",
                "name": "Synthetic UI NPC",
                "portrait_set": {
                    "base_path": "res://assets/portraits/nv7/lanyin",
                    "default_expression": "neutral",
                    "expressions": {"neutral": "lanyin__neutral.png", "smile": "lanyin__smile.png"},
                },
            }
        if global_id == "TEST_UI_LOCATION":
            return {"location_id": "TEST_UI_LOCATION", "background_id": "BG_NV7_SQUARE", "music_id": "BGM_VILLAGE_DAY"}
        return null


var _failures: Array[String] = []
var _cases := 0
var _base_root := ""
var _combat_action_types: Array[String] = []


func _ready() -> void:
    _base_root = OS.get_temp_dir().path_join("playable_ui_shell_%d" % OS.get_process_id()).path_join("中文 用户")
    _remove_tree(_base_root)
    await _run()


func _run() -> void:
    var context := _new_context()
    if context.is_empty():
        _finish()
        return
    var ui: Control = context["ui"]
    var state: RefCounted = context["state"]
    var inventory: RefCounted = context["inventory"]
    var quest: RefCounted = context["quest"]
    var relationship: RefCounted = context["relationship"]
    var combat: RefCounted = context["combat"]

    _case("main menu disables continue without a save")
    _expect(ui.get_ui_snapshot().get("mode") == "main_menu", "main menu was not the initial mode")
    _expect(not ui.get_ui_snapshot().get("continue_enabled", true), "continue was enabled without a save")

    _case("new game enters the technical story")
    _expect(ui.new_game(STORY_ID).get("ok", false), "new game failed")
    _expect(ui.get_ui_snapshot().get("mode") == "exploration", "new game did not enter exploration")

    _case("narrative is presented")
    _expect("Synthetic technical narrative" in str(ui.get_ui_snapshot().get("text", "")), "narrative text was not shown")

    _case("Space advances story without activating focused navigation")
    var navigation: Control = ui.find_child("BottomNavigation", true, false)
    (navigation.get_child(0) as Button).grab_focus()
    var space_event := InputEventKey.new()
    space_event.keycode = KEY_SPACE
    space_event.pressed = true
    ui.call("_input", space_event)
    _expect(str(ui.get_ui_snapshot().get("page", "")).is_empty(), "Space activated the focused bottom navigation button")
    ui.call("_release_player_input")

    _case("typewriter input reveals text before advancing and locks reentry")
    ui.call("_apply_settings", {"font_size": 22, "typewriter_enabled": true, "text_speed": 1.0, "autoplay": false, "master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.8})
    ui.call("_render_text", {"text": "Synthetic typewriter protection text.", "location_id": ""}, false)
    var before_reveal: Dictionary = context["story"].get_current_position()
    var reveal_result: Dictionary = ui.submit_player_advance()
    var duplicate_input: Dictionary = ui.submit_player_advance()
    _expect(reveal_result.get("code") == "UI_TEXT_REVEALED" and ui.get_ui_snapshot().get("text_complete", false), "first input did not reveal the current text")
    _expect(duplicate_input.get("code") == "UI_INPUT_LOCKED", "same-frame repeated input was not locked")
    _expect(context["story"].get_current_position() == before_reveal, "revealing text advanced the story")
    ui.call("_release_player_input")

    _case("dialogue presents speaker and portrait")
    _expect(ui.advance_story().get("ok", false), "could not advance to dialogue")
    var dialogue: Dictionary = ui.get_ui_snapshot()
    _expect(dialogue.get("mode") == "dialogue" and dialogue.get("speaker") == "Synthetic UI NPC", "dialogue speaker was not shown")
    _expect(dialogue.get("portrait", {}).get("visible", false), "dialogue portrait was hidden")

    _case("expression switches through PortraitPresenter")
    _expect(dialogue.get("portrait", {}).get("expression") == "smile", "dialogue expression was not selected")

    _case("missing portrait uses fallback without blocking")
    var portrait: Control = ui.find_child("PortraitPresenter", true, false)
    var fallback: Dictionary = portrait.present({"speaker_id": "TEST_MISSING_NPC", "expression": "missing", "portrait_action": "show"})
    _expect(fallback.get("ok", false) and fallback.get("using_fallback", false), "missing portrait did not use fallback")

    _case("choice is filtered and submitted")
    _expect(ui.advance_story().get("ok", false), "could not advance to choice")
    _expect(ui.get_ui_snapshot().get("choices", []).size() == 1, "locked choice was not filtered")

    _case("task page refreshes from QuestManager")
    _expect(quest.activate_quest(QUEST_ID, "debug").get("ok", false), "fixture quest did not activate")
    _expect(ui.show_page("quest").get("ok", false), "task page did not open")
    _expect("进行中" in str(ui.get_ui_snapshot().get("page_text", "")), "localized active task status was not displayed")
    ui.close_page()

    _case("qualified is distinct from completed")
    quest.update_objective(QUEST_ID, "commission_a", {"value": true, "event_id": "ui_a"}, "debug")
    quest.update_objective(QUEST_ID, "commission_b", {"value": true, "event_id": "ui_b"}, "debug")
    ui.show_page("quest")
    _expect("已满足推进条件" in str(ui.get_ui_snapshot().get("page_text", "")) and "已完成" not in str(ui.get_ui_snapshot().get("page_text", "")), "qualified status was not displayed distinctly")
    ui.close_page()

    _case("inventory changes refresh the page")
    ui.show_page("inventory")
    inventory.add_item(FIELD_TONIC, 2, "debug")
    inventory.add_item(BATTLE_TONIC, 2, "debug")
    inventory.add_item(SWORD, 1, "debug")
    _expect("Synthetic field tonic" in str(ui.get_ui_snapshot().get("page_text", "")), "inventory signal did not refresh the localized page")

    _case("equipment action uses InventoryManager public API")
    var equip_result: Dictionary = ui.inventory_action("equip", SWORD, "weapon")
    _expect(equip_result.get("ok", false), "UI equipment action failed")
    _expect(inventory.get_equipment().get("equipment", {}).get("weapon", {}).get("item_id", "") == SWORD, "equipment was not stored by InventoryManager")
    ui.close_page()

    _case("relationship changes refresh public dimensions")
    ui.show_page("relationship")
    var relation_result: Dictionary = relationship.apply_effect(RELATIONSHIP_ID, {"op": "inc", "dimension_id": "trust", "value": 2}, "debug")
    _expect(relation_result.get("ok", false), "relationship public update failed")
    _expect("信任 3" in str(ui.get_ui_snapshot().get("page_text", "")), "relationship page did not refresh localized trust")
    _expect("mutual_interest" not in str(ui.get_ui_snapshot().get("page_text", "")), "relationship page exposed an internal flag")
    ui.close_page()

    _case("player pages do not expose forbidden internal labels")
    var visible_text := str(ui.get_ui_snapshot().get("location", ""))
    for player_page: String in ["quest", "inventory", "relationship", "save", "settings", "history"]:
        ui.show_page(player_page)
        visible_text += "\n" + str(ui.get_ui_snapshot().get("page_text", ""))
    for forbidden: String in ["NV7_", "TEST_", "trust", "affection", "respect", "tension", "stranger", "Page opened"]:
        _expect(forbidden not in visible_text, "player UI exposed forbidden token: %s" % forbidden)
    ui.close_page()

    _case("choice enters CombatRunner-backed combat")
    _expect(ui.choose_choice("continue_test").get("ok", false), "choice submission failed")
    _expect(combat.is_active() and ui.get_ui_snapshot().get("mode") == "combat", "choice did not enter real combat")

    _case("combat actions are submitted through CombatRunner")
    var attack: Dictionary = ui.submit_combat_action({"type": "attack", "actor_id": PLAYER, "target_id": ENEMY})
    var skill: Dictionary = ui.submit_combat_action({"type": "skill", "actor_id": PLAYER, "skill_id": SKILL, "target_id": ENEMY})
    var item: Dictionary = ui.submit_combat_action({"type": "item", "actor_id": PLAYER, "item_id": BATTLE_TONIC, "target_id": PLAYER})
    _expect(attack.get("ok", false) and skill.get("ok", false) and item.get("ok", false), "attack, skill, or item action failed")
    _expect(_combat_action_types.has("attack") and _combat_action_types.has("skill") and _combat_action_types.has("item"), "combat action signals did not record all UI actions")

    _case("save controls are disabled during combat")
    var blocked_save: Dictionary = ui.save_slot("manual_1")
    _expect(not blocked_save.get("ok", true) and blocked_save.get("code") == "SAVE_BLOCKED_COMBAT", "combat save was not blocked")

    _case("combat finish restores exploration and continues story")
    combat.abort_combat("victory", "test_ui_victory")
    _expect(ui.get_ui_snapshot().get("mode") == "exploration", "combat finish did not restore exploration")
    _expect(not combat.is_active(), "combat remained active")

    _case("completed task and reward are applied once")
    quest.update_objective(QUEST_ID, "commission_c", {"value": true, "event_id": "ui_c"}, "debug")
    _expect(quest.get_quest_status(QUEST_ID).get("status") == "completed", "third task objective did not complete the task")
    var critical_before: Dictionary = inventory.get_item_quantity("TEST_ITEM_CRITICAL_REWARD")
    quest.complete_quest(QUEST_ID, "debug")
    var critical_after: Dictionary = inventory.get_item_quantity("TEST_ITEM_CRITICAL_REWARD")
    _expect(critical_before.get("quantity") == critical_after.get("quantity"), "repeat completion duplicated reward")

    _case("save and load restore the integrated runtime")
    var expected_state: Dictionary = state.export_snapshot()
    var expected_inventory: Dictionary = inventory.export_snapshot()
    var expected_story: Dictionary = context["story"].get_current_position()
    _expect(ui.save_slot("manual_1").get("ok", false), "manual save failed")
    state.reset_all_states("system")
    inventory.reset_inventory("system")
    _expect(ui.load_slot("manual_1").get("ok", false), "manual load failed")
    _expect(state.export_snapshot() == expected_state and inventory.export_snapshot() == expected_inventory and context["story"].get_current_position() == expected_story, "save load did not precisely restore runtime")

    _case("valid save enables continue and continue loads latest")
    ui.show_main_menu()
    _expect(ui.get_ui_snapshot().get("continue_enabled", false), "valid save did not enable continue")
    _expect(ui.continue_game().get("ok", false), "continue did not load the latest valid save")

    _case("720p layout keeps core controls visible")
    var layout_720: Dictionary = ui.validate_layout(Vector2i(1280, 720), 22)
    _expect(layout_720.get("ok", false) and layout_720.get("choices_visible", false) and layout_720.get("sidebar_collapsible", false), "720p layout contract failed")

    _case("1080p layout is valid")
    _expect(ui.validate_layout(Vector2i(1920, 1080), 22).get("ok", false), "1080p layout contract failed")

    _case("32px font remains operable")
    ui.call("_apply_settings", {"font_size": 32, "typewriter_enabled": false, "text_speed": 30.0, "autoplay": false, "master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.8})
    var main_text: RichTextLabel = ui.find_child("MainText", true, false)
    _expect(ui.validate_layout(Vector2i(1280, 720), 32).get("font_operable", false), "32px font layout contract failed")
    _expect(main_text.get_theme_font_size("normal_font_size") == 32, "32px setting was not applied to the real main text control")

    _case("five long choices scroll wrap and preserve visual locked slots")
    var synthetic_choices: Array = []
    for choice_index: int in range(5):
        synthetic_choices.append({
            "choice_id": "synthetic_%d" % choice_index,
            "text": "这是用于验证中文长选项自动换行与滚动区域稳定性的技术文本，第%d项不会被截断。" % (choice_index + 1),
            "enabled": choice_index != 0,
        })
    ui.call("_on_choice_presented", {"choices": synthetic_choices})
    await get_tree().process_frame
    await get_tree().process_frame
    var choice_scroll: ScrollContainer = ui.find_child("ChoiceScroll", true, false)
    var choice_box: VBoxContainer = ui.find_child("Choices", true, false)
    var choice_snapshot: Dictionary = ui.get_ui_snapshot()
    _expect(choice_scroll != null and choice_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "long choices do not have a vertical scroll contract")
    _expect(choice_box.get_child_count() == 5, "five choices were not rendered")
    _expect((choice_box.get_child(0) as Button).disabled and "暂不可选" in (choice_box.get_child(0) as Button).text, "visible locked choice lacks an understandable prompt")
    _expect((choice_box.get_child(4) as Button).autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "long choice wrapping is disabled")
    _expect((choice_box.get_child(4) as Button).get_theme_font_size("font_size") == 32, "32px setting was not applied to dynamically created choices")
    _expect(choice_snapshot.get("choice_slots", []).size() == 5 and choice_snapshot.get("choices", []).size() == 4, "visual choice positions were collapsed onto selectable choices")
    var viewport_rect := Rect2(Vector2.ZERO, Vector2(1280, 720))
    _expect(main_text.get_global_rect().size.x > 100.0 and main_text.get_global_rect().size.y > 40.0, "32px text lost its operable reading area")
    _expect(viewport_rect.encloses(choice_scroll.get_global_rect()), "choice scroll area left the 720p viewport")
    _expect(not main_text.get_global_rect().intersects(choice_scroll.get_global_rect()), "long choices overlap the main text")
    _expect(choice_scroll.get_v_scroll_bar().max_value > choice_scroll.get_v_scroll_bar().page, "five long 32px choices do not produce a usable scroll range")

    _case("history is structured bounded and contains choices and system notices")
    var history_before_cap: Array = ui.get_ui_snapshot().get("history", [])
    _expect(history_before_cap.any(func(entry: Dictionary): return entry.get("category") == "choice"), "selected player choice was not recorded")
    _expect(history_before_cap.any(func(entry: Dictionary): return entry.get("category") == "system"), "important system notice was not recorded")
    for history_index: int in range(205):
        ui.present_system_message("Synthetic bounded history %d" % history_index)
    var bounded_history: Array = ui.get_ui_snapshot().get("history", [])
    _expect(bounded_history.size() == 200, "history capacity was not bounded")
    _expect(str(bounded_history.back().get("text", "")).ends_with("204"), "history did not retain the newest entry")

    _case("dialogue review is view-only and can return to current")
    var state_before_review: Dictionary = state.export_snapshot()
    ui.review_previous()
    _expect(ui.get_ui_snapshot().get("review_active", false), "previous dialogue did not enter review mode")
    _expect(state.export_snapshot() == state_before_review, "dialogue review changed GameState")
    ui.return_to_current()
    _expect(not ui.get_ui_snapshot().get("review_active", true), "return current did not leave review mode")

    _case("remappable input detects conflicts and restores defaults")
    var rebind_start: Dictionary = ui.begin_rebind("open_inventory")
    var key_event := InputEventKey.new(); key_event.keycode = KEY_K; key_event.pressed = true
    var rebind_result: Dictionary = ui.capture_rebind_event(key_event)
    _expect(rebind_start.get("ok", false) and rebind_result.get("ok", false), "new key binding failed")
    ui.begin_rebind("open_quest")
    var conflict_result: Dictionary = ui.capture_rebind_event(key_event)
    _expect(conflict_result.get("code") == "INPUT_BINDING_CONFLICT", "key conflict was not reported")
    _expect(ui.confirm_binding_replace().get("ok", false), "conflicting binding could not be replaced")
    _expect(ui.reset_bindings().get("ok", false), "default bindings could not be restored")

    _case("settings instructions reflect live bindings and mouse support")
    ui.show_page("settings")
    var instructions := str(ui.get_ui_snapshot().get("page_text", ""))
    _expect("推进剧情：空格 / 回车" in instructions and "所有核心功能均可使用鼠标完成" in instructions, "settings did not show live operation instructions")
    ui.close_page()

    _case("player error summary hides internal detail")
    var friendly_error: Dictionary = ui.call("_feedback", false, "SAVE_BLOCKED_COMBAT", "res://internal/file.json state.secret.key")
    _expect("internal" not in str(friendly_error.get("message", "")) and "state.secret.key" not in str(friendly_error.get("message", "")), "player error exposed internal detail")

    _case("settings persist outside progress saves")
    var settings := SettingsManagerClass.new()
    var settings_path := _base_root.path_join("settings.json")
    _expect(settings.initialize(settings_path).get("ok", false), "test settings did not initialize")
    var setting_result: Dictionary = settings.set_value("font_size", 32)
    _expect(setting_result.get("ok", false), "settings did not save: %s" % setting_result)
    var reloaded := SettingsManagerClass.new()
    var reload_result: Dictionary = reloaded.initialize(settings_path)
    _expect(reload_result.get("ok", false) and reloaded.get_value("font_size") == 32, "settings did not independently round trip: %s" % reload_result)

    _case("DebugConsole is available only in development")
    var debug := DebugConsoleClass.new()
    add_child(debug)
    _expect(debug.configure(context["services"], true, false, false).get("enabled", false), "development debug console was not enabled")
    _expect(debug.open_console().get("ok", false), "development debug console did not open")
    _expect(debug.execute("state.list").get("ok", false), "debug state query failed")

    _case("release build cannot open DebugConsole")
    debug.configure(context["services"], true, true, true)
    _expect(not debug.open_console().get("ok", true), "release debug console opened")

    _case("technical vertical slice completes through connected systems")
    _expect(expected_story.get("completed", false), "technical story did not reach complete")
    _expect(_combat_action_types.has("attack") and quest.get_quest_status(QUEST_ID).get("status") == "completed" and relationship.get_dimension(RELATIONSHIP_ID, "trust").get("value") == 3, "technical slice did not connect all systems")

    _finish()


func _new_context() -> Dictionary:
    var state_groups := [_read_json(BASE_STATE).get("states", []), _read_json(STORY_STATE).get("states", []), _read_json(INVENTORY_STATE).get("states", []), _read_json(RELATIONSHIP_STATE).get("states", [])]
    var loader := FixtureContentLoader.new(
        _merge_states(state_groups),
        _read_json(ITEMS).get("items", []),
        _read_json(QUESTS).get("quests", []),
        _read_json(RELATIONSHIPS),
        _read_json(COMBATS),
        _read_json(ENEMIES).get("enemies", []),
        _read_json(SKILLS).get("skills", []),
        _read_json(STORY),
    )
    var state := GameStateClass.new()
    var inventory := InventoryManagerClass.new()
    var quest := QuestManagerClass.new()
    var relationship := RelationshipManagerClass.new()
    var story := StoryRunnerClass.new()
    var save := SaveManagerClass.new()
    var combat := CombatRunnerClass.new()
    if not state.initialize_from_content_loader(loader): _failures.append("GameState initialization failed"); return {}
    if not inventory.initialize(loader, state): _failures.append("Inventory initialization failed"); return {}
    if not quest.initialize(loader, state): _failures.append("Quest initialization failed"); return {}
    if not relationship.initialize(loader, state): _failures.append("Relationship initialization failed"); return {}
    quest.bind_relationship_manager(relationship)
    quest.quest_reward_ready.connect(inventory.apply_quest_reward)
    if not story.initialize(loader, state, quest): _failures.append("Story initialization failed"); return {}
    story.bind_relationship_manager(relationship)
    if not save.initialize(loader, state, story, _base_root.path_join("saves"), _base_root.path_join("backups"), "", Callable(), inventory): _failures.append("Save initialization failed"); return {}
    if not combat.initialize(loader, state, inventory): _failures.append("Combat initialization failed"); return {}
    combat.bind_save_manager(save)
    combat.action_resolved.connect(func(result: Dictionary): _combat_action_types.append(str(result.get("action_type", ""))))
    var ui: Control = MainUIScene.instantiate()
    add_child(ui)
    var services := {"content_loader": loader, "game_state": state, "story_runner": story, "quest_manager": quest, "inventory_manager": inventory, "relationship_manager": relationship, "combat_runner": combat, "save_manager": save}
    if not ui.bind_services(services).get("ok", false): _failures.append("UI binding failed"); return {}
    return {"ui": ui, "state": state, "inventory": inventory, "quest": quest, "relationship": relationship, "story": story, "save": save, "combat": combat, "services": services}


func _merge_states(groups: Array) -> Array:
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
        _failures.append("Could not open fixture %s" % path)
        return {}
    var value: Variant = JSON.parse_string(file.get_as_text())
    if not value is Dictionary:
        _failures.append("Fixture is invalid JSON: %s" % path)
        return {}
    return value


func _case(label: String) -> void:
    _cases += 1
    print("UI_SHELL_CASE:%02d:%s" % [_cases, label])


func _expect(value: bool, message: String) -> void:
    if not value: _failures.append(message)


func _finish() -> void:
    _remove_tree(_base_root)
    for child: Node in get_children():
        child.queue_free()
    if _failures.is_empty():
        print("PLAYABLE_UI_SHELL_TESTS_OK:%d" % _cases)
        return
    for failure: String in _failures: printerr("PLAYABLE_UI_SHELL_TEST_FAILED:%s" % failure)
    get_tree().call_deferred("quit", 1)


func _remove_tree(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path): return
    var directory := DirAccess.open(path)
    if directory == null: return
    directory.list_dir_begin()
    var name := directory.get_next()
    while not name.is_empty():
        var child := path.path_join(name)
        if directory.current_is_dir(): _remove_tree(child)
        else: DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(path)
