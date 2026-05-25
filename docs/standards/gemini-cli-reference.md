---
last_verified: 2026-05-25
derived_from: [M-001]
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [tool_update]
audit_note: 2026-05-19 验证 — 工具版本与项目实际使用对齐
---
# Gemini CLI 集成信息

> Gemini CLI 的认证方式、配额、版本信息，用于三方交叉审计。

## 认证

| 模式 | 配额 | 场景 |
|---|---|---|
| Google 账号登录（推荐） | 1500 RPD 免费 | 日常审计 |
| API Key | 按量计费 | 超额 fallback |

## 模型

- 优先：gemini-3-pro-preview（强推理）
- 备选：gemini-2.5-pro（节省配额）

## 调用

```bash
gemini -p "<prompt>" 2>&1
```

- 审计不加 --sandbox（性能 2x+ 优势）
- prompt 必须内联项目约束

## 已知限制

- 训练数据不覆盖 iOS 26
- Critical 结论必须代码验证
- 大型审计分批（每批不超过 5 个长文件）
