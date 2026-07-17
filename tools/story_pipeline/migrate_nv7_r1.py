"""Mechanically normalize the reviewed NV7 R1.1 delivery into governed scripts.

This is deliberately a package-specific migration adapter.  The production
pipeline still accepts only fenced ``story-meta``/``story-node`` Markdown and
does not attempt to guess arbitrary prose Markdown.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SPEAKERS = {
    "枫月": ("PROTAGONIST_FENGYUE", "neutral", "hide"),
    "岚音": ("NV7_NPC_LANYIN", "neutral", "show"),
    "顾长川": ("NV7_NPC_CHIEF", "calm", "show"),
    "韩石": ("NV7_NPC_HANSHI", "neutral", "show"),
    "苏芷": ("NV7_NPC_SUZHI", "calm", "show"),
    "王五": ("NV7_NPC_WANGWU", "hearty", "show"),
    "天火冷魂": ("NV7_NPC_TIANHUOLENGHUN", "confident", "show"),
    "风云石虎": ("NV7_NPC_FENGYUN_SHIHU", "default", "show"),
    "风云黑虎": ("NV7_NPC_FENGYUN_HEIHU", "default", "show"),
    "风云黄虎": ("NV7_NPC_FENGYUN_HUANGHU", "default", "show"),
}


@dataclass(frozen=True)
class Task:
    quest_id: str
    source_glob: str
    title: str
    chapters: list[str]
    start_location: str
    participants: list[str]
    next_story: str


TASKS = (
    Task("NV_MAIN_001", "01_*", "没有退出键", ["2", "3"], "NV7_LOC_ALTAR",
         ["PROTAGONIST_FENGYUE", "NV7_NPC_CHIEF", "NV7_NPC_SUZHI"], "NV_MAIN_002"),
    Task("NV_MAIN_002", "02_*", "三份委托", ["3", "4", "5"], "NV7_LOC_SQUARE",
         ["PROTAGONIST_FENGYUE", "NV7_NPC_CHIEF", "NV7_NPC_HANSHI", "NV7_NPC_SUZHI"], "NV_MAIN_003"),
    Task("NV_MAIN_003", "03_*", "兔王不该出现", ["5", "6"], "NV7_LOC_APOTHECARY",
         ["PROTAGONIST_FENGYUE", "NV7_NPC_LANYIN", "NV7_NPC_SUZHI"], "NV_MAIN_004"),
    Task("NV_MAIN_004", "04_*", "狼影中的同伴", ["6", "7", "8"], "NV7_LOC_SQUARE",
         ["PROTAGONIST_FENGYUE", "NV7_NPC_LANYIN", "NV7_NPC_WANGWU", "NV7_NPC_TIANHUOLENGHUN",
          "NV7_NPC_FENGYUN_SHIHU", "NV7_NPC_FENGYUN_HEIHU", "NV7_NPC_FENGYUN_HUANGHU"], ""),
)

CHOICE_END_MARKERS = {
    "NV_MAIN_001": {
        "选择组 A": "无论玩家顺序如何",
        "选择组 B": "三项都不改变长期状态",
        "选择组 C": "### 共通回应",
    },
    "NV_MAIN_002": {
        "选择组 B": "战斗胜利后",
        "选择组 C": "### 北坡中的动态回应",
        "选择组 D": "### 共通信息",
    },
    "NV_MAIN_003": {"选择组 A": "## 场景 S04"},
    "NV_MAIN_004": {"玩家主策略": "### 岚音伙伴倾向"},
}

SCENE_LOCATIONS = {
    "NV_MAIN_001": ["NV7_LOC_ALTAR", "NV7_LOC_ALTAR", "NV7_LOC_ALTAR", "NV7_LOC_FIELDS", "NV7_LOC_SQUARE", "NV7_LOC_SQUARE"],
    "NV_MAIN_002": ["NV7_LOC_FORGE", "NV7_LOC_FORGE", "NV7_LOC_FIELDS", "NV7_LOC_APOTHECARY", "NV7_LOC_FIELDS", "NV7_LOC_APOTHECARY", "NV7_LOC_FIELDS", "NV7_LOC_FIELDS"],
    "NV_MAIN_003": ["NV7_LOC_APOTHECARY", "NV7_LOC_FIELDS", "NV7_LOC_FIELDS", "NV7_LOC_APOTHECARY", "NV7_LOC_FIELDS"],
    "NV_MAIN_004": ["NV7_LOC_SQUARE", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH", "NV7_LOC_WOLF_PATH"],
}

MANAGER_LINE_PREFIXES = (
    "QuestManager", "RelationshipManager", "InventoryManager", "WorldState", "CombatRunner",
    "即时效果：", "任务目标：", "任务完成：", "战斗结果：", "relationship flag：",
)


def dump(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def clean_lines(lines: list[str]) -> list[str]:
    cleaned: list[str] = []
    for raw in lines:
        line = raw.strip().rstrip("  ")
        if not line or line == "---" or line.startswith("```"):
            continue
        if line.startswith("[ACTION:") and line.endswith("]"):
            line = line[len("[ACTION:"):-1].strip()
        if line.startswith(("[BG:", "[BGM:", "[SFX:", "[PORTRAIT:")):
            continue
        if line.startswith(MANAGER_LINE_PREFIXES):
            continue
        if line.startswith("###") or line.startswith("##") or line.startswith("# "):
            continue
        line = re.sub(r"^[-*]\s+", "", line)
        line = line.replace("`", "")
        if line:
            cleaned.append(line)
    return cleaned


def option_label(line: str) -> tuple[str, str] | None:
    match = re.match(r"^([A-Z][0-9]+)[.、]?【([^】]+)】(?:\s*[“\"]?([^”\"]*)[”\"]?)?", line.strip())
    if not match:
        return None
    extra = match.group(3).strip()
    label = match.group(2).strip() + (f"——{extra}" if extra else "")
    return match.group(1).lower(), label


def scene_sections(source: str, quest_id: str) -> list[tuple[str, str, list[str]]]:
    lines = source.splitlines()
    sections: list[tuple[str, str, list[str]]] = []
    current_id = ""
    current_title = ""
    current: list[str] = []
    skip_notes = False
    for line in lines:
        match = re.match(r"^## 场景\s+([A-Z]\d+|S\d+)：(.+)$", line.strip())
        if match:
            if current_id:
                sections.append((current_id, current_title, current))
            current_id, current_title, current = match.group(1).lower(), match.group(2).strip(), []
            skip_notes = False
            continue
        if current_id:
            if line.startswith("### Codex"):
                skip_notes = True
                continue
            if skip_notes and line.startswith("### 失败续接"):
                skip_notes = False
            if skip_notes:
                continue
            current.append(line)
    if current_id:
        sections.append((current_id, current_title, current))
    return sections


def split_choice_groups(lines: list[str], quest_id: str) -> list[tuple[str, Any]]:
    markers = CHOICE_END_MARKERS.get(quest_id, {})
    tokens: list[tuple[str, Any]] = []
    prose: list[str] = []

    def flush() -> None:
        nonlocal prose
        values = clean_lines(prose)
        if values:
            tokens.append(("prose", values))
        prose = []

    index = 0
    while index < len(lines):
        heading = re.match(r"^#{2,3}\s+(选择组\s+[A-Z][^：]*|玩家主策略)(?:：.*)?$", lines[index].strip())
        if not heading:
            prose.append(lines[index])
            index += 1
            continue
        flush()
        group_name = heading.group(1).strip()
        end_marker = next((value for key, value in markers.items() if key in group_name), "")
        index += 1
        choices: list[dict[str, Any]] = []
        current: dict[str, Any] | None = None
        while index < len(lines):
            line = lines[index]
            if end_marker and line.strip().startswith(end_marker):
                break
            if not end_marker and re.match(r"^#{2,3}\s+", line.strip()):
                break
            parsed = option_label(line)
            if parsed:
                if current:
                    current["response"] = clean_lines(current["raw"])
                    current.pop("raw")
                    choices.append(current)
                current = {"choice_id": parsed[0], "text": parsed[1], "raw": []}
            elif current is not None:
                current["raw"].append(line)
            index += 1
        if current:
            current["response"] = clean_lines(current["raw"])
            current.pop("raw")
            choices.append(current)
        if len(choices) >= 2:
            tokens.append(("choice", {"name": group_name, "choices": choices}))
        if end_marker and index < len(lines):
            prose.append(lines[index])
            index += 1
    flush()
    return tokens


def dialogue(line: str) -> tuple[str, str] | None:
    match = re.match(r"^([^：“”]{1,12})[：:]\s*[“\"](.+?)[”\"]$", line)
    if not match or match.group(1) not in SPEAKERS:
        return None
    return match.group(1), match.group(2)


def quest_runtime(task: Task) -> dict[str, Any]:
    number = task.quest_id[-3:].lower()
    objectives: list[dict[str, Any]]
    if task.quest_id == "NV_MAIN_002":
        objectives = [
            {"objective_id": name, "type": "boolean", "required": True,
             "progress_state_key": f"quest.nv_main_002.objective.{name}", "target": True}
            for name in ("hanshi", "suzhi", "guchangchuan")
        ]
    else:
        objective = {"NV_MAIN_001": "arrival", "NV_MAIN_003": "resolve_rabbit_event", "NV_MAIN_004": "resolve_wolf_event"}[task.quest_id]
        objectives = [{"objective_id": objective, "type": "boolean", "required": True,
                       "progress_state_key": f"quest.nv_main_{number}.objective.{objective}", "target": True}]
    availability: dict[str, Any] = {"all": [], "any": []}
    if task.quest_id == "NV_MAIN_002":
        availability["all"] = [{"kind": "quest", "quest_id": "NV_MAIN_001", "op": "eq", "value": "completed"}]
    elif task.quest_id == "NV_MAIN_003":
        availability["all"] = [{"kind": "quest", "quest_id": "NV_MAIN_002", "op": "in", "value": ["qualified", "completed"]}]
    elif task.quest_id == "NV_MAIN_004":
        availability["all"] = [{"kind": "quest", "quest_id": "NV_MAIN_003", "op": "eq", "value": "completed"}]
    result = {
        "status_state_key": f"quest.nv_main_{number}.status",
        "reward_granted_state_key": f"quest.nv_main_{number}.reward_granted",
        "availability": availability,
        "objectives": objectives,
        "completion_mode": "automatic",
        "failure": {
            "continuation_state_key": f"quest.nv_main_{number}.continuation",
            "allowed_continuations": {
                "NV_MAIN_001": ["none", "altar_boundary_retry"],
                "NV_MAIN_002": ["none", "hanshi_recovery", "suzhi_recovery", "boundary_recovery"],
                "NV_MAIN_003": ["none", "apothecary_recovery"],
                "NV_MAIN_004": ["none", "wolf_path_recovery"],
            }[task.quest_id],
            "resume_from_failed": "active", "resume_from_suspended": "active", "reopen_allowed": True,
        },
    }
    if task.quest_id == "NV_MAIN_002":
        result["qualification"] = {"objective_ids": ["hanshi", "suzhi", "guchangchuan"], "required_count": 2}
    return result


def node_from_line(node_id: str, scene_id: str, location_id: str, line: str) -> dict[str, Any]:
    spoken = dialogue(line)
    if spoken:
        speaker_id, expression, portrait = SPEAKERS[spoken[0]]
        return {"node_id": node_id, "type": "dialogue", "scene_id": scene_id, "location_id": location_id,
                "purpose": "reviewed_dialogue", "speaker_id": speaker_id, "expression": expression,
                "portrait_action": portrait, "text": [spoken[1]]}
    return {"node_id": node_id, "type": "narrative", "scene_id": scene_id, "location_id": location_id,
            "purpose": "reviewed_narrative", "text": [line]}


def build_task(task: Task, source_path: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    source = source_path.read_text(encoding="utf-8")
    sections = scene_sections(source, task.quest_id)
    nodes: list[dict[str, Any]] = []
    scenes: list[dict[str, Any]] = []
    main_order: list[str] = []
    scene_nodes: dict[str, list[str]] = {}
    response_links: list[tuple[str, str]] = []
    choice_counter = 0
    locations = SCENE_LOCATIONS[task.quest_id]
    for scene_index, (scene_id, title, lines) in enumerate(sections):
        location = locations[min(scene_index, len(locations) - 1)]
        scene_nodes[scene_id] = []
        for kind, payload in split_choice_groups(lines, task.quest_id):
            if kind == "prose":
                for line in payload:
                    node_id = f"{scene_id}_{len(scene_nodes[scene_id]) + 1:03d}"
                    nodes.append(node_from_line(node_id, scene_id, location, line))
                    main_order.append(node_id)
                    scene_nodes[scene_id].append(node_id)
                continue
            choice_counter += 1
            choice_id = f"{scene_id}_choice_{choice_counter}"
            choice_node = {"node_id": choice_id, "type": "choice", "scene_id": scene_id, "location_id": location,
                           "purpose": "reviewed_choice", "choices": []}
            for option_index, option in enumerate(payload["choices"], 1):
                response_id = f"{choice_id}_{option_index}_response"
                response_text = option["response"] or [option["text"]]
                response = {"node_id": response_id, "type": "narrative", "scene_id": scene_id,
                            "location_id": location, "purpose": "reviewed_choice_response", "text": response_text}
                nodes.append(response)
                response_links.append((response_id, choice_id))
                choice_node["choices"].append({
                    "choice_id": f"{choice_id}_{option['choice_id']}", "text": option["text"],
                    "intent": option["text"], "protagonist_boundary": "allowed", "visible_risk": "可见后果见选项文本",
                    "consequence_summary": "进入审核稿声明的对应回应", "hidden_consequence": "无额外隐藏改写",
                    "conditions": [], "effects": [], "goto": response_id,
                })
            nodes.append(choice_node)
            main_order.append(choice_id)
            scene_nodes[scene_id].append(choice_id)
        if scene_nodes[scene_id]:
            scenes.append({"scene_id": scene_id, "title": title, "entry_nodes": [scene_nodes[scene_id][0]],
                           "exit_nodes": [scene_nodes[scene_id][-1]], "participant_ids": task.participants,
                           "objective": title, "optional_interactions": []})
    by_id = {node["node_id"]: node for node in nodes}
    for index, node_id in enumerate(main_order[:-1]):
        by_id[node_id]["next"] = main_order[index + 1]
    for response_id, choice_id in response_links:
        choice_pos = main_order.index(choice_id)
        by_id[response_id]["next"] = main_order[choice_pos + 1] if choice_pos + 1 < len(main_order) else "story_complete"

    # R1.3 adds a source-declared investigation choice that is not labelled as a choice group.
    if task.quest_id == "NV_MAIN_003" and len(scenes) > 1:
        target = scenes[1]["entry_nodes"][0]
        investigation = {
            "node_id": "s02_investigation_choice", "type": "choice", "scene_id": scenes[1]["scene_id"],
            "location_id": "NV7_LOC_FIELDS", "purpose": "investigation_priority",
            "choices": [
                {"choice_id": f"investigate_{idx}", "text": text, "intent": text,
                 "protagonist_boundary": "allowed", "visible_risk": "调查顺序", "consequence_summary": "进入限时调查",
                 "hidden_consequence": "无", "conditions": [], "effects": [], "goto": target}
                for idx, text in enumerate(("检查捕兽夹碎片", "检查硬底靴印", "检查蓝色驱兽粉"), 1)
            ],
        }
        previous_scene_last = scenes[0]["exit_nodes"][0]
        by_id[previous_scene_last]["next"] = investigation["node_id"]
        nodes.append(investigation)
        scenes[1]["entry_nodes"] = [investigation["node_id"]]
        by_id[investigation["node_id"]] = investigation

    first = main_order[0]
    by_id[first].setdefault("quest_actions", []).append({"action": "activate", "quest_id": task.quest_id})
    objective_name = {"NV_MAIN_001": "arrival", "NV_MAIN_003": "resolve_rabbit_event", "NV_MAIN_004": "resolve_wolf_event"}.get(task.quest_id)
    if objective_name:
        by_id[main_order[-1]].setdefault("quest_actions", []).append(
            {"action": "update_objective", "quest_id": task.quest_id, "objective_id": objective_name, "update": {"value": True}}
        )
    complete = {"node_id": "story_complete", "type": "complete", "scene_id": scenes[-1]["scene_id"],
                "location_id": locations[-1], "purpose": "r1_story_complete", "terminal": True,
                "outcome": f"{task.quest_id.lower()}_complete"}
    if task.next_story:
        complete["next_story_id"] = task.next_story
    nodes.append(complete)
    if task.quest_id != "NV_MAIN_002":
        by_id[main_order[-1]]["next"] = "story_complete"

    # R1.2 is explicitly a three-route quest: any two qualify, all three complete.
    if task.quest_id == "NV_MAIN_002":
        route_scenes = {"hanshi": ("a01", "a03"), "suzhi": ("b01", "b03"), "guchangchuan": ("c01", "c02")}
        route_exits: dict[str, list[str]] = {}
        hub = {"node_id": "commission_hub", "type": "choice", "scene_id": scenes[0]["scene_id"],
               "location_id": "NV7_LOC_SQUARE", "purpose": "parallel_commission_hub", "choices": []}
        for name, (start_scene, end_scene) in route_scenes.items():
            start_id = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == start_scene)]["entry_nodes"][0]
            end_id = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == end_scene)]["exit_nodes"][0]
            progress_key = f"quest.nv_main_002.objective.{name}"
            hub["choices"].append({"choice_id": f"commission_{name}", "text": {"hanshi": "韩石的试刃", "suzhi": "苏芷的药篮", "guchangchuan": "顾长川的界石"}[name],
                                   "intent": "执行并行委托", "protagonist_boundary": "allowed", "visible_risk": "委托中可能受伤",
                                   "consequence_summary": "完成该委托目标", "hidden_consequence": "无", "conditions": [{"key": progress_key, "op": "eq", "value": False}],
                                   "effects": [], "goto": start_id, "hidden_when_locked": True})
            end_node = by_id[end_id]
            route_exits[name] = (
                [str(option["goto"]) for option in end_node.get("choices", [])]
                if end_node.get("type") == "choice" else [end_id]
            )
            for exit_id in route_exits[name]:
                by_id[exit_id].setdefault("quest_actions", []).append(
                    {"action": "update_objective", "quest_id": task.quest_id, "objective_id": name, "update": {"value": True}}
                )
                by_id[exit_id]["next"] = "commission_hub"
        hub["choices"].append({"choice_id": "continue_main_story", "text": "前往下一阶段", "intent": "推进主线",
                               "protagonist_boundary": "allowed", "visible_risk": "未完成的第三份委托仍可回访",
                               "consequence_summary": "任意两项完成后推进", "hidden_consequence": "全清反馈取决于第三项目标",
                               "conditions": [{"key": "quest.nv_main_002.status", "op": "in", "value": ["qualified", "completed"]}],
                               "effects": [], "goto": "story_complete", "hidden_when_locked": True})
        nodes.append(hub)
        by_id[hub["node_id"]] = hub
        commission_start = {
            "node_id": "commission_start", "type": "narrative", "scene_id": scenes[0]["scene_id"],
            "location_id": "NV7_LOC_SQUARE", "purpose": "parallel_commission_start",
            "text": ["三个委托没有固定顺序。完成任意两项后可以继续推进，第三项仍可回访。"],
            "quest_actions": [{"action": "activate", "quest_id": task.quest_id}], "next": "commission_hub",
        }
        nodes.append(commission_start)
        by_id[commission_start["node_id"]] = commission_start
        first = "commission_start"

        # The reviewed equipment choice grants exactly the selected starter item.
        equipment_choice = next(node for node in nodes if node["type"] == "choice" and node["scene_id"] == "a01")
        equipment_items = ("NV7_ITEM_NOVICE_SWORD", "NV7_ITEM_NOVICE_SHIELD", "NV7_ITEM_NOVICE_HOOK_STAFF")
        for option, item_id in zip(equipment_choice["choices"], equipment_items):
            response = by_id[option["goto"]]
            original_next = response["next"]
            reward_id = f"{response['node_id']}_reward"
            reward = {"node_id": reward_id, "type": "reward", "scene_id": "a01", "location_id": "NV7_LOC_FORGE",
                      "purpose": "selected_starter_equipment", "reward_item_ids": [item_id],
                      "reward_items": [{"item_id": item_id, "quantity": 1}], "next": original_next}
            response["next"] = reward_id
            nodes.append(reward)
            by_id[reward_id] = reward

        # Han Shi's route contains the formal combat and a retryable defeat continuation.
        for hanshi_exit in route_exits["hanshi"]:
            by_id[hanshi_exit].pop("quest_actions", None)
            by_id[hanshi_exit]["next"] = "hanshi_badger_combat"
        hanshi_combat = {"node_id": "hanshi_badger_combat", "type": "combat", "scene_id": "a03",
                         "location_id": "NV7_LOC_FIELDS", "purpose": "basic_combat_commission",
                         "combat_ref": "NV7_COMBAT_GREY_BADGERS", "next_on_win": "hanshi_route_success",
                         "next_on_loss": "hanshi_route_recovery"}
        hanshi_success = {"node_id": "hanshi_route_success", "type": "narrative", "scene_id": "a03",
                          "location_id": "NV7_LOC_FIELDS", "purpose": "commission_result",
                          "text": ["战斗胜利后，矿车附近恢复通行。"],
                          "quest_actions": [{"action": "update_objective", "quest_id": task.quest_id,
                                             "objective_id": "hanshi", "update": {"value": True}}],
                          "relationship_actions": [{"relationship_id": "NV7_REL_FENGYUE_HANSHI", "dimension": "respect", "op": "inc", "value": 1}],
                          "next": "commission_hub"}
        hanshi_recovery = {"node_id": "hanshi_route_recovery", "type": "narrative", "scene_id": "a03",
                           "location_id": "NV7_LOC_APOTHECARY", "purpose": "failure_continuation",
                           "text": ["枫月在药棚醒来。", "灰背獾不会追到村里来。任务重新开放，已获得的观察信息保留。"],
                           "quest_actions": [
                               {"action": "fail", "quest_id": task.quest_id, "continuation_id": "hanshi_recovery"},
                               {"action": "resume", "quest_id": task.quest_id},
                           ],
                           "next": "commission_hub"}
        for extra in (hanshi_combat, hanshi_success, hanshi_recovery):
            nodes.append(extra)
            by_id[extra["node_id"]] = extra

        # The other two reviewed commissions grant their registered evidence items.
        for scene_id, item_id, relationship_id, dimension in (
            ("b03", "NV7_ITEM_BLUE_POWDER_SAMPLE", "NV7_REL_FENGYUE_SUZHI", "trust"),
            ("c02", "NV7_ITEM_BOUNDARY_RUBBING", "NV7_REL_FENGYUE_GUCHANGCHUAN", "respect"),
        ):
            reward_id = f"{scene_id}_evidence_reward"
            route_name = "suzhi" if scene_id == "b03" else "guchangchuan"
            for exit_id in route_exits[route_name]:
                by_id[exit_id]["next"] = reward_id
                by_id[exit_id].setdefault("relationship_actions", []).append(
                    {"relationship_id": relationship_id, "dimension": dimension, "op": "inc", "value": 1}
                )
            reward = {"node_id": reward_id, "type": "reward", "scene_id": scene_id,
                      "location_id": by_id[route_exits[route_name][0]]["location_id"], "purpose": "commission_evidence_reward",
                      "reward_item_ids": [item_id], "reward_items": [{"item_id": item_id, "quantity": 1}],
                      "next": "commission_hub"}
            nodes.append(reward)
            by_id[reward_id] = reward

    if task.quest_id == "NV_MAIN_003":
        route_choice = next(node for node in nodes if node["type"] == "choice" and node["scene_id"] == "s03")
        success_target = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == "s05")]["entry_nodes"][0]
        loss_target = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == "s04")]["entry_nodes"][0]
        route_specs = (
            ("NV7_COMBAT_RABBIT_GUARDS", "alive", "escaped", "none"),
            ("NV7_COMBAT_POACHERS", "alive", "scattered", "ledger_partial"),
            ("NV7_COMBAT_DUDU_RABBIT", "dead", "displaced", "none"),
        )
        for index, (option, spec) in enumerate(zip(route_choice["choices"], route_specs), 1):
            response = by_id[option["goto"]]
            combat_id = f"rabbit_route_{index}_combat"
            response["next"] = combat_id
            response.setdefault("effects", []).extend([
                {"key": "world.nv7.rabbit_king_outcome", "op": "set", "value": spec[1]},
                {"key": "world.nv7.rabbit_herd_outcome", "op": "set", "value": spec[2]},
                {"key": "world.nv7.live_capture_evidence", "op": "set", "value": spec[3]},
            ])
            combat = {"node_id": combat_id, "type": "combat", "scene_id": "s03", "location_id": "NV7_LOC_FIELDS",
                      "purpose": "rabbit_event_route", "combat_ref": spec[0],
                      "next_on_win": success_target, "next_on_loss": loss_target}
            nodes.append(combat)
            by_id[combat_id] = combat
        by_id[loss_target].setdefault("effects", []).extend([
            {"key": "world.nv7.rabbit_king_outcome", "op": "set", "value": "injured"},
            {"key": "world.nv7.rabbit_herd_outcome", "op": "set", "value": "scattered"},
        ])
        by_id[loss_target].setdefault("quest_actions", []).extend([
            {"action": "fail", "quest_id": task.quest_id, "continuation_id": "apothecary_recovery"},
            {"action": "resume", "quest_id": task.quest_id},
        ])
        by_id[main_order[-1]].setdefault("relationship_actions", []).append(
            {"relationship_id": "NV7_REL_FENGYUE_LANYIN", "dimension": "trust", "op": "inc", "value": 1}
        )

    if task.quest_id == "NV_MAIN_004":
        strategy_choice = next(node for node in nodes if node["type"] == "choice" and node["scene_id"] == "s05")
        success_target = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == "s07")]["entry_nodes"][0]
        loss_target = scenes[next(i for i, value in enumerate(scenes) if value["scene_id"] == "s06")]["entry_nodes"][0]
        combat = {"node_id": "wolf_king_combat", "type": "combat", "scene_id": "s05", "location_id": "NV7_LOC_WOLF_PATH",
                  "purpose": "wolf_king_three_party_battle", "combat_ref": "NV7_COMBAT_WOLF_KING",
                  "next_on_win": "wolf_king_success", "next_on_loss": loss_target}
        success = {"node_id": "wolf_king_success", "type": "narrative", "scene_id": "s05", "location_id": "NV7_LOC_WOLF_PATH",
                   "purpose": "combat_result", "text": ["山狼王的攻势被控制，众人得以撤向旧猎棚。"],
                   "effects": [{"key": "world.nv7.wolf_king_outcome", "op": "set", "value": "controlled"}],
                   "next": success_target}
        for option in strategy_choice["choices"]:
            by_id[option["goto"]]["next"] = "wolf_king_combat"
        by_id[loss_target].setdefault("effects", []).extend([
            {"key": "world.nv7.wolf_king_outcome", "op": "set", "value": "escaped"},
            {"key": "world.nv7.wangwu_injury_stage", "op": "set", "value": "medium"},
        ])
        by_id[loss_target].setdefault("quest_actions", []).extend([
            {"action": "fail", "quest_id": task.quest_id, "continuation_id": "wolf_path_recovery"},
            {"action": "resume", "quest_id": task.quest_id},
        ])
        for extra in (combat, success):
            nodes.append(extra)
            by_id[extra["node_id"]] = extra
        rescue_choice = next(node for node in nodes if node["type"] == "choice" and node["scene_id"] == "s02")
        first_rescue = by_id[rescue_choice["choices"][0]["goto"]]
        first_rescue.setdefault("relationship_actions", []).extend([
            {"relationship_id": "NV7_REL_FENGYUE_TIANHUOLENGHUN", "dimension": "trust", "op": "inc", "value": 1},
            {"relationship_id": "NV7_REL_FENGYUE_TIANHUOLENGHUN", "action": "set_flag", "flag_id": "owes_fengyue_rescue", "value": True},
        ])

    # Manager mappings frozen by the reviewed package.
    if task.quest_id == "NV_MAIN_001":
        by_id[first].setdefault("effects", []).append({"key": "world.nv7.return_channel_seen", "op": "set", "value": True})
        by_id[first]["foreshadowing_refs"] = ["RETURN_CHANNEL", "WORLD_REALITY", "PLAYERS_TRAPPED"]
        origin_choice = next(node for node in nodes if node["type"] == "choice" and node["scene_id"] == "s03")
        origin_actions = (
            [
                {"relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN", "dimension": "trust", "op": "inc", "value": 1},
                {"relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN", "action": "set_flag", "flag_id": "remembers_fengyue_candor", "value": True},
            ],
            [
                {"relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN", "dimension": "tension", "op": "inc", "value": 1},
                {"relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN", "action": "set_flag", "flag_id": "cautious_about_fengyue", "value": True},
            ],
            [{"relationship_id": "NV7_REL_FENGYUE_GUCHANGCHUAN", "dimension": "tension", "op": "inc", "value": 1}],
        )
        for option, actions in zip(origin_choice["choices"], origin_actions):
            by_id[option["goto"]]["relationship_actions"] = actions
    elif task.quest_id == "NV_MAIN_003":
        by_id[first].setdefault("effects", []).append({"key": "world.nv7.rabbit_event_started", "op": "set", "value": True})
        by_id[first]["foreshadowing_refs"] = ["LIVE_CREATURE_PURCHASE", "SILVER_BLACK_SYSTEM_MATERIAL", "LANYIN_CHARACTER_ARC"]
    elif task.quest_id == "NV_MAIN_004":
        by_id[first].setdefault("effects", []).extend([
            {"key": "world.nv7.adventurers_trapped_confirmed", "op": "set", "value": True},
            {"key": "world.nv7.wangwu_injury_stage", "op": "set", "value": "light"},
        ])
        by_id[first]["foreshadowing_refs"] = ["PLAYERS_TRAPPED", "GREED_RING", "LANYIN_CHARACTER_ARC"]

    quest = {
        "schema_version": "1.5.0", "quest_id": task.quest_id, "content_status": "complete_script", "title": task.title,
        "region_id": "NV7", "category": "main", "source_chapters": task.chapters,
        "source_refs": [f"reviewed-package:R1.1/{source_path.name}"],
        "design": {"purpose": "第七新手村R1正式接入", "theme": "被困世界中的求证与协作", "emotion": "异常、试探、行动",
                   "source": "审核通过的R1.1完整剧本包", "adaptation": "机械结构化，不改写核心台词",
                   "conflict": "玩家在真实风险中判断行动", "mechanic": "对话、选择、任务与战斗引用",
                   "start": sections[0][1], "end": sections[-1][1], "feedback": "保留任务后回访"},
        "prerequisites": [], "mutual_exclusions": [],
        "trigger": {"method": "story_chain", "location_id": task.start_location, "conditions": [], "opening_presentation": {}},
        "scenes": scenes, "entry_node": first, "nodes": nodes,
        "mechanics": [{"type": "story_choice"}, {"type": "manager_integration"}],
        "branch_summary": [{"branch": "reviewed_choices_preserved"}],
        "continuations": [{"type": "normal", "node_id": "story_complete"},
                          {"type": "failure", "node_id": scenes[-1]["entry_nodes"][0]}],
        "rewards": [{"type": "signal_only", "reward_id": f"{task.quest_id}_REWARD"}],
        "world_changes": [{"type": "registered_state_only"}],
        "post_quest_feedback": [{"text": "任务后回访内容已保留在结构化节点中。"}],
        "implementation": {"owner": "story", "version": 1, "reviewed": True, "offline": True,
                           "notes": "R1.1审核包机械结构化；迁移映射见生成报告。"},
        "runtime": quest_runtime(task),
        "allowed_loops": ([{"loop_id": "parallel_commission_return", "node_ids": ["commission_hub"],
                             "max_recommended_repeats": 3, "has_exit": True}] if task.quest_id == "NV_MAIN_002" else []),
        "test_cases": [
            {"test_id": f"{task.quest_id.lower()}_start", "initial_state": {}, "steps": [first], "expected": ["story_started"]},
            {"test_id": f"{task.quest_id.lower()}_route", "initial_state": {}, "steps": [first], "expected": ["choice_or_dialogue"]},
            {"test_id": f"{task.quest_id.lower()}_complete", "initial_state": {}, "steps": [first], "expected": ["story_complete"]},
        ],
    }
    meta = {
        "quest": {key: value for key, value in quest.items() if key != "nodes"},
        "baseline": {"min_visible_text_chars": 2500, "min_nodes": 6, "min_dialogue_nodes": 20,
                     "min_choice_nodes": 2, "min_terminal_nodes": 1, "required_node_ids": [first, "story_complete"]},
        "ownership": {"conditions": "GameState", "effects": "GameState", "quest_actions": "QuestManager",
                      "item_rewards": "InventoryManager", "combat_id": "CombatRunner", "relationship_actions": "RelationshipManager",
                      "expression": "MainUI", "gesture": "MainUI", "portrait_action": "MainUI", "camera": "MainUI", "delivery": "MainUI"},
    }
    document = [f"# TASK {task.quest_id}《{task.title}》", "", "## META", "", "```story-meta", json.dumps(meta, ensure_ascii=False, indent=2), "```", ""]
    scene_titles = {scene["scene_id"]: scene["title"] for scene in scenes}
    active_scene = None
    for node in nodes:
        if node["scene_id"] != active_scene:
            active_scene = node["scene_id"]
            document.extend([f"## SCENE {active_scene}：{scene_titles.get(active_scene, active_scene)}", ""])
        document.extend(["```story-node", dump(node), "```", ""])
    report = {
        "story_id": task.quest_id, "source": source_path.name, "source_status": "COMPLETE_SCRIPT_DRAFT",
        "normalized_status": "COMPLETE_SCRIPT", "dialogue_policy": "verbatim extraction",
        "choice_policy": "explicit labelled groups preserved; R1.3 investigation headings promoted mechanically",
        "manager_mapping": "registered IDs and typed public Manager actions only", "core_rewrite": False,
        "scene_count": len(scenes), "node_count": len(nodes), "choice_group_count": sum(node["type"] == "choice" for node in nodes),
    }
    return {"markdown": "\n".join(document), "quest": quest}, report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package_root", type=Path)
    parser.add_argument("output_root", type=Path)
    args = parser.parse_args()
    output = args.output_root
    output.mkdir(parents=True, exist_ok=True)
    reports = []
    for task in TASKS:
        matches = sorted(args.package_root.glob(task.source_glob))
        if len(matches) != 1:
            raise SystemExit(f"expected one {task.source_glob}, found {len(matches)}")
        built, report = build_task(task, matches[0])
        (output / f"{task.quest_id}.md").write_text(built["markdown"] + "\n", encoding="utf-8")
        reports.append(report)
    report_path = output.parents[2] / "reviews" / "nv7_r1_migration_report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps({"schema_version": "1.0.0", "reports": reports}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
