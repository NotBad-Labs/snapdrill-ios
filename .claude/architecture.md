# SnapDrill 架构（2026-03-07 最终状态）

> **上游依赖**：`principles.md`（工程哲学、包边界原则、DI 原则）
>
> Last verified: 2026-03-19（全量审计，与代码库一致）

## 包结构（5 包）

```
SnapDrillCore    (0 deps)
  └─ SM-2 调度器（ReviewScheduler）
  └─ OCR / ImageStorage / Logger
  └─ ReviewDataNotification
  └─ Difficulty / ReviewRating enums

SnapDrillData    (→ Core)
  └─ @Model 类（直接作领域对象，无映射层）
  └─ 具体 Repository 类（无协议）
  └─ PersistenceController / 迁移计划
  └─ ReviewExportSnapshot（导出专用 Sendable 快照）

SnapDrillUI      (→ Core)
  └─ 设计系统组件 / ImageCropper

SnapDrillFeatures（5 个独立 target）
  SnapDrillFeatureCapture   (→ Core, Data, UI)
  SnapDrillFeatureLibrary   (→ Core, Data, UI)  ← 含分类管理（Subject/Source/Grade）
  SnapDrillFeatureReview    (→ Core, Data, UI, Library)
  SnapDrillFeatureDashboard (→ Core, Data, UI, Library)
  SnapDrillFeatureSettings  (→ Core, Data, UI, Library)

SnapDrillInfrastructure (→ Core; 仅 SnapDrill/App 可 import)
  └─ Firebase 实现（Analytics / RemoteConfig）
  └─ FirebaseBootstrap

SnapDrill/App（薄壳组合根）
  └─ DependencyContainer（唯一单例）
  └─ AppRouter
```

## 模块依赖方向（严格单向）

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore
        │                                     ▲
        └──────────► SnapDrillUI ─────────────┘

SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

反向依赖禁止。SnapDrillCore 不得 import 任何本地包。
SnapDrillInfrastructure 只能被 SnapDrill/App 直接依赖，Features/Data/UI/Core 均禁止 import。

## 数据流

```
@Query（SwiftUI）
  └─ 驱动 View 自动刷新（无需 NotificationCenter）

ViewModel
  └─ 注入具体 Repository（非协议）
  └─ 调用 ReviewScheduler（Core）计算 SM-2 调度
  └─ 直接写入 ModelContext（通过 Repository）

View
  └─ 只读 ViewModel 状态，转发用户事件
  └─ 不直接接触 ModelContext
```

## DI 链路

```
DependencyContainer（@MainActor 单例）
  ├─ LiveServiceContainer  → .environment(\.services)
  ├─ RepositoryContainer   → .environment(\.repositories)
  └─ AppRouter
```

`DefaultUseCaseContainer` 已删除。`\.useCases` Environment key 已删除。

## Feature 结构

```
SnapDrillFeatures/Sources/SnapDrillFeature<Name>/
  ├─ <Feature>View.swift
  ├─ <Feature>ViewModel.swift
  └─ <Feature>Router.swift（如有导航）
```

## 关键设计决策

| 决策 | 结论 |
|---|---|
| Domain 层 | **已删除**。@Model 直接作领域对象，无映射层 |
| UseCase 层 | **已删除**。ViewModel 直接调 Repository |
| Repository 协议 | **已删除**。具体类直接使用，测试用 in-memory ModelContainer |
| 持久化框架 | SwiftData（非 CoreData / SQLite / Realm） |
| 包结构 | 5 包严格单向依赖 |
| DI 模式 | DependencyContainer 唯一单例 + @Environment |
| Infrastructure 隔离 | Firebase 封装在独立包，仅 App 可 import |
| 复习算法 | SM-2（经典，简单，与产品定位匹配） |
| Export DTO | `ReviewExportSnapshot`（6字段 Sendable struct），桥接 @Model → Transferable | — |
| 列表驱动 | @Query（LibraryView 等），Repository.fetch（ReviewViewModel 状态机）| — |

## Feature 间依赖（2026-03-07 精化）

```
SnapDrillFeatureCapture   ──► Core, Data, UI
SnapDrillFeatureLibrary   ──► Core, Data, UI
SnapDrillFeatureReview    ──► Core, Data, UI, Library（LibraryEditView 嵌入复习卡）
SnapDrillFeatureDashboard ──► Core, Data, UI, Library（SubjectManagerView）
SnapDrillFeatureSettings  ──► Core, Data, UI, Library（SubjectManager / SourceManager / GradeManager）
```

分类管理视图（SubjectManagerView 等）语义归属 Library（题目元数据 CRUD），
不属 Dashboard（统计看板）。Settings 直接依赖 Library，无需经由 Dashboard。

## 平台技术能力（2026-03-23 从 product-vision.md 迁入）

> **上游决策**：`product-vision.md`§市场与平台 确定 iOS/iPadOS 为唯一主战场。
> 本节记录支撑该决策的技术细节。

### 依赖的 Apple 原生能力

- **Apple Vision Framework**：`RecognizeTextRequest` 印刷体中英文 OCR（18 种语言，端上实时运行，无需联网）+ `VNDetectTextRectanglesRequest` 实时文字区域检测
- **VNDocumentCameraViewController**：系统级文档扫描（自动透视校正、边缘检测、多页扫描）
- **Foundation Models**（iOS 26+）：端上 AI（文本分类、摘要等，4096 token 上下文，多语言含中文）
- **CloudKit / iCloud**：零服务器同步方案
- **PencilKit / Smart Script**：iPad 手写输入体验（屏幕手写，非照片识别）

### 技术声明修正（2026-03-23）

- Vision Framework 的 OCR 强项是**印刷体**识别。手写体识别有一定支持（`.accurate` 识别级别），但无独立的中文手写识别模型
- Math Notes 是 Calculator App 的私有能力，**无公开 API**，第三方 App 无法调用
- Smart Script 是 PencilKit 屏幕手写输入系统，不是照片中手写文字的 OCR 识别
- Foundation Models 擅长文本理解/分类/摘要，**不擅长数学推理和逻辑计算**

### 平台对比（2026-03-23 修正，基于 Apple 官方文档核实）

| 能力 | Apple（iOS/iPadOS） | HarmonyOS | Android |
|---|---|---|---|
| 印刷体 OCR | 18 种语言，中文专用模型，端上运行 | 10 种语言 | Google ML Kit（端上可用，中文支持弱于 Apple Vision） |
| 实时文字区域检测 | VNDetectTextRectanglesRequest | 无平台级 API | 无平台级 API |
| 文档扫描 | VNDocumentCameraViewController（系统级） | 无 | 无平台级 API |
| 端上 AI | Foundation Models（iOS 26+） | 无对应 | 无对应 |
| 手写输入 | PencilKit + Smart Script（iPad） | 无 | 无 |

Android / HarmonyOS 即使要做，也无法复制同等体验。

## 验证结果（2026-03-23 更新）

| 指标 | 值 |
|---|---|
| SPM 包数 | 5 |
| 平台声明 | 全部仅 `.iOS(.v26)`（无 macOS） |
| Swift 文件数 | 174（137 production + 37 tests） |
| 测试 | 须通过 Xcode Simulator 运行（SPM 包不声明 macOS，`swift test` 不可用）|
| xcodebuild build | BUILD SUCCEEDED ✅ |
| swiftlint | 0 violations ✅ |
