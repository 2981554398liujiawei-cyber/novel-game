from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from tools.validate_repository import validate_combat_registries

ROOT = Path(__file__).resolve().parents[2]
FIXTURE_ROOT = ROOT / "content/tests/fixtures/combat_runner"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


class CombatDataValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schemas = {
            "combat": load_json(ROOT / "schemas/combat.schema.json"),
            "enemy": load_json(ROOT / "schemas/enemy.schema.json"),
            "skill": load_json(ROOT / "schemas/skill.schema.json"),
        }
        cls.formal = {
            "combat": load_json(ROOT / "content/combats/combats.json"),
            "enemy": load_json(ROOT / "content/enemies/enemies.json"),
            "skill": load_json(ROOT / "content/skills/skills.json"),
        }
        cls.fixtures = {
            "combat": load_json(FIXTURE_ROOT / "combats.json"),
            "enemy": load_json(FIXTURE_ROOT / "enemies.json"),
            "skill": load_json(FIXTURE_ROOT / "skills.json"),
        }

    def assert_schema_valid(self, kind: str, document: Any) -> None:
        errors = list(Draft202012Validator(self.schemas[kind]).iter_errors(document))
        messages = [f"{'/'.join(map(str, error.absolute_path))}: {error.message}" for error in errors]
        self.assertEqual([], messages)

    def validate(self, documents: dict[str, Any]) -> list[str]:
        return validate_combat_registries(
            documents["combat"],
            documents["enemy"],
            documents["skill"],
        )

    def test_legacy_formal_registries_remain_compatible(self) -> None:
        for kind, document in self.formal.items():
            self.assert_schema_valid(kind, document)
        self.assertEqual([], self.validate(self.formal))

    def test_runtime_fixtures_pass_schema_and_semantic_validation(self) -> None:
        for kind, document in self.fixtures.items():
            self.assert_schema_valid(kind, document)
        self.assertEqual([], self.validate(self.fixtures))
        status_ids = {
            entry["status_id"]
            for entry in self.fixtures["combat"]["runtime"]["status_definitions"]
        }
        self.assertTrue({"poison", "stun", "guard", "attack_up", "defense_down"} <= status_ids)

    def test_fixture_ids_are_synthetic_and_manifest_stays_isolated(self) -> None:
        for combat in self.fixtures["combat"]["combats"]:
            self.assertTrue(combat["combat_id"].startswith("TEST_"))
        for enemy in self.fixtures["enemy"]["enemies"]:
            self.assertTrue(enemy["enemy_id"].startswith("TEST_"))
        for skill in self.fixtures["skill"]["skills"]:
            self.assertTrue(skill["skill_id"].startswith("TEST_"))

        manifest = load_json(ROOT / "content/manifest.json")
        self.assertFalse(
            any("combat_runner" in path or "fixtures" in path for path in manifest["content_files"])
        )

    def test_unknown_enemy_skill_reference_is_rejected(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        documents["enemy"]["enemies"][0]["skill_ids"][0] = "TEST_SKILL_MISSING"
        errors = self.validate(documents)
        self.assertIn("Enemy 'TEST_ENEMY_DUMMY' references unknown skill: TEST_SKILL_MISSING", errors)

    def test_unknown_status_reference_is_rejected(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        documents["skill"]["skills"][1]["effects"][1]["status_id"] = "missing_status"
        errors = self.validate(documents)
        self.assertIn("Skill 'TEST_SKILL_POISON_EDGE' references unknown status: missing_status", errors)

    def test_ai_requires_positive_weight_and_equipped_skill(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        enemy = documents["enemy"]["enemies"][0]
        for action in enemy["runtime"]["ai_actions"]:
            action["weight"] = 0
        enemy["runtime"]["ai_actions"][1]["skill_id"] = "TEST_SKILL_RECOVER"
        errors = self.validate(documents)
        self.assertIn("Enemy 'TEST_ENEMY_DUMMY' AI actions have no positive total weight", errors)
        self.assertIn(
            "Enemy 'TEST_ENEMY_DUMMY' AI action 'power_strike' uses an unequipped skill: TEST_SKILL_RECOVER",
            errors,
        )

    def test_phase_unit_and_ai_action_references_are_rejected(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        phase = documents["combat"]["combats"][0]["runtime"]["phases"][0]
        phase["target_unit_id"] = "TEST_UNIT_MISSING"
        phase["ai_weight_modifiers"] = {"missing_action": 1.0}
        errors = self.validate(documents)
        self.assertIn(
            "Combat 'TEST_COMBAT_BASIC' phase 'default' references unknown unit: TEST_UNIT_MISSING",
            errors,
        )

    def test_boss_requires_two_or_three_runtime_phases(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        boss = next(
            combat
            for combat in documents["combat"]["combats"]
            if combat["combat_id"] == "TEST_COMBAT_BOSS"
        )
        boss["runtime"]["phases"] = boss["runtime"]["phases"][:1]
        errors = self.validate(documents)
        self.assertIn("Combat 'TEST_COMBAT_BOSS' boss runtime must declare two or three phases", errors)

    def test_runtime_enemy_instances_must_match_legacy_enemy_list(self) -> None:
        documents = copy.deepcopy(self.fixtures)
        documents["combat"]["combats"][0]["runtime"]["enemy_instances"][0][
            "enemy_id"
        ] = "TEST_ENEMY_BRUTE"
        errors = self.validate(documents)
        self.assertIn(
            "Combat 'TEST_COMBAT_BASIC' runtime enemy instances do not match enemy_ids",
            errors,
        )

    def test_content_loader_exposes_combat_runtime_contract(self) -> None:
        source = (ROOT / "src/core/content_loader.gd").read_text(encoding="utf-8")
        for signature in (
            "func get_combat(combat_id: String) -> Variant:",
            "func get_combat_definitions() -> Array:",
            "func get_enemy(enemy_id: String) -> Variant:",
            "func get_enemy_definitions() -> Array:",
            "func get_skill(skill_id: String) -> Variant:",
            "func get_skill_definitions() -> Array:",
            "func get_combat_runtime_registry() -> Dictionary:",
        ):
            self.assertIn(signature, source)


if __name__ == "__main__":
    unittest.main()
