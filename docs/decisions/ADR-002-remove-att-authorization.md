---
last_verified: 2026-06-13
layer: decision
derived_from: [M-002]
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, downstream_change]
---
# ADR-002: 删除 ATT 授权弹窗

> 状态：**已决策** | 日期：2026-04-10 | 决策者：PO

## 背景

代码中存在完整的 ATT 授权链路（PrivacyPrePromptView → requestTrackingAuthorization()），但 Privacy Manifest 声明 NSPrivacyTracking = false，且产品不收集 IDFA、不做 behavioral advertising。

Apple Review Guidelines 5.1.2(i) 规定：只有在发生 tracking 时，才通过 ATT 获取许可。Not Tracking 口径下弹 ATT 弹窗构成"声明与行为不一致"，存在拒审风险。

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A. 保留 ATT | 维持现有代码 | 防御性姿态，未来需要时链路已就绪 | Rule 5.1.2 拒审；Privacy Manifest/Privacy Label/运行时三处不一致 |
| **B. 删除 ATT** | **移除 PrivacyPrePromptView + requestTrackingAuthorization** | **声明与行为一致，消除拒审风险** | 未来需要 ad attribution 时需重新实现 |

## 三方研究摘要

Claude / Codex / Gemini 三方一致建议删除：
- Apple Rule 5.1.2(i)：Not Tracking = 不需要 ATT
- NSPrivacyTracking=false + ATT 弹窗 = 矛盾信号
- 不收集 IDFA，弹 ATT 无实际收益
- Analytics opt-in 由设置页两个独立开关管理，已足够透明

## 决策

**删除 ATT 授权链路**（PO 批准）。

## 后果

- 需创建 Issue 移除 PrivacyPrePromptView + PrivacyConsentService 中的 ATT 调用
- 保持 NSPrivacyTracking = false
- 设置页保留单一匿名遥测同意开关，但全球生产环境注入 `NoOpAnalyticsService`，不进行后端行为采集；端侧 MetricKit 不依赖该开关（见 ADR-005）
- 提交前做隐私一致性检查：Privacy Manifest / App Privacy Details / 应用内文案三方一致
- 若未来引入 ad attribution，再恢复 ATT
