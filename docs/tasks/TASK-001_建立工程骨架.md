# 建立工程骨架

## Goal

确认最小 Godot 工程、目录、主场景和导出 preset 正确。

## Context

- `docs/spec/03_技术与数据/30_技术架构.md`
- `docs/production/01_开发环境锁定.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 不实现正式剧情
- 不增加第三方插件

## Acceptance criteria

工程可无界面启动并输出 SMOKE_TEST_OK。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`
- `scripts/smoke_test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
