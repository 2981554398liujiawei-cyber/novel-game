# 实现资产加载与回退

## Goal

接入立绘、通用人物、背景、SFX 和音乐占位资产。

## Context

- `docs/spec/03_技术与数据/32_立绘资源与命名规范.md`
- `docs/production/05_背景与音频资产规范.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 缺失立绘回退 npc_missing.png
- 缺音频不得阻塞主线

## Acceptance criteria

所有登记 NPC 表情可加载；缺图回退可用；音乐与音效可关闭。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
