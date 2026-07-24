---
id: feat-export
title: PDF 导出与打印
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-20
intent_refs:
  - vision:P2
  - vision:P4
release_refs:
  - release-1:C2-Core
  - release-1:C2-Optional
  - release-1:C5-E
  - release-1:C5-S1
  - release-1:D2-A
  - release-1:D4S-A
release_outcomes:
  - M5
  - M9
  - M10
---

# Feature: PDF 导出与打印

> **产品重基线（2026-07-19）**：导出 / 打印与永久手动备份属于宪章核心承诺。C2-Core 要求打印作为独立正式终点，并把分享 / 保存视为并列出口；D2-A 固定基础 PDF 无封面及物理页数；D4S-A 将 selected PDF / CSV 明确归为 partial export，不等待完整资料库 barrier，也不冒充完整备份。PDF 增强按 C2-Optional 逐 build 冻结，SmartPaper 仅按 C5-E / C5-S1 的非公开实验边界复用管线。frontmatter 与技术章节仍只记录当前实现；旧 Profile / Pro 分层不得驱动新工作。

> 人读摘要：🧩 当前实现存在（当前分层：free）。派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示 Release 1 PRD 符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户归档资料的最终目的之一是把内容输出到纸上或其他工作流——导出 / 打印是产品价值链的终点（采集 → 整理 / 找回 → **导出 / 打印**）。"数据属于用户"不是口号，而是可导出、可打印、可带走；缺失基础导出会把数据锁在 App 中。
- **定位**：基础多选 PDF 与系统打印是日常导出主入口。增强导出（去答案、留白、页眉页码）是 Candidate optional，默认隐藏；即使 manifest 纳入也不得成为付费墙。
- **原则归属**：P4 数据属于用户（可导出/可打印/可带走）。任何功能若损害"录入/管理"的简洁性就不该做——导出/打印作为价值链终点服从此铁律。详见 `../../product/vision.md`。

## 2. 需求规则 (What)
- **PDF 导出（基础，免费）**：资料库过滤后批量导出，含**导出前预览**，支持分享与打印。
- **基础分页（D2-A）**：基础 PDF 不生成封面，物理页数严格为 `ceil(N / itemsPerPage)`；空选择在进入渲染器前失败。未来封面必须重新 shaping，不能作为默认版式元素引入。
- **局部快照（D4S-A）**：selected PDF / CSV 只对调用时取得的稳定选择 / 查询快照负责，是 partial export；不关闭 complete-operation admission、不等待完整资料库 prestate，也不得使用“完整备份”表述。若 complete operation 已关闭 snapshot admission，请求立即 busy 失败而不是排队。
- **PDF 增强（Candidate optional）**：默认隐藏，只有冻结 manifest 显式纳入并通过 PDF fidelity / 打印门禁才可见：
  - **去答案打印模式**：隐藏答案文字字段，只留题目内容，面向自测 / 回顾（布局层操作）。
  - **留白区**：题目下方留白供用户手写补充。
  - **页眉页码**：打印后纸质资料可翻阅定位。
- **单条快速打印**：面向临时打印一条资料的轻量场景；属于 C2-Optional，默认隐藏，只有冻结 manifest 显式纳入才可见。基础多选 PDF 与系统打印不得依赖它。
- **边界 / 不做**：
  - 不做导出水印；不在导出中嵌入广告或 Pro 引导；不嵌入「上传云盘/分享社交网络」类公开传播引导（版权合规：导出/打印面向个人使用）。
  - **本 feature 只覆盖 PDF 导出与打印**。JSON / CSV 结构化数据导出是同级数据导出能力（隐私设置页 / 资料库面板），`.snapdrillbackup` 全量备份 / 恢复是独立 feature；本 spec 不展开。
  - **"去答案打印"（隐藏答案字段，布局层）** 与候选的图片处理增强（图片层）是不同层面，不应混淆；图片增强不是当前 Pro 或 Release 1 承诺。
- **前置依赖**：无。智能组卷（`../backlog/feat-smartpaper.md`）**复用本 feature 的 PDFExportService 管线**作为输出末端——是本 feature 的下游消费方。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；已纳入 Release PRD 的导出 / 打印能力不得承担升级转化。Word 与图片增强只是候选假设，不是 Pro、价格或发布时间承诺。

## 3. 技术设计 (How)
- **模块归属**：PDF 渲染/排版管线 `SnapDrillCore/Service/PDFExportService`（统一 PDF 引擎，注入于 `ServiceContainer.pdfExport`）；打印呈现走 `SnapDrillUI/PrintPresenting` adapter（生产默认 `LivePrintPresenter`，内部使用 `UIPrintInteractionController`，iPad 需要有效 anchor）。
  - **实现现状（GAP-R5 已接入，剩余 dogfood）**：`LibraryDetailView` 单题快速打印生成 PDF 后调用 `PrintPresenting.present(...)`；`ExportPreviewView` 的批量打印同样通过 `PrintPresenting`。旧 spec 所称"经 ShareSheet 间接打印、尚未接入 `UIPrintInteractionController`"已过期。剩余真实缺口是无 AirPrint 打印机 / 真机 AirPrint 三态 dogfood 尚未完成。
- **关键机制 / 数据流**：资料库过滤 / 选中结果集 → 资料快照 → PDFExportService 排版（去答案 / 留白 / 页眉页码为 Candidate optional）→ 生成 PDF → 预览 → 分享 / 保存 / 打印。C5-E 实验中的 SmartPaper 与未来可能重入的 Word 应优先复用管线而非重建 PDF 引擎。ShareCard 例外：用 SwiftUI `ImageRenderer`，不走 PDFExport 管线。
  - **实现现状（D2-A / D4S-A）**：资料库在呈现导出页前冻结当前完整选择及可见顺序，解析结果必须与冻结 ID 集合严格闭合；`PDFExportService` 不生成封面，物理页数按 `ceil(N / itemsPerPage)`，并在渲染前拒绝空选择、不可读条目和无法保证可读内容的页面密度。图片按页准备和释放，任一页失败时整次调用抛错且不返回部分 PDF 数据。
- **State & Concurrency**（Swift 6 strict）：导出/打印为只读编排。批量 PDF 渲染**逐页包 `autoreleasepool` 释放**控制峰值内存（防 OOM）；重活不阻塞主线程。PDF 导出预览经 `AppActivityTracker.begin(.exporting) → end(...)` 标记活动；单题快速打印与预览页打印经 `AppActivityTracker.begin(.printing) → end(...)` 标记活动。D4S-A 要求 selected export 使用稳定选择快照但不等待 complete-operation barrier；当前 Profile-switch 互斥只是实现事实，不能外推为目标 barrier。
  - **实现现状（GAP-R4 已接入，剩余 caveat）**：旧 spec 所称"快速打印未接入 tracker、`.printing` 生产代码零调用"已过期。当前剩余真实缺口是 `LibraryEditViewModel.save()` 仍使用 `.capturing` 标记编辑保存，需后续判断是否改为更准确的活动类型；另外真机 AirPrint dogfood 尚未完成。
- **设计裁决（仅本模块）**：
  - **去答案是布局层操作**（隐藏答案文字字段后排版），不触碰原资料答案数据，与候选图片处理增强的技术路径完全分离。
  - ShareCard 单题渲染**不共享** PDF 批量管线（避免为单题强行复用批量流水线，design §简洁单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 唯一资料库中有 `N >= 1` 条可导出资料，When 以每页 `itemsPerPage` 条发起基础 PDF 导出，Then PDF 无封面、物理页数严格为 `ceil(N / itemsPerPage)`、每条选定资料恰好出现一次且每条至少有一种可读内容，并提供系统预览、打印、分享与保存（UC5）。
  - Given manifest 纳入某个 PDF 增强或单条快速打印，When 用户使用该能力，Then 它通过对应 fidelity / printing oracle，且基础多选 PDF 与系统打印不依赖它。
- **边界 / 异常**：
  - 导出结果集为空 → 不生成空文件，提示"无可导出资料"（UC5 Exception）。
  - 文件写入失败 / 磁盘空间不足 → 不提示导出成功；已生成临时文件必须清理（UC5 Exception / Boundary B07）。
  - 无 AirPrint 打印机 → 停留在打印前状态并给出失败反馈，不得误记为已打印（UC5 Exception）。
  - complete operation 正在建立或持有 barrier → 已 detached 的 selected PDF / CSV snapshot 可完成；尚未取得 snapshot 的新请求立即显示 busy 失败，不排队、不生成文件。
- **数据保证**：
  - PDF 内容必须来自当前过滤结果或当前选择结果，不得夹带遗留容器或资料库外数据。
  - 若 manifest 纳入去答案模式，它只影响导出内容，**不改动原题答案数据**。
  - 导出与打印是**只读操作**，不得修改题目主数据、复习状态或统计。
  - selected PDF / CSV 不声明或推断未选资料、完整 taxonomy inventory、恢复能力或完整资料库时间点。
- **NFR**：
  - PDF 导出 < 5 秒（50 条资料，点击导出到预览页显示）；快速打印 < 3 秒只在 manifest 纳入该 optional 时适用。
  - PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。
  - 若 manifest 纳入 CSV 导出，以 `=+-@` 开头的值前加 tab（CSV 注入防护；属同级数据导出）。


## 5. Contracts（PDF / 分享 / 打印）

### A. 输入与输出

- 导出入口必须传入明确的资料集合和选项；空集合不得进入 PDF 渲染器，也不得生成空 PDF/CSV。
- 基础 PDF 第一张物理页就是内容页；不得生成未计入页码或纸张数量的强制封面。
- PDF、分享、打印结果必须区分 completed / cancelled / failed；用户取消不等于失败。
- 导出成功只能在文件生成或系统交互完成后提示，不得在后台任务启动时提前宣称成功。

### B. 分享与打印

- 分享走系统 share sheet；打印走 `PrintPresenting` adapter 或系统打印面板。代码中的 iPad anchor 属非 shipping 实现约束，不构成 B7-A 的 iPad 发布承诺。
- 已知缺口：打印已通过 `PrintPresenting` adapter 接入系统打印面板；真实 AirPrint 打印机 dogfood 仍需补齐。
- 打印/分享失败必须用户可见，并保留 retry 路径。

### C. 活动追踪与隐私

- 导出、分享、打印、备份等长任务必须通过 `AppActivityTracker` 阻止会破坏一致性的并发数据操作。当前阻止 Profile 切换只是待退场实现机制，不是产品契约。
- PDF 渲染应使用 autoreleasepool 防 OOM；导出内容不得重新引入图片 EXIF GPS/位置信息。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| completed/cancelled/failed 三态 | `PrintPresenting` tests + dogfood |
| shipping iPhone 打印呈现 | UI test / simulator route test |
| 空集合不导出 | Export service tests |
| 无封面与物理页数 | PDF page-count / first-page content tests + 打印预览 dogfood |
| 活动追踪 | AppActivityTracker 契约测试 + 编辑保存活动类型后续收敛 |
| D4S-A partial export | barrier 前 detached snapshot 完成 + barrier 后新请求立即 busy 失败、零产物的并发契约测试 |
| 真机打印 | dogfood 待验 |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../product/vision.md`（P4 用户拥有数据 / P2 简洁） | 导出/打印是价值链一等终点；数据可导出可打印可带走；不损害录入/管理简洁 |
| Release 1 PRD | `../../product/release-1-prd.md` C2-Core / C2-Optional / C5-E / C5-S1 / D2-A / D4S-A | 打印是独立终点，分享 / 保存不能替代；基础 PDF 无封面且页数闭合；selected export 只作 partial snapshot；增强项与 SmartPaper 不能顺带扩张 |
| 结果 / 发布证据消费者 | `../../product/release-1-prd.md` C6-A | 真实打印结果可供发布 gate 取证；不表示本 feature 拥有 release-operations 裁决或已经完成验证 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | Release 1 免费、无广告、无 IAP；Word / 图片增强只作候选，不作为升级承诺 |
| 待验证假设 | `../../explanations/assumptions.md` H3（导出/打印是归档后的高价值终点） | 导出/打印使用率验证 H3 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../product/vision.md`（P4 数据属于用户）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 6：导出 / 打印，含去答案 / 留白 / 快速打印）
- 商业政策：`../../explanations/business-model.md`
- 下游 / 相关 feature：`../backlog/feat-smartpaper.md`、`../backlog/feat-word-export.md`、`feat-review.md`
