---
id: feat-library
title: 题库管理 + 分享卡片
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: 题库管理 + 分享卡片

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：抄题、剪贴、分类、归档枯燥、重复、低效。题目录进来后若不能定位、整理、按需挑出，采集就失去意义——管理是价值链承上启下的一环（采集 → **管理** → 导出/打印）。题库管理让积累的题目可搜、可分类、可编辑、可安全删除，是产品的核心可用性。
- **定位**：管理与录入并列为主路径，是价值链核心环节而非附加值；任何损害"录入/管理"简洁性的功能都不该做（设计铁律）。分享卡片定位为**家长间一对一交流的样张图片**，不是社交分享——SnapDrill 不是社交产品（不做分享社区 / 跨用户推荐算法 / 行为信号采集 feed）。
- **原则归属**：P1 录入体验（管理服务于"录入后立即可用"）+ P2 简洁（过滤维度克制、不做回收站 / 多级撤销）+ P4 数据属于用户与数据安全（删除可撤销）+ P5 家长友好（零学习曲线）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **题库列表与排序**：默认按录入时间倒序（最新录入最可能需编辑补充）；可按录入时间 / 学科 / 难度 / 复习状态切换排序。
- **搜索**：基于 OCR 文字内容匹配，使用标准导航栏搜索栏（用户记得题目关键词即可检索）。
- **多维过滤**：学科（多选）+ 标签（多选）+ 难度（多选），条件可叠加组合生效。**来源 / 年级字段可开启录入但不进入过滤维度**——使用频率低且加入会使过滤 UI 复杂（P2 简洁）。
- **编辑**：进入题目详情可看原图、OCR 文字、元数据、答案；编辑可改系统字段、自定义标签、答案文字 / 答案图片，**可只补答案而不动题目主内容**，可只改难度，可扩展尚未开启的字段（不必先去设置）。
- **字段配置系统**：固定字段（题目内容）永不可关；学科默认开启可关；难度 / 来源 / 年级 / 答案默认关闭按需开启；自定义标签始终可用不可关。系统字段（学科 / 来源 / 年级）选项列表可增删改——录入页输入新值无感创建（颜色 / 图标默认随机）、设置页深度管理；重命名级联更新所有引用该选项的题目；**已被题目使用的选项禁止删除**（数据完整性）。
- **批量操作**：编辑按钮进入选择模式 → 勾选多题 → 批量打标签（追加目标标签、不移除既有标签）/ 批量删除。**只做批量打标签与批量删除**（最高频需求）；批量编辑系统字段场景少、交互复杂，暂不做。
- **删除 + 撤销**：单题 / 多题删除走软删除 + 底部 Toast 5 秒撤销窗口；超时永久删除；仅支持最近一次删除的单级撤销（新删除覆盖旧撤销上下文）；不做回收站、不做摇一摇撤销、不做确认弹窗。
- **分享卡片（ShareCard）**：单题生成一张图片，用于家长间一对一样张交流；走系统 ShareSheet 保留路径自由，但 App 内 UI 文案不引导公开传播。
- **边界 / 不做**：不做来源 / 年级过滤；不做回收站 / 多级撤销栈；不做批量编辑系统字段；分享卡片不做社交分享 / 社区 / 推荐算法；不提供题库内容（工具非内容平台）。**PDF / JSON / CSV / `.zip` 导出与打印是同级 / 独立 feature**，本 spec 不展开（见 `feat-export.md`）。
- **前置依赖**：无。被依赖：复习（`feat-review.md`）、智能组卷（`../backlog/feat-smartpaper.md`）、高级统计（`../backlog/feat-advanced-stats.md`）消费本 feature 的题目 / 分类 / 过滤数据；导出（`feat-export.md`）以题库过滤 / 选中结果集为输入。
- **商业分层**：搜索 / 学科·标签·难度过滤 / 排序 / 编辑 / 批量打标签 / 批量删除 / 字段配置 / 单题分享卡片 / Multi-Profile = **免费基础能力，不作订阅门槛**（单设备题库完整可管理，多孩家庭可直接使用）。本 feature 无 Pro 项；SM-2 数据驱动的智能组卷 / 高级统计是 Pro（在各自 feature 展开，定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：`SnapDrillFeatureLibrary`（题库列表 / 搜索 / 过滤 / 详情 `LibraryDetailView` / 编辑 `LibraryEditViewModel` / `LibraryViewModel`）。`@Model` 类型 `ReviewItem` / `Subject` / `Source` / `Grade` / `Tag` 定义在 `SnapDrillData`，经各 Repository（`ReviewRepository` / 分类 `Subject·Source·Grade·TagRepository`）+ `RepositoryContainer` 访问。删除窗口由 `DeletionScheduler`（App 级 Service，`SnapDrillCore`）管理。ShareCard 归 `SnapDrillFeatureLibrary/ShareCardView`。
- **关键机制 / 数据流**：View（`@Environment(\.repositories)` 注入）→ ViewModel → Repository（封装 ModelContext）→ `DataExecutor`（actor）→ SwiftData `@Model`。Repository `insert()` 为纯内存操作，必须显式 `saveContext()` 才持久化；保存失败 `rollbackContext()`。跨模块刷新发 `Notification.Name.reviewDataDidChange`（`LibraryEditViewModel` 等为发布方，Dashboard / Review ViewModel 监听刷新）。软删除：`LibraryViewModel.softDeleteItems()` → `DeletionScheduler.scheduleDeletion(ids:executor:)` 注册 ID 集合 + 删除执行器并启动 5 秒倒计时，从列表临时移除；`undoDeletion()` 恢复、取消倒计时；`commitImmediately()` 在 App 进入后台时立即落删。批量删除复用同一套机制。ShareCard 用 SwiftUI `ImageRenderer`（iOS 16+），**不走 PDFExport 批量管线**（仅渲染单题，单一职责）。
- **State & Concurrency**（Swift 6 strict）：题库 View 由 `@Observable` ViewModel（`@MainActor`）驱动；搜索 / 过滤 / 排序为内存视图操作，不改底层数据；编辑保存、批量打标签、删除等重活与落库经 Repository → `DataExecutor`（actor），不阻塞主线程。题库列表图片**按需 + 降采样加载**（`loadDownsampledImage`）控制滚动内存。Per-Profile 隔离：题库 / 字段配置 / 自动推断历史 / 排序偏好由 `ProfileManager` 按 Profile 切换重建 `ModelContainer` + `RepositoryContainer`。
- **设计裁决（仅本模块）**：
  - **过滤维度只取学科 / 标签 / 难度**：来源 / 年级开启可录入但不过滤（P2 简洁，避免过滤 UI 膨胀）——局部裁决，不外推到其他字段语义。
  - **无回收站、单级撤销**：误删用 5 秒软删除窗口兜底而非回收站（回收站增加信息架构复杂度，违 P2）；只撤销最近一次（奥卡姆剃刀）。
  - **ShareCard 不复用 PDF 批量管线**：单题渲染用 `ImageRenderer`，避免为单题强行套批量流水线（design §简洁 / 单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 当前 Profile 题库已有 ≥1 道题，When 进入题库，Then 默认按录入时间倒序展示当前 Profile 题目；可搜索（OCR 文字）、可学科 / 标签 / 难度多选叠加过滤、可切换排序（UC2）。
  - Given 选中某题，When 进入编辑并改系统字段 / 标签 / 答案文字或图片后保存，Then 列表与详情反映更新结果；可只补答案 / 只改难度而不动主内容（UC2）。
  - Given 进入选择模式勾选多题，When 执行批量打标签，Then 目标标签追加到所选题目、不移除未触及的既有标签（UC2）。
  - Given 删除单题或多题，When 软删除并弹出 5 秒 Toast，Then 窗口内点撤销恢复最近一次删除的全部题目；未撤销超时永久删除，列表 / 统计 / 复习入口同步移除（UC3）。
- **边界 / 异常**：
  - 空题库 → 显示空状态 + 去采集入口，不显示脏数据（Boundary B17）。
  - 搜索 / 过滤无结果 → 保留用户已选搜索词与过滤条件，显示无结果状态，不清空条件、不改列表数据（Boundary B18 / UC2 Exception）。
  - 编辑保存失败 → 保持旧数据不变，提示失败可重试（UC2 Exception）。
  - 批量打标签 / 删除部分失败 → 反馈成功 / 失败数量，已成功项保留，失败项不写半状态（Boundary B12 / UC2·UC3 Exception）。
  - 删除请求发起失败 → 不从列表移除、不弹成功 Toast；撤销请求失败 → 提示恢复失败，原题保留软删除状态待重试（UC3 Exception）。
  - Undo window 内 App 进入后台 / 被杀 → 下次启动 `DeletionScheduler` 在 boot 阶段扫描未过窗口的软删除项自动收敛为"已恢复"或"已永久删除"，不出现幽灵记录 / 重复记录 / 孤儿状态（Boundary B10 / B11）。
  - 系统字段选项删除：已被题目使用的选项禁止删除，UI 阻断并提示（UC2 Variant）。
- **数据保证**：
  - 搜索 / 过滤 / 排序只影响当前展示，不改动底层题目数据。
  - 编辑保存原子更新，失败保持旧数据不变；批量打标签对每个题目独立落库，不因单条失败回滚已成功项。
  - 软删除窗口内题目不得被其他功能当作正式可编辑记录修改；撤销成功后题目 ID / 元数据 / 图片 / 复习进度完整恢复；永久删除后题目主记录 / 图片引用 / 搜索索引 / 复习记录一致移除。
  - 重命名系统字段选项级联更新所有引用该选项的题目。
  - 题目始终归属当前 Profile，搜索 / 过滤 / 编辑 / 删除 / 撤销不得跨 Profile 泄露或污染数据。
- **NFR**：题库列表加载 < 500ms（200 题，Tab 切换到渲染完成）；搜索响应 < 300ms（输入到结果更新）；滚动 60fps（快速滚动无掉帧）；题库浏览内存 < 150MB（200 题，图片按需 + 降采样）。分享走系统分享 sheet（非 Analytics 事件）；无内置 `library_count` 事件（激活深度由 `review_item_created` 累计推导）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（管理是价值链核心 / 设计铁律 / 不是社交产品） | vision §使命·价值链 + §不是社交产品 + design §产品价值链铁律 + business §免费层定义 |
| Why（分享卡片 = 一对一样张非社交） | design §版权合规边界 + vision §不是社交产品 |
| What（列表 / 排序 / 过滤维度 / 搜索） | requirements §题库排序与过滤 + design §题库信息架构 [P1, P2] |
| What（编辑 / 字段配置 / 系统字段选项增删改） | requirements §字段配置规格 + design §字段可配置系统 [P1, P2] |
| What（批量操作 / 删除撤销 / 不做回收站·多级撤销） | requirements §软删除强退收敛 + design §批量操作设计 [P2] + §删除撤销设计 [P4] |
| What（分享卡片定位 / 系统 ShareSheet 不引导公开传播） | requirements §数据可携带权矩阵·分享卡片 + design §版权合规边界 |
| What（功能分层 MoSCoW / 免费边界） | requirements §功能边界 MoSCoW + business §免费层完整定义·管理 |
| How（FeatureLibrary / @Model / Repository / DataExecutor / 通知） | architecture §模块拓扑 + §数据流 + §ShareCard |
| How（DeletionScheduler 软删除机制） | architecture §Soft Delete + Undo 实现 |
| How（ImageRenderer / 单一职责 / 降采样 / Per-Profile） | architecture §ShareCard + §Multi-Profile 实现 + NFR §内存 |
| Verify（success / 边界 / 数据保证） | cases UC2 + UC3 + Boundary B10/B11/B12/B17/B18 |
| Verify（NFR 性能 / 内存 / 埋点） | NFR §性能 + §内存 + analytics §激活深度·成果分发 |

## 关联
- 原则：`../../explanations/vision.md`（P1 录入体验 / P2 简洁 / P4 数据属于用户 / P5 家长友好）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 4：整理和管理已有题目，含过滤 / 编辑 / 搜索 / 误删撤销 / 过滤→导出打印）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（下游 Pro 分层）
- 相关 / 下游 feature：`feat-export.md`（PDF / 打印 / 数据导出）、`feat-review.md`（消费分类数据）、`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
