# COMPLETE_SCRIPT 受约束 Markdown 格式

本格式是人工审核后的完整剧本权威格式。它面向编剧和剧情 AI，但不是任意自由 Markdown：工具只解析明确的 fenced JSON 块，不猜测自然语言结构，也不依赖复杂 Markdown 表格。

## 文档骨架

下面是结构示例，不代表达到正式主线的深度门槛。`quest` 必须包含 `quest.schema.json` 要求的完整设计、场景、机制、续接、奖励、回访、实现和测试字段；正式主线还必须满足固定的场景、话轮、选择、失败续接和反馈门槛。

````markdown
# TASK

## META

```story-meta
{
  "quest": {
    "schema_version": "1.5.0",
    "quest_id": "TEST_STORY_FORMAT",
    "content_status": "complete_script",
    "title": "结构示例",
    "region_id": "TEST_REGION",
    "category": "main",
    "design": {"purpose":"format","theme":"format","emotion":"format","source":"format","adaptation":"format","conflict":"format","mechanic":"format","start":"format","end":"format","feedback":"format"},
    "prerequisites": [],
    "mutual_exclusions": [],
    "trigger": {"method":"test","location_id":"TEST_LOC","conditions":[],"opening_presentation":{}},
    "scenes": [{"scene_id":"opening_scene","title":"开场","entry_nodes":["opening"],"exit_nodes":["complete"],"participant_ids":["TEST_NPC"],"objective":"展示格式","optional_interactions":[]}],
    "entry_node": "opening",
    "mechanics": [{"type":"format_example"}],
    "branch_summary": [{"branch":"continue"}],
    "continuations": [{"type":"normal","node_id":"complete"}],
    "rewards": [{"type":"signal_only","reward_id":"TEST_REWARD"}],
    "world_changes": [{"type":"none"}],
    "post_quest_feedback": [{"text":"结构示例结束。"}],
    "implementation": {"owner":"story","version":1,"reviewed":true,"offline":true,"notes":"format"},
    "allowed_loops": [],
    "test_cases": [
      {"test_id":"format_a","initial_state":{},"steps":["opening"],"expected":["complete"]},
      {"test_id":"format_b","initial_state":{},"steps":["opening"],"expected":["complete"]},
      {"test_id":"format_c","initial_state":{},"steps":["opening"],"expected":["complete"]}
    ]
  },
  "baseline": {"min_visible_text_chars":0,"min_nodes":1,"min_dialogue_nodes":0,"min_choice_nodes":0,"min_terminal_nodes":1,"required_node_ids":[]},
  "ownership": {"conditions":"GameState","effects":"GameState","quest_actions":"QuestManager","item_rewards":"InventoryManager","combat_id":"CombatRunner","relationship_actions":"RelationshipManager","expression":"MainUI","gesture":"MainUI","portrait_action":"MainUI","camera":"MainUI","delivery":"MainUI"}
}
```

## SCENE opening_scene

```story-node
{"node_id":"opening","type":"narrative","scene_id":"opening_scene","location_id":"TEST_LOC","purpose":"hook","text":["实际玩家可见正文。"],"conditions":[],"effects":[],"next":"choice"}
```

### CHOICE

```story-node
{"node_id":"choice","type":"choice","scene_id":"opening_scene","location_id":"TEST_LOC","purpose":"choice","choices":[{"choice_id":"continue","text":"继续。","intent":"continue","protagonist_boundary":"allowed","visible_risk":"none","consequence_summary":"继续到出口","hidden_consequence":"none","conditions":[],"effects":[],"goto":"complete"}]}
```

```story-node
{"node_id":"complete","type":"complete","scene_id":"opening_scene","location_id":"TEST_LOC","purpose":"complete","terminal":true,"outcome":"example_complete"}
```
````

每个 `story-meta` 和 `story-node` 块必须是合法 JSON。节点顺序是审阅顺序；执行顺序由 `next`、choice 的 `goto`、战斗结果续接明确给出。条件和效果必须是类型化对象，禁止表达式字符串。Normalized Story Model 会保留 task metadata、来源章节、scene、node、dialogue、choice、condition、effect、combat/item/relationship/quest/world 操作、失败续接、奖励、回访和 presentation 标签。

## 内容状态映射

区域接入报告使用：`SOURCE_ONLY → DRAFT → COMPLETE_SCRIPT → PARSED → DATA_READY → VERIFIED`。

Quest JSON 使用现有小写运行状态：`outline → design_card → draft_script → complete_script → data_ready → implemented → verified`。映射关系为 `SOURCE_ONLY=尚无任务剧本`、`DRAFT=draft_script或更早`、`COMPLETE_SCRIPT=complete_script`、`PARSED=已生成并验证IR`、`DATA_READY=data_ready`、`VERIFIED=verified`。原始包通过预检不自动提升任何任务状态。

## 表现与主角

NPC 对白使用登记的 `speaker_id`；`expression` 必须属于该 NPC 的 `portrait_set.expressions`。枫月没有大立绘：枫月对白使用姓名牌语义，内心使用旁白语义，禁止把“枫月”或主角占位符作为 portrait 目标。背景、音乐、音效、gesture、camera、delivery 与 portrait_action 必须来自正式注册表，Parser 不会自动创建标签。
