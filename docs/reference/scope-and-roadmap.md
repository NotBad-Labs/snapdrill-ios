---
last_verified: 2026-07-25
layer: roadmap
derived_from:
  - ../product/vision.md
  - ../product/release-1-prd.md
---
# 功能候选与路线

> 本文件只维护尚未进入当前发布承诺的跨功能候选及其重入条件。它不定义当前发布范围、
> 当前实现或单功能行为，也不复制 Product Vision & Principles 或 Release PRD。

## 读取边界

- 长期产品身份、原则和耐久非目标只读
  [Product Vision & Principles](../product/vision.md)。
- 当前发布的目标、Must outcomes、optional 可见性、明确非目标和验收只读
  [Release 1 PRD](../product/release-1-prd.md)。
- 单功能行为只读 owning [feature spec](../features/)；当前实现状态只读自动生成的
  [feature-status.md](feature-status.md)。
- 历史 issue、PR、旧路线图、实现数量和技术可行性都不能让候选自动进入发布范围。候选若要
  重入，必须先通过 Current Admission，并由相应产品、数据、隐私或平台 owner 承接。
- 不改变产品范围的安全、数据完整性和 CI 可靠性修复属于缺陷治理，不在本路线图排功能优先级。

## 候选组合

本表只帮助发现下一轮 shaping 所需证据，不是功能承诺或 Release 1 状态表。

| 候选方向 | 进入 shaping 前的最低条件 | 需要更新的 owner |
|---|---|---|
| Review / SmartPaper 的公开可见性 | 当前受控实验产生可复核证据，且核心价值链不被削弱 | Release PRD + owning feature spec |
| Apple 私有同步 | 明确的多设备需求与手动备份摩擦证据 | Product / Data / Privacy contract |
| Word、高级统计或图片增强 | 明确用户任务、可证伪价值假设和商业边界 | Product / Business policy + feature spec |
| iPad / Pencil | iPhone 无法满足的明确任务及完整平台验收计划 | Product / Platform contract |
| 中国大陆专项发行 | 新区域立项及账号、签名、合规和元数据复核 | Product / Legal / Release contract |
| 手写识别、自动拆分或智能标注增强 | 真实材料上的收益、修正成本和失败可恢复证据 | Product / Privacy + feature spec |

## 探索性能力评估

探索项只有满足“明确用户问题、可证伪假设、风险边界和 Go / No-Go 证据”后才能进入 shaped candidate。技术可行不等于产品应做。

| 候选方向 | 最低证据 | 主要边界 |
|---|---|---|
| 手写识别增强 | 真实材料任务准确率与人工修正成本 | Apple 平台能力、误识别、离线隐私 |
| 自动拆分 / 智能标注 | 对核心采集摩擦的可测改善 | 错误可见、可改、可撤销，不阻塞保存 |
| 图片处理增强 | 端侧质量、体积、速度与隐私证据 | 不上传内容，不破坏 App-managed 可读内容真相或可恢复性 |
| Apple 私有同步 | 多设备需求与手动备份摩擦证据 | 冲突、兼容、存储、区域和取消 / 降级策略 |
| iPad / Pencil | iPhone 无法满足的明确任务 | 不以“布局能跑”代替完整平台验收 |

评估结论写入 assumptions 或 shaped brief。Go 仍需 PO / DRI 按决策类别批准，并由 Release PRD 或 feature spec 承接；No-Go 保留证据和复核触发器。

## 相关文档

| 文档 | 单一职责 |
|---|---|
| [../product/vision.md](../product/vision.md) | Product Vision & Principles 与最高产品边界 |
| [Release 1 PRD](../product/release-1-prd.md) | 当前发布目标、范围、非目标与结果级验收 |
| [local-library-data-contract.md](local-library-data-contract.md) | 单一本地资料库 inventory、路径、generation / journal 与恢复生命周期 |
| [feature-status.md](feature-status.md) | 自动生成的当前实现状态 |
| [../features/](../features/) | 单功能 Why / What / How / Verify |
| [../explanations/assumptions.md](../explanations/assumptions.md) | 可证伪假设与推翻信号 |
| [../explanations/business-model.md](../explanations/business-model.md) | 当前商业政策与重入条件 |
