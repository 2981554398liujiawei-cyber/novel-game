# 实现 SaveManager

## Goal

实现开发期存档、原子写入、备份、恢复和版本字段。

## Context

- `docs/spec/02_玩法与UI/22_存档失败续接与调试规范.md`
- `docs/production/04_存档开发期兼容策略.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- Prototype 阶段可不迁移旧开发档
- 不得静默丢档

## Acceptance criteria

保存读取往返一致；损坏主档可从备份恢复；随机种子持久化。

## Required validation

- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
