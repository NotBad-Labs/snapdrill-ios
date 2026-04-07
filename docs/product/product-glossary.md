# SnapDrill 术语表

> 本文件是产品文档体系的术语唯一来源（Single Source of Truth）。
> 所有产品文档、技术文档、AI 规则和代码命名应遵循本表定义。
> 如需新增或修改术语，在本文件更新后同步下游文档。

---

## 核心价值链

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **采集** | Capture | 从外部载体（相机/相册/PDF/剪贴板）获取题目图片并进入录入流程的全过程 | `SnapDrillFeatureCapture` (Features) |
| **录入** | Create / Save | 完成题目编辑（OCR 文本、答案、分类、标签）并保存到题库的动作 | `CaptureResultViewModel.save()` (Features) |
| **题库** | Library | 已保存题目的集合，支持浏览、搜索、过滤、编辑、导出 | `SnapDrillFeatureLibrary` (Features) |
| **导出** | Export | 将题目数据从 App 输出为外部格式（PDF/JSON/CSV/ZIP/分享卡片） | `ExportOptionsSheet` (Features) |
| **打印** | Print | 导出 PDF 后通过系统打印服务输出到纸质 | `PDFExportService` (Core) |
| **复习** | Review | 基于 SM-2 间隔重复算法的卡片式复习会话 | `SnapDrillFeatureReview` (Features) |

**价值链完整表述**：采集 → 管理（题库浏览/编辑/分类） → 导出/打印。复习是独立附加值，不在价值链内

---

## 用户与数据

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Profile** | Profile | 独立的用户档案，每个 Profile 拥有独立的题库、复习进度、字段配置和统计数据 | `Profile` struct (Core), `ProfileManager` (Data) |
| **基线用户** | Baseline User | 35 岁妈妈（零技术背景），所有设计决策以此用户能否顺利完成为最低标准 | — |
| **图片是真相** | Image is Truth | 当 OCR 文本与原图冲突时，以原图为准。原图是题目数据的唯一真相源 | `ReviewItemModel.imagePath` (Data) |
| **.snapdrill** | .snapdrill | App 专属备份文件格式（ZIP 内含 JSON 数据 + 图片文件） | `BackupService` (Data) |

---

## 功能与技术

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **SM-2** | SM-2 Algorithm | SuperMemo 2 间隔重复调度算法，计算每道题的下次复习时间 | `ReviewScheduler` (Core) |
| **字段配置** | Field Configuration | 用户在设置中开关学科/难度/来源/年级/答案等录入字段 | `SettingsView` captureFields (Features) |
| **连续录入** | Continuous Capture | 保存一道题后自动回到相机界面，支持批量录入不中断 | `CaptureRouter` (Features) |
| **软删除** | Soft Delete | 5 秒 Toast 撤销窗口内的临时删除状态，超时后执行真实删除 | `LibraryViewModel.softDeleteItems()` (Features) |

---

## 界面与交互

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Dashboard** | Dashboard | 首屏状态总览界面，展示当前 Profile 的题库统计（总题数、待复习数）、待复习快捷入口和用户问候语 | `DashboardView` (Features) |
| **Onboarding** | Onboarding | 首次启动多页引导流程（3-4 页），介绍核心功能（采集/复习/导出），完成后不再显示 | `OnboardingView` (UI) |
| **复习卡片** | Review Card | 正反面翻转式卡片，正面展示题目（图文），背面展示答案。用户通过滑动或按钮评估掌握程度 | `ReviewCardContent` (Features) |
| **标签** | Tag | 用户自定义的题目分类维度（如"易错""考前"），支持多选过滤和批量操作 | `TagModel` (Data), `TagRepository` (Data) |
| **Profile 切换** | Profile Switch | 用户在多个独立题库间切换，各 Profile 拥有独立数据库和统计 | `ProfileManager.switchProfile()` (Data) |

---

## 流程与方法

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **PoC** | Proof of Concept | 功能正式纳入前的验证阶段，需满足预定义的 Go/No-Go 条件 | — |
| **S0-S3** | Severity Level | 缺陷严重度分级：S0 数据不可逆丢失 > S1 流程阻断 > S2 有摩擦 > S3 不紧急 | — |
| **DoD** | Definition of Done | PR 合并前检查清单（lint/build/review/文档同步），定义在 `docs/workflow.md` | — |

---

## 商业化

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **免费层** | Free Tier | 全部基础功能，单设备完整体验（采集 → 管理 → 导出/打印） | — |
| **Pro** | Pro Subscription | 付费订阅层（iCloud 同步/图片处理增强（免费限次体验）/智能组卷/Word 导出/高级统计等增值能力） | — |
| **Grandfather** | Grandfather Pricing | 老用户保留原价的涨价策略 | — |
