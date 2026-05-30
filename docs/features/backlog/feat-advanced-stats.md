---
id: feat-advanced-stats
title: 高级统计（Pro）
status: blocked         # implemented | in-progress | blocked | poc-needed | backlog
tier: pro              # free | pro
blocked_by: [479]      # StoreKit 未接，Pro 不可达
mode: lightweight      # backlog：仅 Why + What 必填
last_updated: 2026-05-30
---

# Feature: 高级统计（Pro）

> 人读摘要：⛔ 阻塞（Pro，blocked_by #479）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / ADR-001 / architecture 聚合（docs 重组 B）。
> `mode: lightweight`（backlog）：How / Verify 仅承载源文档已落档的事实，未实现/未定的不编造。

## 1. 为什么做 (Why)
- **痛点 / 价值**：基础统计（总题数、按科目计数、近期趋势）让家长有"成就感"，但回答不了"补习哪里、练什么难度的题"。高级统计为家长提供**决策依据**——通过趋势图 + 难度分布 + 薄弱排行 + 交叉筛选，定位孩子的薄弱环节，是 Pro 的"专业感"层。
- **转化定位**：高级统计提升 Pro 专业感和长期价值；与智能组卷形成转化闭环——看到薄弱点 → 一键生成针对性练习卷 → 打印 → 练习 → 再次统计（两个 Pro 功能转化力叠加）。智能组卷是 Pro 核心转化引擎，高级统计提供深度洞察。
- **原则归属**：P3 免费即门槛（基础统计永久免费、不锁基础能力，付费只解锁增值"深度洞察"）+ P5 家长友好 / 不贩卖焦虑（数字只显示事实，不做完成度比较、不做焦虑诱导）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **核心能力（Hybrid 分层，ADR-001）**：
  - **免费层（基础统计，已实现，主 Dashboard 可见）**：总题数、按科目计数、近 7/30 天简单趋势 + 各学科分布。口径与字段由 `feat-review.md` 的 Dashboard 定义、本功能仅在 Pro 层之上扩展。
  - **Pro 层（趋势图 / 薄弱排行 / 交叉筛选，阻塞 #479）**：学科趋势图 + 难度分布 + 薄弱排行 + 交叉筛选（学科 × 难度 × 时间窗叠加）。
- **入口**：Dashboard 快捷入口 + 设置/统计页完整视图。
- **Analytics → Smart Paper 联动**：用户可基于薄弱排行一键进入智能组卷生成针对性练习卷（联动仅传题目 ID）。
- **边界 / 不做**：
  - Pro 图表区域对免费用户显示**模糊预览 + Pro 引导**（展示价值再转化），不暗示"再不订阅就看不到"（防焦虑，vision §不贩卖焦虑 / business §防焦虑条款）。
  - 数据不足以生成趋势时显示"数据积累中"提示，不展示误导性图表。
  - 统计基于**当前 Profile**，不跨 Profile 聚合。
- **前置依赖**：依赖 `feat-review.md` 产出的 SM-2 复习记录（正确率 / 薄弱判定的数据来源）+ 题库（学科 / 难度元数据）。
- **商业分层**：基础统计 = 免费；趋势图 / 难度分布 / 薄弱排行 / 交叉筛选 = Pro（Hybrid，ADR-001）。订阅取消后高级统计图表回到免费层基础统计、数据完整保留。定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How)
> backlog · lightweight：以下为源文档（architecture / design）已落档的实现归属与机制；Pro gating 与深度图表细节待 #479 StoreKit 落地后随 #567 实现补全。

- **模块归属**：数据源 `SnapDrillData/RepositoryContainer` 各 Repository 聚合查询；聚合层 `SnapDrillFeatureDashboard/DashboardAnalyticsViewModel`；图表渲染用 SwiftUI Charts 框架（iOS 16+，原生可视化）。
- **Pro gating**：通过 `ProEntitlementProvider` 控制可见性（ADR-001 Hybrid，免费层只看基础指标）；当前 `isProUser` 硬编码 false（#479 未接），Pro 分支不可达。
- **State & Concurrency**（Swift 6 strict）：待实现补 / 随 #567 落档（统计聚合查询应走 Repository → `DataExecutor` actor，不阻塞主线程；与 `feat-review.md` Dashboard 字段同一聚合路径——具体 @Observable 归属与 actor 边界以实现为准，避免编造）。

## 4. 验证标准 (Verify)
> backlog · lightweight：Success path 承接 cases UC9；Pro 分支当前不可达（`isProUser=false`），Pro 分支不作回归基线，待 #479 落地后补全 GWT。

- **Success path (GWT，承接 UC9)**：Given 当前 Profile 题库有题目数据，When 用户从 Dashboard 快捷入口或统计页进入高级统计，Then 免费用户看到基础统计（总题数 / 按科目计数 / 近期趋势）；Pro 用户（落地后）看到完整图表（学科趋势图 + 难度分布 + 薄弱排行 + 交叉筛选），并可基于薄弱排行一键进入智能组卷。
- **边界 / 异常**：
  - 免费用户查看 Pro 图表区域 → 显示模糊预览 + Pro 引导。
  - 题目数据不足以生成趋势 → 显示"数据积累中"，不展示误导性图表。
  - 跨学科筛选 → Pro 用户可叠加学科 + 难度 + 时间窗；免费用户仅按学科切换。
  - 统计数据计算失败 → 保留上次缓存结果，提示"数据正在更新"，不展示空白页。
- **数据保证**：统计仅基于当前 Profile 的题库与复习记录，不跨 Profile 聚合；图表结果与题库实际数据一致，删题 / 改难度后下次进入页面必须刷新；"薄弱排行 → 智能组卷"联动仅传题目 ID，不携带跨 Profile 数据。
- **NFR**：装饰性统计数字随系统 Dynamic Type 缩放（`tech/non-functional-requirements.md` §Dynamic Type）。其余性能 / 埋点 NFR 待 #567 实现补。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（决策依据 / 专业感层 / 联动转化） | design §高级统计设计·核心理念 + business §分层原则 + ADR-001 §联动策略 |
| Why（原则归属 P3 / P5·防焦虑） | vision §产品原则 3 免费即门槛 + §6 防焦虑边界 |
| What（Hybrid 分层 / 免费 vs Pro 字段） | requirements §Dashboard 字段表 + §功能状态总表 + business 付费对照表 + ADR-001 §高级统计决策 |
| What（入口 / 模糊预览 / 数据不足 / 联动） | design §高级统计设计·设计决策 + cases UC9 Variants |
| What（前置依赖 SM-2 数据） | vision §核心价值链 + feat-review 被依赖关系 |
| What（订阅取消降级） | business §订阅取消后数据降级策略 |
| How（模块归属 / Repository 聚合 / Swift Charts / Pro gating） | tech/architecture.md §高级统计（Pro 增值，Dashboard Hybrid 路径）+ design §设计决策 |
| Verify（success / 边界 / 数据保证） | cases UC9 Success path + Variants & Exceptions + Data guarantees |
| Verify（NFR Dynamic Type） | tech/non-functional-requirements.md §Dynamic Type |

## 关联
- 原则：`../../explanations/vision.md`（P3 免费即门槛 / P5 家长友好 · 不贩卖焦虑）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 12：考前精准组卷 Analytics → Smart Paper → Print）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（高级统计 Hybrid 定价）
- 依赖 / 相关 feature：`feat-review.md`（SM-2 复习数据，被依赖方）、`feat-smartpaper.md`（薄弱排行 → 智能组卷联动）
