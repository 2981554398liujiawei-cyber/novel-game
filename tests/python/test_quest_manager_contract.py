from __future__ import annotations

import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


REPO_ROOT = Path(__file__).resolve().parents[2]
FIXTURE_ROOT = REPO_ROOT / "content/tests/fixtures/quest_manager"
QUEST_FIXTURE_PATH = FIXTURE_ROOT / "quests.json"
STATE_FIXTURE_PATH = FIXTURE_ROOT / "state_registry.json"

QUEST_STATUSES = {
    "not_started",
    "available",
    "active",
    "qualified",
    "completed",
    "failed",
    "suspended",
}
OBJECTIVE_TYPES = {
    "boolean",
    "counter",
    "collection",
    "combat_result",
    "state_condition",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class QuestManagerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.quest_schema = load_json(REPO_ROOT / "schemas/quest.schema.json")
        cls.quest_fixture = load_json(QUEST_FIXTURE_PATH)
        cls.state_fixture = load_json(STATE_FIXTURE_PATH)
        cls.quests = cls.quest_fixture["quests"]
        cls.quests_by_id = {quest["quest_id"]: quest for quest in cls.quests}
        cls.states_by_key = {state["key"]: state for state in cls.state_fixture["states"]}

    def test_every_quest_is_a_complete_quest_schema_document(self):
        validator = Draft202012Validator(self.quest_schema)
        self.assertEqual(3, len(self.quests))
        self.assertEqual(len(self.quests), len(self.quests_by_id))
        for quest in self.quests:
            errors = sorted(validator.iter_errors(quest), key=lambda item: list(item.path))
            self.assertEqual(
                [],
                [error.message for error in errors],
                msg=f"{quest.get('quest_id')} must satisfy quest.schema.json",
            )

    def test_state_fixture_matches_registry_schema(self):
        schema = load_json(REPO_ROOT / "schemas/state_registry.schema.json")
        errors = sorted(
            Draft202012Validator(schema).iter_errors(self.state_fixture),
            key=lambda item: list(item.path),
        )
        self.assertEqual([], [error.message for error in errors])
        self.assertEqual(len(self.state_fixture["states"]), len(self.states_by_key))

    def test_formal_manifest_cannot_load_quest_manager_fixtures(self):
        manifest = load_json(REPO_ROOT / "content/manifest.json")
        normalized_paths = [path.replace("\\", "/").lower() for path in manifest["content_files"]]
        self.assertFalse(any("tests/fixtures" in path for path in normalized_paths))
        self.assertFalse(any("quest_manager" in path for path in normalized_paths))

    def test_fixture_is_strictly_synthetic(self):
        self.assertTrue(all(quest_id.startswith("TEST_QUEST_") for quest_id in self.quests_by_id))
        serialized = json.dumps(self.quest_fixture, ensure_ascii=False)
        forbidden_tokens = [
            "NV_MAIN_",
            "NV_SIDE_",
            "NV7_NPC_",
            "NV7_ITEM_",
            "NV7_ENEMY_",
            "韩石",
            "苏芷",
            "顾长川",
            "岚音",
            "枫月",
        ]
        for token in forbidden_tokens:
            self.assertNotIn(token, serialized)

    def test_runtime_has_registered_persistent_game_state_keys(self):
        for quest in self.quests:
            runtime = quest["runtime"]
            self.assertEqual(
                {
                    "status_state_key",
                    "reward_granted_state_key",
                    "availability",
                    "objectives",
                    "completion_mode",
                    "failure",
                },
                {
                    key
                    for key in runtime
                    if key != "qualification"
                },
            )
            managed_keys = [
                runtime["status_state_key"],
                runtime["reward_granted_state_key"],
                runtime["failure"]["continuation_state_key"],
            ]
            managed_keys.extend(
                objective["progress_state_key"]
                for objective in runtime["objectives"]
                if objective["type"] != "state_condition"
            )
            for key in managed_keys:
                self.assertIn(key, self.states_by_key)
                state = self.states_by_key[key]
                self.assertTrue(state["persistent"])
                self.assertEqual(["quest"], state.get("write_sources"))

            status_state = self.states_by_key[runtime["status_state_key"]]
            self.assertEqual("string", status_state["type"])
            self.assertEqual("not_started", status_state["default"])
            self.assertEqual(QUEST_STATUSES, set(status_state["allowed"]))

            reward_state = self.states_by_key[runtime["reward_granted_state_key"]]
            self.assertEqual("boolean", reward_state["type"])
            self.assertIs(False, reward_state["default"])

    def test_all_objective_types_have_a_fixture_contract(self):
        found_types = {
            objective["type"]
            for quest in self.quests
            for objective in quest["runtime"]["objectives"]
        }
        self.assertEqual(OBJECTIVE_TYPES, found_types)

        unlocked = self.quests_by_id["TEST_QUEST_UNLOCKED"]
        unlocked_types = {objective["type"] for objective in unlocked["runtime"]["objectives"]}
        self.assertEqual(OBJECTIVE_TYPES, unlocked_types)

    def test_objective_progress_contract_is_absolute_bounded_and_monotonic(self):
        progress_keys: set[str] = set()
        for quest in self.quests:
            objective_ids: set[str] = set()
            for objective in quest["runtime"]["objectives"]:
                objective_id = objective["objective_id"]
                self.assertNotIn(objective_id, objective_ids)
                objective_ids.add(objective_id)
                objective_type = objective["type"]
                if objective_type == "state_condition":
                    condition = objective["condition"]
                    self.assertIn(condition["key"], self.states_by_key)
                    continue

                progress_key = objective["progress_state_key"]
                self.assertNotIn(progress_key, progress_keys)
                progress_keys.add(progress_key)
                state = self.states_by_key[progress_key]
                target = objective["target"]

                if objective_type == "boolean":
                    self.assertEqual("boolean", state["type"])
                    self.assertIs(False, state["default"])
                    self.assertIs(True, target)
                elif objective_type in {"counter", "collection"}:
                    self.assertEqual("integer", state["type"])
                    self.assertEqual(0, state["default"])
                    self.assertEqual(0, state["min"])
                    self.assertEqual(target, state["max"])
                    self.assertGreater(target, 0)
                elif objective_type == "combat_result":
                    self.assertEqual("string", state["type"])
                    self.assertEqual("", state["default"])
                    self.assertIn(target, objective["allowed_results"])
                    self.assertTrue(set(objective["allowed_results"]).issubset(state["allowed"]))

        test_cases = [case for quest in self.quests for case in quest["test_cases"]]
        self.assertTrue(any("monotonic" in expected for case in test_cases for expected in case["expected"]))

    def test_parallel_qualification_and_unlock_contract(self):
        parallel = self.quests_by_id["TEST_QUEST_PARALLEL"]
        parallel_runtime = parallel["runtime"]
        self.assertEqual(3, len(parallel_runtime["qualification"]["objective_ids"]))
        self.assertEqual(2, parallel_runtime["qualification"]["required_count"])
        self.assertTrue(parallel_runtime["availability"]["all"])
        self.assertGreaterEqual(len(parallel_runtime["availability"]["any"]), 2)

        unlocked = self.quests_by_id["TEST_QUEST_UNLOCKED"]
        quest_conditions = [
            condition
            for condition in unlocked["runtime"]["availability"]["all"]
            if condition["kind"] == "quest"
        ]
        self.assertEqual(1, len(quest_conditions))
        self.assertEqual("TEST_QUEST_PARALLEL", quest_conditions[0]["quest_id"])
        self.assertEqual("in", quest_conditions[0]["op"])
        self.assertEqual({"qualified", "completed"}, set(quest_conditions[0]["value"]))

    def test_failure_recovery_and_reward_idempotency_markers_are_data_driven(self):
        recovery = self.quests_by_id["TEST_QUEST_RECOVERY"]
        failure = recovery["runtime"]["failure"]
        self.assertEqual({"retry_route", "alternate_route"}, set(failure["allowed_continuations"]))
        self.assertEqual("active", failure["resume_from_failed"])
        self.assertEqual("active", failure["resume_from_suspended"])
        self.assertTrue(failure["reopen_allowed"])
        self.assertEqual(["TEST_QUEST_UNLOCKED"], recovery["mutual_exclusions"])

        reward_keys = [quest["runtime"]["reward_granted_state_key"] for quest in self.quests]
        self.assertEqual(len(reward_keys), len(set(reward_keys)))
        for key in reward_keys:
            self.assertIs(False, self.states_by_key[key]["default"])


if __name__ == "__main__":
    unittest.main()
