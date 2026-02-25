# ADR 0001: 采用架构决策记录 (ADR) 机制

**日期**: 2026-02-25
**状态**: ✅ Accepted

## 1. 背景 (Context)

随着项目的演进和自动化 AI Agent 的介入，我们目前有多个代码规范文件（如 `.github/copilot-instructions.md`, `.agent/skills/snapdrill-swift-standards/swift6_rules_full.md` 等）。这些“宪法式”的约定极大地保证了代码下限，但也容易陷入“立下规矩后不再更新”、“法理冲突”以及“过度教条化”的困境。我们需要一种方法来追溯：**为什么我们要打破旧规矩？为什么我们要定下这个新规矩？**

## 2. 决策 (Decision)

我们决定采用 **架构决策记录 (Architecture Decision Records, ADR)** 机制。
所有针对项目全局架构、核心依赖、代码规范重大变更的决定，都必须以一个带有递增编号的 Markdown 文件记录在 `docs/adr` 目录下。

## 3. 后果 (Consequences)

- **好处**:
  - 所有重大决策有案可稽，新加入的开发者（或 AI）能读懂重构背后的 Trade-off。
  - 避免“暗箱操作”式的规范修改。
- **坏处**:
  - 修改架构规范的流程变长，需要提 ADR -> 审查 -> 才能去改宪法。
