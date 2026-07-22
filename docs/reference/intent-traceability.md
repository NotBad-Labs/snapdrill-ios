# 意图追溯索引（自动生成）

> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。
> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs` / `release_refs` / `release_outcomes`；
> Release 1 精确 ID 从 effective `release-1-contract.md` 的 `ratified_decisions` 读取。
> 实现状态只描述代码路径，不证明 Release 1 合同符合、公开可达或发布就绪。
> `release_refs` 只表示 Feature 消费 / 追溯边，不把 Feature 变成上游裁决 owner；
> `release_outcomes` 与 operational oracle 行只证明 owner / proof-plan 声明完整；
> 它们不证明语义正确、实现符合、M1-M10 已执行证据、Capability Manifest inclusion 或发布授权。

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

| Feature | Release 1 消费引用 | Must outcome owner / contributor |
|---|---|---|
| [备份与 CSV 导入导出](../features/active/feat-backup.md) | [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:DATA-1`](release-1-contract.md) / [`release-1:DATA-1-E`](release-1-contract.md) / [`release-1:DATA-1-R`](release-1-contract.md) / [`release-1:D1-B`](release-1-contract.md) / [`release-1:D3-B`](release-1-contract.md) / [`release-1:#891-copy`](release-1-contract.md) / [`release-1:S1-A`](release-1-contract.md) / [`release-1:D4S-A`](release-1-contract.md) / [`release-1:P2-B-A`](release-1-contract.md) / [`release-1:P2-C-A`](release-1-contract.md) / [`release-1:P2-D-A`](release-1-contract.md) / [`release-1:P2-E-A`](release-1-contract.md) / [`release-1:P2-F-A`](release-1-contract.md) / [`release-1:P2-G-A`](release-1-contract.md) | `M7` / `M8` / `M9` / `M10` |
| [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Image`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:S1-A`](release-1-contract.md) / [`release-1:P1-A`](release-1-contract.md) / [`release-1:P2-C-A`](release-1-contract.md) / [`release-1:P2-E-A`](release-1-contract.md) / [`release-1:P2-G-A`](release-1-contract.md) | `M1` / `M2` / `M3` / `M6` / `M9` / `M10` |
| [首页概览（Dashboard）](../features/active/feat-dashboard.md) | [`release-1:C2-Personalization`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) | `M1` / `M10` |
| [PDF 导出与打印](../features/active/feat-export.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) / [`release-1:C5-S1`](release-1-contract.md) / [`release-1:D2-A`](release-1-contract.md) / [`release-1:D4S-A`](release-1-contract.md) | `M5` / `M9` / `M10` |
| [资料库管理 + 分享卡片](../features/active/feat-library.md) | [`release-1:C2-Core`](release-1-contract.md) / [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) / [`release-1:D4-B`](release-1-contract.md) / [`release-1:S1-A`](release-1-contract.md) / [`release-1:M1-A`](release-1-contract.md) / [`release-1:D4S-A`](release-1-contract.md) / [`release-1:P2-B-A`](release-1-contract.md) / [`release-1:P2-C-A`](release-1-contract.md) / [`release-1:P2-G-A`](release-1-contract.md) | `M4` / `M10` |
| [Onboarding 新手引导](../features/active/feat-onboarding.md) | [`release-1:C2-Optional`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:C5-E`](release-1-contract.md) | `M1` / `M10` |
| [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) | [`release-1:DATA-1`](release-1-contract.md) / [`release-1:DATA-1-E`](release-1-contract.md) / [`release-1:DATA-1-R`](release-1-contract.md) | `M1` / `M8` / `M10` |
| [回顾（SM-2 间隔调度）](../features/active/feat-review.md) | [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:P2-D-A`](release-1-contract.md) | — |
| [设置与个性化](../features/active/feat-settings.md) | [`release-1:C2-Personalization`](release-1-contract.md) / [`release-1:C3`](release-1-contract.md) / [`release-1:C4-D`](release-1-contract.md) / [`release-1:D5-A`](release-1-contract.md) / [`release-1:S1-A`](release-1-contract.md) / [`release-1:D4S-A`](release-1-contract.md) | `M7` / `M8` / `M9` / `M10` |
| [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) | [`release-1:section-7`](release-1-contract.md) | — |
| [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) | [`release-1:section-7`](release-1-contract.md) | — |
| [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) | [`release-1:C2-Optional`](release-1-contract.md) | — |
| [SmartPaper（候选，商业分层未定）](../features/backlog/feat-smartpaper.md) | [`release-1:C5-E`](release-1-contract.md) / [`release-1:C5-S1`](release-1-contract.md) | — |
| [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) | [`release-1:section-7`](release-1-contract.md) | — |

## Release 1 -> Feature / Operations Consumers

| Release 1 引用 | Feature / operations consumer |
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
| [`release-1:D1-B`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) |
| [`release-1:D2-A`](release-1-contract.md) | [PDF 导出与打印](../features/active/feat-export.md) |
| [`release-1:D3-B`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) |
| [`release-1:D4-B`](release-1-contract.md) | [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:D5-A`](release-1-contract.md) | [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:#932-A`](release-1-contract.md) | `release-operations` |
| [`release-1:#891-copy`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) |
| [`release-1:S1-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:M1-A`](release-1-contract.md) | [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:D4S-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`release-1:ORI-A`](release-1-contract.md) | `release-operations` |
| [`release-1:P1-A`](release-1-contract.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) |
| [`release-1:P2-B-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:P2-C-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:P2-D-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [回顾（SM-2 间隔调度）](../features/active/feat-review.md) |
| [`release-1:P2-E-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) |
| [`release-1:P2-F-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) |
| [`release-1:P2-G-A`](release-1-contract.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) |
| [`release-1:section-7`](release-1-contract.md) | [高级统计（候选，商业分层未定）](../features/backlog/feat-advanced-stats.md) / [Apple 私有同步（候选，商业分层未定）](../features/backlog/feat-icloud-sync.md) / [Word 导出（候选，商业分层未定）](../features/backlog/feat-word-export.md) |

## Release 1 Must Outcome -> Feature / Proof Plan

| Must | Owning / contributing active Feature | Operational outcome oracle | DRI |
|---|---|---|---|
| [`M1`](release-1-contract.md#31-must-outcomes) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) | clean install 到首次可保存路径，全程无注册、身份或资料空间 gate | QA / Product |
| [`M2`](release-1-contract.md#31-must-outcomes) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | 相机 / 文扫、相册、PDF 分别完成确认、保存和读回；确认后的裁剪图片可读且持久化，图片 / 文档内容自身方向在采集、查看与导出中保持，backup 图片无 GPS；印刷体中英文分别验证可见可编辑 OCR，人工修正值读回；OCR 失败 / 空结果仍可保存 | Capture / QA |
| [`M3`](release-1-contract.md#31-must-outcomes) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | 首次 / 既有拒权、各输入取消和 OCR failure 均能经替代路径保存，无残留 cover / overlay / 失效导航 | Capture / QA |
| [`M4`](release-1-contract.md#31-must-outcomes) | [资料库管理 + 分享卡片](../features/active/feat-library.md) | 分类 / 标签选择保存并读回；搜索与基础过滤命中正确集合；查看、编辑、删除；删除从点击时持久化五秒绝对期限，后台 / 重启不缩短，期限内撤销完整恢复，期限后只硬删除一次 | Library / Data / QA |
| [`M5`](release-1-contract.md#31-must-outcomes) | [PDF 导出与打印](../features/active/feat-export.md) | `N >= 1` 的 selected set 与 PDF 条目一一对应且顺序稳定；基础 PDF 无封面且物理页数严格为 `ceil(N / itemsPerPage)`，空选择在渲染前失败；图片 / 纯文字 / 混合资料均可读且无空白 / 重复；真实 AirPrint 完成并检查输出；系统 share sheet 与“存储到文件”分别覆盖成功 / 取消 / 失败；已明确保存到 App 外的副本保留，无打印机 / 取消 / 失败不误报且清理 App-owned 临时输出 | Export / QA |
| [`M6`](release-1-contract.md#31-must-outcomes) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | 后台 / 终止注入后重启，只出现可完整恢复草稿或明确无草稿 / 丢弃结果，不出现半状态 | Capture / Data / QA |
| [`M7`](release-1-contract.md#31-must-outcomes) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [设置与个性化](../features/active/feat-settings.md) | 正式 writer-reader round-trip 覆盖完整资料库；损坏 / 恶意 / 超限输入在 mutation 前拒绝或进入明确恢复态，原库不变；按 D4S-A 覆盖 pending delete / undo、健康 closed generation 与 unavailable-store raw prestate、complete-operation barrier、immutable backup snapshot detach，以及 partial export 的 pre-barrier completion / post-barrier fail-fast oracles | Data / Security |
| [`M8`](release-1-contract.md#31-must-outcomes) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) / [设置与个性化](../features/active/feat-settings.md) | store 打不开、停在裁决页终止、重启、恢复 / 放弃 / 双失败；始终保留 DATA-1 要求的材料且正常 UI 不假空 | Data / QA |
| [`M9`](release-1-contract.md#31-must-outcomes) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [PDF 导出与打印](../features/active/feat-export.md) / [设置与个性化](../features/active/feat-settings.md) | 静态数据流 / entitlement / manifest / policy 对账；禁网运行全部可达 Must + included optional；受控联网覆盖启动 / 后台 / 升级 / Share Extension，区分用户主动外发、Apple 系统流量与意外外发；持久化 / 备份图片 GPS 检查；结论一致 | Privacy / Security / Release |
| [`M10`](release-1-contract.md#31-must-outcomes) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [PDF 导出与打印](../features/active/feat-export.md) / [资料库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [单一本地资料库（Multi-Profile 退场）](../features/active/feat-profile.md) / [设置与个性化](../features/active/feat-settings.md) | 中英文、iPhone 17e / 17 / 17 Pro Max、默认 / xxxLarge / Accessibility 5 与 VoiceOver 最低矩阵；覆盖全部 Must、included optional、loading / empty / error / confirmation 和系统面板，旅程可完成且无阻断截断 / 遮挡 / 不可达操作；source settings、signed archive 与运行时证明 ORI-A 的 portrait-only App shell 且不旋转媒体内容，并与 ASC availability 一起证明 Mac / Vision Pro compatibility opt-out | UI / AX / QA / Release |
