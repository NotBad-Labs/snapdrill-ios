# 意图追溯索引（自动生成）

> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。
> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs` / `release_refs`；
> Release 1 精确 ID 从 effective `release-1-contract.md` 的 `ratified_decisions` 读取。
> 实现状态只描述代码路径，不证明 Release 1 合同符合、公开可达或发布就绪。
> `release_refs` 只表示规范归属，不证明语义正确、实现符合或候选纳入；
> 也不证明 M1-M10 已有证据、Capability Manifest inclusion 或发布授权。

## 可引用上游

| 引用 | 含义 | 来源 |
|---|---|---|
| `ADR-001` | 历史记录（已取代，当前权威：business-model）：智能组卷与高级统计定价模型 | [../decisions/ADR-001-smart-paper-analytics-pricing.md](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| `ADR-002` | 删除 ATT 授权弹窗 | [../decisions/ADR-002-remove-att-authorization.md](../decisions/ADR-002-remove-att-authorization.md) |
| `ADR-003` | 历史记录（已挂起，当前权威：positioning-and-audience）：双账号双地区发布架构 | [../decisions/ADR-003-dual-region-release.md](../decisions/ADR-003-dual-region-release.md) |
| `ADR-004` | 历史记录（已取代，当前权威：ADR-005）：国内版 Firebase-Free（中国大陆 build 不含 Firebase） | [../decisions/ADR-004-china-build-firebase-free.md](../decisions/ADR-004-china-build-firebase-free.md) |
| `ADR-005` | 全球版分析与隐私遥测策略（端侧聚合 + Apple 免费层，不上后端行为采集） | [../decisions/ADR-005-analytics-privacy-strategy.md](../decisions/ADR-005-analytics-privacy-strategy.md) |
| `positioning-and-audience` | 定位与受众 guardrail | [../explanations/positioning-and-audience.md](../explanations/positioning-and-audience.md) |
| `vision:P1` | 采集摩擦最低 | [../explanations/vision.md](../explanations/vision.md) |
| `vision:P2` | 简洁优于功能堆叠 | [../explanations/vision.md](../explanations/vision.md) |
| `vision:P3` | 免费层完成核心闭环 | [../explanations/vision.md](../explanations/vision.md) |
| `vision:P4` | 用户拥有数据 | [../explanations/vision.md](../explanations/vision.md) |
| `vision:P5` | 冷静、清晰、成人生产力工具 | [../explanations/vision.md](../explanations/vision.md) |
| `vision:P6` | Apple 原生优先 | [../explanations/vision.md](../explanations/vision.md) |

## Feature -> Durable Intent

| Feature | 实现状态 | 层级 | 上游意图 |
|---|---|---|---|
| [备份与 CSV 导入导出](../features/active/feat-backup.md) | 🧩 实现存在 | 免费 | [`vision:P4`](../explanations/vision.md) |
| [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | 🧩 实现存在 | 免费 | [`vision:P1`](../explanations/vision.md) / [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P6`](../explanations/vision.md) / [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) |
| [首页概览（Dashboard）](../features/active/feat-dashboard.md) | 🛠 进行中 | 免费 | [`vision:P1`](../explanations/vision.md) / [`vision:P2`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [PDF 导出与打印](../features/active/feat-export.md) | 🧩 实现存在 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) |
| [资料库管理 + 分享卡片](../features/active/feat-library.md) | 🧩 实现存在 | 免费 | [`vision:P1`](../explanations/vision.md) / [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [Onboarding 新手引导](../features/active/feat-onboarding.md) | 🧩 实现存在 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-002`](../decisions/ADR-002-remove-att-authorization.md) / [`positioning-and-audience`](../explanations/positioning-and-audience.md) |
| [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) | 🛠 进行中 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`positioning-and-audience`](../explanations/positioning-and-audience.md) |
| [回顾（SM-2 间隔调度）](../features/active/feat-review.md) | 🧩 实现存在 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P3`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [设置与个性化](../features/active/feat-settings.md) | 🧩 实现存在 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) |
| [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) | 📋 Backlog | 未定 | [`vision:P3`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) | 📋 Backlog | 未定 | [`vision:P4`](../explanations/vision.md) / [`vision:P6`](../explanations/vision.md) |
| [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) | 📋 Backlog | 未定 | [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) |
| [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) | 🛠 进行中 | 未定 | [`vision:P2`](../explanations/vision.md) / [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) |
| [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) | 📋 Backlog | 未定 | [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) |

## Durable Intent -> Feature

| 上游意图 | 承接 Feature |
|---|---|
| [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) | — |
| [`ADR-002`](../decisions/ADR-002-remove-att-authorization.md) | [Onboarding 新手引导](../features/active/feat-onboarding.md) |
| [`ADR-003`](../decisions/ADR-003-dual-region-release.md) | — |
| [`ADR-004`](../decisions/ADR-004-china-build-firebase-free.md) | — |
| [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`positioning-and-audience`](../explanations/positioning-and-audience.md) | [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) |
| [`vision:P1`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`vision:P2`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) / [回顾（SM-2 间隔调度）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) / [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) |
| [`vision:P3`](../explanations/vision.md) | [回顾（SM-2 间隔调度）](../features/active/feat-review.md) / [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) / [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) / [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) |
| [`vision:P4`](../explanations/vision.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) / [设置与个性化](../features/active/feat-settings.md) / [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) / [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) / [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) |
| [`vision:P5`](../explanations/vision.md) | [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) / [回顾（SM-2 间隔调度）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) / [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) |
| [`vision:P6`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) |

## Feature -> Release 1

| Feature | Release 1 规范归属 |
|---|---|
| [备份与 CSV 导入导出](../features/active/feat-backup.md) | [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:DATA-1`](release-1-contract.md) / [`release-1:DATA-1-E`](release-1-contract.md) / [`release-1:DATA-1-R`](release-1-contract.md) |
| [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Image`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) |
| [首页概览（Dashboard）](../features/active/feat-dashboard.md) | [`release-1:C2-Personalization`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) |
| [PDF 导出与打印](../features/active/feat-export.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) / [`release-1:C5-S1`](release-1-contract.md) |
| [资料库管理 + 分享卡片](../features/active/feat-library.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) |
| [Onboarding 新手引导](../features/active/feat-onboarding.md) | [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) |
| [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) | [`release-1:DATA-1`](release-1-contract.md) / [`release-1:DATA-1-E`](release-1-contract.md) / [`release-1:DATA-1-R`](release-1-contract.md) |
| [回顾（SM-2 间隔调度）](../features/active/feat-review.md) | [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) |
| [设置与个性化](../features/active/feat-settings.md) | [`release-1:C2-Personalization`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) |
| [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) | [`release-1:section-7`](release-1-contract.md) |
| [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) | [`release-1:section-7`](release-1-contract.md) |
| [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) | [`release-1:C2-Optional`](release-1-contract.md) |
| [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) | [`release-1:C5-E`](release-1-contract.md) / [`release-1:C5-S1`](release-1-contract.md) |
| [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) | [`release-1:section-7`](release-1-contract.md) |

## Release 1 -> Feature / Operations

| Release 1 引用 | Feature / operations owner |
|---|---|
| [`release-1:C1-A`](release-1-contract.md) | `release-operations` |
| [`release-1:C2-Core`](release-1-contract.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:C2-Image`](release-1-contract.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) |
| [`release-1:C2-Optional`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) |
| [`release-1:C2-Personalization`](release-1-contract.md) | [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:C3`](release-1-contract.md) | [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [回顾（SM-2 间隔调度）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:C4-D`](release-1-contract.md) | [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [回顾（SM-2 间隔调度）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:C5-E`](release-1-contract.md) | [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) |
| [`release-1:C5-S1`](release-1-contract.md) | [PDF 导出与打印](../features/active/feat-export.md) / [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) |
| [`release-1:C6-A`](release-1-contract.md) | `release-operations` |
| [`release-1:DATA-1`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) |
| [`release-1:DATA-1-E`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) |
| [`release-1:DATA-1-R`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) |
| [`release-1:D1-B`](release-1-contract.md) | — |
| [`release-1:D2-A`](release-1-contract.md) | — |
| [`release-1:D3-B`](release-1-contract.md) | — |
| [`release-1:D4-B`](release-1-contract.md) | — |
| [`release-1:D5-A`](release-1-contract.md) | — |
| [`release-1:#932-A`](release-1-contract.md) | — |
| [`release-1:#891-copy`](release-1-contract.md) | — |
| [`release-1:section-7`](release-1-contract.md) | [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) / [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) / [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) |
