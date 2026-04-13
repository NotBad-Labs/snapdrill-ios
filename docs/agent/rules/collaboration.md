---
paths:
  - "CODEX.md"
  - "STATUS.md"
  - "docs/workflow.md"
---

<!-- last verified: 2026-04-13 -->
# 智能体协作架构（Codex Baseline）

## 目标

- 在不牺牲可追溯性的前提下提升交付速度与审计质量。
- 所有结论必须可回放到代码、文档或命令输出。

## 协作工具位

| 工具 | 主要用途 |
|---|---|
| Codex（最高裁决） | 任务分解、验收口径、冲突裁决、最终放行 |
| Claude CLI（主写入者） | 代码/文档落地修改、提交前自检 |
| Gemini CLI（独立视角） | 第三方交叉审计、对抗性复核（默认只读） |
| Xcode Review | UI 与运行态核验 |
| GitHub Issue/PR | 留痕、决策与验收同步 |

## 阶段性执行模式（2026-04-13 起）

1. 受当前配额与订阅策略影响，进入“Codex 统筹 + Claude 执行 + Gemini 审查”模式。
2. Codex 默认不承担大批量直接改写，优先做分批规划、验收定义与最终裁决。
3. 单批次只允许一个写入者，默认固定为 Claude CLI（single-writer）。
4. Gemini CLI 对同一范围做独立复核，输出必须锚定文件与证据，不直接改同批文件。
5. 若出现冲突，以 Codex 基于仓库可验证事实（代码/测试/构建/文档裁决顺序）做最终判定。

## 订阅切换预案（记录）

- 当前计划：2026 年 5 月起提升 Codex 订阅档位、降低 Claude 订阅档位。
- 过渡期目标：最晚在 2026 年 6 月完成“Codex 主执行”模式评估并决定是否切换。
- 切换前提：Codex 配额、吞吐和稳定性达到当期主线任务需求。

## 交叉审计原则

1. 每个智能体独立审计同一批完整文件，不拆半。
2. 汇总时区分“共同发现 / 各方独有发现”。
3. 所有事实性结论必须二次核验（grep/read/build/test）。
4. 修复后至少做一次独立复审，避免“修了一个引入两个”。

## 交叉审计流程（Single-Writer）

1. Codex 输出任务单（目标、范围、No-Go、验收标准、证据格式）。
2. Claude CLI 与 Gemini CLI 并行产出方案或审计结论（先不改文件）。
3. Codex 选定执行方案并下发“执行版任务单”。
4. Claude CLI 按任务单落地改文件并执行验证。
5. Gemini CLI 基于同一验收清单做只读复审。
6. Codex 终审裁决并写回 Issue/PR（通过 / 返工 / 拆分新 issue）。

## 记忆隔离基线（强制）

为避免历史会话/私有记忆污染当前裁决，跨工具委派必须遵循以下规则：

1. Claude CLI 委派必须使用 `--bare --no-session-persistence`。
2. Claude CLI 禁止使用 `-c/--continue`、`-r/--resume`、`--from-pr`。
3. Gemini CLI 委派禁止使用 `--resume`；默认使用 `--approval-mode plan` 做只读审查。
4. 委派 prompt 必须显式声明“仅以下文件为事实源，不引用历史会话结论”。
5. 外部模型输出只作为候选证据，最终以仓库可验证事实和 `docs/workflow.md` 裁决顺序为准。

## 留痕要求

- 重要执行决定写入 `docs/memory/decisions.md`。
- 里程碑事件写入 `docs/memory/timeline.md`。
- 接手状态写入 `docs/memory/handoff.md`。
