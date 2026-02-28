# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build & Run**
Open `SnapDrill.xcodeproj` in Xcode 26.0+ (current env: Xcode 26.3), select the `SnapDrill` scheme, and run on an iOS 18 simulator or physical device (primary test device: iPhone 17).

**Lint**
```bash
swiftlint                     # Run from repo root; config is .swiftlint.yml
bash Scripts/lint.sh          # Wrapper that checks if swiftlint is installed first
```

**Test (all)**
```bash
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Test (single package)**
```bash
# SnapDrillCoreTests only
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SnapDrillCoreTests

# SnapDrillDataTests only
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SnapDrillDataTests
```

**Install SwiftLint (required)**
```bash
brew install swiftlint
```

## Architecture

SnapDrill is a spaced-repetition (flashcard) learning app built with Swift 6.2 + SwiftUI + SwiftData, targeting iOS 18.0+. It uses a **strict modular SPM architecture** where the main app target is a thin composition root.

### Module Dependency Graph

```
SnapDrillFeatures ──► SnapDrillDomain ──► SnapDrillCore (0 deps)
        │                   │
        ▼                   ▼
  SnapDrillData ──────► SnapDrillCore
        │
        ▼
  SnapDrillUI ────────► SnapDrillCore
```

**Strict rule**: reverse dependencies are forbidden. `SnapDrillCore` must never import any other local package.

### Packages

| Package | Role |
|---|---|
| **SnapDrillCore** | Zero-dependency kernel: domain entities (protocol-based), OCR/Capture/ImageStorage services, spaced-repetition engine, utils |
| **SnapDrillDomain** | Use case layer (Clean Architecture): `ReviewUseCase`, `TaxonomyUseCase`, repository protocols, `UseCaseContainer` |
| **SnapDrillData** | SwiftData persistence: `*Model` classes, `*Repository` implementations, `PersistenceController`, migration plan |
| **SnapDrillUI** | Shared design system, `ImageCropper`, routing base protocols |
| **SnapDrillFeatures** | All product features: Capture, Library, Review, Dashboard, Settings — each as a folder with `View + ViewModel` |

### Composition Root (`SnapDrill/App/`)

`DependencyContainer` (singleton, `@MainActor`) wires everything at launch:
1. `LiveServiceContainer` — OCR, analytics, crash reporting, network monitor, privacy consent
2. `DefaultRepositoryContainer` — SwiftData repositories injected via `@Environment(\.repositories)`
3. `DefaultUseCaseContainer` — use cases injected via `@Environment(\.useCases)`
4. `AppRouter` — top-level navigation

All dependencies flow into the view tree through SwiftUI `Environment` keys defined in `SnapDrillFeatures/Sources/SnapDrillFeatures/Environment/`.

### Feature Structure Pattern

Each feature in `SnapDrillFeatures/Sources/SnapDrillFeatures/<FeatureName>/` follows:
- `<Feature>View.swift` — SwiftUI view, reads from ViewModel
- `<Feature>ViewModel.swift` — `@Observable @MainActor final class`, all async state management
- `<Feature>Router.swift` — navigation path management (where applicable)

### Data Flow

Views read from `@Environment` to get repositories/use cases, pass them to ViewModels at init. ViewModels call UseCases (domain layer) or Repositories (data layer) directly. Views **never** touch `ModelContext` directly.

## Key Conventions

**Swift 6 Strict Concurrency**
- All ViewModels: `@Observable @MainActor final class`
- Async `Task`s must store handles and support cancellation — no fire-and-forget I/O tasks
- Forbidden: `@unchecked Sendable`, force-unwrap `!`, `any` existentials
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
//  核心职责：一句话描述该文件的功能。
```

**Comments**: Use Simplified Chinese for all comments. Public APIs get DocC (`///`) with Chinese description; parameter names may remain English.

**No orphan features**: Every Repository method or ViewModel public property must have a clear UI call chain. Implemented-but-UI-pending items must be tagged `// TODO: UI Integration Pending`.
