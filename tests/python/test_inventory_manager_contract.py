from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator

from tools.validate_repository import validate_item_registry


REPO_ROOT = Path(__file__).resolve().parents[2]
FIXTURE_ROOT = REPO_ROOT / "content/tests/fixtures/inventory_manager"

RUNTIME_TYPES = {"consumable", "equipment", "quest", "material", "key_item"}
EQUIPMENT_SLOTS = {"weapon", "off_hand", "head", "body", "accessory_1", "accessory_2"}
FORMAL_ITEM_IDS = {
    "NV7_ITEM_RABBIT_MASK",
    "NV7_ITEM_POACHER_LEDGER",
    "NV7_ITEM_RABBIT_HIDE",
    "NV7_ITEM_NOVICE_SWORD",
    "NV7_ITEM_NOVICE_SHIELD",
    "NV7_ITEM_NOVICE_HOOK_STAFF",
    "NV7_ITEM_BLUE_POWDER_SAMPLE",
    "NV7_ITEM_BOUNDARY_RUBBING",
    "NV7_ITEM_NOVICE_MEDKIT",
    "NV7_ITEM_TREASURE_MAP_FRAGMENT",
    "NV7_ITEM_SILVERBLACK_FRAGMENT",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class InventoryManagerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.item_schema = load_json(REPO_ROOT / "schemas/item.schema.json")
        cls.quest_schema = load_json(REPO_ROOT / "schemas/quest.schema.json")
        cls.state_schema = load_json(REPO_ROOT / "schemas/state_registry.schema.json")
        cls.formal_items = load_json(REPO_ROOT / "content/items/items.json")
        cls.formal_states = load_json(REPO_ROOT / "content/states/state_registry.json")
        cls.fixture_items = load_json(FIXTURE_ROOT / "items.json")
        cls.fixture_states = load_json(FIXTURE_ROOT / "state_registry.json")
        cls.quest_fixture = load_json(REPO_ROOT / "content/tests/fixtures/quest_manager/quests.json")
        cls.fixture_by_id = {item["item_id"]: item for item in cls.fixture_items["items"]}

    def assert_schema_valid(self, schema, document, label):
        errors = sorted(Draft202012Validator(schema).iter_errors(document), key=lambda item: list(item.path))
        self.assertEqual([], [error.message for error in errors], msg=label)

    def test_formal_and_fixture_item_registries_match_schema_and_semantics(self):
        self.assert_schema_valid(self.item_schema, self.formal_items, "formal items")
        self.assert_schema_valid(self.item_schema, self.fixture_items, "inventory fixture items")
        self.assertEqual([], validate_item_registry(self.formal_items, self.formal_states))
        self.assertEqual([], validate_item_registry(self.fixture_items, self.fixture_states))

    def test_optional_runtime_preserves_legacy_item_documents(self):
        legacy = copy.deepcopy(self.formal_items)
        legacy["schema_version"] = "1.3.0"
        for item in legacy["items"]:
            item.pop("runtime")
        self.assert_schema_valid(self.item_schema, legacy, "legacy item registry without runtime")
        self.assertEqual([], validate_item_registry(legacy, self.formal_states))

    def test_formal_item_identity_set_is_unchanged(self):
        self.assertEqual(FORMAL_ITEM_IDS, {item["item_id"] for item in self.formal_items["items"]})
        self.assertEqual("1.4.0", self.formal_items["schema_version"])
        self.assertTrue(all("runtime" in item for item in self.formal_items["items"]))

    def test_fixture_covers_every_runtime_type_and_only_test_ids(self):
        self.assertEqual(
            RUNTIME_TYPES,
            {item["runtime"]["type"] for item in self.fixture_items["items"]},
        )
        self.assertTrue(self.fixture_items["items"])
        self.assertTrue(all(item["item_id"].startswith("TEST_ITEM_") for item in self.fixture_items["items"]))
        self.assertTrue(any(item["runtime"]["stackable"] for item in self.fixture_items["items"]))
        self.assertTrue(any(not item["runtime"]["stackable"] for item in self.fixture_items["items"]))
        self.assertTrue(any(item["runtime"]["unique"] for item in self.fixture_items["items"]))
        self.assertTrue(any(item["runtime"]["quest_critical"] for item in self.fixture_items["items"]))

    def test_fixture_covers_all_six_slots_accessory_compatibility_and_two_handed_occupancy(self):
        equipment = [
            item["runtime"]
            for item in self.fixture_items["items"]
            if item["runtime"]["type"] == "equipment"
        ]
        self.assertEqual(EQUIPMENT_SLOTS, {runtime["equipment_slot"] for runtime in equipment})

        for item_id in ["TEST_ITEM_RING_ALPHA", "TEST_ITEM_RING_BETA"]:
            self.assertEqual(
                {"accessory_1", "accessory_2"},
                set(self.fixture_by_id[item_id]["runtime"]["compatible_slots"]),
            )
        self.assertEqual(
            {"weapon", "off_hand"},
            set(self.fixture_by_id["TEST_ITEM_TWO_HANDED_SWORD"]["runtime"]["occupies_slots"]),
        )
        self.assertEqual(
            ["weapon"],
            self.fixture_by_id["TEST_ITEM_ONE_HANDED_SWORD"]["runtime"]["occupies_slots"],
        )
        self.assertTrue(any(runtime["stat_modifiers"] for runtime in equipment))

    def test_consumable_contexts_and_effect_states_are_registered_for_inventory(self):
        consumables = {
            item["runtime"]["use_context"]: item
            for item in self.fixture_items["items"]
            if item["runtime"]["type"] == "consumable"
        }
        self.assertIn("field_only", consumables)
        self.assertIn("battle_only", consumables)
        state_by_key = {state["key"]: state for state in self.fixture_states["states"]}
        self.assert_schema_valid(self.state_schema, self.fixture_states, "inventory effect state fixture")
        for item in consumables.values():
            for effect in item["runtime"]["use_effects"]:
                self.assertIn(effect["key"], state_by_key)
                self.assertEqual(["inventory"], state_by_key[effect["key"]].get("write_sources"))
        battle_tonic = self.fixture_by_id["TEST_ITEM_BATTLE_TONIC"]["runtime"]
        self.assertEqual([{"effect": "heal", "value": 15}], battle_tonic["combat_effects"])

    def test_parallel_quest_item_bundle_matches_quest_schema_and_references_fixture(self):
        quest_validator = Draft202012Validator(self.quest_schema)
        for quest in self.quest_fixture["quests"]:
            errors = sorted(quest_validator.iter_errors(quest), key=lambda item: list(item.path))
            self.assertEqual([], [error.message for error in errors], msg=quest["quest_id"])

        parallel = next(
            quest for quest in self.quest_fixture["quests"] if quest["quest_id"] == "TEST_QUEST_PARALLEL"
        )
        self.assertEqual(
            [
                {
                    "type": "items",
                    "reward_id": "parallel_reward",
                    "items": [{"item_id": "TEST_ITEM_CRITICAL_REWARD", "quantity": 1}],
                }
            ],
            parallel["rewards"],
        )
        for reward in parallel["rewards"]:
            for entry in reward["items"]:
                self.assertIn(entry["item_id"], self.fixture_by_id)
                self.assertGreater(entry["quantity"], 0)
                runtime = self.fixture_by_id[entry["item_id"]]["runtime"]
                self.assertTrue(runtime["quest_critical"])
                self.assertEqual("custody", runtime["overflow_policy"])

    def test_item_bundle_schema_rejects_non_positive_quantity(self):
        invalid = copy.deepcopy(self.quest_fixture["quests"][0])
        invalid["rewards"][0]["items"][0]["quantity"] = 0
        errors = list(Draft202012Validator(self.quest_schema).iter_errors(invalid))
        self.assertTrue(errors)

    def test_quest_reward_schema_rejects_missing_or_unknown_types(self):
        validator = Draft202012Validator(self.quest_schema)
        for invalid_reward in [{}, {"type": "itmes", "reward_id": "typo_reward", "items": []}]:
            invalid = copy.deepcopy(self.quest_fixture["quests"][0])
            invalid["rewards"] = [invalid_reward]
            self.assertTrue(list(validator.iter_errors(invalid)), msg=invalid_reward)

    def test_semantic_validator_rejects_cross_field_and_reference_errors(self):
        invalid = copy.deepcopy(self.fixture_items)
        invalid_by_id = {item["item_id"]: item for item in invalid["items"]}
        invalid_by_id["TEST_ITEM_FIELD_TONIC"]["runtime"]["max_stack"] = 21
        invalid_by_id["TEST_ITEM_TWO_HANDED_SWORD"]["runtime"]["occupies_slots"] = ["weapon", "head"]
        invalid_by_id["TEST_ITEM_TWO_HANDED_SWORD"]["runtime"]["combat_effects"] = [
            {"effect": "heal", "value": 1}
        ]
        critical = invalid_by_id["TEST_ITEM_CRITICAL_REWARD"]["runtime"]
        critical["sellable"] = True
        critical["overflow_policy"] = "reject"
        critical["ownership_state_key"] = "test.inventory.unknown"
        errors = validate_item_registry(invalid, self.fixture_states)
        self.assertTrue(any("consumable max_stack exceeds 20" in error for error in errors))
        self.assertTrue(any("multi-slot equipment" in error for error in errors))
        self.assertTrue(any("only consumables may declare combat effects" in error for error in errors))
        self.assertTrue(any("cannot be sold or discarded" in error for error in errors))
        self.assertTrue(any("must overflow to custody" in error for error in errors))
        self.assertTrue(any("unknown ownership state" in error for error in errors))

        wrong_state_type = copy.deepcopy(self.fixture_items)
        wrong_state_type_by_id = {item["item_id"]: item for item in wrong_state_type["items"]}
        wrong_state_type_by_id["TEST_ITEM_CRITICAL_REWARD"]["runtime"]["ownership_state_key"] = (
            "test.inventory.health"
        )
        type_errors = validate_item_registry(wrong_state_type, self.fixture_states)
        self.assertTrue(any("must be boolean" in error for error in type_errors))

        restricted_states = copy.deepcopy(self.fixture_states)
        restricted_by_key = {state["key"]: state for state in restricted_states["states"]}
        restricted_by_key["test.inventory.health"]["write_sources"] = ["story"]
        permission_errors = validate_item_registry(self.fixture_items, restricted_states)
        self.assertTrue(any("does not allow inventory writes" in error for error in permission_errors))

        ownership_effect_collision = copy.deepcopy(self.fixture_items)
        collision_by_id = {item["item_id"]: item for item in ownership_effect_collision["items"]}
        collision_by_id["TEST_ITEM_CRITICAL_REWARD"]["runtime"]["ownership_state_key"] = (
            "test.inventory.battle_buff"
        )
        collision_errors = validate_item_registry(ownership_effect_collision, self.fixture_states)
        self.assertTrue(any("cannot modify ownership state" in error for error in collision_errors))

    def test_fixture_paths_are_excluded_from_formal_manifest(self):
        manifest = load_json(REPO_ROOT / "content/manifest.json")
        paths = [path.replace("\\", "/").lower() for path in manifest["content_files"]]
        self.assertFalse(any("tests/fixtures" in path for path in paths))
        self.assertFalse(any("inventory_manager" in path for path in paths))

    def test_content_loader_exposes_item_lookup_contract(self):
        source = (REPO_ROOT / "src/core/content_loader.gd").read_text(encoding="utf-8")
        self.assertIn("func get_item(item_id: String) -> Variant:", source)
        self.assertIn("func get_item_definitions() -> Array:", source)


if __name__ == "__main__":
    unittest.main()
