# 文档控制面

> 本文件定义仓库文档的角色与生命周期，不是产品 SSOT 的第四层。产品规范仍只有
> Product Constitution -> Release Product Contract -> owning feature spec。

## 为什么需要分类

仓库同时保存规范、操作说明、当前实现证据和历史审计。如果只按目录或文件名猜测，旧计划、
固定基线报告和 Agent skill 可能被误当成当前产品要求。机器可读 registry
[`document-control.json`](document-control.json) 因此覆盖每个 tracked Markdown 文件；新增或
移动文档时必须让它恰好匹配一条规则。validator 同时检查已跟踪文件与工作树中尚未提交的
Markdown，避免新文件在首次 commit 时绕过分类。

## 角色

| Role | 能做什么 | 不能做什么 |
|---|---|---|
| `authority` | 在自身 scope 内定义规范、契约或已批准候选 | 低层权威不能覆盖 Product Constitution / Release Contract |
| `operations` | 定义当前工作方式、验证和恢复入口 | 不能定义产品范围、用户语义或发布承诺 |
| `evidence` | 描述 live 实现、固定基线、测试或审计结果 | 不能从“已经实现”反推“应该发布” |
| `generated` | 从 owning source 生成只读索引 | 不能手改或成为新的源数据 |
| `template` | 约束新 issue、PR、spec 或报告的输入结构 | 空模板不是决策或证据 |
| `alias` | 为工具提供同一 tracked 文件的兼容入口 | 不能复制形成第二份正文 |

## 生命周期

| Lifecycle | 含义 |
|---|---|
| `effective` | 已合入 `develop` 且在指定 scope 内生效的权威 |
| `candidate` | 已 shaping，但不能替代 effective baseline |
| `current` | 当前操作或实证入口；仍须用 live repo 复核易变事实 |
| `frozen` | 固定基线历史证据；正文不随当前状态重写 |
| `superseded` | 已被新权威或流程取代，只保留历史 |
| `suspended` | 明确挂起，只有新裁决才能重新激活 |

允许组合由 validator 中的 fail-closed allowlist 固定。角色与生命周期是两条轴：
`evidence/frozen` 表示历史审计，`authority/superseded` 表示曾经有效但已取代的 ADR。

## 读取规则

1. 先查 registry，确认文件角色和生命周期，再决定它是否能指导当前工作。
2. `frozen`、`superseded`、`suspended` 内容只能提供历史与风险证据；其中带有“下一步”“应合并”
   等句子时，也只描述当时基线。
3. `operations` 与 Agent skill 每次运行必须重新读取 live authority；它们不得复制产品范围。
4. `generated` 文件由 owner generator 的 `--check` 证明一致，不使用 hash 推断是否手改。
5. UI 历史证据继续保留截图与缺陷记录，但当前 UI 验收必须从 Release Contract、owning feature
   spec、设计原则与 live UI / AX 证据重新生成。

## 门禁

```bash
python3 Scripts/validate_document_control.py --check
python3 Scripts/validate_docs.py --check
```

第一条检查：

- 每个 tracked Markdown 恰好匹配一条 registry 规则；
- authority 不会通过目录 glob 静默增加；
- alias 确实是 symlink；
- 高风险历史审计与 UI 文件有可见降级提示；
- 本地 Markdown 文件链接和显式 heading anchor 存在。

第二条继续检查产品定位、历史 ADR、术语与 feature intent。两者都通过才代表文档机械门禁绿色；
它们不能替代人工语义复核或外部事实新鲜度核查。
