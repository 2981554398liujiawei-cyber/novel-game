import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


REPO_ROOT = Path(__file__).resolve().parents[2]
FIXTURE_PATH = REPO_ROOT / "content/tests/fixtures/story_runner/minimal_story.json"


class StoryRunnerContractTests(unittest.TestCase):
    def test_story_fixture_matches_quest_schema(self):
        schema = json.loads((REPO_ROOT / "schemas/quest.schema.json").read_text(encoding="utf-8"))
        fixture = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
        errors = sorted(Draft202012Validator(schema).iter_errors(fixture), key=lambda item: list(item.path))
        self.assertEqual([], [error.message for error in errors])

    def test_story_fixture_is_not_in_formal_manifest(self):
        manifest = json.loads((REPO_ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        self.assertNotIn("tests/fixtures/story_runner/minimal_story.json", manifest["content_files"])
        export_config = (REPO_ROOT / "export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn("content/tests/**", export_config)
        self.assertIn("tests/**", export_config)

    def test_story_runner_has_no_ui_or_private_state_dependency(self):
        source = (REPO_ROOT / "src/core/story_runner.gd").read_text(encoding="utf-8")
        self.assertNotIn("extends Control", source)
        self.assertNotIn("NodePath", source)
        self.assertNotIn("_values", source)
        self.assertNotIn("set_state(", source)
        self.assertIn('call("evaluate_condition"', source)
        self.assertIn('call("apply_effects"', source)

    def test_quest_schema_uses_game_state_operator_contract(self):
        schema = json.loads((REPO_ROOT / "schemas/quest.schema.json").read_text(encoding="utf-8"))
        operator_sets = []

        def visit(value):
            if isinstance(value, dict):
                properties = value.get("properties", {})
                if isinstance(properties, dict) and isinstance(properties.get("op"), dict):
                    operator_sets.append(set(properties["op"].get("enum", [])))
                for child in value.values():
                    visit(child)
            elif isinstance(value, list):
                for child in value:
                    visit(child)

        visit(schema)
        condition_ops = {"eq", "ne", "neq", "gt", "gte", "lt", "lte", "in", "not_in"}
        effect_ops = {"set", "inc", "dec"}
        self.assertTrue(operator_sets)
        self.assertTrue(all(ops in (condition_ops, effect_ops) for ops in operator_sets))
        self.assertIn(condition_ops, operator_sets)
        self.assertIn(effect_ops, operator_sets)

    def test_runtime_manager_actions_are_executable_node_contracts(self):
        schema = json.loads((REPO_ROOT / "schemas/quest.schema.json").read_text(encoding="utf-8"))
        node_properties = schema["properties"]["nodes"]["items"]["properties"]
        for field in ("quest_actions", "relationship_actions", "reward_items"):
            self.assertIn(field, node_properties)
        choice_properties = node_properties["choices"]["items"]["properties"]
        self.assertIn("quest_actions", choice_properties)
        self.assertIn("relationship_actions", choice_properties)
        source = (REPO_ROOT / "src/core/story_runner.gd").read_text(encoding="utf-8")
        self.assertIn("_apply_node_actions(node)", source)
        self.assertIn("apply_relationship_effects(relationship_id, [effect])", source)
        self.assertIn('"activate": result = activate_quest(quest_id)', source)
        self.assertIn('"reward_items": node.get("reward_items"', source)


if __name__ == "__main__":
    unittest.main()
