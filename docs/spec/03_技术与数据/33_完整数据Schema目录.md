# 完整数据Schema目录

## 1. 必备Schema

| Schema | 对象 | 关键校验 |
|---|---|---|
| `quest.schema.json` | 任务与完整节点剧本 | 统一内容状态、节点、分支、回访、测试，以及可选QuestManager运行时状态键、目标、推进门槛和失败续接策略 |
| `npc.schema.json` | 具名与通用人物 | 身份分类、现实记忆、复活规则、人物资料、立绘表情 |
| `state_registry.schema.json` | 集中状态表 | 类型、默认值、范围、允许值、持久性 |
| `location.schema.json` | 地点节点 | 背景卡、连接、开放条件、版本文本 |
| `item.schema.json` | 物品与装备 | 类型、品质、堆叠、关键物品、价格、装备槽 |
| `skill.schema.json` | 战斗/非战斗技能 | 冷却、每战次数、目标、效果、来源 |
| `enemy.schema.json` | 敌人与首领 | 属性、技能、AI、掉落、首领阶段引用 |
| `combat.schema.json` | 战斗实例 | 参战单位、胜负条件、撤退、阶段、续接 |
| `quest_dependency.schema.json` | 任务依赖图 | 稳定任务ID、唯一依赖边、状态门；重复拥有者、自依赖和循环依赖由语义校验器阻止 |
| `save.schema.json` | 存档结构 | 版本、状态、任务、随机种子、当前节点 |
| `content_manifest.schema.json` | 运行内容清单 | 文件类型、哈希、加载顺序、禁止夹具 |

## 2. 演出注册表

另设`presentation_tags.json`登记`gesture`、`delivery`、`camera`、`portrait_action`和音效标签。任务数据只能引用已登记标签，禁止同义词无限膨胀。标签可带参数，例如`look_at(target)`应转成固定动作ID与目标字段，而不是临时创造字符串。

## 3. 跨文件校验

每次构建必须检查：Schema错误、重复ID、无效引用、未知状态、类型不匹配、数值越界、非法操作、任务依赖循环、不可达节点、强制无限循环、无终止出口、立绘`keep`无已显示人物、表情不存在、战斗规则字符串化、关键奖励不存在、运行manifest引用夹具、存档版本无迁移方案。

`quest.schema.json`的`runtime`为向后兼容的可选区块：旧任务数据可继续只作为StoryRunner节点数据使用；需要QuestManager管理时，必须显式声明生命周期状态键、奖励幂等键、前置条件组、目标、完成方式和失败续接策略。所有引用键都必须先登记到状态注册表，管理器不得由任务ID临时拼接或创建状态键。

## 4. 版本

Schema使用语义版本。增加可选字段提升次版本；删除字段、改语义或改变存档结构提升主版本。每个数据文件必须声明`schema_version`，加载器不接受未知主版本。
