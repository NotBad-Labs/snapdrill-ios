---
id: feat-export
title: PDF 导出与打印
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-12
intent_refs:
  - vision:P2
  - vision:P4
---

# Feature: PDF 导出与打印

> **产品重基线（2026-07-12）**：导出 / 打印与永久手动备份属于宪章核心承诺，但 frontmatter 与下文只记录当前实现，具体格式、入口和结果级验收等待 Gate C / Release 1 Product Contract。B6-A 已取消当前 Pro 商业承诺；下文 Word、图片增强、SmartPaper、Profile 和 Pro 分层只作实现 / 历史追溯，不得驱动新工作。

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户归档资料的最终目的之一是把内容输出到纸上或其他工作流——导出 / 打印是产品价值链的终点（采集 → 整理 / 找回 → **导出 / 打印**）。"数据属于用户"不是口号，而是可导出、可打印、可带走；缺失基础导出会把数据锁在 App 中。
- **定位**：PDF 导出是**日常导出主入口**、基础能力，覆盖「整理一份资料并打印出来用」的核心场景；增强导出（去答案、留白、页眉页码）是价值链增值（Kano Performance/Should），不是付费墙。
- **原则归属**：P4 数据属于用户（可导出/可打印/可带走）。任何功能若损害"录入/管理"的简洁性就不该做——导出/打印作为价值链终点服从此铁律。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **PDF 导出（基础，免费）**：资料库过滤后批量导出，含**导出前预览**，支持分享与打印。
- **PDF 增强（免费）**：
  - **去答案打印模式**：隐藏答案文字字段，只留题目内容，面向自测 / 回顾（布局层操作）。
  - **留白区**：题目下方留白供用户手写补充。
  - **页眉页码**：打印后纸质资料可翻阅定位。
- **快速打印（免费）**：面向临时打印一条资料的轻量场景。详情页选中单条直接打印；批量导出 / 打印的版式选择属于当前实现，Release 1 具体选项等待 Gate C。
- **边界 / 不做**：
  - 不做导出水印；不在导出中嵌入广告或 Pro 引导；不嵌入「上传云盘/分享社交网络」类公开传播引导（版权合规：导出/打印面向个人使用）。
  - **本 feature 只覆盖 PDF 导出与打印**。JSON / CSV 结构化数据导出是同级数据导出能力（隐私设置页 / 资料库面板），`.zip` 全量备份 / 恢复是独立 feature；本 spec 不展开。
  - **"去答案打印"（隐藏答案字段，布局层）** 与候选的图片处理增强（图片层）是不同层面，不应混淆；图片增强不是当前 Pro 或 Release 1 承诺。
- **前置依赖**：无。智能组卷（`../backlog/feat-smartpaper.md`）**复用本 feature 的 PDFExportService 管线**作为输出末端——是本 feature 的下游消费方。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；已纳入 Release Contract 的导出 / 打印能力不得承担升级转化。Word 与图片增强只是候选假设，不是 Pro、价格或发布时间承诺。

## 3. 技术设计 (How)
- **模块归属**：PDF 渲染/排版管线 `SnapDrillCore/Service/PDFExportService`（统一 PDF 引擎，注入于 `ServiceContainer.pdfExport`）；打印呈现走 `SnapDrillUI/PrintPresenting` adapter（生产默认 `LivePrintPresenter`，内部使用 `UIPrintInteractionController`，iPad 需要有效 anchor）。
  - **实现现状（GAP-R5 已接入，剩余 dogfood）**：`LibraryDetailView` 单题快速打印生成 PDF 后调用 `PrintPresenting.present(...)`；`ExportPreviewView` 的批量打印同样通过 `PrintPresenting`。旧 spec 所称"经 ShareSheet 间接打印、尚未接入 `UIPrintInteractionController`"已过期。剩余真实缺口是无 AirPrint 打印机 / 真机 AirPrint 三态 dogfood 尚未完成。
- **关键机制 / 数据流**：资料库过滤 / 选中结果集 → 资料快照 → PDFExportService 排版（去答案 / 留白 / 页眉页码为布局选项）→ 生成 PDF → 预览 → 分享 / 保存 / 打印。候选 SmartPaper / Word 若未来回归，应优先复用管线而非重建 PDF 引擎。ShareCard 例外：用 SwiftUI `ImageRenderer`，不走 PDFExport 管线。
- **State & Concurrency**（Swift 6 strict）：导出/打印为只读编排。批量 PDF 渲染**逐页包 `autoreleasepool` 释放**控制峰值内存（防 OOM）；重活不阻塞主线程。PDF 导出预览经 `AppActivityTracker.begin(.exporting) → end(...)` 标记活动；单题快速打印与预览页打印经 `AppActivityTracker.begin(.printing) → end(...)` 标记活动——期间禁止切换 Profile（互斥），UI 显示对应忙碌提示。
  - **实现现状（GAP-R4 已接入，剩余 caveat）**：旧 spec 所称"快速打印未接入 tracker、`.printing` 生产代码零调用"已过期。当前剩余真实缺口是 `LibraryEditViewModel.save()` 仍使用 `.capturing` 标记编辑保存，需后续判断是否改为更准确的活动类型；另外真机 AirPrint dogfood 尚未完成。
- **设计裁决（仅本模块）**：
  - **去答案是布局层操作**（隐藏答案文字字段后排版），不触碰原资料答案数据，与候选图片处理增强的技术路径完全分离。
  - ShareCard 单题渲染**不共享** PDF 批量管线（避免为单题强行复用批量流水线，design §简洁单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 唯一资料库中有可导出资料，When 经搜索 / 过滤形成结果集并发起 PDF 导出，Then 系统生成导出前预览；用户确认后生成 PDF 并提供预览、分享、保存（UC5）。
  - Given 选中单题或多题，When 发起快速打印并选择每页题数（1/2/4），Then 调用系统打印（UC5）。
- **边界 / 异常**：
  - 导出结果集为空 → 不生成空文件，提示"无可导出资料"（UC5 Exception）。
  - 文件写入失败 / 磁盘空间不足 → 不提示导出成功；已生成临时文件必须清理（UC5 Exception / Boundary B07）。
  - 无 AirPrint 打印机 → 停留在打印前状态并给出失败反馈，不得误记为已打印（UC5 Exception）。
- **数据保证**：
  - PDF 内容必须来自当前过滤结果或当前选择结果，不得夹带遗留容器或资料库外数据。
  - 去答案模式只影响导出内容，**不改动原题答案数据**。
  - 导出与打印是**只读操作**，不得修改题目主数据、复习状态或统计。
- **NFR**：
  - PDF 导出 < 5 秒（50 题，点击导出到预览页显示）；快速打印 < 3 秒（4 题，选中到系统打印面板弹出）。
  - PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。
  - 导出 CSV 时以 `=+-@` 开头的值前加 tab（CSV 注入防护；属同级数据导出，列此供完整 NFR 参照）。


## 5. Contracts（PDF / 分享 / 打印）

### A. 输入与输出

- 导出入口必须传入明确的资料集合和选项；空集合不得生成空 PDF/CSV/ZIP。
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
| 活动追踪 | AppActivityTracker 契约测试 + 编辑保存活动类型后续收敛 |
| 真机打印 | dogfood 待验 |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P4 用户拥有数据 / P2 简洁） | 导出/打印是价值链一等终点；数据可导出可打印可带走；不损害录入/管理简洁 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | Release 1 免费、无广告、无 IAP；Word / 图片增强只作候选，不作为升级承诺 |
| 待验证假设 | `../../explanations/assumptions.md` H3（导出/打印是归档后的高价值终点） | 导出/打印使用率验证 H3 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 6：导出 / 打印，含去答案 / 留白 / 快速打印）
- 商业政策：`../../explanations/business-model.md`
- 下游 / 相关 feature：`../backlog/feat-smartpaper.md`、`../backlog/feat-word-export.md`、`feat-review.md`
