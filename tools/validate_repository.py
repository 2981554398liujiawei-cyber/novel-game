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
    check_portraits(errors)
    check_asset_counts(errors)
    check_no_formal_quests(errors)
    check_story_sources(errors)
    check_current_commission_contract(errors)
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
    print("- offline runtime scan: ok")
    print("- AGENTS critical rules: ok")
    print("- AGENTS instruction-chain budget: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
