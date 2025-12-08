# 架构决策记录 (Architecture Decision Records)

本目录包含 NotBad 项目的架构决策记录。

## 什么是 ADR？

架构决策记录 (ADR) 是一种记录重要架构决策的文档格式。每个 ADR 描述了一个架构决策，包括决策的上下文、考虑的选项、做出的决定以及后果。

## ADR 列表（活跃）

| 编号 | 标题 | 状态 | 日期 |
|------|------|------|------|
| [ADR-006](ADR-006-pragmatic-architecture.md) | **实用主义架构** | ✅ 已采纳 | 2025-12-06 |
| [ADR-007](ADR-007-modularization-direction.md) | **模块化演进方向** | 📋 提议中 | 2025-12-06 |

> 📢 **当前架构**：ADR-006 实用主义架构（3 层：Views → Services → Models）
> 
> 📋 **未来方向**：ADR-007 提议在代码量增长后采用 Swift Package 模块化

## 已归档

- 过往 ADR 已迁移至 `../archive/adr/`：
	- [ADR-001](../archive/adr/ADR-001-clean-architecture.md)
	- [ADR-002](../archive/adr/ADR-002-swiftdata.md)
	- [ADR-003](../archive/adr/ADR-003-use-cases.md)
	- [ADR-004](../archive/adr/ADR-004-error-system.md)
	- [ADR-005](../archive/adr/ADR-005-di-factory.md)
- 历史 ADA 规划：`../archive/ADA_ROADMAP.md`

## ADR 模板

```markdown
# ADR-XXX: 标题

## 状态
已采纳 / 已废弃 / 待定

## 上下文
描述问题背景和约束条件...

## 决策
我们决定...

## 选项考虑
### 选项 A
- 优点: ...
- 缺点: ...

### 选项 B
- 优点: ...
- 缺点: ...

## 后果
### 正面
- ...

### 负面
- ...

## 参考
- 相关链接或文档
```

## 参考资料

- [ADR GitHub Organization](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
