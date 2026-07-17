from __future__ import annotations

import copy
import io
import json
import tempfile
import unittest
import zipfile
from contextlib import redirect_stdout
from pathlib import Path

from jsonschema import Draft202012Validator

from tools.story_pipeline.cli import main as cli_main
from tools.story_pipeline.core import (
    TEST_POLICY,
    PipelineError,
    build_runtime_json,
    canonical_bytes,
    check_ir,
    diff_ir_runtime,
    parse_markdown,
    render_review,
    sha256_bytes,
    story_status_report,
    validate_chapter_mapping,
    validate_foreshadowing,
)


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/story_pipeline/valid_complete_script.md"


def catalogs() -> dict:
    return {
        "states": {"states": [{"key": "test.flag"}]},
        "npcs": {"npcs": [{"npc_id": "TEST_NPC", "portrait_set": {"expressions": {"neutral": "neutral.png"}}}]},
        "locations": {"locations": [{"location_id": "TEST_LOC"}]},
        "items": {"items": [{"item_id": "TEST_ITEM"}]},
        "combats": {"combats": [{"combat_id": "TEST_COMBAT"}]},
        "presentation": {
            "portrait_actions": ["show", "keep", "hide", "replace"],
            "cameras": ["none"], "deliveries": ["normal"], "gestures": ["none"],
            "audio_cues": ["TEST_SFX"], "background_ids": ["TEST_BG"], "music_ids": ["TEST_MUSIC"],
        },
    }


def refresh(ir: dict) -> dict:
    """Keep integrity metadata current when a test targets semantic validation."""
    quest = ir["quest"]
    kinds: dict[str, int] = {}
    visible = []
    for node in quest["nodes"]:
        kinds[node["type"]] = kinds.get(node["type"], 0) + 1
        visible.extend(node.get("text", []))
        for choice in node.get("choices", []):
            visible.extend([choice.get("text", ""), choice.get("locked_text", "")])
    for feedback in quest.get("post_quest_feedback", []):
        visible.append(feedback.get("text", "") if isinstance(feedback, dict) else str(feedback))
    ir["metrics"] = {
        "visible_text_chars": len("".join(visible)), "node_count": len(quest["nodes"]),
        "dialogue_count": kinds.get("dialogue", 0), "choice_count": kinds.get("choice", 0),
        "terminal_count": sum(node.get("type") == "complete" and node.get("terminal") is True for node in quest["nodes"]),
        "node_types": kinds,
    }
    ir["canonical_sha256"] = sha256_bytes(canonical_bytes(quest))
    return ir


def approval(ir: dict) -> dict:
    return {
        "approval_version": "1.0.0", "story_id": ir["quest"]["quest_id"], "status": "approved",
        "reviewer": "technical-reviewer", "approved_at": "2025-01-01T00:00:00Z",
        "source_sha256": ir["source"]["sha256"], "canonical_sha256": ir["canonical_sha256"], "notes": "fixture",
    }


def codes(errors: list[dict[str, str]]) -> set[str]:
    return {error["code"] for error in errors}


class StoryPipelineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.ir = parse_markdown(FIXTURE)
        self.catalogs = catalogs()

    def test_01_legal_script_parses_and_passes_formal_lint(self) -> None:
        self.assertEqual("TEST_STORY_PIPELINE", self.ir["quest"]["quest_id"])
        self.assertEqual([], check_ir(self.ir, self.catalogs, TEST_POLICY))

    def test_02_empty_dialogue_fails(self) -> None:
        self.ir["quest"]["nodes"][1]["text"] = []
        self.assertIn("STORY_TEXT_EMPTY", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_03_placeholder_and_legacy_terms_fail(self) -> None:
        self.ir["quest"]["nodes"][0]["text"] = ["TODO：旧主角名稍后自由发挥"]
        result = codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY))
        self.assertIn("STORY_PLACEHOLDER_FOUND", result)
        self.assertIn("STORY_CANON_VIOLATION", result)

    def test_04_node_without_exit_fails(self) -> None:
        self.ir["quest"]["nodes"][0].pop("next")
        self.assertIn("STORY_NODE_NO_EXIT", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_05_invalid_jump_fails(self) -> None:
        self.ir["quest"]["nodes"][0]["next"] = "missing"
        self.assertIn("STORY_REFERENCE_INVALID", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_06_unreachable_node_fails(self) -> None:
        self.ir["quest"]["nodes"][2]["choices"][1]["goto"] = "talk_a"
        self.assertIn("STORY_NODE_UNREACHABLE", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_07_dead_automatic_loop_fails(self) -> None:
        self.ir["quest"]["nodes"][0]["next"] = "talk_one"
        self.ir["quest"]["nodes"][1]["next"] = "start"
        result = codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY))
        self.assertIn("STORY_DEAD_LOOP", result)

    def test_08_combat_requires_failure_continuation(self) -> None:
        node = self.ir["quest"]["nodes"][1]
        node.update({"type": "combat", "combat_ref": "TEST_COMBAT", "next_on_win": "choose"})
        node.pop("next")
        self.assertIn("STORY_FAILURE_CONTINUATION_MISSING", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_09_relationship_dimension_whitelist(self) -> None:
        self.ir["quest"]["nodes"][3]["relationship_actions"][0]["dimension"] = "candor"
        self.assertIn("RELATIONSHIP_DIMENSION_INVALID", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_10_unknown_state_item_npc_and_combat_fail(self) -> None:
        choice = self.ir["quest"]["nodes"][2]["choices"][0]
        choice["conditions"][0]["key"] = "missing.state"
        self.ir["quest"]["nodes"][1]["speaker_id"] = "MISSING_NPC"
        self.ir["quest"]["nodes"][0]["item_rewards"] = ["MISSING_ITEM"]
        self.ir["quest"]["nodes"][0]["combat_id"] = "MISSING_COMBAT"
        messages = "\n".join(error["message"] for error in check_ir(refresh(self.ir), self.catalogs, TEST_POLICY))
        for value in ("missing.state", "MISSING_NPC", "MISSING_ITEM", "MISSING_COMBAT"):
            self.assertIn(value, messages)

    def test_11_unregistered_presentation_tags_fail_closed(self) -> None:
        node = self.ir["quest"]["nodes"][0]
        node.update({"background_id": "BAD_BG", "music_id": "BAD_MUSIC", "audio_cue": "BAD_SFX"})
        messages = "\n".join(error["message"] for error in check_ir(refresh(self.ir), self.catalogs, TEST_POLICY))
        for value in ("BAD_BG", "BAD_MUSIC", "BAD_SFX"):
            self.assertIn(value, messages)

    def test_12_expression_is_validated_per_npc(self) -> None:
        self.ir["quest"]["nodes"][1]["expression"] = "invented"
        self.assertIn("PRESENTATION_REFERENCE_INVALID", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_13_protagonist_portrait_is_forbidden(self) -> None:
        node = self.ir["quest"]["nodes"][1]
        node["speaker_id"] = "PROTAGONIST_FENGYUE"
        node["portrait_action"] = "show"
        self.assertIn("PROTAGONIST_PORTRAIT_FORBIDDEN", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_14_manager_ownership_is_semantic(self) -> None:
        self.ir["quest"]["nodes"][2]["choices"][0]["effects"][0]["key"] = "relation.test.trust"
        self.assertIn("MANAGER_OWNERSHIP_INVALID", codes(check_ir(refresh(self.ir), self.catalogs, TEST_POLICY)))

    def test_15_formal_depth_cannot_be_lowered_by_markdown_baseline(self) -> None:
        self.ir["quest"]["nodes"] = self.ir["quest"]["nodes"][-1:]
        self.ir["quest"]["entry_node"] = "done"
        self.ir["baseline"].update({key: 0 for key in self.ir["baseline"] if key != "required_node_ids"})
        self.assertIn("STORY_DEPTH_INSUFFICIENT", codes(check_ir(refresh(self.ir), self.catalogs)))

    def test_16_chapter_mapping_missing_duplicate_and_category(self) -> None:
        mapping = {"chapters": [
            {"source_chapter": "c1", "disposition": "KEEP_GAME"},
            {"source_chapter": "c1", "disposition": "INVALID"},
        ]}
        result = codes(validate_chapter_mapping(mapping, ["c1", "c2"]))
        self.assertEqual({"CHAPTER_MAPPING_DUPLICATE", "CHAPTER_MAPPING_INVALID", "CHAPTER_MAPPING_MISSING"}, result)

    def test_17_foreshadowing_registry_and_reference(self) -> None:
        registry = {"foreshadowing": [{
            "foreshadowing_id": "RETURN_CHANNEL", "title": "test", "first_appearance": None,
            "reinforcement_nodes": [], "misdirection_nodes": [], "reveal_node": None,
            "payoff_node": None, "status": "reserved",
        }]}
        self.assertEqual([], validate_foreshadowing(registry, ["RETURN_CHANNEL"]))
        self.assertIn("FORESHADOWING_REFERENCE_INVALID", codes(validate_foreshadowing(registry, ["MISSING"])))

    def test_18_runtime_json_schema_review_and_roundtrip(self) -> None:
        self.ir["quest"]["nodes"][0]["item_rewards"] = [{"item_id": "TEST_ITEM", "quantity": 3}]
        self.ir["quest"]["nodes"][0]["quest_actions"] = [{"action": "activate", "quest_id": "TEST_QUEST"}]
        self.ir["quest"]["nodes"][2]["choices"][0]["quest_actions"] = [{"action": "complete", "quest_id": "TEST_QUEST"}]
        refresh(self.ir)
        runtime = build_runtime_json(self.ir, approval(self.ir), self.catalogs, TEST_POLICY)
        schema = json.loads((ROOT / "schemas/quest.schema.json").read_text(encoding="utf-8"))
        self.assertEqual([], list(Draft202012Validator(schema).iter_errors(runtime)))
        self.assertTrue(diff_ir_runtime(self.ir, runtime)["match"])
        self.assertEqual([{"action": "activate", "quest_id": "TEST_QUEST"}], runtime["nodes"][0]["quest_actions"])
        self.assertEqual("complete", runtime["nodes"][2]["choices"][0]["quest_actions"][0]["action"])
        self.assertEqual([{"item_id": "TEST_ITEM", "quantity": 3}], runtime["nodes"][0]["reward_items"])
        self.assertEqual("TEST_RELATIONSHIP", runtime["nodes"][3]["relationship_actions"][0]["relationship_id"])
        extensions = runtime["implementation"].get("story_pipeline_extensions", {})
        self.assertNotIn("quest_actions", extensions.get("start", {}))
        self.assertNotIn("item_rewards", extensions.get("start", {}))
        self.assertNotIn("relationship_actions", extensions.get("talk_a", {}))
        review = render_review(runtime, {"source_sha256": self.ir["source"]["sha256"]})
        self.assertIn("第一条路径", review)
        self.assertIn("relationship_actions", review)
        self.assertIn("choose_a", review)

    def test_19_stale_or_cross_story_approval_fails(self) -> None:
        record = approval(self.ir)
        record["story_id"] = "OTHER_STORY"
        with self.assertRaisesRegex(PipelineError, "story_id"):
            build_runtime_json(self.ir, record, self.catalogs, TEST_POLICY)

    def test_20_status_report_states(self) -> None:
        report = story_status_report("TEST", script_status="COMPLETE_SCRIPT", parsed=True, references_ok=True, ownership_ok=True, runtime_generated=True, runtime_valid=True, playable=True, verified=True)
        self.assertEqual("VERIFIED", report["status"])
        self.assertEqual("READY", report["playable"])

    def test_21_preflight_cli_returns_nonzero_for_failed_package(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            package = Path(directory) / "bad.zip"
            output = Path(directory) / "report.json"
            with zipfile.ZipFile(package, "w") as archive:
                archive.writestr("README.md", "not a complete script")
            with redirect_stdout(io.StringIO()):
                exit_code = cli_main(["preflight", str(package), str(output)])
            self.assertEqual(1, exit_code)
            self.assertFalse(json.loads(output.read_text(encoding="utf-8"))["release_ready"])

    def test_22_formal_governance_file_shapes_integrate(self) -> None:
        chapter = json.loads((ROOT / "docs/story/chapter_mapping_nv7.json").read_text(encoding="utf-8"))
        foreshadowing = json.loads((ROOT / "docs/story/foreshadowing_registry.json").read_text(encoding="utf-8"))
        self.assertEqual([], validate_chapter_mapping(chapter))
        self.assertEqual([], validate_foreshadowing(foreshadowing, ["RETURN_CHANNEL"]))
        self.assertEqual([], check_ir(self.ir, self.catalogs, TEST_POLICY, chapter_mapping=chapter, foreshadowing_registry=foreshadowing))

    def test_23_formal_chapter_mapping_detects_missing_and_duplicate(self) -> None:
        mapping = {
            "source_chapters": ["chapter_1", "chapter_2"],
            "mappings": [
                {"chapter_id": "chapter_1", "classification": "KEEP_GAME", "task_ids": [], "note": ""},
                {"chapter_id": "chapter_1", "classification": "DROP", "task_ids": [], "note": ""},
            ],
        }
        result = codes(validate_chapter_mapping(mapping))
        self.assertIn("CHAPTER_MAPPING_DUPLICATE", result)
        self.assertIn("CHAPTER_MAPPING_MISSING", result)


if __name__ == "__main__":
    unittest.main()
