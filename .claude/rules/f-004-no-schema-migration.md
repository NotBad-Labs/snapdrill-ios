---
paths:
  - "**/*Model*.swift"
  - "**/*Schema*.swift"
  - "**/*Migration*.swift"
  - "**/*Persistence*.swift"
---

# F-004: 内测阶段不做 Schema 迁移

内测阶段（TestFlight Internal，0 外部用户）不需要 Schema 向后兼容迁移。

**Why:** 没有任何用户数据需要保护。设计复杂的向后兼容方案属于「战术勤奋掩盖战略懒惰」。

**How to apply:** 数据结构变更直接覆盖（新结构 replace 旧结构）。等正式发布后有真实用户数据时再考虑迁移。判断标准：App Store 上架前 = 不需要迁移。

> timeboxed: review_after 2026-07-01 | sunset: App Store 正式上架后废止
