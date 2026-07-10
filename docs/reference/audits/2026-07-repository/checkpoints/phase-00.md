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
- `00b`：pending
- verified findings：0
- blockers：0
- 下一条命令：为 `00b` 创建三个 detached worktree，并用同一 brief 独立审阅 control-plane 文件集
