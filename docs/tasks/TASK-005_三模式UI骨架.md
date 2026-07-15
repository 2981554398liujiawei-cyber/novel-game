# 实现三模式 UI 骨架

## Goal

实现探索阅读、NPC 对话立绘、文本战斗的基础布局和切换。

## Context

- `docs/spec/02_玩法与UI/21_Windows_UI_UX规范.md`
- `docs/spec/02_玩法与UI/21A_战斗UI与功能页线框规范.md`
- `docs/wireframes/README.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 使用占位资产
- 1280x720 不遮挡正文和选项

## Acceptance criteria

三种模式可切换；720p 与 1080p 布局无核心遮挡。

## Required validation

- `scripts/test.ps1`
- `scripts/smoke_test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
