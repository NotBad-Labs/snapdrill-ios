# 意图追溯索引（自动生成）

> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。
> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs`。
> 本索引证明“已声明上游引用”，不证明语义完全正确；语义仍需人工 review 和代码/测试实证。

## 可引用上游

| 引用 | 含义 | 来源 |
|---|---|---|
| `ADR-001` | 智能组卷与高级统计定价模型 | [../decisions/ADR-001-smart-paper-analytics-pricing.md](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
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

## Feature -> Intent

| Feature | 状态 | 层级 | 上游意图 |
|---|---|---|---|
| [备份与 CSV 导入导出](../features/active/feat-backup.md) | ✅ 已实现 | 免费 | [`vision:P4`](../explanations/vision.md) |
| [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) | ✅ 已实现 | 免费 | [`vision:P1`](../explanations/vision.md) / [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P6`](../explanations/vision.md) / [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) |
| [首页概览（Dashboard）](../features/active/feat-dashboard.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [PDF 导出与打印](../features/active/feat-export.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [题库管理 + 分享卡片](../features/active/feat-library.md) | ✅ 已实现 | 免费 | [`vision:P1`](../explanations/vision.md) / [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) |
| [Onboarding 新手引导](../features/active/feat-onboarding.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-002`](../decisions/ADR-002-remove-att-authorization.md) / [`positioning-and-audience`](../explanations/positioning-and-audience.md) |
| [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`positioning-and-audience`](../explanations/positioning-and-audience.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [复习（SM-2 间隔重复）](../features/active/feat-review.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P3`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [设置与个性化](../features/active/feat-settings.md) | ✅ 已实现 | 免费 | [`vision:P2`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) |
| [高级统计（Pro）](../features/backlog/feat-advanced-stats.md) | ⛔ 阻塞 | Pro | [`vision:P3`](../explanations/vision.md) / [`vision:P5`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [iCloud 多设备同步](../features/backlog/feat-icloud-sync.md) | ⛔ 阻塞 | Pro | [`vision:P4`](../explanations/vision.md) / [`vision:P6`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) | 📋 Backlog | Pro | [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [智能组卷（SmartPaper · Pro）](../features/backlog/feat-smartpaper.md) | ⛔ 阻塞 | Pro | [`vision:P2`](../explanations/vision.md) / [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |
| [Word 导出（Pro）](../features/backlog/feat-word-export.md) | ⛔ 阻塞 | Pro | [`vision:P3`](../explanations/vision.md) / [`vision:P4`](../explanations/vision.md) / [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) |

## Intent -> Feature

| 上游意图 | 承接 Feature |
|---|---|
| [`ADR-001`](../decisions/ADR-001-smart-paper-analytics-pricing.md) | [PDF 导出与打印](../features/active/feat-export.md) / [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) / [复习（SM-2 间隔重复）](../features/active/feat-review.md) / [高级统计（Pro）](../features/backlog/feat-advanced-stats.md) / [iCloud 多设备同步](../features/backlog/feat-icloud-sync.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) / [智能组卷（SmartPaper · Pro）](../features/backlog/feat-smartpaper.md) / [Word 导出（Pro）](../features/backlog/feat-word-export.md) |
| [`ADR-002`](../decisions/ADR-002-remove-att-authorization.md) | [Onboarding 新手引导](../features/active/feat-onboarding.md) |
| [`ADR-003`](../decisions/ADR-003-dual-region-release.md) | — |
| [`ADR-004`](../decisions/ADR-004-china-build-firebase-free.md) | — |
| [`ADR-005`](../decisions/ADR-005-analytics-privacy-strategy.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [设置与个性化](../features/active/feat-settings.md) |
| [`positioning-and-audience`](../explanations/positioning-and-audience.md) | [Onboarding 新手引导](../features/active/feat-onboarding.md) / [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) |
| [`vision:P1`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [题库管理 + 分享卡片](../features/active/feat-library.md) |
| [`vision:P2`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [PDF 导出与打印](../features/active/feat-export.md) / [题库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) / [复习（SM-2 间隔重复）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) / [智能组卷（SmartPaper · Pro）](../features/backlog/feat-smartpaper.md) |
| [`vision:P3`](../explanations/vision.md) | [复习（SM-2 间隔重复）](../features/active/feat-review.md) / [高级统计（Pro）](../features/backlog/feat-advanced-stats.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) / [智能组卷（SmartPaper · Pro）](../features/backlog/feat-smartpaper.md) / [Word 导出（Pro）](../features/backlog/feat-word-export.md) |
| [`vision:P4`](../explanations/vision.md) | [备份与 CSV 导入导出](../features/active/feat-backup.md) / [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [PDF 导出与打印](../features/active/feat-export.md) / [题库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) / [设置与个性化](../features/active/feat-settings.md) / [iCloud 多设备同步](../features/backlog/feat-icloud-sync.md) / [图片处理增强（去手写 / 去批改痕迹 / 试卷还原）](../features/backlog/feat-image-enhance.md) / [智能组卷（SmartPaper · Pro）](../features/backlog/feat-smartpaper.md) / [Word 导出（Pro）](../features/backlog/feat-word-export.md) |
| [`vision:P5`](../explanations/vision.md) | [首页概览（Dashboard）](../features/active/feat-dashboard.md) / [题库管理 + 分享卡片](../features/active/feat-library.md) / [Onboarding 新手引导](../features/active/feat-onboarding.md) / [Multi-Profile Vault（独立资料库）](../features/active/feat-profile.md) / [复习（SM-2 间隔重复）](../features/active/feat-review.md) / [设置与个性化](../features/active/feat-settings.md) / [高级统计（Pro）](../features/backlog/feat-advanced-stats.md) |
| [`vision:P6`](../explanations/vision.md) | [采集（拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板）](../features/active/feat-capture.md) / [iCloud 多设备同步](../features/backlog/feat-icloud-sync.md) |
