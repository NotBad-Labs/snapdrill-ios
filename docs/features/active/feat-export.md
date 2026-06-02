---
id: feat-export
title: PDF 导出与打印
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: PDF 导出与打印

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech architecture / NFR 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：家长录题的最终目的是让孩子在纸上练习——导出/打印是产品价值链的终点（采集 → 管理 → **导出/打印**）。"数据属于用户"不是口号，而是可导出、可打印、可带走；缺失基础导出 = 数据被锁在 App 中。
- **定位**：PDF 导出是**日常导出主入口**、基础能力，覆盖「整理一份错题卷打印给孩子练」的核心场景；增强导出（去答案、留白、页眉页码）是价值链增值（Kano Performance/Should），不是付费墙。
- **原则归属**：P4 数据属于用户（可导出/可打印/可带走）。任何功能若损害"录入/管理"的简洁性就不该做——导出/打印作为价值链终点服从此铁律。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **PDF 导出（基础，免费）**：题库页过滤后批量导出，含**导出前预览**，支持分享与打印。
- **PDF 增强（免费）**：
  - **去答案打印模式**：隐藏答案文字字段，只留题目，面向考前练习（布局层操作）。
  - **留白答题区**：题目下方留白供孩子手写作答。
  - **页眉页码**：打印后纸质卷可翻阅定位。
- **快速打印（免费）**：面向"临时打一道题"的轻量场景。详情页选中单题直接打印（固定 1 题/页）；批量导出/打印支持每页题数可选（1/2/4 题），直接调用系统打印。
- **边界 / 不做**：
  - 不做导出水印；不在导出中嵌入广告或 Pro 引导；不嵌入「上传云盘/分享社交网络」类公开传播引导（版权合规：导出/打印面向个人使用）。
  - **本 feature 只覆盖 PDF 导出与打印**。JSON / CSV 结构化数据导出是同级数据导出能力（隐私设置页/题库面板，GDPR 数据可携带权），`.zip` 全量备份/恢复是独立 feature；本 spec 不展开。
  - **"去答案打印"（免费，隐藏答案字段，布局层）** 与 **"图片处理增强"（Pro，AI 去手写/去批改/试卷还原，图片层）** 是不同层面，不应混淆。
- **前置依赖**：无。智能组卷（`../backlog/feat-smartpaper.md`）**复用本 feature 的 PDFExportService 管线**作为输出末端——是本 feature 的下游消费方。
- **商业分层**：PDF 导出 + PDF 增强 + 单题/批量快速打印 = **免费基础能力，不作订阅门槛**。Word 高级排版导出（家长二次调整段落/页眉页码/字体后打印）= Pro 增值，是 PDF 导出的格式升级（见 `../backlog/feat-word-export.md`，阻塞 #486 前置 #479）。图片处理增强 = Pro（阻塞 #479）。定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How)
- **模块归属**：PDF 渲染/排版管线 `SnapDrillCore/Service/PDFExportService`（统一 PDF 引擎，注入于 `ServiceContainer.pdfExport`）；快速打印**目标**为 `UIPrintInteractionController` + 自定义 `UIPrintPageRenderer`（layoutN：1/2/4 题/页），将来抽出落 `SnapDrillCore/Service/PrintService.swift`。
  - **⚠ 实现现状（GAP-R5，代码债）**：当前快速打印为**过渡实现**——`LibraryDetailView` 单题打印生成 PDF 后经系统分享表（`UIActivityViewController` / ShareSheet，含 AirPrint 打印项）打印（多题/每页题数走导出预览 `ExportPreviewView`），**尚未接入** `UIPrintInteractionController` / `UIPrintPageRenderer`；每页题数直排打印（1/2/4 题/页）待真 AirPrint 补全。
- **关键机制 / 数据流**：题库过滤/选中结果集 → 题目快照 → PDFExportService 排版（去答案 / 留白 / 页眉页码为布局选项）→ 生成 PDF → 预览 → 分享/保存/打印。智能组卷、Word 导出均**复用同一 PDF 管线，不重新实现 PDF 引擎**（单一职责）。ShareCard 例外：用 SwiftUI `ImageRenderer`，不走 PDFExport 管线。
- **State & Concurrency**（Swift 6 strict）：导出/打印为只读编排。批量 PDF 渲染**逐页包 `autoreleasepool` 释放**控制峰值内存（防 OOM）；重活不阻塞主线程。PDF 导出预览经 `AppActivityTracker.begin(.exporting) → end(...)` 标记活动——期间禁止切换 Profile（互斥），UI 显示"正在导出中，请稍候"。
  - **⚠ 实现现状（GAP-R4，代码债）**：快速打印（`LibraryDetailView` 单题）当前**未接入** tracker，`.printing` 活动类型生产代码零调用、部分编辑路径误用 `.capturing`——快速打印期间 Profile 切换保护暂缺，待 code 债补全。（导出预览 `.exporting` 标记的实例一致性另受 KI-01 影响，见 `../../explanations/development-process.md` §5。）
- **设计裁决（仅本模块）**：
  - **去答案是布局层操作**（隐藏答案文字字段后排版），不触碰原题答案数据，与图片层的 Pro 图片处理增强技术路径完全分离。
  - ShareCard 单题渲染**不共享** PDF 批量管线（避免为单题强行复用批量流水线，design §简洁单一职责）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - Given 当前 Profile 下有可导出题目，When 在题库经搜索/过滤形成结果集并发起 PDF 导出，Then 系统生成导出前预览；用户可选去答案/留白/页眉页码，确认后生成 PDF 并提供预览、分享、保存（UC5）。
  - Given 选中单题或多题，When 发起快速打印并选择每页题数（1/2/4），Then 调用系统打印（UC5）。
- **边界 / 异常**：
  - 导出结果集为空 → 不生成空文件，提示"无可导出题目"（UC5 Exception）。
  - 文件写入失败 / 磁盘空间不足 → 不提示导出成功；已生成临时文件必须清理（UC5 Exception / Boundary B07）。
  - 无 AirPrint 打印机 → 停留在打印前状态并给出失败反馈，不得误记为已打印（UC5 Exception）。
- **数据保证**：
  - PDF 内容必须来自当前过滤结果或当前选择结果，**不得夹带其他 Profile 题目**。
  - 去答案模式只影响导出内容，**不改动原题答案数据**。
  - 导出与打印是**只读操作**，不得修改题目主数据、复习状态或统计。
- **NFR**：
  - PDF 导出 < 5 秒（50 题，点击导出到预览页显示）；快速打印 < 3 秒（4 题，选中到系统打印面板弹出）。
  - PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。
  - 导出 CSV 时以 `=+-@` 开头的值前加 tab（CSV 注入防护；属同级数据导出，列此供完整 NFR 参照）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（价值链终点 / P4 / 简洁铁律） | vision §核心价值链 + design §导出与打印设计 [P4] + business §免费层定义 |
| What（PDF 基础 / 增强 / 快速打印 / 分层） | requirements §导出与打印能力 + 功能全景 + design §导出与打印设计 + business 免费层 §导出 |
| What（去答案 vs 图片处理增强 / 不做水印·广告 / 版权个人使用） | design §"去答案打印"与"图片处理增强"的区分 + §不做什么 + §版权合规边界 |
| What（智能组卷复用管线为下游） | design §智能组卷设计 + architecture §Smart Paper |
| How（PDFExportService / PrintService / ImageRenderer 边界） | architecture §Smart Paper + §ShareCard + §1/2/4 题快速打印 |
| How（autoreleasepool / AppActivityTracker 互斥） | NFR §内存 + requirements §AppActivityTracker 互斥 + architecture §切换保护 |
| Verify（success / 边界 / 数据保证） | cases UC5 + Boundary B07 |
| Verify（NFR 性能 / 内存 / CSV 注入） | NFR §性能 + §内存 + §CSV 注入防护 |

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 6：过滤→导出 PDF→打印；旅程 7：导出打印；旅程 11：预览并打印）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（智能组卷复用本管线 / Pro 分层）
- 下游 / 相关 feature：`../backlog/feat-smartpaper.md`、`../backlog/feat-word-export.md`、`feat-review.md`
