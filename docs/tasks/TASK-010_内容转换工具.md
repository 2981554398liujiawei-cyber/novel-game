# 实现内容转换工具

## Goal

建立审核稿到 JSON 和 JSON 到审阅稿的单向受控转换流程。

## Context

- `docs/spec/03_技术与数据/31A_内容权威源与转换流程.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 正式任务尚未达到`data_ready`时使用合成样例；不得直接转换`source_mother_draft`
- 禁止长期双源手改

## Acceptance criteria

转换结果稳定、可重复；生成 JSON 可通过 Schema；可从 JSON 生成审阅稿。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
