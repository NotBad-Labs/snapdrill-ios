---
id: ADR-003
status: Accepted
date: 2026-03-07
---

# ADR-003: 5 包结构与严格单向依赖

## 背景

随着功能增长，需要决定代码库的模块化策略。核心问题是：如何在「足够隔离以防止耦合」和「足够简单以降低维护成本」之间取得平衡。

## 决策

**采用 5 个 SPM 包，依赖严格单向，编译器强制守住边界。**

```
SnapDrillCore      (0 依赖)  — SM-2 引擎、OCR、日志、通知、枚举
SnapDrillData      (→ Core)  — @Model、Repository、持久化
SnapDrillUI        (→ Core)  — 设计系统组件、ImageCropper
SnapDrillFeatures  (→ Core, Data, UI) — 5 个独立 Feature target
SnapDrillInfrastructure (→ Core) — Firebase 实现，仅 App 可 import
```

依赖方向：
```
Features ──► Data ──► Core
    │                   ▲
    └──► UI ────────────┘

App ──► Infrastructure ──► Core
```

反向依赖禁止。Core 不得 import 任何本地包。

## 被否决的方案

### 方案 A：单包（Monolith）

- **为什么否决**：所有代码在同一编译单元，无法通过编译器强制依赖方向。随着 AI 协作者增多，没有编译器约束的架构规则会被频繁违反
- **何时适用**：项目初期原型阶段（SnapDrill 已过此阶段）

### 方案 B：更多包（按功能 1:1 拆分，如每个 Feature 独立包）

- **为什么否决**：5 个 Feature 共享 SnapDrillData 和 SnapDrillUI 的大量类型。如果每个 Feature 是独立包，会产生大量跨包类型共享问题，包管理复杂度与收益不成比例
- **何时重新评估**：如果某个 Feature 需要独立发布或被其他 App 复用

### 方案 C：Core + Data 合并为一个包

- **为什么否决**：Core 是零依赖的纯逻辑包（SM-2 算法、OCR 封装），可以在 macOS 命令行跑 `swift test`。Data 依赖 SwiftData 框架。合并后 Core 的可独立测试性丧失
- **何时重新评估**：如果 Core 包的独立测试价值不再显著（如所有测试都需要 Xcode 环境），合并可减少包管理开销

## 后果

**正面**：
- 编译器强制单向依赖，AI 协作者无法意外引入反向依赖
- Core 包可独立 `swift test`（24/24 测试，不依赖 Xcode）
- Infrastructure 包隔离 Firebase，其他包不受第三方 SDK 污染

**负面**：
- Feature 间存在依赖（Review/Dashboard/Settings → Library），增加了 Feature 模块的耦合度
- 5 个包的 Package.swift 配置需要维护

**技术债**：
- `principles.md` 标记：部分具体实现（CaptureDraftService、PDFExportService 等）暂留 Core，待拆出 Services 包后迁移
