---
last_verified: 2026-05-17
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [uc_change, code_refactor, adr_added]
---
# SnapDrill 需求-代码 Traceability Matrix

> **来源**：`docs/product/product-cases.md`（验收点定义）→ Swift 源码（`// Trace:` 注解）→ `Packages/*/Tests/`（测试绑定）
>
> **目标**：任何代码段能反推 UC/ADR/NFR；任何 UC/ADR/NFR 能正向定位到代码 + 测试 + 监控。完整链条可搜、可证、可追溯。
>
> **当前阶段**：UC-4 试点行（深度优先，epic #766 Phase 2）。其他 UC 待 PR #C 之后批量补齐。

## 表结构（13 列 schema）

| 列 | 语义 |
|---|---|
| `Trace ID` | `UC-N.{SP\|VE\|EX\|DG}i` 稳定标识，源码 `// Trace:` 注解直接引用 |
| `Use Case` | `UC-N Title` 反向链回 cases.md |
| `Acceptance Point` | 摘自 cases.md 的原文或稳定简写 |
| `Type` | `success` / `variant` / `exception` / `data_guarantee` 四档 |
| `Product Source` | `docs/product/product-cases.md` 锚点（含行号或 heading） |
| `Implementation Anchors` | `file:type:method [strength]` 列表，`[strength]` ∈ `implements`/`triggers`/`references` |
| `Test Anchors` | `TestFile.testName` 列表 |
| `NFR Links` | `NFR-{DOMAIN}-{METRIC}` 大写 slug 列表 |
| `ADR Links` | `ADR-NNN[strength]` 列表，含 `backlog: ADR-NNN` 占位 |
| `Instrumentation` | `OSSignposter` / Analytics event / test assertion 描述 |
| `Coverage Status` | `covered` / `partial` / `gap` 三档（机读，禁 emoji） |
| `Last Verified` | 该行最近一次手工/自动核验日期 |
| `Notes` | 限制、风险、设计偏差、非目标 |

## 双轨防脱同步契约

- **轨道 1（matrix → source）**：每个 `Implementation Anchors` 必须能在源码中 grep 到对应 `// Trace: UC-N.APi` token；`Test Anchors` 必须真实存在
- **轨道 2（source → matrix）**：源码 `// Trace:` 中出现的所有 UC ID 必须在本 matrix 出现；不在 cases.md 的 AP ID 视为 error
- **覆盖率口径**：`covered` 行 ≥1 `implements` anchor；`partial` 行有 anchor 但 UI 或边界路径未测；`gap` 行可无 anchor，但 Notes 必须解释为何 gap
- 强制由 `Scripts/audit/docaudit.py` 的 `traceability` check 执行（PR #B 落地）

## Coverage Status 三档

| Status | 含义 | 触发动作 |
|---|---|---|
| `covered` | ≥1 `implements` anchor + ≥1 测试覆盖关键路径 | 仅 monitor，无需动作 |
| `partial` | 有 anchor 但 UI 路径、边界场景或 NFR 验证未单测 | 列入测试 backlog |
| `gap` | 无 anchor 或无测试 | Notes 必须解释；优先级看 AP 严重度 |

---

## UC-4 Review Due Cards

> **Source**: `docs/product/product-cases.md` § Use Case 4（line 144–179）
> **Trace ID 前缀**：`UC-4.{SP\|VE\|EX\|DG}i`
> **AP 总数**：16（SP×7 + VE×3 + EX×3 + DG×3）
> **Last Verified**: 2026-05-17

| Trace ID | Use Case | Acceptance Point | Type | Product Source | Implementation Anchors | Test Anchors | NFR Links | ADR Links | Instrumentation | Coverage Status | Last Verified | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| UC-4.SP1 | UC-4 Review Due Cards | Dashboard 展示待复习数量和入口 | success | `product-cases.md#Use-Case-4` SP1 | `ReviewDashboardView.swift [implements]`; `ReviewHeroCard.swift [implements]`; `ReviewViewModel.loadDataAsync [implements]` | `ReviewViewModelTests.initialPhaseIsLoading`; `ReviewViewModelTests.loadDataAsync_distinguishesDueFromFuture` | `NFR-PERF-LIST-500MS` | `ADR-001[references]` | Analytics `review_session_started` (entry path) | partial | 2026-05-17 | UI 渲染未做 snapshot 测试 |
| UC-4.SP2 | UC-4 Review Due Cards | 用户点击入口进入 Review | success | `product-cases.md#Use-Case-4` SP2 | `ReviewRouter.swift [implements]`; `ReviewViewModel.startSession [implements]` | `ReviewViewModelTests.startSession_将 reviewQueue 复制到 workingItems 并进入 reviewing`; `ReviewViewModelTests.startSession_清除上次会话的残留状态` | — | `ADR-001[references]` | Analytics `review_session_started` | partial | 2026-05-17 | 路由 UI 未单测 |
| UC-4.SP3 | UC-4 Review Due Cards | 系统按队列展示卡片正面（含原题图片与 OCR 文字） | success | `product-cases.md#Use-Case-4` SP3 | `ReviewView.swift [implements]`; `ReviewCardContent.swift [implements]`; `ReviewCardFactory.swift [implements]`; `ReviewViewModel.workingItems [references]` | — | `NFR-PERF-SCROLL-60FPS`; `NFR-A11Y-IMAGE-REQUIRED` | `ADR-001[references]` | proposed `OSSignposter(review.cardRender)` | gap | 2026-05-17 | UI snapshot 与图片/OCR 渲染未单测；纳入 PR #C 之后的测试 backlog |
| UC-4.SP4 | UC-4 Review Due Cards | 用户点击翻面查看答案 | success | `product-cases.md#Use-Case-4` SP4 | `ReviewViewModel.toggleAnswer [implements]`; `ReviewCardBack.swift [implements]`; `isAnswerShown [references]` | `ReviewViewModelTests.toggleAnswer 每次调用切换 isAnswerShown` | — | `ADR-001[references]` | — | partial | 2026-05-17 | 翻面动画/手感未单测 |
| UC-4.SP5 | UC-4 Review Due Cards | 滑动/按钮完成评估（手势与按钮等价） | success | `product-cases.md#Use-Case-4` SP5 | `ReviewViewModel.triggerButtonRating [implements]`; `ReviewViewModel.handleSwipeCompletion [implements]`; `ReviewActionButtons.swift [implements]`; `SwipeCard.swift [implements]` | `ReviewViewModelTests.向右滑（good）更新 SM-2 状态并持久化到 @Model`; `ReviewViewModelTests.向左滑（again）将 repetitions 和 interval 重置为 0` | — | `ADR-001[references]` | Analytics `review_item_completed` | partial | 2026-05-17 | 仅 button 路径有测；gesture 路径只跑过 ViewModel handleSwipe，无 SwipeCard UI 测 |
| UC-4.SP6 | UC-4 Review Due Cards | 系统依据评估更新 SM-2 状态并推进下一题 | success | `product-cases.md#Use-Case-4` SP6 | `ReviewScheduler.scheduleNextReview [implements]`; `SM2State [implements]`; `ReviewViewModel.handleSwipeCompletion [triggers]` | `ReviewSchedulerTests.*` (14 test); `ReviewViewModelTests.向右滑（good）更新 SM-2`; `ReviewViewModelTests.again 评分后题目仍在待复习队列（nextReviewAt 约 10 分钟后）` | `NFR-RELIABILITY-SAVE-ROLLBACK` | `ADR-001[references]`; `backlog: ADR-004` (SM-2 选型) | Analytics `review_item_completed` (with rating) | covered | 2026-05-17 | SM-2 算法本身已 14 test 全覆盖 |
| UC-4.SP7 | UC-4 Review Due Cards | 全部到期题完成后展示摘要并返回上一级 | success | `product-cases.md#Use-Case-4` SP7 | `ReviewSessionSummaryView.swift [implements]`; `ReviewViewModel.phase=.finished [implements]`; `sessionGoodCount` / `sessionAgainCount` [implements] | `ReviewViewModelTests.最后一张卡片滑走后 phase 变为 finished`; `ReviewViewModelTests.非最后一张卡片滑走后 phase 保持 reviewing` | — | `ADR-001[references]` | Analytics `review_session_completed` (with total/good/again) | partial | 2026-05-17 | SessionSummaryView UI 未 snapshot 测；"返回上一级" 语义在 UC-4 文本未明确（gap-by-design，本期不修） |
| UC-4.VE1 | UC-4 Review Due Cards | 手势与按钮等价输入 | variant | `product-cases.md#Use-Case-4` Variants | `ReviewViewModel.triggerButtonRating [implements]`; `SwipeCard.swift [implements]`; 双路径汇入 `handleSwipeCompletion` | `ReviewViewModelTests.triggerButtonRating 快速连续调用时第二次被防抖忽略` (button only) | `NFR-A11Y-GESTURE-FALLBACK` | — | — | partial | 2026-05-17 | 手势/按钮等价性无对照测试 |
| UC-4.VE2 | UC-4 Review Due Cards | 图片题复习时必须显示图片，OCR 仅为辅助 | variant | `product-cases.md#Use-Case-4` Variants | `ReviewCardContent.swift [implements]` (图片渲染分支) | — | `NFR-A11Y-IMAGE-REQUIRED` | — | — | gap | 2026-05-17 | 无 UI 断言验证图片必显示；待 PR #C 之后补 |
| UC-4.VE3 | UC-4 Review Due Cards | 用户可撤销最近评估（受 `undoStackCapacity=20` 限） | variant | `product-cases.md#Use-Case-4` Variants（PR #A 新增） | `ReviewViewModel.undoLastSwipe [implements]`; `ReviewViewModel.undoStack [implements]`; `UndoEntry [implements]`; `undoStackCapacity=20 [references]` | `ReviewViewModelTests.undoLastSwipe 将条目移回 workingItems 头部`; `ReviewViewModelTests.finished 状态下 undoLastSwipe 恢复为 reviewing`; `ReviewViewModelTests.undoStack 为空时 undoLastSwipe 无操作`; `ReviewViewModelTests.undoLastSwipe 完整回滚 SM-2 状态到滑动前，避免数据损坏`; `ReviewViewModelTests.undoStack 超过上限时自动丢弃最旧条目`; `ReviewViewModelTests.undoStack 未超限时不丢弃条目` | `NFR-RELIABILITY-SAVE-ROLLBACK` | `backlog: ADR-005` (Undo 策略) | — | covered | 2026-05-17 | Undo 在 PR #A 之前 UC-4 文本未声明但实现已有；本 PR 同步补 Variant 文本 |
| UC-4.EX1 | UC-4 Review Due Cards | 当前无到期题：Dashboard 与 Review 入口显示空状态 | exception | `product-cases.md#Use-Case-4` Exceptions | `ReviewEmptyStateView.swift [implements]`; `ReviewViewModel.phase=.idle` when `reviewQueue.isEmpty [implements]` | `ReviewViewModelTests.loadDataAsync_emptyDatabase_idleAndEmptyQueue` | — | — | — | partial | 2026-05-17 | UI 渲染未单测 |
| UC-4.EX2 | UC-4 Review Due Cards | 某题缺答案：允许翻面进入空答案状态，仍可评估 | exception | `product-cases.md#Use-Case-4` Exceptions | `ReviewCardBack.swift [implements]` (空答案分支) | — | — | — | — | gap | 2026-05-17 | 空答案 UI 路径无单测 |
| UC-4.EX3 | UC-4 Review Due Cards | 单题更新失败时阻止假完成（rollback） | exception | `product-cases.md#Use-Case-4` Exceptions | `ReviewViewModel.persistRatingChange [implements]` (save 失败 rollback + 不更新 workingItems) | `ReviewViewModelSaveFailureTests.handleSwipeCompletion 保存失败时恢复 workingItems、undoStack 与 SM-2 字段` | `NFR-RELIABILITY-SAVE-ROLLBACK` | — | test assertion | covered | 2026-05-17 | 失败路径已 1 test 覆盖 |
| UC-4.DG1 | UC-4 Review Due Cards | 只更新当前 Profile 的复习状态 | data_guarantee | `product-cases.md#Use-Case-4` Data guarantees | `ProfileManager [implements]` (Profile scope 来源); `AppRootView [triggers]` (Profile 切换入口); `RepositoryContainer [references]` (Profile 注入 Repository) | — | `NFR-DATA-PROFILE-ISOLATION` | — | — | partial | 2026-05-17 | **Codex R3 修正**：DG1 锚点不在 `ReviewRepository.fetchDueModels`（因 `ReviewItemModel` 无 profileId 字段，隔离由 Profile-scoped DB / Repository 注入实现）。Repository 层 Profile 隔离 test 缺失 |
| UC-4.DG2 | UC-4 Review Due Cards | 评估只落库一次，不双重更新 | data_guarantee | `product-cases.md#Use-Case-4` Data guarantees | `ReviewViewModel.isProcessingSwipe [implements]`; `ReviewViewModel.minInteractionInterval=0.55s [references]` | `ReviewViewModelTests.triggerButtonRating 快速连续调用时第二次被防抖忽略`; `ReviewViewModelTests.triggerButtonRating 在 minInteractionInterval 内重复调用被节流`; `ReviewViewModelTests.handleSwipeCompletion 重置 isProcessingSwipe，允许下一次触发`; `ReviewViewModelTests.空队列时 handleSwipeCompletion 不崩溃` | — | `backlog: ADR-006` (防抖间隔 0.55s 取值) | — | covered | 2026-05-17 | 防抖与重入防御 4 test 完整 |
| UC-4.DG3 | UC-4 Review Due Cards | 摘要与本轮成功提交的评估结果一致 | data_guarantee | `product-cases.md#Use-Case-4` Data guarantees | `sessionGoodCount` / `sessionAgainCount` 在 `handleSwipeCompletion` 内 atomic 更新 [implements] | `ReviewViewModelTests.undoLastSwipe 完整回滚 SM-2 状态到滑动前，避免数据损坏`; `ReviewViewModelTests.quitSession 后 workingItems 和 undoStack 被清空` | — | — | — | covered | 2026-05-17 | 间接覆盖（计数器一致性已测） |

## 后续阶段（不在本 PR 范围）

- **PR #B**：`Scripts/audit/docaudit.py` 加 `traceability` check + `policy.yaml` SSOT + baseline whitelist（首次 partial/gap 大量命中需 baseline suppress 直到 PR #C 补完注解 + 测试）
- **PR #C**：UC-4 全部 16 AP 在源码 + 测试加 `// Trace:` 注解（13 文件）
- **PR #D**：新建 ADR-004（SM-2 选型）/ ADR-005（Undo 策略）/ ADR-006（防抖间隔 0.55s）/ ADR-007（maxInterval=365 天上限）4 个 ADR 占位文档
- **未来 epic #766 Phase 3+**：扩展到 UC-1..UC-3 / UC-5..UC-9

## 相关文档

- `docs/product/product-cases.md` — UC 验收点定义（**SSOT**）
- `docs/tech/non-functional-requirements.md` — NFR 条目定义
- `docs/decisions/ADR-*.md` — ADR 决策记录
- `docs/standards/review-prompt-guide.md` — Review 提示词规范
- `docs/KNOWLEDGE_MAP.md` — 文档全景索引
