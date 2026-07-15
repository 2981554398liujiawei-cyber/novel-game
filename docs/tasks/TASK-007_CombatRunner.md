# 实现 CombatRunner

## Goal

实现低成本文本回合战斗核心。

## Context

- `docs/spec/02_玩法与UI/20A_战斗与检定完整规格.md`
- `docs/spec/02_玩法与UI/20B_成长经济与物品规则.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 无 MP
- 敏捷顺序
- 防御减伤 40%
- 同伴倾向三档
- 首领最多三阶段

## Acceptance criteria

固定种子下结果可复现；攻击、防御、技能、物品、撤退和失败续接接口可测。

## Required validation

- `scripts/test.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
