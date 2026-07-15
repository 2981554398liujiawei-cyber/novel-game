from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class ContentLoaderIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        configured = os.environ.get("GODOT_BIN")
        cls.godot = configured or shutil.which("godot_console") or shutil.which("godot") or shutil.which("godot4")
        if not cls.godot:
            raise unittest.SkipTest("Godot is not available for ContentLoader integration tests")

    def _copy_content(self, temp_dir: str) -> Path:
        destination = Path(temp_dir) / "content"
        shutil.copytree(ROOT / "content", destination)
        return destination

    def _run_loader(
        self,
        content_root: Path,
        expected_error: str | None = None,
        expected_content_id: str = "NV7_NPC_LANYIN",
        expected_story_id: str | None = None,
    ) -> str:
        command = [
            str(self.godot),
            "--headless",
            "--path",
            str(ROOT),
            "--",
            "--smoke-test",
            f"--content-root={content_root}",
            f"--expect-content-id={expected_content_id}",
        ]
        if expected_error:
            command.append(f"--expect-content-error={expected_error}")
        if expected_story_id:
            command.append(f"--expect-story-id={expected_story_id}")
        completed = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30,
            check=False,
        )
        output = completed.stdout + completed.stderr
        self.assertEqual(0, completed.returncode, output)
        self.assertNotIn("SCRIPT ERROR", output)
        if expected_error:
            self.assertIn(f"EXPECTED_CONTENT_ERROR_OK:{expected_error}", output)
        else:
            self.assertIn("CONTENT_LOADER_OK:", output)
            self.assertIn(f"CONTENT_ID_QUERY_OK:{expected_content_id}", output)
            if expected_story_id:
                self.assertIn(f"STORY_QUERY_OK:{expected_story_id}", output)
            self.assertIn("SMOKE_TEST_OK", output)
        return output

    def test_normal_manifest_loads(self) -> None:
        self._run_loader(ROOT / "content")

    def test_missing_manifest_file_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            (content_root / "items/items.json").unlink()
            self._run_loader(content_root, "CONTENT_FILE_MISSING")

    def test_malformed_json_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            (content_root / "items/items.json").write_text("{broken", encoding="utf-8")
            self._run_loader(content_root, "CONTENT_JSON_INVALID")

    def test_schema_error_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            path = content_root / "items/items.json"
            document = json.loads(path.read_text(encoding="utf-8"))
            del document["items"][0]["name"]
            path.write_text(json.dumps(document, ensure_ascii=False), encoding="utf-8")
            self._run_loader(content_root, "CONTENT_SCHEMA_INVALID")

    def test_invalid_reference_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            path = content_root / "combats/combats.json"
            document = json.loads(path.read_text(encoding="utf-8"))
            document["combats"][0]["location_id"] = "NV7_LOC_DOES_NOT_EXIST"
            path.write_text(json.dumps(document, ensure_ascii=False), encoding="utf-8")
            self._run_loader(content_root, "INVALID_CONTENT_REFERENCE")

    def test_duplicate_id_fails_and_restored_data_recovers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            path = content_root / "items/items.json"
            original = path.read_text(encoding="utf-8")
            document = json.loads(original)
            document["items"].append(document["items"][0].copy())
            path.write_text(json.dumps(document, ensure_ascii=False), encoding="utf-8")
            self._run_loader(content_root, "DUPLICATE_CONTENT_ID")

            path.write_text(original, encoding="utf-8")
            self._run_loader(content_root)

    def test_story_fixture_can_be_loaded_and_queried_through_content_loader(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            fixture_path = ROOT / "content/tests/fixtures/story_runner/minimal_story.json"
            story_path = content_root / "quests/minimal_story.json"
            story_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(fixture_path, story_path)

            manifest_path = content_root / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["content_files"].append("quests/minimal_story.json")
            manifest_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")

            registry_path = content_root / "states/state_registry.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            fixture_registry = json.loads(
                (ROOT / "content/tests/fixtures/game_state/state_registry.json").read_text(encoding="utf-8")
            )
            registry["states"].extend(fixture_registry["states"])
            registry_path.write_text(json.dumps(registry, ensure_ascii=False), encoding="utf-8")

            self._run_loader(
                content_root,
                expected_content_id="TEST_STORY_MINIMAL",
                expected_story_id="TEST_STORY_MINIMAL",
            )

    def test_quest_dependency_cycle_fails_content_loading(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            content_root = self._copy_content(temp_dir)
            fixture_path = ROOT / "content/tests/fixtures/story_runner/minimal_story.json"
            fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
            quest_paths: list[str] = []
            quest_ids = ["TEST_DEPENDENCY_A", "TEST_DEPENDENCY_B"]
            for quest_id in quest_ids:
                quest = json.loads(json.dumps(fixture))
                quest["quest_id"] = quest_id
                relative_path = f"quests/{quest_id.lower()}.json"
                destination = content_root / relative_path
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_text(json.dumps(quest, ensure_ascii=False), encoding="utf-8")
                quest_paths.append(relative_path)

            dependencies_path = content_root / "quest_dependencies.json"
            dependencies = {
                "schema_version": "1.0.0",
                "quests": [
                    {"quest_id": quest_ids[0], "depends_on": [quest_ids[1]]},
                    {"quest_id": quest_ids[1], "depends_on": [quest_ids[0]]},
                ],
            }
            dependencies_path.write_text(json.dumps(dependencies, ensure_ascii=False), encoding="utf-8")

            manifest_path = content_root / "manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["content_files"].extend(quest_paths)
            manifest_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")

            registry_path = content_root / "states/state_registry.json"
            registry = json.loads(registry_path.read_text(encoding="utf-8"))
            fixture_registry = json.loads(
                (ROOT / "content/tests/fixtures/game_state/state_registry.json").read_text(encoding="utf-8")
            )
            registry["states"].extend(fixture_registry["states"])
            registry_path.write_text(json.dumps(registry, ensure_ascii=False), encoding="utf-8")

            self._run_loader(content_root, "QUEST_DEPENDENCY_CYCLE")


if __name__ == "__main__":
    unittest.main()
