from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
R1_IDS = [f"NV_MAIN_{index:03d}" for index in range(1, 5)]


def load_json(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


class Nv7R1ReviewContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.quests = {
            quest_id: load_json(f"content/quests/nv7/{quest_id.lower()}.json")
            for quest_id in R1_IDS
        }

    def test_content_review_queue_is_closed_without_faking_manual_verification(self) -> None:
        review = (ROOT / "docs/story/reviews/nv7/R1_content_review_required.md").read_text(encoding="utf-8")
        self.assertIn("CONTENT_REVIEW_REQUIRED：**0**", review)
        self.assertIn("真人完整游玩记录：尚未提供", review)
        for issue_id in ["R1-CR-001", "R1-CR-002", "R1-CR-003", "R1-CR-004"]:
            self.assertIn(issue_id, review)
        self.assertEqual(4, review.count("关闭结论：**CLOSED"))

    def test_r1_is_ready_for_manual_verification_but_not_verified(self) -> None:
        region = load_json("docs/story/scripts/nv7/region_manifest.json")
        self.assertTrue(all(x["status"] == "READY_FOR_MANUAL_VERIFICATION" for x in region["tasks"][:4]))
        self.assertTrue(all(x["status"] == "SOURCE_ONLY" for x in region["tasks"][4:]))
        self.assertTrue(all(q["content_status"] == "data_ready" for q in self.quests.values()))

    def test_manual_playtest_template_captures_repeatable_timing(self) -> None:
        template = (ROOT / "docs/story/reviews/nv7/R1_manual_playtest_template.md").read_text(encoding="utf-8")
        for field in [
            "开始时间（含时区）", "结束时间（含时区）", "阅读速度设置", "是否跳过逐字显示",
            "战斗次数", "战败次数", "打开任务页次数", "总时长", "构建提交 SHA",
        ]:
            self.assertIn(field, template)
        self.assertIn("90—135 分钟", template)

    def test_r2_entry_contract_lists_every_frozen_state_domain(self) -> None:
        contract = (ROOT / "docs/story/reviews/nv7/R2_entry_contract.md").read_text(encoding="utf-8")
        required = [
            "quest.nv_main_001.status", "quest.nv_main_002.status", "quest.nv_main_003.status",
            "quest.nv_main_004.status", "world.nv7.rabbit_king_outcome",
            "world.nv7.live_capture_evidence", "world.nv7.poacher_exposed",
            "world.nv7.wolf_king_outcome", "NV7_REL_FENGYUE_LANYIN",
            "NV7_REL_FENGYUE_TIANHUOLENGHUN", "NV7_ITEM_TREASURE_MAP_FRAGMENT",
            "RETURN_CHANNEL", "PLAYERS_TRAPPED", "LIVE_CREATURE_PURCHASE",
            "SILVER_BLACK_SYSTEM_MATERIAL",
        ]
        for value in required:
            self.assertIn(value, contract)
        self.assertIn("不得覆盖", contract)
        self.assertIn("不得重发", contract)

    def test_required_foreshadowing_points_to_existing_r1_nodes(self) -> None:
        registry = load_json("docs/story/foreshadowing_registry.json")
        entries = {x["foreshadowing_id"]: x for x in registry["entries"]}
        node_ids = {
            quest_id: {node["node_id"] for node in quest["nodes"]}
            for quest_id, quest in self.quests.items()
        }
        for foreshadowing_id in [
            "RETURN_CHANNEL", "PLAYERS_TRAPPED", "LIVE_CREATURE_PURCHASE", "SILVER_BLACK_SYSTEM_MATERIAL",
        ]:
            entry = entries[foreshadowing_id]
            self.assertEqual("reinforced", entry["status"])
            self.assertTrue(entry["reinforcement_nodes"])
            for reference in [entry["first_appearance"], *entry["reinforcement_nodes"]]:
                quest_id, node_id = reference.split(":", 1)
                self.assertIn(node_id, node_ids[quest_id], f"{foreshadowing_id}:{reference}")

    def test_story_effects_respect_manager_ownership(self) -> None:
        allowed_dimensions = {"trust", "affection", "respect", "tension"}
        for quest in self.quests.values():
            for node in quest["nodes"]:
                for effect in node.get("effects", []):
                    self.assertFalse(effect.get("key", "").startswith(("quest.", "relation.", "inventory.", "item.")))
                for action in node.get("relationship_actions", []):
                    if "dimension" in action:
                        self.assertIn(action["dimension"], allowed_dimensions)
                if node["type"] == "combat":
                    self.assertIn("combat_ref", node)
                    self.assertNotIn("quest_actions", node)

    def test_r2_runtime_content_is_still_out_of_scope(self) -> None:
        manifest = load_json("content/manifest.json")
        planned = {x["content_id"]: x for x in manifest["planned_content"]}
        for index in range(5, 9):
            quest_id = f"NV_MAIN_{index:03d}"
            self.assertEqual("not_loaded", planned[quest_id]["status"])
            self.assertIsNone(planned[quest_id]["path"])
            self.assertFalse((ROOT / f"content/quests/nv7/{quest_id.lower()}.json").exists())


if __name__ == "__main__":
    unittest.main()
