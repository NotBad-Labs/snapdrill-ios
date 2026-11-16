# SnapDrill · 工程说明（greenfield）

## 打开与编译

```bash
cd /path/to/snapdrill-ios
xcodegen generate    # 修改 project.yml 后重跑
open SnapDrill.xcodeproj
```

- **最低系统**：iOS 26+（见 PRD §3.2）
- **签名**：在 Xcode 为 `SnapDrill` 选择你的 **Team**（仓库内 `project.yml` 默认可本地 `CODE_SIGNING_ALLOWED: NO` 仅用于无签名 compile smoke）

## 方案 1 · 当前实现边界

| 模块 | 状态 | 对应 AC |
|---|---|---|
| Tab + 纸与笔主题 | Slice 1 ✅ | AC-01 部分 |
| SwiftData 科目预置 | Slice 1 ✅ | AC-01 |
| 采集三步 | **占位 UI** | Slice 2 进行中 |
| F-10 去手写 | **占位降级**（§8.6） | AC-04 未验收 |
| 订阅 / iCloud / PDF | 占位 | 后续 Slice |

路线见 [`ROADMAP.md`](ROADMAP.md)。

## 目录

```
SnapDrill/           SwiftUI 应用源码
SnapDrillTests/      单元测试
project.yml          XcodeGen 定义
```