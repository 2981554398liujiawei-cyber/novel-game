# AGENTS 规则分层说明

## 根 AGENTS.md

存放 Codex 高频调用且必须长期记住的规则，包括：

- 产品范围；
- 剧情禁止自行补写；
- 世界规则；
- 主角人格边界；
- 战斗冻结规则；
- UI 与资产范围；
- 架构、数据、存档、离线、测试和 Git 规则。

## 目录级 AGENTS.md

只写局部补充，避免根文件无限膨胀：

- `content/AGENTS.md`：内容和数据规则；
- `src/AGENTS.md`：代码架构规则；
- `tests/AGENTS.md`：测试规则；
- `docs/spec/AGENTS.md`：规格修改规则。

关键规则不能只存在于深层文档中。高频规则必须在根 AGENTS 保留简明版本。
