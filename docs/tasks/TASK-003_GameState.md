# 实现 GameState

## Goal

建立唯一状态真源和类型化条件/效果接口。

## Context

- `docs/spec/03_技术与数据/30_技术架构.md`
- `docs/spec/03_技术与数据/31_数据与ID规范.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 禁止未登记状态
- 禁止 UI 直接写状态

## Acceptance criteria

支持读取、设置、增减、条件判断和状态变化信号，并有单元测试。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
