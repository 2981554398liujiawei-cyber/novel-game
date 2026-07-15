# 实现 ContentLoader

## Goal

按 manifest 加载外部内容，并执行 Schema 和引用前置校验。

## Context

- `docs/spec/03_技术与数据/30_技术架构.md`
- `docs/spec/03_技术与数据/31_数据与ID规范.md`
- `content/AGENTS.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 不扫描未登记临时文件
- 验证失败不得继续进入游戏

## Acceptance criteria

合法内容可加载；非法 Schema、缺文件和无效引用有明确错误。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
