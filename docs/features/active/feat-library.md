---
id: feat-library
title: 资料库管理 + 分享卡片
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-15
intent_refs:
  - vision:P1
  - vision:P2
  - vision:P4
  - vision:P5
release_refs:
  - release-1:C2-Core
  - release-1:C2-Optional
  - release-1:C4-D
  - release-1:C5-E
  - release-1:D4-B
---

# Feature: 资料库管理 + 分享卡片

> **产品重基线（2026-07-15）**：整理 / 找回属于核心价值链，用户可见容器统一为一个“资料库”。C2-Core 将搜索、查看、编辑、分类和可撤销删除列为 Must；D4-B 固定五秒绝对撤销期限跨后台与重启继续。动态字段与批量操作按 C2-Optional 成为默认隐藏的 Candidate optional，ShareCard 与按回顾状态排序则须新上游裁决才能重入。C4-D / C5-E 只允许 `po-only` / `research` build 通过 Library 各自一个静态次级入口实验，`public-candidate` 完全隐藏。frontmatter 与下文技术细节仍记录当前实现，旧 Multi-Profile、Pro、SmartPaper 和高级统计分层不得驱动新工作。

> 人读摘要：🧩 当前实现存在（当前分层：free）。派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示 Release 1 合同符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：采集、剪贴、分类、归档容易变成重复劳动。资料进入 App 后若不能定位、整理、按需挑出，采集就失去意义——管理是价值链承上启下的一环（采集 → **整理 / 找回** → 导出 / 打印）。资料库让积累的材料可搜、可分类、可编辑、可安全删除。
- **定位**：管理与录入并列为主路径，是价值链核心环节而非附加值；任何损害"录入/管理"简洁性的功能都不该做（设计铁律）。分享卡片定位为**用户间一对一交流的样张图片**，不是社交分享——SnapDrill 不是社交产品（不做分享社区 / 跨用户推荐算法 / 行为信号采集 feed）。
- **原则归属**：P1 采集摩擦最低（管理服务于"录入后立即可用"）+ P2 简洁（过滤维度克制、不做回收站 / 多级撤销）+ P4 数据属于用户与数据安全（删除可撤销）+ P5 成人生产力工具（零学习曲线、中性成熟）。详见 `../../explanations/vision.md`。

## 2. 当前实现规则与 Release 1 分类 (What)

> 下列条目同时记录当前实现。Release 1 Must 是资料库搜索、查看、编辑、基础分类和可撤销删除；动态字段与批量操作是 manifest 可纳入的 Candidate optional。ShareCard 默认 hidden，按回顾状态排序随 C4-D hidden；后二者都不能由 manifest 单独纳入，重入需新上游裁决。
- **资料库列表与排序**：默认按录入时间倒序（最新录入最可能需编辑补充）；当前实现可按录入时间 / 分类 / 回顾状态切换，非默认排序不属于 Must，其中按回顾状态排序必须隐藏。
- **搜索**：基于 OCR 文字内容匹配，使用标准导航栏搜索栏（用户记得题目关键词即可检索）。
- **多维过滤**：所有已配置动态维度均可过滤（分类 / 来源 / 级别 / 标签 / 自定义属性）；维度间 AND、维度内 OR，条件可叠加组合生效。难度不再是 `ArchiveItemModel` 静态字段，若用户需要“难度/级别”语义，应通过字段管理器创建或启用对应动态维度。
- **编辑**：进入资料详情可看 App-managed 主图、OCR 文字、元数据、答案；Must 编辑覆盖基础分类 / 标签与主内容，可只补答案而不动主内容。动态字段及尚未开启字段的扩展属于 Candidate optional。
- **字段配置系统（Candidate optional）**：固定字段（内容）永不可关；内置分类 / 来源 / 级别 / 标签默认不在录入页显示，用户按需开启；自定义维度默认可见。系统字段选项列表可增删改；重命名级联更新所有引用该选项的资料；**已被资料使用的选项禁止删除**（数据完整性）。未被 manifest 纳入时零入口、零副作用。
- **批量操作（Candidate optional）**：编辑按钮进入选择模式 → 勾选多条资料 → 批量打标签（追加目标标签、不移除既有标签）/ 批量删除。批量编辑系统字段不做；未被 manifest 纳入时零入口、零副作用。
- **删除 + 撤销（D4-B）**：单条删除与五秒撤销机会属于 Must。点击删除时持久化绝对 deadline；后台不提前永久删除，deadline 前回到前台继续显示剩余时间，deadline 过后在前台恢复或下次启动幂等完成。新批次必须先等待上一批收敛，再获得自己的五秒窗口。批量删除本身是 Candidate optional；仅支持最近一次删除的单级撤销，不做回收站、摇一摇撤销或确认弹窗。
- **分享卡片（ShareCard，hidden）**：当前实现可把单条资料生成图片并走系统 ShareSheet；它不属于 C2-Optional 可由 manifest 纳入的范围，重入需新上游裁决。
- **边界 / 不做**：不做独立难度字段 / 星级难度筛选；不做回收站 / 多级撤销栈；不做批量编辑系统字段；分享卡片不做社交分享 / 社区 / 推荐算法；不提供题库内容（工具非内容平台）。**PDF / JSON / CSV / `.snapdrillbackup` 导出与打印是同级 / 独立 feature**，本 spec 不展开（见 `feat-export.md`）。
- **前置依赖**：无。回顾（`feat-review.md`）与候选 SmartPaper / 高级统计可消费本 feature 的资料、分类和过滤数据；导出（`feat-export.md`）以资料库过滤 / 选中结果集为输入。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；资料库 Must 不承担升级转化。SmartPaper 只按 C5-E 的非公开实验边界出现，高级统计隐藏；未来公开可见性或商业化需要新 contract。

## 3. 技术设计 (How)
- **模块归属**：`SnapDrillFeatureLibrary`（资料库列表 / 搜索 / 过滤 / 详情 `LibraryDetailView` / 编辑 `LibraryEditViewModel` / `LibraryViewModel`）。`@Model` 类型 `ArchiveItemModel` / `CategoryDimensionModel` / `CategoryValueModel` 定义在 `SnapDrillData`，经 `ArchiveRepository` / `CategoryDimensionRepository` / `CategoryValueRepository` + `RepositoryContainer` 访问。删除窗口由 `DeletionScheduler`（App 级 Service，`SnapDrillCore`）管理。ShareCard 归 `SnapDrillFeatureLibrary/ShareCardView`。注意：备份 wire key `reviewItems` 与开发种子入口 `seedReviewItems` 是刻意保留的外部格式 / 调试入口名称，不代表主领域模型仍叫 `ReviewItem`。
- **关键机制 / 数据流**：View（`@Environment(\.repositories)` 注入）→ ViewModel → Repository（封装 ModelContext）→ `DataExecutor`（actor）→ SwiftData `@Model`。Repository `insert()` 为纯内存操作，必须显式 `saveContext()` 才持久化；保存失败 `rollbackContext()`。跨模块刷新发 `Notification.Name.reviewDataDidChange`（`LibraryEditViewModel` 等为发布方，Dashboard / Review ViewModel 监听刷新）。当前软删除由 `DeletionScheduler` 仅在内存注册 ID、执行器与倒计时，并在后台调用 `commitImmediately()`；该实现会缩短 D4-B 承诺且无法跨进程恢复，是待独立 schema / code slice 收敛的偏差。目标机制必须让待删状态与资料行同一持久事务，并以绝对 deadline 唯一决定撤销或幂等永久删除。批量删除复用同一语义。ShareCard 用 SwiftUI `ImageRenderer`（iOS 16+），**不走 PDFExport 批量管线**（仅渲染单题，单一职责）。
- **State & Concurrency**（Swift 6 strict）：资料库 View 由 `@Observable` ViewModel（`@MainActor`）驱动；搜索 / 过滤 / 排序为内存视图操作，不改底层数据；编辑保存、批量打标签、删除等重活与落库经 Repository → `DataExecutor`（actor），不阻塞主线程。列表图片**按需 + 降采样加载**（`loadDownsampledImage`）控制滚动内存。当前 `develop` 的 Per-Profile container / preferences 是 B5-A 待退场实现，不能作为新增行为依据。
- **设计裁决（仅本模块）**：
  - **过滤维度取动态字段全集**：分类 / 来源 / 级别 / 标签 / 自定义属性走同一维度系统；不再为难度保留独立静态筛选器，避免产品重新滑回教育专用结构。
  - **无回收站、单级撤销**：误删用 5 秒软删除窗口兜底而非回收站（回收站增加信息架构复杂度，违 P2）；只撤销最近一次（奥卡姆剃刀）。
  - **ShareCard 不复用 PDF 批量管线**：单题渲染用 `ImageRenderer`，避免为单题强行套批量流水线（design §简洁 / 单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 资料库已有 ≥1 条资料，When 从 Dashboard 进入资料库，Then 可搜索 OCR 文字、按基础分类 / 标签过滤并查看资料（UC2）。
  - Given 选中某条资料，When 编辑基础分类 / 标签 / 答案文字或图片后保存，Then 列表与详情反映更新结果；可只补答案而不动主内容（UC2）。
  - Given 删除单条资料，When 软删除并弹出撤销机会，Then 从点击时刻起五秒内撤销可完整恢复；切到后台或重启不缩短绝对期限，期限结束后只执行一次永久删除（UC3）。
  - Given manifest 纳入动态字段或批量打标签 / 删除，When 使用对应能力，Then 通过该 optional 的数据完整性、部分失败摘要与 AX oracle；未纳入时零入口、零副作用。
  - Given 任一 Release 1 候选 build，When 遍历 Library 与系统触发面，Then ShareCard 保持隐藏且无副作用；当前 manifest 不得单独纳入，只有新上游裁决才能改变。
- **边界 / 异常**：
  - 空资料库 → 显示空状态 + 去采集入口，不显示脏数据（Boundary B17）。
  - 搜索 / 过滤无结果 → 保留用户已选搜索词与过滤条件，显示无结果状态，不清空条件、不改列表数据（Boundary B18 / UC2 Exception）。
  - 编辑保存失败 → 保持旧数据不变，提示失败可重试（UC2 Exception）。
  - 若 manifest 纳入批量打标签 / 删除，部分失败 → 反馈成功 / 失败数量，已成功项保留，失败项不写半状态（Boundary B12 / UC2·UC3 Exception）。
  - 删除请求发起失败 → 不从列表移除、不弹成功 Toast；撤销请求失败 → 提示恢复失败，原题保留软删除状态待重试（UC3 Exception）。
  - Undo window 内 App 进入后台 / 被杀 → deadline 前恢复运行时继续显示剩余时间；deadline 已过则在恢复 / 启动时幂等永久删除。不得因后台而提前提交，也不得把明确删除静默恢复（Boundary B10 / B11）。
  - 若 manifest 纳入动态字段管理，删除已被资料使用的选项 → UI 阻断并提示（UC2 Variant）。
- **数据保证**：
  - 搜索 / 过滤 / 排序只影响当前展示，不改动底层题目数据。
  - 编辑保存原子更新，失败保持旧数据不变；若纳入批量打标签，对每条资料独立落库，不因单条失败回滚已成功项。
  - 软删除窗口内题目不得被其他功能当作正式可编辑记录修改；撤销成功后题目 ID / 元数据 / 图片 / 复习进度完整恢复；永久删除后题目主记录 / 图片引用 / 搜索索引 / 复习记录一致移除。
  - 若纳入动态字段管理，重命名选项级联更新所有引用该选项的资料。
  - 搜索 / 过滤 / 编辑 / 删除 / 撤销只作用于唯一资料库，不得读写资料库之外的文件或遗留容器。
- **NFR**：资料库列表加载 < 500ms（200 条，从 Dashboard 进入到渲染完成）；搜索响应 < 300ms（输入到结果更新）；滚动 60fps（快速滚动无掉帧）；资料库浏览内存 < 150MB（200 条，图片按需 + 降采样）。ShareCard 必须有隐藏负向证据；生产仍无逐事件后端 Analytics。


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
| 五秒绝对撤销期限 | DeletionScheduler/Data 持久化测试 + background/relaunch fault tests + targeted UI test |
| Library 文案定位 | Capture/Library 范围 grep gate 或 PR review |
| 共享 L10n key 归属 | 批量 L10n 归属整理 PR |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 用户拥有数据 / P5 成人生产力工具） | 管理是价值链承上启下环节；过滤维度克制、软删除可撤销、零学习曲线中性成熟 |
| Release 1 Contract | `../../reference/release-1-contract.md` C2-Core / C2-Optional / C4-D / C5-E / D4-B | 五秒绝对撤销期限跨后台 / 重启；Must 与 optional 不从现有表面反推；Review / SmartPaper 只按 audience 和单一静态入口实验，不自动进入公开候选 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | Release 1 免费、无广告、无 IAP；分享卡片走系统 ShareSheet、不引导公开传播 |
| 待验证假设 | `../../explanations/assumptions.md` H2（管理能力被真实使用，而非仅当一次性扫描器） | 搜索 / 过滤 / 编辑的使用率验证 H2 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 数据属于用户 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 5：搜索 / 过滤 / 编辑，含批量打标签 / 误删撤销 / 过滤→导出打印）
- 商业政策：`../../explanations/business-model.md`
- 相关 / 下游 feature：`feat-export.md`（PDF / 打印 / 数据导出）、`feat-review.md`（消费分类数据）、`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
