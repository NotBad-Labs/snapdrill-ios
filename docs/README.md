# SnapDrill 文档导航

从仓库根 [README](../README.md) 开始。它是人和 Agent 的唯一冷启动入口；本页只负责把读者
路由到拥有相应事实的文档，不复制产品范围、当前状态或执行规则。

## 产品需求

```text
Product Vision & Principles
  -> Release PRD
  -> Feature Spec
  -> 验收标准
  -> 代码与测试
```

| 文档 | 单一职责 |
|---|---|
| [Product Vision & Principles](product/vision.md) | 长期产品身份、方向、原则和耐久边界 |
| [Release 1 PRD](product/release-1-prd.md) | 当前发布的目标、范围、非目标和结果级验收 |
| [Feature Specs](features/) | 单功能的 Why / What / How / Verify |
| [产品定位与受众](explanations/positioning-and-audience.md) | 受众信号、公开定位和合规边界 |
| [设计原则](explanations/design-principles.md) | 跨功能体验规则 |
| [术语表](reference/glossary.md) | 中英文标准用词 |

产品文档说明“应该是什么”。代码、测试、构建、设备与发布证据说明“现在是什么”；两者不一致
时记录偏差，不能用实现反向改写需求。PO 的想法只有经过
`exploration -> shaped candidate -> ratified -> effective -> superseded`，并合入归属权威后，
才替换其他 lane 的当前基线。

## 工程设计与契约

| 文档 | 单一职责 |
|---|---|
| [架构说明](explanations/architecture.md) | 模块拓扑、依赖规则、并发与当前架构偏差 |
| [本地资料库数据契约](reference/local-library-data-contract.md) | 数据接受边界、inventory、事务与恢复生命周期 |
| [备份 wire 格式](reference/backup-wire-format.md) | 外部备份格式与兼容边界 |
| [隐私与合规](explanations/privacy-compliance.md) | 隐私承诺与平台合规 |
| [非功能需求](reference/non-functional-requirements.md) | 可靠性、性能、安全与可访问性要求 |
| [ADR](decisions/README.md) | 重要、耐久且有真实技术取舍的架构决策；含准入与退役规则 |
| [Package 文档](../Packages/) | 各模块公开职责与 API 文档入口 |

## 工作方式

| 文档 | 单一职责 |
|---|---|
| [Definition of Ready](how-to/definition-of-ready.md) | 开工准入、Standing Delegation 与 Stop And Ask |
| [并行协作](how-to/parallel-lanes.md) | lane、worktree、WIP、验证等级与合并授权 |
| [Shape Up](how-to/shape-up.md) | shaping、betting、building 与 cool-down |
| [发布与 CI](how-to/release-and-ci.md) | 本地验证、签名、TestFlight 与发布证据 |
| [AGENTS.md](../AGENTS.md) | 编码 Agent 的最小执行规则；不是产品或架构权威 |

当前工作由 [GitHub pull requests](https://github.com/NotBad-Labs/snapdrill-ios/pulls) 和
[issues](https://github.com/NotBad-Labs/snapdrill-ios/issues) 承载。旧 issue、PR、报告、聊天和
旧 CI 默认只是证据，必须按当前 `origin/develop` 与有效需求通过
[`Current Admission`](how-to/definition-of-ready.md#current-admission) 后才能执行；执行准入不产生
产品要求，也不能替代 PO 的产品、合并或发布裁决。

## 生成索引

| 文档 | 来源 |
|---|---|
| [功能状态](reference/feature-status.md) | feature spec frontmatter 的 `status` / `tier` / `blocked_by` / `mode` |
| [意图追溯](reference/intent-traceability.md) | feature spec 的 `intent_refs` / `release_refs` / `release_outcomes` 与发布运维消费边 |
| [文档控制](reference/document-control.md) | 文档角色、生命周期、生成状态与本地链接规则 |

生成文件不得手改。修改来源后分别运行：

```bash
python3 Scripts/generate_feature_status.py
python3 Scripts/generate_intent_traceability.py
```

文档门禁：

```bash
python3 Scripts/validate_document_control.py --check
python3 Scripts/validate_docs.py --check
```

`reference/audits/` 是固定 base 的历史审计证据，`ui-redesign/` 是已取代的历史 UI 证据；
二者都不能替代当前产品需求、工程契约或 live 实证。
