---
last_verified: 2026-05-18
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [tool_update]
---
# AI 工具链规格快照

> Claude/Codex/DeepSeek/Gemini/Xcode AI 工具链最新规格。选型和委派时参考。

## Claude Code CLI

- 模型：claude-opus-4-7（主线程）/ claude-sonnet-4-6（子代理）
- 上下文：终端 1M token / Xcode 200K token
- 模式：fast mode（Opus 4.7 加速输出）

## Codex CLI

- 版本：0.130.0
- 模型：gpt-5.5（审计/Review 默认）
- 调用：codex exec --model gpt-5.5 --full-auto

## DeepSeek V4-Pro

- 端点：通过 ~/.local/bin/deepseek wrapper
- 子代理：deepseek-rescue
- 角色：单文件贪吃蛇执行者

## Gemini CLI

- 版本：0.41.2
- 模型：gemini-3-pro-preview（优先）/ gemini-2.5-pro（备选）
- 调用：gemini -p "<prompt>"

## Xcode

- 版本：26.5
- Review：Xcode Intelligence Review（UI 改动必须）
