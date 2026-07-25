# Architecture Decision Records

本目录只保存当前可用于指导实现的 Architecture Decision Record（ADR）。ADR 解释一个重要、
耐久且难以从代码直接看出的技术取舍；它不是 PRD、路线图、法律意见、商业政策、会议纪要或
执行日志。

## 准入标准

只有同时满足以下条件时才新建 ADR：

1. 决策会长期影响多个模块、数据边界、平台集成或非功能属性；
2. 至少存在两个真实可行的技术方案；
3. 方案之间存在需要保留的成本、风险或可逆性取舍；
4. 当前代码或 API 形状不足以解释为什么选择该方案；
5. 产品、发布、法律或商业语义已经由对应 owner 文档确定，ADR 不替它们做决定。

以下内容不得创建 ADR：

- 用户需求、Release 范围和默认行为：归 Product Vision、Release PRD 或 feature spec；
- 定价、付费层和区域发行：归商业、定位或发布 owner；
- wire / 数据接受边界：归 owning data contract，除非另有跨模块技术取舍需要解释；
- 临时实现步骤、PR 顺序、审计结论和 agent 对话：归 issue、PR 或 frozen evidence；
- 仅有一个实现方案、可由代码清楚表达的局部选择。

## 生命周期

有效 ADR 的 frontmatter `status` 只允许：

- `proposed`：候选技术方案，不具有当前规范效力；
- `accepted`：已接受并可指导当前实现。

`proposed` ADR 必须在 `document-control.json` 中显式登记为 `authority/candidate`，且不得被 feature
spec 的 `intent_refs` 引用。`accepted` ADR 才会进入下方当前列表和生成的意图追溯索引。

当 ADR 不再有效时，从 active ADR 集合移除，并在
[Retired Decisions](retired-decisions.md) 留下最小回执。`superseded` 表示已有明确替代 owner，
`suspended` 表示方向已挂起且只能经新裁决恢复，`withdrawn` 表示该方向已退出但没有新的同类
技术方案。完整旧正文由 Git 历史保留，不在当前工作树继续复制失效前提。

## 当前 ADR

| ID | 决策 | 状态 |
|---|---|---|
| [ADR-002](ADR-002-remove-att-authorization.md) | 不引入 App Tracking Transparency 授权链路 | accepted |
| [ADR-005](ADR-005-analytics-privacy-strategy.md) | 生产环境无后端行为遥测，使用本地 MetricKit 诊断 | accepted |

## 必需结构

每份 active ADR 必须包含：

- frontmatter：`last_verified`、`layer: architecture-decision`、`decision_id`、`status`、
  `decided_at`；
- 标题：`# ADR-NNN: ...`，编号与文件名、`decision_id` 一致；
- 六个章节：背景（Context）、决策（Decision）、备选方案（Alternatives）、
  后果（Consequences）、验证与复议触发器（Validation）、关联权威（Related authorities）。

新增或修改 ADR 后运行：

```bash
python3 Scripts/generate_intent_traceability.py
python3 Scripts/validate_docs.py --check
python3 Scripts/validate_document_control.py --check
```
