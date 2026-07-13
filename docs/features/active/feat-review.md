---
id: feat-review
title: 回顾（SM-2 间隔调度）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-14
intent_refs:
  - vision:P2
  - vision:P3
  - vision:P5
---

# Feature: 回顾（SM-2 间隔调度）

> **产品重基线（2026-07-14）**：Product Constitution v1 将回顾定义为不得抢占核心链路的可选附加值；Release 1 Contract C4-D 只允许 `po-only` / `research` build 通过 Library 的单一静态次级入口实验，`public-candidate` 完全隐藏。无主 Tab、Dashboard cue / 计数、Onboarding 介绍、Settings 控件、通知、徽标或隐式恢复入口；达到预登记 cohort 门槛也只触发重新裁决。frontmatter 与技术章节仍记录当前实现，不代表这些偏差获准保留。

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户扫描、整理后的资料需要一个低摩擦的回看机制，避免重要内容只被归档而不再被处理。SM-2 间隔调度让资料库具备持续复用价值。
- **定位**：回顾是**可选留存层 / 免费附加值**，不是产品核心，**不向儿童学习、打卡或游戏化记忆工具靠拢**；若复杂度开始挤压采集/管理/导出主路径，以 vision P2 简洁裁决。
- **原则归属**：P3 免费层完成核心闭环（核心永久免费、回顾为免费附加值）+ P5 成人生产力工具（零学习曲线、不贩卖焦虑）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **SM-2 间隔回顾**：翻卡 + 滑动评估（有印象 / 没印象）。
- **Release 1 可见性**：仅 `po-only` / `research` 冻结 build 可从 Library 的一个静态次级入口进入；`public-candidate` 完全隐藏。C4-D 的实验不包含主 Tab、Dashboard cue / 计数、Onboarding、Settings、提醒 / 通知 / 徽标或隐式状态恢复。
- **Dashboard 回顾字段**（仅当前实现口径，Release 1 Dashboard 不保留 Review hero / cue / 计数）：
  - 资料总数；**待回顾数 = `ArchiveItemModel.nextReviewAt ≤ now` 且资料未软删**；**已回顾数 = 至少 1 次 SM-2 评估**；今日新增；各分类分布。
  - 时间序列 / 高级统计属于未获当前范围授权的候选，见 `../backlog/feat-advanced-stats.md`。
- **复习卡片外观设置与提醒**：当前代码包含字号、对齐和提醒设置；C4-D 的单一 Library 入口实验不包含这些 Settings 表面或通知，Release 1 必须隐藏。
- **边界 / 不做**：不做打卡、连续天数、成就弹窗；回顾入口在信息架构中不得压过采集与资料库。
- **前置依赖**：无。候选高级统计可以消费 Review 产出的 SM-2 数据；SmartPaper 当前实现中的 SM-2 依赖是遗留偏差，C5-S1 明确禁止 Release 1 实验 selector 使用 Review / SM-2。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP。非公开实验中的 Review 不做付费墙；公开可见性与任何未来商业化都需要新 contract。

## 3. 技术设计 (How)
- **模块归属**：SM-2 引擎 `SnapDrillCore`（`ReviewScheduler` / `SM2State`）；当前 Dashboard 聚合位于 `SnapDrillFeatureDashboard`，但 C3 / C4-D 的 Release 1 目标不消费 Review cue / 计数。
- **关键机制 / 数据流**：评估依结果更新该资料的 `easeFactor / interval / nextReviewAt` 并推进下一条；正面 = 原内容（图文，**必须显示图片**，尤其图形资料），背面 = 参考答案/备注；左滑/没印象、右滑/有印象，**手势必有等价按钮**（HIG）；答案缺失仍可翻面评估。
- **SM-2 数值合同**（`ReviewScheduler` 是 SSOT，测试向量必须同步）：
  - 评分 raw value：`again = 0`、`hard = 2`、`good = 3`、`easy = 5`。
  - EF 公式：`newEF = max(oldEF + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02), 1.3)`；EF clamp 在输出侧执行。
  - `again`：`repetitions = 0`、`interval = 0`、`nextReviewAt = now + 10 minutes`。
  - 非 `again`：`repetitions += 1`；第 1 次 interval = 1 天；第 2 次 interval = 6 天；第 3 次及以后 `interval = min(ceil(previousInterval * newEF), 365)` 天。
  - 当前合同向量：初始 EF 2.5 时 `hard → 2.18`、`good → 2.36`、`easy → 2.6`；`interval=6/repetitions=2/good` 的下一间隔为 15 天；`interval=10/repetitions=2/good` 的下一间隔为 24 天（证明使用更新后的 EF）；单次间隔上限为 365 天。
- **State & Concurrency**（Swift 6 strict）：复习 View 由 `@Observable` ViewModel（`@MainActor`）驱动；SM-2 状态更新经 Repository → `DataExecutor`（actor）落库，不阻塞主线程；每次评估**即时持久化**（不缓存到本轮结束）。
- **回顾 UI 可达性约束**：翻卡"有印象/没印象"为主观回忆自评，UI 必须低门槛、可达——大字号、清晰可点按钮、手势必有等价按钮（HIG 无障碍基线，承接 vision P5「无障碍是基础质量」）。重构回顾 UI 不得退化此可达性（缩小按钮 / 去掉按钮等价 = 退化）。
- **设计裁决（仅本模块）**：滑动手势 vs 系统返回 edge-swipe 冲突——复习场景卡片简洁性权重高于 P6 原生优先，**仅本模块裁决、不外推**；其他模块手势冲突仍走全局 P1>…>P6。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 有到期资料，When 进入 Review 并对每张卡翻面后评估（有印象/没印象，手势或按钮），Then SM-2 状态更新并推进下一张；全部完成后展示摘要（"N 条有印象，M 条需回看"）并返回。
- **可见性 (GWT)**：Given `public-candidate` build，When 用户遍历全部入口和系统触发面，Then Review 完全不可达且无调度副作用；Given 获准的 `po-only` / `research` build，Then 只有 Library 的一个静态次级入口可进入 Review。
- **边界 / 异常**：
  - 无到期资料 → 获准的非公开 Review 实验显示空状态，不进空白卡片流；Dashboard 不显示 Review cue / 计数，`public-candidate` 中 Review 完全不可达（Boundary B19）。
  - 某题缺答案 → 允许翻面进空答案状态，仍可评估。
  - **软删除 × 回顾队列**：资料软删除（5s undo 窗口）→ 立即从到期队列移除；undo 恢复 → 回顾状态一并恢复；过窗口永久删除 → 其 `ArchiveItemModel` 随资料级联清理。
    - **⚠ 实现现状（GAP-R1，代码债）**：当前 `ReviewViewModel.loadDataAsync()` 已在加载队列时排除 `DeletionScheduler.pendingDeletionIDs`；但 `.reviewing` 期仍忽略 `reviewDataDidChange` 通知，进行中会话不会被外部删除即时打断。需求不变（应避免已删除资料继续处理），待后续 ViewModel 契约修复。
  - 单题状态更新失败 → 阻止标记"已完成本轮"，提示重试，避免**假完成**。
- **数据保证**：只更新唯一资料库中被评估资料的回顾状态、不改资料主内容；每次评估只落库一次（重复手势 / 点击不得双重更新）；结果摘要必须与本轮成功提交的评估一致。
- **NFR**：卡片大图用降采样加载（`loadDownsampledImage`）控制延迟与内存；因每次评估即时落库，**中途退出不丢已评估进度**（仅未评估题保留到期）。

## 5. Review flagship polish checklist (2026-06-17)

**Scope**：仅处理 Review 屏族（入口概览、回顾会话、卡片正反面、底部动作、完成摘要）及其直接 L10n / a11y 文案。其它屏、发布硬化、bundle 名、TestFlight、Pro 功能、Core/Data/OCR 引擎不在本轮。

**Completion line**：
- 入口概览、加载/错误/空/完成态都应有明确用户反馈，不留空白或“点了没反应”的状态。
- 卡片会话保留“手势 + 等价按钮 + VoiceOver”三条路径；底部动作不得依赖仅红/绿或仅图标理解。
- Review 对外可见文案改为通用受众生产力语义：`回顾 / 没印象 / 有印象 / 已回顾 / 需回看`；避免儿童化、游戏化、打气式语言。
- 视觉与 Library / Capture 的基线一致：系统 grouped 背景、低阴影、清晰分割、适中圆角、克制蓝色强调；移除大面积紫蓝渐变和游戏化成功动效。
- 保留已存在的 VoiceOver 标签、a11y hints、selected traits、`accessibilityIdentifier` 相关路径。
- 若发现需要 ViewModel/Core/Data 新状态才能正确表达，应登记为跨层 blocker，不在本 UI PR 中重写逻辑。
- `swiftlint --strict` 与 `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` 必须通过。


## 6. Contracts（回顾 / 评级 / 会话一致性）

### A. 回顾卡片状态

- 回顾卡片默认只展示题面/资料内容；参考内容默认隐藏，用户显式点击或手势触发后才显示。
- 显示参考内容不得重置当前队列、评级状态或会话进度。
- 空队列、加载中、完成、错误四类状态应有明确 UI；不能让用户停在无反馈的空白页。

### B. 评级语义

- `有印象` / `Recalled` 表示用户认为自己已回忆起内容，应延长回顾间隔；`没印象` / `Forgot` 表示稍后需要再次出现。
- 按钮、左右滑、stamp、VoiceOver hint、会话摘要必须使用同一组语义；取消手势或退出会话不应被记录成评级。
- 保留“回顾”命名，不回退到校园化或儿童化的“复习/练习/闯关”语言。

### C. 会话一致性

- 每次评级只能作用于当前可见资料；队列进度、summary 和回顾计划必须来源于同一会话快照。
- 已知缺口：外部删除当前回顾资料的处理仍是 GAP-R1；在 ViewModel 暴露明确状态前，UI 不应伪造已处理结果。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| 参考内容默认隐藏 | View/UI 测试或针对性模拟器实测 |
| 评级词与 SM-2 语义一致 | L10n/a11y grep + Review ViewModel/服务层已有测试 |
| SM-2 数值合同 | `ReviewSchedulerTests` 合同向量（raw value / EF delta / interval / 365 天上限） |
| 取消不等于评级 | 针对性测试或 dogfood 实测 |
| 外部删除当前资料 | GAP-R1 跨层 blocker，后续契约修复 |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P5 成人生产力工具） | 复习是可选留存层、免费附加值；不向 Anki 靠拢、不贩卖焦虑；无障碍是基础质量 |
| Release 1 Contract | `../../reference/release-1-contract.md` C3 / C4-D | Dashboard 不由 Review 主导；只按指定 audience、单一 Library 入口和预登记证据实验，不自动公开 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | Release 1 免费、无广告、无 IAP；数据驱动候选不构成 Pro 承诺 |
| 待验证假设 | `../../explanations/assumptions.md` H9（可选回顾提升复用价值但不应拖向复杂记忆工具） | 复习使用率与复杂度验证 H9 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（复习作用于旅程 2 归档、旅程 5 整理后的题目；本版本未单列复习旅程）
- 商业政策：`../../explanations/business-model.md`
- 被依赖：`../backlog/feat-advanced-stats.md`；`../backlog/feat-smartpaper.md` 的当前 SM-2 依赖属于 C5-S1 禁止的遗留实现偏差
