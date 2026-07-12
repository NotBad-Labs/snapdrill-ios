---
last_verified: 2026-07-12
layer: roadmap
derived_from:
  - ../explanations/vision.md
---
# 功能范围与路线

> 本文件只维护跨功能候选、重入边界和投资状态，不定义当前实现，也不充当 Release Product Contract。
>
> 当前实现见自动生成的 [feature-status.md](feature-status.md)；单功能行为见 feature spec；Release 1 的 Must outcomes、明确非目标和验收必须由待建立的 Release 1 Product Contract 单独定义。

## 当前上游边界

Product Constitution v1 已由 PO 于 2026-07-12 批准 B1-A 至 B7-A，并在其权威内容合入 `develop` 后生效：

- 首个切口：处理结构化纸张 / PDF 的成年人。
- 核心价值链：采集 -> 整理 / 找回 -> 导出 / 打印。
- 数据定位：local-first、无 SnapDrill 账户、一个资料库、永久手动备份。
- 商业定位：Release 1 免费、无广告、无 IAP；未来商业化只是候选假设。
- 平台定位：Release 1 iPhone-only，美国主体全球版，英文 + 简体中文。

任何 roadmap 项都不得覆盖这些边界。改变跨 feature、数据 / wire、公开承诺、商业或平台范围时，必须先有新的 effective 上游 contract。

## Release 1 合同前的投资边界

在 Release 1 Product Contract 生效前：

1. 不把任何已实现功能自动提升为 Release 1 Must。
2. 不根据旧 MoSCoW、旧 `v2.0` 全景、历史 ADR、issue 数量或 Draft PR 反推产品范围。
3. Dashboard、Review 与 SmartPaper 的发布分类保持待 PO 裁决；现有可达性只是实现事实。
4. 不新增 Pro、StoreKit、CloudKit、Word、付费配额、iPad 或中国大陆专项发行工作。
5. 安全、数据完整性、CI 可靠性和不改变产品范围的缺陷修复仍可按 DoR 独立 shaping。
6. Draft PR #868 作为单资料库候选实现与风险证据保持冻结，等待上游 contract 后重审。

## 能力簇状态

本表用于安排后续 shaping，不是功能承诺：

| 能力簇 | 当前产品关系 | 下一裁决 |
|---|---|---|
| 采集 | 核心价值链起点 | Release Contract 选择 Must outcomes 与输入边界 |
| 资料库搜索、整理、找回 | 核心价值链中段 | Release Contract 选择 Must outcomes、字段与批量操作边界 |
| 导出 / 打印 | 核心价值链终点 | Release Contract 选择格式、打印与取消 / 失败验收 |
| 手动备份 / 恢复 | 耐久数据所有权承诺 | Release Contract 定义兼容、损坏与恢复结果边界 |
| Dashboard | 当前实现可达，不是宪章承诺 | Gate C 分类 Must、optional、hidden 或 removed |
| Review | 可选复用价值 | Gate C 分类及导航位置 |
| SmartPaper | 可选复用 / 输出工具；旧 Pro 定价已失效 | Gate C 决定可见性、配额和 Release 1 范围 |
| Multi-Profile | 当前代码已实现，但产品目标已退休 | Product / Release Contract 生效后重审 #868 |
| Apple 私有同步 | 候选假设 | 外部证据 + 新 Product / Data / Privacy contract |
| Word、高级统计、图片增强 | 候选增值方向 | 外部证据 + 新商业裁决，不进入当前 Release 1 |
| iPad | 已退出当前范围 | 新平台立项、UI / AX / 截图 / 发布证据 |
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
| 图片处理增强 | 端侧质量、体积、速度与隐私证据 | 不上传内容，不把原图真相替换为不可恢复结果 |
| Apple 私有同步 | 多设备需求与手动备份摩擦证据 | 冲突、兼容、存储、区域和取消 / 降级策略 |
| iPad / Pencil | iPhone 无法满足的明确任务 | 不以“布局能跑”代替完整平台验收 |

评估结论写入 assumptions 或 shaped brief。Go 仍需 PO / DRI 按决策类别批准，并由 Release Contract 或 feature spec 承接；No-Go 保留证据和复核触发器。

## 相关文档

| 文档 | 单一职责 |
|---|---|
| [../explanations/vision.md](../explanations/vision.md) | Product Constitution 与最高产品边界 |
| 待建立的 Release 1 Product Contract | 当前发布范围、非目标和结果级验收 |
| [feature-status.md](feature-status.md) | 自动生成的当前实现状态 |
| [../features/](../features/) | 单功能 Why / What / How / Verify |
| [../explanations/assumptions.md](../explanations/assumptions.md) | 可证伪假设与推翻信号 |
| [../explanations/business-model.md](../explanations/business-model.md) | 当前商业政策与重入条件 |
