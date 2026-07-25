---
last_verified: 2026-07-25
layer: decision-history
retired_ids:
  - ADR-001
  - ADR-003
  - ADR-004
---
# Retired Decisions

> 文档状态：固定基线历史证据。本文件是已退役 ADR 的最小历史索引，不是当前规范权威，不能
> 定义当前需求、范围、架构或执行顺序。当前工作只跟随“当前 owner”列；完整旧正文和讨论保留
> 在 Git 历史中，不得从本索引恢复失效范围。

| ID | 原决策主题 | 退役状态 | 当前 owner | 最小回执 |
|---|---|---|---|---|
| ADR-001 | SmartPaper 与高级统计定价 | superseded（2026-07-12） | [商业模式](../explanations/business-model.md) / [Release 1 PRD](../product/release-1-prd.md) | B6-A 已取代旧 Hybrid / Pro 方案；Release 1 免费、无广告、无 IAP |
| ADR-003 | 双账号双地区发行 | suspended（2026-06-09；2026-07-12 再确认） | [定位与受众](../explanations/positioning-and-audience.md) / [发布与 CI](../how-to/release-and-ci.md) | 当前只维护美国主体的全球 iPhone 版；国内路线只有重新立项才能恢复 |
| ADR-004 | 中国大陆 build Firebase-Free | superseded（2026-06-10） | [ADR-005](ADR-005-analytics-privacy-strategy.md) | Firebase-free 已成为全球生产技术边界，不再存在国内/海外 Firebase 分流 |

退役索引只保存编号、主题、状态、当前 owner 和仍需解释的最小转折。旧实现步骤、过期账号状态、
历史法律分析、agent 投票和待办不得继续保留在这里。
