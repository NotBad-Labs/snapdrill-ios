---
last_verified: 2026-07-24
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
| **采集** | Capture | 从外部载体（相机/相册/PDF/剪贴板文本/Share Extension）获取资料内容并进入录入流程的全过程 | `SnapDrillFeatureCapture` 模块 (Features) |
| **资料** | Material / Item | 用户保存和管理的单条内容，可能包含图片、OCR 文本、答案/备注、分类、标签与回顾状态。PO 2026-07-05 裁决：通用资料系界面中，“题目”统一改为“资料”。 | `ArchiveItemModel` (Data) |
| **录入** | Create / Save | 完成资料项编辑（OCR 文本、答案/备注、分类、标签）并保存到资料库的动作 | `CaptureResultViewModel` 模块 (Features) |
| **资料库** | Library | 已保存资料项的集合，支持浏览、搜索、过滤、编辑、导出。PO 2026-07-05 裁决：用户可见容器统一称“资料库”；代码与部分内部 spec 仍使用 `Library` 指代同一功能域。 | `SnapDrillFeatureLibrary` 模块 (Features) |
| **整理 / 找回** | Organize / Retrieve | 核心价值链中间环节：资料库浏览、编辑、分类、标签、搜索和过滤等操作 | `SnapDrillFeatureLibrary` 模块 (Features) |
| **导出** | Export | 将资料数据从 App 输出为外部格式。资料库导出：PDF/CSV/`.snapdrillbackup`/分享卡片；隐私数据导出：JSON（设置→隐私） | `ExportOptionsSheet` (Features)；隐私导出见 `PrivacySettingsView` (Features) |
| **打印** | Print | 导出 PDF 后通过系统打印服务输出到纸质 | `ExportPreviewView` (Features) 提供打印入口，依赖 `PDFExportService` (Core) 生成 PDF |
| **回顾** | Review | 基于 SM-2 间隔重复算法的卡片式回顾会话。代码 target 仍为 `FeatureReview` | `SnapDrillFeatureReview` 模块 (Features) |

**价值链完整表述**：核心价值链为采集 → 整理 / 找回 → 导出 / 打印。回顾与 SmartPaper 是可选复用能力，不得占据或复杂化主路径；当前不存在有效 Pro 分层。

---

## 用户与数据

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Profile（当前实现遗留）** | Profile / Workspace | 当前代码中的多资料库容器。Product Constitution v1 的产品目标是一个可见资料库，用户文案不得继续引入“资料空间 / Profile / Workspace”；本词只用于完成单资料库收敛前识别代码、数据和测试风险。 | `Profile` struct (Core), `ProfileManager` (Data) |
| **基线用户** | Baseline User | 不熟悉专业扫描 / 归档工具的成年用户（假设，待首批用户画像验证，见 `../explanations/assumptions.md` H1）。所有设计决策以此用户能否顺利完成为最低标准 | — |
| **图片是真相** | Image is Truth | 当 OCR 文本与图片冲突时，以用户确认裁剪 / 方向后的 App-managed 可读图片为内容真相；不承诺来源原始字节或完整分辨率 | `ArchiveItemModel.imagePath` (Data) |
| **.snapdrillbackup 备份** | .snapdrillbackup Backup | Release 1 的单一 purpose-built SQLite application document；不是 live SwiftData store 或通用 ZIP。Profile ZIP v2 仅为 epoch 前开发 fixture | 目标 wire 见 `backup-wire-format.md`；当前 `BackupService` 仍为待替换 v2 |

---

## 功能与技术

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **OCR** | Optical Character Recognition | Apple Vision 端上光学字符识别，用于生成搜索索引和可复制文本。App-managed 可读图片是内容真相，OCR 是辅助 | `CaptureViewModel` (Features) |
| **SM-2** | SM-2 Algorithm | SuperMemo 2 间隔重复调度算法，计算每个资料项的下次回顾时间 | `ReviewScheduler` (Core) |
| **字段配置** | Field Configuration | D-META-A 下，`category` 是默认可见但可跳过的主分类，`tag` 是次级多选入口；`source` / `level` 默认隐藏并仅按需开启。当前 canonical key 为 `category` / `source` / `level` / `tag`；这些通用字段不得被解释为学科、年级、知识点、难度或掌握度，自定义维度管理仍为 Candidate optional。 | `CategorySystemKey`, `CategoryDimensionModel.defaultCaptureVisibility`, `CategoryValueListViewModel.isVisibleInCapture` |
| **连续录入** | Continuous Capture | 保存一项资料后自动回到相机界面，支持批量录入不中断 | `CaptureRouter` (Features) |
| **软删除** | Soft Delete | 5 秒绝对期限内的持久待删状态；后台与重启不缩短窗口，期限后幂等执行真实删除 | 当前 `DeletionScheduler` 为待收敛实现 |

### SmartPaper 域保留词

PO 2026-07-05 裁决：资料系界面统一使用“资料 / 资料库”，但 SmartPaper 是生成练习卷的功能域，域内保留以下术语。Product Constitution v1 不保证 SmartPaper 进入 Release 1；只有该功能保持可达时才应用本域词表：

| 术语 | 英文 | 使用边界 |
|---|---|---|
| **题** | Question | 仅在 SmartPaper 选题、题数、已选 N 题、暂无可选题目等组卷语境中使用 |
| **试卷** | Paper | 仅用于 SmartPaper 输出物、PDF 标题或生成试卷动作 |
| **组卷** | Paper Generation | 仅用于 SmartPaper 功能名称、入口、配额与生成流程 |

---

## 界面与交互

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **Dashboard** | Dashboard | Release 1 普通启动默认任务入口；Capture / Library 一步可达，不承担 Profile、Pro、analytics 或 Review hero 叙事。具体卡片和五 Tab 结构未获批准 | `DashboardView` (Features) |
| **Onboarding** | Onboarding | 首次启动引导，解释采集、整理 / 找回、导出 / 打印与 local-first；不介绍 Review、SmartPaper、Profile 或 Pro，完成后不再显示 | `OnboardingView` (UI) |
| **回顾卡片** | Review Card | 正反面翻转式卡片，正面展示资料内容（图文），背面展示答案/备注。用户通过滑动或按钮评估掌握程度 | `ReviewCardFront` / `ReviewCardBack` (Features) |
| **标签** | Tag | 多选资料分类维度（如"重点""考前"），支持过滤和批量操作 | `CategorySystemKey.tag`, `CategoryValueModel` (Data) |
| **Profile 切换（当前实现遗留）** | Profile Switch | 当前 Multi-Profile 代码路径；不属于已批准的单资料库产品行为，只用于重基线前的实现与测试识别 | `ProfileManager.switchProfile(to:)` (Data) |

---

## 流程与方法

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **PoC** | Proof of Concept | 功能正式纳入前的验证阶段，需满足预定义的 Go/No-Go 条件 | — |
| **S0-S3** | Severity Level | 缺陷严重度分级：S0 数据不可逆丢失 > S1 流程阻断 > S2 有摩擦 > S3 不紧急 | — |
| **DoD** | Definition of Done | 完成证据与风险分级（见根 `AGENTS.md` §6 与 `docs/how-to/parallel-lanes.md` §6） | — |

---

## 商业化

| 术语 | 英文 | 定义 | 代码对应 |
|---|---|---|---|
| **免费版** | Free Release | Release 1 的当前商业形态：免费、无广告、无 IAP，并在单设备完成核心价值链 | — |
| **Pro（未来候选）** | Pro | 尚未批准的未来商业化概念，不代表订阅、功能组合、价格或时间表。任何用户可见 Pro 承诺必须等待新商业 contract | — |

---

## 相关文档

| 文档 | 关系 | 说明 |
|---|---|---|
| `../explanations/vision.md` | 上游 | 术语的定义来源 |
| `../explanations/design-principles.md` | 相关 | 部分术语在设计决策中定义 |
| `../explanations/business-model.md` | 相关 | 商业化术语 |
