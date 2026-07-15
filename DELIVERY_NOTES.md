# 《王者》novel-game Codex生产启动包 v1.5 交付说明

## 1. 对应仓库

`2981554398liujiawei-cyber/novel-game`

本次整理以空仓库作为干净基线，压缩包根目录内容可直接放入仓库根目录。

## 2. 本次完成的生产准备

- 强化根 `AGENTS.md`，集中高频、关键且不可违背的产品、剧情、数据、战斗、UI、存档、验证和Git规则。
- 在 `content/`、`docs/spec/`、`docs/story/`、`src/`、`tests/` 使用局部 `AGENTS.md` 补充目录级职责，并自动检查指令链大小。
- 锁定 Godot 4.6.2 Standard、GDScript、Windows 10/11 x86-64 基线。
- 建立可打开的Godot最小工程结构、内容接口、Schema、manifest、测试和PowerShell统一命令。
- 建立 GitHub Actions 基础CI。
- 建立6张UI低保真线框、21张人物占位图、8张地点背景卡、12个短音效和3首循环音乐占位文件。
- 建立第一批Codex技术任务卡，禁止第一次任务直接要求“完成整个游戏”。
- 接入剧情源治理结构，区分当前剧情源、未来路线和参考材料。
- 同步修复当前 `NV_MAIN_002《三份委托》` 的定义冲突，以“韩石的试刃 / 苏芷的药篮 / 顾长川的界石”为当前版本。

## 3. 剧情文件状态

当前新手村剧情母稿已作为剧情权威源登记，项目规格、状态键、任务依赖接口和Codex规则已经同步到该版本。

原始上传的剧情附件在本次工具环境中只能作为文件引用读取，不能直接复制原始文件字节到生成的ZIP。因此压缩包内提供：

- `docs/story/source_manifest.json`：原始剧情文件名、权威级别、作用范围、目标仓库路径；
- `docs/story/active/`：当前新手村剧情源接入索引；
- `docs/story/roadmap/`：全剧情任务树的隔离与使用规则；
- `docs/story/reference/`：樱花岛和旧世界设定的参考隔离规则；
- `docs/story/raw_sources/`：原始附件应原样放入的目标目录。

不得用不完整摘录冒充原始附件。原始附件未落位时，Codex可以开发技术骨架，但不得自行补写正式剧情。

## 4. 当前剧情生产边界

剧情母稿状态为 `source_mother_draft`，后续必须逐任务完成：

`source_mother_draft → design_card → draft_script → complete_script → data_ready → implemented → verified`

只有 `data_ready` 的任务才能进入 `content/quests/nv7/` 作为正式运行时JSON。

## 5. 已执行验证

- 仓库结构、JSON、Schema、manifest、资产数量、剧情源治理、三份委托状态契约、离线运行时扫描：通过。
- Python仓库契约测试：7/7通过。
- 25个JSON文件：全部可解析。
- 根AGENTS与任何局部AGENTS的常见指令链：均低于32 KiB默认项目文档预算。

当前执行环境没有Godot 4.6.2可执行文件，因此没有在这里实际执行Godot无界面启动或Windows导出；仓库内已经提供 `scripts/smoke_test.ps1` 和 `scripts/build_windows.ps1`，应在装有锁定版本Godot的Windows环境中执行。
