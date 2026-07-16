from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator

from tools.validate_repository import validate_relationship_registry


ROOT = Path(__file__).resolve().parents[2]
FIXTURE_ROOT = ROOT / "content/tests/fixtures/relationship_manager"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


class RelationshipManagerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.relationships = load_json(FIXTURE_ROOT / "relationships.json")
        cls.states = load_json(FIXTURE_ROOT / "state_registry.json")
        cls.schema = load_json(ROOT / "schemas/relationship.schema.json")
        cls.source = (ROOT / "src/core/relationship_manager.gd").read_text(encoding="utf-8")

    def test_fixture_passes_schema_and_semantic_validation(self) -> None:
        schema_errors = list(Draft202012Validator(self.schema).iter_errors(self.relationships))
        self.assertEqual([], [error.message for error in schema_errors])
        self.assertEqual([], validate_relationship_registry(self.relationships, self.states))

    def test_fixture_is_synthetic_and_not_in_formal_manifest(self) -> None:
        self.assertTrue(all(entry["relationship_id"].startswith("TEST_") for entry in self.relationships["relationships"]))
        manifest = load_json(ROOT / "content/manifest.json")
        self.assertFalse(any("relationship_manager" in path or "fixtures" in path for path in manifest["content_files"]))

    def test_validator_rejects_unknown_state_and_stage_references(self) -> None:
        invalid = copy.deepcopy(self.relationships)
        invalid["relationships"][0]["dimensions"]["trust"] = "test.relationship.missing"
        invalid["relationships"][0]["stage_rules"][0]["stage_id"] = "missing_stage"
        errors = validate_relationship_registry(invalid, self.states)
        self.assertIn("Relationship 'TEST_REL_PLAYER_ALPHA' references unknown state: test.relationship.missing", errors)
        self.assertIn("Relationship 'TEST_REL_PLAYER_ALPHA' rule references unknown stage: missing_stage", errors)

    def test_validator_rejects_unknown_flag_boundary_and_state_condition(self) -> None:
        invalid = copy.deepcopy(self.relationships)
        intimate = invalid["relationships"][0]["stage_rules"][0]["conditions"]["all"]
        intimate[3]["flag_id"] = "missing_flag"
        intimate[5]["boundary_id"] = "missing_boundary"
        intimate[6]["key"] = "test.relationship.missing_gate"
        errors = validate_relationship_registry(invalid, self.states)
        self.assertTrue(any("unknown flag" in error for error in errors))
        self.assertTrue(any("unknown boundary" in error for error in errors))
        self.assertTrue(any("unknown state" in error for error in errors))

    def test_required_runtime_api_and_signals_are_declared(self) -> None:
        for marker in (
            "signal relationship_changed",
            "signal stage_changed",
            "signal flag_changed",
            "signal boundary_changed",
            "signal conflict_changed",
            "func get_dimension(",
            "func apply_effects(",
            "func evaluate_condition(",
            "func reject_action(",
            "func reopen_action(",
            "func repair_conflict(",
            "func select_text_version(",
        ):
            self.assertIn(marker, self.source)

    def test_existing_managers_delegate_instead_of_copying_relationship_logic(self) -> None:
        for path in (ROOT / "src/core/story_runner.gd", ROOT / "src/core/quest_manager.gd"):
            source = path.read_text(encoding="utf-8")
            self.assertIn("func bind_relationship_manager(", source)
            self.assertIn("_relationship_manager.call(\"evaluate_condition\"", source)
            self.assertIn("_relationship_manager.call(\"apply_effects\"", source)
        combat_source = (ROOT / "src/core/combat_runner.gd").read_text(encoding="utf-8")
        self.assertNotIn("relationship_manager", combat_source.lower())


if __name__ == "__main__":
    unittest.main()
