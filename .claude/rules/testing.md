---
paths:
  - "**/*Tests*/**"
  - "**/*Test*"
---

# 测试策略

| 层 | 策略 |
|---|---|
| 纯算法 | TDD |
| ViewModel | Test-after |
| Repository | in-memory ModelContainer |
| View / 胶水 | 不测 |
