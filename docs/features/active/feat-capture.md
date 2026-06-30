---
id: feat-capture
title: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-30
intent_refs:
  - vision:P1
  - vision:P2
  - vision:P4
  - vision:P6
  - ADR-005
---

# Feature: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户从打开 App 到存好一道题，步骤越少、耗时越短越好——任何增加录入摩擦的设计都是反模式。用户的真实拍摄场景远比实验室恶劣（夜晚昏暗光线、揉皱的纸张、红蓝黑笔交错、阴影和折痕），对复杂物理环境的鲁棒性是核心技术考量。
- **定位**：采集是产品价值链（采集 → 管理 → 导出/打印）的**第一环、最高频场景**。主路径必须是图片（拍照 / 选图 / 扫描），因为 OCR 文字是辅助、图片是真相（含公式、图形、批注）；CSV 等数据导入定位为数据可携带权场景，不与拍照同级展示。
- **原则归属**：P1 录入体验是生命线（最高优先级）+ P2 简洁（录入路径最短）+ P4 数据属于用户（端上 OCR、不上传、隐私）+ P6 原生优先（Vision / VisionKit）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **多入口录入（全入口免费、无限录题）**：
  - **摄像头拍照（智能相机，P0）**：实时文字区域检测 + 稳定性指示器 + 自动框选。
  - **相册导入（P0）**：导入已有照片（截图、微信图片等）；iPad 上为主要录入方式（举 iPad 拍试卷笨重）。
  - **文档扫描（P0）**：系统级文档扫描，自动透视校正、边缘检测、多页扫描。
  - **PDF 导入（P0）**：选择 PDF 后逐页预览、页面选择、裁剪后录入。
  - **手动编辑（P1）**：兜底方案，用户自行输入文字与图片；允许无图保存纯文本题目。
  - **剪贴板导入（P1）**：从系统剪贴板粘贴文本到 SnapDrill。
  - **iOS Share Extension（P1）**：从微信/QQ/浏览器直接分享图片到 SnapDrill，免去保存相册步骤。
- **OCR（辅助，不阻断保存）**：印刷体中英文识别（Apple Vision 高精度模式），用户可手动修正；识别失败提供手动重试 + 稳定性提示；OCR 结果可复制到剪贴板。**保存按钮可用性只依赖「至少一张图片或一段手动文字」，不依赖 OCR 结果质量**（图片是真相）。
- **一图多题**：一图一题（手动裁剪）+ 同一张图连续裁剪多题（不用重新选图）。
- **连续录入**：保存后默认回到采集界面（摄像头 / 同图再次出现），不回 Dashboard。
- **元数据填写**：编辑页只展示用户已开启的系统字段；新资料库的内置字段默认不在录入页显示，用户可在分类管理中按需打开「分类 / 来源 / 级别 / 标签」等维度。已开启字段沿用上次选值作为默认。
- **草稿恢复**：采集页退出时自动保存草稿（图片 + OCR 文字，或纯文本）；下次进入采集检测到草稿弹窗提示恢复或放弃；仅保留最近一份，保存新题目后清除，7 天过期自动清理。
- **边界 / 不做**：
  - 手写体识别增强、AI 辅助拆题、数理化公式识别均为**探索性**（需 PoC 达标才纳入），当前不做（见 How·平台边界）。
  - CSV / JSON 不是主录入路径，UI 上不与拍照同级展示（属数据可携带权场景，对应 Settings 的 CSV/JSON 导入导出）。
  - 草稿不做多份历史、不做云端草稿。
- **前置依赖**：无。采集是价值链上游、被依赖方——题库管理 / 导出 / 复习 / 智能组卷均消费采集产出的题目与图片。
- **商业分层**：全部采集入口（Camera / Photos / PDF / Manual / Clipboard / Share Extension）+ 无限录题 + OCR 展示/复制/手动修正 = **免费**，绝不限制录入数量、不做「每日 N 题」。Pro 的「图片处理增强」（AI 去手写/去批改痕迹/试卷还原，免费限次 + Pro 无限）是采集之上的增值，不属本 feature 核心（定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：`SnapDrillFeatureCapture`（UI + 各入口）；OCR 引擎与图片存储在 `SnapDrillCore`（`OCRService` 实现 `OCRServiceProtocol`、`ImageStorage`）；`CaptureDraftService`（草稿）与 `ContentTaggingService` / `QuestionSplittingService` 均为 Core service protocol，经 `ServiceContainer` 注入。落库走 `SnapDrillData` Repository → `DataExecutor`。
- **采集入口归属（文件 → 底层 API）**：
  - 摄像头 → `SmartCameraView` / `SmartCameraViewController` / `CameraSessionManager`（AVFoundation）
  - 文档扫描 → `DocumentScannerView`（`VisionKit.VNDocumentCameraViewController`）
  - Photos 导入 → `CaptureView` PhotosPicker（PhotosUI）
  - PDF 导入 → `PDFPagePickerView`（PDFKit 选页 → 渲染为 UIImage）
  - 剪贴板 / 手动 → `CaptureMethodCard` 手动入口 → ManualEdit；纯文本路径走 `CaptureResultView`（不依赖 OCR，允许无图保存，Image is Truth 例外）
  - Share Extension → `SnapDrillShare` Extension target（系统 ShareSheet，通过 App Groups 共享容器；进入后直接进裁剪/编辑 → 保存）
- **关键机制 / 数据流**：图片来源进入裁剪（`ImageCropperView`，依赖 Mantis）→ 对图片执行 OCR（端上 Vision，目标态为 `recognitionLanguages` 按 Profile 优先语言传入，系统默认含 `zh-Hans` / `zh-Hant` / `en-US`）→ 识别结果展示可编辑/可复制但不阻塞保存 → 保存时 Repository 原子性写入题目、图片引用、OCR 文本、元数据。图片**只存裁剪压缩后的副本**（长边限制 2000px、JPEG quality 0.8，~200KB/张），不修改用户原始照片。
  - **⚠ 实现现状（GAP-R3，代码债）**：当前 `OCRService.recognizeText` 的 `recognitionLanguages` 仍硬编码 `zh-Hans` / `en-US`（`OCRService.swift:43`），**未含 `zh-Hant` 繁体**、**未按 Profile 优先语言动态传入**。需求不变（含繁体 + Profile 语言感知），待 code 债修复。
- **EXIF 隐私铁律**：图片入库前必须经 `ImageStorage` 剥离 GPS / 位置信息（保存前清除）。
- **State & Concurrency**（Swift 6 strict）：采集 View 由 `@Observable` ViewModel（`@MainActor`：`CaptureViewModel` / `CaptureResultViewModel`）驱动；OCR、图片压缩与落库等重活经 Core service / Repository → `DataExecutor`（actor 拥有 `ModelContainer`，`createOffMainActor()` 消除 MainActor+XPC 死锁 #599），不阻塞主线程；保存后通过 `Notification.Name.reviewDataDidChange` 跨模块刷新 Dashboard / Review。采集流程必须 `AppActivityTracker.begin(...)` → ... → `end(...)`，否则 Profile 切换不被阻塞（已接入 `CaptureViewModel` / `CaptureResultViewModel`）。
- **设计裁决（仅本模块）**：采集入口作为底部 Tab 栏标准 Tab（首页/题库/采集/复习/设置），而非自定义突出按钮——为保持导航架构极致简洁（P2）、降低认知负荷；Share Extension 不污染主导航（不改变 Tab 结构），作为系统级扩展独立于主界面。
- **平台边界**（apple-limits）：Vision OCR 强项是印刷体，**无独立中文手写识别模型**；`RecognizeDocumentsRequest` 适合整页文档结构、**不适合裁剪后的单题图片**；Foundation Models（`ContentTaggingService`）擅长分类/摘要、**不擅长数学推理**（自动标签可用、解题不可）；Math Notes / Smart Script / 原生公式识别（LaTeX/MathML）均无可用公开 API——故手写增强、AI 拆题、公式识别列为探索性。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 当前 Profile 已选定且用户位于采集入口，When 用户从 Camera / Photos / PDF / Clipboard / Manual 任一入口（含 Document Scan）进入并完成裁剪、OCR、元数据填写后点击保存，Then 系统原子性写入题目（含 Profile 归属、图片引用、OCR 文本、元数据），给出成功反馈（触觉 + 缩略图动画）并默认回到采集界面支持连续录入。
- **边界 / 异常**：
  - Camera 权限拒绝/受限 → 不可进入拍照，给出权限说明 + 跳转系统设置入口，不创建空题目（B14）；权限后续被系统撤销 → 再次进入立即提示、不黑屏假死（B15）。
  - Photo Library 权限拒绝/受限 → 提示权限缺失、不静默返回、不生成空白导入任务（B16）。
  - 导入图片/PDF 损坏或不可读 → 提示文件不可用，允许重新选择，现有数据不变（B08）。
  - OCR 首次失败 → 提供手动重试 + 稳定性提示，仍保留继续编辑与保存能力。
  - OCR 返回空文本 → 图片题仍可保存，OCR 文本字段允许为空（B20）。
  - 保存写入失败（磁盘满 / SwiftData 错误）→ 不显示成功状态，保留当前编辑内容为 draft 或停留编辑页可重试，`rollbackContext()` 回滚，不产生半写入记录（B01 / B02）。
  - 连续保存重复点击 → 忽略重复或 disable 保存按钮，不产生重复题目记录（B13）。
  - 录题中意外退出（来电/崩溃/强退）→ 下次进入采集提示恢复最近一份 draft（B03 / B11）。
  - 未裁剪直接保存整页大图 → 给裁剪引导提示或保留更高清晰度，满足再次放大查看（B22）。
- **数据保证**：未点击保存前不产生正式题目记录；保存成功后题目记录必须同时含当前 Profile 归属、主内容载体、元数据与可检索 OCR 文本；图片题必须保留裁剪后的副本，OCR 不是唯一数据来源；任何写入失败不得产生「列表已出现但内容不完整」的半写入记录；Draft 仅保留最近一份、按 Profile 隔离、成功保存后自动清除、7 天过期清理；图片入库前必须剥离 EXIF GPS/位置信息。
  - **实现现状（GAP-R2 已缓解，剩余 caveat）**：草稿图片不再使用全局 `Caches/draft_capture.jpg`，而是按 `activeProfileId` 写入 `Application Support/CaptureDrafts/<profileId>/draft_capture.jpg`；草稿元数据仍写 `UserDefaults.standard`，但 `UDKey.captureDraftMetadata` 已列入 `ProfileManager.perProfileKeys`，切换 Profile 时随偏好保存 / 加载。剩余 caveat：`CaptureDraftService` 仍通过 `UserDefaults.standard` 读取 active profile 与元数据，尚未显式接收 `ProfileScope`。
- **NFR**：OCR 识别响应 < 2 秒（印刷体中英文，拍照到文字出现在编辑区）；图片裁剪内存 < 300MB（Mantis 内部管理）；单题存储均值 ~205KB（OCR ~5KB + 压缩图 ~200KB）；草稿恢复为 S0 级数据丢失防护（意外退出后可恢复）；OCR 端上执行、图片不上传云端。

## 5. Contracts（状态 / 错误 / 文案 / L10n 归属）

本节写“应该如此”的意图行为，不用当前实现反向覆盖产品目标。若代码、测试或真机行为与本节冲突，应登记为 bug 或跨层 blocker，而不是把现状固化为契约。

### A. 状态机契约

| 状态 | UI 必须给出的可见反馈 |
|---|---|
| `idle` | 显示可用入口（相机 / 相册 / 文档扫描 / PDF / 手动 / 剪贴板），无后台忙碌遮罩，入口可点击。 |
| `importing` | 展示导入或处理中反馈；触发导入的入口禁用或被系统 picker 接管，不能出现“点了没反应”。 |
| `ocrProcessing` | 展示识别中反馈；重复识别 / 保存等会造成竞态的操作禁用。 |
| `ocrSuccessWithContent` | 进入编辑页，识别文本可见且可编辑，图片存在时继续保留。 |
| `ocrEmptyResult` | 进入编辑页或展示空结果提示；空结果不是失败，图片仍可保存，用户可手动补文字或重新采集。 |
| `ocrFailed` | 展示用户可见错误，并提供重新识别与继续编辑；图片不得丢失。 |
| `readyToEdit` | 编辑页显示内容 / 图片 / 元数据；只要有文本或图片即可保存，OCR 质量不是保存前置条件。 |
| `saving` | 保存按钮禁用或显示保存中状态；重复点击不得产生重复记录。 |
| `saved` | 给出保存成功反馈，清除已保存草稿，并回到可继续采集的路径。 |
| `saveFailed` | 展示用户可见错误；不得显示成功状态；保留当前编辑内容，允许修正或重试。 |

### B. 错误语义契约

- 用户取消不是系统失败：取消 picker、扫描或系统流程时，不应展示失败错误，也不应写入空记录。
- OCR 空结果不是失败：空文本保留为可编辑结果，图片题仍可保存。
- 导入不可读或格式不支持是显式错误态：用户必须看到错误与可重试路径，不只写 log。
- 所有失败必须用户可见：保存、导入、OCR 与权限失败都不能静默吞掉。

### C. 文案 / 政策契约

- 相机与相册权限用途串是 PO-gated 对外文案。当前基线为：
  - `NSCameraUsageDescription`：`SnapDrill 需要使用相机拍摄并识别你选择的资料内容。`
  - `NSPhotoLibraryUsageDescription`：`SnapDrill 需要访问相册以导入你选择的图片资料。`
  - `NSCameraUsageDescription`：`SnapDrill needs camera access to capture and recognize the materials you choose.`
  - `NSPhotoLibraryUsageDescription`：`SnapDrill needs photo library access to import the images you choose.`
- Capture 直接暴露的用户可见文案不得出现「错题 / 作业 / 儿童 / 年级」等会把产品拉回儿童教育或旧错题本定位的词。
- 上述规则只约束 Capture 暴露面与权限用途串；历史 ADR、其它屏幕或发布硬化文案另走各自 owner 与门禁。

### D. L10n 归属契约

- 被多屏共用的 L10n key 不应挂在单屏命名空间下；应迁入 `Common` / `Shared` 命名空间，或在 spec 中显式登记为共享例外。
- 已知实例：`L10n.Onboarding.fieldConfigTitle` / `fieldConfigDescription` 被 `CaptureResultView` 复用，但仍归在 Onboarding 命名空间。建议后续迁入共享命名空间；迁移动作 PO-gated，本 seed 只登记，不强行迁移。

### Enforcement / 待验缺口

| 契约 | Enforcement | 当前状态 |
|---|---|---|
| 状态与错误语义 A/B | ViewModel / 服务层现有公开 API 的最小单测；无可测 seam 时登记 blocker，不为测试改架构。 | 已用 `CaptureViewModelTests` 钉住 OCR 空结果可编辑、OCR 失败可继续编辑、OCR 前图片先入草稿、保存重复点击防护等路径。 |
| 文案 / 政策 C | `Scripts/validate_capture_contract.py --check` 窄扫 Capture 暴露的 L10n key、InfoPlist 权限用途串与 Capture View 用户可见字符串。 | 已接入 pre-commit 与 CI docs gate。 |
| L10n 归属 D | 当前只登记与建议；若要 enforce，后续可加脚本检查多屏复用 key 是否位于共享命名空间。 | `fieldConfigTitle` / `fieldConfigDescription` 待 PO 决策迁移。 |
| OCR 真机识别质量 / 超时 | dogfood 待验。 | Owner：Codex + PO；触发：首次真机 Capture dogfood 或发布就绪检查。 |
| 文档扫描真机路径 | dogfood 待验。 | Owner：Codex + PO；触发：iPhone 17 真机扫描。 |
| 打印真机三态 | dogfood 待验。 | Owner：Codex + PO；触发：导出/打印链路发布前 dogfood。 |


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 用户拥有数据 / P6 Apple 原生优先） | 采集是价值链第一环；主路径图片、OCR 辅助不阻塞保存；端上 OCR 不上传；Apple Vision / VisionKit 原生 |
| 产品政策 / ADR | `../../decisions/ADR-005-analytics-privacy-strategy.md`（全球零后端行为采集） | 采集不产生任何后端行为上报；图片入库前剥离 EXIF GPS / 位置信息 |
| 待验证假设 | `../../explanations/assumptions.md` H1（首次能完成采集与保存）/ H2（管理需求成立） | 采集首次达成的成败直接验证 H1 |
| 验收证据 | §4 验证标准 GWT + AllTests + 真机录入 | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P1 采集摩擦最低 / P2 简洁 / P4 用户拥有数据 / P6 原生优先）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 1 首次采集 / 旅程 2 长期归档（含导入与一图多题）/ 旅程 3 证书培训资料）
- 决策：`../../decisions/ADR-005-analytics-privacy-strategy.md`（全球生产零后端行为采集；OCR 端上处理）
- 被依赖 / 相关：`feat-review.md`（消费采集产出的题目）、`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
