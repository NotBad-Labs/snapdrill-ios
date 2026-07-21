---
id: feat-capture
title: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-20
intent_refs:
  - vision:P1
  - vision:P2
  - vision:P4
  - vision:P6
  - ADR-005
release_refs:
  - release-1:C2-Core
  - release-1:C2-Image
  - release-1:C2-Optional
  - release-1:S1-A
  - release-1:P1-A
release_outcomes:
  - M1
  - M2
  - M3
  - M6
  - M9
  - M10
---

# Feature: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）

> **产品重基线（2026-07-20）**：采集属于核心价值链。Release 1 Must 输入是相机 / 文档扫描、相册与 PDF；手动、剪贴板和 Share Extension 属 Candidate optional，默认隐藏。OCR 是可编辑辅助，保存真相是用户确认裁剪 / 方向后的 App-managed 可读图片；不承诺来源原始字节或完整分辨率。S1-A 的文字与 normalized JPEG 接受边界由 Local Library Data Contract 唯一拥有。P1-A 固定未保存草稿不按时间自动删除，只在正式保存成功或用户明确丢弃后删除。frontmatter 与技术章节仍记录当前实现，下文 iPad、Profile 和 Pro 图片增强描述只作实现 / 历史追溯。

> 人读摘要：🧩 当前实现存在（当前分层：free）。派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示 Release 1 合同符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户从打开 App 到存好一条资料，步骤越少、耗时越短越好——任何增加录入摩擦的设计都是反模式。用户的真实拍摄场景远比实验室恶劣（夜晚昏暗光线、揉皱的纸张、红蓝黑笔交错、阴影和折痕），对复杂物理环境的鲁棒性是核心技术考量。
- **定位**：采集是产品价值链（采集 → 管理 → 导出/打印）的**第一环、最高频场景**。主路径必须是图片（拍照 / 选图 / 扫描），因为 OCR 文字是辅助、图片是真相（含公式、图形、批注）；CSV 等数据导入定位为数据可携带权场景，不与拍照同级展示。
- **原则归属**：P1 录入体验是生命线（最高优先级）+ P2 简洁（录入路径最短）+ P4 数据属于用户（端上 OCR、不上传、隐私）+ P6 原生优先（Vision / VisionKit）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **当前多入口实现与 Release 1 分类**：
  - **摄像头拍照（智能相机，P0）**：实时文字区域检测 + 稳定性指示器 + 自动框选。
  - **相册导入（P0）**：导入已有照片（截图、聊天附件等）。B7-A 的 Release 1 仅覆盖 iPhone，不从当前代码推导 iPad 工作流。
  - **文档扫描（P0）**：系统级文档扫描，自动透视校正、边缘检测、多页扫描。
  - **PDF 导入（P0）**：选择 PDF 后逐页预览、页面选择、裁剪后录入。
  - **手动编辑（Candidate optional）**：兜底方案，用户自行输入文字与图片；默认隐藏，只有冻结 manifest 显式纳入才可见。
  - **剪贴板导入（Candidate optional）**：从系统剪贴板粘贴文本到 SnapDrill；默认隐藏，只有冻结 manifest 显式纳入才可见。
  - **iOS Share Extension（Candidate optional）**：从其他 App 分享图片到 SnapDrill；默认隐藏，只有冻结 manifest 显式纳入且通过 App Group / GPS / AX 门禁才可见。
- **OCR（辅助，不阻断保存）**：印刷体中英文识别（Apple Vision 高精度模式），用户可手动修正；识别失败提供手动重试 + 稳定性提示；OCR 结果可复制到剪贴板。**Must 路径的保存按钮只依赖至少一张 App-managed 可读图片，不依赖 OCR 结果质量；纯文本保存只在 manifest 纳入手动录入时可见。**
- **一图多题**：一图一题（手动裁剪）+ 同一张图连续裁剪多题（不用重新选图）。
- **连续录入**：保存后默认回到采集界面（摄像头 / 同图再次出现），不回 Dashboard。
- **元数据填写**：Release 1 Must 支持基础分类 / 标签；来源、级别与自定义字段属于动态字段 Candidate optional，只有冻结 manifest 纳入时才出现。当前实现会沿用已开启字段的上次选值，该机制不得让首次采集依赖 optional 配置。
- **草稿恢复**：采集页退出时自动保存草稿（图片 + OCR 文字，或纯文本）；下次进入采集检测到草稿弹窗提示恢复或放弃；仅保留最近一份，不按时间自动删除，仅在正式保存成功或用户明确丢弃后删除。
- **边界 / 不做**：
  - 手写体识别增强、AI 辅助拆题、数理化公式识别均为**探索性**（需 PoC 达标才纳入），当前不做（见 How·平台边界）。
  - CSV / JSON 不是主录入路径，UI 上不与拍照同级展示（属数据可携带权场景，对应 Settings 的 CSV/JSON 导入导出）。
  - 草稿不做多份历史、不做云端草稿。
- **前置依赖**：无。采集是价值链上游、被依赖方——资料库、导出和可选回顾消费采集产出的资料与图片。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；不得限制基础录入数量。图片处理增强只是候选假设，不是当前 Pro、配额或价格承诺。

## 3. 技术设计 (How)
- **模块归属**：`SnapDrillFeatureCapture`（UI + 各入口）；OCR 引擎与图片存储在 `SnapDrillCore`（`OCRService` 实现 `OCRServiceProtocol`、`ImageStorage`）；`CaptureDraftService`（草稿）与 `ContentTaggingService` / `QuestionSplittingService` 均为 Core service protocol，经 `ServiceContainer` 注入。落库走 `SnapDrillData` Repository → `DataExecutor`。
- **采集入口归属（文件 → 底层 API）**：
  - 摄像头 → `SmartCameraView` / `SmartCameraViewController` / `CameraSessionManager`（AVFoundation）
  - 文档扫描 → `DocumentScannerView`（`VisionKit.VNDocumentCameraViewController`）
  - Photos 导入 → `CaptureView` PhotosPicker（PhotosUI）
  - PDF 导入 → `PDFPagePickerView`（PDFKit 选页 → 渲染为 UIImage）
  - 剪贴板 / 手动 → `CaptureMethodCard` 手动入口 → ManualEdit；纯文本路径走 `CaptureResultView`（不依赖 OCR，允许无图保存，Image is Truth 例外）
  - Share Extension → `SnapDrillShare` Extension target（系统 ShareSheet，通过 App Groups 共享容器；进入后直接进裁剪/编辑 → 保存）
- **关键机制 / 数据流**：图片来源进入裁剪（`ImageCropperView`，依赖 Mantis）→ 对图片执行 OCR（端上 Vision；当前实现语言配置仍含遗留 Profile 偏好）→ 识别结果可编辑 / 可复制但不阻塞保存 → Repository 原子性写入资料、图片引用、OCR 文本与元数据。图片**只存裁剪压缩后的副本**；产品接受边界只见 [S1-A](../../reference/local-library-data-contract.md#21-release-1-内容与图片接受边界s1-a)，JPEG quality 0.8 与约 200KB / 张只是当前实现 / 测量基准，不修改用户原始照片。
  - **实现现状（待单资料库重基线）**：当前 OCR 语言配置仍经 Profile 相关偏好表达。B5-A 后不得新增 Profile 语言感知需求；B7-A 的英文 / 简体中文只约束产品 UI 语言，OCR 识别语言集合（含已落地的繁体识别）由 Release Contract 与识别质量证据另行裁定。
- **EXIF 隐私铁律**：图片入库前必须经 `ImageStorage` 剥离 GPS / 位置信息（保存前清除）。
- **State & Concurrency**（Swift 6 strict）：采集 View 由 `@Observable` ViewModel（`@MainActor`：`CaptureViewModel` / `CaptureResultViewModel`）驱动；OCR、图片压缩与落库等重活经 Core service / Repository → `DataExecutor`（actor 拥有 `ModelContainer`，`createOffMainActor()` 消除 MainActor+XPC 死锁 #599），不阻塞主线程；保存后通过 `Notification.Name.reviewDataDidChange` 跨模块刷新 Dashboard / Review。采集流程必须 `AppActivityTracker.begin(...)` → ... → `end(...)`；当前用于阻止 Profile 切换，单资料库实现中应继续保护并发数据一致性。
- **设计现状**：采集当前是标准 Tab；Release 1 只要求从 Dashboard 一次操作可达，不批准五 Tab 结构。Share Extension 是 Candidate optional 的系统级扩展，不构成主导航承诺。
- **平台边界**（apple-limits）：Vision OCR 强项是印刷体，**无独立中文手写识别模型**；`RecognizeDocumentsRequest` 适合整页文档结构、**不适合裁剪后的单题图片**；Foundation Models（`ContentTaggingService`）擅长分类/摘要、**不擅长数学推理**（自动标签可用、解题不可）；Math Notes / Smart Script / 原生公式识别（LaTeX/MathML）均无可用公开 API——故手写增强、AI 拆题、公式识别列为探索性。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 用户从 Dashboard 进入采集，When 使用相机 / 文档扫描、相册或 PDF 完成裁剪、方向确认、OCR 辅助编辑并保存，Then 系统原子性写入唯一资料库（App-managed 可读图片、OCR 文本、元数据）并给出成功反馈；OCR 失败或为空不阻断保存。optional 入口只有冻结 manifest 显式纳入时才进入同一结果 oracle。
- **边界 / 异常**：
  - Camera 权限拒绝 / 受限 → 不可进入拍照，给出权限说明 + 跳转系统设置入口，不创建空资料（B14）；权限后续被系统撤销 → 再次进入立即提示、不黑屏假死（B15）。
  - Photo Library 权限拒绝/受限 → 提示权限缺失、不静默返回、不生成空白导入任务（B16）。
  - 导入图片/PDF 损坏或不可读 → 提示文件不可用，允许重新选择，现有数据不变（B08）。
  - OCR 首次失败 → 提供手动重试 + 稳定性提示，仍保留继续编辑与保存能力。
  - OCR 返回空文本 → 图片题仍可保存，OCR 文本字段允许为空（B20）。
  - 保存写入失败（磁盘满 / SwiftData 错误）→ 不显示成功状态，保留当前编辑内容为 draft 或停留编辑页可重试，`rollbackContext()` 回滚，不产生半写入记录（B01 / B02）。
  - 连续保存重复点击 → 忽略重复或 disable 保存按钮，不产生重复资料记录（B13）。
  - 采集中意外退出（来电 / 崩溃 / 强退）→ 下次进入采集提示恢复最近一份 draft（B03 / B11）。
  - 未裁剪直接保存整页大图 → 给裁剪引导提示或保留更高清晰度，满足再次放大查看（B22）。
- **数据保证**：未点击保存前不产生正式资料记录；保存成功后记录必须包含主内容载体、必要元数据与可检索 OCR 文本；图片资料必须保留裁剪后的副本，OCR 不是唯一数据来源；S1-A 校验失败必须在正式 mutation 前拒绝且不得截断；任何写入失败不得产生半写入记录；Draft 隔离策略等待单资料库实现收敛，成功保存后清除、用户明确丢弃后清除、不按时间自动删除与 EXIF GPS 剥离保证不变。
  - **实现现状（GAP-R2 已缓解，剩余 caveat）**：草稿图片不再使用全局 `Caches/draft_capture.jpg`，而是按 `activeProfileId` 写入 `Application Support/CaptureDrafts/<profileId>/draft_capture.jpg`；草稿元数据仍写 `UserDefaults.standard`，但 `UDKey.captureDraftMetadata` 已列入 `ProfileManager.perProfileKeys`，切换 Profile 时随偏好保存 / 加载。剩余 caveat：`CaptureDraftService` 仍通过 `UserDefaults.standard` 读取 active profile 与元数据，尚未显式接收 `ProfileScope`。
- **NFR**：OCR 识别响应 < 2 秒（印刷体中英文，拍照到文字出现在编辑区）；图片裁剪内存 < 300MB（Mantis 内部管理）；单题存储均值 ~205KB（OCR ~5KB + 压缩图 ~200KB）；草稿恢复为 S0 级数据丢失防护（意外退出后可恢复）；OCR 端上执行、图片不上传云端。

## 5. Contracts（状态 / 错误 / 文案 / L10n 归属）

本节写“应该如此”的意图行为，不用当前实现反向覆盖产品目标。若代码、测试或真机行为与本节冲突，应登记为 bug 或跨层 blocker，而不是把现状固化为契约。

### A. 状态机契约

| 状态 | UI 必须给出的可见反馈 |
|---|---|
| `idle` | 显示 Must 入口（相机 / 文档扫描、相册、PDF）；手动 / 剪贴板只在冻结 manifest 显式纳入时出现。无后台忙碌遮罩，可见入口可点击。 |
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
| Release 1 Contract | `../../reference/release-1-contract.md` C2-Core / C2-Image / C2-Optional / S1-A / P1-A | Must 输入、确认裁剪后的 App-managed 图片真相、手动 / 剪贴板 / Share Extension 的默认隐藏边界、Local Library Data Contract 统一拥有的输入接受边界，以及未保存草稿不按时间自动删除的生命周期 |
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
