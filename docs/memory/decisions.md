---
last_verified: 2026-04-19
layer: pattern
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

## D-003: 抽出 agent-harness 独立仓库（2026-04-22）

**决策**：把自主迭代系统（docaudit / hooks / skills / 文档契约 / 反哺协议）抽到独立仓库 [NotBad-Labs/agent-harness](https://github.com/NotBad-Labs/agent-harness)。snapdrill-ios 既是孵化器（提供实战经验），又是消费者（通过 `.agent-harness/` 接入）。

**战略锚（用户 2026-04-22 拍板）**：
1. 自主迭代系统应**普遍通用**，能被不同项目复用，随项目演进
2. 定位为**any-agent harness**（不自限 Claude Code），但当前实现聚焦 Claude Code + Codex + Gemini
3. 独立仓库 + 直接开空仓 + 双仓并行推进

**三方 cross-audit consensus 共识（Claude / Codex / Gemini）**：
- 独立仓库优于单仓分层（3/3 ✅）
- 形态：CLI 工具 + 模板仓库（2/3 ✅，Codex + Gemini 一致）
- B 档务实骨架（3/3 ✅）
- Phase D 非破坏性消费试点（2/3 ✅，Claude 初提的"删 snapdrill 本地副本"被 override）
- 反哺硬门槛：Codex **two-consumer rule** + Gemini **3 迭代周期** + Claude **去项目化 grep**

**Phase D 落地（2026-04-22 一天全收官）**：
- PR-D1（agent-harness #1）：骨架建仓 + 3 原则契约 + 4 层分层契约
- PR-D2（agent-harness #2）：docaudit 引擎迁入 + 完全参数化（34 tests）
- PR-D3（agent-harness #3）：CLI init / doctor / sync --check（21 tests）
- PR-D4（agent-harness #4）：adapter-claude hooks + skills + settings + policy.starter
- **PR-D5（本 PR）**：snapdrill-ios 消费试点（`.agent-harness/project.yaml` + lock.json）

**异议处理**：
- Claude 原主张"Claude Code 原生 meta-dev-loop"定位被用户 override 为"any-agent"
- Claude 原主张 submodule + symlink 方案被 Codex + Gemini 的 CLI 工具方案 override

**下一步**：Phase E 反哺机制（extract-candidate CLI + harness-introspection skill + 首次反哺实战）

**完整 consensus 归档**：`~/.claude/plans/phase-de-consensus-20260422.md`（Claude 私有记忆）
