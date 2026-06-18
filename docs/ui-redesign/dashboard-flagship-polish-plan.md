# Dashboard 首页屏发布级打磨清单（待 PO 确认）

> 状态：待 PO 确认。本文只收敛 Dashboard 首页屏打磨范围、完成线、文案候选和验证方式；确认前不执行实现。

## 0. PO 决策区

| 决策项 | Codex 默认建议 | PO 结论 |
| --- | --- | --- |
| D1 启动首屏定位 | Dashboard 是启动首屏，应呈现为成人生产力概览：资料库、回顾、近期活动和快捷入口；不呈现为儿童学习 App 或游戏化任务页。 | 待确认 |
| D2 视觉统一 | 沿用 Library / Capture / Review 的冷静系统风格：grouped 背景、克制蓝色、清晰分割、低饱和状态色；降低当前入口卡片的强渐变和营销感。 | 待确认 |
| D3 状态机 | Loading / Empty / Data / Error 都要有可见状态，不留裸 `ProgressView` 或只写 log 的失败。若 ViewModel 没暴露错误状态，记录跨层 blocker，不静默改逻辑。 | 待确认 |
| D4 首页回顾语义 | 保留“回顾”作为成人生产力语境；避免“复习 / 学习 / 错题 / 同学 / 太棒了”等儿童或校园化信号。 | 待确认 |
| D5 快捷入口 | 保留采集、资料库、今日概览、分类管理等高频入口，但命名和层级改为资料管理语境。 | 待确认 |
| D6 高级统计 / Pro | Pro 能力保留为 v1.x 方向；首版纯免费。首页若展示锁态，应克制呈现为“稍后推出 / 更多洞察”，不做诱导付费弹窗。 | 待确认 |
| D7 草稿恢复 | 当前草稿恢复文案在 ViewModel 内硬编码中文且使用“题”。默认建议改为 L10n 驱动的“资料 / 采集”语境；若需要触碰 ViewModel，仅做文案外科手术式修理。 | 待确认 |
| D8 L10n 归属 | Dashboard 当前复用 `L10n.Library.categoryManager`。若继续多屏复用，应登记为共享 key 或后续迁入 Common/Shared；本屏打磨不顺手搬层。 | 待确认 |
| D9 契约 seed | Dashboard 打磨 PR 完成后，另开小 PR 沉淀状态 / 文案 / L10n 归属契约；不把契约 seed 塞进实现 PR。 | 待确认 |

## 1. 范围与红线

**范围**：Dashboard 首页屏族，包括 `DashboardView`、首页 header、回顾 hero、快捷入口卡片、今日统计、分类管理入口、`DashboardAnalyticsView` 的首页可见部分，以及这些视图直接露出的 L10n / VoiceOver 文案。

**不做**：其它屏、Data/Core/Infrastructure、统计算法、Pro 实现、bundle 名、`developmentRegion`、TestFlight、ASO、`#816` DIRTY 分支。默认不改 `*ViewModel.swift`；若只有 ViewModel 能修复 UI 可见问题，先列明最小改动理由和风险。

**硬边界**：

- 对外文案候选需 PO 确认后才能落代码。
- 不删除 VoiceOver 标签、选中 trait、`accessibilityIdentifier` 或 XCUITest 依赖。
- Dashboard 中任何“现在没有状态暴露”的问题，不用 UI 假装解决；登记为跨层 blocker。
- PO 最新明确决策 > 代码实证 > `AGENTS.md` / git-tracked SSOT > feature spec / ADR > 私有记忆。

## 2. 当前代码事实

- `DashboardView` 在 `viewModel == nil` 时只显示裸 `ProgressView`，没有启动文案或骨架态（`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift:136`）。
- 空态由 `totalCount == 0` 触发，使用 `dashboard.empty_title` / `dashboard.empty_description` / `dashboard.goCapture`（`DashboardView.swift:58`）。
- 首页快捷入口使用多组高饱和渐变：blue/purple、orange/pink、green/teal、gray（`DashboardView.swift:83`）。
- 分类管理入口标题复用 `L10n.Library.categoryManager`，属于跨屏 L10n 归属问题（`DashboardView.swift:188`）。
- `DashboardViewModel.loadData()` 失败只写日志，不向 UI 暴露错误态；代码注释明确把 Dashboard 统计失败视为 S3 非阻塞（`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardViewModel.swift:76`）。
- 草稿恢复文案在 `DashboardViewModel.draftAlertMessage` 内硬编码中文，并使用“题”语境（`DashboardViewModel.swift:101`）。
- `DashboardAnalyticsView` 对非 Pro 用户显示锁态 overlay；有数据、空数据、Pro gate 三种 UI，但错误仍在 ViewModel 内 log-only（`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsView.swift:23`）。
- Dashboard / Statistics 现有中英文文案仍包含“题目 / 错题 / 复习 / 学习 / 学科 / 薄弱 / Student”等旧教育语境（`SnapDrill/Resources/zh-Hans.lproj/Localizable.strings:125`、`SnapDrill/Resources/en.lproj/Localizable.strings:125`、`SnapDrill/Resources/zh-Hans.lproj/Localizable.strings:846`、`SnapDrill/Resources/en.lproj/Localizable.strings:847`）。

## 3. 打磨清单

### D1 启动首屏信息架构

**目标**：打开 App 后第一屏给用户清楚的生产力概览：当前资料库规模、今日回顾负载、最近入口和下一步操作。

**完成线**：

- Header 不使用校园化称呼；默认用户文案中英文一致。
- Hero 区突出“今日回顾 / 待处理内容 / 资料库状态”，不使用奖励式语气。
- 视觉层级稳定：首要动作、次要入口、状态指标一眼可分。

### D2 Loading / Empty / Data / Error 状态

**目标**：每个可见状态都有解释和下一步，不出现“页面空白 / 裸 spinner / 只 log”的状态。

**完成线**：

- Loading：给出轻量骨架或说明，不只显示无上下文 `ProgressView`。
- Empty：强调“采集第一条资料 / 建立资料库”，避免“错题 / 复习之旅”。
- Data：指标卡和入口不跳动，Dynamic Type 下不互相遮挡。
- Error：若现有 ViewModel 没有错误状态，登记 blocker；若可最小暴露状态，则需 PO 确认是否允许触碰 ViewModel。

### D3 快捷入口与分类管理

**目标**：入口是工具台，不是营销卡片。

**完成线**：

- 采集、资料库、回顾、分类管理入口命名中性、图标轻快、色彩克制。
- 卡片尺寸稳定，长文案不撑破布局。
- 分类管理入口若继续复用 Library key，需要在后续契约 seed 中登记共享归属。

### D4 高级统计 / Pro 锁态

**目标**：首版纯免费语境下，高级统计不制造付费焦虑，也不虚假承诺已可用。

**完成线**：

- 非 Pro 锁态文案改为“更多数据洞察稍后推出”一类中性表达。
- 不新增购买弹窗、不实现 StoreKit、不暗示首版已有 Pro。
- 空数据提示从“学习分析”改为资料/回顾洞察语境。

### D5 草稿恢复

**目标**：未完成采集恢复是可靠的生产力安全网。

**完成线**：

- 文案从“题”改为“资料 / 采集内容”。
- zh/en 都走 L10n 或等价的本地化路径，不保留硬编码中文。
- 若文案迁移需要改 ViewModel，只做文案层最小改动，不改恢复逻辑。

### D6 无障碍与布局稳定

**目标**：首屏在 VoiceOver、Dynamic Type、深色模式下仍可用。

**完成线**：

- 保留现有 a11y identifier 和标签。
- 状态指标有可读 VoiceOver label。
- 卡片和统计区域在大字号下不重叠、不截断关键动作。

## 4. 对外文案合规清单（PO-gated）

| 现有 key / 文案 | 风险 | 候选方向 |
| --- | --- | --- |
| `dashboard.empty_title` = `还没有任何题目` | 旧教育语境 | `还没有资料` / `从第一条资料开始` |
| `dashboard.empty_description` = `拍摄一道错题，开始你的间隔复习之旅` | 错题 + 复习旅程 | `拍摄或导入一条资料，建立你的资料库` |
| `dashboard.add_new` = `录入新题` | 题目限定 | `添加资料` / `采集资料` |
| `dashboard.browse_library` = `题库浏览` | 题库限定 | `资料库` / `浏览资料` |
| `dashboard.today_reviewed` = `今日复习` | 校园化 | `今日回顾` |
| `dashboard.due_review` = `待复习` | 校园化 | `待回顾` |
| `dashboard.draft_alert_title` = `恢复未完成的题目？` | 题目限定 | `恢复未完成的采集？` |
| `DashboardViewModel.draftAlertMessage` = `有一道…题未保存…` | 硬编码中文 + 题目限定 | `有一条…资料未保存…`，并迁入 L10n |
| `dashboard.welcome_subtitle` = `添加第一道错题，开启复习之旅` | 错题 + 复习旅程 | `添加第一条资料，开始整理` |
| `dashboard.all_done` = `太棒了！` | 奖励式儿童化语气 | `今日已完成` / `已完成` |
| `dashboard.default_name` en = `Student` | 学生身份 | `User` |
| `statistics.title` = `学习分析` | 教育定位 | `资料洞察` / `回顾分析` |
| `statistics.subject_trend` = `学科错题趋势` | 学科 + 错题 | `分类趋势` |
| `statistics.weak_subjects` = `薄弱学科` | 学习诊断语境 | `待回顾较多的分类` |
| `statistics.weak_subjects_hint` = `待复习题目最多的学科` | 复习 + 题目 + 学科 | `待回顾内容较多的分类` |
| `statistics.no_data_hint` = `采集一些题目后即可查看学习分析` | 题目 + 学习 | `采集一些资料后即可查看数据洞察` |
| `statistics.pro_required` = `学习分析为 Pro 功能，敬请期待` | 学习 + Pro 暗示 | `更多数据洞察稍后推出` |

## 5. 状态验证矩阵

| 状态 | 当前证据 | 本轮目标 | 验证方式 |
| --- | --- | --- | --- |
| 初始化加载 | 裸 `ProgressView` | 有上下文 loading / skeleton | Simulator + code path |
| 空资料库 | 使用旧题目/复习文案 | 通用资料库空态 + 清晰 CTA | Simulator |
| 有资料 + 有待回顾 | Hero / stats 显示待回顾数量 | 文案回顾化，布局稳定 | Seed data / Simulator |
| 有资料 + 今日已完成 | `all_done` 旧奖励式文案 | 成人化完成态 | Seed data / Simulator |
| 草稿存在 | Alert 文案硬编码中文 | L10n + 资料语境 | Code path / Simulator |
| 草稿不存在 | 无 alert | 不误触发 | Code path |
| 分类管理入口 | 复用 Library key | 行为保留，归属登记 | Code review |
| 高级统计锁态 | Pro gate overlay | 克制稍后推出，不诱导付费 | Simulator |
| 高级统计有数据 | Statistics cards | 文案与视觉统一 | Mock / seed data |
| 高级统计空数据 | Empty hint | 资料洞察语境 | Simulator |
| Dashboard load 失败 | log-only | 可见 error 或跨层 blocker | Code review + PO 决策 |
| Analytics load 失败 | log-only | 可见 error 或跨层 blocker | Code review + PO 决策 |

## 6. 跨层发现与待裁决

- `DashboardViewModel.loadData()` 与 `DashboardAnalyticsViewModel.loadAnalytics()` 当前错误只写日志。如果 PO 要求首页错误可见，需要新增最小错误状态或接受“保留旧数据 + 非阻塞提示”的契约。
- `DashboardViewModel.draftAlertMessage` 是用户可见文案但在 ViewModel 内硬编码中文。若本轮修复，需要允许一次外科手术式 ViewModel 文案迁移。
- `L10n+Insights.swift` 位于 Core，但承载 Dashboard / Statistics UI 文案。本轮可改已批准字符串，不移动层级；跨层发现继续记录。
- `L10n.Library.categoryManager` 被 Dashboard 复用。共享 key 归属应在 Dashboard contract seed 中明确。
- `docs/features/active/feat-dashboard.md` 仍有首页概览、复习、题目等旧描述。实现 PR 可同步更新 feature spec，或在 Dashboard contract seed 中单独收敛。

## 7. 实现完成线

确认本清单后，Dashboard 实现 PR 的完成线为：

- PO 决策区 D1-D9 已确认或明确延期。
- Dashboard 首页状态矩阵逐项完成或登记 blocker。
- PO-gated 对外文案经 PO 签字后落代码，zh/en 同步。
- 不触碰 #816，不改受保护分支，不重写 Data/Core/Infrastructure 或统计算法。
- 若确需改 `*ViewModel.swift`，只做已说明的 UI 文案或状态暴露最小改动，并在 PR 中单独列出。
- `swiftlint --strict` 通过。
- `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` 通过。
- 针对性 Simulator / 真机可行路径实测记录完成。
- 创建 Ready PR，不 merge。

## 8. 本计划 PR 验证

本 PR 只新增 Dashboard 打磨清单，属于 T0 文档治理改动。验证要求：

- `git diff --check`
- `python3 Scripts/validate_docs.py --check`
- `python3 Scripts/generate_feature_status.py --check`
- `python3 Scripts/generate_intent_traceability.py --check`

不运行 iOS 全量 build；任何后续 Dashboard View / L10n / ViewModel 实现改动按 T2-T3 执行完整验证。
