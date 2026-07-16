---
last_verified: 2026-07-15
layer: roadmap
derived_from:
  - ../explanations/vision.md
---
# 功能范围与路线

> 本文件只维护跨功能候选、重入边界和投资状态，不定义当前实现，也不充当 Release Product Contract。
>
> 当前实现见自动生成的 [feature-status.md](feature-status.md)；单功能行为见 feature spec；Release 1 的 Must outcomes、明确非目标和验收由 [Release 1 Product Contract](release-1-contract.md) 单独定义。Gate C 与截至 2026-07-15 的 follow-up decisions 已 ratified，合入 `develop` 后 effective。

## 当前上游边界

Product Constitution v1 已由 PO 于 2026-07-12 批准 B1-A 至 B7-A，并在其权威内容合入 `develop` 后生效：

- 首个切口：处理结构化纸张 / PDF 的成年人。
- 核心价值链：采集 -> 整理 / 找回 -> 导出 / 打印。
- 数据定位：local-first、无 SnapDrill 账户、一个资料库、永久手动备份。
- 商业定位：Release 1 免费、无广告、无 IAP；未来商业化只是候选假设。
- 平台定位：Release 1 iPhone-only，美国主体全球版，英文 + 简体中文；#932-A 同时退出 Apple Silicon Mac 与 Apple Vision Pro 的 iPhone-app compatibility distribution。

任何 roadmap 项都不得覆盖这些边界。改变跨 feature、数据 / wire、公开承诺、商业或平台范围时，必须先有新的 effective 上游 contract。

## Release 1 投资边界

1. 不把任何已实现功能自动提升为 Release 1 Must。
2. 不根据旧 MoSCoW、旧 `v2.0` 全景、历史 ADR、issue 数量或 Draft PR 反推产品范围。
3. Dashboard-default 已由 C3 固定，但卡片与五 Tab 未获批准；Review / SmartPaper 只允许 C4-D / C5-E 的非公开实验，现有公开可达性只是实现偏差。
4. 不新增 Pro、StoreKit、CloudKit、Word、付费配额、iPad 或中国大陆专项发行工作。
5. 安全、数据完整性、CI 可靠性和不改变产品范围的缺陷修复仍可按 DoR 独立 shaping。
6. 已关闭的 PR #868 只保留为单资料库影响与风险证据，不再重开、rebase 或合并；生产收敛从最新 `develop` 按 [Local Library Data Contract](local-library-data-contract.md)、精确 Backup v3 Wire 与 S0 / S1 优先级拆分。

## 能力簇状态

本表用于安排后续 shaping，不是功能承诺：

| 能力簇 | 当前产品关系 | 下一裁决 |
|---|---|---|
| 采集 | Release 1 Must；相机 / 文扫、相册、PDF + OCR 辅助 | 实现对齐 M2 / M3 与 C2-Image，optional 输入按 manifest 隐藏 |
| 资料库搜索、整理、找回 | Release 1 Must | 实现对齐 M4；动态字段、批量和 ShareCard 默认隐藏 |
| 导出 / 打印 | Release 1 Must | 对齐 M5；打印独立验收，PDF 增强默认隐藏 |
| 手动备份 / 恢复 | 耐久数据所有权承诺与 Release 1 Must | Local Library Data Contract + 精确 Backup v3 Wire、实现与 T4 证据 |
| Dashboard | Release 1 普通启动默认任务枢纽；当前实现只作差距证据 | 独立实现刀隐藏 Profile / Pro / analytics / Review hero，补一步 Capture / Library 与启动 oracle |
| Review | 仅 `po-only` / `research` 的 Library 单入口实验；公开隐藏 | 先做隐藏 / 负向门禁；实验实现与 cohort 另行授权 |
| SmartPaper | 仅 `po-only` / `research` 的 Library 单入口实验；公开隐藏、可见即无配额 / Pro | 对齐 C5-S1 无权重不重复 selector；实验实现另行授权 |
| Multi-Profile | 当前代码已实现，但产品目标已退休 | 按 Local Library Data Contract、精确 wire 和当前风险顺序从最新 `develop` 分片退场 |
| Apple 私有同步 | 候选假设 | 外部证据 + 新 Product / Data / Privacy contract |
| Word、高级统计、图片增强 | 候选增值方向 | 外部证据 + 新商业裁决，不进入当前 Release 1 |
| iPad | 已退出当前范围 | 新平台立项、UI / AX / 截图 / 发布证据 |
| Apple Silicon Mac / Apple Vision Pro compatibility | Release 1 明确退出 | 新平台裁决、对应运行时 / 输入 / AX / 支持与商店证据 |
| 中国大陆专项发行 | 已挂起 | 新区域立项、账号 / 签名 / 合规 / 元数据复核 |

## 耐久非目标

下列边界来自 Product Constitution，不属于可随意排期的 backlog：

- 平台题库、答案搜索、自动解题或内容分发服务。
- 社交关系、排行榜、签到、虚拟奖励和焦虑驱动增长。
- 使用核心价值链前强制创建 SnapDrill 账户。
- 开发者可访问的用户内容后端或默认第三方行为分析。
- 通过限制基础录入、锁定资料、阻断手动备份、广告或水印变现。

要重新考虑任一非目标，必须先修改 Product Constitution；普通 feature PR 无权改变。

## 探索性能力评估

探索项只有满足“明确用户问题、可证伪假设、风险边界和 Go / No-Go 证据”后才能进入 shaped candidate。技术可行不等于产品应做。

| 候选方向 | 最低证据 | 主要边界 |
|---|---|---|
| 手写识别增强 | 真实材料任务准确率与人工修正成本 | Apple 平台能力、误识别、离线隐私 |
| 自动拆分 / 智能标注 | 对核心采集摩擦的可测改善 | 错误可见、可改、可撤销，不阻塞保存 |
| 图片处理增强 | 端侧质量、体积、速度与隐私证据 | 不上传内容，不破坏 App-managed 可读内容真相或可恢复性 |
| Apple 私有同步 | 多设备需求与手动备份摩擦证据 | 冲突、兼容、存储、区域和取消 / 降级策略 |
| iPad / Pencil | iPhone 无法满足的明确任务 | 不以“布局能跑”代替完整平台验收 |

评估结论写入 assumptions 或 shaped brief。Go 仍需 PO / DRI 按决策类别批准，并由 Release Contract 或 feature spec 承接；No-Go 保留证据和复核触发器。

## 相关文档

| 文档 | 单一职责 |
|---|---|
| [../explanations/vision.md](../explanations/vision.md) | Product Constitution 与最高产品边界 |
| [release-1-contract.md](release-1-contract.md) | Gate C 与 2026-07-15 follow-up decisions 已 ratified；合入 `develop` 后为 current effective Release 1 Contract |
| [local-library-data-contract.md](local-library-data-contract.md) | 单一本地资料库 inventory、路径、generation / journal 与恢复生命周期 |
| [feature-status.md](feature-status.md) | 自动生成的当前实现状态 |
| [../features/](../features/) | 单功能 Why / What / How / Verify |
| [../explanations/assumptions.md](../explanations/assumptions.md) | 可证伪假设与推翻信号 |
| [../explanations/business-model.md](../explanations/business-model.md) | 当前商业政策与重入条件 |
