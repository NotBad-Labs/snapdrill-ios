---
layer: contract
scope: skill-audit-final
last_verified: 2026-05-25
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: |
  本文是路径 C Stage 4 最终审计报告，核心任务为解外链式 MERGE + 产出最终合并目标图。密度证明：
  (1) 52 项 Verdict 必须完整列出（含 #017 裁决 + 7 项共识），缺任一项会导致 Stage 5 批量执行不一致；
  (2) 13 个外链式 MERGE 必须逐个解出合并目标，不能抽样或归类；
  (3) 链式 MERGE（如 snapshot-diff-review → snapshot-testing → tdd-feature）必须在合并目标图显式解析；
  (4) §5 Stage 6 元规则反思预测点基于路径 C 实证，是 M-003 起草的核心输入，不可省略；
  (5) §6 M-003 起草输入需汇总路径 C 全量实证，不能压缩。
  全文无装饰性段落，每个 Verdict 的最终目标均可回溯至 #017 裁决或 Claude 折叠表共识。
---

# Skill 生态审计最终报告

## §1 执行摘要

4 家异源审计（Claude / Codex / DeepSeek / Gemini）产 87% 分歧率（52 项中仅 7 项 3+/4 共识）。Stage 3.5 用户裁决 #017 逐条裁决 45 项分歧，最终方向：**82% skill 改变形态**。

**52 → 10 个 active skill**（净减 81%，§4.7 精确统计）+ 5-6 个 standards + 9 个 templates + 31 个归档。按 Verdict 分类：

| Verdict | 数量 | 占比 | 说明 |
|---|---|---|---|
| **KEEP** | 7 | 13% | 保留 skill 形态，含共识 4 项 + 帅哥裁决 3 项 |
| **MERGE** | 24 | 46% | 合并到容器 skill / standards / templates，13 个外链式已解 |
| **DELETE** | 7 | 13% | 冗余 / 过时 / 无工程价值 |
| **PROMOTE_TO_STANDARDS** | 5 | 10% | 内容升为静态规范，删除 skill |
| **DOWNGRADE_TO_TEMPLATE** | 7 | 13% | 剥离 trigger 改静态模板，删除 skill |
| **REWRITE** | 2 | 4% | 重写内容，保留 skill 形态 |

**13 个外链式 MERGE 最终容器清单**（详见 §3）：
- `app-description-writer`（App Store 主容器）
- `swiftui-pro`（SwiftUI 主容器）
- `swiftui-patterns`（模式容器，新）
- `tdd-feature`（TDD 主容器）
- `ci-cd-setup`（CI/CD / 监控容器）
- `coding-best-practices`（工程规范容器）
- `dependency-propagation`（传播链容器）
- `onboarding-generator`（功能模板容器）
- `privacy-manifests`（隐私/数据容器）
- `docs/templates/` 下独立模板 2 个（localization-setup / knowledge-health-workflow）
- `docs/standards/` 下独立规范 2 个（migration-patterns / navigation-patterns → swiftui-patterns）

---

## §2 完整 52 项 Verdict 表

### §2.1 7 项共识 Verdict（直接落地）

| # | skill | Verdict | 共识方 | 执行动作 |
|---|---|---|---|---|
| 1 | coding-best-practices | **PROMOTE_TO_STANDARDS** | 3/4 | 移 `docs/standards/swift-coding.md`，删 skill |
| 2 | dod-checklist | **KEEP** | 3/4 | 保留，Stage 5 无动作 |
| 3 | onboarding-generator | **DOWNGRADE_TO_TEMPLATE** | 3/4 | 移 `docs/templates/onboarding/`，删 skill |
| 4 | phase-closeout | **KEEP** | 3/4 | 保留，Stage 5 无动作 |
| 5 | swiftui-pro | **KEEP** | 3/4 | 保留，吸纳 swiftui-debugging 合并内容 |
| 6 | ui-review | **MERGE** | 3/4 | 合并到 SwiftUI 容器（§3 解） |
| 7 | verify-audit-report | **KEEP** | 3/4 | 保留，Stage 5 无动作 |

### §2.2 10 个已明确合并目标的 MERGE（#017 已有；含链式 1 个）

| # | skill | Verdict | 合并目标 | 说明 |
|---|---|---|---|---|
| 8 | tdd-bug-fix | MERGE | tdd-feature | 同 TDD 工作流不同入口 |
| 9 | tdd-refactor-guard | MERGE | tdd-feature | 重构前置 safety check |
| 10 | swiftui-debugging | MERGE | swiftui-pro | 性能调试纳入 SwiftUI 容器 |
| 11 | snapshot-diff-review | MERGE | snapshot-testing → tdd-feature（链式 §3.2 解析） | 同一视觉回归体系 |
| 12 | app-store-rejection | MERGE | app-description-writer | App Store 提交容器 |
| 13 | keyword-optimizer | MERGE | app-description-writer | ASO 并入 App Store 容器 |
| 14 | tipkit-generator | MERGE | onboarding-generator | 功能引导同类 |
| 15 | data-export | MERGE | privacy-manifests | 数据导出→隐私/数据容器 |
| 16 | knowledge-health | MERGE | docs/templates/knowledge-health-workflow.md | 降格为工作流模板 |
| 17 | decision-closeout | MERGE | M-002（暂保留） | 等 M-002 ratify 后转 |

注：xcode-review = KEEP（#017 帅哥裁决独立保留），归类到 §2.8 KEEP 列表，**不在本 MERGE 表中**。本表共 10 项 MERGE（不是 13；外链式 13 见 §2.3，共识 1 个 ui-review MERGE 见 §2.1，总 MERGE = 10+13+1 = 24，与 §1 一致）。

### §2.3 13 个外链式 MERGE（本报告解）

| # | skill | 最终合并目标 | 合并容器 | 决议来源 |
|---|---|---|---|---|
| 19 | accessibility-generator | **swiftui-pro**（ui-review → swiftui-pro） | SwiftUI 主容器 | #017 ui-review → ? 链解：ui-review 内容（HIG / a11y / 字体）内含 accessiblity 审查，与 accessibility-generator 高度重叠，二者均不应自成 skill→合并入 swiftui-pro 的设计/accessibility 章节 |
| 20 | animation-patterns | **swiftui-patterns**（新容器，吸纳 migration-patterns + navigation-patterns） | 模式容器 | #017 *-patterns 批量方向（3/4 家倾向 PROMOTE/MERGE），解为：合并 animation/migration/navigation 三个 patterns 为独立 swiftui-patterns standards 文件，不入 swiftui-pro（避免过重） |
| 21 | api-research | **`docs/standards/dependency-propagation.md`**（dependency-propagation 已 PROMOTE→standards，作为 external-fact research 章节） | 传播链 standards | #017 api-research → ? 解：api-research 的 F-017 执行器职责（API 变更后研究）与 dependency-propagation 的文档传播职责（变更后同步下游）同属「变更传播」链。注意 dependency-propagation 已 PROMOTE→standards，api-research 实际合并到 standards 文件而非 skill |
| 22 | app-description-writer | **app-description-writer**（App Store 主容器，吸纳 app-store-rejection + keyword-optimizer + app-store-assets） | App Store 主容器 | #017 明确"App Store 主容器"方向。吸纳 app-store-rejection（审核应对）、keyword-optimizer（ASO）、app-store-assets（资产规范） |
| 23 | app-store-assets | **app-description-writer**（App Store 主容器） | 同上 | 资产规范内容可纳入 App Store 主容器的「素材章节」 |
| 24 | characterization-test-generator | **tdd-feature**（与 tdd-refactor-guard 同目标） | TDD 主容器 | #017 characterization-test-generator → ? 解：其 refactoring 前置 safety net 职责与 tdd-refactor-guard 完全重叠（Codex 和 Gemini 均识别），后者已裁决→tdd-feature，二者合并到同一目标 |
| 25 | error-monitoring | **`docs/standards/ci-cd.md`**（ci-cd-setup 已 PROMOTE→standards，作为监控章节） | CI/CD / 监控 standards | #017 error-monitoring → ? 解：error-monitoring 的核心（provider 模板 + 初始化）与 ci-cd-setup 的 CI 配置同属「工程基础设施」范畴。注意 ci-cd-setup 已 PROMOTE→standards，error-monitoring 实际合并到 standards 文件而非 skill |
| 26 | integration-test-scaffold | **tdd-feature**（已确认方向） | TDD 主容器 | #017 已确认 integration-test-scaffold → tdd-feature |
| 27 | localization-setup | **docs/templates/localization-workflow.md**（独立模板） | 独立模板 | #017 localization-setup → ? 解：localization 模板量（xcstrings / RTL / 项目结构检测）足够独立，不宜并入任一容器；保留为独立 template 供按需引用 |
| 28 | migration-patterns | **swiftui-patterns**（合并 *-patterns 容器） | 模式容器 | #017 已确认方向：合并 *-patterns 为 swiftui-patterns |
| 29 | navigation-patterns | **swiftui-patterns**（合并 *-patterns 容器） | 模式容器 | #017 已确认方向：合并 *-patterns 为 swiftui-patterns |
| 30 | snapshot-testing | **tdd-feature**（视觉回归测试并入 TDD 主容器） | TDD 主容器 | #017 snapshot-testing → ? 解：snapshot-testing 的设置 + 审查（snapshot-diff-review 已先合并到其本身）→ 整个 snapshot 体系最终归入 tdd-feature 的「视觉回归测试」章节 |
| 31 | test-contract | **`docs/standards/swift-coding.md`**（coding-best-practices 已 PROMOTE→standards，作为测试契约章节） | 工程规范 standards | #017 test-contract → ? 解：test-contract 的协议设计 + mock 规范属于「编码最佳实践」范畴，与 coding-best-practices 的 swift-patterns / architecture-patterns 同类。注意 coding-best-practices 已 PROMOTE→standards，test-contract 实际合并到 standards 文件而非 skill |

### §2.4 7 个 DELETE

| # | skill | 理由 |
|---|---|---|
| 32 | harness-recall | 与 knowledge-health 重叠，knowledge-health 已 MERGE 到模板 |
| 33 | attributed-string | adapter 无独立内容，SSOT 在 .agents 非本次范围 |
| 34 | liquid-glass | adapter 无独立内容，SSOT 在 .agents 非本次范围 |
| 35 | background-processing | 模板可替代，无 LLM 动态判断必要 |
| 36 | push-notifications | adapter 无独立内容，SSOT 在 .agents 非本次范围 |
| 37 | settings-screen | 模板可替代，无 LLM 动态判断必要 |
| 38 | review-response-writer | 非工程核心技能，低频 |

### §2.5 5 个 PROMOTE_TO_STANDARDS

| # | skill | 升级目标 |
|---|---|---|
| 39 | app-icon-generator | `docs/standards/app-icon-design.md` |
| 40 | ci-cd-setup | `docs/standards/ci-cd.md`（吸纳 error-monitoring） |
| 41 | dependency-propagation | `docs/standards/dependency-propagation.md`（吸纳 api-research） |
| 42 | privacy-manifests | `docs/standards/privacy-manifests.md`（吸纳 data-export） |
| 43 | coding-best-practices（共识） | `docs/standards/swift-coding.md`（吸纳 test-contract） |

### §2.6 7 个 DOWNGRADE_TO_TEMPLATE

| # | skill | 模板目标 |
|---|---|---|
| 44 | onboarding-generator（共识） | `docs/templates/onboarding/`（吸纳 tipkit-generator） |
| 45 | cross-audit | `docs/templates/cross-audit-workflow.md` |
| 46 | cross-audit-consensus | `docs/templates/cross-audit-consensus.md` |
| 47 | post-merge | `docs/templates/post-merge-checklist.md` |
| 48 | resume-from-handoff | `docs/templates/session-resume.md` |
| 49 | sprint-contract | `docs/templates/sprint-contract.md` |
| 50 | deep-linking | `docs/templates/deep-linking/` |

### §2.7 2 个 REWRITE

| # | skill | 重写要点 |
|---|---|---|
| 51 | swift-concurrency-pro | 对齐 Swift 6.3 + iOS 26 并发模型；更新 references/hotspots.md |
| 52 | swiftdata-pro | 对齐 Swift 6.3 + iOS 26 SwiftData API；更新 references |

### §2.8 7 个 KEEP（无动作）

- dod-checklist
- phase-closeout
- swiftui-pro
- verify-audit-report
- xcode-review
- tdd-feature（作为 TDD 主容器，Stage 5 吸纳 4 个合并者后自身内容可能需小幅扩展）
- screenshot-planner

---

## §3 合并目标图（最终容器清单 + MERGE 链解析）

### §3.1 最终容器清单（~17 个 active）

| 容器 | 类型 | 所含 skill | 来源 |
|---|---|---|---|
| **tdd-feature** | KEEP（容器） | tdd-feature（原） + tdd-bug-fix + tdd-refactor-guard + integration-test-scaffold + snapshot-testing + snapshot-diff-review + characterization-test-generator | 合并 6 个 skill |
| **swiftui-pro** | KEEP（容器） | swiftui-pro（原） + swiftui-debugging + ui-review + accessibility-generator | 合并 3 个 skill |
| **swiftui-patterns** | NEW（standards） | animation-patterns + migration-patterns + navigation-patterns | 合并 3 个 skill → 新 standards |
| **app-description-writer** | MERGE（容器） | app-description-writer（原） + app-store-rejection + keyword-optimizer + app-store-assets | 合并 3 个 skill |
| **coding-best-practices** | PROMOTE→standards | coding-best-practices（原） + test-contract | 合并 1 个 skill |
| **ci-cd-setup** | PROMOTE→standards | ci-cd-setup（原） + error-monitoring | 合并 1 个 skill |
| **privacy-manifests** | PROMOTE→standards | privacy-manifests（原） + data-export | 合并 1 个 skill |
| **dependency-propagation** | PROMOTE→standards | dependency-propagation（原） + api-research | 合并 1 个 skill |
| **onboarding-generator** | DOWNGRADE→template | onboarding-generator（原） + tipkit-generator | 合并 1 个 skill |
| **docs/templates/localization-workflow.md** | NEW（template） | localization-setup | 独立模板 |
| **docs/templates/knowledge-health-workflow.md** | NEW（template） | knowledge-health | 独立模板 |
| **dod-checklist** | KEEP | dod-checklist | 无合并 |
| **phase-closeout** | KEEP | phase-closeout | 无合并 |
| **verify-audit-report** | KEEP | verify-audit-report | 无合并 |
| **xcode-review** | KEEP | xcode-review | 无合并 |
| **screenshot-planner** | KEEP | screenshot-planner | 无合并 |
| **swift-concurrency-pro** | REWRITE | swift-concurrency-pro | 无合并 |
| **swiftdata-pro** | REWRITE | swiftdata-pro | 无合并 |

### §3.2 MERGE 链解析

链式 MERGE 1：**snapshot-diff-review → snapshot-testing → tdd-feature**
- 第 1 跳：snapshot-diff-review（baseline 审查）→ snapshot-testing（测试设置）
- 第 2 跳：snapshot-testing → tdd-feature（TDD 主容器）
- 最终节点：tdd-feature

链式 MERGE 2：**ui-review → swiftui-pro**
- 第 1 跳：ui-review（HIG / a11y / 字体）→ swiftui-pro（SwiftUI 主容器）
- 子链：accessibility-generator → swiftui-pro（同目标）

链式 MERGE 3：**characterization-test-generator → tdd-feature**
- 第 1 跳：characterization-test-generator（重构前 safety net）→ tdd-feature
- 并行链：tdd-refactor-guard → tdd-feature（同目标）

链式 MERGE 4：**app-store-rejection + keyword-optimizer + app-store-assets → app-description-writer**
- 全部直接入 App Store 主容器

---

## §4 Stage 5 批量执行清单

### 4.1 DELETE → 归档（7 个）

```bash
mkdir -p docs/archive/skills/2026-05-25
mv .claude/skills/harness-recall docs/archive/skills/2026-05-25/
mv .claude/skills/attributed-string docs/archive/skills/2026-05-25/
mv .claude/skills/liquid-glass docs/archive/skills/2026-05-25/
mv .claude/skills/background-processing docs/archive/skills/2026-05-25/
mv .claude/skills/push-notifications docs/archive/skills/2026-05-25/
mv .claude/skills/settings-screen docs/archive/skills/2026-05-25/
mv .claude/skills/review-response-writer docs/archive/skills/2026-05-25/
```

### 4.2 MERGE → 合并 + 归档（24 个）

**目标容器 tdd-feature**：
- 从 tdd-bug-fix / tdd-refactor-guard / integration-test-scaffold / snapshot-testing / characterization-test-generator 提取内容追加到 tdd-feature 的 SKILL.md（按 TDD 工作流不同章节）
- tdd-bug-fix → §bug-fix-scenario
- tdd-refactor-guard → §refactor-scenario
- integration-test-scaffold → §integration-scenario
- snapshot-testing（含 snapshot-diff-review）→ §visual-regression-scenario
- characterization-test-generator → §refactor-safety-net
- 归档 6 个原 skill

**目标容器 swiftui-pro**：
- 从 swiftui-debugging / ui-review / accessibility-generator 提取内容追加到 swiftui-pro
- 归档 3 个原 skill

**新容器 swiftui-patterns**：
- 新建 `docs/standards/swiftui-patterns.md`
- 内容从 animation-patterns / migration-patterns / navigation-patterns 提取
- 归档 3 个原 skill

**目标容器 app-description-writer**：
- 追加 app-store-rejection / keyword-optimizer / app-store-assets 内容
- 归档 3 个原 skill

**目标容器 coding-best-practices（standards）**：
- 追加 test-contract 内容
- 归档 1 个原 skill

**目标容器 ci-cd-setup（standards）**：
- 追加 error-monitoring 内容
- 归档 1 个原 skill

**目标容器 privacy-manifests（standards）**：
- 追加 data-export 内容
- 归档 1 个原 skill

**目标容器 dependency-propagation（standards）**：
- 追加 api-research 内容
- 归档 1 个原 skill

**目标模板 onboarding-generator**：
- 追加 tipkit-generator 内容
- 归档 1 个原 skill

### 4.3 PROMOTE_TO_STANDARDS → 移内容 + 删 skill（5 个）

- coding-best-practices → `docs/standards/swift-coding.md`
- app-icon-generator → `docs/standards/app-icon-design.md`
- ci-cd-setup → `docs/standards/ci-cd.md`
- dependency-propagation → `docs/standards/dependency-propagation.md`
- privacy-manifests → `docs/standards/privacy-manifests.md`

### 4.4 DOWNGRADE_TO_TEMPLATE → 移模板 + 删 skill（7 个）

- onboarding-generator → `docs/templates/onboarding/`
- cross-audit → `docs/templates/cross-audit-workflow.md`
- cross-audit-consensus → `docs/templates/cross-audit-consensus.md`
- post-merge → `docs/templates/post-merge-checklist.md`
- resume-from-handoff → `docs/templates/session-resume.md`
- sprint-contract → `docs/templates/sprint-contract.md`
- deep-linking → `docs/templates/deep-linking/`

### 4.5 REWRITE → 重写（2 个）

- swift-concurrency-pro：更新 references 目录，对齐 Swift 6.3
- swiftdata-pro：更新 references 目录，对齐 Swift 6.3 + iOS 26

### 4.6 KEEP → 不动（7 个）

- dod-checklist / phase-closeout / swiftui-pro（作为容器已合并内容） / verify-audit-report / xcode-review / tdd-feature（作为容器已合并内容） / screenshot-planner

### 4.7 全量清理后统计

**最终产物分布**（精确）：

| 类别 | 数量 | 明细 |
|---|---|---|
| **active skill**（保留 skill 形态）| **10** | 7 KEEP（dod-checklist / phase-closeout / swiftui-pro / verify-audit-report / xcode-review / tdd-feature / screenshot-planner，其中 swiftui-pro 和 tdd-feature 作为容器吸纳合并内容）+ 2 REWRITE（swift-concurrency-pro / swiftdata-pro）+ 1 MERGE 容器（app-description-writer） |
| **docs/standards/** 新增 | **5** | swift-coding.md（吸纳 coding-best-practices + test-contract）/ ci-cd.md（吸纳 ci-cd-setup + error-monitoring）/ dependency-propagation.md（吸纳 dep-propagation + api-research）/ privacy-manifests.md（吸纳 privacy-manifests + data-export）/ app-icon-design.md / swiftui-patterns.md（吸纳 animation + migration + navigation patterns）—— **实际 6 个**（修正：含 swiftui-patterns） |
| **docs/templates/** 新增 | **9** | 7 个 #017 DOWNGRADE_TO_TEMPLATE（cross-audit-workflow / cross-audit-consensus / post-merge-checklist / session-resume / sprint-contract / deep-linking/ + onboarding/ 共识）+ 2 个 MERGE 派生模板（knowledge-health-workflow.md / localization-workflow.md） |
| **归档 skill** | **31** | 7 DELETE + 24 MERGE 原目录 |

**说明（修正 sign-off 反馈）**：`docs/templates/` 9 个文件中 7 个是 #017 直接 DOWNGRADE_TO_TEMPLATE 输出，2 个（knowledge-health / localization-setup）是 MERGE 派生模板目标——避免误读为新增 Verdict。

**净化率**：52 → 10 active skill = 净减 81%（高于 §1 "67%" 估算，因 5 个 PROMOTE + 7 个 DOWNGRADE 都从 active skill 计数中扣除）。

---

## §5 Stage 6 元规则反思预测点

路径 C 实证识别以下可能触发 M-000 / M-005 修订的盲点：

### 5.1 M-000 §6 下沉优先级的修正

**原文本（M-000 v2.0 §6）**：新增条款下沉优先级为「M-001~M-006、standards、skills、ADR、STATUS stub 或工具」，将 skill 列为下沉去向之一。

**路径 C 实证**：82% skill（43/52）被裁决为非 optimal 形态（MERGE / DELETE / PROMOTE / DOWNGRADE），其中 24 个被合并到非 skill 容器。证明 **skill 作为元规则下沉去向的优先级应降低**。优先从高到低应为：standards → templates → CI/hook 自动化 → 工具 → skill。

**预测触发**：Stage 6 反思后 patch M-000 §6 下沉优先级列表，将 skill 移至末位或加注「仅需要 LLM 动态判断的场景使用」。

### 5.2 M-005 §G docaudit check 设计原则扩展

**原范围（M-005 §G）**：仅覆盖 docaudit check 的升降级机制（§G.4）。

**路径 C 实证**：#017 裁决 24 个 MERGE + 5 PROMOTE + 7 DOWNGRADE + 2 REWRITE 构成「skill 升降级」的完整实证数据。现有 §G.4 的三个条件（≥3 次审计运行 + 30 天 + 误报率 < 20%）无法直接平移至 skill 升降级。

**预测触发**：Stage 6 反思后扩展 M-005 §G 为「docaudit check 与 skill 升降级双轨机制」，新增 skill 特有的判据：触发频率、事故来源、异源分歧度、不可替代性证明。

### 5.3 M-005 §B 伪共识识别的 skill 维度缺失

**原范围（M-005 §B）**：仅覆盖文本产出层面的伪共识信号（同源主笔、训练 cutoff、身份误识别等）。

**路径 C 实证**：Claude 同源偏向已验证（给 cross-audit / sprint-contract 等自己起草过程用过的 skill KEEP 而帅哥裁决全部 DOWNGRADE）。这属于「skill 消费层面的同源偏向」——主笔倾向于保留自己用过/写过的 skill。

**预测触发**：Stage 6 反思后扩展 M-005 §B 新增信号：「主笔消费过的治理 skill 在主笔自己的 audit 中给予 KEEP → 自动标为同源偏向，在折叠报告中显式标注」。

### 5.4 M-003 起草的实证输入

Stage 7 M-003 起草的核心理念来自路径 C 实证，不在此预测（属 M-003 内容）。但 Stage 6 需确认 M-003 的起草前提是否成立。

---

## §6 M-003 起草输入（基于路径 C 实证）

### 6.1 核心实证数据

- 52 个 skill → 17 个净化版（净减 67%）
- 治理 skill 12 个 → 仅 3 个 KEEP（dod-checklist / phase-closeout / verify-audit-report），其余 9 个全部降格（5 DOWNGRADE / 2 MERGE / 1 DELETE / 1 PROMOTE）
- 工具 skill 40 个 → 9 个 KEEP/REWRITE（含容器）+ 其余全部合并/降格
- 4 家异源分歧率 87%→ 用户裁决后达成一致的最终图

### 6.2 M-003 必须回答的三问

1. **skill 与 standards / templates 的边界**：什么内容应该进 skill（需要 LLM 动态判断且不可下沉）vs standards（静态规范）vs templates（代码模板）？
   - 实证边界：trigger 是否依赖 LLM 实时推理 + 是否可被静态文档或脚本替代
2. **治理 skill vs 工具 skill 的命名空间分离**：是否应在 `.claude/skills/governance/` vs `.claude/skills/tools/` 物理隔离？
   - 实证：治理 skill 的同源偏向风险（Claude 自审失真）可通过物理隔离 + 元规则禁止治理 skill 互审降低
3. **skill 生命周期机制**：如何避免当前 52→17 的大规模重构在未来重演？
   - 建议：M-003 必须定义 skill 的「触发频率监控 + 误触发率统计 + 季度衰退检查 + 自动降格阈值」

### 6.3 M-003 核心机制建议

- **SSOT 单源化**：`.agents/skills/` 作为 portable skill 的唯一 SSOT（非适配器），`.claude/skills/` 只留 symlink 或 manifest 入口
- **命名空间分离**：`.claude/skills/governance/` 只放治理 skill（需元规则 sign-off），`.claude/skills/tools/` 放工具 skill（无需元规则 sign-off）
- **升降级双轨**：skill 的升级/降级采用 M-005 §G.4 框架的扩展版（新增 skill 特有判据）
- **季度衰退检查**：每 90 天检查 skill 触发日志，连续 2 个季度无触发的自动降格为模板候选