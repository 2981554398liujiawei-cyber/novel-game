# 原始剧情附件落位目录

这里是原始剧情附件的归档位置，不是运行时内容目录。原始附件保持文件名与内容不变，禁止由 Codex 重写后覆盖原件。

推荐落位：

```text
raw_sources/
  active/
    王者_第七新手村完整剧情母稿_v0.1.md
  roadmap/
    01_全剧情任务树_v0.2.docx
  reference/
    02_樱花岛区域完整剧本_v0.2.docx
    《王者：天梦大陆》开放世界剧本与角色设定集_v0.1.docx
```

当前生产包已经通过 `docs/story/source_manifest.json`、接入索引、正式规格与状态契约完成剧情治理接入。若原始附件未物理存在于这些路径，Codex 不得假装已经读取原文；需要逐字核对时应报告 `CONTENT_MISSING`。
