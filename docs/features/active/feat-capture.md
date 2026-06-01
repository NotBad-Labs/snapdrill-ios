---
id: feat-capture
title: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: 采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户从打开 App 到存好一道题，步骤越少、耗时越短越好——任何增加录入摩擦的设计都是反模式。家长的真实拍摄场景远比实验室恶劣（夜晚昏暗光线、揉皱的试卷、红蓝黑笔交错、阴影和折痕），对复杂物理环境的鲁棒性是核心技术考量。
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
- **元数据填写**：编辑页只展示用户已开启的系统字段（学科默认开启）；已开启字段沿用上次选值作为默认。
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
- **关键机制 / 数据流**：图片来源进入裁剪（`ImageCropperView`，依赖 Mantis）→ 对图片执行 OCR（端上 Vision，`recognitionLanguages` 按 Profile 优先语言传入，系统默认含 `zh-Hans` / `zh-Hant` / `en-US`）→ 识别结果展示可编辑/可复制但不阻塞保存 → 保存时 Repository 原子性写入题目、图片引用、OCR 文本、元数据。图片**只存裁剪压缩后的副本**（长边限制 2000px、JPEG quality 0.8，~200KB/张），不修改用户原始照片。
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
- **NFR**：OCR 识别响应 < 2 秒（印刷体中英文，拍照到文字出现在编辑区）；图片裁剪内存 < 300MB（Mantis 内部管理）；单题存储均值 ~205KB（OCR ~5KB + 压缩图 ~200KB）；草稿恢复为 S0 级数据丢失防护（意外退出后可恢复）；OCR 端上执行、图片不上传云端。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（生命线 / 物理鲁棒 / 主路径图片 / P1·P2·P4·P6） | vision §产品原则 1 录入体验是生命线 + §产品价值链 + design §OCR 定位 / §图片存储策略 |
| What（采集入口优先级 / 相册 / 扫描 / PDF / 手动 / 剪贴板 / Share Extension） | requirements §采集方式优先级 + §功能全景·录入 |
| What（OCR 不阻断保存 / 重试 / 复制） | requirements §OCR 识别能力演进路线 + design §OCR 定位 |
| What（一图多题 / 连续录入 / 字段沿用） | requirements §一图多题演进路线 + design §连续录入设计 / §一图多题设计原则 |
| What（草稿恢复规则） | requirements §草稿恢复 + design §草稿恢复设计 |
| What（探索性不做 / 平台边界） | requirements §OCR / §一图多题（PoC 条目）+ apple-limits §Vision / §Foundation Models / §不存在的 API |
| What（商业分层 / 不限录入） | business §免费层完整定义（采集行）+ §绝不限制录入数量 + vision P3 |
| How（模块归属 / 采集入口文件→API） | architecture §采集方式归属 + §模块拓扑 + §SnapDrillCore Capture |
| How（OCR 数据流 / 压缩副本 / EXIF / 多脚本语言） | design §OCR 定位 / §图片存储策略 + architecture §ImageStorage + NFR §存储 / §隐私与安全 |
| How（State & Concurrency / DataExecutor / ActivityTracker / 通知刷新） | architecture §DataExecutor #599 / §AppActivityTracker / §reviewDataDidChange |
| How（Tab 入口裁决 / Share Extension 不污染主导航） | design §信息架构 + §Share Extension 设计 |
| Verify（success / variants / exceptions / data guarantees） | cases UC1 Create Problem |
| Verify（边界 B01/B02/B03/B08/B11/B13/B14/B15/B16/B20/B22） | cases Appendix Boundary Cases |
| Verify（NFR：OCR<2s / 裁剪内存 / 单题存储 / 草稿 S0） | non-functional-requirements §性能 / §内存 / §存储 / §数据完整性 |
| Verify（旅程实证 30s 录入 / 微信导入 / OCR 失败兜底） | journeys 旅程 0 / 旅程 2 / 旅程 3 / 旅程 9 |

## 关联
- 原则：`../../explanations/vision.md`（P1 录入体验 / P2 简洁 / P4 隐私 / P6 原生优先）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 0 首次录入 / 旅程 2 拍照录错题 / 旅程 3 微信导入 / 旅程 9 OCR 失败修正）
- 决策：`../../decisions/ADR-004-china-build-firebase-free.md`（端上 OCR / 国内版零分析出境）
- 被依赖 / 相关：`feat-review.md`（消费采集产出的题目）、`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
