---
last_verified: 2026-05-18
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [tool_update]
---
# Snapshot Testing 环境变量

> swift-snapshot-testing v1.19+ 原生读取 SNAPSHOT_TESTING_RECORD，不需要自写 helper。

## 使用

```bash
SNAPSHOT_TESTING_RECORD=1 xcodebuild test ...
```

## 纪律

- 禁止盲目 record 所有 baseline
- 删除单个 baseline png 后重跑即可重新 record
- 一次性更新超过 3 张 baseline 必须质询合理性（F-014）
