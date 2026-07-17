extends Control

signal mode_changed(mode: String)
signal feedback_changed(result: Dictionary)

const PortraitPresenterClass = preload("res://src/ui/portrait_presenter.gd")
const BackgroundPresenterClass = preload("res://src/ui/background_presenter.gd")
const AudioPresenterClass = preload("res://src/ui/audio_presenter.gd")
const SettingsManagerClass = preload("res://src/ui/settings_manager.gd")

const MODES := ["main_menu", "exploration", "dialogue", "combat"]
const PAGES := ["quest", "inventory", "relationship", "save", "settings", "history"]
const SAVE_SLOTS := ["manual_1", "manual_2", "manual_3", "auto", "quick"]
const HISTORY_LIMIT := 200
const CHOICE_VIEW_HEIGHT := 190.0

var _services: Dictionary = {}
var _settings := SettingsManagerClass.new()
var _mode := "main_menu"
var _page := ""
var _history: Array[Dictionary] = []
var _choice_ids: Array[String] = []
var _choice_slots: Array[Dictionary] = []
var _choice_texts: Dictionary = {}
var _test_story_id := ""
var _last_result: Dictionary = {"ok": true, "code": "OK", "message": ""}
var _combat_log: Array[String] = []
var _confirmation: Dictionary = {}

var _background: TextureRect
var _portrait: TextureRect
var _audio: Node
var _menu_panel: PanelContainer
var _game_panel: VBoxContainer
var _functional_panel: PanelContainer
var _combat_panel: VBoxContainer
var _location_label: Label
var _time_label: Label
var _speaker_label: Label
var _text_label: RichTextLabel
var _objective_label: Label
var _character_label: Label
var _choice_box: VBoxContainer
var _choice_scroll: ScrollContainer
var _status_label: Label
var _history_label: RichTextLabel
var _page_title: Label
var _page_content: RichTextLabel
var _page_actions: VBoxContainer
var _sidebar: VBoxContainer
var _continue_button: Button
var _combat_units_label: RichTextLabel
var _combat_info_label: Label
var _combat_log_label: RichTextLabel
var _combat_actions: HBoxContainer
var _text_tween: Tween
var _player_input_locked := false
var _active_font_size := 22


func _ready() -> void:
    set_process_input(true)
    _build_interface()
    _settings.initialize()
    _settings.settings_changed.connect(_apply_settings)
    _apply_settings(_settings.get_settings())
    show_main_menu()


func bind_services(services: Dictionary) -> Dictionary:
    var required := ["content_loader", "game_state", "story_runner", "quest_manager", "inventory_manager", "relationship_manager", "combat_runner", "save_manager"]
    for key: String in required:
        if not services.has(key) or services[key] == null:
            return _feedback(false, "UI_SERVICE_MISSING", "Missing UI service '%s'" % key)
    _services = services.duplicate()
    _background.bind_content_loader(_services["content_loader"])
    _portrait.bind_content_loader(_services["content_loader"])
    _connect_signals()
    refresh_continue_state()
    return _feedback(true, "OK", "UI services connected")


func set_test_story_id(story_id: String) -> void:
    _test_story_id = story_id


func show_main_menu() -> void:
    _set_mode("main_menu")
    _page = ""
    _menu_panel.visible = true
    _game_panel.visible = false
    _functional_panel.visible = false
    _combat_panel.visible = false
    if not _services.is_empty():
        refresh_continue_state()


func new_game(story_id: String = "") -> Dictionary:
    if _services.is_empty():
        return _feedback(false, "UI_NOT_BOUND", "UI services are not connected")
    _services["game_state"].call("reset_all_states", "system")
    _services["inventory_manager"].call("reset_inventory", "system")
    _services["quest_manager"].call("refresh_availability", "system")
    _history.clear()
    _combat_log.clear()
    _show_game_shell("exploration")
    var selected := story_id if not story_id.is_empty() else _test_story_id
    if selected.is_empty() and _services["content_loader"].has_method("get_default_story_id"):
        selected = str(_services["content_loader"].call("get_default_story_id"))
    if selected.is_empty():
        _render_text({"text": "技术壳层已就绪；正式剧情数据尚未导入。", "location_id": ""}, false)
        return _feedback(true, "STORY_NOT_DATA_READY", "New runtime started without formal story data")
    if not bool(_services["story_runner"].call("start_story", selected)):
        return _feedback(false, str(_services["story_runner"].last_error.get("code", "STORY_START_FAILED")), str(_services["story_runner"].last_error.get("message", "Could not start story")))
    return _feedback(true, "OK", "New game started")


func continue_game() -> Dictionary:
    var latest := _latest_valid_save()
    if latest.is_empty():
        return _feedback(false, "SAVE_NOT_FOUND", "No valid save is available")
    return load_slot(str(latest.get("slot_id", "")))


func advance_story() -> Dictionary:
    if _services.is_empty() or not bool(_services["story_runner"].call("advance")):
        var error: Dictionary = _services["story_runner"].last_error if not _services.is_empty() else {}
        return _feedback(false, str(error.get("code", "STORY_ADVANCE_FAILED")), str(error.get("message", "Could not advance story")))
    return _feedback(true, "OK", "Story advanced")


func submit_player_advance() -> Dictionary:
    if not _begin_player_input():
        return {"ok": false, "code": "UI_INPUT_LOCKED", "message": "Input is already being handled"}
    if _is_typewriter_active():
        _finish_typewriter()
        return {"ok": true, "code": "UI_TEXT_REVEALED", "message": "Current text revealed"}
    return advance_story()


func choose_choice(choice_id: String) -> Dictionary:
    if choice_id not in _choice_ids:
        return _feedback(false, "STORY_CHOICE_UNAVAILABLE", "Choice is not available")
    var selected_text := str(_choice_texts.get(choice_id, choice_id))
    _append_history("choice", "枫月", selected_text)
    if not bool(_services["story_runner"].call("choose_choice", choice_id)):
        if not _history.is_empty() and str(_history.back().get("category", "")) == "choice":
            _history.pop_back()
        var error: Dictionary = _services["story_runner"].last_error
        return _feedback(false, str(error.get("code", "STORY_CHOICE_FAILED")), str(error.get("message", "Choice failed")))
    return _feedback(true, "OK", "Choice submitted")


func submit_player_choice(choice_id: String) -> Dictionary:
    if not _begin_player_input():
        return {"ok": false, "code": "UI_INPUT_LOCKED", "message": "Input is already being handled"}
    if _is_typewriter_active():
        _finish_typewriter()
        return {"ok": false, "code": "UI_TEXT_REVEALED", "message": "Finish reading before choosing"}
    return choose_choice(choice_id)


func present_system_message(message: String) -> void:
    _append_history("system", "系统", message)


func show_page(page: String) -> Dictionary:
    if page not in PAGES:
        return _feedback(false, "UI_PAGE_UNKNOWN", "Unknown page '%s'" % page)
    if _mode == "combat" and page == "save":
        return _feedback(false, "SAVE_BLOCKED_COMBAT", "Saving and loading are disabled during combat")
    _page = page
    _functional_panel.visible = true
    _refresh_page()
    return _feedback(true, "OK", "Page opened")


func close_page() -> void:
    _page = ""
    _functional_panel.visible = false


func inventory_action(action: String, item_id: String, value: String = "") -> Dictionary:
    var result: Dictionary
    match action:
        "equip": result = _services["inventory_manager"].call("equip_item", item_id, value, "ui")
        "unequip": result = _services["inventory_manager"].call("unequip_item", value, "ui")
        "use": result = _services["inventory_manager"].call("use_item", item_id, "field", "ui")
        "discard": result = _services["inventory_manager"].call("discard_item", item_id, 1, "ui")
        "claim": result = _services["inventory_manager"].call("claim_custody_item", item_id, 1, "ui")
        _: return _feedback(false, "UI_INVENTORY_ACTION_UNKNOWN", "Unknown inventory action")
    _feedback_from_result(result)
    _refresh_inventory_page()
    return result


func start_combat(combat_id: String, seed: int) -> Dictionary:
    var result: Dictionary = _services["combat_runner"].call("start_combat", combat_id, seed)
    if bool(result.get("ok", false)):
        _show_game_shell("combat")
        _combat_log.clear()
        if bool(_services["combat_runner"].call("is_active")) and str(_services["combat_runner"].call("get_current_actor").get("role", "")) != "player":
            _services["combat_runner"].call("run_until_player_turn")
        _refresh_combat()
    _feedback_from_result(result)
    return result


func submit_combat_action(command: Dictionary) -> Dictionary:
    if _mode != "combat":
        return _feedback(false, "COMBAT_NOT_ACTIVE", "Combat UI is not active")
    var result: Dictionary = _services["combat_runner"].call("perform_action", command)
    _feedback_from_result(result)
    if bool(result.get("ok", false)) and bool(_services["combat_runner"].call("is_active")):
        var auto_result: Dictionary = _services["combat_runner"].call("run_until_player_turn")
        if not bool(auto_result.get("ok", false)):
            _feedback_from_result(auto_result)
    _refresh_combat()
    return result


func save_slot(slot_id: String, confirmed: bool = false) -> Dictionary:
    if _mode == "combat":
        return _feedback(false, "SAVE_BLOCKED_COMBAT", "Saving is disabled during combat")
    if not confirmed and _services["save_manager"].call("has_save", slot_id):
        _confirmation = {"action": "overwrite", "slot_id": slot_id}
        if _page == "save": _refresh_save_page()
        return _feedback(false, "UI_CONFIRMATION_REQUIRED", "Overwrite confirmation is required")
    var result: Dictionary = _services["save_manager"].call("save", slot_id)
    _feedback_from_result(result)
    _refresh_save_page()
    refresh_continue_state()
    return result


func load_slot(slot_id: String) -> Dictionary:
    if _mode == "combat":
        return _feedback(false, "LOAD_BLOCKED_COMBAT", "Loading is disabled during combat")
    var result: Dictionary = _services["save_manager"].call("load", slot_id)
    _feedback_from_result(result)
    if bool(result.get("ok", false)):
        _show_game_shell("exploration")
    else:
        _confirmation = {"action": "restore_backup", "slot_id": slot_id}
        if _page == "save": _refresh_save_page()
    return result


func delete_slot(slot_id: String, confirmed: bool = false) -> Dictionary:
    if not confirmed:
        _confirmation = {"action": "delete", "slot_id": slot_id}
        if _page == "save": _refresh_save_page()
        return _feedback(false, "UI_CONFIRMATION_REQUIRED", "Delete confirmation is required")
    var result: Dictionary = _services["save_manager"].call("delete_save", slot_id)
    _feedback_from_result(result)
    _refresh_save_page()
    refresh_continue_state()
    return result


func restore_backup(slot_id: String) -> Dictionary:
    var result: Dictionary = _services["save_manager"].call("restore_backup", slot_id)
    _feedback_from_result(result)
    _refresh_save_page()
    return result


func confirm_pending_action() -> Dictionary:
    var pending := _confirmation.duplicate(true)
    _confirmation.clear()
    match str(pending.get("action", "")):
        "overwrite": return save_slot(str(pending.get("slot_id", "")), true)
        "delete": return delete_slot(str(pending.get("slot_id", "")), true)
        "restore_backup": return restore_backup(str(pending.get("slot_id", "")))
        _: return _feedback(false, "UI_CONFIRMATION_MISSING", "There is no pending confirmation")


func cancel_pending_action() -> void:
    _confirmation.clear()
    if _page == "save": _refresh_save_page()


func quick_save() -> Dictionary:
    if _mode == "combat":
        return _feedback(false, "SAVE_BLOCKED_COMBAT", "Quick save is disabled during combat")
    var result: Dictionary = _services["save_manager"].call("request_quick_save")
    _feedback_from_result(result)
    return result


func quick_load() -> Dictionary:
    return load_slot("quick")


func update_setting(key: String, value: Variant) -> Dictionary:
    return _settings.set_value(key, value, true)


func get_ui_snapshot() -> Dictionary:
    return {
        "mode": _mode,
        "page": _page,
        "continue_enabled": false if _continue_button == null else not _continue_button.disabled,
        "location": _location_label.text,
        "speaker": _speaker_label.text,
        "text": _text_label.text,
        "choices": _choice_ids.duplicate(),
        "choice_slots": _choice_slots.duplicate(true),
        "history_size": _history.size(),
        "history": _history.duplicate(true),
        "input_locked": _player_input_locked,
        "text_complete": not _is_typewriter_active(),
        "portrait": _portrait.get_presentation_state(),
        "background": _background.get_presentation_state(),
        "page_text": _page_content.text,
        "combat_log_size": _combat_log.size(),
        "feedback": _last_result.duplicate(true),
    }


func validate_layout(size: Vector2i, font_size: int = 22) -> Dictionary:
    var valid_resolution := size.x >= 1280 and size.y >= 720
    var valid_font := font_size >= 18 and font_size <= 32
    var sidebar_collapsible := size.x <= 1280
    var text_scrollable := _text_label != null and _text_label.scroll_active
    var choices_scrollable := _choice_scroll != null and _choice_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
    return {
        "ok": valid_resolution and valid_font and text_scrollable and choices_scrollable,
        "core_controls_visible": valid_resolution,
        "choices_visible": valid_resolution,
        "portrait_does_not_cover_text": valid_resolution,
        "sidebar_collapsible": sidebar_collapsible,
        "font_operable": valid_font,
        "text_scrollable": text_scrollable,
        "choices_scrollable": choices_scrollable,
    }


func refresh_continue_state() -> void:
    if _continue_button != null:
        _continue_button.disabled = _latest_valid_save().is_empty()


func _build_interface() -> void:
    _background = BackgroundPresenterClass.new()
    _background.name = "BackgroundPresenter"
    _background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_background)

    var shade := ColorRect.new()
    shade.color = Color(0.03, 0.04, 0.06, 0.78)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)

    _audio = AudioPresenterClass.new()
    _audio.name = "AudioPresenter"
    add_child(_audio)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    add_child(margin)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    margin.add_child(root_box)

    var top := HBoxContainer.new()
    root_box.add_child(top)
    _location_label = _make_label("地点：—")
    _location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_location_label)
    _time_label = _make_label("时间：—")
    top.add_child(_time_label)
    _status_label = _make_label("")
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_status_label)

    _game_panel = VBoxContainer.new()
    _game_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_box.add_child(_game_panel)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _game_panel.add_child(body)

    _portrait = PortraitPresenterClass.new()
    _portrait.name = "PortraitPresenter"
    _portrait.custom_minimum_size = Vector2(280, 360)
    body.add_child(_portrait)

    var narrative_box := VBoxContainer.new()
    narrative_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(narrative_box)
    _speaker_label = _make_label("")
    _speaker_label.add_theme_font_size_override("font_size", 24)
    narrative_box.add_child(_speaker_label)
    _text_label = RichTextLabel.new()
    _text_label.name = "MainText"
    _text_label.bbcode_enabled = false
    _text_label.fit_content = false
    _text_label.scroll_active = true
    _text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    narrative_box.add_child(_text_label)
    _choice_scroll = ScrollContainer.new()
    _choice_scroll.name = "ChoiceScroll"
    _choice_scroll.custom_minimum_size = Vector2(0, CHOICE_VIEW_HEIGHT)
    _choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    narrative_box.add_child(_choice_scroll)
    _choice_box = VBoxContainer.new()
    _choice_box.name = "Choices"
    _choice_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _choice_scroll.add_child(_choice_box)

    _sidebar = VBoxContainer.new()
    _sidebar.custom_minimum_size = Vector2(260, 0)
    body.add_child(_sidebar)
    _character_label = _make_label("角色状态：已就绪")
    _sidebar.add_child(_character_label)
    _objective_label = _make_label("当前任务：—")
    _objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _sidebar.add_child(_objective_label)
    _history_label = RichTextLabel.new()
    _history_label.custom_minimum_size = Vector2(240, 180)
    _history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _sidebar.add_child(_history_label)
    var collapse := _make_button("折叠状态栏", func(): _sidebar.visible = false)
    _sidebar.add_child(collapse)

    var functions := HBoxContainer.new()
    _game_panel.add_child(functions)
    for pair: Array in [["任务 J", "quest"], ["背包 I", "inventory"], ["关系 R", "relationship"], ["保存", "save"], ["设置", "settings"], ["历史 L", "history"]]:
        functions.add_child(_make_button(str(pair[0]), func(page: String = str(pair[1])): show_page(page)))
    functions.add_child(_make_button("状态栏", func(): _sidebar.visible = not _sidebar.visible))
    functions.add_child(_make_button("返回菜单", show_main_menu))

    _combat_panel = VBoxContainer.new()
    _combat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _game_panel.add_child(_combat_panel)
    _combat_info_label = _make_label("")
    _combat_panel.add_child(_combat_info_label)
    _combat_units_label = RichTextLabel.new()
    _combat_units_label.custom_minimum_size = Vector2(0, 130)
    _combat_panel.add_child(_combat_units_label)
    _combat_log_label = RichTextLabel.new()
    _combat_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _combat_panel.add_child(_combat_log_label)
    _combat_actions = HBoxContainer.new()
    _combat_panel.add_child(_combat_actions)
    for action: String in ["attack", "defend", "skill", "item", "inspect", "retreat"]:
        _combat_actions.add_child(_make_button(action.capitalize(), func(value: String = action): _submit_default_combat_action(value)))

    _menu_panel = PanelContainer.new()
    _menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_box.add_child(_menu_panel)
    var menu := VBoxContainer.new()
    menu.alignment = BoxContainer.ALIGNMENT_CENTER
    _menu_panel.add_child(menu)
    var title := _make_label("《王者》第七新手村 · 可玩技术壳层")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    menu.add_child(title)
    menu.add_child(_make_button("新游戏", func(): new_game()))
    _continue_button = _make_button("继续游戏", continue_game)
    menu.add_child(_continue_button)
    menu.add_child(_make_button("读取存档", func(): _show_game_shell("exploration"); show_page("save")))
    menu.add_child(_make_button("设置", func(): _show_game_shell("exploration"); show_page("settings")))
    menu.add_child(_make_button("退出", func(): get_tree().quit()))

    _functional_panel = PanelContainer.new()
    _functional_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _functional_panel.custom_minimum_size = Vector2(880, 560)
    add_child(_functional_panel)
    var page_box := VBoxContainer.new()
    _functional_panel.add_child(page_box)
    _page_title = _make_label("")
    _page_title.add_theme_font_size_override("font_size", 28)
    page_box.add_child(_page_title)
    _page_content = RichTextLabel.new()
    _page_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    page_box.add_child(_page_content)
    _page_actions = VBoxContainer.new()
    page_box.add_child(_page_actions)
    page_box.add_child(_make_button("关闭 Esc", close_page))


func _connect_signals() -> void:
    var story: RefCounted = _services["story_runner"]
    story.story_node_entered.connect(_on_story_node_entered)
    story.narrative_presented.connect(_on_narrative_presented)
    story.dialogue_presented.connect(_on_dialogue_presented)
    story.choice_presented.connect(_on_choice_presented)
    story.combat_requested.connect(_on_combat_requested)
    story.reward_requested.connect(_on_reward_requested)
    story.story_completed.connect(_on_story_completed)
    story.story_position_restored.connect(_on_story_position_restored)
    story.story_error.connect(_feedback_from_result)
    _services["quest_manager"].quest_status_changed.connect(_on_quest_status_changed)
    _services["quest_manager"].quest_objective_changed.connect(_on_quest_objective_changed)
    _services["inventory_manager"].inventory_changed.connect(_on_inventory_changed)
    _services["inventory_manager"].equipment_changed.connect(_on_inventory_changed)
    _services["inventory_manager"].custody_changed.connect(_on_inventory_changed)
    _services["relationship_manager"].relationship_changed.connect(_on_relationship_changed)
    _services["relationship_manager"].stage_changed.connect(_on_relationship_stage_changed)
    var combat: RefCounted = _services["combat_runner"]
    combat.combat_started.connect(_on_combat_signal)
    combat.round_started.connect(_on_combat_signal)
    combat.turn_started.connect(_on_combat_signal)
    combat.action_resolved.connect(_on_combat_action)
    combat.unit_damaged.connect(_on_combat_signal)
    combat.unit_healed.connect(_on_combat_signal)
    combat.status_applied.connect(_on_combat_signal)
    combat.unit_defeated.connect(_on_combat_signal)
    combat.phase_changed.connect(_on_combat_signal)
    combat.combat_finished.connect(_on_combat_finished)
    _services["save_manager"].save_completed.connect(_on_save_signal)
    _services["save_manager"].load_completed.connect(_on_load_signal)


func _input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if event is InputEventKey:
        match event.keycode:
            KEY_ENTER, KEY_SPACE:
                if _mode in ["exploration", "dialogue"] and _page.is_empty(): submit_player_advance()
            KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
                var index := int(event.keycode - KEY_1)
                if index < _choice_slots.size():
                    var slot: Dictionary = _choice_slots[index]
                    if bool(slot.get("enabled", false)):
                        submit_player_choice(str(slot.get("choice_id", "")))
            KEY_ESCAPE:
                if not _page.is_empty(): close_page()
                elif _mode != "main_menu": show_main_menu()
            KEY_J: show_page("quest")
            KEY_I: show_page("inventory")
            KEY_R: show_page("relationship")
            KEY_L: show_page("history")
            KEY_F5: quick_save()
            KEY_F9: quick_load()


func _on_story_node_entered(_story_id: String, _node_id: String, node_type: String) -> void:
    if node_type == "dialogue": _set_mode("dialogue")
    elif node_type not in ["combat"]: _set_mode("exploration")


func _on_narrative_presented(payload: Dictionary) -> void:
    _render_text(payload, false)


func _on_dialogue_presented(payload: Dictionary) -> void:
    _render_text(payload, true)


func _on_choice_presented(payload: Dictionary) -> void:
    _clear_choices()
    for raw_choice: Variant in payload.get("choices", []):
        if not raw_choice is Dictionary:
            continue
        var choice: Dictionary = raw_choice
        var choice_id := str(choice.get("choice_id", ""))
        var enabled := bool(choice.get("enabled", false))
        var display_text := str(choice.get("text", choice_id))
        if not enabled and not display_text.begins_with("【"):
            display_text = "【暂不可选】%s" % display_text
        var visual_index := _choice_slots.size() + 1
        var button := _make_button("%d. %s" % [visual_index, display_text], func(id: String = choice_id): submit_player_choice(id))
        button.name = "Choice_%s" % choice_id
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
        button.custom_minimum_size = Vector2(0, 54)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.disabled = not enabled
        _choice_box.add_child(button)
        _choice_slots.append({"choice_id": choice_id, "enabled": enabled, "text": display_text})
        if not button.disabled:
            _choice_ids.append(choice_id)
            _choice_texts[choice_id] = display_text


func _on_combat_requested(payload: Dictionary) -> void:
    var seed := maxi(1, int(_services["save_manager"].call("get_random_state").get("seed", 1)))
    start_combat(str(payload.get("combat_ref", "")), seed)


func _on_reward_requested(payload: Dictionary) -> void:
    var grants: Array = payload.get("reward_items", []).duplicate(true)
    if grants.is_empty():
        for item_id: Variant in payload.get("reward_item_ids", []):
            grants.append({"item_id": str(item_id), "quantity": 1})
    var result: Dictionary = _services["inventory_manager"].call("grant_items", grants, "story")
    if bool(result.get("ok", false)):
        _services["story_runner"].call("resolve_external_node", "success")
    else:
        _feedback_from_result(result)


func _on_story_completed(result: Dictionary) -> void:
    var next_story_id := str(result.get("next_story_id", ""))
    if not next_story_id.is_empty():
        if not bool(_services["story_runner"].call("start_story", next_story_id)):
            _feedback_from_result(_services["story_runner"].last_error)
        return
    _render_text({"text": "当前剧情阶段已完成。", "location_id": ""}, false)


func _on_story_position_restored(_position: Dictionary, presentation: Dictionary) -> void:
    _show_game_shell("dialogue" if not str(presentation.get("speaker_id", "")).is_empty() else "exploration")
    _render_text(presentation, not str(presentation.get("speaker_id", "")).is_empty())


func _on_quest_status_changed(_quest_id: String, _old_status: String, _new_status: String, _source: String) -> void:
    _refresh_objective_summary()
    if _new_status in ["qualified", "completed", "failed", "suspended"]:
        var definition: Dictionary = _services["quest_manager"].call("get_quest_definition", _quest_id)
        _append_history("system", "系统", "任务“%s”状态已更新。" % definition.get("title", "当前任务"))
    if _page == "quest": _refresh_quest_page()


func _on_quest_objective_changed(_quest_id: String, _objective_id: String, _old_value: Variant, _new_value: Variant, _source: String) -> void:
    _refresh_objective_summary()
    if _page == "quest": _refresh_quest_page()


func _on_inventory_changed(_payload: Dictionary) -> void:
    if _page == "inventory": _refresh_inventory_page()


func _on_relationship_changed(_payload: Dictionary) -> void:
    if _page == "relationship": _refresh_relationship_page()


func _on_relationship_stage_changed(_relationship_id: String, _previous_stage: String, _current_stage: String, _source: String) -> void:
    if _page == "relationship": _refresh_relationship_page()


func _on_combat_signal(payload: Dictionary) -> void:
    _combat_log.append(str(payload))
    _refresh_combat()


func _on_combat_action(payload: Dictionary) -> void:
    _combat_log.append("%s: %s" % [payload.get("actor_id", "?"), payload.get("action_type", "action")])
    var action_type := str(payload.get("action_type", "attack"))
    var sound_id: String = str({"attack": "SFX_COMBAT_HIT", "defend": "SFX_COMBAT_GUARD", "skill": "SFX_COMBAT_SKILL", "item": "SFX_COMBAT_ITEM", "retreat": "SFX_COMBAT_RETREAT"}.get(action_type, "SFX_UI_CONFIRM"))
    _audio.play_sfx(sound_id)
    _refresh_combat()


func _on_combat_finished(result: Dictionary) -> void:
    _combat_log.append("战斗结束：%s" % result.get("result_type", "unknown"))
    _show_game_shell("exploration")
    var position: Dictionary = _services["story_runner"].call("get_current_position")
    if str(position.get("waiting_for", "")) == "combat":
        _services["story_runner"].call("resolve_external_node", str(result.get("result_type", "defeat")))


func _on_save_signal(result: Dictionary) -> void:
    _feedback_from_result(result)
    if bool(result.get("ok", false)):
        _append_history("system", "系统", "存档已保存。")
    refresh_continue_state()


func _on_load_signal(result: Dictionary) -> void:
    _feedback_from_result(result)
    if bool(result.get("ok", false)):
        _append_history("system", "系统", "存档已读取。")


func _render_text(payload: Dictionary, dialogue: bool) -> void:
    _show_game_shell("dialogue" if dialogue else "exploration")
    var speaker_id := str(payload.get("speaker_id", ""))
    _speaker_label.text = _display_name(speaker_id) if dialogue else "旁白"
    _text_label.text = str(payload.get("text", ""))
    if _text_tween != null and _text_tween.is_valid(): _text_tween.kill()
    var settings := _settings.get_settings()
    if bool(settings.get("typewriter_enabled", true)) and float(settings.get("text_speed", 30.0)) > 0.0:
        _text_label.visible_characters = 0
        _text_tween = create_tween()
        _text_tween.tween_property(_text_label, "visible_characters", _text_label.text.length(), maxf(0.01, float(_text_label.text.length()) / float(settings.get("text_speed", 30.0))))
        if bool(settings.get("autoplay", false)):
            _text_tween.tween_interval(0.8)
            _text_tween.tween_callback(func():
                var position: Dictionary = _services["story_runner"].call("get_current_position")
                if str(position.get("waiting_for", "")) in ["narrative", "dialogue"]: advance_story()
            )
    else:
        _text_label.visible_characters = -1
    if not _text_label.text.is_empty():
        _append_history("dialogue" if dialogue else "narrative", _speaker_label.text, _text_label.text)
    _clear_choices()
    var location_id := str(payload.get("location_id", ""))
    _location_label.text = "地点：%s" % (location_id if not location_id.is_empty() else "—")
    _background.show_location(location_id)
    if not location_id.is_empty():
        var location: Variant = _services["content_loader"].call("get_by_id", location_id)
        if location is Dictionary:
            var music_id := str(location.get("music_id", ""))
            if not music_id.is_empty() and music_id != _audio.get_current_music_id(): _audio.play_music(music_id)
    if dialogue:
        _portrait.present(payload)
    else:
        _portrait.present({"portrait_action": str(payload.get("portrait_action", "hide"))})
    _refresh_objective_summary()
    if _services["game_state"].call("has_state", "test.inventory.health"):
        _character_label.text = "角色状态：HP %s" % _services["game_state"].call("get_state", "test.inventory.health")
    else:
        _character_label.text = "角色状态：运行时已就绪"


func _show_game_shell(mode: String) -> void:
    _menu_panel.visible = false
    _game_panel.visible = true
    _functional_panel.visible = false
    _combat_panel.visible = mode == "combat"
    _portrait.visible = mode == "dialogue"
    _text_label.visible = mode != "combat"
    _choice_scroll.visible = mode != "combat"
    _set_mode(mode)


func _set_mode(mode: String) -> void:
    if mode not in MODES:
        return
    if _mode != mode:
        _mode = mode
        mode_changed.emit(mode)


func _clear_choices() -> void:
    _choice_ids.clear()
    _choice_slots.clear()
    _choice_texts.clear()
    if _choice_box == null:
        return
    for child: Node in _choice_box.get_children():
        _choice_box.remove_child(child)
        child.queue_free()


func _refresh_page() -> void:
    _clear_page_actions()
    match _page:
        "quest": _refresh_quest_page()
        "inventory": _refresh_inventory_page()
        "relationship": _refresh_relationship_page()
        "save": _refresh_save_page()
        "settings": _refresh_settings_page()
        "history":
            _page_title.text = "历史记录"
            _page_content.text = "\n\n".join(_formatted_history(_history))


func _refresh_quest_page() -> void:
    _page_title.text = "任务"
    var lines: Array[String] = []
    var listed: Dictionary = _services["quest_manager"].call("list_quests")
    for entry: Variant in listed.get("quests", []):
        if not entry is Dictionary: continue
        var quest_id := str(entry.get("quest_id", ""))
        var definition: Dictionary = _services["quest_manager"].call("get_quest_definition", quest_id)
        var progress: Dictionary = _services["quest_manager"].call("get_quest_progress", quest_id)
        lines.append("%s\n  状态：%s\n  说明：%s\n  目标：%s" % [definition.get("title", quest_id), entry.get("status", "not_started"), definition.get("design", {}).get("purpose", ""), _format_objectives(progress)])
    _page_content.text = "\n\n".join(lines) if not lines.is_empty() else "没有已登记任务。"


func _refresh_inventory_page() -> void:
    _page_title.text = "背包与装备"
    var inventory: RefCounted = _services["inventory_manager"]
    var backpack: Dictionary = inventory.call("get_backpack_contents")
    var equipment_result: Dictionary = inventory.call("get_equipment")
    var custody: Dictionary = inventory.call("get_custody_contents")
    _page_content.text = "容量：%s/%s\n\n背包：\n%s\n\n装备：\n%s\n\n保管箱：\n%s" % [inventory.call("get_used_slots"), inventory.call("get_capacity"), _format_entries(backpack), _format_dictionary(equipment_result.get("equipment", {})), _format_entries(custody)]
    _clear_page_actions()
    for entry: Variant in backpack.get("items", []):
        if not entry is Dictionary: continue
        var item_id := str(entry.get("item_id", ""))
        var definition: Dictionary = inventory.call("get_item_definition", item_id)
        var runtime: Dictionary = definition.get("runtime", definition)
        var row := HBoxContainer.new()
        var name_label := _make_label("%s × %s" % [definition.get("name", item_id), entry.get("quantity", 0)])
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(name_label)
        if str(runtime.get("type", "")) == "consumable":
            row.add_child(_make_button("使用", func(id: String = item_id): inventory_action("use", id)))
        if str(runtime.get("type", "")) == "equipment":
            row.add_child(_make_button("装备", func(id: String = item_id, slot: String = str(runtime.get("equipment_slot", ""))): inventory_action("equip", id, slot)))
        if bool(runtime.get("discardable", false)):
            row.add_child(_make_button("丢弃", func(id: String = item_id): inventory_action("discard", id)))
        _page_actions.add_child(row)
    var equipment: Dictionary = equipment_result.get("equipment", {})
    for raw_slot: Variant in equipment:
        var equipped: Variant = equipment[raw_slot]
        if equipped is Dictionary and not equipped.is_empty():
            var slot := str(raw_slot)
            _page_actions.add_child(_make_button("卸下 %s" % slot, func(value: String = slot): inventory_action("unequip", "", value)))
    for entry: Variant in custody.get("items", []):
        if entry is Dictionary:
            var custody_id := str(entry.get("item_id", ""))
            _page_actions.add_child(_make_button("领取保管箱：%s" % custody_id, func(id: String = custody_id): inventory_action("claim", id)))


func _refresh_relationship_page() -> void:
    _page_title.text = "关系"
    var lines: Array[String] = []
    var listed: Dictionary = _services["relationship_manager"].call("list_relationships")
    for entry: Variant in listed.get("relationships", []):
        if not entry is Dictionary: continue
        var relationship_id := str(entry.get("relationship_id", ""))
        var state_result: Dictionary = _services["relationship_manager"].call("get_relationship_state", relationship_id)
        var state: Dictionary = state_result.get("relationship", {})
        var dimensions: Dictionary = state.get("dimensions", {})
        lines.append("%s\n  trust %s | affection %s | respect %s | tension %s\n  阶段：%s" % [relationship_id, dimensions.get("trust", 0), dimensions.get("affection", 0), dimensions.get("respect", 0), dimensions.get("tension", 0), state.get("stage", entry.get("stage", ""))])
    _page_content.text = "\n\n".join(lines) if not lines.is_empty() else "没有已登记关系。"


func _refresh_save_page() -> void:
    _page_title.text = "保存与读取"
    var metadata := {}
    var result: Dictionary = _services["save_manager"].call("list_saves")
    for entry: Variant in result.get("saves", []):
        if entry is Dictionary: metadata[str(entry.get("slot_id", ""))] = entry
    var lines: Array[String] = []
    for slot_id: String in SAVE_SLOTS:
        var entry: Dictionary = metadata.get(slot_id, {})
        lines.append("%s：%s" % [slot_id, "空" if entry.is_empty() else ("有效 · %s" % entry.get("updated_at", "")) if bool(entry.get("valid", false)) else "损坏（可尝试备份恢复）"])
    if _mode == "combat": lines.append("\n战斗中：保存和读取已禁用。")
    _page_content.text = "\n".join(lines)
    _clear_page_actions()
    for slot_id: String in SAVE_SLOTS:
        var row := HBoxContainer.new()
        var label := _make_label(slot_id)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        if slot_id.begins_with("manual_"):
            row.add_child(_make_button("保存", func(value: String = slot_id): save_slot(value)))
        var load_button := _make_button("读取", func(value: String = slot_id): load_slot(value))
        load_button.disabled = not _services["save_manager"].call("has_save", slot_id)
        row.add_child(load_button)
        row.add_child(_make_button("删除", func(value: String = slot_id): delete_slot(value, false)))
        row.add_child(_make_button("恢复备份", func(value: String = slot_id): restore_backup(value)))
        _page_actions.add_child(row)
    if not _confirmation.is_empty():
        var confirm_row := HBoxContainer.new()
        confirm_row.add_child(_make_label("确认操作：%s %s" % [_confirmation.get("action", ""), _confirmation.get("slot_id", "")]))
        confirm_row.add_child(_make_button("确认", confirm_pending_action))
        confirm_row.add_child(_make_button("取消", cancel_pending_action))
        _page_actions.add_child(confirm_row)


func _refresh_settings_page() -> void:
    _page_title.text = "设置"
    var value := _settings.get_settings()
    _page_content.text = "主音量：%d%%\n音乐：%d%%\n音效：%d%%\n文字速度：%s\n逐字显示：%s\n字号：%s\n显示：%s / %s\n自动播放：%s\n\n设置保存在独立 settings.json，不写入游戏进度存档。" % [int(float(value.master_volume) * 100.0), int(float(value.music_volume) * 100.0), int(float(value.sfx_volume) * 100.0), value.text_speed, value.typewriter_enabled, value.font_size, "全屏" if value.fullscreen else "窗口", value.resolution, value.autoplay]
    _clear_page_actions()
    var volume_row := HBoxContainer.new()
    for setting_key: String in ["master_volume", "music_volume", "sfx_volume"]:
        volume_row.add_child(_make_button("%s -" % setting_key, func(key: String = setting_key): update_setting(key, maxf(0.0, float(_settings.get_value(key)) - 0.1))))
        volume_row.add_child(_make_button("%s +" % setting_key, func(key: String = setting_key): update_setting(key, minf(1.0, float(_settings.get_value(key)) + 0.1))))
    _page_actions.add_child(volume_row)
    var text_row := HBoxContainer.new()
    text_row.add_child(_make_button("字号 -", func(): update_setting("font_size", maxi(18, int(_settings.get_value("font_size")) - 1))))
    text_row.add_child(_make_button("字号 +", func(): update_setting("font_size", mini(32, int(_settings.get_value("font_size")) + 1))))
    text_row.add_child(_make_button("逐字显示", func(): update_setting("typewriter_enabled", not bool(_settings.get_value("typewriter_enabled")))))
    text_row.add_child(_make_button("自动播放", func(): update_setting("autoplay", not bool(_settings.get_value("autoplay")))))
    _page_actions.add_child(text_row)
    var display_row := HBoxContainer.new()
    display_row.add_child(_make_button("全屏/窗口", func(): update_setting("fullscreen", not bool(_settings.get_value("fullscreen")))))
    display_row.add_child(_make_button("切换分辨率", func(): update_setting("resolution", "1920x1080" if str(_settings.get_value("resolution")) == "1280x720" else "1280x720")))
    _page_actions.add_child(display_row)


func _refresh_objective_summary() -> void:
    if _services.is_empty(): return
    var listed: Dictionary = _services["quest_manager"].call("list_quests")
    for entry: Variant in listed.get("quests", []):
        if entry is Dictionary and str(entry.get("status", "")) in ["active", "qualified"]:
            _objective_label.text = "当前任务：%s [%s]" % [entry.get("quest_id", ""), entry.get("status", "")]
            return
    _objective_label.text = "当前任务：—"


func _refresh_combat() -> void:
    if _services.is_empty(): return
    var combat: RefCounted = _services["combat_runner"]
    _combat_info_label.text = "回合：%s　当前行动者：%s" % [combat.call("get_round"), combat.call("get_current_actor").get("unit_id", "—")]
    var lines: Array[String] = []
    for entry: Variant in combat.call("get_action_order"):
        var unit_id := str(entry.get("unit_id", "")) if entry is Dictionary else str(entry)
        var unit: Dictionary = combat.call("get_unit_state", unit_id)
        if not unit.is_empty():
            lines.append("%s [%s] HP %s/%s　状态 %s" % [unit_id, unit.get("role", ""), unit.get("hp", 0), unit.get("max_hp", 0), unit.get("statuses", [])])
    _combat_units_label.text = "\n".join(lines)
    _combat_log_label.text = "\n".join(_combat_log.slice(maxi(0, _combat_log.size() - 12)))
    var player_turn := bool(combat.call("is_active")) and str(combat.call("get_current_actor").get("role", "")) == "player"
    for child: Node in _combat_actions.get_children():
        if child is Button: child.disabled = not player_turn


func _submit_default_combat_action(action: String) -> void:
    var combat: RefCounted = _services["combat_runner"]
    var actor: Dictionary = combat.call("get_current_actor")
    var command := {"type": action, "actor_id": str(actor.get("unit_id", ""))}
    var enemy_id := ""
    for entry: Variant in combat.call("get_action_order"):
        var unit_id := str(entry.get("unit_id", "")) if entry is Dictionary else str(entry)
        var state: Dictionary = combat.call("get_unit_state", unit_id)
        if str(state.get("role", "")) == "enemy" and int(state.get("hp", 0)) > 0:
            enemy_id = unit_id
            break
    if action in ["attack", "inspect"]: command["target_id"] = enemy_id
    if action == "skill":
        command["skill_id"] = str(actor.get("skill_ids", [""])[0]) if not actor.get("skill_ids", []).is_empty() else ""
        command["target_id"] = enemy_id
    if action == "item":
        command["item_id"] = _first_battle_item_id()
        command["target_id"] = str(actor.get("unit_id", ""))
    submit_combat_action(command)


func _first_battle_item_id() -> String:
    var contents: Dictionary = _services["inventory_manager"].call("get_backpack_contents")
    for entry: Variant in contents.get("items", []):
        if not entry is Dictionary: continue
        var definition: Dictionary = _services["inventory_manager"].call("get_item_definition", str(entry.get("item_id", "")))
        if str(definition.get("use_context", definition.get("runtime", {}).get("use_context", ""))) in ["battle_only", "both"]:
            return str(entry.get("item_id", ""))
    return ""


func _latest_valid_save() -> Dictionary:
    if _services.is_empty(): return {}
    var listed: Dictionary = _services["save_manager"].call("list_saves")
    var latest: Dictionary = {}
    for entry: Variant in listed.get("saves", []):
        if not entry is Dictionary or not bool(entry.get("valid", false)): continue
        if latest.is_empty() or str(entry.get("updated_at", "")) > str(latest.get("updated_at", "")):
            latest = entry.duplicate(true)
    return latest


func _format_objectives(progress: Dictionary) -> String:
    var values: Array[String] = []
    for entry: Variant in progress.get("objectives", []):
        if entry is Dictionary: values.append("%s=%s" % [entry.get("objective_id", "?"), entry.get("progress", entry.get("value", "?"))])
    return ", ".join(values) if not values.is_empty() else "—"


func _format_entries(document: Dictionary) -> String:
    var values: Array[String] = []
    for entry: Variant in document.get("items", []):
        if entry is Dictionary: values.append("%s × %s" % [entry.get("item_id", "?"), entry.get("quantity", 0)])
    return "\n".join(values) if not values.is_empty() else "—"


func _format_dictionary(document: Dictionary) -> String:
    var values: Array[String] = []
    for key: Variant in document:
        values.append("%s：%s" % [key, document[key]])
    return "\n".join(values) if not values.is_empty() else "—"


func _display_name(global_id: String) -> String:
    if global_id.is_empty() or _services.is_empty(): return global_id
    var definition: Variant = _services["content_loader"].call("get_by_id", global_id)
    if definition is Dictionary:
        return str(definition.get("name", global_id))
    return global_id


func _apply_settings(settings: Dictionary) -> void:
    var font_size := int(settings.get("font_size", 22))
    _active_font_size = font_size
    _apply_font_size(self, font_size)
    if _audio != null:
        _audio.set_volumes(float(settings.get("master_volume", 1.0)), float(settings.get("music_volume", 0.8)), float(settings.get("sfx_volume", 0.8)))
    _settings.apply_window_settings()
    if _page == "settings": _refresh_settings_page()


func _make_label(text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", _active_font_size)
    return label


func _make_button(text_value: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(140, 44)
    button.add_theme_font_size_override("font_size", _active_font_size)
    button.pressed.connect(callback)
    return button


func _apply_font_size(node: Node, font_size: int) -> void:
    if node is RichTextLabel:
        node.add_theme_font_size_override("normal_font_size", font_size)
        node.add_theme_font_size_override("bold_font_size", font_size)
    elif node is Control:
        node.add_theme_font_size_override("font_size", font_size)
    for child: Node in node.get_children():
        _apply_font_size(child, font_size)


func _begin_player_input() -> bool:
    if _player_input_locked:
        return false
    _player_input_locked = true
    call_deferred("_release_player_input")
    return true


func _release_player_input() -> void:
    _player_input_locked = false


func _is_typewriter_active() -> bool:
    return _text_label != null and _text_label.visible_characters >= 0 and _text_label.visible_characters < _text_label.text.length()


func _finish_typewriter() -> void:
    if _text_tween != null and _text_tween.is_valid():
        _text_tween.kill()
    _text_label.visible_characters = -1


func _append_history(category: String, speaker: String, text_value: String) -> void:
    var clean_text := text_value.strip_edges()
    if clean_text.is_empty():
        return
    _history.append({"category": category, "speaker": speaker, "text": clean_text})
    while _history.size() > HISTORY_LIMIT:
        _history.pop_front()
    if _history_label != null:
        var recent: Array = _history.slice(maxi(0, _history.size() - 8))
        _history_label.text = "\n".join(_formatted_history(recent))


func _formatted_history(entries: Array) -> Array[String]:
    var lines: Array[String] = []
    for entry_value: Variant in entries:
        if not entry_value is Dictionary:
            continue
        var entry: Dictionary = entry_value
        var category := str(entry.get("category", ""))
        var speaker := str(entry.get("speaker", ""))
        var text_value := str(entry.get("text", ""))
        if category == "choice":
            lines.append("【选择】%s" % text_value)
        elif category == "system":
            lines.append("【系统】%s" % text_value)
        else:
            lines.append("%s：%s" % [speaker, text_value])
    return lines


func _clear_page_actions() -> void:
    if _page_actions == null: return
    for child: Node in _page_actions.get_children():
        _page_actions.remove_child(child)
        child.queue_free()


func _feedback_from_result(result: Dictionary) -> void:
    _feedback(bool(result.get("ok", false)), str(result.get("code", "UNKNOWN")), str(result.get("message", result)))


func _feedback(ok: bool, code: String, message: String) -> Dictionary:
    var public_message := message if ok else _friendly_error_summary(code)
    _last_result = {"ok": ok, "code": code, "message": public_message}
    if _status_label != null:
        _status_label.text = ("✓ " if ok else "⚠ ") + public_message
    if not ok and _should_log_error(code):
        push_error("UI_DETAIL [%s] %s" % [code, message])
    if not ok:
        _append_history("system", "系统", public_message)
    feedback_changed.emit(_last_result.duplicate(true))
    return _last_result.duplicate(true)


func _friendly_error_summary(code: String) -> String:
    if code.begins_with("SAVE_") or code.begins_with("LOAD_"):
        return "存档操作失败，请稍后重试或尝试恢复备份。"
    if code.begins_with("STORY_"):
        return "剧情数据暂时无法继续，请返回菜单后重试。"
    if code.begins_with("COMBAT_"):
        return "当前战斗操作无法执行，请选择其他行动。"
    if code.begins_with("INVENTORY_"):
        return "当前物品操作无法完成。"
    return "操作未能完成，请稍后重试。"


func _should_log_error(code: String) -> bool:
    return not (
        code.begins_with("UI_")
        or code.ends_with("_BLOCKED_COMBAT")
        or code in ["SAVE_NOT_FOUND", "STORY_CHOICE_UNAVAILABLE", "INVENTORY_CAPACITY_FULL"]
    )
