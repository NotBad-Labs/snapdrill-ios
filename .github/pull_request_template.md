## Summary

<!-- 1–3 句 -->

## 轨道 / 范围

| 项 | 填写 |
|---|---|
| 轨道 | A · MVP / B · 阶段 0 / C · 商业化 / D · 横切 |
| Slice | |
| **本 PR 做** | |
| **本 PR 不做** | |

## PRD / 合同

| PRD | AC | 合同 |
|-----|-----|------|
| § | AC- | 无 / CapturePipeline / … |

## 测试

- [ ] `xcodebuild test` 或 N/A
- [ ] 手测：

## 决策

- [ ] 无需 `ARCHITECTURE.md` §8 更新
- [ ] 已更新 §8：

## iOS 26/27 硬红线自查（详见 [`.agents/rules/snapdrill-ios26-standards.md`](../.agents/rules/snapdrill-ios26-standards.md)）

- [ ] **架构隔离**：`Features/` 零底层视觉/相机/CoreML import；`Models/` 零 UIKit/SwiftUI；未造无第二使用者的空协议
- [ ] **Swift 6+ 并发**：Complete checking + Release 零警告；重活显式 `@concurrent`/`Task.detached`；无 `iOS 27.0+` 未守护 API
- [ ] **状态与 Glass UI**：`@Observable` + 阶段 `enum`；纯系统 `TabView`/右上角主按钮（非 `tabViewBottomAccessory`）；适配可调玻璃透明度语义色
- [ ] **端侧图像与 AI**：大图经 ImageIO 降采样及剥离 `{GPS}`；AI/同步失败显式返回并有 UI 提示（无 `try?` 静默吞错）
- [ ] **无障碍与本地化**：`ForEach` 稳定 ID；热区 ≥ 44pt + `accessibilityLabel`；5 语种 `Localizable.xcstrings` 同步
- [ ] **质量与隔离**：核心路径与降级测试全绿；调试深链/开关全包 `#if DEBUG`；不触碰 `Docs/` 与 `Samples/`

---

完整说明见 [`Docs/PR_TEMPLATE.md`](../Docs/PR_TEMPLATE.md) · [`DEVELOPMENT_PRINCIPLES.md`](../Docs/DEVELOPMENT_PRINCIPLES.md)