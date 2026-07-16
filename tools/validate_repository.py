#!/usr/bin/env python3
from __future__ import annotations

import json
import hashlib
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
SCHEMAS = ROOT / "schemas"

REQUIRED_FILES = [
    "AGENTS.md",
    "project.godot",
    "export_presets.cfg",
    "content/manifest.json",
    "content/states/state_registry.json",
    "content/npcs/npcs.json",
    "content/locations/locations.json",
    "content/items/items.json",
    "content/enemies/enemies.json",
    "content/skills/skills.json",
    "content/combats/combats.json",
    "content/quest_dependencies.json",
    "schemas/presentation_tags.schema.json",
    "schemas/relationship.schema.json",
    "src/core/content_loader.gd",
    "src/core/relationship_manager.gd",
    "src/core/json_schema_validator.gd",
    "scripts/validate.ps1",
    "scripts/test.ps1",
    "scripts/smoke_test.ps1",
    "scripts/build_windows.ps1",
    "docs/story/AGENTS.md",
    "docs/story/source_manifest.json",
    "docs/story/active/00_第七新手村剧情源接入索引.md",
    "docs/story/FORMAT.md",
    "docs/story/CONTRACT.md",
    "docs/story/story_package_manifest.json",
    "docs/story/scripts/nv7/region_manifest.json",
    "docs/story/chapter_mapping_nv7.json",
    "docs/story/foreshadowing_registry.json",
    "docs/story/reviews/README.md",
    "docs/story/generated_reviews/README.md",
    "docs/story/scripts/nv7/R1/README.md",
    "docs/story/scripts/nv7/R2/README.md",
    "content/quests/nv7/README.md",
    "content/story/README.md",
]

SCHEMA_MAP = {
    "content/states/state_registry.json": "state_registry.schema.json",
    "content/npcs/npcs.json": "npc.schema.json",
    "content/locations/locations.json": "location.schema.json",
    "content/items/items.json": "item.schema.json",
    "content/enemies/enemies.json": "enemy.schema.json",
    "content/skills/skills.json": "skill.schema.json",
    "content/combats/combats.json": "combat.schema.json",
    "content/quest_dependencies.json": "quest_dependency.schema.json",
    "content/presentation_tags.json": "presentation_tags.schema.json",
    "content/manifest.json": "content_manifest.schema.json",
    "docs/story/source_manifest.json": "story_source_manifest.schema.json",
    "docs/story/story_package_manifest.json": "story_package_manifest.schema.json",
    "docs/story/scripts/nv7/region_manifest.json": "story_region_manifest.schema.json",
    "docs/story/chapter_mapping_nv7.json": "story_chapter_mapping.schema.json",
    "docs/story/foreshadowing_registry.json": "foreshadowing_registry.schema.json",
}

FORBIDDEN_RUNTIME_TOKENS = [
    "HTTPRequest",
    "HTTPClient",
    "WebSocketPeer",
    "WebSocketMultiplayerPeer",
    "https://",
    "http://",
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_schema(data_path: Path, schema_path: Path, errors: list[str]) -> None:
    try:
        data = load_json(data_path)
        schema = load_json(schema_path)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"JSON load failed: {data_path.relative_to(ROOT)}: {exc}")
        return
    for error in Draft202012Validator(schema).iter_errors(data):
        loc = "/".join(str(x) for x in error.absolute_path)
        errors.append(f"Schema error {data_path.relative_to(ROOT)} [{loc}]: {error.message}")


def check_manifest(errors: list[str]) -> None:
    manifest_path = CONTENT / "manifest.json"
    if not manifest_path.exists():
        return
    manifest = load_json(manifest_path)
    listed = manifest.get("content_files", [])
    forbidden = manifest.get("forbidden_path_fragments", [])
    normalized_forbidden = [str(fragment).replace("\\", "/").lower() for fragment in forbidden]
    required_forbidden = {"tests/fixtures", "content/tests", "fixtures/", "docs/story", "raw_sources"}
    for missing in sorted(required_forbidden - set(normalized_forbidden)):
        errors.append(f"Manifest is missing required forbidden path protection: {missing}")
    if len(listed) != len(set(listed)):
        errors.append("Manifest repeats a content file")
    for rel in listed:
        normalized = str(rel).replace("\\", "/").lower()
        if any(fragment in normalized for fragment in normalized_forbidden):
            errors.append(f"Manifest references forbidden path: {rel}")
        if not (CONTENT / rel).exists():
            errors.append(f"Manifest references missing file: {rel}")
    for rel in listed:
        if rel.startswith("quests/") and not rel.endswith(".json"):
            errors.append(f"Quest manifest entry must be JSON: {rel}")
        if rel.startswith("quests/") and (CONTENT / rel).exists():
            try:
                status = load_json(CONTENT / rel).get("content_status")
            except Exception:  # JSON/schema validation reports the precise error.
                continue
            if status not in {"data_ready", "implemented", "verified"}:
                errors.append(f"Manifest cannot load non-runtime quest status '{status}': {rel}")

    planned = manifest.get("planned_content", [])
    planned_ids = [entry.get("content_id") for entry in planned if isinstance(entry, dict)]
    expected_nv7 = {f"NV_MAIN_{index:03d}" for index in range(1, 9)}
    if set(planned_ids) != expected_nv7 or len(planned_ids) != len(expected_nv7):
        errors.append("Manifest planned_content must contain exactly NV_MAIN_001 through NV_MAIN_008")
    for entry in planned:
        if not isinstance(entry, dict):
            continue
        status = entry.get("status")
        path = entry.get("path")
        if status == "not_loaded":
            if path is not None:
                errors.append(f"Unloaded planned content must use a null path: {entry.get('content_id')}")
            continue
        if not isinstance(path, str) or path not in listed:
            errors.append(f"Loaded planned content must reference a manifest quest path: {entry.get('content_id')}")
            continue
        document_path = CONTENT / path
        if document_path.exists():
            document = load_json(document_path)
            if document.get("quest_id") != entry.get("content_id") or document.get("content_status") != status:
                errors.append(f"Loaded planned content metadata does not match runtime quest: {entry.get('content_id')}")


def check_states(errors: list[str]) -> None:
    data = load_json(CONTENT / "states/state_registry.json")
    states = data.get("states", [])
    keys = [s.get("key") for s in states]
    if len(keys) != len(set(keys)):
        errors.append("Duplicate state key")
    pattern = re.compile(r"^[a-z][a-z0-9_.]+$")
    for state in states:
        key = state.get("key", "")
        if not pattern.match(key):
            errors.append(f"Invalid state key format: {key}")
    start = next((s for s in states if s.get("key") == "quest.nv_main_001.status"), None)
    if start and start.get("default") != "not_started":
        errors.append("Production default must not pre-complete NV_MAIN_001")


ITEM_EQUIPMENT_SLOTS = {
    "weapon",
    "off_hand",
    "head",
    "body",
    "accessory_1",
    "accessory_2",
}
ITEM_STATE_KEY_PATTERN = re.compile(r"^[a-z][a-z0-9_.]+$")


def validate_relationship_registry(document: Any, state_registry: Any) -> list[str]:
    """Validate relationship cross-references that JSON Schema cannot express."""
    errors: list[str] = []
    if not isinstance(document, dict) or not isinstance(state_registry, dict):
        return ["Relationship registry and state registry must be objects"]
    state_by_key = {
        state.get("key"): state
        for state in state_registry.get("states", [])
        if isinstance(state, dict) and isinstance(state.get("key"), str)
    }
    dimensions = {
        entry.get("dimension_id")
        for entry in document.get("dimension_definitions", [])
        if isinstance(entry, dict)
    }
    stages = {
        entry.get("stage_id")
        for entry in document.get("stage_definitions", [])
        if isinstance(entry, dict)
    }
    for required in {"trust", "affection", "respect", "tension"} - dimensions:
        errors.append(f"Missing required relationship dimension: {required}")
    for required in {"stranger", "acquaintance", "trusted", "close", "intimate"} - stages:
        errors.append(f"Missing required relationship stage: {required}")
    ids: set[str] = set()
    pairs: set[tuple[str, str]] = set()

    def validate_state(key: Any, expected: set[str], relationship_id: str) -> None:
        state = state_by_key.get(key)
        if state is None:
            errors.append(f"Relationship '{relationship_id}' references unknown state: {key}")
            return
        if state.get("type") not in expected:
            errors.append(f"Relationship '{relationship_id}' state '{key}' has incompatible type")
        if state.get("persistent") is not True:
            errors.append(f"Relationship '{relationship_id}' state '{key}' must be persistent")
        sources = state.get("write_sources", [])
        if state.get("read_only") or (sources and "relationship" not in sources):
            errors.append(f"Relationship '{relationship_id}' state '{key}' forbids relationship writes")

    def validate_conditions(
        group: Any,
        relationship_id: str,
        declared_dimensions: set[str],
        flags: set[str],
        boundaries: set[str],
    ) -> None:
        if not isinstance(group, dict):
            return
        for condition in [*group.get("all", []), *group.get("any", [])]:
            if not isinstance(condition, dict):
                continue
            kind = condition.get("kind")
            if kind == "dimension" and condition.get("dimension_id") not in declared_dimensions:
                errors.append(f"Relationship '{relationship_id}' condition references unknown dimension: {condition.get('dimension_id')}")
            elif kind == "stage" and condition.get("stage_id") not in stages:
                errors.append(f"Relationship '{relationship_id}' condition references unknown stage: {condition.get('stage_id')}")
            elif kind == "flag" and condition.get("flag_id") not in flags:
                errors.append(f"Relationship '{relationship_id}' condition references unknown flag: {condition.get('flag_id')}")
            elif kind == "boundary" and condition.get("boundary_id") not in boundaries:
                errors.append(f"Relationship '{relationship_id}' condition references unknown boundary: {condition.get('boundary_id')}")
            elif kind == "state" and condition.get("key") not in state_by_key:
                errors.append(f"Relationship '{relationship_id}' condition references unknown state: {condition.get('key')}")

    for relationship in document.get("relationships", []):
        if not isinstance(relationship, dict):
            continue
        relationship_id = str(relationship.get("relationship_id", ""))
        if relationship_id in ids:
            errors.append(f"Duplicate relationship ID: {relationship_id}")
        ids.add(relationship_id)
        pair = (str(relationship.get("actor_id", "")), str(relationship.get("target_id", "")))
        if pair in pairs:
            errors.append(f"Duplicate directed relationship pair: {pair[0]}>{pair[1]}")
        pairs.add(pair)
        if pair[0] == pair[1]:
            errors.append(f"Relationship '{relationship_id}' actor and target must differ")
        relation_dimensions = set(relationship.get("dimensions", {}))
        for dimension_id, state_key in relationship.get("dimensions", {}).items():
            if dimension_id not in dimensions:
                errors.append(f"Relationship '{relationship_id}' references unknown dimension: {dimension_id}")
            validate_state(state_key, {"integer", "number"}, relationship_id)
        validate_state(relationship.get("stage_state_key"), {"string"}, relationship_id)
        flags = {entry.get("id") for entry in relationship.get("flags", []) if isinstance(entry, dict)}
        boundaries = {entry.get("id") for entry in relationship.get("boundaries", []) if isinstance(entry, dict)}
        for entry in [*relationship.get("flags", []), *relationship.get("boundaries", [])]:
            if isinstance(entry, dict):
                validate_state(entry.get("state_key"), {"boolean"}, relationship_id)
        conflict = relationship.get("conflict", {})
        validate_state(conflict.get("active_state_key"), {"boolean"}, relationship_id)
        validate_state(conflict.get("reason_state_key"), {"string"}, relationship_id)
        validate_state(conflict.get("repair_progress_state_key"), {"integer", "number"}, relationship_id)
        for rule in relationship.get("stage_rules", []):
            if not isinstance(rule, dict):
                continue
            if rule.get("stage_id") not in stages:
                errors.append(f"Relationship '{relationship_id}' rule references unknown stage: {rule.get('stage_id')}")
            validate_conditions(rule.get("conditions"), relationship_id, relation_dimensions, flags, boundaries)
        for rule in relationship.get("action_rules", []):
            if isinstance(rule, dict):
                validate_conditions(rule.get("conditions"), relationship_id, relation_dimensions, flags, boundaries)
        for rule in relationship.get("rejection_rules", []):
            if not isinstance(rule, dict):
                continue
            if rule.get("rejection_flag_id") not in flags:
                errors.append(f"Relationship '{relationship_id}' rejection references unknown flag: {rule.get('rejection_flag_id')}")
            for boundary_id in rule.get("boundary_updates", {}):
                if boundary_id not in boundaries:
                    errors.append(f"Relationship '{relationship_id}' rejection references unknown boundary: {boundary_id}")
        for version in relationship.get("text_versions", []):
            if isinstance(version, dict):
                validate_conditions(version.get("conditions"), relationship_id, relation_dimensions, flags, boundaries)
    return errors


def check_relationship_fixture(errors: list[str]) -> None:
    fixture_root = CONTENT / "tests/fixtures/relationship_manager"
    relationship_path = fixture_root / "relationships.json"
    state_path = fixture_root / "state_registry.json"
    if not relationship_path.exists() or not state_path.exists():
        errors.append("RelationshipManager fixtures are missing")
        return
    validate_schema(relationship_path, SCHEMAS / "relationship.schema.json", errors)
    validate_schema(state_path, SCHEMAS / "state_registry.schema.json", errors)
    errors.extend(validate_relationship_registry(load_json(relationship_path), load_json(state_path)))


def validate_item_registry(document: Any, state_registry: Any | None = None) -> list[str]:
    """Return deterministic cross-field errors for an item registry.

    JSON Schema owns the field shapes. This helper owns compatibility between
    the legacy item fields and the optional InventoryManager runtime contract.
    It is side-effect free so fixture tests and conversion tools can reuse it.
    """
    errors: list[str] = []
    state_by_key = {
        state.get("key"): state
        for state in state_registry.get("states", [])
        if isinstance(state, dict) and isinstance(state.get("key"), str)
    } if isinstance(state_registry, dict) else None
    state_keys = set(state_by_key) if state_by_key is not None else None
    seen_item_ids: set[str] = set()
    items = document.get("items", []) if isinstance(document, dict) else []
    ownership_keys: dict[str, str] = {}
    for raw_item in items:
        if not isinstance(raw_item, dict) or not isinstance(raw_item.get("runtime"), dict):
            continue
        ownership_key = raw_item["runtime"].get("ownership_state_key")
        if not isinstance(ownership_key, str) or not ownership_key:
            continue
        item_id = str(raw_item.get("item_id", ""))
        if ownership_key in ownership_keys:
            errors.append(
                f"Item ownership state '{ownership_key}' is shared by '{ownership_keys[ownership_key]}' and '{item_id}'"
            )
        else:
            ownership_keys[ownership_key] = item_id

    def allows_inventory_write(state_key: str) -> bool:
        if state_by_key is None or state_key not in state_by_key:
            return False
        definition = state_by_key[state_key]
        write_sources = definition.get("write_sources", [])
        return (
            definition.get("read_only") is not True
            and isinstance(write_sources, list)
            and (not write_sources or "inventory" in write_sources)
        )

    for raw_item in items:
        if not isinstance(raw_item, dict):
            continue
        item_id = raw_item.get("item_id")
        if not isinstance(item_id, str):
            continue
        if item_id in seen_item_ids:
            errors.append(f"Duplicate item ID: {item_id}")
        seen_item_ids.add(item_id)

        runtime = raw_item.get("runtime")
        if runtime is None:
            continue
        if not isinstance(runtime, dict):
            continue

        runtime_type = runtime.get("type")
        max_stack = runtime.get("max_stack")
        legacy_stack = raw_item.get("stack_limit")
        stackable = runtime.get("stackable")
        unique = runtime.get("unique")
        quest_critical = runtime.get("quest_critical")
        equipment_slot = runtime.get("equipment_slot")
        compatible_slots = runtime.get("compatible_slots", [])
        occupies_slots = runtime.get("occupies_slots", [])
        combat_effects = runtime.get("combat_effects", [])

        expected_kind = {
            "consumable": "consumable",
            "equipment": "equipment",
            "quest": "quest",
            "material": "material",
            "key_item": "quest",
        }.get(runtime_type)
        if expected_kind is not None and raw_item.get("kind") != expected_kind:
            errors.append(
                f"Item '{item_id}' runtime type '{runtime_type}' conflicts with legacy kind '{raw_item.get('kind')}'"
            )
        if isinstance(max_stack, int) and isinstance(legacy_stack, int) and max_stack != legacy_stack:
            errors.append(f"Item '{item_id}' max_stack must equal legacy stack_limit")
        if stackable is False and max_stack != 1:
            errors.append(f"Item '{item_id}' non-stackable runtime must use max_stack=1")
        if unique is True and max_stack != 1:
            errors.append(f"Item '{item_id}' unique runtime must use max_stack=1")

        if runtime_type == "consumable" and isinstance(max_stack, int) and max_stack > 20:
            errors.append(f"Item '{item_id}' consumable max_stack exceeds 20")
        if runtime_type == "material" and isinstance(max_stack, int) and max_stack > 99:
            errors.append(f"Item '{item_id}' material max_stack exceeds 99")
        if runtime_type != "consumable" and isinstance(combat_effects, list) and combat_effects:
            errors.append(f"Item '{item_id}' only consumables may declare combat effects")

        if runtime_type == "equipment":
            if raw_item.get("stack_limit") != 1:
                errors.append(f"Item '{item_id}' equipment must use legacy stack_limit=1")
            if equipment_slot not in ITEM_EQUIPMENT_SLOTS:
                errors.append(f"Item '{item_id}' equipment_slot is invalid")
            if raw_item.get("equip_slot") != equipment_slot:
                errors.append(f"Item '{item_id}' legacy equip_slot must match runtime equipment_slot")
            if not isinstance(compatible_slots, list) or equipment_slot not in compatible_slots:
                errors.append(f"Item '{item_id}' compatible_slots must include its primary equipment_slot")
            if not isinstance(occupies_slots, list) or equipment_slot not in occupies_slots:
                errors.append(f"Item '{item_id}' occupies_slots must include its primary equipment_slot")
            if isinstance(occupies_slots, list) and len(occupies_slots) > 1:
                if set(occupies_slots) != {"weapon", "off_hand"}:
                    errors.append(f"Item '{item_id}' multi-slot equipment may only occupy weapon and off_hand")
        else:
            if equipment_slot is not None:
                errors.append(f"Item '{item_id}' non-equipment runtime must use equipment_slot=null")
            if compatible_slots != [] or occupies_slots != []:
                errors.append(f"Item '{item_id}' non-equipment runtime must not declare equipment slots")
            if raw_item.get("equip_slot") is not None:
                errors.append(f"Item '{item_id}' non-equipment legacy equip_slot must be null")

        if runtime_type == "quest" and runtime.get("storage") != "quest":
            errors.append(f"Item '{item_id}' quest runtime must use quest storage")
        if runtime_type == "key_item" and raw_item.get("key_item") is not True:
            errors.append(f"Item '{item_id}' key_item runtime must set legacy key_item=true")
        if quest_critical is True:
            if raw_item.get("key_item") is not True:
                errors.append(f"Item '{item_id}' quest-critical runtime must set legacy key_item=true")
            if runtime.get("sellable") is not False or runtime.get("discardable") is not False:
                errors.append(f"Item '{item_id}' quest-critical runtime cannot be sold or discarded")
            if runtime.get("overflow_policy") != "custody":
                errors.append(f"Item '{item_id}' quest-critical runtime must overflow to custody")

        ownership_key = runtime.get("ownership_state_key")
        if ownership_key is not None:
            if not isinstance(ownership_key, str) or not ITEM_STATE_KEY_PATTERN.fullmatch(ownership_key):
                errors.append(f"Item '{item_id}' ownership_state_key format is invalid")
            elif state_keys is not None and ownership_key not in state_keys:
                errors.append(f"Item '{item_id}' references unknown ownership state '{ownership_key}'")
            elif state_by_key is not None and state_by_key[ownership_key].get("type") != "boolean":
                errors.append(f"Item '{item_id}' ownership state '{ownership_key}' must be boolean")
            elif state_by_key is not None and not allows_inventory_write(ownership_key):
                errors.append(f"Item '{item_id}' ownership state '{ownership_key}' does not allow inventory writes")

        if state_keys is not None:
            for effect in runtime.get("use_effects", []):
                if not isinstance(effect, dict):
                    continue
                effect_key = effect.get("key")
                if effect_key not in state_keys:
                    errors.append(f"Item '{item_id}' use effect references unknown state '{effect_key}'")
                elif not allows_inventory_write(effect_key):
                    errors.append(f"Item '{item_id}' use effect state '{effect_key}' does not allow inventory writes")
                if effect_key in ownership_keys:
                    errors.append(
                        f"Item '{item_id}' use effect cannot modify ownership state '{effect_key}'"
                    )
    return errors


def check_items(errors: list[str]) -> None:
    item_path = CONTENT / "items/items.json"
    state_path = CONTENT / "states/state_registry.json"
    if item_path.exists() and state_path.exists():
        errors.extend(validate_item_registry(load_json(item_path), load_json(state_path)))


def check_portraits(errors: list[str]) -> None:
    data = load_json(CONTENT / "npcs/npcs.json")
    for npc in data.get("npcs", []):
        portrait = npc.get("portrait_set", {})
        base = portrait.get("base_path", "")
        if not base.startswith("res://"):
            errors.append(f"{npc.get('npc_id')}: portrait base_path must use res://")
            continue
        base_dir = ROOT / base.removeprefix("res://")
        for expression, filename in portrait.get("expressions", {}).items():
            path = base_dir / filename
            if not path.exists():
                errors.append(f"Missing portrait {npc.get('npc_id')}:{expression}: {path.relative_to(ROOT)}")
    fallback = ROOT / "assets/portraits/fallback/npc_missing.png"
    if not fallback.exists():
        errors.append("Missing fallback portrait")


def check_asset_counts(errors: list[str]) -> None:
    portrait_files = list((ROOT / "assets/portraits").rglob("*.png"))
    bg_files = list((ROOT / "assets/backgrounds/nv7").glob("*.png"))
    sfx_files = list((ROOT / "assets/audio/sfx").glob("*.wav"))
    music_files = list((ROOT / "assets/audio/music").glob("*.ogg"))
    if len(portrait_files) != 21:
        errors.append(f"Expected 21 placeholder portrait PNGs, found {len(portrait_files)}")
    if len(bg_files) != 8:
        errors.append(f"Expected 8 background cards, found {len(bg_files)}")
    if not 10 <= len(sfx_files) <= 15:
        errors.append(f"Expected 10-15 SFX placeholders, found {len(sfx_files)}")
    if len(music_files) != 3:
        errors.append(f"Expected 3 music placeholders, found {len(music_files)}")


def check_formal_quests(errors: list[str]) -> None:
    manifest = load_json(CONTENT / "manifest.json")
    listed = {str(path).replace("\\", "/") for path in manifest.get("content_files", [])}
    quest_schema = SCHEMAS / "quest.schema.json"
    for quest in sorted((CONTENT / "quests").rglob("*.json")):
        relative = quest.relative_to(CONTENT).as_posix()
        validate_schema(quest, quest_schema, errors)
        try:
            status = load_json(quest).get("content_status")
        except Exception:
            continue
        if status not in {"data_ready", "implemented", "verified"}:
            errors.append(f"Runtime quest directory contains non-runtime status '{status}': {relative}")
        if relative not in listed:
            errors.append(f"Runtime quest is not registered in content manifest: {relative}")


def check_story_governance(errors: list[str]) -> None:
    region = load_json(ROOT / "docs/story/scripts/nv7/region_manifest.json")
    region_ids = [entry.get("task_id") for entry in region.get("tasks", [])]
    expected = [f"NV_MAIN_{index:03d}" for index in range(1, 9)]
    if region_ids != expected:
        errors.append("NV7 region manifest must list NV_MAIN_001 through NV_MAIN_008 in order")
    for entry in region.get("tasks", []):
        status = entry.get("status")
        script_path = entry.get("script_path")
        runtime_path = entry.get("runtime_path")
        if status == "SOURCE_ONLY" and (script_path is not None or runtime_path is not None):
            errors.append(f"SOURCE_ONLY NV7 task must not declare paths: {entry.get('task_id')}")
        elif status in {"DRAFT", "COMPLETE_SCRIPT", "PARSED"} and (
            not isinstance(script_path, str) or runtime_path is not None
        ):
            errors.append(f"Script-stage NV7 task must declare only script_path: {entry.get('task_id')}")
        elif status in {"DATA_READY", "VERIFIED"} and (
            not isinstance(script_path, str) or not isinstance(runtime_path, str)
        ):
            errors.append(f"Runtime-stage NV7 task must declare script and runtime paths: {entry.get('task_id')}")

    root_manifest = load_json(CONTENT / "manifest.json")
    root_entries = root_manifest.get("planned_content", [])
    root_ids = [entry.get("content_id") for entry in root_entries]
    if root_ids != region_ids:
        errors.append("NV7 region manifest and runtime planned_content disagree")
    root_by_id = {entry.get("content_id"): entry for entry in root_entries}
    for entry in region.get("tasks", []):
        root_entry = root_by_id.get(entry.get("task_id"), {})
        if entry.get("status") == "SOURCE_ONLY" and root_entry.get("status") != "not_loaded":
            errors.append(f"SOURCE_ONLY region task must remain unloaded at runtime: {entry.get('task_id')}")
        if entry.get("status") in {"DATA_READY", "VERIFIED"} and root_entry.get("status") not in {"data_ready", "implemented", "verified"}:
            errors.append(f"Runtime-ready region task is not loaded by content manifest: {entry.get('task_id')}")
    task_statuses = {entry.get("status") for entry in region.get("tasks", [])}
    expected_runtime_status = (
        "EMPTY_SHELL" if task_statuses == {"SOURCE_ONLY"}
        else "VERIFIED" if task_statuses == {"VERIFIED"}
        else "READY" if task_statuses <= {"DATA_READY", "VERIFIED"}
        else "PARTIAL"
    )
    if region.get("runtime_status") != expected_runtime_status:
        errors.append(f"NV7 runtime_status must be {expected_runtime_status} for its task states")

    chapter_map = load_json(ROOT / "docs/story/chapter_mapping_nv7.json")
    chapters = chapter_map.get("source_chapters", [])
    mapped = [entry.get("chapter_id") for entry in chapter_map.get("mappings", [])]
    if len(mapped) != len(set(mapped)):
        errors.append("Chapter mapping repeats a source chapter")
    unknown = sorted(set(mapped) - set(chapters))
    for chapter_id in unknown:
        errors.append(f"Chapter mapping references undeclared chapter: {chapter_id}")
    if chapter_map.get("coverage_status") == "COMPLETE":
        if not chapters:
            errors.append("Complete chapter mapping must declare at least one source chapter")
        if set(mapped) != set(chapters):
            errors.append("Complete chapter mapping must classify every source chapter exactly once")
        for mapping in chapter_map.get("mappings", []):
            for task_id in mapping.get("task_ids", []):
                if task_id not in region_ids:
                    errors.append(f"Chapter mapping references unknown NV7 task: {task_id}")

    registry = load_json(ROOT / "docs/story/foreshadowing_registry.json")
    ids = [entry.get("foreshadowing_id") for entry in registry.get("entries", [])]
    expected_foreshadowing = {
        "RETURN_CHANNEL", "EXTERNAL_AUTHORITY", "PLAYERS_TRAPPED", "WORLD_REALITY",
        "LIVE_CREATURE_PURCHASE", "SILVER_BLACK_SYSTEM_MATERIAL", "GREED_RING",
        "LANYIN_CHARACTER_ARC",
    }
    if set(ids) != expected_foreshadowing or len(ids) != len(expected_foreshadowing):
        errors.append("Foreshadowing registry must contain the eight reserved canonical IDs exactly once")

    package_manifest = load_json(ROOT / "docs/story/story_package_manifest.json")
    packages = package_manifest.get("packages", [])
    registered_files = {entry.get("file") for entry in packages if isinstance(entry, dict)}
    incoming_root = ROOT / "docs/story/raw_sources/incoming"
    actual_files = {
        path.relative_to(ROOT).as_posix()
        for path in incoming_root.glob("*.zip")
    }
    if registered_files != actual_files or len(packages) != len(actual_files):
        errors.append("Incoming story ZIP files and story package manifest disagree")
    for package in packages:
        if not isinstance(package, dict):
            continue
        package_path = ROOT / str(package.get("file", ""))
        report_path = ROOT / str(package.get("preflight_report", ""))
        if not package_path.exists() or not report_path.exists():
            errors.append(f"Story package source or preflight report is missing: {package.get('package_id')}")
            continue
        digest = hashlib.sha256(package_path.read_bytes()).hexdigest()
        report = load_json(report_path)
        if digest != package.get("sha256") or report.get("sha256") != digest:
            errors.append(f"Story package hash chain is invalid: {package.get('package_id')}")
        if report.get("package") != package_path.name:
            errors.append(f"Story preflight report names the wrong package: {package.get('package_id')}")


def check_export_exclusions(errors: list[str]) -> None:
    preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    match = re.search(r'^exclude_filter="([^"]*)"', preset, re.MULTILINE)
    filters = set(match.group(1).split(",")) if match else set()
    required = {"content/tests/**", "tests/**", "docs/story/raw_sources/**", "docs/story/**/fixtures/**"}
    for missing in sorted(required - filters):
        errors.append(f"Windows export does not exclude development content: {missing}")


def check_story_sources(errors: list[str]) -> None:
    manifest_path = ROOT / "docs/story/source_manifest.json"
    if not manifest_path.exists():
        return
    data = load_json(manifest_path)
    sources = data.get("sources", [])
    active = [s for s in sources if s.get("bucket") == "active" and s.get("authority") == "current_story_source"]
    if len(active) != 1:
        errors.append(f"Expected exactly one active current story source, found {len(active)}")
    elif active[0].get("title") != "王者_第七新手村完整剧情母稿_v0.1.md":
        errors.append("Unexpected active story source title")
    for source in sources:
        if source.get("bucket") in {"roadmap", "reference"} and source.get("authority") == "current_story_source":
            errors.append(f"Non-active source cannot be current authority: {source.get('title')}")
    index_path = ROOT / "docs/story/active/00_第七新手村剧情源接入索引.md"
    if index_path.exists():
        index = index_path.read_text(encoding="utf-8")
        for phrase in ["韩石的试刃", "苏芷的药篮", "顾长川的界石", "NV_MAIN_008"]:
            if phrase not in index:
                errors.append(f"Active story index missing: {phrase}")


def check_current_commission_contract(errors: list[str]) -> None:
    registry = load_json(CONTENT / "states/state_registry.json")
    keys = {s.get("key") for s in registry.get("states", [])}
    required = {
        "quest.nv_main_002.commission.hanshi_trial.status",
        "quest.nv_main_002.commission.suzhi_herb_basket.status",
        "quest.nv_main_002.commission.guchangchuan_boundary_stones.status",
    }
    for key in sorted(required - keys):
        errors.append(f"Missing current commission state: {key}")
    for stale in ["quest.nv_side_001.status", "quest.nv_side_002.status", "quest.nv_side_003.status"]:
        if stale in keys:
            errors.append(f"Stale commission state must not remain in runtime registry: {stale}")


def validate_quest_dependency_graph(document: Any) -> list[str]:
    """Return deterministic semantic errors for a quest dependency document.

    JSON Schema validates the shape of the document; this function owns graph
    invariants that Schema cannot express, and is intentionally side-effect free
    so tests and future conversion tools can call it directly.
    """
    errors: list[str] = []
    graph: dict[str, list[str]] = {}
    seen_owners: set[str] = set()

    quests = document.get("quests", []) if isinstance(document, dict) else []
    for raw_entry in quests:
        if not isinstance(raw_entry, dict):
            continue
        owner = raw_entry.get("quest_id")
        if not isinstance(owner, str):
            continue
        if owner in seen_owners:
            errors.append(f"Duplicate quest dependency owner: {owner}")
        else:
            seen_owners.add(owner)
            graph[owner] = []

        seen_edges: set[str] = set()
        for dependency in raw_entry.get("depends_on", []):
            if not isinstance(dependency, str):
                continue
            if dependency in seen_edges:
                errors.append(f"Quest '{owner}' repeats dependency '{dependency}'")
                continue
            seen_edges.add(dependency)
            if dependency == owner:
                errors.append(f"Quest dependency self-cycle: {owner}")
                continue
            graph.setdefault(owner, []).append(dependency)
            graph.setdefault(dependency, [])

    visit_state: dict[str, int] = {}
    active_path: list[str] = []
    reported_cycles: set[tuple[str, ...]] = set()

    def visit(node: str) -> None:
        visit_state[node] = 1
        active_path.append(node)
        for dependency in graph.get(node, []):
            state = visit_state.get(dependency, 0)
            if state == 0:
                visit(dependency)
            elif state == 1:
                start = active_path.index(dependency)
                cycle = tuple(active_path[start:] + [dependency])
                if cycle not in reported_cycles:
                    reported_cycles.add(cycle)
                    errors.append(f"Quest dependency cycle: {' -> '.join(cycle)}")
        active_path.pop()
        visit_state[node] = 2

    for quest_id in graph:
        if visit_state.get(quest_id, 0) == 0:
            visit(quest_id)
    return errors


def validate_combat_registries(
    combat_document: Any,
    enemy_document: Any,
    skill_document: Any,
) -> list[str]:
    """Validate cross-registry CombatRunner invariants without side effects.

    Legacy 1.3 registries deliberately remain valid when they omit ``runtime``.
    Once a combat registry declares the optional runtime contract, every runtime
    reference is checked here because JSON Schema cannot express cross-file IDs.
    """

    errors: list[str] = []
    combats = combat_document.get("combats", []) if isinstance(combat_document, dict) else []
    enemies = enemy_document.get("enemies", []) if isinstance(enemy_document, dict) else []
    skills = skill_document.get("skills", []) if isinstance(skill_document, dict) else []
    combat_runtime = combat_document.get("runtime") if isinstance(combat_document, dict) else None

    def index_entries(entries: Any, id_field: str, label: str) -> dict[str, dict[str, Any]]:
        indexed: dict[str, dict[str, Any]] = {}
        if not isinstance(entries, list):
            return indexed
        for raw_entry in entries:
            if not isinstance(raw_entry, dict):
                continue
            entry_id = raw_entry.get(id_field)
            if not isinstance(entry_id, str):
                continue
            if entry_id in indexed:
                errors.append(f"Duplicate {label} ID: {entry_id}")
                continue
            indexed[entry_id] = raw_entry
        return indexed

    skill_by_id = index_entries(skills, "skill_id", "skill")
    enemy_by_id = index_entries(enemies, "enemy_id", "enemy")
    index_entries(combats, "combat_id", "combat")

    status_by_id: dict[str, dict[str, Any]] = {}
    if isinstance(combat_runtime, dict):
        status_by_id = index_entries(
            combat_runtime.get("status_definitions", []),
            "status_id",
            "combat status",
        )
        rules = combat_runtime.get("rules", {})
        if isinstance(rules, dict):
            if rules.get("initiative_random_min", 0) > rules.get("initiative_random_max", 0):
                errors.append("Combat initiative random minimum exceeds maximum")
            if rules.get("damage_variance_min", 0) > rules.get("damage_variance_max", 0):
                errors.append("Combat damage variance minimum exceeds maximum")
            if rules.get("retreat_min_chance", 0) > rules.get("retreat_max_chance", 0):
                errors.append("Combat retreat minimum chance exceeds maximum")
            guard_status_id = rules.get("guard_status_id")
            if guard_status_id not in status_by_id:
                errors.append(f"Combat rules reference unknown guard status: {guard_status_id}")

        for status_id, status in status_by_id.items():
            stack_policy = status.get("stack_policy")
            max_stacks = status.get("max_stacks")
            if stack_policy in {"replace", "refresh"} and max_stacks != 1:
                errors.append(f"Combat status '{status_id}' must use max_stacks=1 for {stack_policy}")
            if stack_policy == "stack" and isinstance(max_stacks, int) and max_stacks < 2:
                errors.append(f"Combat status '{status_id}' stack policy requires max_stacks >= 2")
            behavior = status.get("behavior")
            if behavior == "periodic_effect" and not isinstance(status.get("tick_effect"), dict):
                errors.append(f"Combat status '{status_id}' periodic behavior requires tick_effect")
            if behavior == "skip_action" and status.get("block_action") is not True:
                errors.append(f"Combat status '{status_id}' skip_action behavior must block actions")
            if behavior == "damage_reduction" and "direct_damage_reduction" not in status:
                errors.append(f"Combat status '{status_id}' damage reduction requires a reduction value")
            if behavior == "stat_modifier" and not status.get("stat_modifiers"):
                errors.append(f"Combat status '{status_id}' stat modifier requires at least one modifier")

    def validate_status_conditions(owner: str, conditions: Any) -> None:
        if not isinstance(conditions, list):
            return
        for condition in conditions:
            if not isinstance(condition, dict):
                continue
            if condition.get("type") == "status" and status_by_id:
                status_id = condition.get("status_id")
                if status_id not in status_by_id:
                    errors.append(f"{owner} references unknown status: {status_id}")
            if condition.get("type") == "hp_threshold":
                value = condition.get("value")
                if not isinstance(value, (int, float)) or not 0 <= value <= 1:
                    errors.append(f"{owner} has invalid HP threshold: {value}")

    def validate_skill_list(owner: str, raw_ids: Any) -> set[str]:
        if not isinstance(raw_ids, list):
            return set()
        if len(raw_ids) > 4:
            errors.append(f"{owner} equips more than four skills")
        seen: set[str] = set()
        for raw_skill_id in raw_ids:
            if not isinstance(raw_skill_id, str):
                continue
            if raw_skill_id in seen:
                errors.append(f"{owner} repeats skill: {raw_skill_id}")
            seen.add(raw_skill_id)
            if raw_skill_id not in skill_by_id:
                errors.append(f"{owner} references unknown skill: {raw_skill_id}")
        return seen

    def validate_ai_actions(
        owner: str,
        actions: Any,
        allowed_skills: set[str],
        require_tendencies: bool = False,
    ) -> set[str]:
        if not isinstance(actions, list):
            return set()
        action_ids: set[str] = set()
        total_weight = 0.0
        tendency_totals = {"offensive": 0.0, "defensive": 0.0, "support": 0.0}
        for action in actions:
            if not isinstance(action, dict):
                continue
            action_id = action.get("action_id")
            if isinstance(action_id, str):
                if action_id in action_ids:
                    errors.append(f"{owner} repeats AI action ID: {action_id}")
                action_ids.add(action_id)
            weight = action.get("weight", 0)
            if not isinstance(weight, (int, float)) or weight < 0:
                errors.append(f"{owner} AI action '{action_id}' has invalid weight: {weight}")
                weight = 0
            total_weight += float(weight)
            action_type = action.get("action_type")
            skill_id = action.get("skill_id")
            if action_type == "skill":
                if skill_id not in skill_by_id:
                    errors.append(f"{owner} AI action '{action_id}' references unknown skill: {skill_id}")
                elif skill_id not in allowed_skills:
                    errors.append(f"{owner} AI action '{action_id}' uses an unequipped skill: {skill_id}")
            elif skill_id is not None:
                errors.append(f"{owner} non-skill AI action '{action_id}' must not declare skill_id")
            conditions = action.get("conditions", [])
            if action.get("mode") == "conditional_action" and not conditions:
                errors.append(f"{owner} conditional AI action '{action_id}' requires a condition")
            validate_status_conditions(f"{owner} AI action '{action_id}'", conditions)
            if require_tendencies:
                tendencies = action.get("tendency_weights", {})
                for tendency in tendency_totals:
                    multiplier = tendencies.get(tendency, 0) if isinstance(tendencies, dict) else 0
                    if not isinstance(multiplier, (int, float)) or multiplier < 0:
                        errors.append(
                            f"{owner} AI action '{action_id}' has invalid {tendency} tendency weight"
                        )
                        multiplier = 0
                    tendency_totals[tendency] += float(weight) * float(multiplier)
        if actions and total_weight <= 0:
            errors.append(f"{owner} AI actions have no positive total weight")
        if require_tendencies:
            for tendency, total in tendency_totals.items():
                if total <= 0:
                    errors.append(f"{owner} has no usable AI action for {tendency} tendency")
        return action_ids

    for skill_id, skill in skill_by_id.items():
        for effect in skill.get("effects", []):
            if not isinstance(effect, dict) or not status_by_id:
                continue
            if effect.get("effect") in {"apply_status", "remove_status"}:
                status_id = effect.get("status_id")
                if status_id not in status_by_id:
                    errors.append(f"Skill '{skill_id}' references unknown status: {status_id}")
        runtime = skill.get("runtime")
        if isinstance(runtime, dict):
            validate_status_conditions(f"Skill '{skill_id}'", runtime.get("conditions", []))

    enemy_action_ids: dict[str, set[str]] = {}
    for enemy_id, enemy in enemy_by_id.items():
        allowed_skills = validate_skill_list(f"Enemy '{enemy_id}'", enemy.get("skill_ids", []))
        runtime = enemy.get("runtime")
        if not isinstance(runtime, dict):
            continue
        enemy_action_ids[enemy_id] = validate_ai_actions(
            f"Enemy '{enemy_id}'",
            runtime.get("ai_actions", []),
            allowed_skills,
        )
        if status_by_id:
            for status_id in runtime.get("status_immunities", []):
                if status_id not in status_by_id:
                    errors.append(f"Enemy '{enemy_id}' is immune to unknown status: {status_id}")

    for combat in combats if isinstance(combats, list) else []:
        if not isinstance(combat, dict):
            continue
        combat_id = combat.get("combat_id", "<unknown>")
        for enemy_id in combat.get("enemy_ids", []):
            if enemy_id not in enemy_by_id:
                errors.append(f"Combat '{combat_id}' references unknown enemy: {enemy_id}")
        runtime = combat.get("runtime")
        if not isinstance(runtime, dict):
            continue
        if not isinstance(combat_runtime, dict):
            errors.append(f"Combat '{combat_id}' has runtime data without a runtime registry")

        player = runtime.get("player_unit", {})
        player_id = player.get("unit_id") if isinstance(player, dict) else None
        unit_ids: set[str] = set()
        if isinstance(player_id, str):
            unit_ids.add(player_id)
        validate_skill_list(f"Combat '{combat_id}' player", player.get("skill_ids", []))

        for companion in runtime.get("companion_units", []):
            if not isinstance(companion, dict):
                continue
            unit_id = companion.get("unit_id")
            if unit_id in unit_ids:
                errors.append(f"Combat '{combat_id}' repeats unit ID: {unit_id}")
            if isinstance(unit_id, str):
                unit_ids.add(unit_id)
            companion_skills = validate_skill_list(
                f"Combat '{combat_id}' companion '{unit_id}'",
                companion.get("skill_ids", []),
            )
            validate_ai_actions(
                f"Combat '{combat_id}' companion '{unit_id}'",
                companion.get("ai_actions", []),
                companion_skills,
                require_tendencies=True,
            )

        runtime_enemy_counts: Counter[str] = Counter()
        enemy_id_by_unit: dict[str, str] = {}
        for instance in runtime.get("enemy_instances", []):
            if not isinstance(instance, dict):
                continue
            unit_id = instance.get("unit_id")
            enemy_id = instance.get("enemy_id")
            if unit_id in unit_ids:
                errors.append(f"Combat '{combat_id}' repeats unit ID: {unit_id}")
            if isinstance(unit_id, str):
                unit_ids.add(unit_id)
            if enemy_id not in enemy_by_id:
                errors.append(f"Combat '{combat_id}' instance '{unit_id}' references unknown enemy: {enemy_id}")
            elif isinstance(unit_id, str) and isinstance(enemy_id, str):
                enemy_id_by_unit[unit_id] = enemy_id
                runtime_enemy_counts[enemy_id] += 1
        if Counter(combat.get("enemy_ids", [])) != runtime_enemy_counts:
            errors.append(f"Combat '{combat_id}' runtime enemy instances do not match enemy_ids")

        phases = runtime.get("phases", [])
        phase_ids: set[str] = set()
        hp_thresholds: list[float] = []
        has_start_phase = False
        for phase in phases:
            if not isinstance(phase, dict):
                continue
            phase_id = phase.get("phase_id")
            if phase_id in phase_ids:
                errors.append(f"Combat '{combat_id}' repeats phase ID: {phase_id}")
            if isinstance(phase_id, str):
                phase_ids.add(phase_id)
            target_unit_id = phase.get("target_unit_id")
            if target_unit_id not in unit_ids:
                errors.append(f"Combat '{combat_id}' phase '{phase_id}' references unknown unit: {target_unit_id}")
            validate_skill_list(
                f"Combat '{combat_id}' phase '{phase_id}'",
                phase.get("skill_ids", []),
            )
            trigger = phase.get("trigger", {})
            if isinstance(trigger, dict):
                trigger_type = trigger.get("type")
                if trigger_type == "combat_start":
                    if has_start_phase:
                        errors.append(f"Combat '{combat_id}' declares more than one combat_start phase")
                    has_start_phase = True
                if trigger_type in {"hp_threshold", "status"} and trigger.get("unit_id") not in unit_ids:
                    errors.append(
                        f"Combat '{combat_id}' phase '{phase_id}' trigger references unknown unit: "
                        f"{trigger.get('unit_id')}"
                    )
                if trigger_type == "hp_threshold":
                    value = trigger.get("value")
                    if not isinstance(value, (int, float)) or not 0 <= value <= 1:
                        errors.append(f"Combat '{combat_id}' phase '{phase_id}' has invalid HP threshold: {value}")
                    else:
                        hp_thresholds.append(float(value))
                if trigger_type == "status" and status_by_id and trigger.get("status_id") not in status_by_id:
                    errors.append(
                        f"Combat '{combat_id}' phase '{phase_id}' references unknown status: "
                        f"{trigger.get('status_id')}"
                    )
            target_enemy_id = enemy_id_by_unit.get(str(target_unit_id))
            known_actions = enemy_action_ids.get(target_enemy_id, set())
            for action_id in phase.get("ai_weight_modifiers", {}):
                if known_actions and action_id not in known_actions:
                    errors.append(
                        f"Combat '{combat_id}' phase '{phase_id}' references unknown AI action: {action_id}"
                    )
        if not has_start_phase:
            errors.append(f"Combat '{combat_id}' runtime phases require one combat_start phase")
        if any(left <= right for left, right in zip(hp_thresholds, hp_thresholds[1:])):
            errors.append(f"Combat '{combat_id}' HP phase thresholds must descend without duplicates")

        contains_boss = any(enemy_by_id.get(enemy_id, {}).get("boss") is True for enemy_id in runtime_enemy_counts)
        if contains_boss and not 2 <= len(phases) <= 3:
            errors.append(f"Combat '{combat_id}' boss runtime must declare two or three phases")

        inspect_ids: set[str] = set()
        for inspect_rule in runtime.get("inspect_rules", []):
            if not isinstance(inspect_rule, dict):
                continue
            inspect_id = inspect_rule.get("inspect_id")
            if inspect_id in inspect_ids:
                errors.append(f"Combat '{combat_id}' repeats inspect ID: {inspect_id}")
            if isinstance(inspect_id, str):
                inspect_ids.add(inspect_id)
            if inspect_rule.get("target_unit_id") not in unit_ids:
                errors.append(
                    f"Combat '{combat_id}' inspect '{inspect_id}' references unknown unit: "
                    f"{inspect_rule.get('target_unit_id')}"
                )
            if inspect_rule.get("seeded") is True and inspect_rule.get("difficulty", 0) <= 0:
                errors.append(f"Combat '{combat_id}' seeded inspect '{inspect_id}' requires difficulty > 0")
            for condition in inspect_rule.get("conditions", []):
                if not isinstance(condition, dict):
                    continue
                if condition.get("type") == "status" and status_by_id and condition.get("status_id") not in status_by_id:
                    errors.append(
                        f"Combat '{combat_id}' inspect '{inspect_id}' references unknown status: "
                        f"{condition.get('status_id')}"
                    )
                if condition.get("type") == "phase" and condition.get("phase_id") not in phase_ids:
                    errors.append(
                        f"Combat '{combat_id}' inspect '{inspect_id}' references unknown phase: "
                        f"{condition.get('phase_id')}"
                    )

        retreat = runtime.get("retreat", {})
        if isinstance(retreat, dict):
            allowed = retreat.get("allowed") is True
            mode = retreat.get("mode")
            if allowed and mode == "disabled":
                errors.append(f"Combat '{combat_id}' allows retreat but uses disabled mode")
            if not allowed and mode != "disabled":
                errors.append(f"Combat '{combat_id}' disables retreat but uses active mode '{mode}'")
            if allowed and not retreat.get("continuation_tag"):
                errors.append(f"Combat '{combat_id}' allowed retreat requires continuation_tag")

    return errors


def check_combat_registries(errors: list[str]) -> None:
    combat_path = CONTENT / "combats/combats.json"
    enemy_path = CONTENT / "enemies/enemies.json"
    skill_path = CONTENT / "skills/skills.json"
    if combat_path.exists() and enemy_path.exists() and skill_path.exists():
        errors.extend(
            validate_combat_registries(
                load_json(combat_path),
                load_json(enemy_path),
                load_json(skill_path),
            )
        )


def check_quest_dependencies(errors: list[str]) -> None:
    path = CONTENT / "quest_dependencies.json"
    if path.exists():
        errors.extend(validate_quest_dependency_graph(load_json(path)))


def check_offline_runtime(errors: list[str]) -> None:
    for path in (ROOT / "src").rglob("*.gd"):
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_RUNTIME_TOKENS:
            if token in text:
                errors.append(f"Offline violation in {path.relative_to(ROOT)}: {token}")


def check_agents_chain_sizes(errors: list[str]) -> None:
    """Guard common root-to-leaf AGENTS instruction chains against Codex's default 32 KiB project-doc budget."""
    root_agents = ROOT / "AGENTS.md"
    if not root_agents.exists():
        return
    root_size = root_agents.stat().st_size
    local_agents = [p for p in ROOT.rglob("AGENTS.md") if p != root_agents]
    for local in local_agents:
        combined = root_size + local.stat().st_size
        if combined >= 32 * 1024:
            rel = local.relative_to(ROOT)
            errors.append(f"AGENTS instruction chain too large for default 32 KiB budget: root + {rel} = {combined} bytes")


def check_agents(errors: list[str]) -> None:
    root_agents = ROOT / "AGENTS.md"
    size = root_agents.stat().st_size if root_agents.exists() else 0
    if not 5000 <= size <= 30000:
        errors.append(f"Root AGENTS.md should be dense but below 30 KiB; size={size}")
    required_phrases = [
        "禁止自行创作缺失的正式剧情",
        "CONTENT_MISSING",
        "Godot 4.6.2",
        "完全离线",
        "scripts/validate.ps1",
        "玩家类 NPC",
        "系统 NPC",
        "STORY_NOT_DATA_READY",
        "docs/story/source_manifest.json",
        "韩石的试刃",
        "顾长川的界石",
    ]
    text = root_agents.read_text(encoding="utf-8") if root_agents.exists() else ""
    for phrase in required_phrases:
        if phrase not in text:
            errors.append(f"AGENTS.md missing critical rule marker: {phrase}")


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).exists():
            errors.append(f"Missing required file: {rel}")
    for data_rel, schema_name in SCHEMA_MAP.items():
        data_path = ROOT / data_rel
        schema_path = SCHEMAS / schema_name
        if data_path.exists() and schema_path.exists():
            validate_schema(data_path, schema_path, errors)
        elif not schema_path.exists():
            errors.append(f"Missing schema: {schema_name}")
    check_manifest(errors)
    check_states(errors)
    check_items(errors)
    check_relationship_fixture(errors)
    check_combat_registries(errors)
    check_portraits(errors)
    check_asset_counts(errors)
    check_formal_quests(errors)
    check_story_sources(errors)
    check_story_governance(errors)
    check_export_exclusions(errors)
    check_current_commission_contract(errors)
    check_quest_dependencies(errors)
    check_offline_runtime(errors)
    check_agents(errors)
    check_agents_chain_sizes(errors)

    if errors:
        print("REPOSITORY VALIDATION FAILED")
        for error in sorted(set(errors)):
            print(f"- {error}")
        return 1
    print("REPOSITORY VALIDATION PASSED")
    print("- structure: ok")
    print("- schemas: ok")
    print("- manifest: ok")
    print("- portraits/backgrounds/audio placeholders: ok")
    print("- story source governance: ok")
    print("- story region/chapter/foreshadowing governance: ok")
    print("- export development-content exclusions: ok")
    print("- current commission contract: ok")
    print("- item runtime semantics: ok")
    print("- combat registry semantics: ok")
    print("- quest dependency graph: ok")
    print("- offline runtime scan: ok")
    print("- AGENTS critical rules: ok")
    print("- AGENTS instruction-chain budget: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
