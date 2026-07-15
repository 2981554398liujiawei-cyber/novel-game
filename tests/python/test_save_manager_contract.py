import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


REPO_ROOT = Path(__file__).resolve().parents[2]
SAVE_SCHEMA_PATH = REPO_ROOT / "schemas/save.schema.json"
SAVE_FIXTURE_PATH = REPO_ROOT / "content/tests/fixtures/save_manager/valid_save.json"


class SaveManagerContractTests(unittest.TestCase):
    def test_valid_fixture_matches_save_schema(self):
        schema = json.loads(SAVE_SCHEMA_PATH.read_text(encoding="utf-8"))
        fixture = json.loads(SAVE_FIXTURE_PATH.read_text(encoding="utf-8"))
        errors = sorted(
            Draft202012Validator(schema).iter_errors(fixture),
            key=lambda item: list(item.path),
        )
        self.assertEqual([], [error.message for error in errors])

    def test_save_schema_contains_the_runtime_round_trip_contract(self):
        schema = json.loads(SAVE_SCHEMA_PATH.read_text(encoding="utf-8"))
        required = set(schema["required"])
        self.assertEqual(
            {
                "schema_version",
                "save_version",
                "game_version",
                "development_save",
                "created_at",
                "updated_at",
                "slot_id",
                "playtime_seconds",
                "current_story_id",
                "current_story_node_id",
                "game_state",
                "random_state",
            },
            required,
        )
        self.assertEqual(
            ["manual_1", "manual_2", "manual_3", "auto", "quick"],
            schema["properties"]["slot_id"]["enum"],
        )
        self.assertIn("seed", schema["properties"]["random_state"]["required"])
        self.assertFalse(schema["additionalProperties"])

    def test_save_fixture_is_test_only_and_excluded_from_exports(self):
        manifest = json.loads((REPO_ROOT / "content/manifest.json").read_text(encoding="utf-8"))
        self.assertNotIn(
            "tests/fixtures/save_manager/valid_save.json",
            manifest["content_files"],
        )
        export_config = (REPO_ROOT / "export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn('exclude_filter="content/tests/**,tests/**"', export_config)

    def test_save_manager_is_ui_independent_and_uses_fixed_slots(self):
        source = (REPO_ROOT / "src/core/save_manager.gd").read_text(encoding="utf-8")
        self.assertNotIn("extends Control", source)
        self.assertNotIn("NodePath", source)
        self.assertNotIn("accept_dialog", source)
        self.assertIn('const SLOT_IDS := ["manual_1", "manual_2", "manual_3", "auto", "quick"]', source)
        for method in (
            "save",
            "load",
            "delete_save",
            "list_saves",
            "has_save",
            "restore_backup",
            "request_auto_save",
            "request_quick_save",
            "migrate_save",
        ):
            self.assertIn(f"func {method}(", source)
        for error_code in (
            "SAVE_NOT_FOUND",
            "SAVE_JSON_INVALID",
            "SAVE_SCHEMA_INVALID",
            "SAVE_VERSION_UNSUPPORTED",
            "SAVE_STATE_INVALID",
            "SAVE_STORY_INVALID",
            "SAVE_WRITE_FAILED",
            "SAVE_RESTORE_FAILED",
            "SAVE_NOT_INITIALIZED",
        ):
            self.assertIn(f'const {error_code} := "{error_code}"', source)

    def test_save_manager_uses_temp_validation_backup_and_single_rename(self):
        source = (REPO_ROOT / "src/core/save_manager.gd").read_text(encoding="utf-8")
        write_body = source.split("func _write_document_atomic", 1)[1].split(
            "func _backup_existing_save", 1
        )[0]
        self.assertLess(write_body.index("_write_text_file"), write_body.index("_read_json_file"))
        self.assertLess(write_body.index("_read_json_file"), write_body.index("_backup_existing_save"))
        self.assertLess(write_body.index("_backup_existing_save"), write_body.index("_replace_file"))
        replace_body = source.split("func _replace_file", 1)[1].split(
            "func _read_json_file", 1
        )[0]
        self.assertEqual(1, replace_body.count("DirAccess.rename_absolute"))
        self.assertNotIn("replace_old", source)

    def test_project_uses_a_windows_user_writable_custom_directory(self):
        project = (REPO_ROOT / "project.godot").read_text(encoding="utf-8")
        self.assertIn('config/use_custom_user_dir=true', project)
        self.assertIn('config/custom_user_dir_name="WangZheTextRPG"', project)
        self.assertIn('config/version="0.1.0"', project)
        source = (REPO_ROOT / "src/core/save_manager.gd").read_text(encoding="utf-8")
        self.assertIn('var _save_root := "user://saves"', source)
        self.assertIn('var _backup_root := "user://backups"', source)
        self.assertIn('ProjectSettings.get_setting("application/config/version"', source)
        self.assertIn("_is_install_path", source)
        self.assertIn("_is_allowed_storage_root", source)
        self.assertIn("path.is_absolute_path()", source)

    def test_restore_uses_dedicated_no_effect_story_position_interface(self):
        runner_source = (REPO_ROOT / "src/core/story_runner.gd").read_text(encoding="utf-8")
        restore_body = runner_source.split("func restore_position", 1)[1].split(
            "func advance", 1
        )[0]
        self.assertIn("_restore_exact_node", restore_body)
        self.assertNotIn("_enter_node", restore_body)
        self.assertNotIn("story_started.emit", restore_body)
        self.assertNotIn("story_completed.emit", restore_body)
        self.assertIn("emit_position_restored", restore_body)
        self.assertIn("func create_runtime_checkpoint() -> Dictionary:", runner_source)
        self.assertIn("func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:", runner_source)
        state_source = (REPO_ROOT / "src/core/game_state.gd").read_text(encoding="utf-8")
        self.assertIn("func validate_snapshot(snapshot: Dictionary) -> bool:", state_source)
        self.assertIn("func create_runtime_checkpoint() -> Dictionary:", state_source)
        self.assertIn("func restore_runtime_checkpoint(checkpoint: Dictionary) -> bool:", state_source)


if __name__ == "__main__":
    unittest.main()
