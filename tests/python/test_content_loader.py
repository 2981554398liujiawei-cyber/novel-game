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

    def _run_loader(self, content_root: Path, expected_error: str | None = None) -> str:
        command = [
            str(self.godot),
            "--headless",
            "--path",
            str(ROOT),
            "--",
            "--smoke-test",
            f"--content-root={content_root}",
            "--expect-content-id=NV7_NPC_LANYIN",
        ]
        if expected_error:
            command.append(f"--expect-content-error={expected_error}")
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
            self.assertIn("CONTENT_ID_QUERY_OK:NV7_NPC_LANYIN", output)
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


if __name__ == "__main__":
    unittest.main()
