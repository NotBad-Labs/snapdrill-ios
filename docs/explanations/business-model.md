---
last_verified: 2026-07-19
layer: product-policy
derived_from:
  - vision.md#商业定位
  - vision.md#p3-免费层完成核心闭环
  - vision.md#p4-用户拥有数据
---
# SnapDrill 商业政策与候选假设

> 本文件定义当前商业政策、未来商业化重入条件和可证伪假设。它不承诺价格、订阅、Pro 功能或上线时间。
>
> Product Constitution 是上游权威；某次发布的商业范围由对应 Release Contract 承接。功能代码、历史 ADR、占位界面和 backlog 不能自行创造商业承诺。

## 当前商业政策

PO 于 2026-07-12 批准 Gate B6-A：

- Release 1 免费、无广告、无 IAP。
- 当前没有有效的 SnapDrill Pro、订阅价格、Free Trial、Lifetime、付费配额、CloudKit 或 Word 商业承诺。
- 不可购买的升级入口、“即将推出 Pro”文案和价格 / IAP 元数据必须从 Release 1 用户可见面隐藏。
- 当前商业政策不永久禁止变现。未来商业化必须重新满足本文件的重入条件。

Release 1 Contract C3 固定 Dashboard-default；C4-D / C5-E 只允许 Review 与 SmartPaper 在 `po-only` / `research` build 以受限实验出现，公开候选隐藏；C5-S1 固定 SmartPaper 基础随机选择器。现有配额、Pro、Review 主入口和公开可见性都是实现偏差，不构成商业权威。

## 免费核心边界

无论未来是否商业化，下列边界持续受 Product Constitution 约束：

1. 不限制基础录入数量，不以“每日 N 条”阻断采集。
2. 用户可在单设备完成采集、整理 / 找回、导出 / 打印的核心价值链。
3. 手动备份与恢复永久免费、长期可用，用户资料不得被锁在 App 或付费墙内。
4. 不添加广告、水印、强制账户、焦虑倒计时或损失暗示推动付费。
5. 未来付费能力只能增加独立增值，不能撤销查看、编辑、删除、导出和备份权利。

具体输入渠道、输出格式和附加功能是否属于一次发布，由 Release Contract 定义；“当前已经实现”不自动等于免费层永久 Must。

## 未来商业化重入条件

未来 Pro、IAP 或其他付费模式只有同时满足下列条件，才能从假设进入 effective baseline：

1. 有外部用户证据证明某项独立增值具有真实价值，且核心价值链保持完整。
2. PO 对商业边界、公开承诺和价格策略重新作出 Gate A 裁决。
3. 对应 Product / Data / Privacy contract 已生效；涉及同步时还必须定义兼容、冲突和失败策略。
4. StoreKit 与 App Store Connect 产品可真实购买、恢复和取消，不展示不可兑现的占位入口。
5. 独立 Release Contract 明确范围、非目标、验收、数据降级和支持责任。
6. 用户可见文案、隐私政策、App Store 元数据、截图、测试和 dogfood 证据一致。

缺少任一条件时，候选功能继续留在假设或 backlog，不得通过 UI 预告形成外部承诺。

## 候选增值方向

以下方向只用于未来研究，不表示 Pro 分层、价格或排期已批准：

| 候选方向 | 需要证明的价值 | 主要风险 |
|---|---|---|
| Apple 私有同步 | 多设备流转明显优于永久免费手动备份 | 隐私、冲突、存储、区域差异和支持成本 |
| Word 或其他高级输出 | 用户确实需要在导出后继续精细排版 | 与免费 PDF / 打印边界混淆，格式维护成本高 |
| SmartPaper / 智能增强 | 自动化提升资料复用，而不复杂化主路径 | 教育定位漂移、错误结果、配额与转化压力 |
| 高级统计 | 洞察产生可执行价值，而不是装饰数字 | 焦虑设计、低使用率、数据解释责任 |
| 图片处理增强 | 端侧处理可靠、隐私可接受且明显节省时间 | 模型体积、准确率、第三方依赖和云上传诱惑 |

任何方向都可以被证据否决。候选列表不是 roadmap。

## 订阅取消后数据降级策略

Release 1 没有订阅，本节不是当前功能承诺。若未来订阅获批，下列约束是重入前必须固化的最低数据 contract：

- 本机已有资料和图片完整保留、可查看、可编辑、可删除。
- 免费导出与手动备份持续可用，不把既有资料改为只读。
- 只停止已明确属于付费增值的未来行为，不删除或隐藏用户数据。
- 取消、退款、宽限期、恢复购买和换机行为必须在实现、公开文案与测试中一致。

未来 contract 可以增加保护，不能降低 Product Constitution 的数据所有权底线。

## 当前实现偏差

下列现有表面可能仍反映旧商业方案；它们是后续 Release 1 shaping 的输入，不是现行政策：

- SmartPaper 配额、Pro toast、月度偏好键及相关测试。
- Dashboard、Settings、Library 或导出流程中的 Pro / “稍后提供”文案。
- App Store 元数据、隐私文案、截图和 glossary 中的价格、IAP 或 Pro 主张。
- iCloud、Word、图片增强、高级统计和 SmartPaper feature spec 中的旧免费 / Pro 分层。

这些偏差不得在 Product Constitution PR 中顺手改代码。Release 1 Contract 先决定功能可见性与范围，再按不相交文件集实施。

## 历史商业决策状态

- `ADR-001-smart-paper-analytics-pricing.md` 的 Hybrid / Pro 定价裁决已被 B6-A 取代，不再是当前商业权威。
- 旧月费、年费、Lifetime、14 天试用、Grandfather 和“iCloud 是付费核心引擎”等内容属于历史研究，可从 Git 历史追溯，不能用于当前 UI 或对外材料。
- 中国大陆定价和双发行版商业路线已挂起。恢复时必须重新核验账号、税务、合规、元数据和支持成本。

## 商业模型假设

假设不是承诺。当前无后端行为采集，优先使用 TestFlight 定性反馈、支持请求、App Store Connect 聚合信号和明确的可用性测试。

| # | 假设 | 复核方式 | 推翻信号 |
|---|---|---|---|
| H4 | 不限制基础录入能降低采用门槛并形成信任 | TestFlight 反馈、任务测试、App Store 转化聚合信号 | 用户不把不限量视为价值，或核心障碍来自其他环节 |
| H5 | iPhone-only、英文 + 简体中文的全球版足以支持首轮产品学习 | TestFlight 邀请与完成率、地区反馈、App Store Connect | 关键任务因 iPad 或缺失语言持续无法完成 |
| H6 | 无 SnapDrill 账户、local-first 和可携带备份能成为采用与留存理由 | 用户访谈、支持请求、隐私反馈 | 用户持续因缺少同步离开，且不重视本地与可携带性 |
| H7 | Apple 私有同步未来可能形成独立增值价值 | 多设备用户访谈、手动备份摩擦证据 | 手动备份已足够，或同步风险 / 成本高于用户价值 |
| H8 | 高级输出或智能增强未来可能形成增值，同时不破坏简洁主路径 | 原型任务、可用性测试、功能反馈 | 使用率低、错误成本高，或用户认为产品因此变复杂 |

## 隐私与区域边界

- 当前生产无注册、无开发者内容云、无第三方行为分析；真实隐私状态以代码、Privacy Manifest、网络与发布实证为准。
- NotBad Labs L.L.C. 维护当前全球发行版；英文与简体中文是 Release 1 产品语言。
- iPad、中国大陆专项发行和任何区域化价格都需要新的重入裁决。

## 相关文档

| 文档 | 关系 |
|---|---|
| [vision.md](vision.md) | 上游 Product Constitution 与商业 / 数据边界 |
| [assumptions.md](assumptions.md) | 产品假设 H1-H3、H9-H12 |
| [competitive-analysis.md](competitive-analysis.md) | 可更新的竞品证据，不定义当前商业政策 |
| [../decisions/ADR-001-smart-paper-analytics-pricing.md](../decisions/ADR-001-smart-paper-analytics-pricing.md) | 已被 B6-A 取代的历史商业决策 |
| [Release 1 Product Contract](../reference/release-1-contract.md) | Release 1 功能可见性、非目标与验收；Gate C 与截至 2026-07-19 的 follow-up decisions 已 ratified，合入 `develop` 后 effective |
