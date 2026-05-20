---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 2 — 三方对抗共识报告（反向溯源）

> **日期**：2026-05-20 | **维度**：2 反向溯源（requirements → vision） | **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」，三家独立审 `product-requirements.md` 全部功能反推回 `product-vision.md` 价值主张。[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (6 findings + 1 自驳)
> - Codex 桌面端：本会话上下文 (7 findings + 4 自驳)
> - Antigravity：[`semantic-audit-dim2-findings.md`](semantic-audit-dim2-findings.md) (6 findings)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) 追加维度 2 段

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 总 finding 数 | 6 | 7 | 6 |
| HIGH | 0 | 0 | 1 |
| MEDIUM | 0 | 3 | 2 |
| LOW | 4 | 3 | 3 |
| INFO | 2 | 1 | 0 |
| 自驳 / REJECTED | 1 | 4 | 0 |

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **3/3 全共识** | 1 | HIGH×1 |
| **2/3 共识** | 4 | MEDIUM×2 LOW×2 |
| **1/3 单家可采纳** | 6 | LOW×4 INFO×2 |
| **Reconcile 撤回 / 自驳** | 3 | — |
| **合计可采纳** | 11 | HIGH×1 MEDIUM×2 LOW×6 INFO×2 |

## 3/3 全共识

### S-D2-001 [HIGH, 3/3] — CSV 数据导入

- Claude (LOW ORPHAN) / Codex (MEDIUM 半 ORPHAN) / Antigravity (HIGH ORPHAN)
- 三家一致认定 ORPHAN，但 Antigravity 论证最深刻：CSV 导入违反 vision §「图片是真相 Image is Truth」核心定位 + P2 简洁原则。Pure text 导入会把工具拖向 Anki 式重度文本记忆库
- **维度 1 已标 S-D1-002 HIGH (架构层断链)，维度 2 这个是反向溯源 ORPHAN，同一域不同视角双重命中**——这个功能不该存在的信号最强

**修复方向**：从 requirements 撤回 CSV 导入功能，或 vision/design 显式加「不支持非图片数据导入」负向声明。两条路径需 PO 决策。

## 2/3 共识

### S-D2-002 [MEDIUM, 3/3 reconcile 后] — 分享卡片「社交分享」用途字眼违反非社交红线

- Codex (MEDIUM 反向冲突) / Antigravity (MEDIUM 反向冲突) / **Claude 原标 REJECTED 已撤回**
- Claude 自驳依据：仅看了 vision §成功信号 line 178「非社交功能」，没去查 requirements line 104 数据可携带权矩阵实际文字
- **实锤**：`requirements.md:104` 写「分享卡片 \| 单题生成图片 \| 社交分享 \| ✅」——「社交分享」字面违反 vision §不是社交产品红线

**修复方向**：requirements line 104「主要用途」字段从「社交分享」改为「单题打印 / 多设备手动传送 / 家长协作」；Design 加 ShareCard 设计段强化非社交约束。

### S-D2-003 [MEDIUM, 2/3] — AI 解题提示蚕食非内容平台禁令

- Codex (MEDIUM 反向冲突) / Antigravity (MEDIUM 反向冲突) — Claude 漏
- requirements line 270/370「待评估」列出 AI 解题提示，与 vision §「不是内容平台——不提供题库、课本、试卷」直接冲突；vision H3 推翻信号明确写「用户频繁要求题库/解题」作为定位偏离

**修复方向**：requirements 撤回 AI 解题提示规划，或在 design 加严格隔离防线「仅一句话考点概念，禁直接给步骤/答案」。

### S-D2-004 [LOW, 2/3] — Word 导出 Pro 定价层无 vision 承接

- Claude / Antigravity (LOW 半 ORPHAN) — Codex 漏
- vision Pro 三大引擎明确点名 iCloud / 智能组卷 / 图片增强；Word 导出未在 vision Pro 价值主张出现
- Antigravity 进一步指出：vision §iCloud 变现承载能力风险段仅把「高级导出格式（Word）」列为「替代或补充变现路径」（二线储备），requirements 直接把它升级为 v2.0 阻塞链（#486 阻塞），是战略错位

**修复方向**：requirements 解除 Word 导出对 StoreKit (#486) 的硬阻塞——MVP 首发可不带 Word，作为 post-launch 储备变现。

### S-D2-005 [LOW, 2/3] — iPad + Apple Pencil 价值论证缺失

- Codex / Antigravity (LOW 半 ORPHAN) — Claude 漏
- vision §市场与平台仅声明 iOS/iPadOS 唯一平台，Pencil 未在 vision/design 任何位置作为价值锚点出现
- Antigravity 提出具体论证路径：Pencil 集成需绑定「孩子 iPad 手写作答」或「家长 Pencil 涂抹遮罩答案/裁剪试卷」具体 P1 场景

**修复方向**：requirements 维持 PoC 状态，不升级正式 feature；design 补 Pencil 与价值链锚点的绑定论证。

## 1/3 单家可采纳

| Finding ID | 单家 | 严重度 | 描述 |
|---|---|---|---|
| **S-D2-006** | Claude | LOW | 复习卡片字号正反面独立设置无 vision 承接（与维度 1 S-D1-003 Dynamic Type 混淆配套）|
| **S-D2-007** | Claude | INFO | 全模块 VoiceOver — vision 完全缺 accessibility 价值主张 |
| **S-D2-008** | Antigravity | LOW | 每日复习目标设置与 vision §不贩卖焦虑张力（缺防焦虑设计约束）|
| **S-D2-009** | Codex | LOW | 角色预设套件 vision 无承接 |
| **S-D2-010** | Codex | LOW | 多科目模板 vision 无承接 |
| **S-D2-011** | Codex | INFO | 批量导出原图 ZIP 独立价值未论证（建议合并到数据可携带权矩阵）|

## Reconcile 撤回 / 自驳

| Finding ID | 撤回方 | 撤回依据 |
|---|---|---|
| **S-D2-R01** | Claude 原标「分享卡片」REJECTED | requirements line 104 实文字「社交分享」字面违反 vision；接受 Codex/Antigravity 升为 S-D2-002 (MEDIUM) |
| **S-D2-R02** | Claude 原标「端上 AI 自动标注」LOW 半 ORPHAN | Antigravity 论证 vision P1 录入体验 + P4 零 PII + P6 原生优先三原则闭环承接；列入"正面典型"段 |
| **S-D2-R03** | Claude 原标「OCR 复制剪贴板」INFO 半 ORPHAN | vision P4 数据属于用户 + §支持导出 可承接 OCR 文本被用户取走 |
| **S-D2-R04** | Claude 原标「Dashboard 统计贩卖焦虑」自驳 | Dashboard 显示中性事实数字不属于 vision §不贩卖焦虑明确点名的三类（今日仅剩 X 题/连续天数/成就弹窗）|
| **Codex 自驳** | 4 项 | 基础 SM-2 / iCloud / 智能组卷 / 图片处理增强——Codex 在自家审计中已标为 REJECTED 误判（可回溯）|

## Antigravity 正面典型段（值得保留）

Antigravity 在维度 2 输出新增了「亮点：反向溯源高度一致的优秀实践」段，识别 3 个完美承接案例：

1. **不使用角标 (Badge)** — 完美承接 P2 简洁 + P5 防焦虑
2. **端上 AI 自动标注 (Foundation Models)** — 完美承接 P1 + P4 + P6 三原则闭环
3. **使用数据独立 opt-in 开关 (Analytics/Crashlytics 分离)** — 完美承接 P4 隐私 + 合规

**评估**：这是 Antigravity 新加的行为模式（维度 1 没有正面案例段）。可能是 over-endorse 病灶的潜在前兆（输出越来越"全面平衡"），但因为同时给出了 6 项真 finding（含 1 HIGH），暂不构成 over-endorse 复现。**继续监控维度 3-7**。

## Gemini 3.5 over-endorse 持续监控（维度 2 数据点）

| 指标 | 维度 1 | 维度 2 |
|---|---|---|
| HIGH 占比 | 33% (4/12) | 17% (1/6) |
| 100% VALID 倾向 | ❌ | ❌ |
| 抓到独家致命 finding | ✅ Dynamic Type 混淆 | ✅ CSV 导入违反「图片是真相」(论证最深) |
| 误判数 | 2 | 0 |
| 新增行为 | — | 加正面典型段 |

**累计结论**：仍未复现 over-endorse 病灶。Antigravity 新加正面段是行为变化点，需在维度 3-7 持续观察。如果出现「finding 越来越少 + 正面段越来越长」的趋势再触发降权重。

## 下一步

1. **本会话**：commit 共识报告 + ledger 维度 2 追加 + ADR-005 更新
2. **下一会话**：维度 3「内部冲突扫描」（vision「不是 Anki」是否被 SM-2 间接违反 + 其他价值主张同法扫描）
3. **累计 OPEN finding**：维度 1 (22) + 维度 2 (11) = **33 项**，按用户决策跑完 7 维度集中入 PR
