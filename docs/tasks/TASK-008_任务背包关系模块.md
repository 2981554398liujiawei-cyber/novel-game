# 实现任务、背包与关系模块

## Goal

建立 QuestManager、InventoryManager、RelationshipManager 的数据接口。

## Context

- `docs/spec/03_技术与数据/30_技术架构.md`
- `docs/spec/02_玩法与UI/20B_成长经济与物品规则.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 模块不持有重复世界状态
- 拒绝暧昧不得造成主线惩罚

## Acceptance criteria

关键物品不丢失；背包满有保管机制；关系阈值读取正确。

## Required validation

- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
