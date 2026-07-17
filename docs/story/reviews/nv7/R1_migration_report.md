# NV7 R1 规范化迁移报告

## 结论

NV_MAIN_001—004 已从审核交付包中的 `COMPLETE_SCRIPT_DRAFT` 机械结构化为受约束 Markdown，并经 Story Pipeline 生成运行时 JSON。迁移没有改写核心对白、人物动机、分支结果或任务结局。

## 自动修正

- 关系维度：`candor` 优先转为“记住坦率态度”flag；`wariness`、`caution` 转为 tension 或谨慎 flag；`debt` 转为“欠下救援”flag；`pragmatism` 转为“认可务实”flag；`closeness` 仅在原语义明确时映射 affection。本批次没有用不明确映射替代正文语义。
- 主角表现：枫月保留 speaker/nameplate；移除主角大立绘要求，内心与动作改用 narrative，portrait action 使用 hide/keep。
- 音频标签：村庄、野外、首领和静音分别映射到 `MUSIC_VILLAGE`、`MUSIC_WILDERNESS`、`MUSIC_BOSS`、`NONE`；音效只引用现有 presentation tag 注册表，不自动创建标签。
- Manager 所有权：任务动作使用 QuestManager；物品授予使用 InventoryManager；关系维度、flag 与 boundary 使用 RelationshipManager；战斗只引用 CombatRunner 的 combat_id；长期世界结果使用 GameState。
- 正式 ID：复用已有 NPC；新增物品、敌人、战斗、地点、关系与状态均登记后再由剧情引用。

## 结构化产物

| 任务 | 场景 | 节点 | 选择组 | 状态 |
|---|---:|---:|---:|---|
| NV_MAIN_001 | 6 | 131 | 3 | DATA_READY |
| NV_MAIN_002 | 8 | 223 | 5 | DATA_READY |
| NV_MAIN_003 | 5 | 125 | 2 | DATA_READY |
| NV_MAIN_004 | 8 | 269 | 4 | DATA_READY |

逐任务机器可读记录见 `docs/story/reviews/nv7_r1_migration_report.json`。受约束 Markdown、Normalized Story Model、生成审阅稿和运行时 JSON 均保留 source reference 与 approval 记录。

## 未自动处理

- 不推断未冻结世界观真相。
- 不替原著章节做文学判断；章节映射按审核包标注登记。
- 不新增 R2、NV_MAIN_005—008 正文或运行时文件。
