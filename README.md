# novel-game 生产启动与剧情接入包 v1.5

这是面向 `https://github.com/2981554398liujiawei-cyber/novel-game.git` 整理的可直接落仓库项目结构。仓库当前为空，因此本包按干净的 Godot 项目结构组织。

## 已包含

- 重点强化的仓库级与目录级 `AGENTS.md`；
- v1.3 正式产品/技术规格，并已同步当前剧情母稿的三份委托定义；
- `docs/story/` 剧情源分层、来源清单、当前新手村接入索引和未来剧情隔离规则；
- Godot 4.6.2 最小工程骨架；
- 内容目录、Schema、运行时 manifest 和非剧本基础数据；
- Python 校验器、PowerShell 一键命令和 GitHub Actions 基础CI；
- 6张 UI 低保真线框；
- 21张人物占位图、8张背景色调卡、12个短音效和3首音乐占位资源；
- 第一批 Codex 技术任务卡；
- 生产启动、Git、存档、背景音频和内容转换规范。

## 剧情包接入状态

当前第七新手村剧情母稿被登记为 `source_mother_draft`：它是当前篇章剧情来源，但还需要逐任务拆成16字段 `complete_script` 并冻结为 `data_ready`，才能生成正式 `content/quests/*.json`。

未来全剧情任务树、樱花岛剧本和旧开放世界设定被隔离到 `docs/story/roadmap/` 与 `docs/story/reference/` 的治理规则中，不能扩大当前新手村开发范围。

## 推荐首次操作

```powershell
./scripts/setup.ps1
./scripts/validate.ps1
./scripts/test.ps1
./scripts/smoke_test.ps1
```

Godot 不在 PATH 时：

```powershell
$env:GODOT_BIN = "C:\Tools\Godot_v4.6.2-stable_win64.exe"
./scripts/smoke_test.ps1
```

开发从 `docs/tasks/00_任务索引.md` 开始。不要第一次就要求 Codex “完成整个游戏”。

## 原始剧情附件说明

本包已经完成剧情源的目录治理、权威级别、当前新手村冲突清理和运行时接口接入。原始上传附件应按 `docs/story/raw_sources/README.md` 的路径原样归档；原始附件本身不是运行时数据。若原件尚未物理落入仓库，技术骨架仍可开发，但任何依赖具体剧情正文的任务必须停在 `STORY_NOT_DATA_READY` / `CONTENT_MISSING` 边界，Codex不得自行补写。
