extends SceneTree

const GameStateClass = preload("res://src/core/game_state.gd")
const InventoryManagerClass = preload("res://src/core/inventory_manager.gd")

const ITEM_FIXTURE := "res://content/tests/fixtures/inventory_manager/items.json"
const STATE_FIXTURE := "res://content/tests/fixtures/inventory_manager/state_registry.json"

const FIELD_TONIC := "TEST_ITEM_FIELD_TONIC"
const BATTLE_TONIC := "TEST_ITEM_BATTLE_TONIC"
const MATERIAL := "TEST_ITEM_MATERIAL_BUNDLE"
const QUEST_ITEM := "TEST_ITEM_QUEST_NOTE"
const CRITICAL_REWARD := "TEST_ITEM_CRITICAL_REWARD"
const ONE_HANDED_SWORD := "TEST_ITEM_ONE_HANDED_SWORD"
const TWO_HANDED_SWORD := "TEST_ITEM_TWO_HANDED_SWORD"
const SHIELD := "TEST_ITEM_OFF_HAND_SHIELD"
const HEAD_GEAR := "TEST_ITEM_HEAD_GEAR"
const BODY_ARMOR := "TEST_ITEM_BODY_ARMOR"
const RING_ALPHA := "TEST_ITEM_RING_ALPHA"
const RING_BETA := "TEST_ITEM_RING_BETA"


class FixtureContentLoader extends RefCounted:
    var state_definitions: Array
    var item_definitions: Array

    func _init(states: Array, items: Array) -> void:
        state_definitions = states
        item_definitions = items

    func get_state_definitions() -> Array:
        return state_definitions.duplicate(true)

    func get_item_definitions() -> Array:
        return item_definitions.duplicate(true)


var _failures: Array[String] = []
var _state_definitions: Array = []
var _item_definitions: Array = []
var _items_by_id: Dictionary = {}


func _init() -> void:
    var item_document := _read_json(ITEM_FIXTURE)
    var state_document := _read_json(STATE_FIXTURE)
    if (
        item_document.is_empty()
        or state_document.is_empty()
        or not item_document.get("items") is Array
        or not state_document.get("states") is Array
    ):
        quit(1)
        return
    _item_definitions = item_document["items"]
    _state_definitions = state_document["states"]
    for raw_item: Variant in _item_definitions:
        if raw_item is Dictionary:
            _items_by_id[str(raw_item.get("item_id", ""))] = raw_item.duplicate(true)
    _expect_fixture_ids()

    _test_stack_add_merge_split_and_limits()
    _test_nonstackable_unique_and_unknown_items()
    _test_remove_discard_and_quantity_guards()
    _test_capacity_and_custody()
    _test_equipment_transactions_and_modifiers()
    _test_consumable_contexts()
    _test_definition_and_reward_guards()
    _test_new_game_and_reset_are_empty()

    if _failures.is_empty():
        print("INVENTORY_MANAGER_TESTS_OK")
        quit(0)
        return
    for failure: String in _failures:
        printerr("INVENTORY_MANAGER_TEST_FAILURE:%s" % failure)
    quit(1)


func _test_stack_add_merge_split_and_limits() -> void:
    var stack_limit := _stack_limit(MATERIAL)
    var context := _new_context("stacking", 3)
    if context.is_empty():
        return
    var manager: RefCounted = context["inventory"]

    _expect_ok(manager.add_item(MATERIAL, 1), "ordinary stackable add")
    _expect_quantity(manager, MATERIAL, "backpack", 1, "ordinary stackable add")
    _expect(manager.get_used_slots() == 1, "one stackable item did not occupy exactly one slot")
    _expect_ok(manager.add_item(MATERIAL, maxi(1, stack_limit - 1)), "merge into an existing stack")
    _expect_quantity(manager, MATERIAL, "backpack", stack_limit, "merged stack")
    _expect(manager.get_used_slots() == 1, "merge unexpectedly consumed another slot")

    var split_context := _new_context("stack_split", 2)
    if split_context.is_empty():
        return
    var split_manager: RefCounted = split_context["inventory"]
    var over_limit_before: Dictionary = split_manager.export_snapshot()
    var over_limit_result: Dictionary = split_manager.add_item(MATERIAL, stack_limit + 1)
    if bool(over_limit_result.get("ok", false)):
        _expect(
            _stack_quantities(split_manager, MATERIAL) == [1, stack_limit],
            "quantity above max_stack was not split into bounded stacks",
        )
        var split_contents: Dictionary = split_manager.get_backpack_contents()
        for raw_entry: Variant in split_contents.get("items", []):
            if raw_entry is Dictionary and str(raw_entry.get("item_id", "")) == MATERIAL:
                _expect(int(raw_entry.get("quantity", 0)) <= stack_limit, "a material stack exceeded max_stack")
    else:
        _expect_failure(over_limit_result, "explicit over-limit rejection")
        _expect(split_manager.export_snapshot() == over_limit_before, "over-limit rejection partially changed inventory")

    var reject_context := _new_context("stack_reject", 1)
    if reject_context.is_empty():
        return
    var reject_manager: RefCounted = reject_context["inventory"]
    var before: Dictionary = reject_manager.export_snapshot()
    _expect_failure(reject_manager.add_item(MATERIAL, stack_limit + 1), "over-limit add without enough slots")
    _expect(reject_manager.export_snapshot() == before, "failed split partially changed inventory")


func _test_nonstackable_unique_and_unknown_items() -> void:
    var context := _new_context("nonstackable", 3)
    if context.is_empty():
        return
    var manager: RefCounted = context["inventory"]
    _expect_ok(manager.add_item(HEAD_GEAR, 2), "two nonstackable items")
    _expect(_stack_quantities(manager, HEAD_GEAR) == [1, 1], "nonstackable equipment shared one stack")
    _expect(manager.get_used_slots() == 2, "nonstackable equipment did not use two slots")

    var unique_context := _new_context("unique", 2)
    if unique_context.is_empty():
        return
    var unique_manager: RefCounted = unique_context["inventory"]
    _expect_ok(unique_manager.add_item(CRITICAL_REWARD, 1), "first unique item add")
    var unique_before: Dictionary = unique_manager.export_snapshot()
    _expect_failure(unique_manager.add_item(CRITICAL_REWARD, 1), "duplicate unique item add")
    _expect(unique_manager.export_snapshot() == unique_before, "duplicate unique item changed inventory")
    _expect_quantity(unique_manager, CRITICAL_REWARD, "all", 1, "unique item across all containers")

    var unknown_before: Dictionary = manager.export_snapshot()
    _expect_failure(manager.add_item("TEST_ITEM_UNKNOWN", 1), "unknown item add")
    _expect_failure(manager.remove_item("TEST_ITEM_UNKNOWN", 1), "unknown item remove")
    _expect(manager.export_snapshot() == unknown_before, "unknown item operation polluted inventory")


func _test_remove_discard_and_quantity_guards() -> void:
    var context := _new_context("removal", 3)
    if context.is_empty():
        return
    var manager: RefCounted = context["inventory"]
    _expect_ok(manager.add_item(MATERIAL, 5), "removal setup")
    _expect_ok(manager.remove_item(MATERIAL, 2), "valid removal")
    _expect_quantity(manager, MATERIAL, "backpack", 3, "valid removal")
    var insufficient_before: Dictionary = manager.export_snapshot()
    _expect_failure(manager.remove_item(MATERIAL, 4), "insufficient removal")
    _expect(manager.export_snapshot() == insufficient_before, "insufficient removal was not atomic")

    _expect_ok(manager.add_item(CRITICAL_REWARD, 1), "critical discard setup")
    var critical_before: Dictionary = manager.export_snapshot()
    _expect_failure(manager.discard_item(CRITICAL_REWARD, 1), "critical item discard")
    _expect(manager.export_snapshot() == critical_before, "critical item was changed by discard")
    _expect_ok(manager.discard_item(MATERIAL, 1), "ordinary item discard")
    _expect_quantity(manager, MATERIAL, "backpack", 2, "ordinary item discard")

    for invalid_quantity: int in [0, -1]:
        var invalid_before: Dictionary = manager.export_snapshot()
        _expect_failure(manager.add_item(MATERIAL, invalid_quantity), "invalid add quantity %d" % invalid_quantity)
        _expect_failure(manager.remove_item(MATERIAL, invalid_quantity), "invalid remove quantity %d" % invalid_quantity)
        _expect_failure(manager.discard_item(MATERIAL, invalid_quantity), "invalid discard quantity %d" % invalid_quantity)
        _expect(manager.export_snapshot() == invalid_before, "invalid quantity %d changed inventory" % invalid_quantity)
    _expect(_quantity(manager, MATERIAL, "all") >= 0, "item quantity became negative")


func _test_capacity_and_custody() -> void:
    var full_context := _new_context("full_ordinary", 1)
    if full_context.is_empty():
        return
    var full_manager: RefCounted = full_context["inventory"]
    _expect_ok(full_manager.add_item(BODY_ARMOR, 1), "full backpack setup")
    _expect(full_manager.get_used_slots() == full_manager.get_capacity(), "backpack setup did not fill capacity")
    var full_before: Dictionary = full_manager.export_snapshot()
    _expect_failure(full_manager.add_item(MATERIAL, 1), "ordinary item into full backpack")
    _expect(full_manager.export_snapshot() == full_before, "failed full-backpack add was not atomic")

    _expect_ok(full_manager.add_item(CRITICAL_REWARD, 1), "critical reward overflow to custody")
    _expect_quantity(full_manager, CRITICAL_REWARD, "custody", 1, "critical reward custody overflow")
    _expect_quantity(full_manager, CRITICAL_REWARD, "backpack", 0, "critical reward should not enter a full backpack")
    _expect_ok(full_manager.discard_item(BODY_ARMOR, 1), "free capacity before custody claim")
    _expect_ok(full_manager.claim_custody_item(CRITICAL_REWARD, 1), "custody claim with capacity")
    _expect_quantity(full_manager, CRITICAL_REWARD, "custody", 0, "claimed custody quantity")
    _expect_quantity(full_manager, CRITICAL_REWARD, "backpack", 1, "claimed backpack quantity")

    var blocked_context := _new_context("custody_blocked", 1)
    if blocked_context.is_empty():
        return
    var blocked_manager: RefCounted = blocked_context["inventory"]
    _expect_ok(blocked_manager.add_item(BODY_ARMOR, 1), "blocked custody setup backpack")
    _expect_ok(blocked_manager.add_item(CRITICAL_REWARD, 1), "blocked custody setup reward")
    var custody_before: Dictionary = blocked_manager.export_snapshot()
    _expect_failure(blocked_manager.claim_custody_item(CRITICAL_REWARD, 1), "custody claim into full backpack")
    _expect(blocked_manager.export_snapshot() == custody_before, "failed custody claim lost or moved the item")
    _expect_quantity(blocked_manager, CRITICAL_REWARD, "custody", 1, "failed custody claim retention")

    var quest_context := _new_context("quest_storage", 1)
    if not quest_context.is_empty():
        var quest_manager: RefCounted = quest_context["inventory"]
        _expect_ok(quest_manager.add_item(BODY_ARMOR, 1), "quest storage capacity setup")
        _expect_ok(quest_manager.add_item(QUEST_ITEM, 1), "separate quest item storage")
        _expect_quantity(quest_manager, QUEST_ITEM, "quest", 1, "separate quest item storage")
        _expect(quest_manager.get_used_slots() == 1, "quest item consumed a normal backpack slot")


func _test_equipment_transactions_and_modifiers() -> void:
    var equip_context := _new_context("equip", 3)
    if equip_context.is_empty():
        return
    var manager: RefCounted = equip_context["inventory"]
    _expect_ok(manager.add_item(HEAD_GEAR, 1), "correct-slot equip setup")
    _expect_ok(manager.equip_item(HEAD_GEAR, "head"), "correct-slot equip")
    _expect(_equipped_item(manager, "head") == HEAD_GEAR, "correct-slot equipment was not installed")

    _expect_ok(manager.add_item(BODY_ARMOR, 1), "wrong-slot equip setup")
    var wrong_slot_before: Dictionary = manager.export_snapshot()
    _expect_failure(manager.equip_item(BODY_ARMOR, "weapon"), "wrong-slot equip")
    _expect(manager.export_snapshot() == wrong_slot_before, "wrong-slot equip was not atomic")

    var swap_context := _new_context("equip_swap", 1)
    if swap_context.is_empty():
        return
    var swap_manager: RefCounted = swap_context["inventory"]
    _expect_ok(swap_manager.add_item(RING_ALPHA, 1), "first ring setup")
    _expect_ok(swap_manager.equip_item(RING_ALPHA, "accessory_1"), "first ring equip")
    _expect_ok(swap_manager.add_item(RING_BETA, 1), "replacement ring setup")
    _expect_ok(swap_manager.equip_item(RING_BETA, "accessory_1"), "one-for-one equipment swap")
    _expect(_equipped_item(swap_manager, "accessory_1") == RING_BETA, "replacement ring was not equipped")
    _expect_quantity(swap_manager, RING_ALPHA, "backpack", 1, "old ring returned after swap")

    var two_hand_context := _new_context("two_hand_capacity", 1)
    if two_hand_context.is_empty():
        return
    var two_hand_manager: RefCounted = two_hand_context["inventory"]
    _expect_ok(two_hand_manager.add_item(ONE_HANDED_SWORD, 1), "one-handed setup")
    _expect_ok(two_hand_manager.equip_item(ONE_HANDED_SWORD, "weapon"), "one-handed equip")
    _expect_ok(two_hand_manager.add_item(SHIELD, 1), "shield setup")
    _expect_ok(two_hand_manager.equip_item(SHIELD, "off_hand"), "shield equip")
    _expect_ok(two_hand_manager.add_item(TWO_HANDED_SWORD, 1), "two-handed replacement setup")
    var two_hand_before: Dictionary = two_hand_manager.export_snapshot()
    _expect_failure(two_hand_manager.equip_item(TWO_HANDED_SWORD, "weapon"), "two-handed swap without room for both old items")
    _expect(two_hand_manager.export_snapshot() == two_hand_before, "failed two-handed swap was not atomic")
    _expect(_equipped_item(two_hand_manager, "weapon") == ONE_HANDED_SWORD, "failed two-handed swap changed weapon")
    _expect(_equipped_item(two_hand_manager, "off_hand") == SHIELD, "failed two-handed swap changed off-hand")

    var unequip_context := _new_context("unequip_capacity", 1)
    if unequip_context.is_empty():
        return
    var unequip_manager: RefCounted = unequip_context["inventory"]
    _expect_ok(unequip_manager.add_item(HEAD_GEAR, 1), "unequip setup head")
    _expect_ok(unequip_manager.equip_item(HEAD_GEAR, "head"), "unequip setup equip")
    _expect_ok(unequip_manager.add_item(BODY_ARMOR, 1), "unequip setup full backpack")
    var unequip_before: Dictionary = unequip_manager.export_snapshot()
    _expect_failure(unequip_manager.unequip_item("head"), "unequip without backpack capacity")
    _expect(unequip_manager.export_snapshot() == unequip_before, "failed unequip was not atomic")

    var modifier_context := _new_context("modifiers", 3)
    if modifier_context.is_empty():
        return
    var modifier_manager: RefCounted = modifier_context["inventory"]
    _expect_ok(modifier_manager.add_item(TWO_HANDED_SWORD, 1), "modifier weapon setup")
    _expect_ok(modifier_manager.equip_item(TWO_HANDED_SWORD, "weapon"), "modifier weapon equip")
    var modifiers_result: Dictionary = modifier_manager.get_stat_modifiers()
    _expect_ok(modifiers_result, "equipped stat modifier query")
    var expected_attack := _item_modifier(TWO_HANDED_SWORD, "attack")
    _expect(
        is_equal_approx(float(modifiers_result.get("modifiers", {}).get("attack", 0.0)), expected_attack),
        "equipped stat modifiers were not aggregated correctly",
    )
    _expect_ok(modifier_manager.unequip_item("weapon"), "modifier weapon unequip")
    var after_unequip: Dictionary = modifier_manager.get_stat_modifiers()
    _expect(is_zero_approx(float(after_unequip.get("modifiers", {}).get("attack", 0.0))), "unequipped item still contributed stat modifiers")


func _test_consumable_contexts() -> void:
    var context := _new_context("consumables", 3)
    if context.is_empty():
        return
    var game_state: RefCounted = context["game_state"]
    var manager: RefCounted = context["inventory"]
    _expect_ok(manager.add_item(FIELD_TONIC, 2), "field consumable setup")
    var health_before := int(game_state.get_state("test.inventory.health"))
    var allowed_context := _first_use_context(FIELD_TONIC)
    _expect_ok(manager.use_item(FIELD_TONIC, allowed_context), "consumable in an allowed scene")
    _expect_quantity(manager, FIELD_TONIC, "backpack", 1, "successful consumable use")
    _expect(int(game_state.get_state("test.inventory.health")) > health_before, "successful consumable did not apply its GameState effect")

    _expect_ok(manager.add_item(BATTLE_TONIC, 1), "restricted consumable setup")
    var denied_context := "field" if _first_use_context(BATTLE_TONIC) != "field" else "battle"
    var denied_before: Dictionary = manager.export_snapshot()
    var battle_flag_before: Variant = game_state.get_state("test.inventory.battle_buff")
    _expect_failure(manager.use_item(BATTLE_TONIC, denied_context), "consumable in a disallowed scene")
    _expect(manager.export_snapshot() == denied_before, "disallowed consumable use deducted inventory")
    _expect(game_state.get_state("test.inventory.battle_buff") == battle_flag_before, "disallowed consumable use applied its effect")

    var reentrant_context := _new_context("consumable_reentrancy", 3)
    if reentrant_context.is_empty():
        return
    var reentrant_state: RefCounted = reentrant_context["game_state"]
    var reentrant_inventory: RefCounted = reentrant_context["inventory"]
    _expect_ok(reentrant_inventory.add_item(FIELD_TONIC, 1), "reentrant consumable setup")
    var reentrant_results: Array = []
    var reentrant_callback := func(
        key: String, _old_value: Variant, _new_value: Variant, _source: String,
    ) -> void:
        if key == "test.inventory.health" and reentrant_results.is_empty():
            reentrant_results.append(reentrant_inventory.use_item(FIELD_TONIC, allowed_context))
    reentrant_state.state_changed.connect(reentrant_callback)
    var reentrant_health_before := int(reentrant_state.get_state("test.inventory.health"))
    _expect_ok(reentrant_inventory.use_item(FIELD_TONIC, allowed_context), "outer reentrant consumable use")
    _expect(reentrant_results.size() == 1, "GameState listener did not attempt the reentrant inventory write")
    if reentrant_results.size() == 1:
        _expect(
            str(reentrant_results[0].get("code", "")) == InventoryManagerClass.INVENTORY_MUTATION_IN_PROGRESS,
            "reentrant inventory write was not rejected with INVENTORY_MUTATION_IN_PROGRESS",
        )
    _expect_quantity(reentrant_inventory, FIELD_TONIC, "backpack", 0, "reentrant consumable final quantity")
    var expected_delta := int(_items_by_id[FIELD_TONIC]["runtime"]["use_effects"][0]["value"])
    _expect(
        int(reentrant_state.get_state("test.inventory.health")) == reentrant_health_before + expected_delta,
        "reentrant consumable applied its GameState effect more than once",
    )
    reentrant_state.state_changed.disconnect(reentrant_callback)


func _test_new_game_and_reset_are_empty() -> void:
    var first := _new_context("reset", 3)
    if first.is_empty():
        return
    var first_manager: RefCounted = first["inventory"]
    _expect_ok(first_manager.add_item(MATERIAL, 3), "reset inventory setup")
    _expect_ok(first_manager.add_item(HEAD_GEAR, 1), "reset equipment setup")
    _expect_ok(first_manager.equip_item(HEAD_GEAR, "head"), "reset equipped setup")
    _expect_ok(first_manager.reset_inventory(), "reset_inventory")
    _expect_inventory_empty(first_manager, "reset inventory")

    var second := _new_context("new_game", 3)
    if second.is_empty():
        return
    _expect_inventory_empty(second["inventory"], "new game")


func _test_definition_and_reward_guards() -> void:
    var restricted_states: Array = _state_definitions.duplicate(true)
    for raw_state: Variant in restricted_states:
        if raw_state is Dictionary and str(raw_state.get("key", "")) == "test.inventory.health":
            raw_state["write_sources"] = ["story"]
    var restricted_loader := FixtureContentLoader.new(restricted_states, _item_definitions)
    var restricted_game_state := GameStateClass.new()
    _expect(restricted_game_state.initialize_from_content_loader(restricted_loader), "restricted state fixture initialization")
    var restricted_inventory := InventoryManagerClass.new()
    _expect(
        not restricted_inventory.initialize(restricted_loader, restricted_game_state, 3),
        "InventoryManager accepted a use-effect state without inventory write permission",
    )

    var collision_items: Array = _item_definitions.duplicate(true)
    for raw_item: Variant in collision_items:
        if raw_item is Dictionary and str(raw_item.get("item_id", "")) == CRITICAL_REWARD:
            raw_item["runtime"]["ownership_state_key"] = "test.inventory.battle_buff"
    var collision_loader := FixtureContentLoader.new(_state_definitions, collision_items)
    var collision_game_state := GameStateClass.new()
    _expect(collision_game_state.initialize_from_content_loader(collision_loader), "ownership collision fixture initialization")
    var collision_inventory := InventoryManagerClass.new()
    _expect(
        not collision_inventory.initialize(collision_loader, collision_game_state, 3),
        "InventoryManager accepted a use effect targeting an ownership projection",
    )

    var context := _new_context("reward_type_guard", 3)
    if context.is_empty():
        return
    var invalid_reward := {
        "ok": true,
        "quest_id": "TEST_QUEST_REWARD_TYPE",
        "rewards": [{"type": "itmes", "reward_id": "typo_reward", "items": []}],
    }
    _expect_failure(context["inventory"].apply_quest_reward(invalid_reward), "unknown quest reward type")


func _new_context(case_name: String, capacity: int) -> Dictionary:
    var loader := FixtureContentLoader.new(_state_definitions, _item_definitions)
    var game_state := GameStateClass.new()
    if not game_state.initialize_from_content_loader(loader):
        _failures.append("GameState initialization failed for %s: %s" % [case_name, str(game_state.last_error)])
        return {}
    var manager := InventoryManagerClass.new()
    if not manager.initialize(loader, game_state, capacity):
        _failures.append("InventoryManager initialization failed for %s: %s" % [case_name, str(manager.last_error)])
        return {}
    return {"loader": loader, "game_state": game_state, "inventory": manager}


func _expect_fixture_ids() -> void:
    for item_id: String in [
        FIELD_TONIC, BATTLE_TONIC, MATERIAL, QUEST_ITEM, CRITICAL_REWARD,
        ONE_HANDED_SWORD, TWO_HANDED_SWORD, SHIELD, HEAD_GEAR, BODY_ARMOR,
        RING_ALPHA, RING_BETA,
    ]:
        _expect(_items_by_id.has(item_id), "inventory fixture is missing %s" % item_id)


func _stack_limit(item_id: String) -> int:
    return int(_items_by_id.get(item_id, {}).get("stack_limit", 1))


func _first_use_context(item_id: String) -> String:
    var declared := str(_items_by_id.get(item_id, {}).get("runtime", {}).get("use_context", ""))
    match declared:
        "field_only":
            return "field"
        "battle_only":
            return "battle"
        "both":
            return "field"
    _failures.append("%s has no supported runtime.use_context fixture value" % item_id)
    return ""


func _item_modifier(item_id: String, stat: String) -> float:
    for raw_modifier: Variant in _items_by_id.get(item_id, {}).get("runtime", {}).get("stat_modifiers", []):
        if raw_modifier is Dictionary and str(raw_modifier.get("stat", "")) == stat:
            return float(raw_modifier.get("value", 0.0))
    _failures.append("%s has no %s stat modifier" % [item_id, stat])
    return 0.0


func _stack_quantities(manager: RefCounted, item_id: String) -> Array[int]:
    var result: Dictionary = manager.get_backpack_contents()
    _expect_ok(result, "backpack contents query")
    var quantities: Array[int] = []
    for raw_entry: Variant in result.get("items", []):
        if raw_entry is Dictionary and str(raw_entry.get("item_id", "")) == item_id:
            quantities.append(int(raw_entry.get("quantity", 0)))
    quantities.sort()
    return quantities


func _equipped_item(manager: RefCounted, slot: String) -> String:
    var result: Dictionary = manager.get_equipment()
    _expect_ok(result, "equipment query")
    var value: Variant = result.get("equipment", {}).get(slot, null)
    if value is Dictionary:
        return str(value.get("item_id", ""))
    return "" if value == null else str(value)


func _quantity(manager: RefCounted, item_id: String, scope: String) -> int:
    var result: Dictionary = manager.get_item_quantity(item_id, scope)
    _expect_ok(result, "quantity query for %s in %s" % [item_id, scope])
    return int(result.get("quantity", -1))


func _expect_quantity(manager: RefCounted, item_id: String, scope: String, expected: int, label: String) -> void:
    var actual := _quantity(manager, item_id, scope)
    _expect(actual == expected, "%s quantity was %d instead of %d" % [label, actual, expected])


func _expect_inventory_empty(manager: RefCounted, label: String) -> void:
    var backpack: Dictionary = manager.get_backpack_contents()
    var quest_items: Dictionary = manager.get_quest_item_contents()
    var custody: Dictionary = manager.get_custody_contents()
    var equipment: Dictionary = manager.get_equipment()
    _expect_ok(backpack, "%s backpack query" % label)
    _expect_ok(quest_items, "%s quest storage query" % label)
    _expect_ok(custody, "%s custody query" % label)
    _expect_ok(equipment, "%s equipment query" % label)
    _expect(backpack.get("items", []).is_empty(), "%s backpack is not empty" % label)
    _expect(quest_items.get("items", []).is_empty(), "%s quest storage is not empty" % label)
    _expect(custody.get("items", []).is_empty(), "%s custody is not empty" % label)
    for equipped: Variant in equipment.get("equipment", {}).values():
        _expect(equipped == null or str(equipped).is_empty(), "%s equipment is not empty" % label)
    _expect(manager.get_used_slots() == 0, "%s used slot count is not zero" % label)


func _expect_ok(result: Dictionary, label: String) -> void:
    _expect(bool(result.get("ok", false)), "%s failed: %s" % [label, str(result)])


func _expect_failure(result: Dictionary, label: String) -> void:
    _expect(not bool(result.get("ok", true)), "%s unexpectedly succeeded" % label)
    _expect(not str(result.get("code", "")).is_empty(), "%s did not return an error code" % label)


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


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
