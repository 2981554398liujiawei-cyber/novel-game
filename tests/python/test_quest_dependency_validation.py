from __future__ import annotations

import unittest

from tools.validate_repository import validate_quest_dependency_graph


class QuestDependencyValidationTests(unittest.TestCase):
    def test_acyclic_graph_is_valid(self) -> None:
        document = {
            "quests": [
                {"quest_id": "TEST_QUEST_A", "depends_on": []},
                {"quest_id": "TEST_QUEST_B", "depends_on": ["TEST_QUEST_A"]},
                {"quest_id": "TEST_QUEST_C", "depends_on": ["TEST_QUEST_B"]},
            ]
        }
        self.assertEqual([], validate_quest_dependency_graph(document))

    def test_duplicate_owner_edge_and_self_dependency_are_rejected(self) -> None:
        document = {
            "quests": [
                {
                    "quest_id": "TEST_QUEST_A",
                    "depends_on": ["TEST_QUEST_B", "TEST_QUEST_B", "TEST_QUEST_A"],
                },
                {"quest_id": "TEST_QUEST_A", "depends_on": []},
            ]
        }
        errors = validate_quest_dependency_graph(document)
        self.assertIn("Duplicate quest dependency owner: TEST_QUEST_A", errors)
        self.assertIn("Quest 'TEST_QUEST_A' repeats dependency 'TEST_QUEST_B'", errors)
        self.assertIn("Quest dependency self-cycle: TEST_QUEST_A", errors)

    def test_multi_quest_cycle_is_rejected(self) -> None:
        document = {
            "quests": [
                {"quest_id": "TEST_QUEST_A", "depends_on": ["TEST_QUEST_B"]},
                {"quest_id": "TEST_QUEST_B", "depends_on": ["TEST_QUEST_C"]},
                {"quest_id": "TEST_QUEST_C", "depends_on": ["TEST_QUEST_A"]},
            ]
        }
        self.assertEqual(
            ["Quest dependency cycle: TEST_QUEST_A -> TEST_QUEST_B -> TEST_QUEST_C -> TEST_QUEST_A"],
            validate_quest_dependency_graph(document),
        )


if __name__ == "__main__":
    unittest.main()
