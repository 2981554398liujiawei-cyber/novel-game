# Git 与分支工作流

仓库：`2981554398liujiawei-cyber/novel-game`

建议：

- `main`：始终保持可验证。
- `feature/task-xxx-*`：一张任务卡一个分支。
- `fix/*`：缺陷修复。
- 不在 `main` 上直接进行大范围试验。

合并前至少满足：

- `scripts/validate.ps1` 通过；
- 涉及代码时 `scripts/test.ps1` 通过；
- 涉及启动流程时 `scripts/smoke_test.ps1` 通过；
- 没有误提交 `.godot/`、`builds/`、存档、密钥、虚拟环境或缓存。

提交信息建议：

- `feat: ...`
- `fix: ...`
- `test: ...`
- `docs: ...`
- `chore: ...`
