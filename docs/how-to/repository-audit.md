# Repository Audit

> 用于可恢复、可复核的全仓审计。审计解释证据，不以模型共识、issue 数量或 CI 红灯数量代替事实。

## 1. 边界

审计先回答“当前仓库是什么”，再回答“历史投入为什么发生”，最后才判断保留、修复、冻结或删除。三类问题不得混写：

1. **当前质量**：以固定 base commit 的代码、测试、构建、真机/模拟器和发布证据为准。
2. **历史成本**：以 Git/GitHub 元数据、失败分类、返工链和当时可见信息为准；历史数量本身不证明浪费。
3. **未来决策**：由 PO 基于已复核 finding 裁决，不由 agent 自动生成 roadmap。

审计分支只写协议、证据和结论，不修产品代码。发现需要修复时，先形成 verified finding，再由 PO 决定是否另开 bounded fix slice。合并仍需 PO 明确授权。

## 2. 每个 Slice 的启动门

每个 slice 必须记录：

- `base_sha`、目标分支、worktree、dirty files 和与 `origin/develop` 的关系。
- outcome、文件集、排除项、验证等级和停止条件。
- 上游真相来源；产品意图与当前实现分开写。
- 预计最多 60 分钟或 50 个主要文件。超出即拆分，不靠长会话硬撑。
- 原始报告路径与 checkpoint 路径。模型额度耗尽或进程中断时，已完成证据仍可恢复。

若 base 漂移、文件集越界、需要产品裁决、出现 P0/P1 数据风险或验证命令不可运行，停止当前 slice 并写 `PARTIAL` / `BLOCKED`，不得静默扩大范围。

## 3. 独立审阅

同一 slice 中每个获授权的独立 reviewer 使用同一份中性 brief，彼此看不到先前结论。模型多数票
不是事实；任何结论进入仓库前都由 orchestrator 在 live base 上重跑命令并核对 `file:line`。
私有仓库内容外发前还必须按
[`external-agent-review.md`](external-agent-review.md)
取得 PO 对 vendor 与最小 payload 的明确授权。

角色约束：

| Role | 约束 |
|---|---|---|
| Orchestrator | 固定 base、分配文件集、复核每条证据、归一化 finding；不把自身判断当 PO 裁决 |
| Independent reviewer | 新会话、最小 payload、只读工具、关闭记忆 / subagent / web；输出候选证据 |
| Fact verifier | 在 live base 重跑命令、重开路径并记录接受 / 拒绝理由；不能仅转述 reviewer |

当前可用 vendor、精确模型、CLI 参数和已验证版本只在 invocation protocol 维护，不能从本流程
文件推断。外部 agent 的最终报告由编排器保存到仓库外：

```text
/private/tmp/snapdrill-repository-audit-raw/<base_sha>/<phase>/<agent>.md
```

原始 transcript、模型缓存、auth/debug log、brain artifact、session/upload queue 和重复分析不入仓。
编排器取证后删除临时状态；超时或不完整 run 标为无效，不通过重启会话伪装成连续独立审阅。
仓库只保留 brief、可复现命令、归一化 finding、拒绝理由和 checkpoint。

## 4. Finding 生命周期

Finding 状态只有以下几种：

- `candidate`：agent 提出，尚未现场复核。
- `verified`：C1 在固定 base 上复现，证据和影响成立。
- `rejected`：证据不成立、路径漂移、已有 guard 或误读；保留简短拒绝理由防止重复返工。
- `pending-po`：事实成立，但产品含义或取舍需要 PO。
- `deferred`：事实成立，当前不修；必须有 owner 或重新评估条件。
- `fixed`：独立修复已合并到 `develop`，并附 PR/commit 与回归证据。

每条 finding 至少包含：稳定 ID、severity、类别、状态、`base_sha`、期望、实际、`file:line`、复现命令、影响、置信度和下一步。没有直接证据的内容只能进入 hypotheses，不能进入 finding ledger。

## 5. Checkpoint 与停止规则

每个 phase 完成后提交一个 checkpoint，写明已覆盖文件、四方报告状态、新增/拒绝 finding、剩余风险、额度或工具阻塞和下一条可执行命令。Checkpoint 是恢复点，不是第二套 feature status。

出现以下任一情况时结束或暂停审计：

- 发现 P0，或 P1 涉及数据破坏、隐私、安全、迁移或发布签名。
- 连续两个独立 phase 没有新增 P0/P1，且新增 P2/P3 已主要为重复项；转入综合裁决。
- 继续扫描只能增加未经验证的模型意见，不能增加可复现证据。
- PO 已有足够证据作 go/no-go 或重构/删除裁决。

## 6. Skill 提炼门

本流程先作为项目文档运行。至少两个 phase 按同一协议成功恢复、复核和提交后，才允许把重复步骤提炼为项目内 skill；skill 只能指向本文件和脚本，不能复制产品事实或保存阶段结论。
