# 第七新手村 R2 接入前状态契约

## 范围

本文只冻结 R1 结束时允许 R2 读取的公开接口和状态，不包含 NV_MAIN_005—008 剧情、节点或运行时数据。R2 必须通过各 Manager 公开接口读取，不能直接修改内部字典。

## R1 任务状态

- `quest.nv_main_001.status`：应为 `completed`。
- `quest.nv_main_002.status`：允许 `qualified` 或 `completed`。
- `quest.nv_main_003.status`：应为 `completed`。
- `quest.nv_main_004.status`：应为 `completed`。
- 三份委托进度：读取 `hanshi`、`suzhi`、`guchangchuan` 三个 objective；至少两个为 true，第三个可以在 R2 开始前后回补。
- R2 不得把 qualified 强制改成 completed，也不得重发 R1 奖励。

## 世界与分支状态

| 领域 | GameState 键 | 允许值/含义 |
|---|---|---|
| 兔王 | `world.nv7.rabbit_king_outcome` | `alive` / `dead` / `injured` |
| 兔群 | `world.nv7.rabbit_herd_outcome` | R1 已登记枚举结果 |
| 捕兽网络证据 | `world.nv7.live_capture_evidence` | `none` 或 R1 调查所得证据等级 |
| 捕兽者暴露 | `world.nv7.poacher_exposed` | boolean |
| 蓝色粉末 | `world.nv7.blue_powder_seen` | boolean |
| 界石异常 | `world.nv7.boundary_stone_anomaly` | boolean |
| 山狼王 | `world.nv7.wolf_king_outcome` | `controlled` / `escaped` 等登记结果 |
| 玩家受困事实 | `world.nv7.adventurers_trapped_confirmed` | boolean |

R2 不得覆盖兔王、兔群、捕兽证据和山狼王既有结果；只能基于结果选择反馈版本或通过新事件产生后续状态。

## 人物关系

- 岚音：通过 `NV7_REL_FENGYUE_LANYIN` 读取 trust、affection、respect、tension、stage、登记 flag/boundary。
- 天火冷魂：通过 `NV7_REL_FENGYUE_TIANHUOLENGHUN` 读取四维中已登记维度、stage 和 `owes_fengyue_rescue` flag。
- 顾长川、韩石、苏芷同样只通过 RelationshipManager 公开接口读取。
- R2 不得重新执行 R1 关系 effects，不得把岚音视为奖励，也不得让顾长川获得现实世界知识。

## 玩家物品

通过 InventoryManager 查询，不以 GameState 临时布尔值代替：

- 初始装备三选一：`NV7_ITEM_NOVICE_SWORD` / `NV7_ITEM_NOVICE_SHIELD` / `NV7_ITEM_NOVICE_HOOK_STAFF`。
- 委托证据：`NV7_ITEM_BLUE_POWDER_SAMPLE`、`NV7_ITEM_BOUNDARY_RUBBING`。
- R1 线索/任务物：`NV7_ITEM_TREASURE_MAP_FRAGMENT`、`NV7_ITEM_SILVERBLACK_FRAGMENT`。
- 其他 R1 物品数量按 InventoryManager 快照原样继承；R2 不得因进入新任务重复授予唯一物品。

## 已登记伏笔与下一次读取义务

| foreshadowing_id | R1 状态 | R2 接入义务 |
|---|---|---|
| RETURN_CHANNEL | reinforced | 读取无法退出与顾长川认知差异，不提前给出返回真相 |
| PLAYERS_TRAPPED | reinforced | 读取玩家受困事实，保持玩家类 NPC 规则 |
| LIVE_CREATURE_PURCHASE | reinforced | 读取捕兽网络证据及兔王路线结果 |
| SILVER_BLACK_SYSTEM_MATERIAL | reinforced | 读取银黑碎片是否持有，不解释最终来源 |

R2 剧本冻结节点后，必须把实际再次读取节点登记到 `foreshadowing_registry.json`；在此之前不得填造 reveal_node 或 payoff_node。

## 存档与幂等

- SaveManager 恢复后，以 GameState、QuestManager、InventoryManager、RelationshipManager 和 StoryRunner 的现有快照为准。
- R2 开场不得重放 R1 complete 节点来“补状态”。
- 所有 R1 `reward_granted` 标记必须保留。
- R2 接入测试必须从 `qualified` 和 `completed` 两种 NV_MAIN_002 快照分别启动。
