# content/AGENTS.md

本目录只存运行时内容数据；剧情源文档永远放在`docs/story/`，不能被运行时直接加载。

- 只有达到`data_ready`的任务才能在`content/quests/`生成正式JSON。
- `source_mother_draft`、`design_card`、`draft_script`、`complete_script`阶段的Markdown不得直接进入运行时manifest。
- 当前剧情母稿已提供，但未自动视为`data_ready`。不得为了“先跑起来”而由Codex自行补全缺失节点或对白。
- 测试专用合成数据只能放`content/tests/fixtures/`，正式manifest禁止引用任何fixture路径。
- 所有新增JSON必须存在对应Schema，并在提交前通过`scripts/validate.ps1`。
- 所有状态键必须先登记到`states/state_registry.json`；禁止任务、战斗或代码临时发明未登记状态。
- 修改ID前先搜索全仓库引用。已签收ID默认不可改名。
- 条件和效果必须使用类型化对象，不使用表达式字符串。
- 正式内容文件必须由`manifest.json`显式登记；未登记文件不得被运行时自动扫描加载。
- NPC立绘表情必须存在于`npcs/npcs.json`声明的表情集合中。
- 当前`NV_MAIN_002`三项子目标为韩石试刃、苏芷药篮、顾长川界石；旧的黄金铁锤/黄金药鼎/二十条虎尾状态不得重新引入。
- 内容修改必须保持跨文件引用有效，并补充相应测试。
