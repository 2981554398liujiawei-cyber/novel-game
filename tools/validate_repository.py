#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
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
    "src/core/content_loader.gd",
    "src/core/json_schema_validator.gd",
    "scripts/validate.ps1",
    "scripts/test.ps1",
    "scripts/smoke_test.ps1",
    "scripts/build_windows.ps1",
    "docs/story/AGENTS.md",
    "docs/story/source_manifest.json",
    "docs/story/active/00_第七新手村剧情源接入索引.md",
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
    for rel in listed:
        if any(fragment in rel for fragment in forbidden):
            errors.append(f"Manifest references forbidden path: {rel}")
        if not (CONTENT / rel).exists():
            errors.append(f"Manifest references missing file: {rel}")
    for rel in listed:
        if rel.startswith("quests/") and not rel.endswith(".json"):
            errors.append(f"Quest manifest entry must be JSON: {rel}")


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


def check_no_formal_quests(errors: list[str]) -> None:
    quest_files = list((CONTENT / "quests").glob("*.json"))
    if quest_files:
        quest_schema = SCHEMAS / "quest.schema.json"
        for quest in quest_files:
            validate_schema(quest, quest_schema, errors)


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
    check_portraits(errors)
    check_asset_counts(errors)
    check_no_formal_quests(errors)
    check_story_sources(errors)
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
    print("- current commission contract: ok")
    print("- item runtime semantics: ok")
    print("- quest dependency graph: ok")
    print("- offline runtime scan: ok")
    print("- AGENTS critical rules: ok")
    print("- AGENTS instruction-chain budget: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
