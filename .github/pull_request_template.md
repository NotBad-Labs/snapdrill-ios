## Summary

<!-- 1–2 句：本 PR 做什么、为什么 -->

## 轨道 / Slice

- [ ] A · MVP 产品壳
- [ ] B · 阶段 0 / 去手写
- [ ] C · 订阅 / CloudKit
- [ ] D · 无障碍 / 本地化
- [ ] docs / chore only

**Slice 或任务名**：

## PRD / 验收

- **PRD 章节**：
- **AC（若有）**：

## 本 PR 明确不做

<!-- 防止 scope creep -->

-

## 架构与原则

- [ ] 已读 [`Docs/ARCHITECTURE.md`](../Docs/ARCHITECTURE.md) 与 [`Docs/DEVELOPMENT_PRINCIPLES.md`](../Docs/DEVELOPMENT_PRINCIPLES.md)
- [ ] Capture 相关：仅改 `CaptureContracts` / Pipeline **或** 仅改 `Features/Capture`（二者变更合同须先改 protocol）
- [ ] 未在 UI Feature 中直接引入 Vision/AVFoundation 业务逻辑（Capture 规则）

## 测试

- [ ] `xcodebuild test`（Simulator）通过，或说明为何未跑
- [ ] 真机手测步骤（若有 UI）：

```text
1.
2.
```

## 决策记录（若适用）

是否需要更新 `ARCHITECTURE.md` §8 决策表：是 / 否