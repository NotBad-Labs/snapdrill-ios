---
paths:
  - "**/*Tests*/**"
  - "**/*Test*"
---

<!-- last verified: 2026-04-02 -->
# 测试策略

| 层 | 策略 |
|---|---|
| 纯算法 / Extension | TDD |
| Service | Test-after，direct test；必要时用 controlled input / temp dir / mock boundary |
| Repository | in-memory ModelContainer |
| ViewModel | Test-after |
| Data infrastructure（Migration / Backup / DTO / Persistence / Profile） | Test-after |
| View / UI 组件 | Smoke test only |
