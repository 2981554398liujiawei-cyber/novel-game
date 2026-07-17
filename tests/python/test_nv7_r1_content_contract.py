from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
QUEST_IDS = [f"NV_MAIN_{index:03d}" for index in range(1, 5)]


def load_json(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def runtime_projection(value):
    if isinstance(value, dict):
        return {
            key: runtime_projection(item)
            for key, item in value.items()
            if key not in {"source_chapters", "source_refs", "source_trace", "foreshadowing_refs"}
        }
    if isinstance(value, list):
        return [runtime_projection(item) for item in value]
    return value


class Nv7R1ContentContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.quests = {
            quest_id: load_json(f"content/quests/nv7/{quest_id.lower()}.json")
            for quest_id in QUEST_IDS
        }

    def test_only_r1_tasks_are_runtime_loaded(self) -> None:
        manifest = load_json("content/manifest.json")
        loaded = [
            entry["content_id"]
            for entry in manifest["planned_content"]
            if entry["status"] == "data_ready"
        ]
        self.assertEqual(QUEST_IDS, loaded)
        self.assertEqual("NV_MAIN_001", manifest["entry_story_id"])

    def test_story_chain_is_continuous_through_r1(self) -> None:
        expected_next = QUEST_IDS[1:] + [None]
        for quest_id, next_story_id in zip(QUEST_IDS, expected_next, strict=True):
            complete_nodes = [n for n in self.quests[quest_id]["nodes"] if n["type"] == "complete"]
            self.assertEqual(1, len(complete_nodes), quest_id)
            self.assertEqual(next_story_id, complete_nodes[0].get("next_story_id"), quest_id)

    def test_three_commission_gate_preserves_qualified_semantics(self) -> None:
        dependencies = load_json("content/quest_dependencies.json")
        by_id = {entry["quest_id"]: entry for entry in dependencies["quests"]}
        commission = self.quests["NV_MAIN_002"]["runtime"]
        objectives = {entry["objective_id"]: entry for entry in commission["objectives"]}
        self.assertEqual({"hanshi", "suzhi", "guchangchuan"}, set(objectives))
        self.assertEqual(2, commission["qualification"]["required_count"])
        self.assertTrue(all(entry.get("required", False) for entry in objectives.values()))
        self.assertIn("qualified", json.dumps(by_id["NV_MAIN_003"], ensure_ascii=False))

    def test_rabbit_routes_and_wolf_battle_have_failure_continuations(self) -> None:
        combat_nodes = {
            node["combat_ref"]: node
            for quest in self.quests.values()
            for node in quest["nodes"]
            if node["type"] == "combat"
        }
        for combat_id in [
            "NV7_COMBAT_RABBIT_GUARDS",
            "NV7_COMBAT_POACHERS",
            "NV7_COMBAT_DUDU_RABBIT",
            "NV7_COMBAT_WOLF_KING",
        ]:
            node = combat_nodes[combat_id]
            self.assertTrue(node["next_on_win"])
            self.assertTrue(node["next_on_loss"])

    def test_all_formal_references_resolve(self) -> None:
        catalogs = {
            "combat_ref": {x["combat_id"] for x in load_json("content/combats/combats.json")["combats"]},
            "speaker_id": {x["npc_id"] for x in load_json("content/npcs/npcs.json")["npcs"]}
            | {"PROTAGONIST_FENGYUE"},
            "location_id": {x["location_id"] for x in load_json("content/locations/locations.json")["locations"]},
        }
        for quest in self.quests.values():
            for node in quest["nodes"]:
                for field, known_ids in catalogs.items():
                    if node.get(field):
                        self.assertIn(node[field], known_ids, f"{quest['quest_id']}:{node['node_id']}:{field}")

    def test_relationship_actions_use_registered_dimensions_or_flags(self) -> None:
        relationships = load_json("content/relationships/relationships.json")
        registered = {entry["relationship_id"]: entry for entry in relationships["relationships"]}
        allowed_dimensions = {"trust", "affection", "respect", "tension"}
        for quest in self.quests.values():
            for node in quest["nodes"]:
                for action in node.get("relationship_actions", []):
                    definition = registered[action["relationship_id"]]
                    action_type = action.get("action", action.get("op", ""))
                    if action_type in {"inc", "dec", "set"} and "dimension" in action:
                        self.assertIn(action["dimension"], allowed_dimensions)
                    elif action_type == "set_flag":
                        self.assertIn(action["flag_id"], {x["id"] for x in definition["flags"]})
                    elif action_type == "set_boundary":
                        self.assertIn(action["boundary_id"], {x["id"] for x in definition["boundaries"]})

    def test_generated_runtime_matches_normalized_ir(self) -> None:
        ignored = {"source_chapters", "source_refs", "source_trace"}
        for quest_id in QUEST_IDS:
            ir = load_json(f"docs/story/generated/nv7/R1/{quest_id}.ir.json")["quest"]
            runtime = self.quests[quest_id]
            self.assertEqual("data_ready", runtime["content_status"])
            self.assertEqual(ir["quest_id"], runtime["quest_id"])
            self.assertEqual(ir["entry_node"], runtime["entry_node"])
            self.assertEqual(runtime_projection(ir["nodes"]), runtime["nodes"])
            self.assertTrue(ignored.isdisjoint(runtime))

    def test_approval_notes_and_status_are_human_readable(self) -> None:
        for quest_id in QUEST_IDS:
            approval = load_json(f"docs/story/approvals/nv7/R1/{quest_id}.approval.json")
            self.assertEqual("approved", approval["status"])
            self.assertNotIn("????", approval["notes"])
            self.assertIn("机械结构化", approval["notes"])


if __name__ == "__main__":
    unittest.main()
