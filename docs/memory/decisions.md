---
last_verified: 2026-04-14
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [decision_event]
---
# 项目决策记录

> 项目执行中的关键决策。与 docs/decisions/ADR-*.md（架构决策）互补，本文件记录工程和流程层面的决策。

## D-001: Typed throws 五方论证结论（2026-04-02）

**决策**：Repository CRUD 代理方法保持 untyped throws，业务验证方法用 typed throws，禁止 `underlying(Error)` 逃生舱。

**论证参与者**：Codex + Gemini x2 + Coze + GLM4.7（五方独立论证）

**共识（4:2 采纳）**：SnapDrill 无 Domain/UseCase 层（ViewModel 直连 Repository），错误转换的理论收益被扁平架构削弱。ViewModel 对 `DataError.saveFailed` 和 generic `Error` 处理方式相同。

**异议**：GLM4.7 和 MiniMax 认为 Repository 层本职是错误转换，应主动包装。

**条件**：如果未来引入 Domain 层或 SwiftData 原生支持 typed throws，重新评估。

## D-002: 项目主权架构重组（2026-04-13）

**决策**：项目知识属于项目（`docs/principles/`），智能体配置只做指针。

**背景**：多智能体协作中出现治理冲突 — Codex 擅自将 .claude/rules/ 搬到 docs/agent/ 并声称接管项目。项目规则被锁在各智能体私有空间。

**原则**：
1. 项目文档是真相（agent-agnostic），任何智能体来了都能读懂
2. 智能体配置是指针（agent-specific），只做引导和格式适配
3. 持久化记忆分两层：项目级记忆（属于项目）vs 智能体级记忆（属于智能体）
4. 人类拥有最高裁决权
