from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class RepositoryContractTests(unittest.TestCase):
    def test_main_scene_exists(self) -> None:
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertIn('run/main_scene="res://scenes/app/main.tscn"', project)
        self.assertTrue((ROOT / "scenes/app/main.tscn").exists())

    def test_runtime_manifest_excludes_fixtures(self) -> None:
        manifest = json.loads((ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        for rel in manifest["content_files"]:
            self.assertNotIn("fixture", rel.lower())
            self.assertNotIn("content/tests", rel.lower())

    def test_nv7_planned_content_is_an_unloaded_shell(self) -> None:
        manifest = json.loads((ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        planned = manifest["planned_content"]
        self.assertEqual([f"NV_MAIN_{index:03d}" for index in range(1, 9)], [x["content_id"] for x in planned])
        self.assertTrue(all(x["region_id"] == "NV7" for x in planned))
        self.assertTrue(all(x["status"] == "not_loaded" and x["path"] is None for x in planned))

    def test_runtime_quest_files_are_recursive_and_manifest_registered(self) -> None:
        manifest = json.loads((ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        listed = set(manifest["content_files"])
        for quest_path in (ROOT / "content/quests").rglob("*.json"):
            relative = quest_path.relative_to(ROOT / "content").as_posix()
            quest = json.loads(quest_path.read_text(encoding="utf-8"))
            self.assertIn(quest["content_status"], {"data_ready", "implemented", "verified"})
            self.assertIn(relative, listed)

    def test_windows_export_excludes_story_sources_and_fixtures(self) -> None:
        preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
        for fragment in [
            "content/tests/**",
            "tests/**",
            "docs/story/raw_sources/**",
            "docs/story/**/fixtures/**",
        ]:
            self.assertIn(fragment, preset)

    def test_story_governance_shells_are_registered(self) -> None:
        region = json.loads((ROOT / "docs/story/scripts/nv7/region_manifest.json").read_text(encoding="utf-8"))
        self.assertEqual("EMPTY_SHELL", region["runtime_status"])
        self.assertTrue(all(entry["status"] == "SOURCE_ONLY" for entry in region["tasks"]))
        chapter_map = json.loads((ROOT / "docs/story/chapter_mapping_nv7.json").read_text(encoding="utf-8"))
        self.assertEqual("FRAMEWORK_ONLY", chapter_map["coverage_status"])
        registry = json.loads((ROOT / "docs/story/foreshadowing_registry.json").read_text(encoding="utf-8"))
        self.assertEqual(8, len({entry["foreshadowing_id"] for entry in registry["entries"]}))
        packages = json.loads((ROOT / "docs/story/story_package_manifest.json").read_text(encoding="utf-8"))["packages"]
        incoming = {path.relative_to(ROOT).as_posix() for path in (ROOT / "docs/story/raw_sources/incoming").glob("*.zip")}
        self.assertEqual(incoming, {entry["file"] for entry in packages})
        self.assertTrue(all(entry["intake_status"] == "preflight_failed" for entry in packages))

    def test_no_formal_quest_json_in_starter(self) -> None:
        self.assertEqual([], list((ROOT / "content/quests").rglob("*.json")))

    def test_root_agents_contains_content_guardrail(self) -> None:
        text = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("禁止自行创作缺失的正式剧情", text)
        self.assertIn("CONTENT_MISSING", text)

    def test_story_source_manifest_has_single_active_source(self) -> None:
        manifest = json.loads((ROOT / "docs/story/source_manifest.json").read_text(encoding="utf-8"))
        active = [s for s in manifest["sources"] if s["bucket"] == "active" and s["authority"] == "current_story_source"]
        self.assertEqual(1, len(active))
        self.assertEqual("王者_第七新手村完整剧情母稿_v0.1.md", active[0]["title"])

    def test_current_three_commissions_replace_legacy_side_states(self) -> None:
        registry = json.loads((ROOT / "content/states/state_registry.json").read_text(encoding="utf-8"))
        keys = {s["key"] for s in registry["states"]}
        self.assertIn("quest.nv_main_002.commission.hanshi_trial.status", keys)
        self.assertIn("quest.nv_main_002.commission.suzhi_herb_basket.status", keys)
        self.assertIn("quest.nv_main_002.commission.guchangchuan_boundary_stones.status", keys)
        self.assertNotIn("quest.nv_side_001.status", keys)
        self.assertNotIn("quest.nv_side_002.status", keys)
        self.assertNotIn("quest.nv_side_003.status", keys)

    def test_agents_contains_story_source_gates(self) -> None:
        text = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("STORY_NOT_DATA_READY", text)
        self.assertIn("docs/story/source_manifest.json", text)
        self.assertIn("韩石的试刃", text)
        self.assertIn("顾长川的界石", text)


if __name__ == "__main__":
    unittest.main()
