---
last_verified: 2026-05-26
layer: pattern
scope: audit
derived_from: [M-000 §11.10, M-005 §G]
freshness:
  max_age_days: 90
  decay_trigger: [standards_refactor, derived_from_check_implemented]
---
# Goal H7 — docs/standards/ 内容级 Traceability Audit（2026-05-26）

> Goal H 健康度收敛 sprint 第 7 项。**揭出 40% 漂移率**——印证帅哥 concern「字段层 audit 看不出，内容层才暴露」。

## 1. 背景与触发

主笔 Claude Opus 4.7 在元规则搭建期完结后做 Goal H1-H8 收敛，帅哥提问：「除产品文档外的第一方文档系统性重构是否完成？是否已不存在过时信息？是否全链条可追溯？」

字段层 `docaudit frontmatter` clean（90% 文档有 derived_from 字段），但**字段不等于内容真派生**。已知反例锚：
- `feedback_numeric_alignment_blindspot` 4 次复发（M-002 v1 §10.1「7 字段」漏第 7 项 / M-006 v1 §12 幻觉式合规等）

5 份 M-XXX sample audit 全 PASS，但 standards 30 份未查。本次 H7 audit 由 Explore agent 执行，逐文件 grep + Read 上位章节做内容级核对。

## 2. 总览

| 项 | 数 | % |
|---|---|---|
| 总样本 | 30 | 100% |
| ✅ 完整一致 | 12 | 40% |
| ⚠️ 标注不精（应补来源） | 8 | 27% |
| 🔴 严重漂移（标注错误） | 4 | 13% |
| ⏸️ 需读上位文档确认 | 6 | 20% |

**严重漂移率：13.3%（4/30）**
**含标注不精：40%（12/30）需要改进**

## 3. 🔴 严重漂移清单（P0 立即修复）

### 3.1 shared-constraints.md

- **当前**：`derived_from: [M-005 §G]`
- **问题**：M-005 §G 是「审计 check 设计」，与 7 条约束汇总（产品定位 / 工程哲学 / 编码铁律 / 数据安全 / 开发纪律 / 优先级 / 技术栈）**完全无关**
- **建议**：`derived_from: [M-005 §A, M-000 §2]`（产出度量 + PRIMARY 内核）
- **修复影响**：高——shared-constraints 是多个 delegation skill 的引用源（codex-delegation / gemini-delegation 都读它），derived_from 错会污染下游裁决链

### 3.2 permission-model.md

- **当前**：`derived_from: [M-001]`
- **问题**：M-001 是「协作工作流」，与 Tool 分级 / Bash 拦截 / Hook 生命周期 / 治理 Skill 权限矩阵**无关**
- **建议**：`derived_from: [M-006 §6.4]`（CLI 调用规约 + 治理基础设施）或新建专题
- **修复影响**：高——permission-model 是 11 个 hook 的策略源，错标 derived_from 会让审计追溯到错误的上位

### 3.3 audit-rubric.md

- **当前**：`derived_from: [M-005 §G]`
- **问题**：M-005 §G 是「check 设计 + 升级路径」，audit-rubric 是「verdict 分类定义（VALID/STALE/NEEDS_REVISION/VALID_WITH_GAP）」+ 证据类型 + 置信度。重叠但焦点不同
- **建议**：`derived_from: [M-005 §G, M-002, verdict-framework]`（双向引用 + 显式 verdict 来源）
- **修复影响**：中——audit-rubric 是审计纪律 SSOT，标注精化能提高未来审计的引用准确性

### 3.4 harness-recall.md

- **当前**：`derived_from: [M-005 §G]`
- **问题**：M-005 §G 是「check 设计」，harness-recall 是「harness 自进化闭环 + 反模式扫描规则」
- **建议**：`derived_from: [M-005 §C, M-001 §8.4]`（静默退化识别 + 单方执行窗口违反信号）
- **修复影响**：中——harness-recall 标错来源会让自进化机制的派生关系模糊

## 4. 🟡 标注不精清单（P1 次周修复）

| 文件 | 当前 | 建议 | 原因 |
|---|---|---|---|
| codex-delegation.md | [M-001] | + [shared-constraints, M-005 §A] | 必读 shared-constraints 应显式 |
| gemini-delegation.md | [M-001] | + [shared-constraints] | 与 codex-delegation 对称 |
| ai-toolchain-specs.md | [M-001] | [tool-snapshot, ai-toolchain-versions] | M-001 不覆盖工具版本快照 |
| gemini-cli-reference.md | [M-001] | [tool-snapshot, gemini-cli-integration] | CLI 认证配额属工具快照 |
| deepseek-delegation.md | [M-001] | [tool-snapshot, deepseek-v4-integration] | 工具链配置快照 |
| ci-infrastructure.md | [M-005 §A] | [infrastructure-snapshot, ci-runner-diagnostics] | Mac mini 诊断与产出度量无关 |
| snapshot-testing-environment.md | [M-005 §A] | [testing.md, tool-config-snapshot] | env var 快照属工具配置 |
| claude-cooperation-behavior.md | [M-001] | [tool-snapshot] | Opus 行为是工具版本快照 |

**共同问题**：M-000 §11.10 schema 严格要求 `derived_from` 元素只能是 `M-NNN` / `M-NNN §N` / `user-decision-log #NNN`——**没有「tool-snapshot」「shared-constraint-source」这类 cross-standards 派生类型**。这是 schema 表达力不足，可能需要 M-000 §11.10 v2.2 升级新增 「同级派生」概念。

## 5. ✅ 完整一致清单（12 份，无需动作）

| 文件 | derived_from | 验证 |
|---|---|---|
| coding.md | [M-005 §A] | 编码规范是产出度量落地 |
| testing.md | [M-005 §A] | 测试分层是质量判据落地 |
| engineering.md | [M-005 §A] | 工程原则关联 PRIMARY 内核 |
| execution-gates.md | [M-005 §G] | 门禁 SSOT 是 check 设计落地 |
| collaboration.md | [M-001] | 协作哲学派生工作流 |
| dependency-propagation.md | [M-005 §J] | 字数下沉证明 |
| swift-coding.md | [M-005 §A] | skill adapter，质量保留原则 |
| swiftui-patterns.md | [M-005 §A] | UI patterns 关联 Apple 原生原则 |
| ux-design.md | [M-005 §A] | UX 原则关联产品愿景 |
| apple-native.md | [M-005 §A] | 原生优先原则 |
| privacy-manifests.md | [M-005 §A] | skill adapter |
| app-icon-design.md | [M-005 §A] | skill adapter |
| worktree-audit-workflow.md | [M-001] | 物理隔离工作流，关联 §5 |

## 6. ⏸️ 需读上位文档确认（6 份）

ci-cd.md（M-004）/ skill-architecture.md（M-003）/ skill-source-ledger.md（M-003）/ memory-routing.md（M-001 §6.3）/ harness-recall.md 验证 / README.md（M-000）

## 7. 元层级注记

### 7.1 帅哥 concern 已实证

帅哥 2026-05-26 提问「内容是否漂移，不能盲信头部日期」—— 本 audit 数据**确认 concern 真实**：
- 字段层 docaudit clean 100%（90% 文档有 derived_from）
- 内容层 H7 audit 揭出 40% 标注问题（13% 严重 + 27% 不精）
- 主笔起草 standards 时**未真正 grep 上位文档**，按印象标 derived_from

### 7.2 与 feedback_numeric_alignment_blindspot 同构

数字凑数巧合（「7 字段」漏第 8 项）的失败模式 = derived_from 标注漂移的失败模式（「标 M-005 §G」实际指 §A）：
- 都是主笔自评不可靠
- 都是字段层 audit 看不出
- 都是异源 grep 才能暴露
- 都需要「机制化 grep 强制」（feedback 升级版第 7 条 + Goal B PreEdit hook + 本次 H7 audit）

### 7.3 schema 表达力问题

M-000 §11.10 v2.1 schema 仅允许 `derived_from: [M-NNN / M-NNN §N / user-decision-log #NNN]`，**不允许同级 standards-to-standards 派生**（如 shared-constraints 实际是多个 standards + product docs 的汇总，无法用现 schema 表达）。建议 M-000 §11.10 v2.2 升级新增「同级派生」类型，或允许 `derived_from: [standards/shared-constraints.md]` 文件路径形式。

## 8. 修复路径建议

### Option A：本会话立即修 P0 4 份
- 工作量：30-60 分钟
- 风险：P0 都涉及 derived_from 重新分析，可能需 M-006 / governance 上位文档确认
- 优势：解除最高优先级污染

### Option B：本会话修 P0 + 启动 P1 修复 PR
- 工作量：1.5-2 小时
- 风险：P1 中 7 份工具快照类需 schema gap 处理（M-000 §11.10 v2.2 升级或临时 workaround）
- 优势：standards 标注体系一次性收敛

### Option C：本会话不修 standards，先做 H7 剩余（templates 9 / ADR 6 / tech 6 / audits 32）
- 工作量：3-4 小时（agy + Codex + DeepSeek 并行）
- 风险：扩大已知问题面但未修复
- 优势：先掌握完整漂移图谱再批量修

### Option D：把 H7 audit 报告本身作为 Goal H 阶段性交付，留下次 session 修
- 工作量：本 session 仅 commit audit 报告
- 优势：留充分时间设计 schema 升级 + 多源协调

## 9. 综合建议

**推荐 Option A + 同步启动 Option C**：本会话修 4 份 P0（不阻塞），并发启动 templates/ADR/tech audit。等帅哥裁决。

---

*主笔: Claude Opus 4.7 (1M context) | 2026-05-26*
*执行: Explore agent (a575356c0f8c1283c) | 132 秒 / 74K tokens*
*总样本: 30 份 | 严重漂移: 4 (13.3%) | 含标注不精: 12 (40%)*
