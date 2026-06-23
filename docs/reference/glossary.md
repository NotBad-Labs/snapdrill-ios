---
last_verified: 2026-06-22
layer: pattern
---
# SnapDrill 术语表

> 产品术语参考表。新增或修改术语时在本文件更新后同步下游文档。
> PR Review 时通过 DoD checklist 检查术语一致性（见下方 DoD 定义）。
> 本表同时记录对外推荐术语与内部模型/代码术语。面向用户、ASO、官网和发布材料时优先使用“资料 / 资料库 / 回顾”等通用受众语言；内置 taxonomy 契约以本表“字段配置”条目为准。

---

## 核心概念

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **采集** | Capture | 从外部载体（相机/相册/PDF/剪贴板文本/Share Extension）获取题目内容并进入录入流程的全过程 | `SnapDrillFeatureCapture` 模块 (Features) |
| **录入** | Create / Save | 完成资料项编辑（OCR 文本、答案/备注、分类、标签）并保存到资料库的动作 | `CaptureResultViewModel` 模块 (Features) |
| **资料库** | Library | 已保存资料项的集合，支持浏览、搜索、过滤、编辑、导出。代码与部分内部 spec 仍使用 `Library` / “题库”指代同一功能域 | `SnapDrillFeatureLibrary` 模块 (Features) |
| **管理** | Management | 价值链中间环节：资料库浏览、编辑、分类、标签、搜索、过滤等整理操作的统称 | `SnapDrillFeatureLibrary` 模块 (Features) |
| **导出** | Export | 将资料数据从 App 输出为外部格式。资料库导出：PDF/CSV/ZIP/分享卡片；隐私数据导出：JSON（设置→隐私） | `ExportOptionsSheet` (Features)；隐私导出见 `PrivacySettingsView` (Features) |
| **打印** | Print | 导出 PDF 后通过系统打印服务输出到纸质 | `ExportPreviewView` (Features) 提供打印入口，依赖 `PDFExportService` (Core) 生成 PDF |
| **回顾** | Review | 基于 SM-2 间隔重复算法的卡片式回顾会话。代码 target 仍为 `FeatureReview` | `SnapDrillFeatureReview` 模块 (Features) |

**价值链完整表述**：核心价值链为采集 → 管理（资料库浏览/编辑/分类） → 导出/打印。回顾是可选留存层，智能组卷是导出/打印的 Pro 增值延伸。

---

## 用户与数据

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Profile** | Profile | 独立的本地资料库 / 工作区，每个 Profile 拥有独立的资料库、回顾进度、字段配置和统计数据 | `Profile` struct (Core), `ProfileManager` (Data) |
| **基线用户** | Baseline User | 不熟悉专业扫描 / 归档工具的成年用户（假设，待首批用户画像验证，见 `../explanations/assumptions.md` H1）。所有设计决策以此用户能否顺利完成为最低标准 | — |
| **图片是真相** | Image is Truth | 当 OCR 文本与原图冲突时，以原图为准。原图是资料项的唯一真相源 | `ArchiveItemModel.imagePath` (Data) |
| **.zip 备份** | .zip Backup | App 备份文件格式（ZIP 内含 JSON 数据 + 图片文件） | `BackupService` (Data) |

---

## 功能与技术

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **OCR** | Optical Character Recognition | Apple Vision 端上光学字符识别，用于生成搜索索引和可复制文本。原图是真相，OCR 是辅助 | `CaptureViewModel` (Features) |
| **SM-2** | SM-2 Algorithm | SuperMemo 2 间隔重复调度算法，计算每个资料项的下次回顾时间 | `ReviewScheduler` (Core) |
| **字段配置** | Field Configuration | 用户在分类管理中按需开关分类、来源、级别、标签等录入维度。当前 canonical 内置维度 key 为 `category` / `source` / `level` / `tag`；`category` 是主分类维度，不等同于整个 `CategoryDimensionModel` 维度系统；`level` 是通用层级/阶段字段，不默认表达学习年龄段。 | `CategorySystemKey`, `CategoryDimensionModel.defaultCaptureVisibility`, `CategoryValueListViewModel.isVisibleInCapture` |
| **连续录入** | Continuous Capture | 保存一项资料后自动回到相机界面，支持批量录入不中断 | `CaptureRouter` (Features) |
| **软删除** | Soft Delete | 5 秒 Toast 撤销窗口内的临时删除状态，超时后执行真实删除 | `LibraryViewModel.softDeleteItems()` (Features) |

---

## 界面与交互

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Dashboard** | Dashboard | 首屏状态总览界面，展示当前 Profile 的资料统计（总数、待回顾数）、回顾快捷入口和用户问候语 | `DashboardView` (Features) |
| **Onboarding** | Onboarding | 首次启动多页引导流程（3-4 页），介绍核心功能（采集/回顾/导出），完成后不再显示 | `OnboardingView` (UI) |
| **回顾卡片** | Review Card | 正反面翻转式卡片，正面展示资料内容（图文），背面展示答案/备注。用户通过滑动或按钮评估掌握程度 | `ReviewCardFront` / `ReviewCardBack` (Features) |
| **标签** | Tag | 多选资料分类维度（如"重点""考前"），支持过滤和批量操作 | `CategorySystemKey.tag`, `CategoryValueModel` (Data) |
| **Profile 切换** | Profile Switch | 用户在多个独立资料库间切换，各 Profile 拥有独立数据库和统计 | `ProfileManager.switchProfile(to:)` (Data) |

---

## 流程与方法

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **PoC** | Proof of Concept | 功能正式纳入前的验证阶段，需满足预定义的 Go/No-Go 条件 | — |
| **S0-S3** | Severity Level | 缺陷严重度分级：S0 数据不可逆丢失 > S1 流程阻断 > S2 有摩擦 > S3 不紧急 | — |
| **DoD** | Definition of Done | PR 合并前检查清单（lint/build/review/文档同步，见 AGENTS.md §DoD） | — |

---

## 商业化

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **免费层** | Free Tier | 全部基础功能，单设备完整体验（采集 → 管理 → 导出/打印） | — |
| **Pro** | Pro Subscription | 付费订阅层：iCloud 同步 / 图片处理增强 / 智能组卷（无限+精准选题）/ Word 导出 / 高级统计（趋势图+薄弱排行）等增值能力。智能组卷和图片处理增强采用"免费限次体验 + Pro 无限"模式（ADR-001）。**Pro 功能现状**：智能组卷无限 / 高级统计深度 / iCloud 同步 / Word 导出 / 图片处理增强等的实现状态以 `feature-status.md`§功能状态总表（SSOT）为准。当前 StoreKit（#479）未接、Pro 全为"敬请期待"占位、首版纯免费；**Pro 体系为愿景/路线，非当前 shipping**。 | — |
| **Grandfather** | Grandfather Pricing | 老用户保留原价的涨价策略 | — |
| **Lifetime** | Lifetime Purchase | 一次性买断 Pro 全部功能，永久有效，不受后续涨价影响 | — |

---

## 相关文档

| 文档 | 关系 | 说明 |
|---|---|---|
| `../explanations/vision.md` | 上游 | 术语的定义来源 |
| `../explanations/design-principles.md` | 相关 | 部分术语在设计决策中定义 |
| `../explanations/business-model.md` | 相关 | 商业化术语 |
