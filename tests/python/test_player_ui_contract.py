from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class PlayerUiContractTests(unittest.TestCase):
    def test_display_name_resolver_covers_public_relationship_labels(self):
        source = (ROOT / "src/ui/display_name_resolver.gd").read_text(encoding="utf-8")
        for value in ("信任", "好感", "尊重", "紧张", "陌生", "相识", "信赖", "亲近", "亲密"):
            self.assertIn(value, source)

    def test_main_ui_uses_central_display_name_resolver(self):
        source = (ROOT / "src/ui/main_ui.gd").read_text(encoding="utf-8")
        self.assertIn("display_name_resolver.gd", source)
        self.assertIn("_display_names.location_name", source)
        self.assertNotIn('"Page opened"', source)

    def test_input_is_routed_through_remappable_actions(self):
        source = (ROOT / "src/ui/main_ui.gd").read_text(encoding="utf-8")
        input_body = source[source.index("func _input("):source.index("func _on_story_node_entered")]
        self.assertIn("_input_router.matches", input_body)
        self.assertNotIn("KEY_SPACE", input_body)
        self.assertNotIn("KEY_ENTER", input_body)

    def test_settings_persist_key_bindings(self):
        source = (ROOT / "src/ui/settings_manager.gd").read_text(encoding="utf-8")
        self.assertIn('"key_bindings": {}', source)
        self.assertIn('candidate["key_bindings"] is Dictionary', source)

    def test_dialogue_review_never_calls_state_mutators(self):
        source = (ROOT / "src/ui/main_ui.gd").read_text(encoding="utf-8")
        review = source[source.index("func review_previous"):source.index("func begin_rebind")]
        for forbidden in ("set_state", "apply_effect", "reset_state", "update_objective", "add_item"):
            self.assertNotIn(forbidden, review)


if __name__ == "__main__":
    unittest.main()
