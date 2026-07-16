from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class CombatRunnerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = (ROOT / "src/core/combat_runner.gd").read_text(encoding="utf-8")

    def test_runner_is_ui_story_and_quest_independent(self) -> None:
        lowered = self.source.lower()
        self.assertNotIn("quest_manager", lowered)
        self.assertNotIn("story_runner", lowered)
        self.assertNotIn("control", self.source.splitlines()[0].lower())
        self.assertNotIn("nv7_", lowered)
        self.assertNotIn("岚音", self.source)

    def test_runner_uses_public_inventory_contract_only(self) -> None:
        self.assertIn('"get_stat_modifiers"', self.source)
        self.assertIn('"get_item_definition"', self.source)
        self.assertIn('"use_item"', self.source)
        for private_name in ("_backpack", "_equipment", "_custody", "_quest_items"):
            self.assertNotIn(f"_inventory_manager.{private_name}", self.source)
            self.assertNotIn(f'_inventory_manager.get("{private_name}")', self.source)
            self.assertNotIn(f'_inventory_manager["{private_name}"]', self.source)

    def test_runner_has_all_required_actions_signals_and_results(self) -> None:
        self.assertIn(
            'const ACTION_TYPES := ["attack", "defend", "skill", "item", "inspect", "retreat"]',
            self.source,
        )
        self.assertIn(
            'const RESULT_TYPES := ["victory", "defeat", "retreat", "partial_success"]',
            self.source,
        )
        for signal_name in (
            "combat_started",
            "round_started",
            "turn_started",
            "action_resolved",
            "unit_damaged",
            "unit_healed",
            "status_applied",
            "unit_defeated",
            "phase_changed",
            "combat_finished",
        ):
            self.assertIn(f"signal {signal_name}", self.source)

    def test_random_and_persistence_contracts_are_explicit(self) -> None:
        rng_source = (ROOT / "src/core/combat_rng.gd").read_text(encoding="utf-8")
        self.assertIn("func export_state() -> Dictionary:", rng_source)
        self.assertIn("func restore_state(snapshot: Dictionary) -> bool:", rng_source)
        self.assertIn("func export_runtime_snapshot() -> Dictionary:", self.source)
        self.assertIn("func restore_runtime_snapshot(snapshot: Dictionary) -> bool:", self.source)
        self.assertIn("func get_persistence_policy(operation: String) -> Dictionary:", self.source)
        self.assertIn("COMBAT_PERSISTENCE_FORBIDDEN", self.source)

    def test_player_ai_and_checkpoint_authority_are_separated(self) -> None:
        self.assertIn("return _perform_action_internal(command, false)", self.source)
        self.assertIn("_perform_action_internal(command, true)", self.source)
        self.assertIn("COMBAT_ACTOR_CONTROL_FORBIDDEN", self.source)
        self.assertIn("Combat cannot start until a SaveManager is bound", self.source)

        app_source = (ROOT / "src/app/app_root.gd").read_text(encoding="utf-8")
        self.assertIn('preload("res://src/core/save_manager.gd")', app_source)
        self.assertIn('preload("res://src/core/story_runner.gd")', app_source)
        self.assertIn("_save_manager.initialize(", app_source)
        self.assertIn("_combat_runner.bind_save_manager(_save_manager)", app_source)

    def test_runtime_snapshot_uses_content_authority(self) -> None:
        self.assertIn("runtime definition differs from ContentLoader authority", self.source)
        self.assertIn("snapshot rules differ from ContentLoader authority", self.source)
        self.assertIn("snapshot outcomes differ from ContentLoader authority", self.source)

        save_source = (ROOT / "src/core/save_manager.gd").read_text(encoding="utf-8")
        self.assertIn("var _runtime_guard: WeakRef", save_source)
        self.assertIn("weakref(runtime_guard)", save_source)


if __name__ == "__main__":
    unittest.main()
