# SnapDrill · 工程说明（greenfield）

## 打开与编译

```bash
cd /path/to/snapdrill-ios
xcodegen generate    # 修改 project.yml 后重跑
open SnapDrill.xcodeproj
```

- **最低系统**：iOS 26+（见 PRD §3.2）
- **签名（真机必做）**：Xcode → 选中工程 **SnapDrill** → **Signing & Capabilities** → 勾选 **Automatically manage signing** → 选你的 **Team**（Apple ID 即可个人开发）。若 Bundle ID 冲突，可改成唯一值如 `com.yourname.snapdrill`。
- **纯编译烟测（无签名）**：`xcodebuild` 可加 `CODE_SIGNING_ALLOWED=NO`（仅模拟器/CI，**不能装真机**）。

## 基线设备（PO 2026-11-16）

| 角色 | 设备 | 用途 |
|---|---|---|
| **日常 Dogfood / 你做主体验** | **iPhone 17 标准版**（真机） | 默认开发和手感验证 |
| **上架合规性能（PRD 未改前）** | iPhone 11 / SE 第二代 | AC-04「≤2s」、阶段 0 Q2 的**法定基准** |
| **CI / Agent 自动测试** | **iPhone 17 Simulator**（Xcode 27.2） | `xcodebuild test`、编译烟测 |

说明：用 iPhone 17 当真机基线完全合理且更快；**不能替代**最老支持机型的性能抽检。上架前建议至少在 11/SE2（或租借/模拟降级策略）上抽测去手写耗时，除非 PO 正式改 PRD §3.2/§9。

真机离线时 Xcode 会显示「Devices Offline」；插上 USB / 同一 Wi‑Fi 调试即可。

## 方案 1 · 当前实现边界

| 模块 | 状态 | 对应 AC |
|---|---|---|
| Tab + 纸与笔主题 | Slice 1 ✅ | AC-01 部分 |
| SwiftData 科目预置 | Slice 1 ✅ | AC-01 |
| 采集三步 | **占位 UI** | Slice 2 进行中 |
| F-10 去手写 | **占位降级**（§8.6） | AC-04 未验收 |
| 订阅 / iCloud / PDF | 占位 | 后续 Slice |

路线见 [`ROADMAP.md`](ROADMAP.md)。

**冷启动**：系统 Launch Screen 使用 `PaperBackground` 纸色；首装首次打开仍会创建 SwiftData 库（约 1–2s），`StartupView` 显示纸色 + 小加载圈，避免纯白屏。PRD 目标冷启动进相机 1.5s 在 Slice 2+ 再优化。

## 目录

```
SnapDrill/           SwiftUI 应用源码
SnapDrillTests/      单元测试
project.yml          XcodeGen 定义
```