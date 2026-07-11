---
id: feat-library
title: 题库管理 + 分享卡片
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-30
intent_refs:
  - vision:P1
  - vision:P2
  - vision:P4
  - vision:P5
---

# Feature: 题库管理 + 分享卡片

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：抄题、剪贴、分类、归档枯燥、重复、低效。题目录进来后若不能定位、整理、按需挑出，采集就失去意义——管理是价值链承上启下的一环（采集 → **管理** → 导出/打印）。题库管理让积累的题目可搜、可分类、可编辑、可安全删除，是产品的核心可用性。
- **定位**：管理与录入并列为主路径，是价值链核心环节而非附加值；任何损害"录入/管理"简洁性的功能都不该做（设计铁律）。分享卡片定位为**用户间一对一交流的样张图片**，不是社交分享——SnapDrill 不是社交产品（不做分享社区 / 跨用户推荐算法 / 行为信号采集 feed）。
- **原则归属**：P1 采集摩擦最低（管理服务于"录入后立即可用"）+ P2 简洁（过滤维度克制、不做回收站 / 多级撤销）+ P4 数据属于用户与数据安全（删除可撤销）+ P5 成人生产力工具（零学习曲线、中性成熟）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **题库列表与排序**：默认按录入时间倒序（最新录入最可能需编辑补充）；可按录入时间 / 分类 / 复习状态切换排序。
- **搜索**：基于 OCR 文字内容匹配，使用标准导航栏搜索栏（用户记得题目关键词即可检索）。
- **多维过滤**：所有已配置动态维度均可过滤（分类 / 来源 / 级别 / 标签 / 自定义属性）；维度间 AND、维度内 OR，条件可叠加组合生效。难度不再是 `ArchiveItemModel` 静态字段，若用户需要“难度/级别”语义，应通过字段管理器创建或启用对应动态维度。
- **编辑**：进入题目详情可看原图、OCR 文字、元数据、答案；编辑可改系统字段、自定义标签、答案文字 / 答案图片，**可只补答案而不动题目主内容**，可改动态字段，可扩展尚未开启的字段（不必先去设置）。
- **字段配置系统**：固定字段（内容）永不可关；内置分类 / 来源 / 级别 / 标签默认不在录入页显示，用户按需开启；自定义维度默认可见。系统字段（分类 / 来源 / 级别）选项列表可增删改——录入页输入新值无感创建（颜色 / 图标默认随机）、设置页深度管理；重命名级联更新所有引用该选项的资料；**已被资料使用的选项禁止删除**（数据完整性）。
- **批量操作**：编辑按钮进入选择模式 → 勾选多题 → 批量打标签（追加目标标签、不移除既有标签）/ 批量删除。**只做批量打标签与批量删除**（最高频需求）；批量编辑系统字段场景少、交互复杂，暂不做。
- **删除 + 撤销**：单题 / 多题删除走软删除 + 底部 Toast 5 秒撤销窗口；超时永久删除；仅支持最近一次删除的单级撤销（新删除覆盖旧撤销上下文）；不做回收站、不做摇一摇撤销、不做确认弹窗。
- **分享卡片（ShareCard）**：单题生成一张图片，用于用户间一对一样张交流；走系统 ShareSheet 保留路径自由，但 App 内 UI 文案不引导公开传播。
- **边界 / 不做**：不做独立难度字段 / 星级难度筛选；不做回收站 / 多级撤销栈；不做批量编辑系统字段；分享卡片不做社交分享 / 社区 / 推荐算法；不提供题库内容（工具非内容平台）。**PDF / JSON / CSV / `.zip` 导出与打印是同级 / 独立 feature**，本 spec 不展开（见 `feat-export.md`）。
- **前置依赖**：无。被依赖：复习（`feat-review.md`）、智能组卷（`../backlog/feat-smartpaper.md`）、高级统计（`../backlog/feat-advanced-stats.md`）消费本 feature 的题目 / 分类 / 过滤数据；导出（`feat-export.md`）以题库过滤 / 选中结果集为输入。
- **商业分层**：搜索 / 动态维度过滤 / 排序 / 编辑 / 批量打标签 / 批量删除 / 字段配置 / 分享卡片均为免费基础能力。本 feature 无 Pro 项。

## 3. 技术设计 (How)
- **模块归属**：`SnapDrillFeatureLibrary`（题库列表 / 搜索 / 过滤 / 详情 `LibraryDetailView` / 编辑 `LibraryEditViewModel` / `LibraryViewModel`）。`@Model` 类型 `ArchiveItemModel` / `CategoryDimensionModel` / `CategoryValueModel` 定义在 `SnapDrillData`，经 `ArchiveRepository` / `CategoryDimensionRepository` / `CategoryValueRepository` + `RepositoryContainer` 访问。删除窗口由 `DeletionScheduler`（App 级 Service，`SnapDrillCore`）管理。ShareCard 归 `SnapDrillFeatureLibrary/ShareCardView`。注意：备份 wire key `reviewItems` 与开发种子入口 `seedReviewItems` 是刻意保留的外部格式 / 调试入口名称，不代表主领域模型仍叫 `ReviewItem`。
- **关键机制 / 数据流**：View（`@Environment(\.repositories)` 注入）→ ViewModel → Repository（封装 ModelContext）→ `DataExecutor`（actor）→ SwiftData `@Model`。Repository `insert()` 为纯内存操作，必须显式 `saveContext()` 才持久化；保存失败 `rollbackContext()`。跨模块刷新发 `Notification.Name.reviewDataDidChange`（`LibraryEditViewModel` 等为发布方，Dashboard / Review ViewModel 监听刷新）。软删除：`LibraryViewModel.softDeleteItems()` → `DeletionScheduler.scheduleDeletion(ids:executor:)` 注册 ID 集合 + 删除执行器并启动 5 秒倒计时，从列表临时移除；`undoDeletion()` 恢复、取消倒计时；`commitImmediately()` 在 App 进入后台时立即落删。批量删除复用同一套机制。ShareCard 用 SwiftUI `ImageRenderer`（iOS 16+），**不走 PDFExport 批量管线**（仅渲染单题，单一职责）。
- **State & Concurrency**（Swift 6 strict）：资料库由 `@Observable` ViewModel 驱动；搜索/过滤/排序为内存视图；写操作经 Repository → `DataExecutor`。列表图片按需降采样，所有界面共享 `LibrarySession` 的 repositories。
- **设计裁决（仅本模块）**：
  - **过滤维度取动态字段全集**：分类 / 来源 / 级别 / 标签 / 自定义属性走同一维度系统；不再为难度保留独立静态筛选器，避免产品重新滑回教育专用结构。
  - **无回收站、单级撤销**：误删用 5 秒软删除窗口兜底而非回收站（回收站增加信息架构复杂度，违 P2）；只撤销最近一次（奥卡姆剃刀）。
  - **ShareCard 不复用 PDF 批量管线**：单题渲染用 `ImageRenderer`，避免为单题强行套批量流水线（design §简洁 / 单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 资料库已有 ≥1 条资料，When 进入资料库，Then 默认按录入时间倒序展示；可搜索、按动态维度过滤并切换排序（UC2）。
  - Given 选中某题，When 进入编辑并改系统字段 / 标签 / 答案文字或图片后保存，Then 列表与详情反映更新结果；可只补答案 / 只改动态字段而不动主内容（UC2）。
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
  - 搜索 / 过滤 / 编辑 / 删除 / 撤销只操作唯一资料库的明确目标集合。
- **NFR**：题库列表加载 < 500ms（200 题，Tab 切换到渲染完成）；搜索响应 < 300ms（输入到结果更新）；滚动 60fps（快速滚动无掉帧）；题库浏览内存 < 150MB（200 题，图片按需 + 降采样）。分享走系统分享 sheet（非 Analytics 事件）；无内置 `library_count` 事件（激活深度由 `review_item_created` 累计推导）。


## 5. Contracts（列表 / 详情 / 导出入口）

### A. 列表与筛选刷新

- 列表必须区分 loading / empty / no-result / content 四类状态；筛选、搜索、排序切换时不得先展示半更新行（例如标签消失、星级左移）再移除整行。
- 搜索防抖与筛选刷新应以稳定快照为边界；若 UI 无法避免中间态，应登记为 ViewModel/数据快照契约缺口，而不是用动画遮盖。
- 多选状态下，全选、取消、导出入口必须与当前筛选结果一致；导出后选择状态清理或保留属于产品决策，不得由 UI 静默改变。

### B. 详情与参考内容

- 从 Library 进入详情时，题目正文优先展示；参考内容默认收起，用户显式展开后才显示。
- 展开/收起参考内容不得刷新整页或重置滚动位置；图标、标题与内容区域的变化应是局部状态变化。

### C. 导出 / 分享 / 打印入口

- Library 只负责把当前筛选/选择集合交给导出流；PDF、分享、打印的行为契约见 `docs/features/active/feat-export.md`。
- 空集合不得生成空文件；用户取消分享/打印不等于失败；生成失败必须用户可见，不只写日志。

### D. 文案与 L10n 归属

- Library 对外文案必须保持通用受众定位，避免把资料库描述成儿童、作业或校园专用场景。
- 已知共享 key：`L10n.Library.categoryManager` 被 Dashboard 复用。后续 L10n 归属整理应迁入 Common/Shared 或显式登记共享，不应长期挂在单屏命名空间。

### Enforcement

| 契约项 | Enforcement |
|---|---|
| 筛选刷新稳定性 | #816 / 后续 ViewModel 快照修复；合入前需针对性模拟器实测 |
| 详情参考内容默认收起 | UI 状态测试或针对性人工实测 |
| 导出入口集合语义 | Export 契约与相关测试覆盖 |
| Library 文案定位 | Capture/Library 范围 grep gate 或 PR review |
| 共享 L10n key 归属 | 批量 L10n 归属整理 PR |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 用户拥有数据 / P5 成人生产力工具） | 管理是价值链承上启下环节；过滤维度克制、软删除可撤销、零学习曲线中性成熟 |
| 产品政策 / ADR | `../../decisions/ADR-001-smart-paper-analytics-pricing.md`（下游 Pro 分层） | 本 feature 无 Pro 项；分享卡片走系统 ShareSheet、不引导公开传播 |
| 待验证假设 | `../../explanations/assumptions.md` H2（管理能力被真实使用，而非仅当一次性扫描器） | 搜索 / 过滤 / 编辑的使用率验证 H2 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 数据属于用户 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 5：搜索 / 过滤 / 编辑，含批量打标签 / 误删撤销 / 过滤→导出打印）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（下游 Pro 分层）
- 相关 / 下游 feature：`feat-export.md`（PDF / 打印 / 数据导出）、`feat-review.md`（消费分类数据）、`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
