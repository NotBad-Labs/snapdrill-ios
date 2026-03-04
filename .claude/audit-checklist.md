# SnapDrill 全量代码审计清单

> **使用范围**：此清单为**大规模代码审计**（全量扫描 / 发版前深度审计）专用检查框架。
> 日常开发遵循 `principles.md`；发版前验收遵循 `release-checklist.md`。
> 上次使用：2026-03-03（164 文件，~19,275 行）
>
> 版本：1.0（2026-03-03）
> 适用于：19,275 行 / 168 个 .swift 文件 / 4 SPM 包 + 主应用
> 审计员：Claude Code
> 标准：所有批次使用完全相同的标准，不因文件大小或包的重要性而降低要求。

---

## 审计分类与检查项

### A. 注释与代码不一致（Comment-Code Mismatch）

| 编号 | 检查内容 |
|---|---|
| A1 | `///` DocC 注释描述与函数实现语义不符（说"返回今日数量"但实际返回总数等） |
| A2 | `// MARK:` 标签与该区块内容不符（标了 Private Helpers 但放了 public 方法） |
| A3 | 文件顶部一句中文责任描述与文件实际职责不符 |
| A4 | 已废弃逻辑仍留有激活状态的说明注释（即注释说"这个方法做X"但方法已做Y） |
| A5 | `// TODO:` / `// FIXME:` 指向的问题实际已修复（遗留注释），或代码有明显问题但没有 TODO |
| A6 | 注释中提到的参数、返回值与实际签名不符 |

---

### B. 命名规范（Naming Conventions）

| 编号 | 检查内容 |
|---|---|
| B1 | 同类操作动词不统一（同一模块内 `fetch` / `load` / `get` / `retrieve` 混用） |
| B2 | 布尔值命名缺少 `is` / `has` / `should` / `can` 前缀（如 `showing` 而非 `isShowing`） |
| B3 | `static let` 常量命名风格不统一（有的 lowerCamelCase，有的 UPPER_SNAKE） |
| B4 | 文件名与内部主类型名称不一致（如 `FooView.swift` 内主类型叫 `BarView`） |
| B5 | 方法/属性名称含有歧义缩写（不清晰的缩写，非通用的如 URL/ID/OCR 等） |
| B6 | 参数标签不遵循 Swift API Design Guidelines（重复的类型名，介词缺失等） |

---

### C. 访问控制（Access Control）

| 编号 | 检查内容 |
|---|---|
| C1 | `public` 标注了仅在本包内使用的类型/方法（应降为 `internal`） |
| C2 | 跨包调用的类型/方法未标 `public`（仅靠 `@testable` 能访问不算） |
| C3 | `private` 用于需要在同文件其他 extension 访问的属性（应为 `fileprivate`） |
| C4 | `@Observable` 类中状态属性访问控制与其实际使用场景不符 |
| C5 | 测试文件用到的类型实际不需要 `public`（本可 `internal + @testable`） |

---

### D. 死代码 / 僵尸属性（Dead Code）

| 编号 | 检查内容 |
|---|---|
| D1 | 声明但在整个项目中无调用的 `public` 方法 |
| D2 | `// TODO: UI Integration Pending` 标注，检查该功能是否真的没有任何 UI 路径 |
| D3 | SwiftUI View 中声明但从未在 `body` 或任何方法中引用的 `@State` / `@Binding` 属性 |
| D4 | `import` 语句引入了该文件中未使用的模块 |
| D5 | 被注释掉的代码块（`// let foo = ...`、`// func bar() {`） |
| D6 | 私有方法/属性声明后从未被调用 |

---

### E. 并发安全（Concurrency Safety）

| 编号 | 检查内容 |
|---|---|
| E1 | `Task { }` 无句柄存储（fire-and-forget I/O 任务，非 UI 动画触发可接受） |
| E2 | `nonisolated(unsafe)` 使用，必须有明确注释说明理由 |
| E3 | `deinit` 中访问 `@MainActor` 隔离的属性（Swift 6 严格并发下非法） |
| E4 | 非 `@MainActor` 上下文中同步访问 `@Observable @MainActor` 的属性 |
| E5 | `Sendable` 类型中包含非 `Sendable` 的引用类型属性（未用 `nonisolated(unsafe)` 保护） |
| E6 | `.onAppear` / `.task` 中的异步调用未考虑 View 提前消失的情况（取消安全） |

---

## 报告格式（每批次统一使用）

每个问题按以下格式报告：

```
[分类编号] 文件路径:行号
问题：一句话描述
建议：一句话修改方向
```

无问题时：
```
✅ 文件路径 — 通过全部检查项
```

---

## 批次计划

| 批次 | 内容 | 文件数 | 行数 | 状态 |
|---|---|---|---|---|
| B01 | SnapDrillCore/DI + Engine + Model | 10 | 551 | ✅ 完成 |
| B02 | SnapDrillCore/Service 前半（Analytics + CrashReporting + Logger） | 10 | 728 | ✅ 完成 |
| B03 | SnapDrillCore/Service 中（Firebase + ImageStorage + Keychain + LiveNotification + Network） | 6 | 478 | ✅ 完成 |
| B04 | SnapDrillCore/Service 后（Notification + OCR + PDF + Performance + Privacy + Subscription） | 9 | 794 | ✅ 完成 |
| B05 | SnapDrillCore/Support + Utils + SnapDrillLogger | 10 | 1,006 | ✅ 完成 |
| B06 | SnapDrillCore/Tests | 9 | 841 | ✅ 完成 |
| B07 | SnapDrillData/Sources 模型层（Models + Persistence + Error） | 10 | 638 | ✅ 完成 |
| B08 | SnapDrillData/Sources 仓库层（Repositories + DataSeeder + Container） | 7 | 1,131 | ✅ 完成 |
| B09 | SnapDrillData/Tests | 7 | 807 | ✅ 完成 |
| B10 | SnapDrillUI/Sources 长文件（AccessibilityExtensions + ContextualError + HelpView + OnboardingView） | 4 | 1,032 | ✅ 完成 |
| B11 | SnapDrillUI/Sources 短文件 + Tests | 11 | 945 | ✅ 完成 |
| B12 | SnapDrillFeatures/Capture | 11 | 1,818 | ✅ 完成 |
| B13 | SnapDrillFeatures/Dashboard | 14 | 1,772 | ✅ 完成 |
| B14 | SnapDrillFeatures/Library | 13 | 1,932 | ✅ 完成 |
| B15 | SnapDrillFeatures/Review | 12 | 1,614 | ✅ 完成 |
| B16 | SnapDrillFeatures/Settings | 14 | 2,124 | ✅ 完成 |
| B17 | SnapDrillFeatures/Environment + Tests | 3 | 534 | ✅ 完成 |
| B18 | MainApp（App/ 目录） | 4 | 407 | ✅ 完成 |
| B19 | 跨包一致性综合 + audit-report.md 生成 | — | — | ✅ 完成 |

**总计：164 个业务 .swift 文件，约 19,117 行**（Package.swift 构建配置文件不参与审计）

---

## 已知豁免项（不视为问题）

- `nonisolated(unsafe) private var dataChangeObserver: Any?` —— NotificationCenter observer 模式必需，已有注释
- `@testable import` —— 测试文件标准写法，不视为 C5 问题
- `E1 fire-and-forget`：`.task {}` modifier 由 SwiftUI 生命周期管理，View 消失时自动取消，不计入 E1
- DataSeeder 中的大型 mock 数据数组不视为 D5（注释数据）
