# 建立 Windows 构建闭环

## Goal

完成导出、版本信息、日志和发布目录结构。

## Context

- `docs/spec/04_计划与验收/46_Windows运行环境与性能边界.md`
- `export_presets.cfg`

## Scope

只实现本任务目标所需的最小完整改动。

## Out of scope

- 正式剧情创作。
- 与本任务无关的大规模重构。

## Constraints

- 完全离线
- 不打包开发 fixture
- 不包含调试控制台到候选版

## Acceptance criteria

Windows 构建成功；解压可运行；运行时无网络依赖。

## Required validation

- `scripts/validate.ps1`
- `scripts/test.ps1`
- `scripts/smoke_test.ps1`
- `scripts/build_windows.ps1`

## Report format

列出修改文件、主要实现、实际运行的验证命令及结果、仍存在的阻塞项。
