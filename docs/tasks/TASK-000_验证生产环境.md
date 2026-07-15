# 验证生产环境

## Goal

确认 Godot 4.6.2、Python 和仓库脚本可运行。

## Context

- `README.md`
- `docs/production/01_开发环境锁定.md`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 不实现游戏功能
- 不修改产品规格

## Acceptance criteria

setup 和 validate 均成功；记录 Godot 与 Python 版本。

## Required validation

- `scripts/setup.ps1`
- `scripts/validate.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
