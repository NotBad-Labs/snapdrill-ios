# SnapDrill 接口可追溯性矩阵

> **上游依赖**：`architecture.md`（包结构、公开类型）、`product-requirements.md`（功能需求）、`product-journeys.md`（用户旅程）、`product-vision.md`（产品原则）
>
> 为每个公开接口回答「它为什么存在？它的形状为什么是这样的？」
> **维护规则**：在架构审查节点（版本发布前、大规模重构后）批量刷新，不要求每次 PR 同步更新。
> 日常接口追溯通过 Issue→PR→commit 链路保证。创建时间：2026-03-13。

## 追溯引用索引

| 缩写 | 文档 |
|---|---|
| **PV-N** | product-vision.md 产品原则第 N 条 |
| **PR-X** | product-requirements.md「X」章节 |
| **PJ-N.S** | product-journeys.md 旅程 N 步骤 S |
| **PB-X** | product-business.md「X」章节 |
| **ARCH-X** | architecture.md「X」章节 |
| **ADR-N** | decisions/ADR-00N |

## 判定分类

| 判定 | 含义 |
|---|---|
| **JUSTIFIED** | 有明确产品需求支撑 |
| **ARCH_JUSTIFIED** | 无直接产品需求，但有架构/技术必要性 |
| **DEV_TOOL** | 开发工具（Preview/Debug/Seeder），不面向用户 |
| **PREMATURE** | 对应 v1.5/v2.0 需求，超前实现 |
| **SHAPE_CONCERN** | 存在合理但接口形状需要调整 |
| **UNJUSTIFIED** | 未找到产品或架构理由 |

---

## 1. Capture 模块（录入 — 生命线）

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `CaptureView` | JUSTIFIED | PV-1（录入体验是生命线）、PR「录入方式优先级」、PJ-1.1 | 五种录入入口（拍照/相册/手动/剪贴板/PDF）对应 PR 优先级表 |
| `CaptureViewModel` | JUSTIFIED | PV-1、PR「OCR 定位」、PJ-1.4 | 协调相机、相册选择、OCR 识别、草稿恢复 |
| `CaptureRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」、ADR-003 | FeatureRouter 协议实现，管理导航状态 |
| `CaptureDestination` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | 枚举值：`placeholder`（FeatureRouter 协议要求）、`scannerResult`（PJ-1.3→PJ-1.5）、`pdfPagePicker`（PR「PDF 导入 P1」） |
| `CaptureResultView` | JUSTIFIED | PJ-1.3–1.6、PR「字段可配置系统」、PR「OCR 定位」 | 裁剪→OCR→元数据编辑→保存的完整流程 |
| `CaptureResultViewModel` | JUSTIFIED | PJ-1.4–1.6、PR「字段可配置系统」「自动推断」 | 覆盖所有可配置字段（学科/来源/难度/年级/答案/标签），支持自动推断上次选值 |
| `SmartCameraView` | JUSTIFIED | PR「录入方式 P0：摄像头拍照」、PJ-1.2 | SwiftUI 层相机界面，含取景框 overlay |
| `SmartCameraViewController` | JUSTIFIED | PR「录入方式 P0」 | UIKit 层相机控制器（SwiftUI 无原生相机 API） |
| `CameraSessionManager` | JUSTIFIED | PR「录入方式 P0」 | AVCaptureSession + Vision 文字检测管线 |
| `CameraStateActor` | JUSTIFIED | PR「录入方式 P0」 | Vision 矩形平滑与稳定检测（actor 隔离，线程安全） |
| `DocumentScannerView` | JUSTIFIED | PR「录入方式 P0：摄像头拍照」 | VNDocumentCameraViewController 封装，自动边缘检测+透视校正。注：非 PDF 导入，是文档扫描拍照入口 |
| `PDFPagePickerView` | PREMATURE | PR「路线图 v1.5：PDF 导入 P1」 | 已实现 PDF 页面选择→裁剪→OCR 完整流程，但 PDF 导入在路线图中属 v1.5 |
| `PDFThumbnailCache` | PREMATURE | 同上 | PDFPagePickerView 的配套缓存 |
| `PDFThumbnailView` | PREMATURE | 同上 | PDFPagePickerView 的配套缩略图组件 |
| `CornerBracketShape` | JUSTIFIED | PR「录入方式 P0」 | 相机取景框四角装饰（辅助对准题目区域） |
| `SmartCameraRepresentable` | JUSTIFIED | PR「录入方式 P0」 | UIKit↔SwiftUI 桥接（技术必要） |
| `CaptureMethodCardContent` | JUSTIFIED | PR「录入方式优先级」 | CaptureView 内部子组件 |
| `CaptureMethodCard` | JUSTIFIED | PR「录入方式优先级」 | CaptureView 内部子组件 |

### Capture 验证小结

- **字段覆盖**：CaptureResultViewModel 支持学科/来源/难度/年级/答案/标签，与 PR「字段可配置系统」完全对齐
- **连续录入**：CaptureRouter 的 `shouldReopenScanner` + `originalAlbumImage` 支持保存后自动回到摄像头/连续裁剪（PJ-1.6–1.7、PR「连续录入设计」）
- **PDF 相关 3 个类型属 PREMATURE**：功能已完整可用，但 PR 路线图将其排在 v1.5

---

## 2. Library 模块（管理 — 核心体验）

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `LibraryView` | JUSTIFIED | PJ-3.1、PR「功能边界：题目分类管理」 | 题库主列表，含搜索/排序/过滤/多选删除/导出 |
| `LibraryViewModel` | JUSTIFIED | PJ-3.2–3.7、PR「字段可配置系统」 | 三维过滤（搜索+学科+标签）+ 分页 |
| `LibrarySortOption` | JUSTIFIED | PJ-3.1「默认按录入时间倒序」 | 枚举值：`createdAt`（PJ-3.1）、`subject`（PJ-3.2）、`difficulty`（PJ-3.6）、`reviewStatus`（PJ-4 复习状态维度） |
| `LibraryRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」、ADR-003 | FeatureRouter 协议实现 |
| `LibraryDestination` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | `placeholder` + `detail(ReviewItemModel)` |
| `LibraryDetailView` | JUSTIFIED | PJ-3.4 | 题目详情页：原图+OCR文字+元数据+答案 |
| `LibraryEditView` | JUSTIFIED | PJ-3.5–3.6、PR「补充阶段」 | 编辑界面：补答案、改难度、加标签、替换图片 |
| `LibraryEditViewModel` | JUSTIFIED | PJ-3.5–3.6 | 编辑状态管理：图片持久化、OCR、数据同步 |
| `LibraryListView` | JUSTIFIED | PJ-3.1 | 列表渲染组件：学科过滤头+无限滚动+长按多选 |
| `LibraryFilterSheet` | JUSTIFIED | PJ-3.2–3.3 | 多维过滤 UI：学科+标签选择 |
| `LibraryComponents` (SubjectCapsule) | JUSTIFIED | PJ-3.2 | 学科过滤胶囊 UI 组件 |
| `FullScreenImageView` | JUSTIFIED | PR「原图保存铁律」、PJ-3.4 | 全屏查看原图（捏合缩放+拖拽关闭） |
| `SubjectManagerView` | JUSTIFIED | PR「字段可配置系统：系统字段」、PJ-3.2 | 学科分类管理（增删改） |
| `SubjectManagerViewModel` | JUSTIFIED | 同上 | 学科 CRUD + 级联重命名 + 使用中保护 |
| `SourceManagerView` | JUSTIFIED | PR「字段可配置系统：系统字段」 | 来源分类管理 |
| `SourceManagerViewModel` | JUSTIFIED | 同上 | 来源 CRUD |
| `GradeManagerView` | JUSTIFIED | PR「字段可配置系统：系统字段」 | 年级分类管理 |
| `GradeManagerViewModel` | JUSTIFIED | 同上 | 年级 CRUD |
| `SFSymbolPickerView` | SHAPE_CONCERN | 无直接 PR 引用 | 为学科/来源选择图标。PR 字段可配置系统未提及图标定制，但 SubjectModel/SourceModel 有 icon 字段。功能合理但超出 PR 明确范围 |
| `ExportOptionsSheet` | JUSTIFIED | PR「功能边界：PDF 导出」、PJ-3.8 | 导出格式选择（PDF/Markdown/CSV） |
| `ExportPreviewView` | JUSTIFIED | PR「基础 PDF 导出」、PJ-3.8 | PDF 预览+分享/打印 |
| `PDFKitRepresentedView` | JUSTIFIED | PR「基础 PDF 导出」 | PDFView 的 UIViewRepresentable 封装 |
| `ReviewExport` | JUSTIFIED | PR「功能边界：PDF 导出」 | Transferable 数据模型（Markdown/CSV） |
| `ReviewExport.ExportFormat` | JUSTIFIED | PR「功能边界：PDF 导出」 | 导出格式枚举 |
| `ResolvedExportSheet` | JUSTIFIED | PR「基础 PDF 导出」 | ID→Snapshot 解析辅助组件 |
| `EditSubjectView` | JUSTIFIED | PR「字段可配置系统」 | 学科编辑 Sheet（SubjectManagerView 内部） |
| `EditSourceView` | JUSTIFIED | PR「字段可配置系统」 | 来源编辑 Sheet |
| `EditGradeView` | JUSTIFIED | PR「字段可配置系统」 | 年级编辑 Sheet |

### Library 验证小结

- **SFSymbolPickerView 需 Issue 追踪**：功能合理（学科图标选择提升辨识度），但 PR 未明确提及图标定制需求，属产品需求补全范畴
- **排序选项对齐**：4 个 LibrarySortOption 与旅程 3 排序需求一致

---

## 3. Review 模块（复习 — 锦上添花）

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `ReviewView` | JUSTIFIED | PJ-4.1、PR「功能边界：间隔重复复习」 | 复习主界面，状态机驱动（loading/idle/reviewing/finished） |
| `ReviewRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」、ADR-003 | FeatureRouter 协议实现，含跨 Tab 导航回调 |
| `ReviewDestination` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | 仅 `.placeholder`（FeatureRouter 协议要求） |
| `ReviewViewModel` | JUSTIFIED | PJ-4.2–4.7、PR「复习克制原则」 | SM-2 调度、卡片队列、undo/redo、会话统计 |
| `ReviewPhase` | JUSTIFIED | PJ-4.1–4.7 | 状态机枚举：loading→idle→reviewing→finished，对应旅程 4 的完整流程 |
| `SwipeCard` | JUSTIFIED | PJ-4.4「向右滑=记得，向左滑=不记得」 | 滑动手势容器，支持物理模拟+编程触发 |
| `FlipView` | JUSTIFIED | PJ-4.3「点击翻面看答案」、PR「原图保存铁律：卡片式翻转」 | 通用 3D 翻转容器（定义在 SnapDrillUI 包中） |
| `ReviewCardFront` | JUSTIFIED | PJ-4.2「正面=原题图文」 | 正面渲染：原图+OCR 文字+学科/难度/标签元数据 |
| `ReviewCardBack` | JUSTIFIED | PJ-4.3「背面=答案」 | 背面渲染：答案文字+答案图片 |
| `ReviewCardFactory` | SHAPE_CONCERN | — | 工厂枚举提供 `makeFront()`/`makeBack()` 静态方法。奥卡姆剃刀：仅 2 个方法，可内联到 ReviewView 中，但当前封装度合理且不增加文件数 |
| `ReviewActionButtons` | JUSTIFIED | PJ-4.4 | 底部评分按钮组（记得/不记得）+ 触觉反馈 |
| `ReviewProgressHeader` | JUSTIFIED | PJ-4.6「5 道题约 3 分钟过完」 | 顶部进度条：当前/总数 + 暂停按钮 |
| `ReviewDashboardView` | JUSTIFIED | PJ-4.1「Dashboard 显示待复习 5 题」 | Review Tab 的空闲态仪表盘（非 Dashboard Tab） |
| `ReviewSessionSummaryView` | JUSTIFIED | PJ-4.7「简单结果摘要」 | 复习结束摘要：掌握/待加强统计 |
| `ReviewEmptyStateView` | JUSTIFIED | PV-3「免费即门槛」（新用户无题目时的引导） | 空状态引导视图 |
| `ReviewBackground` | UNJUSTIFIED | — | 动态网格渐变背景动画。PR「复习克制原则」明确要求不过度渲染，纯装饰性动画无产品需求支撑 |
| `UndoEntry` | JUSTIFIED | — | 撤销栈条目（SM-2 状态回滚），属于复习流程的防错设计 |

### Review 验证小结

- **ReviewCardFactory**：SHAPE_CONCERN，封装度合理但非必要抽象，暂不需要改动
- **ReviewBackground**：UNJUSTIFIED，动态装饰动画与「复习克制原则」矛盾，建议评估移除
- **ReviewDashboardView vs DashboardView**：无功能重叠。ReviewDashboardView 是 Review Tab 内的空闲态显示（待复习数+开始按钮），DashboardView 是首页统计看板

---

## 4. Dashboard + Settings 模块

### 4.1 Dashboard

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `DashboardView` | JUSTIFIED | PJ-4.1「Dashboard 显示待复习 5 题」、PR「Dashboard 统计」 | 首页仪表盘：复习进度概览+快捷入口 |
| `DashboardViewModel` | JUSTIFIED | 同上 | 统计数据加载、数据变更监听、草稿恢复 |
| `DashboardRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」、ADR-003 | FeatureRouter 协议实现 |
| `DashboardDestination` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | 仅 `.placeholder` |
| `BentoCard` | JUSTIFIED | PR「Dashboard 统计」 | Bento 风格卡片容器（可交互/纯展示两种模式） |
| `ReviewHeroCard` | JUSTIFIED | PJ-4.1 | 复习核心卡片：三态（新用户引导/待复习/已完成） |
| `DailyStatsView` | JUSTIFIED | PR「Dashboard 统计」 | 今日新增/已复习/待复习统计 |
| `HeaderView` | JUSTIFIED | — | 仪表盘顶部标题栏（日期/问候语/头像），基础 UI 组成 |

### 4.2 Settings

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `SettingsView` | JUSTIFIED | PR「功能边界」（设置是基础功能） | 设置主页面 |
| `SettingsViewModel` | JUSTIFIED | PR「手动备份/恢复」、PB「数据迁移方案」 | 数据清除、备份/恢复 |
| `SettingsRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | FeatureRouter 协议实现 |
| `SettingsDestination` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | `placeholder`/`licenses`/`privacyPolicy`/`termsOfService` |
| `DataAndSyncSettingsView` | JUSTIFIED | PB「免费版体验完整性保障」、PR「手动备份/恢复」 | 数据导出、备份/恢复、缓存清理 |
| `NotificationSettingsView` | JUSTIFIED | PR「复习克制原则：默认不推送，用户可开启」 | 每日复习提醒开关+时间配置 |
| `NotificationSettingsViewModel` | JUSTIFIED | 同上 | 权限请求+调度逻辑 |
| `PrivacySettingsView` | JUSTIFIED | PB「隐私策略」、PV-4「数据属于用户」 | 分析开关、数据导出（JSON/CSV） |
| `PrivacyPolicyView` | JUSTIFIED | App Store 审核要求（必须有隐私政策） | 隐私政策展示 |
| `TermsOfServiceView` | JUSTIFIED | App Store 审核要求 | 服务条款展示 |
| `EditProfileView` | JUSTIFIED | PV-4「私有化」 | 本地个人资料（昵称/头像/座右铭）。不收集个人信息≠不允许本地个性化，数据纯本地存储不外传 |
| `LanguageSettingsView` | SHAPE_CONCERN | PR「多语言支持为长期目标」 | 当前仅引导用户到系统设置。功能极轻量（~20 行），不属 PREMATURE（未实现多语言切换逻辑），但长期不会有变化 |
| `ReviewAppearanceSettingsView` | SHAPE_CONCERN | 无 PR 引用 | 复习卡片正面/背面对齐方式+字体大小自定义。PR 未提及卡片外观定制，但属于无害的打磨类设置 |
| `LicenseView` | JUSTIFIED | App Store 审核 + 开源许可义务 | 展示 Mantis、Firebase SDK 许可证 |
| `LicenseDetailView` | JUSTIFIED | 同上 | 单个许可证详情页 |
| `SettingsRow` | JUSTIFIED | — | 设置页通用行组件（内部 UI） |
| `LocalDataWarningView` | JUSTIFIED | PB「用户须知：卸载=数据丢失」 | iCloud 关闭时的数据风险提示 |
| `ExportableItem` | JUSTIFIED | PV-4「支持导出」 | 跨 actor 数据导出 DTO |
| `DataExporter` | JUSTIFIED | PV-4「支持导出」 | JSON/CSV 导出 actor |
| `PrivacyDataExportFormat` | JUSTIFIED | PV-4 | 导出格式枚举 |
| `ExportError` | JUSTIFIED | — | 导出错误类型 |
| `ShareSheet` | JUSTIFIED | — | 系统分享工作表（UIKit 集成） |

### Settings 验证小结

- **EditProfileView 与隐私**：不矛盾。「不收集个人信息」= 不上传到服务器。本地昵称/头像是私有化个性定制
- **LanguageSettingsView**：SHAPE_CONCERN，当前仅系统设置跳转，实现极轻量，保留无害
- **ReviewAppearanceSettingsView**：SHAPE_CONCERN，PR 未提及但属于合理的打磨功能

---

## 5. Core 服务层

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `OCRService` | JUSTIFIED | PR「OCR 定位」、PV-1 | Apple Vision 端上 OCR（actor 隔离） |
| `OCRServiceProtocol` | ARCH_JUSTIFIED | ADR-004（DI 模式） | 跨包服务协议，测试可替换 |
| `OCRError` | JUSTIFIED | — | OCR 错误类型 |
| `ImageStorage` | JUSTIFIED | PR「原图保存铁律」 | 图片压缩+文件 I/O |
| `ImageStorageError` | JUSTIFIED | — | 图片存储错误类型 |
| `PDFExportService` | JUSTIFIED | PR「基础 PDF 导出」、PJ-3.8 | PDF 生成服务 |
| `PDFExportable` | ARCH_JUSTIFIED | ADR-004 | PDF 导出内容协议 |
| `CaptureDraftService` | JUSTIFIED | PJ-1.6–1.7（连续录入中断恢复） | 草稿持久化（防止意外丢失） |
| `CaptureDraftServiceProtocol` | ARCH_JUSTIFIED | ADR-004 | 跨包服务协议 |
| `CaptureDraftService.Draft` | JUSTIFIED | — | 草稿数据结构 |
| `ReviewScheduler` | JUSTIFIED | PR「功能边界：间隔重复复习」、ADR-007 | SM-2 调度引擎 |
| `SM2State` | JUSTIFIED | ADR-007 | SM-2 算法状态值类型 |
| `ReviewRating` | JUSTIFIED | PJ-4.4 | 评分枚举：again/hard/good/easy |
| `Difficulty` | JUSTIFIED | PR「字段可配置系统：难度」 | 难度枚举（1-5 星） |
| `AnalyticsServiceProtocol` | ARCH_JUSTIFIED | ADR-004、ADR-005 | 分析服务协议（Infrastructure 隔离） |
| `AnalyticsServiceMock` | DEV_TOOL | — | 测试/Preview 用 Mock |
| `AnalyticsEvent` | SHAPE_CONCERN | — | 见下方逐 case 分析 |
| `NotificationServiceProtocol` | JUSTIFIED | PR「复习克制原则：用户可开启提醒」 | 通知服务协议 |
| `NotificationServiceMock` | DEV_TOOL | — | 测试用 Mock |
| `LiveNotificationService` | JUSTIFIED | PR「复习克制原则」 | UNUserNotificationCenter 封装 |
| `PrivacyConsentService` | JUSTIFIED | PB「隐私策略」 | ATT 授权管理 |
| `ServiceContainer` | ARCH_JUSTIFIED | ADR-004（DI 模式） | 服务容器协议 |
| `LiveServiceContainer` | ARCH_JUSTIFIED | ADR-004 | 生产环境服务容器 |
| `MockServiceContainer` | DEV_TOOL | ADR-004 | 测试/Preview 服务容器 |
| `ServiceContainerKey` | ARCH_JUSTIFIED | ADR-004 | SwiftUI Environment Key |
| `AnalyticsServiceKey` | ARCH_JUSTIFIED | ADR-004 | SwiftUI Environment Key |
| `AppConfiguration` | JUSTIFIED | — | 应用配置（版本号、环境判断） |
| `AppConfiguration.Environment` | JUSTIFIED | — | 环境枚举（dev/staging/prod） |
| `AppConfiguration.FeatureFlags` | SHAPE_CONCERN | — | 见下方逐 flag 分析 |
| `RemoteConfigurable` | ARCH_JUSTIFIED | ADR-005（Infrastructure 隔离） | 远程配置协议 |
| `SnapDrillLogger` | JUSTIFIED | conventions.md「日志」 | os.Logger 封装 |
| `SnapDrillError` | JUSTIFIED | — | 通用错误类型（dataNotFound/captureFailed/unknown） |
| `Notification.Name` 扩展 | JUSTIFIED | PJ-1.6（数据变更通知）、ARCH「Tab 切换」 | 4 个通知名常量 |
| `UDKey` | SHAPE_CONCERN | — | 见下方逐 key 分析 |
| `L10n` | JUSTIFIED | — | 本地化键常量（国际化基础设施） |
| `Collection[safe:]` | JUSTIFIED | — | 安全下标（防 crash） |
| `Color.init(hex:)` | JUSTIFIED | — | 十六进制颜色（学科/来源的 colorHex 字段） |
| `Date.relativeDescription` | JUSTIFIED | — | 中文相对时间描述（UI 显示用） |

### AnalyticsEvent 逐 case 分析

| Case | 判定 | 追溯 |
|---|---|---|
| `appLaunched` | JUSTIFIED | 基础启动指标 |
| `reviewItemCreated` | JUSTIFIED | PJ-1.6 保存时触发 |
| `reviewItemCompleted` | JUSTIFIED | PJ-4.4 复习评分时触发 |
| `reviewSessionStarted` | JUSTIFIED | PJ-4.1 开始复习时触发 |
| `reviewSessionCompleted` | JUSTIFIED | PJ-4.7 复习结束时触发 |
| `screenViewed` | JUSTIFIED | 标准页面浏览追踪 |
| `sessionStarted` | JUSTIFIED | App 会话开始 |
| `sessionEnded` | JUSTIFIED | App 会话结束 |
| `cameraOpened` | JUSTIFIED | PJ-1.2 相机打开时触发 |
| `captureSaved` | JUSTIFIED | PJ-1.6 保存时触发 |
| `ocrPerformed` | JUSTIFIED | PJ-1.4 OCR 完成时触发 |
| `pdfExported` | JUSTIFIED | PJ-3.8 PDF 导出时触发 |
| `dataExported` | JUSTIFIED | PV-4 数据导出时触发 |
| `icloudSyncStarted` | PREMATURE | iCloud 同步属 v2.0（PB「付费模式」） |
| `icloudSyncCompleted` | PREMATURE | 同上 |
| `icloudSyncFailed` | PREMATURE | 同上 |
| `errorOccurred` | JUSTIFIED | 错误监控 |

### AppConfiguration.FeatureFlags 逐 flag 分析

| Flag | 判定 | 追溯 |
|---|---|---|
| `crashReportingEnabled` | JUSTIFIED | Firebase Crashlytics SDK 自动收集开关（CrashReportingService 已删除，flag 直接控制 SDK 行为） |
| `analyticsEnabled` | JUSTIFIED | PB「隐私策略」用户可控 |
| `iCloudSyncEnabled` | PREMATURE | iCloud 同步属 v2.0 |
| `isEmergencyKillSwitchActive` | JUSTIFIED | 远程 kill-switch，运维必要 |

### UDKey 逐组分析

| 组 | 判定 | 追溯 |
|---|---|---|
| User Profile (userName, userAvatar, userAvatarColorIndex, userMotto) | JUSTIFIED | EditProfileView 的本地存储 |
| Appearance (appearanceMode, appTintColor) | JUSTIFIED | 设置页外观主题 |
| Review Card Appearance (cardFrontAlignment 等 4 个) | SHAPE_CONCERN | ReviewAppearanceSettingsView 配套，PR 未明确提及 |
| Capture Field Visibility (captureFieldSubject 等 5 个) | JUSTIFIED | PR「字段可配置系统：设置中开关」 |
| Last Selection (lastSelectedSubject, lastSelectedSource) | JUSTIFIED | PR「自动推断」 |
| Feature Flags (analyticsEnabled 等 3 个) | JUSTIFIED / PREMATURE | iCloudSyncEnabled 属 PREMATURE |
| Review Settings (dailyReviewGoal 等 3 个) | JUSTIFIED | PR「复习克制原则」+通知设置 |
| Notification Settings (4 个) | JUSTIFIED | PR「复习克制原则：用户可开启通知」 |
| Data & Sync (autoDeleteOldItems, autoDeleteDays) | SHAPE_CONCERN | PR 未提及自动删除旧题目 |
| Privacy (privacyConsentRequested) | JUSTIFIED | PB「隐私策略」 |
| Draft Service (captureDraftMetadata) | JUSTIFIED | CaptureDraftService 配套 |
| Onboarding (hasCompletedOnboarding, hasShownTooltipPrefix) | JUSTIFIED | PR「引导阶段」 |

---

## 6. Data 层 + UI 组件 + Infrastructure

### 6.1 Data 层

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `ReviewItemModel` | JUSTIFIED | PR「字段可配置系统」、ADR-001 | @Model 直接作领域对象。字段与 PR 字段表一一对应 |
| `TagModel` | JUSTIFIED | PR「用户自定义标签」、PJ-3.6 | 多对多关系 |
| `SubjectModel` | JUSTIFIED | PR「字段可配置系统：学科默认开启」 | 含 icon/color 字段 |
| `SourceModel` | JUSTIFIED | PR「字段可配置系统：来源默认关闭」 | 含 icon/color 字段 |
| `GradeModel` | JUSTIFIED | PR「字段可配置系统：年级默认关闭」 | — |
| `ReviewRepository` | JUSTIFIED | ARCH「数据流」、ADR-002 | 无协议，测试用 in-memory ModelContainer |
| `SubjectRepository` | JUSTIFIED | 同上 | 含 seedDefaultsIfNeeded、级联更新 |
| `SourceRepository` | JUSTIFIED | 同上 | — |
| `GradeRepository` | JUSTIFIED | 同上 | — |
| `TagRepository` | JUSTIFIED | 同上 | fetch-or-create 语义 |
| `RepositoryContainer` | ARCH_JUSTIFIED | ADR-004（DI 模式） | 聚合所有 Repository + 原子删除/备份 |
| `PreviewRepositoryContainer` | DEV_TOOL | — | SwiftUI Preview 用 in-memory 容器 |
| `ReviewExportSnapshot` | JUSTIFIED | PR「基础 PDF 导出」 | @Model → Transferable 桥接 DTO |
| `PersistenceController` | ARCH_JUSTIFIED | ADR-006（SwiftData 选型） | ModelContainer 生命周期管理 |
| `DataError` | JUSTIFIED | — | 数据层错误类型（6 个 case 均有明确使用场景） |
| `PersistenceError` | SHAPE_CONCERN | — | 4 个 case 中 `cloudKitConfigurationError` 属 PREMATURE（v2.0） |
| `BackupService` | JUSTIFIED | PR「手动备份/恢复」、PB「数据迁移方案」 | .snapdrill ZIP 文件创建/解析 |
| `BackupError` | JUSTIFIED | — | 备份错误类型 |
| `BackupManifest` | JUSTIFIED | PR「手动备份/恢复」 | 备份元数据 |
| `BackupPayload` | JUSTIFIED | 同上 | 全量数据 DTO |
| `ReviewItemBackupDTO` | JUSTIFIED | 同上 | 序列化 DTO |
| `SubjectBackupDTO` | JUSTIFIED | 同上 | — |
| `SourceBackupDTO` | JUSTIFIED | 同上 | — |
| `GradeBackupDTO` | JUSTIFIED | 同上 | — |
| `TagBackupDTO` | JUSTIFIED | 同上 | — |
| `SnapDrillSchemaV1` | ARCH_JUSTIFIED | ADR-006 | SwiftData 版本化 Schema |
| `SnapDrillSchemaV2` | ARCH_JUSTIFIED | ADR-006 | 非可选 Date 迁移 |
| `SnapDrillMigrationPlan` | ARCH_JUSTIFIED | ADR-006 | 轻量迁移计划 |
| `DataSeeder` | DEV_TOOL | — | 测试数据生成器 |

### ReviewItemModel 字段 vs PR 字段可配置系统

| PR 字段 | Model 字段 | 对齐 |
|---|---|---|
| 题目内容（文字/图片）— 固定 | `content`, `imagePath` | ✅ |
| 学科 — 默认开启 | `subjectRawValue` | ✅ |
| 难度 — 默认关闭 | `difficulty` | ✅ |
| 来源 — 默认关闭 | `sourceRawValue` | ✅ |
| 年级 — 默认关闭 | `grade` | ✅ |
| 答案 — 默认关闭 | `answerText`, `answerImagePath` | ✅ |
| 自定义标签 — 始终可用 | `tags: [TagModel]?` | ✅ |
| SM-2 状态 | `easeFactor`, `interval`, `repetitions`, `nextReviewAt`, `lastReviewedAt` | ✅（算法内部，非用户可见字段） |

### 6.2 UI 组件

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `SnapDrillButton` | JUSTIFIED | — | 设计系统基础组件 |
| `FlipView` | JUSTIFIED | PJ-4.3、PR「原图保存铁律：FlipView」 | 通用翻转容器 |
| `TagInputView` | JUSTIFIED | PR「用户自定义标签」、PJ-3.6 | 标签输入+历史建议 |
| `ImageCropperView` | JUSTIFIED | PJ-1.3「裁剪」、PR「一图一题手动裁剪」 | Mantis 库封装 |
| `TabItem` | JUSTIFIED | PR「采集入口设计：底部 Tab 栏常驻」 | 5 个 Tab 定义 |
| `FeatureRouter` | ARCH_JUSTIFIED | ARCH「Feature 结构」 | 导航协议 |
| `OnboardingView` | JUSTIFIED | PR「字段可配置系统：引导阶段」 | 首次启动引导 |
| `OnboardingPage` | JUSTIFIED | 同上 | 引导页数据模型 |
| `OnboardingManager` | JUSTIFIED | 同上 | 引导状态持久化 |
| `FeatureTooltip` | JUSTIFIED | PR「引导阶段」 | 功能提示气泡 |
| `AppError` | SHAPE_CONCERN | — | 逐 case 见下 |
| `ContextualErrorView` | JUSTIFIED | — | 全屏错误展示（基础 UX 组件） |
| `ErrorBannerView` | JUSTIFIED | — | 内联错误横幅 |
| `ErrorMessageView` | JUSTIFIED | — | 通用错误消息 |
| `LoadingView` | JUSTIFIED | — | 加载指示器 |
| `ProgressLoadingView` | JUSTIFIED | PR「手动备份/恢复」（进度指示） | 确定/不确定进度 |
| `SkeletonLoadingView` | JUSTIFIED | — | 列表骨架屏 |
| `HelpTopic` | JUSTIFIED | PR「引导与帮助：帮助中心」 | 帮助分类数据模型 |
| `HelpQuestion` | JUSTIFIED | PR「引导与帮助：帮助中心」 | 帮助问答数据模型 |
| `HelpView` | JUSTIFIED | PR「引导与帮助：帮助中心」 | 帮助中心主视图（FAQ 分类+搜索） |
| `QuickHelpCard` | JUSTIFIED | PR「引导与帮助：帮助中心」 | 帮助快捷卡片 |
| `AccessibilityHelper` | JUSTIFIED | Apple 审核 + 无障碍合规 | VoiceOver 辅助工具 |
| `AccessibilityAnnouncement` | JUSTIFIED | 同上 | VoiceOver 公告 |
| `AccessibilityNotificationPriority` | JUSTIFIED | 同上 | 公告优先级 |
| `PrivacyPrePromptView` | JUSTIFIED | PB「隐私策略」 | ATT 预提示 |

### AppError 逐 case 分析

| Case | 判定 | 追溯 |
|---|---|---|
| `networkUnavailable` | PREMATURE | v1.0 纯本地，无网络依赖 |
| `iCloudUnavailable` | PREMATURE | iCloud 同步属 v2.0 |
| `cameraPermissionDenied` | JUSTIFIED | PR「录入方式 P0：摄像头拍照」 |
| `photoLibraryPermissionDenied` | JUSTIFIED | PR「录入方式 P0：相册导入」 |
| `ocrFailed(String)` | JUSTIFIED | PR「OCR 定位」 |
| `exportFailed(String)` | JUSTIFIED | PR「基础 PDF 导出」 |
| `importFailed(String)` | JUSTIFIED | PR「手动备份/恢复」 |
| `dataCorrupted` | JUSTIFIED | S0 数据丢失防护 |
| `unknown(Error)` | JUSTIFIED | 兜底错误 |

### 6.3 Infrastructure

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `FirebaseBootstrap` | ARCH_JUSTIFIED | ADR-005（Infrastructure 隔离） | Firebase 初始化入口 |
| `FirebaseAnalyticsService` | ARCH_JUSTIFIED | ADR-005 | Firebase Analytics 实现 |
| `FirebaseRemoteConfigService` | ARCH_JUSTIFIED | ADR-005 | Firebase Remote Config 实现 |

### 6.4 App Shell

| 类型 | 判定 | 追溯 | 备注 |
|---|---|---|---|
| `DependencyContainer` | ARCH_JUSTIFIED | ADR-004（唯一单例组合根） | 构造所有实例 |
| `AppRouter` | JUSTIFIED | PR「采集入口设计：底部 Tab 栏」 | 一级 Tab 管理+跨 Tab 导航 |
| `AppTab` | JUSTIFIED | PR「采集入口设计」 | 5 个 Tab 枚举 |
| `AppRootView` | JUSTIFIED | — | 应用根视图 |
| `SnapDrillApp` | JUSTIFIED | — | @main 入口 |

---

## 7. 汇总统计

### 按判定分类

| 判定 | 数量 | 占比 |
|---|---|---|
| JUSTIFIED | ~109 | ~77% |
| ARCH_JUSTIFIED | ~22 | ~16% |
| DEV_TOOL | 5 | ~4% |
| PREMATURE | 9 | ~6% |
| SHAPE_CONCERN | 7 | ~5% |
| UNJUSTIFIED | 1 | ~1% |

> 注：部分类型兼有多个判定（如 AnalyticsEvent 中个别 case 为 PREMATURE），按主要判定归类。

### PREMATURE 清单（需 Issue 追踪）

| 类型/字段 | 对应版本 | 行动 |
|---|---|---|
| `PDFPagePickerView` + `PDFThumbnailCache` + `PDFThumbnailView` | v1.5 | 功能已完整实现，保留但标记为 v1.5 提前完成 |
| `AnalyticsEvent.icloudSync*` (3 个 case) | v2.0 | 保留枚举值，当前无触发点 |
| `FeatureFlags.iCloudSyncEnabled` | v2.0 | UDKey 已存在，当前仅 UI 开关无实际功能 |
| `UDKey.iCloudSyncEnabled` | v2.0 | 同上 |
| `AppError.networkUnavailable` | v2.0 | 无使用场景 |
| `AppError.iCloudUnavailable` | v2.0 | 无使用场景 |
| `PersistenceError.cloudKitConfigurationError` | v2.0 | 无使用场景 |

### UNJUSTIFIED 清单（需评估移除）

| 类型 | 行动建议 |
|---|---|
| `ReviewBackground` | 评估移除：动态渐变动画与「复习克制原则」矛盾，且消耗 GPU |

### SHAPE_CONCERN 清单（需产品确认）

| 类型 | 关注点 |
|---|---|
| `SFSymbolPickerView` | PR 未提及图标定制，但 Model 已有 icon 字段 |
| `ReviewCardFactory` | 奥卡姆剃刀：仅 2 个静态方法，可内联 |
| `LanguageSettingsView` | 仅系统设置跳转，极轻量 |
| `ReviewAppearanceSettingsView` + 4 个 UDKey | PR 未提及卡片外观定制 |
| `UDKey.autoDeleteOldItems/autoDeleteDays` | PR 未提及自动删除功能 |

---

## 维护指南

1. **新增 public 类型**时，在对应模块章节添加行，填写判定和追溯引用
2. **删除 public 类型**时，从对应章节移除
3. **PREMATURE → JUSTIFIED**：当对应版本开始开发时，更新判定
4. **UNJUSTIFIED**：创建 Issue 后在备注栏标注 Issue 编号
5. 每次架构审查后更新「汇总统计」章节

---

## 8. Issue 追踪

| Issue | 判定 | 涉及类型 |
|---|---|---|
| [#283](https://github.com/NotBad-Labs/snapdrill-ios/issues/283) | UNJUSTIFIED | ReviewBackground |
| [#284](https://github.com/NotBad-Labs/snapdrill-ios/issues/284) | ~~UNJUSTIFIED~~ → JUSTIFIED | HelpView / HelpTopic / HelpQuestion / QuickHelpCard（PR「引导与帮助：帮助中心」已定义，原判定有误） |
| [#285](https://github.com/NotBad-Labs/snapdrill-ios/issues/285) | PREMATURE | iCloud/网络相关枚举值和错误 case（6 项） |
| [#286](https://github.com/NotBad-Labs/snapdrill-ios/issues/286) | SHAPE_CONCERN | SFSymbolPickerView / ReviewAppearanceSettingsView / ReviewCardFactory / autoDelete UDKeys / LanguageSettingsView |

---

## 9. infrastructure.md 审计发现

| 发现 | 严重度 | 状态 |
|---|---|---|
| `L10n`（本地化键枚举）未记录 | 低 | 构建时生成的类型，非手写 API，可不记录 |
| `LiveNotificationService` 缺少独立文档段落 | 低 | 在 LiveServiceContainer init 注释中已提及 |
| `NotificationServiceMock` 未记录 | 低 | DEV_TOOL，可选记录 |

结论：infrastructure.md 当前内容准确，无需紧急修正。
