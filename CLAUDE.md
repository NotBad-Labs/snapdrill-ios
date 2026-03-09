# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@.claude/product.md
@.claude/principles.md
@.claude/architecture.md
@.claude/refactoring-plan.md
@.claude/infrastructure.md

## Commands

**Build & Run**
Open `SnapDrill.xcodeproj` in Xcode 26.0+ (current env: Xcode 26.3), select the `SnapDrill` scheme, and run on an iOS 26 simulator or physical device (primary test device: iPhone 17).

**Lint**
```bash
swiftlint --strict             # Run from repo root; config is .swiftlint.yml
bash Scripts/lint.sh          # Wrapper that checks if swiftlint is installed first
```

**Test (all — main app targets only)**
```bash
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Test (SPM package — macOS, no UIKit)**
```bash
# 在各包目录下运行，不依赖 Xcode
cd Packages/SnapDrillCore && swift test   # UIKit 测试自动跳过
cd Packages/SnapDrillData && swift test   # SwiftData Predicate 测试跳过（需 Xcode）
```

**Test (UIKit 依赖 / SnapDrillFeatures)**
必须通过 Xcode GUI 运行（`swift test` 不支持 UIKit 依赖，`-only-testing:SnapDrillFeaturesTests` 命令无效）。

**注意**：`xcodebuild build` 不编译测试 target，测试编译错误须通过 `swift test` 或 Xcode 才能发现。

**Install SwiftLint (required)**
```bash
brew install swiftlint
```

## Architecture

SnapDrill is a question archiving and spaced-repetition review app for students and parents, built with Swift 6.2 + SwiftUI + SwiftData, targeting iOS 26.0+. It uses a **strict modular SPM architecture** where the main app target is a thin composition root.

### Module Dependency Graph

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore (0 deps)
        │                                      ▲
        └──────────► SnapDrillUI ──────────────┘

SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

### Packages

| Package | Role |
|---|---|
| **SnapDrillCore** | Zero-dependency kernel: SM-2 scheduler, OCR/ImageStorage/Logger, Difficulty/ReviewRating enums |
| **SnapDrillData** | SwiftData `@Model` classes (direct domain objects), concrete `Repository` classes, `PersistenceController` |
| **SnapDrillUI** | Shared design system, `ImageCropper` |
| **SnapDrillFeatures** | 5 independent SPM targets: Capture, Library, Review, Dashboard, Settings — `View + ViewModel` |
| **SnapDrillInfrastructure** | Firebase implementations (Analytics/Crashlytics/RemoteConfig); only `SnapDrill/App` may import |

### Composition Root (`SnapDrill/App/`)

`DependencyContainer` (singleton, `@MainActor`) wires everything at launch:
1. `LiveServiceContainer` — OCR, analytics, crash reporting, network monitor, privacy consent
2. `RepositoryContainer` — SwiftData repositories injected via `@Environment(\.repositories)`
3. `AppRouter` — top-level navigation

### Feature Structure Pattern

Each feature in `SnapDrillFeatures/Sources/SnapDrillFeature<Name>/` follows:
- `<Feature>View.swift` — SwiftUI view, reads from ViewModel (Dashboard uses `@Query` for statistics; Library uses Repository.fetch via ViewModel due to SwiftData many-to-many limitation)
- `<Feature>ViewModel.swift` — `@Observable @MainActor final class`, all async state management
- `<Feature>Router.swift` — navigation path management (where applicable)

### Data Flow

ViewModels are injected with concrete Repository classes (not protocols) via `@Environment`. ViewModels call `ReviewScheduler` (Core) for SM-2 scheduling. Dashboard uses `@Query` for reactive statistics; other features use Repository.fetch via ViewModel. Views **never** touch `ModelContext` directly.

## 编写代码前强制研究声明（每次必走）

**在提出任何非平凡方案前，必须先输出研究声明，否则视为违反铁律。**

格式（直接输出，不得省略）：
```
研究确认：
- Apple 文档：[查了什么 / 不适用（原因）]
- 现有代码库：[找到的参考模式]
- HIG / 行业惯例：[查了什么 / 不适用（原因）]
```

**用户质量检查触发词：「铁律？」**
收到后必须立即补充完整研究声明，再继续。

平凡改动（typo、单行 bug fix、明确指定的机械改动）可免声明，但需说明"免声明理由"。

## API 使用强制规则

**修改任何代码前，必须先确认 API 真实存在，禁止凭名称推测。**

检查顺序（三选一）：
1. 查 `.claude/infrastructure.md`（所有公开接口的权威清单）
2. 用 `Grep` 搜索现有调用方式（`grep -r "methodName"` 找真实用法）
3. 用 `Read` 读源文件确认签名

新增 API 时：写完后同步更新 `.claude/infrastructure.md`。

## Key Conventions

**Swift 6 Strict Concurrency**
- All ViewModels: `@Observable @MainActor final class`
- Async `Task`s must store handles and support cancellation — no fire-and-forget I/O tasks
- Forbidden: `@unchecked Sendable`, force-unwrap `!`, `any` existentials
  - Exception 1: `EnvironmentKey.Value` holding a cross-module protocol type (eliminating `any` would require breaking the dependency direction — a more fundamental rule)
  - Exception 2: Protocols with no associated type / Self requirements used as collection element types (e.g. `[any PDFExportable]` — framework limitation, not design laziness); must add comment explaining reason
- Use `nonisolated` on computed properties of value types that don't need actor isolation

**Logging**
- Use `SnapDrillLogger` (wraps `os.Logger`) — `print()` is banned

**Error Handling**
- No `try?` silent failures on critical save/init paths

**Code Organization (MARK order)**
1. `// MARK: - Properties`
2. `// MARK: - Initialization`
3. `// MARK: - Public API`
4. `// MARK: - View Body / Lifecycle`
5. `// MARK: - Private Helpers`
6. `// MARK: - Preview`

**File Header**
Every file must have the standard Xcode copyright header followed by a one-line responsibility comment:
```swift
//  一句话描述该文件的功能。
```

**Comments**: Use Simplified Chinese for all comments. Public APIs get DocC (`///`) with Chinese description; parameter names may remain English.

**No orphan features**: Every Repository method or ViewModel public property must have a clear UI call chain. Implemented-but-UI-pending items must be tagged `// TODO: UI Integration Pending`.
