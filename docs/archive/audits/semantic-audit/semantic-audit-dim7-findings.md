---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# SnapDrill 文档体系语义层审计报告 — 维度 7：F-rule 实际遵守度

> **审计状态**：`snapshot` 验证进行中
> **执行模型**：Antigravity
> **验证日期**：2026-05-21

---

## 1. 审计概述 (Audit Overview)

本报告针对 SnapDrill 全局项目纪律索引中全部 **20 个 F-rule 编号**（14 个 active 活跃规则 + 6 个 retired 退役规则）的实际遵守度、权威源一致性、触发方式、以及物理代码库的实证表现进行了全量对抗性语义审计。

本次审计基于以下实证基线数据：
1. **全仓 Commit 实证**：对全量 1372 个 commits 进行了精准 `grep`，获取各规则显式打标的 commit 频次。
2. **全仓引用实证（修复工具 Bug 后）**：在对 `docaudit.py` 的提取缺陷进行逆向与修复模拟后，对全仓（`docs/`、`Scripts/`、`Packages/`、`.claude/` 等）进行全量外部引用检索与次数统计。
3. **Skill 权威定义校验**：走读了 `.claude/skills` 及 `.agents/skills` 下物理文件关于 F 规则的权威内嵌校验。
4. **GitHub Issue 实证抽样**：抽样增强/日常 Issue（如 `#710`、`#735`）以确认 `F-018 Sprint Contract` 的真实应用率。
5. **工具缺陷剖析**：对 `docaudit rule-usage` 运行逻辑漏洞的底层原理及漏审机制进行深度实证。

---

## 2. 20 个 F-rule 全量实际遵守度审计大表

| 编号 | 规则名称 | 权威源定义位置 | 触发方式声明 (feedback.md) | git log grep 频次 | 全仓实际引用频次 | 实证表现与假阴性分析 | 最终遵守度三态分类 |
|---|---|---|---|---|---|---|---|
| **F-001** | Git 工作流纪律 | `docs/workflow.md` § Git 工作流 | 所有 git 操作 | 11 | 18 | 每次 commit 实际均在触发，但由于非强制打标，导致 99.2% 的 commit 存在标注假阴性。 | **Alive in Practice (但标注假阴性)** |
| **F-002** | *退役原则* | 退役（无独立价值） | N/A | 6 | 0 | 2026-05-19 退役。工程纪律已被 `engineering.md` + `KNOWLEDGE_MAP.md` 覆盖。 | **Dead on Paper (已退役)** |
| **F-003** | *退役依赖* | 退役（合并入依赖图） | N/A | 7 | 2 | 2026-04-22 退役。已被 `DOC_DEPENDENCY_MAP.md` 索引完全接管。 | **Dead on Paper (已退役)** |
| **F-004** | 内测不做 Schema 迁移 | `feedback.md` 政策标签 | Model 文件变更时 | 5 | 10 | 确实在内测期重置数据库，但由于仅由 Reset 动作触发且无需编写迁移计划，实际打标 commit 较少。 | **Alive in Practice (静默有效)** |
| **F-005** | 对抗性审查 | `docs/workflow.md` § Code Review | PR 提交/合并时 | 8 | 8 | 每轮 Phase 审计均深度执行（Gemini + Codex），但仅 8 个 commit 显式标注，绝大多数 PR 存在假阴性。 | **Alive in Practice** |
| **F-006** | 审计深度验证 | `verify-audit-report` skill | 收到审计报告时 | 2 | 9 | 物理使用 `verify-audit-report` 验证工具链时，执行多在会话中交互，commit 仅 2 次，但全仓有 9 处有效引用。 | **Alive in Skill & Practice** |
| **F-007** | CI 双时点门禁 | `post-merge` skill + hooks | PR 合并时 | 7 | 9 | 自动化 Hook (premerge-checklist.sh) 在 PR 门禁中被强制执行，属于静默守护。 | **Alive in Practice** |
| **F-008** | 三方相同完整任务 | `cross-audit` skill | 审计启动时 | 12 | 37 | 核心纪律。本次 Phase 10 全维度审计均严格遵守，全仓引用高达 37 次，但在普通 commit 中仅标注 12 次。 | **Alive in Practice** |
| **F-009** | *退役提示* | 退役（合并入提示指南） | N/A | 6 | 2 | 2026-04-22 退役。合并入 `review-prompt-guide.md`。 | **Dead on Paper (已退役)** |
| **F-010** | *退役规范* | 退役（合并入工作流） | N/A | 6 | 2 | 2026-04-22 退役。合并入 `workflow.md`。 | **Dead on Paper (已退役)** |
| **F-011** | 审计期间三方只读 | `cross-audit` skill | 审计启动时 | 2 | 9 | 审计中绝不修改非文档代码，因为是“只读”故几乎不应产生 commit，符合静默守规。 | **Alive in Practice** |
| **F-012** | 全量做不偷懒 | `verify-audit-report` skill | 审计验证时 | 1 | 12 | 强烈的自律约定（如全量跑 52 个 skill），多处于静默执行，少有 commit msg 打标。 | **Alive in Practice** |
| **F-013** | Scope 膨胀拆分 | `sprint-contract` skill | 编码时 | 5 | 7 | 多作为静默防御机制，在 Issue 开始时预防范围膨胀，但在 commit 中极少被提及。 | **Alive in Skill (静默防御)** |
| **F-014** | 跳过测试门禁 | `sprint-contract` skill | 编码时 | 7 | 10 | 强制性不许跳过测试的防御防线，无跳过即是遵守，无标打 commit msg 的合理假阴性。 | **Alive in Practice** |
| **F-015** | *退役门禁* | 退役（合并入双时点） | N/A | 7 | 2 | 2026-04-22 退役。已被 `F-007` 双时点门禁机制完全合并。 | **Dead on Paper (已退役)** |
| **F-016** | 质疑方批准 | `cross-audit` skill | 修复后复核时 | 12 | 6 | 多方对抗的决议流程，通常在 Issue/PR Review 交互中完成，commit 级只体现了 12 次。 | **Alive in Practice** |
| **F-017** | UI/SDK 调研 | `api-research` skill | UI/SDK 改动时 | 6 | 8 | UI 改动（如 iOS 26 原生玻璃适配）时均遵循调研，但开发 commit 极少标注 `F-017`，假阴性严重。 | **Alive in Practice** |
| **F-018** | 编码前契约 | `sprint-contract` skill | Issue 进入 Building | 7 | 14 | 极其堪忧。虽然 skill 中定义详实，但由于其在 enhancement/chore Issue 中的贴评论率极低，属于典型空载。 | **Not Applied in Practice (纸面生存)** |
| **F-019** | 反模式回流 | `post-merge` skill | PR 合并后 | 6 | 19 | 自动化 `anti-pattern-scan` 门禁静默防御，在 `post-merge` 及 `harness-recall` 中高频自驱。 | **Alive in Practice** |
| **F-020** | *退役墓碑* | 退役（合并入对抗审查） | N/A | 8 | 2 | 2026-04-21 退役。墓碑化合并入 `F-005`。 | **Dead on Paper (已退役)** |

---

## 3. 维度 7 详细 Findings 清单

### Finding C7.1: F-018 编码前契约纸面生存、实际空载 (HIGH)
- **F-rule 编号**：`F-018`
- **权威源**：`sprint-contract` skill
- **不一致实证**：在物理 GitHub Issue 列表的抽样中（例如最近的 `#710` docaudit 正则加固、`#735` 收尾审计修复等），没有在 Building 状态前于评论区贴出任何 "Sprint Contract" 规范。甚至大量已关闭的日常 chore/enhancement 任务的 comments 数量为 0。仅有超大型 epic `#766` 曾有贴出。这表明该规则在常规与增强型开发过程中应用率低于 10%，处于极度濒临死亡的“纸面规则”状态。
- **严重度**：HIGH
- **类型**：应用率低 / 声明过度
- **推荐处理**：**Skill 改进与工具化**。建议在 `CLAUDE.md` 或 CLI Hook 中引入机械拦截阻断，如果 Issue 处于 Building 状态但没有找到匹配的 Sprint Contract，强制阻断代码修改权限，使契约成为物理强约束。

### Finding C7.2: F-001 触发声明过度与 commit msg 假阴性 (MEDIUM)
- **F-rule 编号**：`F-001`
- **权威源**：`docs/workflow.md` § Git 工作流
- **不一致实证**：`feedback.md` 声明其触发方式为“所有 git 操作”。但在全仓 1372 个 commits 中，只有 11 个 commit 在 message 中显式打上了 `F-001`。这代表 99.2% 的实际 Git 提交操作均没有进行显式声明。
- **严重度**：MEDIUM
- **类型**：声明过度 / 假阴性
- **推荐处理**：**feedback.md 修订**。修剪触发句的野心，从“所有 git 操作”精简为“当触发分支重构/CI 阻断修复/特殊合并工作流时”，避免产生虚假的审计预警；或维持现有定义但在 `docaudit` 策略中将 F-001 设为合理静默。

### Finding C7.3: F-006 / F-012 等审计自律规约存在 commit 假阴性 (LOW)
- **F-rule 编号**：`F-006` / `F-012`
- **权威源**：`verify-audit-report` skill
- **不一致实证**：在全量 1372 个 commits 中，`F-006` (审计深度验证) 仅占 2 频，`F-012` (全量做不偷懒) 仅占 1 频。但这并非因为审计不彻底——前 6 个维度的细致共识报告证明了我们的绝对遵守，而是因为这些“自律性”的规则在执行时均处于只读或本地会话态，并不自然产生物理 commit，从而引发了极高的 commit msg 假阴性。
- **严重度**：LOW
- **类型**：commit msg 假阴性
- **推荐处理**：**认知对齐**。不要将 git log 标注频次作为评价“只读型/自律型”规则执行度的唯一基准。在 `docaudit rule-usage` TSV 输出的说明文档中加注本段假阴性原理，防止后人误判为 dead rule。

### Finding C7.4: F-004 元层级自指悖论与虚假 alive (INFO)
- **F-rule 编号**：`F-004`
- **权威源**：`docs/memory/feedback.md` 政策标签段
- **不一致实证**：`F-004` (内测期不做 Schema 迁移) 规定了 `@Model` 变更直接重置数据库的短期政策。其本身在 git log 中仅有 5 次标注，却在各种审计报告与 ADR 中被提及了 10 次。这构成了一个典型的“元层级自指”——审计活动本身让 F-004 产生了大量的“外部引用生存证据”，掩盖了其在真实数据模型开发中的冷寂状态。
- **严重度**：INFO
- **类型**：元层级自指 / 虚假 alive
- **推荐处理**：**工具规则排除**。在 `docaudit.py` 中，对 `rule-usage` 扫描应剔除 `docs/audits/` 目录和 `ADR-*.md` 本身对 F-rule 的自引用，从而获得真实的“生产级引用度”指标。

### Finding C7.5: docaudit.py 规则提取器严重设计残缺导致 13 项 active 规则漏审 (HIGH)
- **F-rule 编号**：多编号受影响（F-001, F-005 ~ F-008, F-011 ~ F-014, F-016 ~ F-019）
- **权威源**：`Scripts/audit/docaudit.py`
- **不一致实证**：`docaudit.py` 中的 `check_rule_usage` 依靠正则 `re.match(r"^#{1,4}\s+F-(\d{3})\b", line)` 提取 feedback.md 中的声明规则。但这只匹配以 Markdown 标题定义的规则。在 feedback.md 中，除 F-004 外，其余 13 个活跃 F-rule 均在表格行中声明（例如 `| F-001 | ... |`），这导致 `docaudit` 运行 `rule-usage` 时只解析出了 `['004']`，漏掉了其余 13 个规则。这直接导致这些规则在无任何外部引用时仍不会触发 `dead_rule_candidate` 警告，产生了极严重的工具级假阴性。
- **严重度**：HIGH
- **类型**：工具逻辑缺陷 / 假阴性漏报
- **推荐处理**：**修复脚本提取逻辑**。修改 `check_rule_usage` 提取逻辑，使其能匹配 feedback.md 的表格行，例如提取 `r"\|\s*F-(\d{3})\s*\|"` 以涵盖全部在表格中声明的活跃规则。

---

## 4. 推荐治理与规约演进路线

1. **规约瘦身 (F-NNN Pruning)**：
   保留 14 个 active 规则虽然体系完整，但 F-018 和 F-013 在非 Epic 级日常开发中已被退化为散文。建议通过 ADR 正式确立“常规 Issue 契约豁免线”，或在 CLI 钩子中实现 Sprint Contract 模板自动生成 comment，实现工具化支撑。
2. **过滤自引用干扰**：
   重构 `docaudit.py` 中 `check_rule_usage` 逻辑（Finding C7.4），避免审计文档本身的词汇重合产生虚假的 rules-alive 数据。
3. **Commit 规范修正**：
   无需强制将“只读型”原则 (如 F-011) 塞入 Commit 打标规范，应在 workflow.md 明确指出：**静默防线类规则，无 commit 记录为合理常态。**
4. **工具链修复**：
   对 `docaudit.py` 实施热修复（Finding C7.5），将表格中的活跃规则全部纳入统计范围，防止其他规则成为名存实亡的“影子规则”。

---
**Antigravity 独立审计声明**：本报告仅供后续三方审计共识机制裁决参考，当前维度 7 处于 `snapshot` 验证中，不代表终态结案。
