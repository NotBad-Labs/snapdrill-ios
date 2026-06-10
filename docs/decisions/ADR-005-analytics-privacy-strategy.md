---
last_verified: 2026-06-10
layer: decision
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, backend_analytics_added, kids_category_entry]
---
# ADR-005: 全球版分析与隐私遥测策略（端侧聚合 + Apple 免费层，不上后端行为采集）

> 状态：**已决策** | 日期：2026-06-10 | 决策者：PO | 关联：[[ADR-004]]（Firebase-free）/ [[ADR-002]]（ATT 移除）/ [[ADR-003]]（双区域，美国全球版为当前生产基线）

## 背景

PO 一直在纠结一件未完全想清的事：本人倾向不侵犯用户隐私、**绝不触碰用户内容数据**（拍的题、孩子作业、OCR 文本），但希望看到**匿名使用分析**（某页停留几秒、哪个功能用得多、一周用几次等）。核心疑问：想看匿名使用分析，是否构成侵犯隐私？

### 拆解（2026-06-10 讨论结论）

- **内容数据 vs 产品遥测是两回事**：前者敏感（永不碰，已是铁律）；后者是行为使用，正当且普遍，本身不侵犯隐私、更非人权问题。
- 隐私真正的判据不是"内容 vs 使用"，而是：**能否追到个人 / 数据离不离开手机 / 是否知情同意 / 比例是否恰当**。
- **"匿名"的陷阱**：带持久设备/安装 ID 的逐事件回传是**假名化（pseudonymous）**，GDPR/PIPL 仍当个人信息管；Firebase Analytics 默认即此。真匿名 = 聚合、无持久标识、无法还原到个人。
- **SnapDrill 是儿童邻近 app**（存孩子作业）→ 使用分析被**特别约束**：COPPA（儿童持久标识符原则上需可验证家长同意）、Apple Kids Category（完全禁第三方分析 SDK）、PIPL 儿童专章 / GDPR-K / UK AADC。

### 真正的叉口（D6）

不是"分析要不要"，而是**聚合在哪发生、什么离开手机**：

| | A. 端侧聚合 + Apple 免费层 | B. 后端回传（Firebase/PostHog） |
|---|---|---|
| PO 看得到 | Apple 聚合层全量可见；端侧细节须用户自愿快照 | 有 dashboard、逐事件 |
| 隐私/合规 | ≈零（无持久 ID、有同意、不触儿童约束） | 个人信息：披露 + 非必要同意 + 儿童 COPPA/Apple-kids + 真匿名工程 |
| 真匿名 | 天然是 | 须刻意保证 |

## 决策

**D6 = A：维持零采集 / 本地优先。全球版（美国生产基线）不上后端行为采集、不恢复 Firebase 分析。** 分析能力分三层叠加：

- **Layer 0 — Apple 免费聚合层**：App Store Connect App Analytics + TestFlight（留存 D1/D7/D28、会话、活跃设备、崩溃、删除率）——全量、无偏、零代码、零同意、不触儿童（Apple 自己聚合）。**这是核心 PMF 信号（留存/频率）的主来源。**
- **Layer A — 端侧 + 自愿快照**：MetricKit（聚合设备级遥测，顺关 RC-4 崩溃监控缺口）+ 本地账本（按功能计数 / 活跃天，**待实现**，参 PMF pitch）+ 用户自愿快照（显式同意才回传聚合、无持久 ID）。填 Layer 0 拿不到的功能级粒度。
- **Layer B — 后端回传**：**不上。** 运营 + 合规代价大、且对"产品是否 work"非必要（细粒度 dwell 是最不需要却代价最大的）。保留为将来某具体问题逼迫时的可逆选项。

### 理由

- **B 的代价不成比例**：B 唯一独占的是细粒度（逐事件 / dwell / 漏斗），恰是判断 PMF 最不需要的；而最金的指标（一周用几次 / 留存）Layer 0 已免费、全量、无偏给出。
- **A 的已知弱点（诚实记录）= 自愿快照选择偏差**：愿分享者多为重度用户、流失者不分享 → 端侧自愿数据会系统性高估产品。**但 Layer 0 的留存曲线是全量含流失者、无偏**，恰好堵住这个偏差 → 故是"0 无偏留存 + A 功能细节"的叠层，非单选。
- **儿童合规 airtight**：不上后端 = 不从儿童采集持久标识符 = COPPA/PIPL 儿童特殊义务的最干净叙事（与 [[ADR-004]] Firebase-free 同逻辑，此处推广到全球版）。
- 一石二鸟：MetricKit 既是隐私干净的分析路径、又关掉 RC-4 上架阻塞。

## 后果

- **工程（Claude 工程层，已 green-lit）**：① Firebase 编译层剔除（RC-1/2/6：移除 `SnapDrillInfrastructure/Package.swift` 的 firebase-ios-sdk 依赖，二进制不再链接）② MetricKit 接入（RC-4）③ 本地账本扩展。**破坏性重构在零用户阶段直接重定基线**（[[no_legacy_baggage]]）。
- **UI（Codex 协同）**：自愿快照 UI + 端侧"我的使用"展示属 UI 层，归 UI 重设计线。
- **合规文案（Antigravity 线，方向已定）**：官网 + in-app 隐私文案对齐方向 = **"零采集 / 本地优先"**（删除 Firebase 采集 / ATT / 美国服务器存储等失实陈述）。正文定稿仍 legal-gated（儿童条款须律师）。
- **ASC 隐私问卷**：照"零采集"如实填（manifest 已一致）。
- **可逆性**：零用户阶段，若将来 PMF 需要逼出 Layer B，本决策可逆（decay_trigger: backend_analytics_added）。

## 关联

- [[ADR-004]] 国内 Firebase-free —— 本 ADR 将其"Firebase-free / 端侧或不做分析"逻辑从国内 build 推广到全球版生产基线。
- [[ADR-002]] ATT 移除 —— 零追踪前提一致。
- PMF instrumentation pitch（`docs/pitches/`）—— Layer 0 + 自愿快照即该 pitch 的"本地账本 + 自愿快照"路径；D6=A 锁定其隐私 fork。
