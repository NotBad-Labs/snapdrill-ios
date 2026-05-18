---
last_verified: 2026-05-18
layer: pattern
---
# F-001: Git 工作流纪律

「自主执行」偏好的范围是：不需要 yes/no 确认每个代码改动，直接做并汇报。

**不包括**跳过 Git 工作流闭环。任何代码改动都必须：Issue → feature 分支 → PR（Closes #N） → Review → 合并。

**Why:** 2026-03-31 对话中直接在 develop 分支写了 5 个改进项的代码，违反了 workflow.md 的铁律「禁止直推 develop/main」。

**How to apply:** 即使用户要求「一口气全部做完」，也要先建 Issue，切 feature 分支，在分支上开发，完成后开 PR 等用户 review。唯一例外是 STATUS.md 允许直推 develop。
