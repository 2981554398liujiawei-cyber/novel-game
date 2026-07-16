import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "content/tests/fixtures/playable_ui_shell/technical_story.json"


class PlayableUIShellContractTests(unittest.TestCase):
    def test_technical_story_fixture_matches_schema(self):
        schema = json.loads((ROOT / "schemas/quest.schema.json").read_text(encoding="utf-8"))
        document = json.loads(FIXTURE.read_text(encoding="utf-8"))
        errors = sorted(Draft202012Validator(schema).iter_errors(document), key=lambda error: list(error.path))
        self.assertEqual([], [error.message for error in errors])

    def test_fixture_is_excluded_from_formal_content_and_export(self):
        manifest = json.loads((ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        self.assertNotIn("tests/fixtures/playable_ui_shell/technical_story.json", manifest["content_files"])
        export = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn('exclude_filter="content/tests/**,tests/**"', export)

    def test_ui_uses_public_manager_interfaces(self):
        source = (ROOT / "src/ui/main_ui.gd").read_text(encoding="utf-8")
        self.assertNotIn("._runtime", source)
        self.assertNotIn("._values", source)
        self.assertIn('call("perform_action"', source)
        self.assertIn('call("choose_choice"', source)
        self.assertIn('call("save"', source)
        self.assertIn('call("load"', source)

    def test_settings_are_separate_from_progress_save(self):
        settings = (ROOT / "src/ui/settings_manager.gd").read_text(encoding="utf-8")
        save = (ROOT / "src/core/save_manager.gd").read_text(encoding="utf-8")
        self.assertIn('user://settings.json', settings)
        self.assertNotIn('settings.json', save)

    def test_release_debug_console_gate_exists(self):
        source = (ROOT / "src/ui/debug_console.gd").read_text(encoding="utf-8")
        self.assertIn("release_build", source)
        self.assertIn("DEBUG_CONSOLE_DISABLED", source)


if __name__ == "__main__":
    unittest.main()
