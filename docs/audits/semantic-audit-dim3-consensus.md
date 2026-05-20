---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 3 — 三方对抗共识报告（内部冲突扫描）

> **日期**：2026-05-20 | **维度**：3 内部冲突扫描（vision 防线被下游间接违反）| **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」，三家独立扫描 vision 全部硬约束 vs design/requirements/business/tech 是否被间接违反。[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (6 finding：0H/0M/2L/4I)
> - Codex 桌面端：本会话上下文 (6 finding：1H/3M/2L)
> - Antigravity：[`semantic-audit-dim3-findings.md`](semantic-audit-dim3-findings.md) (6 finding：1H/3M/2L)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D3-001 ~ S-D3-010 + S-D3-W01

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 总 finding 数 | 6 | 6 | 6 |
| HIGH | 0 | 1 | 1 |
| MEDIUM | 0 | 3 | 3 |
| LOW | 2 | 2 | 2 |
| INFO | 4 | 0 | 0 |

**Codex 和 Antigravity 6/6 项完全对应**，是三轮里最高的对抗一致度。Claude CLI 形态明显不同——抓的都是「文档表述层小瑕疵」，错过了 vision 假设层和商业层的深层冲突。

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **3/3 全共识** | 1 | MEDIUM×1 |
| **2/3 共识 (Antigravity+Codex)** | 5 | HIGH×1 MEDIUM×2 LOW×2 |
| **1/3 单家 (仅 Claude)** | 4 | LOW×2 INFO×2 |
| **WAIVED** | 1 | — |
| **合计 OPEN** | **10** | HIGH×1 MEDIUM×3 LOW×4 INFO×2 |

## 3/3 全共识

### S-D3-002 [MEDIUM, 3/3] — 「不做推荐算法」红线 vs 智能组卷「算法推荐选题」表述冲突

三家同域命中（Claude 标 INFO 边界微妙，Antigravity/Codex 标 MEDIUM 字面冲突 + 宣发风险）。**Vision §P4 line 133 写「不做推荐算法」绝对红线**，但 design §智能组卷 line 293/301 + requirements §v2.0 line 323 均使用「算法驱动精准选题」「推荐薄弱题目」表述。

**Codex 一句话点穴**：「禁的是社交/内容流推荐，不禁本地、用户私有数据驱动的练习卷选题」——这是 Vision 应该明文补写的豁免边界。

**修复路径**：Vision 加豁免论证；下游措辞从「推荐」改为「本地选题/排序」。

## 2/3 共识（Antigravity+Codex 联袂）

### S-D3-001 [HIGH, 2/3] — H2 与 SM-2 翻卡评估的主体逻辑死锁

**最深刻的 finding**。Vision H2 line 64-72 + §产品原则 P5 line 144 明确「小学阶段家长是唯一用户，孩子不碰手机」，但 design §复习设计 line 385-396 + requirements line 309-311 把 SM-2 做成「翻卡 + 记得/不记得」**主观自我评估**——家长不可能凭空知道孩子记不记得，必须把手机递给孩子（违反 H2）或代扣（违反 P5 零学习曲线）。

**两难困境**：
- 坚持 H2 → SM-2 端上翻卡在小学多孩场景沦为空载功能
- 让 SM-2 运转 → 孩子频繁碰手机，推翻 H2 核心假设

**修复路径**：Vision 澄清「小学 Profile 下 SM-2 改为家长被动打标」；Design 加 Profile 级 UI 折叠端上翻卡入口；或 Vision 重审 H2 假设。

### S-D3-003 [MEDIUM, 2/3] — 订阅取消降级 vs P4 数据属于用户

Business `product-business.md:76-79`「订阅取消后数据降级策略」把「只读 / 限制编辑 / 单设备继续」并列为待定方案。**「只读 / 限制编辑」直接侵蚀 P4 数据属于用户 + P3 免费完整闭环承诺**。

**修复**：Business 硬性承诺——取消订阅后本机已同步数据保持**完整编辑/导出/备份**，仅停跨设备同步。

### S-D3-004 [MEDIUM, 2/3] — 图片增强完全 Pro 锁死 vs P1 物理鲁棒性生命线

Vision P1 line 110-115「真实拍摄环境鲁棒性是核心技术考量」，但 business §付费模式 + design §图片增强 把「去手写/去批改/试卷还原」完全锁 Pro 仅免费限次体验。**真实试卷满批改痕迹场景下，免费层 P1 生命线明显降质**。

**修复**：免费层加基础清理保底配额，或 Vision 承认该鲁棒性不属于基础录入范畴。

### S-D3-005 [LOW, 2/3] — 配额耗尽与模糊预览 UI 缺防焦虑约束

Design line 314-317（配额耗尽展示 Pro 引导）+ line 333（Pro 图表模糊预览）**没规定文案/颜色/打断程度**。可能漂移成红色告警 / 中断流程 / 「落后/错过/仅剩」类焦虑文案。

**修复**：Design 追加配额/付费墙交互铁律——客观冷静、不告警色、不中断、不焦虑文案。

### S-D3-006 [LOW, 2/3] — Declared Age Range API 集成 vs 默认不收集个人信息

Business line 177-178 + line 202 评估集成 Declared Age Range API（获取系统年龄范围），与 vision §P4「默认不收集」+ 隐私表述准确边界（line 137）有信任张力。

**修复**：Business 加硬边界——仅审核/法规要求时使用，仅端上即时判断，禁持久化/展示/上报，默认关闭。

## 1/3 单家可采纳（仅 Claude CLI）

| Finding ID | 严重度 | 描述 |
|---|---|---|
| **S-D3-007** | LOW | Dashboard「今日新增」文案约束缺口 — 配套 S-D3-005 但作用域不同（Dashboard 是首屏渲染影响面最大）|
| **S-D3-008** | LOW | Design line 394 冲突裁决 P1 范围漂移（复习交互归到 P1 录入体验）— 元规则层小漏洞 |
| **S-D3-009** | INFO | Vision §核心问题「订阅制高收费」批评措辞 vs SnapDrill 自身订阅制 — 表述瑕疵 |
| **S-D3-010** | INFO | Vision P6「不做跨平台妥协」字面 vs Architecture 含 Mantis/ZIPFoundation/Firebase（均 iOS-only）— 严格论可挑剔 |

## WAIVED

**S-D3-W01** — 外观三选项 vs HIG「跟随系统」单选。Design line 459 已自我说明「Apple 不因此拒审 + 行业惯例 Telegram/Bear/Notion」。已有论证，不算 finding。

## Gemini 3.5 over-endorse 持续监控（维度 3 数据点）

| 指标 | 维度 1 | 维度 2 | 维度 3 |
|---|---|---|---|
| HIGH 占比 | 33% (4/12) | 17% (1/6) | 17% (1/6) |
| 100% VALID 倾向 | ❌ | ❌ | ❌ |
| 抓到独家深度 finding | ✅ Dynamic Type | ✅ CSV vs Image is Truth | ✅ H2 vs SM-2 死锁（**与 Codex 高度一致，0 误判**） |
| 误判数 | 2 | 0 | 0 |
| 新增行为 | — | 「正面典型」段 | **抢跑落档**（写 ledger / 改 STATUS/handoff/ADR-005）|

**累计结论**：Gemini 3.5 三轮实测**未复现 over-endorse 病灶**，反向越来越锋利。但 Antigravity 在维度 3 出现**新的工作流违规**：未等三方齐就独立写共识落档（ledger / STATUS / handoff / ADR-005）。本会话已通过改进提示词模板（明文「严禁操作」段）封堵此漏洞，后续维度 4-7 适用。

## 抢跑事件后处理

Antigravity 抢跑写的 6 行 ledger 单家口径（1/3 Antigravity_Hit）已被本次 reconcile 覆盖为正确的三方共识口径：
- S-D3-001/003/004/005/006 改为 2/3 (Codex 也命中)
- S-D3-002 改为 3/3 (Claude C3.6 也命中同域)
- S-D3-007 ~ S-D3-010 + S-D3-W01 新增（Claude 独家 4 项 + WAIVED 1 项）

ADR-005 §维度 3 收官观察段 + STATUS/handoff 由 Antigravity 单家口径改回三方共识口径。

## 下一步

1. **本会话**：commit + push（已 reconcile 的 ledger + 新共识报告 + ADR-005 维度 3 段重写 + STATUS/handoff 校）
2. **下一会话**：维度 4「技术↔产品对齐」，使用改进提示词模板（明文「严禁操作」段）
3. **累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) = **43 项**
