# Pull Request 模板（SnapDrill greenfield）

> 复制到 GitHub PR 描述，或依赖 [`.github/pull_request_template.md`](../.github/pull_request_template.md) 自动填充。  
> 原则见 [`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md)。

---

## Summary

<!-- 1–3 句：本 PR 解决什么用户/AC 问题 -->

## 轨道 / 范围

| 项 | 填写 |
|---|---|
| 轨道 | A · MVP / B · 阶段 0 / C · 商业化 / D · 横切 |
| Slice | 例：Slice 2 · Capture 步骤 1 |
| **本 PR 做** | |
| **本 PR 不做** | <!-- 明确排除，防范围蔓延 --> |

## PRD / 合同

| 项 | 填写 |
|---|---|
| PRD 章节 | 例：§8.2 步骤 1 |
| 验收 (AC) | 例：AC-02 子集：… |
| 架构合同 | 无 / `CapturePipelineServing` / （其他 protocol） |

## 测试

- [ ] `xcodebuild test`（Simulator）或说明为何不适用
- [ ] 真机 / 手测步骤（PO Dogfood）：

```text
1.
2.
```

## 决策

- [ ] 无需更新 `ARCHITECTURE.md` §8
- [ ] 已更新 §8 决策表：（一行摘要）

## Checklist（开工原则）

- [ ] 读过 PRD 相关节 + `ARCHITECTURE` + `DEVELOPMENT_PRINCIPLES`
- [ ] 一 PR 一边界；未夹带无关重构
- [ ] 优先 Apple 框架 / 现有 Service，未重复造轮子
- [ ] Capture UI 未直接使用相机/Vision（若适用）