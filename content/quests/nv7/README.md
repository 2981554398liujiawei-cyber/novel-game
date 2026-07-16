# NV7 正式任务运行时数据

本目录仅接收达到 `data_ready` 的第七新手村任务 JSON。

当前剧情母稿已经接入 `docs/story/` 的来源治理，但尚未逐任务完成 16 字段 `complete_script → data_ready` 流程，因此这里暂时不放置正式任务 JSON。

`NV_MAIN_001` 至 `NV_MAIN_008` 的接入槽位登记在根 `content/manifest.json` 的 `planned_content` 中。槽位均为 `not_loaded` 且 `path` 为 `null`；它们不是任务定义，也不会被 ContentLoader 加载。只有生成的任务 JSON 达到 `data_ready` 或更高状态、通过全部预检并把真实路径加入 `content_files` 后，才可切换为运行时内容。

Codex 不得根据母稿、任务标题或路线摘要自行补写缺失剧情并直接生成生产数据；遇到此情况应报告 `STORY_NOT_DATA_READY`。
