from __future__ import annotations

import copy
import hashlib
import json
import re
import zipfile
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

from jsonschema import Draft202012Validator


TOOL_VERSION = "1.1.0"
IR_VERSION = "1.0.0"
ROOT = Path(__file__).resolve().parents[2]
META_RE = re.compile(r"```story-meta[ \t]*\r?\n(.*?)\r?\n```", re.DOTALL)
NODE_RE = re.compile(r"```story-node[ \t]*\r?\n(.*?)\r?\n```", re.DOTALL)
PLACEHOLDERS = (
    "待补", "待定", "自由发挥", "双方争论一番", "NPC解释情况",
    "玩家自由选择", "根据需要生成", "TODO", "TBD",
)
LEGACY_TERMS = ("旧主角名", "旧新手村编号", "黄金铁锤", "黄金药鼎", "二十条虎尾", "模拟玩家", "5×5战棋")
RELATIONSHIP_DIMENSIONS = frozenset({"trust", "affection", "respect", "tension"})
MANAGER_KEYS = {
    "conditions": "GameState",
    "effects": "GameState",
    "quest_actions": "QuestManager",
    "item_rewards": "InventoryManager",
    "combat_id": "CombatRunner",
    "relationship_actions": "RelationshipManager",
    "expression": "MainUI",
    "gesture": "MainUI",
    "portrait_action": "MainUI",
    "camera": "MainUI",
    "delivery": "MainUI",
}
FORMAL_POLICIES = {
    # These are the automatic lower bounds from the governed complete-script
    # specification. They only reject obvious skeletons; human review remains
    # mandatory before a script can become DATA_READY.
    "main": {
        "min_visible_text_chars": 2500, "min_nodes": 6, "min_formal_turns": 30,
        "min_choice_nodes": 2, "min_terminal_nodes": 1, "min_scenes": 5,
        "min_failure_continuations": 1, "min_post_quest_feedback": 1,
    },
    "relationship": {
        "min_visible_text_chars": 2000, "min_nodes": 5, "min_formal_turns": 30,
        "min_choice_nodes": 2, "min_terminal_nodes": 1, "min_scenes": 4,
        "min_failure_continuations": 1, "min_post_quest_feedback": 1,
    },
    "side": {
        "min_visible_text_chars": 1200, "min_nodes": 4, "min_formal_turns": 12,
        "min_choice_nodes": 1, "min_terminal_nodes": 1, "min_scenes": 3,
        "min_failure_continuations": 0, "min_post_quest_feedback": 1,
    },
    "hidden": {
        "min_visible_text_chars": 500, "min_nodes": 3, "min_formal_turns": 0,
        "min_choice_nodes": 1, "min_terminal_nodes": 1, "min_scenes": 1,
        "min_failure_continuations": 0, "min_post_quest_feedback": 1,
    },
    "encounter": {
        "min_visible_text_chars": 500, "min_nodes": 3, "min_formal_turns": 0,
        "min_choice_nodes": 1, "min_terminal_nodes": 1, "min_scenes": 1,
        "min_failure_continuations": 0, "min_post_quest_feedback": 1,
    },
}
# Kept as the public default for callers that imported the first pipeline API.
FORMAL_POLICY = FORMAL_POLICIES["main"]
TEST_POLICY = {key: 0 for key in FORMAL_POLICY}
TEST_POLICY["min_terminal_nodes"] = 1
TEST_POLICY["min_scenes"] = 1


class PipelineError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(f"{code}: {message}")
        self.code = code
        self.message = message


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise PipelineError("PIPELINE_JSON_INVALID", f"{path}: {exc}") from exc


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _block_json(raw: str, label: str) -> dict[str, Any]:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise PipelineError("STORY_MARKDOWN_INVALID", f"{label} JSON解析失败: {exc}") from exc
    if not isinstance(value, dict):
        raise PipelineError("STORY_MARKDOWN_INVALID", f"{label}必须是JSON对象")
    return value


def _text_values(document: dict[str, Any]) -> Iterable[str]:
    for node in document.get("nodes", []):
        text = node.get("text", [])
        if isinstance(text, list):
            yield from (str(value) for value in text)
        elif isinstance(text, str):
            yield text
        for choice in node.get("choices", []):
            yield str(choice.get("text", ""))
            yield str(choice.get("locked_text", ""))
    for feedback in document.get("post_quest_feedback", []):
        if isinstance(feedback, dict):
            yield str(feedback.get("text", ""))
        elif isinstance(feedback, str):
            yield feedback


def _visible_text(document: dict[str, Any]) -> str:
    return "".join(_text_values(document))


def _metrics(document: dict[str, Any]) -> dict[str, Any]:
    nodes = document.get("nodes", []) if isinstance(document.get("nodes", []), list) else []
    by_type: dict[str, int] = {}
    for node in nodes:
        if not isinstance(node, dict):
            continue
        kind = str(node.get("type", "unknown"))
        by_type[kind] = by_type.get(kind, 0) + 1
    return {
        "visible_text_chars": len(_visible_text(document)),
        "node_count": len(nodes),
        "dialogue_count": by_type.get("dialogue", 0),
        "choice_count": by_type.get("choice", 0),
        "terminal_count": sum(1 for node in nodes if isinstance(node, dict) and node.get("type") == "complete" and node.get("terminal") is True),
        "node_types": by_type,
    }


def normalize_story(metadata: dict[str, Any], nodes: list[dict[str, Any]]) -> dict[str, Any]:
    """Build the deterministic normalized model from constrained Markdown blocks."""
    document = metadata.get("quest")
    baseline = metadata.get("baseline", {})
    if not isinstance(document, dict) or not isinstance(baseline, dict):
        raise PipelineError("STORY_METADATA_INVALID", "story-meta缺少quest对象或baseline不是对象")
    if "nodes" in document:
        raise PipelineError("STORY_METADATA_INVALID", "quest.nodes必须由story-node代码块生成")
    normalized = copy.deepcopy(document)
    normalized["nodes"] = copy.deepcopy(nodes)
    return {
        "baseline": copy.deepcopy(baseline),
        "ownership": copy.deepcopy(metadata.get("ownership", {})),
        "quest": normalized,
    }


def parse_markdown(path: Path) -> dict[str, Any]:
    try:
        source_bytes = path.read_bytes()
        source = source_bytes.decode("utf-8")
    except (OSError, UnicodeError) as exc:
        raise PipelineError("STORY_SOURCE_UNREADABLE", f"{path}: {exc}") from exc
    meta_blocks = META_RE.findall(source)
    if len(meta_blocks) != 1:
        raise PipelineError("STORY_METADATA_INVALID", "必须且只能包含一个story-meta代码块")
    metadata = _block_json(meta_blocks[0], "story-meta")
    nodes = [_block_json(raw, f"story-node #{index}") for index, raw in enumerate(NODE_RE.findall(source), 1)]
    if not nodes:
        raise PipelineError("STORY_MARKDOWN_INVALID", "没有story-node代码块")
    normalized = normalize_story(metadata, nodes)
    document = normalized["quest"]
    ir = {
        "ir_version": IR_VERSION,
        "tool_version": TOOL_VERSION,
        "source": {"path": path.as_posix(), "sha256": sha256_bytes(source_bytes)},
        "baseline": normalized["baseline"],
        "ownership": normalized["ownership"],
        "quest": document,
        "metrics": _metrics(document),
        "canonical_sha256": sha256_bytes(canonical_bytes(document)),
    }
    return ir


def _catalog_ids(catalog: dict[str, Any], collection: str, id_key: str) -> set[str]:
    values = catalog.get(collection, []) if isinstance(catalog, dict) else []
    return {str(value.get(id_key)) for value in values if isinstance(value, dict) and value.get(id_key)}


def _collect_transitions(node: dict[str, Any]) -> list[str]:
    targets: list[str] = []
    for key in ("next", "next_on_win", "next_on_loss"):
        if isinstance(node.get(key), str) and node[key]:
            targets.append(node[key])
    for choice in node.get("choices", []):
        if isinstance(choice, dict) and isinstance(choice.get("goto"), str) and choice["goto"]:
            targets.append(choice["goto"])
    return targets


def _objects_with_state_ops(quest: dict[str, Any]) -> Iterable[tuple[str, dict[str, Any]]]:
    for key in ("prerequisites",):
        for value in quest.get(key, []):
            if isinstance(value, dict):
                yield key, value
    trigger = quest.get("trigger", {})
    for value in trigger.get("conditions", []) if isinstance(trigger, dict) else []:
        if isinstance(value, dict):
            yield "trigger.conditions", value
    runtime = quest.get("runtime", {})
    if isinstance(runtime, dict):
        availability = runtime.get("availability", {})
        for group in ("all", "any"):
            for value in availability.get(group, []) if isinstance(availability, dict) else []:
                if isinstance(value, dict) and value.get("kind") == "state":
                    yield f"runtime.availability.{group}", value
        for objective in runtime.get("objectives", []):
            if isinstance(objective, dict) and isinstance(objective.get("condition"), dict):
                yield "runtime.objectives.condition", objective["condition"]
    for node in quest.get("nodes", []):
        if not isinstance(node, dict):
            continue
        for key in ("conditions", "effects"):
            for value in node.get(key, []):
                if isinstance(value, dict):
                    yield f"{node.get('node_id')}.{key}", value
        for choice in node.get("choices", []):
            if not isinstance(choice, dict):
                continue
            for key in ("conditions", "effects"):
                for value in choice.get(key, []):
                    if isinstance(value, dict):
                        yield f"{node.get('node_id')}.{choice.get('choice_id')}.{key}", value


def _schema_errors(value: Any, schema_name: str) -> list[str]:
    path = ROOT / "schemas" / schema_name
    if not path.is_file():
        return [f"缺少Schema: {schema_name}"]
    schema = load_json(path)
    result = []
    for error in Draft202012Validator(schema).iter_errors(value):
        location = ".".join(str(part) for part in error.absolute_path) or "<root>"
        result.append(f"{location}: {error.message}")
    return result


def _can_reach_terminal(graph: dict[str, list[str]], terminals: set[str]) -> set[str]:
    reverse = {node_id: [] for node_id in graph}
    for owner, targets in graph.items():
        for target in targets:
            if target in reverse:
                reverse[target].append(owner)
    reachable = set(terminals)
    pending = list(terminals)
    while pending:
        current = pending.pop()
        for previous in reverse.get(current, []):
            if previous not in reachable:
                reachable.add(previous)
                pending.append(previous)
    return reachable


def validate_chapter_mapping(mapping: dict[str, Any], expected_chapters: Iterable[str] | None = None) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []
    if not isinstance(mapping, dict):
        return [{"code": "CHAPTER_MAPPING_INVALID", "message": "章节映射必须是对象"}]
    # The first prototype used chapters/source_chapter/disposition.  Keep it
    # readable for old generated reports, but make the governed repository
    # contract (source_chapters + mappings) authoritative.
    formal_shape = "mappings" in mapping or "source_chapters" in mapping
    entries = mapping.get("mappings", []) if formal_shape else mapping.get("chapters", [])
    declared = set(mapping.get("source_chapters", [])) if formal_shape else set(expected_chapters or [])
    seen: set[str] = set()
    allowed = {"KEEP_GAME", "MERGE_GAME", "MIGRATE_REALITY", "DROP"}
    for entry in entries:
        chapter = entry.get("chapter_id") if formal_shape and isinstance(entry, dict) else entry.get("source_chapter") if isinstance(entry, dict) else None
        disposition = entry.get("classification") if formal_shape and isinstance(entry, dict) else entry.get("disposition") if isinstance(entry, dict) else None
        if not isinstance(chapter, str) or not chapter:
            errors.append({"code": "CHAPTER_MAPPING_INVALID", "message": "章节映射缺少source_chapter"})
        elif chapter in seen:
            errors.append({"code": "CHAPTER_MAPPING_DUPLICATE", "message": f"章节重复映射: {chapter}"})
        else:
            seen.add(chapter)
        if disposition not in allowed:
            errors.append({"code": "CHAPTER_MAPPING_INVALID", "message": f"非法章节分类: {disposition}"})
        if formal_shape and chapter and chapter not in declared:
            errors.append({"code": "CHAPTER_MAPPING_INVALID", "message": f"映射章节未在source_chapters声明: {chapter}"})
    required = declared | set(expected_chapters or [])
    for chapter in required:
        if chapter not in seen:
            errors.append({"code": "CHAPTER_MAPPING_MISSING", "message": f"章节缺失映射: {chapter}"})
    return errors


def validate_foreshadowing(registry: dict[str, Any], referenced_ids: Iterable[str] = ()) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []
    entries = registry.get("entries", registry.get("foreshadowing", [])) if isinstance(registry, dict) else []
    required = {"foreshadowing_id", "title", "first_appearance", "reinforcement_nodes", "misdirection_nodes", "reveal_node", "payoff_node", "status"}
    seen: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict) or not required.issubset(entry):
            errors.append({"code": "FORESHADOWING_INVALID", "message": "伏笔登记缺少必填字段"})
            continue
        identifier = entry["foreshadowing_id"]
        if identifier in seen:
            errors.append({"code": "FORESHADOWING_DUPLICATE", "message": f"伏笔ID重复: {identifier}"})
        seen.add(identifier)
    for identifier in referenced_ids:
        if identifier not in seen:
            errors.append({"code": "FORESHADOWING_REFERENCE_INVALID", "message": f"伏笔未登记: {identifier}"})
    return errors


def check_ir(
    ir: dict[str, Any],
    catalogs: dict[str, Any] | None = None,
    policy: dict[str, int] | None = None,
    chapter_mapping: dict[str, Any] | None = None,
    expected_chapters: Iterable[str] | None = None,
    foreshadowing_registry: dict[str, Any] | None = None,
) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []

    def fail(code: str, message: str) -> None:
        errors.append({"code": code, "message": message})

    if not isinstance(ir, dict):
        return [{"code": "STORY_IR_INVALID", "message": "IR必须是对象"}]
    for message in _schema_errors(ir, "story_ir.schema.json"):
        fail("STORY_IR_SCHEMA_INVALID", message)
    quest = ir.get("quest", {})
    if not isinstance(quest, dict):
        return [{"code": "STORY_IR_INVALID", "message": "quest必须是对象"}]
    metrics = _metrics(quest)
    if ir.get("canonical_sha256") != sha256_bytes(canonical_bytes(quest)):
        fail("STORY_IR_INTEGRITY_INVALID", "canonical_sha256与quest内容不一致")
    if ir.get("metrics") != metrics:
        fail("STORY_IR_INTEGRITY_INVALID", "metrics与quest内容不一致")
    if quest.get("content_status") not in {"complete_script", "data_ready"}:
        fail("STORY_NOT_DATA_READY", "Markdown必须达到complete_script或data_ready")
    effective_policy = dict(FORMAL_POLICIES.get(str(quest.get("category", "main")), FORMAL_POLICY))
    if policy is not None:
        effective_policy.update(policy)
    formal_turns = metrics["dialogue_count"] + sum(
        len(node.get("choices", []))
        for node in quest.get("nodes", [])
        if isinstance(node, dict) and isinstance(node.get("choices", []), list)
    )
    failure_continuations = sum(
        1 for continuation in quest.get("continuations", [])
        if isinstance(continuation, dict)
        and str(continuation.get("type", "")).lower() in {"failure", "failed", "loss", "resume", "reopen"}
    )
    failure_continuations += sum(
        1 for node in quest.get("nodes", [])
        if isinstance(node, dict) and isinstance(node.get("next_on_loss"), str) and node["next_on_loss"]
    )
    checks = {
        "min_visible_text_chars": metrics["visible_text_chars"],
        "min_nodes": metrics["node_count"],
        "min_formal_turns": formal_turns,
        "min_choice_nodes": metrics["choice_count"],
        "min_terminal_nodes": metrics["terminal_count"],
        "min_scenes": len(quest.get("scenes", [])),
        "min_failure_continuations": failure_continuations,
        "min_post_quest_feedback": len(quest.get("post_quest_feedback", [])),
    }
    for key, actual in checks.items():
        if actual < effective_policy[key]:
            fail("STORY_DEPTH_INSUFFICIENT", f"{key}={actual}，最低要求{effective_policy[key]}")

    nodes = quest.get("nodes", [])
    if not isinstance(nodes, list):
        fail("STORY_IR_INVALID", "nodes必须是数组")
        return errors
    node_ids = [node.get("node_id") if isinstance(node, dict) else None for node in nodes]
    node_set = {node_id for node_id in node_ids if isinstance(node_id, str) and node_id}
    if len(node_set) != len(node_ids):
        fail("STORY_NODE_DUPLICATE", "节点ID缺失或重复")
    entry = quest.get("entry_node")
    if entry not in node_set:
        fail("STORY_REFERENCE_INVALID", f"入口节点不存在: {entry}")
    graph: dict[str, list[str]] = {}
    terminals: set[str] = set()
    allowed_types = {"narrative", "dialogue", "choice", "combat", "reward", "complete"}
    for node in nodes:
        if not isinstance(node, dict):
            fail("STORY_NODE_INVALID", "节点必须是对象")
            continue
        node_id = str(node.get("node_id", "<unknown>"))
        kind = node.get("type")
        if kind not in allowed_types:
            fail("STORY_NODE_TYPE_INVALID", f"{node_id}节点类型未知: {kind}")
        text = node.get("text")
        if kind in {"narrative", "dialogue"} and (not isinstance(text, list) or not text or any(not isinstance(line, str) or not line.strip() for line in text)):
            fail("STORY_TEXT_EMPTY", f"{node_id}正文为空")
        if kind == "choice":
            choices = node.get("choices", [])
            if not isinstance(choices, list) or len(choices) < 2:
                fail("STORY_CHOICE_EMPTY", f"{node_id}至少需要两个实质选项")
            for choice in choices:
                if not isinstance(choice, dict) or not str(choice.get("text", "")).strip():
                    fail("STORY_TEXT_EMPTY", f"{node_id}存在空选项")
        if kind == "complete":
            if node.get("terminal") is not True:
                fail("STORY_TERMINAL_INVALID", f"{node_id}完成节点必须terminal=true")
            terminals.add(node_id)
        transitions = _collect_transitions(node)
        graph[node_id] = transitions
        for target in transitions:
            if target not in node_set:
                fail("STORY_REFERENCE_INVALID", f"{node_id}跳转到不存在节点{target}")
        if kind != "complete" and not transitions:
            fail("STORY_NODE_NO_EXIT", f"{node_id}没有出口")
        if kind == "combat" and not node.get("next_on_loss"):
            fail("STORY_FAILURE_CONTINUATION_MISSING", f"{node_id}缺少失败续接")
    reachable: set[str] = set()
    if entry in node_set:
        pending = [entry]
        while pending:
            current = pending.pop()
            if current in reachable:
                continue
            reachable.add(current)
            pending.extend(target for target in graph.get(current, []) if target in node_set)
        for missing in sorted(node_set - reachable):
            fail("STORY_NODE_UNREACHABLE", f"节点不可达: {missing}")
        terminal_reachable = _can_reach_terminal(graph, terminals)
        for trapped in sorted(reachable - terminal_reachable):
            fail("STORY_DEAD_LOOP", f"节点无法到达完成出口: {trapped}")
    for scene in quest.get("scenes", []):
        if not isinstance(scene, dict):
            fail("STORY_SCENE_EMPTY", "场景必须是对象")
            continue
        if not scene.get("entry_nodes") or not scene.get("exit_nodes"):
            fail("STORY_SCENE_EMPTY", f"场景缺少入口或出口: {scene.get('scene_id')}")
        for target in list(scene.get("entry_nodes", [])) + list(scene.get("exit_nodes", [])):
            if target not in node_set:
                fail("STORY_REFERENCE_INVALID", f"场景引用不存在节点: {target}")
    visible = _visible_text(quest)
    for token in PLACEHOLDERS:
        if token.casefold() in visible.casefold():
            fail("STORY_PLACEHOLDER_FOUND", f"玩家可见文本含占位表达: {token}")
    for token in LEGACY_TERMS:
        if token.casefold() in visible.casefold():
            fail("STORY_CANON_VIOLATION", f"玩家可见文本含旧版或禁用表达: {token}")
    declared = ir.get("ownership", {})
    for key, owner in MANAGER_KEYS.items():
        if not isinstance(declared, dict) or declared.get(key) != owner:
            fail("MANAGER_OWNERSHIP_INVALID", f"{key}必须归属{owner}")
    for node in nodes:
        if not isinstance(node, dict):
            continue
        owners = [node, *(choice for choice in node.get("choices", []) if isinstance(choice, dict))]
        for owner in owners:
            for effect in owner.get("effects", []):
                key = effect.get("key", "") if isinstance(effect, dict) else ""
                if str(key).startswith(("quest.", "inventory.", "relation.")):
                    fail("MANAGER_OWNERSHIP_INVALID", f"{key}不得通过GameState effects写入")
            for action in owner.get("relationship_actions", []):
                if not isinstance(action, dict):
                    fail("RELATIONSHIP_ACTION_INVALID", "关系动作必须是对象")
                    continue
                if action.get("dimension") and action["dimension"] not in RELATIONSHIP_DIMENSIONS:
                    fail("RELATIONSHIP_DIMENSION_INVALID", f"未登记关系维度: {action['dimension']}")
                if not action.get("relationship_id"):
                    fail("RELATIONSHIP_ACTION_INVALID", "关系动作必须指定relationship_id")
                action_type = action.get("op")
                if action_type not in {"set", "inc", "dec"}:
                    fail("RELATIONSHIP_ACTION_INVALID", f"未知关系动作: {action_type}")
                if action_type in {"set", "inc", "dec"} and action.get("dimension") not in RELATIONSHIP_DIMENSIONS:
                    fail("RELATIONSHIP_DIMENSION_INVALID", "数值关系动作必须指定正式维度")
            for action in owner.get("quest_actions", []):
                allowed = {"activate", "update_objective", "set_qualified", "complete", "fail", "suspend", "resume", "reopen"}
                if not isinstance(action, dict) or action.get("action") not in allowed or not action.get("quest_id"):
                    fail("QUEST_ACTION_INVALID", "QuestManager动作缺少合法action或quest_id")
                elif action.get("action") == "update_objective" and (not action.get("objective_id") or not isinstance(action.get("update"), dict)):
                    fail("QUEST_ACTION_INVALID", "update_objective动作必须指定objective_id和update")
                elif action.get("action") == "fail" and "continuation_id" not in action:
                    fail("QUEST_ACTION_INVALID", "fail动作必须指定continuation_id")
            for reward in owner.get("item_rewards", []):
                if isinstance(reward, str):
                    continue
                if not isinstance(reward, dict) or not reward.get("item_id") or not isinstance(reward.get("quantity", 1), int) or reward.get("quantity", 1) < 1:
                    fail("ITEM_REWARD_INVALID", "InventoryManager奖励必须含item_id和正整数quantity")
            if owner.get("combat_id") and owner.get("combat_ref") and owner["combat_id"] != owner["combat_ref"]:
                fail("MANAGER_OWNERSHIP_INVALID", "combat_id与combat_ref冲突")

    if catalogs is not None:
        states = _catalog_ids(catalogs.get("states", {}), "states", "key")
        npcs_doc = catalogs.get("npcs", {}) if isinstance(catalogs.get("npcs", {}), dict) else {}
        npc_entries = {value.get("npc_id"): value for value in npcs_doc.get("npcs", []) if isinstance(value, dict)}
        npcs = set(npc_entries)
        locations = _catalog_ids(catalogs.get("locations", {}), "locations", "location_id")
        items = _catalog_ids(catalogs.get("items", {}), "items", "item_id")
        combats = _catalog_ids(catalogs.get("combats", {}), "combats", "combat_id")
        presentation = catalogs.get("presentation", {}) if isinstance(catalogs.get("presentation", {}), dict) else {}
        for label, state_op in _objects_with_state_ops(quest):
            key = state_op.get("key")
            if key and key not in states:
                fail("CONTENT_REFERENCE_INVALID", f"{label}状态未登记: {key}")
        trigger = quest.get("trigger", {})
        if isinstance(trigger, dict) and trigger.get("location_id") not in locations:
            fail("CONTENT_REFERENCE_INVALID", f"触发地点未登记: {trigger.get('location_id')}")
        for scene in quest.get("scenes", []):
            if not isinstance(scene, dict):
                continue
            for participant in scene.get("participant_ids", []):
                if participant not in npcs and participant != "PROTAGONIST_FENGYUE":
                    fail("CONTENT_REFERENCE_INVALID", f"场景NPC未登记: {participant}")
        for node in nodes:
            if not isinstance(node, dict):
                continue
            node_id = node.get("node_id", "<unknown>")
            if node.get("location_id") not in locations:
                fail("CONTENT_REFERENCE_INVALID", f"{node_id}地点未登记: {node.get('location_id')}")
            speaker = node.get("speaker_id")
            if speaker and speaker not in npcs and speaker != "PROTAGONIST_FENGYUE":
                fail("CONTENT_REFERENCE_INVALID", f"{node_id}说话人未登记: {speaker}")
            if speaker == "PROTAGONIST_FENGYUE" and node.get("portrait_action") in {"show", "replace"}:
                fail("PROTAGONIST_PORTRAIT_FORBIDDEN", f"{node_id}不得展示枫月大立绘")
            expression = node.get("expression")
            if expression and speaker in npc_entries:
                expressions = set(npc_entries[speaker].get("portrait_set", {}).get("expressions", {}))
                if expression not in expressions:
                    fail("PRESENTATION_REFERENCE_INVALID", f"{node_id}.expression未登记: {expression}")
            combat_id = node.get("combat_ref") or node.get("combat_id")
            if combat_id and combat_id not in combats:
                fail("CONTENT_REFERENCE_INVALID", f"战斗未登记: {combat_id}")
            item_values = list(node.get("reward_item_ids", [])) + list(node.get("item_rewards", []))
            for raw_item in item_values:
                item_id = raw_item.get("item_id") if isinstance(raw_item, dict) else raw_item
                if item_id not in items:
                    fail("CONTENT_REFERENCE_INVALID", f"物品未登记: {item_id}")
            mapping = {
                "portrait_action": "portrait_actions", "camera": "cameras", "delivery": "deliveries",
                "gesture": "gestures", "audio_cue": "audio_cues", "sfx_id": "audio_cues",
                "background_id": "background_ids", "music_id": "music_ids",
            }
            for field, registry in mapping.items():
                if node.get(field) is not None and node[field] not in set(presentation.get(registry, [])):
                    fail("PRESENTATION_REFERENCE_INVALID", f"{node_id}.{field}未登记: {node[field]}")
        for reward in quest.get("rewards", []):
            if isinstance(reward, dict):
                for value in reward.get("items", []):
                    if isinstance(value, dict) and value.get("item_id") not in items:
                        fail("CONTENT_REFERENCE_INVALID", f"奖励物品未登记: {value.get('item_id')}")

    if chapter_mapping is not None:
        declared_expected = list(expected_chapters or quest.get("source_chapters", []))
        errors.extend(validate_chapter_mapping(chapter_mapping, declared_expected))
        if quest.get("source_refs") and chapter_mapping.get("coverage_status") != "COMPLETE":
            fail("CHAPTER_MAPPING_MISSING", "正式剧情已声明source_refs，但区域章节映射尚未达到COMPLETE")
    elif expected_chapters:
        fail("CHAPTER_MAPPING_MISSING", "缺少原著章节映射")
    elif quest.get("source_refs"):
        fail("CHAPTER_MAPPING_MISSING", "正式剧情声明source_refs但未提供章节映射")
    foreshadowing_refs = [
        value for node in nodes if isinstance(node, dict)
        for value in node.get("foreshadowing_refs", []) if isinstance(value, str)
    ]
    if foreshadowing_registry is not None:
        errors.extend(validate_foreshadowing(foreshadowing_registry, foreshadowing_refs))
    elif foreshadowing_refs:
        fail("FORESHADOWING_REFERENCE_INVALID", "剧情引用伏笔但缺少登记表")
    return errors


def _validate_approval(ir: dict[str, Any], approval: dict[str, Any]) -> None:
    schema_errors = _schema_errors(approval, "story_approval.schema.json")
    if schema_errors:
        raise PipelineError("STORY_APPROVAL_INVALID", "; ".join(schema_errors))
    if approval["status"] != "approved":
        raise PipelineError("STORY_NOT_APPROVED", "批准状态不是approved")
    if approval.get("approval_version") != "1.0.0":
        raise PipelineError("STORY_APPROVAL_INVALID", "approval_version不受支持")
    if approval.get("story_id") != ir.get("quest", {}).get("quest_id"):
        raise PipelineError("STORY_APPROVAL_INVALID", "批准记录story_id与剧情不一致")
    if approval["source_sha256"] != ir.get("source", {}).get("sha256"):
        raise PipelineError("STORY_APPROVAL_STALE", "Markdown源文件哈希与批准记录不一致")
    if approval["canonical_sha256"] != ir.get("canonical_sha256"):
        raise PipelineError("STORY_APPROVAL_STALE", "结构化内容哈希与批准记录不一致")


def _runtime_projection(document: dict[str, Any]) -> dict[str, Any]:
    runtime = copy.deepcopy(document)
    extensions: dict[str, Any] = {}
    allowed_node = {
        "node_id", "type", "location_id", "scene_id", "purpose", "text", "next", "effects", "conditions",
        "speaker_id", "expression", "portrait_action", "gesture", "target", "camera", "delivery", "choices",
        "combat_ref", "reward_item_ids", "reward_items", "quest_actions", "relationship_actions",
        "terminal", "outcome", "next_on_win", "next_on_loss",
    }
    for node in runtime.get("nodes", []):
        if not isinstance(node, dict):
            continue
        if "combat_id" in node and "combat_ref" not in node:
            node["combat_ref"] = node["combat_id"]
        if "item_rewards" in node and "reward_items" not in node:
            node["reward_items"] = [
                {"item_id": value, "quantity": 1} if isinstance(value, str) else copy.deepcopy(value)
                for value in node["item_rewards"]
            ]
        node.pop("item_rewards", None)
        if "reward_items" in node and "reward_item_ids" not in node:
            node["reward_item_ids"] = [value["item_id"] for value in node["reward_items"]]
        extra = {key: copy.deepcopy(value) for key, value in node.items() if key not in allowed_node}
        if extra:
            extensions[str(node.get("node_id"))] = extra
        for key in list(node):
            if key not in allowed_node:
                del node[key]
    if extensions:
        implementation = runtime.setdefault("implementation", {})
        implementation["story_pipeline_extensions"] = extensions
    if runtime.get("content_status") == "complete_script":
        runtime["content_status"] = "data_ready"
    return runtime


def build_runtime_json(
    ir: dict[str, Any], approval: dict[str, Any], catalogs: dict[str, Any] | None = None,
    policy: dict[str, int] | None = None,
    chapter_mapping: dict[str, Any] | None = None,
    foreshadowing_registry: dict[str, Any] | None = None,
) -> dict[str, Any]:
    errors = check_ir(
        ir, catalogs, policy,
        chapter_mapping=chapter_mapping,
        foreshadowing_registry=foreshadowing_registry,
    )
    if errors:
        raise PipelineError("STORY_STATIC_CHECK_FAILED", json.dumps(errors, ensure_ascii=False))
    _validate_approval(ir, approval)
    document = _runtime_projection(ir["quest"])
    schema_errors = _schema_errors(document, "quest.schema.json")
    if schema_errors:
        raise PipelineError("STORY_RUNTIME_SCHEMA_INVALID", "; ".join(schema_errors))
    return document


def render_review(document: dict[str, Any], provenance: dict[str, Any] | None = None) -> str:
    lines = [f"# {document.get('title', document.get('quest_id', '剧情审阅稿'))}", "", "> 本文件由运行JSON自动生成，只供审阅；请勿手工作为权威源修改。", ""]
    if provenance:
        lines.extend([f"- 源文件 SHA-256：`{provenance.get('source_sha256', '')}`", f"- 运行数据 SHA-256：`{sha256_bytes(canonical_bytes(document))}`", ""])
    lines.extend(["## 元数据", "", "```json", json.dumps({k: v for k, v in document.items() if k != "nodes"}, ensure_ascii=False, indent=2), "```", ""])
    for node in document.get("nodes", []):
        lines.extend([f"## 节点 `{node.get('node_id', '')}`", "", "```json", json.dumps(node, ensure_ascii=False, indent=2), "```", ""])
    return "\n".join(lines)


def diff_ir_runtime(ir: dict[str, Any], runtime: dict[str, Any]) -> dict[str, Any]:
    expected = _runtime_projection(ir.get("quest", {}))
    return {
        "match": expected == runtime,
        "expected_sha256": sha256_bytes(canonical_bytes(expected)),
        "runtime_sha256": sha256_bytes(canonical_bytes(runtime)),
        "quest_id": expected.get("quest_id"),
    }


def story_status_report(
    story_id: str, *, script_status: str, parsed: bool = False, references_ok: bool = False,
    ownership_ok: bool = False, runtime_generated: bool = False, runtime_valid: bool = False,
    playable: bool = False,
) -> dict[str, Any]:
    if playable and runtime_valid:
        status = "VERIFIED"
    elif runtime_generated and runtime_valid:
        status = "DATA_READY"
    elif parsed:
        status = "PARSED"
    elif script_status.upper() == "COMPLETE_SCRIPT":
        status = "COMPLETE_SCRIPT"
    elif script_status.upper() == "DRAFT":
        status = "DRAFT"
    else:
        status = "SOURCE_ONLY"
    return {
        "story_id": story_id, "status": status, "script": script_status,
        "parser": "PASS" if parsed else "PENDING", "references": "PASS" if references_ok else "PENDING",
        "manager_ownership": "PASS" if ownership_ok else "PENDING",
        "runtime_json": "GENERATED" if runtime_generated else "NOT_GENERATED",
        "runtime_validation": "PASS" if runtime_valid else "PENDING", "playable": "READY" if playable else "NOT_READY",
    }


def _safe_zip_name(name: str) -> bool:
    path = PurePosixPath(name.replace("\\", "/"))
    return not path.is_absolute() and ".." not in path.parts


def preflight_package(
    path: Path,
    catalogs: dict[str, Any] | None = None,
    chapter_mapping: dict[str, Any] | None = None,
    foreshadowing_registry: dict[str, Any] | None = None,
) -> dict[str, Any]:
    try:
        package_bytes = path.read_bytes()
        archive = zipfile.ZipFile(path)
    except (OSError, zipfile.BadZipFile) as exc:
        raise PipelineError("STORY_PACKAGE_INVALID", f"{path}: {exc}") from exc
    with archive:
        names = archive.namelist()
        unsafe = [name for name in names if not _safe_zip_name(name)]
        markdown = [name for name in names if name.lower().endswith(".md")]
        manifests = [name for name in names if Path(name).name.lower().startswith("manifest") and name.lower().endswith(".json")]
        scripts = [name for name in markdown if "complete_script" in name.lower()]
        parsed_count = 0
        issues: list[dict[str, str]] = []
        for name in scripts:
            try:
                source_bytes = archive.read(name)
                text = source_bytes.decode("utf-8")
                meta_blocks = META_RE.findall(text)
                node_blocks = NODE_RE.findall(text)
                if len(meta_blocks) != 1 or not node_blocks:
                    issues.append({"code": "STORY_NOT_DATA_READY", "message": f"{name}未采用受约束Markdown结构"})
                    continue
                metadata = _block_json(meta_blocks[0], f"{name}:story-meta")
                nodes = [_block_json(raw, f"{name}:story-node#{index}") for index, raw in enumerate(node_blocks, 1)]
                normalized = normalize_story(metadata, nodes)
                quest = normalized["quest"]
                candidate = {
                    "ir_version": IR_VERSION, "tool_version": TOOL_VERSION,
                    "source": {"path": name, "sha256": sha256_bytes(source_bytes)},
                    "baseline": normalized["baseline"], "ownership": normalized["ownership"],
                    "quest": quest, "metrics": _metrics(quest),
                    "canonical_sha256": sha256_bytes(canonical_bytes(quest)),
                }
                parsed_count += 1
                for error in check_ir(
                    candidate,
                    catalogs,
                    chapter_mapping=chapter_mapping,
                    foreshadowing_registry=foreshadowing_registry,
                ):
                    issues.append({"code": error["code"], "message": f"{name}: {error['message']}"})
            except UnicodeError:
                issues.append({"code": "STORY_SOURCE_UNREADABLE", "message": f"{name}不是UTF-8"})
            except PipelineError as exc:
                issues.append({"code": exc.code, "message": f"{name}: {exc.message}"})
        if unsafe:
            issues.append({"code": "STORY_PACKAGE_UNSAFE_PATH", "message": f"发现{len(unsafe)}个不安全路径"})
        if not manifests:
            issues.append({"code": "STORY_PACKAGE_MANIFEST_MISSING", "message": "压缩包缺少manifest JSON"})
        if not scripts:
            issues.append({"code": "CONTENT_MISSING", "message": "压缩包没有COMPLETE_SCRIPT Markdown"})
        return {
            "package": path.name, "sha256": sha256_bytes(package_bytes),
            "checked_at": datetime.now(timezone.utc).isoformat(), "file_count": len(names),
            "markdown_count": len(markdown), "complete_script_count": len(scripts),
            "pipeline_metadata_ready_count": parsed_count, "manifest_files": manifests,
            "unsafe_paths": unsafe, "issues": issues, "release_ready": not issues,
        }
