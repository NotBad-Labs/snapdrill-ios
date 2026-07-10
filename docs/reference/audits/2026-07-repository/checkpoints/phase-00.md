# Phase 00 Checkpoint

## T0

- `origin/develop`：`d62fead87fb103708652ac5378eda8e2c03f8257`
- 主 checkout：同一 SHA；未修改，已有未跟踪 `agent-reports/` 未触碰
- 独立 worktree：`/private/tmp/snapdrill-repository-audit`
- 独立分支：`codex/repository-audit-program`
- 审计 write WIP：1

## Toolchain

- Codex：`0.144.0-alpha.4`，App-managed
- Claude Code：`2.1.206`；`claude-fable-5[1m]` 单轮无工具握手成功
- Antigravity CLI：`1.1.1`；`Gemini 3.5 Flash (High)` 单轮 plan/sandbox 握手成功
- Grok CLI：`0.2.93`；OAuth 与 `grok-4.5` 单轮 `--no-memory` 握手成功
- Gemini CLI：已移除，避免与 Antigravity 重复

Antigravity 首次 3.5 Flash 握手因 `fetchAvailableModels` 临时 EOF 未解析模型；刷新 `agy models` 后同一显式模型成功。后续禁止 3.1 Pro 和隐式默认回退。

## GitHub Baseline

```text
issues: 347 total / 4 open
pull requests: 517 total
actions runs: 1881 total / 1305 success / 506 failure / 70 cancelled
```

数据来自 2026-07-10 的 GitHub Search API 与 Actions API。Phase 01 前不得把 506 次 failure 直接解释为 506 次缺陷或浪费。

## Cleanup

- 删除重复 Gemini CLI。
- 删除过期 Claude binaries、未完成下载和旧全局 `settings.local.json` 权限白名单。
- Grok 0.2.93 因整包下载在 6.4 MiB 处截断，改用官方 GCS range 分片；31 片逐片校验后，整文件大小为 `127259280`，MD5 为 `9315a4bb6c7a5c6c736292c69e53a1fc`，且二进制自报版本正确后才替换。

## Status

- `00a`：complete
- `00b`：complete
- verified findings：3（1×P2，2×P3）
- blockers：0
- routed Phase 09 candidates：2
- 下一步：为 Phase 01 生成 GitHub 元数据快照和分层抽样 brief

## 00b Adapter Results

- Claude：`--safe-mode --permission-mode plan` + read tools；一次产出合格报告。
- Grok：`plan` 只返回执行计划；改为 `dontAsk` 且工具仅限 `Read,Grep,Glob` 后产出合格报告。
- Antigravity：cwd 和 `--new-project` 不能可靠绑定 worktree；必须显式 `--project <absolute-worktree-path>`。全局旧权限清零后，`--mode plan --sandbox` 仍可只读运行。
- 三方均未读取另一方报告。无模型原始 transcript 入仓。

本机 shared pre-commit 在 00b 开始时落后 tracked `Scripts/pre-commit`，缺少 Capture 契约和脚本回归测试。执行 `Scripts/setup.sh` 后，pre-commit / pre-push 与 tracked source 均已 `cmp` 一致。这是已修复的本机状态，不作为 base commit finding。

Antigravity 清理了 1.2 GB 旧代码备份、22 MB 旧聊天、旧项目映射、旧 CLI conversations 和 141 条全局 allow grants；OAuth、CLI 二进制和必要偏好保留。清理后 `Gemini 3.5 Flash (High)` 显式 project/read-only 握手成功。
