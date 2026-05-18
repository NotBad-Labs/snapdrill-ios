---
last_verified: 2026-05-18
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [tool_update]
---
# DeepSeek V4 子代理工具链

> DeepSeek V4-Pro 作为第三方外部顾问，与 Codex/Gemini 并列。

## CLI

- 路径：~/.local/bin/deepseek
- 子代理类型：deepseek-rescue
- 调用方式：curl 直调 API（避免 agent loop 挂死）

## 角色

- 单文件贪吃蛇执行者
- 与 Claude/Codex 组成三方/四方交叉审计

## 端点

- 模型：deepseek-v4-pro
- 上下文：1M token
