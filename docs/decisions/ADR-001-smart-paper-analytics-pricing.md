---
last_verified: 2026-07-14
layer: decision
current_status: superseded
historical_record: true
current_authority: docs/explanations/business-model.md
derived_from:
  - ../product/vision.md#p3-免费层完成核心闭环
  - ../explanations/business-model.md
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, downstream_change]
---
# ADR-001: 智能组卷与高级统计定价模型

> 状态：**已被 Product Vision & Principles / Gate B6-A 取代，保留为历史记录** | 原决策日期：2026-04-10 | 取代裁决：2026-07-12 | 决策者：PO
>
> 本 ADR 的 Hybrid 配额、Pro 分层和转化联动不再是当前商业权威。Release 1 免费、无广告、无 IAP，未来 Pro / 定价只是候选假设；现行政策见 [`business-model.md`](../explanations/business-model.md)。Release 1 PRD C5-E / C5-S1 只允许 SmartPaper 在非公开实验 build 无配额、无 Pro 地出现，并固定无权重不重复基础 selector；当前代码中的配额与 Pro 分支只是实现偏差，不得从本历史 ADR 反推。

## 背景

智能组卷（Smart Paper, #566）与高级统计（Advanced Analytics, #567）的需求已定价、Pro 分层已决策（本 ADR）。两者的代码存在状态见 `../reference/feature-status.md` 的历史对应行；该索引不证明 Release 1 可达或商业边界。需要决定它们在免费/Pro 分层中的定位。

产品约束：
- 免费层 = 完整单设备产品体验（采集 → 管理 → 导出/打印）
- Pro 层 = iCloud 同步 + 图片处理增强（免费限次体验）+ 增值能力
- 原则：核心功能永久免费，不限录入数量，付费只解锁增值体验

## 选项

### 智能组卷

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A. 纯 Pro | 完全锁定在 Pro 层 | 形成明确付费理由 | 可能被感知为"把学习结果收费"，违反"完整免费体验" |
| B. 纯免费 | 完全免费 | 强化口碑和留存 | 把最强感知价值免费送出，压缩 Pro 卖点 |
| **C. Hybrid** | **免费有限次/月 + 基础模板；Pro 无限 + 精准选题 + 多版式** | **保留免费完整性与转化钩子** | 需精细设计配额 |

### 高级统计

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A. 纯 Pro | 完全锁定 | 符合行业常见做法 | 免费用户看不到价值 |
| B. 纯免费 | 完全免费 | 强化专业感 | 后续很难再卖更高阶洞察 |
| **C. Hybrid** | **基础统计免费（总题数、按科目计数、近期趋势）；趋势图+难度分布+薄弱排行 Pro** | **免费层增加留存，Pro 层提供深度洞察** | 需要界定免费/Pro 边界 |

## 三方研究摘要

Claude/Codex/Gemini 三方独立横向研究，竞品覆盖 Anki、Quizlet、GoodNotes、RemNote、Notion、Bear。

### 智能组卷

- **Claude**：建议 Pro。SM-2 算法超越核心价值链，Quizlet Smart Test 是付费先例
- **Codex**：建议 Hybrid。完全锁死可能触碰"学习结果收费"感知，GoodNotes/RemNote 用 quota 模式更稳妥
- **Gemini**：建议 Pro。算法驱动的自动化是支撑订阅的核心理由

共识：2:1 Pro，但 Codex 的 Hybrid 方案更符合产品"完整免费体验"原则。

### 高级统计

- **Claude**：Hybrid（基础免费 + 深度 Pro）
- **Codex**：Pro（含基础免费统计）
- **Gemini**：Hybrid（基础免费 + 深度 Pro）

共识：3/3 一致，基础统计免费 + 深度分析 Pro。

### Codex 独有洞察

提出联动策略：Analytics → Smart Paper → Print → Review。高级统计让用户看到薄弱点，一键生成针对性练习卷，两个 Pro 功能转化力叠加。

## 决策

采纳 Codex 的 Hybrid 方案（PO 批准）：

| 功能 | 免费层 | Pro 层 |
|---|---|---|
| 智能组卷 | 有限次/月 + 基础模板 | 无限生成 + 精准选题（weakness/difficulty/recency）+ 多版式 |
| 高级统计 | 总题数、按科目计数、近期简单趋势 | 趋势图 + 难度分布 + 薄弱排行 + 交叉筛选 |

与图片处理增强的"免费限次体验 + Pro 无限"模式统一。

## 后果

- `../reference/glossary.md` Pro 定义需更新
- product-business.md 免费/Pro 分层表需同步
- StoreKit 实现时需设计配额机制（月度重置）
- Analytics → Smart Paper 联动作为 Pro 卖点在 UI 中体现
