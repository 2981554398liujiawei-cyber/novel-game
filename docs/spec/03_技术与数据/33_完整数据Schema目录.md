# 完整数据Schema目录

## 1. 必备Schema

| Schema | 对象 | 关键校验 |
|---|---|---|
| `quest.schema.json` | 任务与完整节点剧本 | 统一内容状态、节点、分支、回访、测试，以及可选QuestManager运行时状态键、目标、推进门槛和失败续接策略 |
| `npc.schema.json` | 具名与通用人物 | 身份分类、现实记忆、复活规则、人物资料、立绘表情 |
| `state_registry.schema.json` | 集中状态表 | 类型、默认值、范围、允许值、持久性 |
| `location.schema.json` | 地点节点 | 背景卡、连接、开放条件、版本文本 |
| `item.schema.json` | 物品与装备 | 旧物品字段，以及可选运行时类型、堆叠、唯一性、关键奖励、存储区、保管箱策略、六装备槽、属性修正、使用场景与类型化效果 |
| `skill.schema.json` | 战斗/非战斗技能 | 冷却、每战次数、目标、效果、来源 |
| `enemy.schema.json` | 敌人与首领 | 属性、技能、AI、掉落、首领阶段引用 |
| `combat.schema.json` | 战斗实例 | 参战单位、胜负条件、撤退、阶段、续接 |
| `quest_dependency.schema.json` | 任务依赖图 | 稳定任务ID、唯一依赖边、状态门；重复拥有者、自依赖和循环依赖由语义校验器阻止 |
| `save.schema.json` | 存档结构 | 版本、GameState、可选InventoryManager结构化快照、随机种子、当前节点 |
| `content_manifest.schema.json` | 运行内容清单 | 文件类型、哈希、加载顺序、禁止夹具 |
| `relationship.schema.json` | 关系运行注册表 | 四维关系、五级阶段、状态键映射、边界、拒绝续接、冲突与文本版本标签 |
| `story_ir.schema.json` | Normalized Story Model | 源哈希、完整任务模型、节点指标、Manager所有权与结构哈希 |
| `story_approval.schema.json` | 人工批准记录 | 任务ID、审阅者、时间、源哈希与结构哈希 |
| `story_package_manifest.schema.json` | 原始剧情包登记 | incoming文件、权限状态、哈希与预检报告 |
| `story_region_manifest.schema.json` | 区域接入状态 | SOURCE_ONLY至VERIFIED状态、剧本与运行路径 |
| `story_chapter_mapping.schema.json` | 原著章节映射 | KEEP/MERGE/MIGRATE/DROP完整且不重复 |
| `foreshadowing_registry.schema.json` | 伏笔登记 | 首次出现、强化、误导、揭示、回收与状态 |

## 2. 演出注册表

另设`presentation_tags.json`登记`gesture`、`delivery`、`camera`、`portrait_action`和音效标签。任务数据只能引用已登记标签，禁止同义词无限膨胀。标签可带参数，例如`look_at(target)`应转成固定动作ID与目标字段，而不是临时创造字符串。

## 3. 跨文件校验

每次构建必须检查：Schema错误、重复ID、无效引用、未知状态、类型不匹配、数值越界、非法操作、任务依赖循环、不可达节点、强制无限循环、无终止出口、立绘`keep`无已显示人物、表情不存在、战斗规则字符串化、关键奖励不存在、运行manifest引用夹具、存档版本无迁移方案。

`quest.schema.json`的`runtime`为向后兼容的可选区块：旧任务数据可继续只作为StoryRunner节点数据使用；需要QuestManager管理时，必须显式声明生命周期状态键、奖励幂等键、前置条件组、目标、完成方式和失败续接策略。所有引用键都必须先登记到状态注册表，管理器不得由任务ID临时拼接或创建状态键。

`item.schema.json`的`runtime`同样是向后兼容的可选区块。旧字段由InventoryManager规范化读取；新增或更新的可运行物品应完整声明该区块。Schema负责形状和枚举，语义校验器另外检查堆叠上限、关键物品保护、装备槽组合、双手占槽、状态引用及`inventory`写权限、持有标记隔离和任务奖励物品引用。可选`combat_effects`只描述本场治疗、施加状态和移除状态，由CombatRunner解释，InventoryManager仍独占物品扣除。任务奖励类型只允许`signal_only`或`items`，未知类型不得被静默忽略。测试物品只放在fixtures中，正式manifest不得引用。

`combat.schema.json`、`enemy.schema.json`与`skill.schema.json`以可选`runtime`契约补充CombatRunner所需的集中数值规则、状态效果注册、唯一单位实例、类型化阶段、观察、撤退、结算、AI动作、技能条件和类型化效果。未声明`runtime`的1.3正式数据继续作为兼容内容索引加载；只有需要进入CombatRunner的战斗才必须提供完整运行契约。跨文件语义校验器负责技能、状态、敌人实例、AI动作和阶段引用，并限制每单位最多四个技能、正权重AI以及首领2—3阶段。合成战斗数据只允许放在`content/tests/fixtures/combat_runner/`，不得写入正式manifest或Windows导出包。

`relationship.schema.json`描述独立的关系运行注册表。Schema负责维度、阶段、规则、动作、拒绝、冲突与文本标签的形状；语义校验器另外检查维度/阶段/标记/边界引用、GameState键存在性与类型、持久性、`relationship`写权限、重复关系ID和重复有向人物对。当前只提供`content/tests/fixtures/relationship_manager/`合成数据，正式manifest不得引用该目录；接入正式关系数据前必须先登记对应状态键并完成内容审核。

## 4. 版本

Schema使用语义版本。增加可选字段提升次版本；删除字段、改语义或改变存档结构提升主版本。每个数据文件必须声明`schema_version`，加载器不接受未知主版本。
