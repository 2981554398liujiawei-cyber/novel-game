import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


REPO_ROOT = Path(__file__).resolve().parents[2]


class GameStateContractTests(unittest.TestCase):
    def test_fixture_matches_state_registry_schema(self):
        schema = json.loads((REPO_ROOT / "schemas/state_registry.schema.json").read_text(encoding="utf-8"))
        fixture = json.loads(
            (REPO_ROOT / "content/tests/fixtures/game_state/state_registry.json").read_text(encoding="utf-8")
        )
        errors = sorted(Draft202012Validator(schema).iter_errors(fixture), key=lambda item: list(item.path))
        self.assertEqual([], [error.message for error in errors])

    def test_formal_manifest_does_not_reference_game_state_fixture(self):
        manifest = json.loads((REPO_ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        self.assertFalse(any("fixtures" in path.lower() for path in manifest["content_files"]))


if __name__ == "__main__":
    unittest.main()
