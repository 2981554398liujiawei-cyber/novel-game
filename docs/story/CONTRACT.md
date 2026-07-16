# 正式剧情接入契约

权威链固定为：原始交付包 → 人工审核的 COMPLETE_SCRIPT → Normalized Story Model → 运行时 Quest JSON → 自动生成审阅稿。审阅稿是派生物，不得反向成为权威源。

## Manager 所有权

- GameState：登记后的长期世界状态；条件调用 `evaluate_condition`，效果调用 `apply_effects`。
- QuestManager：任务生命周期、目标进度、qualified、完成、失败、暂停与续接。
- InventoryManager：物品授予、数量、装备、关键物品和保管箱。
- CombatRunner：剧情只引用 `combat_id`、预期结果标签与续接映射，不复制战斗规则。
- RelationshipManager：仅允许 `trust`、`affection`、`respect`、`tension` 维度及正式登记的 flag/boundary。
- MainUI：expression、gesture、portrait_action、camera、delivery 等展示标签。

跨 Manager 操作必须在 Normalized Story Model 中保持类型和所有权，不能伪装成 GameState 键。若当前运行时 Quest Schema 或 StoryRunner 尚无对应执行字段，转换必须失败并报告 `DATA_CONTRACT_MISSING`，不得静默丢弃。

## 注册表来源

- 状态：`content/states/state_registry.json`
- NPC 与 NPC 表情：`content/npcs/npcs.json`
- 物品：`content/items/items.json`
- 战斗：`content/combats/combats.json`
- 地点：`content/locations/locations.json`
- 表现标签：`content/presentation_tags.json`
- 正式运行文件：根 `content/manifest.json`

任何未登记引用、非法所有权、占位文本、不可达节点、无出口或未声明循环都会阻止进入 DATA_READY。正式运行 Manifest 不得引用 DRAFT、fixtures、`docs/story/` 或 `raw_sources/`。

## 目录与状态

- `reviews/` 保存人工审阅记录；`approvals/` 保存绑定源哈希和IR哈希的机器可校验批准记录。
- `generated_reviews/` 保存 Runtime JSON 自动生成的审阅稿，它不是权威源。
- `scripts/nv7/R1/`、`scripts/nv7/R2/` 只接收已人工整理的受约束 Markdown；当前均为空壳。
- 区域报告统一使用 `SOURCE_ONLY → DRAFT → COMPLETE_SCRIPT → PARSED → DATA_READY → VERIFIED`，与 Quest JSON 的小写状态按 `FORMAT.md` 映射。

根 `content/manifest.json` 的 `planned_content` 是八个稳定接入槽。`not_loaded` 时路径必须为 `null`；任务达到 `data_ready` 后，槽位状态改为对应小写运行状态、路径指向真实 Quest JSON，并且同一路径必须加入 `content_files`。校验器会对照任务ID和内容状态。不得通过保留 `not_loaded` 来掩盖已加载任务。
