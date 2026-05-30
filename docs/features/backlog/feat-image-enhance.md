---
id: feat-image-enhance
title: 图片处理增强（去手写 / 去批改痕迹 / 试卷还原）
status: backlog          # implemented | in-progress | blocked | poc-needed | backlog
tier: pro
blocked_by: []           # 源文档标注 PoC + 阻塞 #479（StoreKit）；见 notes / What·前置依赖
mode: lightweight        # backlog：仅 Why + What 必填，How/Verify 待实现补
last_updated: 2026-05-30
---

# Feature: 图片处理增强（去手写 / 去批改痕迹 / 试卷还原）

> 人读摘要：🧪 待实现 / 需 PoC（Pro 增值）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business 聚合（docs 重组 B）。
> `mode: lightweight`：尚未实现且需第三方端上方案 PoC，How / Verify 待 PoC 落地后补，**不为未实现功能编造假设计**。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：家长拍摄的试卷 / 作业上有孩子的手写答案和老师的批改痕迹。去掉这些痕迹、还原干净试卷，是"导出打印练习卷"场景的自然延伸——让打印出来的练习卷像全新的一样，可重复练习。
- **商业价值 / 转化**：作为 Pro 增值能力，采用"免费限次体验 + Pro 无限"策略让用户先感受价值再转化（蜜蜂试卷 / 橙果 / 试卷宝均验证此模式）。属付费层「智能增强」卖点之一（核心引擎仍是 iCloud 同步）。
- **定位**：增值能力，**不是核心闭环**——核心采集 / 管理 / 导出（含免费"去答案打印"）不受其影响；与免费的"去答案打印"是不同层面，不应混淆。
- **原则归属**：P3 免费即门槛（核心永久免费，增强为 Pro 增值，不锁基础能力）+ P4 数据属于用户 / 隐私（端上处理、图片不上传服务端）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：对题目图片本身做智能处理——去手写、去批改痕迹、试卷还原（还原为干净可打印的练习卷）。
- **限次体验**：免费用户每月有限次体验；Pro 用户无限使用。配额按自然月重置，配额耗尽后展示 Pro 引导，**不阻断已有功能 / 不阻塞基础导出**；配额模式与智能组卷统一（ADR-001）。
- **防焦虑边界**（vision §不贩卖焦虑）：配额耗尽文案中性（"本月免费额度已用完，下月 X 日重置"），不用红色 / 警告色 / 倒计时，不显示"剩余 N 次"；Pro 预览必须明确标注"这是 Pro 功能预览"。
- **边界 / 不做**：
  - **不做云端图片处理**（违反 P4 隐私，图片不得上传服务端）。
  - **不在免费层完全锁死**此功能（限次体验是转化关键）。
  - 与**免费**的"去答案打印"（隐藏答案字段、布局层面操作）**是不同层面、技术完全不同**，不合并、不混淆。
- **前置依赖**：
  - **第三方端上方案 PoC**（Go/No-Go 见 requirements §探索性功能评估框架）：Go 条件 = 端上方案可用、SDK < 50MB、去手写准确率 ≥ 80%；No-Go = 所有方案均需云端或准确率 < 60%。
  - **Pro 总闸 StoreKit `#479`**：source 标注本能力 `[需 PoC]`·`[阻塞: #479]`；#479 未接前 Pro 入口保留、功能未接、门后"敬请期待"占位，首版国内 TestFlight 纯免费、无法购买或测试。
- **商业分层**：Pro 增值（免费限次体验 + Pro 无限）。分层理由属 Why / ADR-001，定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
> 待实现 / PoC 阶段填。

- **当前已确定的技术约束**（来自 design / requirements，非"假设计"）：
  - **端上离线处理**：必须使用离线方案，图片不得上传服务端（P4 隐私铁律）。
  - **SDK 体积约束**：第三方方案 SDK < 50MB，避免 App 体积膨胀。
  - **第三方库合规**：纳入后需在开源许可页展示对应第三方库（requirements §合规）。
- **模块归属 / 关键机制 / State & Concurrency / 设计裁决**：待 PoC 选型确定第三方端上方案后补。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
> 待实现 / PoC 阶段填。

- 当前唯一可断言的已落档行为约束（来自 cases UC，非"假设计"）：免费用户超出限次时提示升级，**不阻塞基础导出**；"去答案打印"（免费）与本功能（Pro）保持独立。
- 完整 Success path / 边界异常 / 数据保证 / NFR 待 PoC 落地后补。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（场景延伸 / 干净试卷价值 / 核心理念） | design §图片处理增强设计概要 |
| Why（限次体验转化策略 / 行业验证 / 付费层定位） | business §定价对照表 + §分层原则 |
| Why（与"去答案打印"区分 / P3·P4 归属） | design §"去答案打印"与"图片处理增强"的区分 + vision §3 免费即门槛 / §4 数据属于用户 |
| What（核心能力 / 去手写·去批改·试卷还原） | requirements §功能全景·Could Have + §功能状态总表 |
| What（限次体验 / 配额重置 / 配额模式统一 / 防焦虑文案） | design §图片处理增强设计概要 + §智能组卷设计·配额机制 + §配额耗尽防焦虑铁律 |
| What（不做云端 / 不完全锁死 / 与去答案区分） | design §图片处理增强设计概要·不做什么 |
| What（前置依赖·PoC Go/No-Go 条件） | requirements §探索性功能评估框架 |
| What（前置依赖·Pro 总闸 #479 / 敬请期待占位） | requirements §功能状态总表 + business §Pro 状态说明 |
| What（商业分层 / Hybrid 配额统一） | business §定价对照表 + ADR-001 |
| How（端上离线 / SDK<50MB / 第三方库合规约束） | design §图片处理增强设计概要·设计决策 + requirements §探索性评估框架 + §合规 |
| Verify（限次不阻塞导出 / 与去答案独立） | cases UC §导出·Variants & Exceptions |

## 关联
- 原则：`../../explanations/vision.md`（P3 免费即门槛 / P4 数据属于用户·隐私）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro Hybrid 配额分层，与本功能策略统一）
- 相关 feature：`feat-smartpaper.md`（配额模式统一）、`../active/feat-export.md`（"去答案打印"为不同层面的免费导出能力）
