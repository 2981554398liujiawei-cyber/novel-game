# 实现 StoryRunner 接口

## Goal

实现剧情节点解释器接口和合成fixture流程。可参考`docs/story/active/`理解真实流程需求，但不得把剧情母稿直接当作生产任务JSON。

## Context

- `docs/spec/01_叙事与改编/17_完整任务剧本与对白数据规范.md`
- `schemas/quest.schema.json`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 不得自行生成正式剧情
- 只使用测试夹具验证节点类型

## Acceptance criteria

合成任务可完成叙事、对白、选择、战斗引用、奖励和完成节点的最小链路。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
