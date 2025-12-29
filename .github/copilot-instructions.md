# NotBad Copilot Instructions

## Project Overview

NotBad is an iOS/macOS spaced-repetition study app ("错题本") built with **SwiftUI**, **SwiftData**, and **Swift 6 strict concurrency**. The architecture follows a **"blind box design"** pattern where the main app orchestrates five independent Swift Packages with minimal cross-dependencies.

## Architecture Fundamentals

### Blind Box Design Principle

**Core Rule**: Packages handle generic types and have minimal dependencies. The app layer is the sole coordinator.

```
NotBad App (UI + Assembly)
  ├── StorageKit (Infrastructure: file storage, 0 dependencies)
  ├── ReviewKit (Domain: models, persistence, scheduling algorithm → StorageKit)
  ├── ProcessKit (Utility: image processing, 0 dependencies)
  ├── CaptureKit (Service: OCR, scanning, 0 dependencies)
  └── PaperKit (Specialized: paper document processing → CaptureKit + ProcessKit)
       ↑ Minimal cross-dependencies ↑
```

**Data Flow Example**:
```swift
// ✅ Correct: App assembles generic results into domain models
let result = await captureService.capture(image)  // CaptureKit → CaptureResult
let cleaned = await processor.clean(image)        // ProcessKit → UIImage
let fileName = try await storage.saveImage(img, id: itemId)  // StorageKit → String
let item = ReviewItemModel(content: result.text, imagePath: fileName)  // ReviewKit
modelContext.insert(item)

// ❌ Wrong: CaptureKit returning ReviewItemModel or importing StorageKit
// Infrastructure layer (StorageKit) should not be imported by service layer (CaptureKit)
// Only ReviewKit (domain) depends on StorageKit
```

### Module Responsibilities

| Package | Role | Key Types | Dependencies |
|---------|------|-----------|--------------|
| **StorageKit** | Infrastructure layer | `ImageStorageService` (actor), `StorageConfiguration` | **0** (Foundation, CoreGraphics) |
| **ReviewKit** | Domain layer | `ReviewItemModel` (@Model), `ReviewScheduler` | StorageKit |
| **ProcessKit** | Utility layer | `ImageProcessor` (actor), `ColorBasedEraser` | **0** (CoreImage, CoreML) |
| **CaptureKit** | Service layer | `CaptureResult`, `OCRService` | **0** (Vision, VisionKit) |
| **PaperKit** | Specialized layer | `PaperOCRService` | CaptureKit, ProcessKit |
| **NotBad App** | UI + Assembly | Views, App Groups config | All packages |

**Dependency Hierarchy** (bottom to top):
1. StorageKit (0 dependencies) ← foundation
2. ProcessKit (0 dependencies) ← pure utility
3. CaptureKit (0 dependencies) ← independent service
4. ReviewKit (→ StorageKit) ← domain layer
5. PaperKit (→ CaptureKit + ProcessKit) ← specialized
6. NotBad App (→ all) ← coordinator

## Critical Conventions

### Swift 6 Strict Concurrency

- **All** packages require Swift 6 language mode (`.swiftLanguageMode(.v6)` in Package.swift)
- Use `@Sendable` closures for callbacks (e.g., `ReviewScheduler.masteryMultiplierFn`)
- Wrap I/O services in `actor` (see `ImageStorageService`, `ImageProcessor`)
- Use `@MainActor` only in UI layer; avoid in package code

### SwiftData Usage

- Shared `ModelContainer` via App Groups (`group.com.yimingliao.NotBad`)
- Access via `PersistenceController.shared.container` (defined in ReviewKit)
- Use `@Query` in views, `modelContext.insert()` for writes
- Models live in `ReviewKitModels` target (see [ReviewKit/Package.swift](Packages/ReviewKit/Package.swift))

### Testing Strategy

- **ReviewKit/CaptureKit**: Use Swift Testing framework (`import Testing`)
- **ProcessKit**: Mix of `XCTest` and Swift Testing (migrating)
- Run tests: `swift test --package-path Packages/ReviewKit`
- CI: GitHub Actions self-hosted runner (see [CI_SETUP.md](CI_SETUP.md))

## Key Patterns

### 1. Rich Domain Model (充血模型)

`ReviewItemModel` contains business logic methods:

```swift
@Model
public final class ReviewItemModel {
    public func recordReview(performance: ReviewPerformance) {
        // Updates nextReviewDate, reviewCount using ReviewScheduler
    }
}
```

Don't put this logic in ViewModels or Services—keep it in the model.

### 2. ReviewScheduler Algorithm

**0-based indexing**: `reviewCount` parameter is 0-indexed (matching `baseIntervals[0]`).

```swift
// Model stores 1-based count; convert when calling scheduler
let nextDate = scheduler.calculateNextReviewDate(
    mastery: .basic,
    reviewCount: max(0, item.reviewCount - 1)  // ← Important!
)
```

**Performance enum** (5 levels): `.forgot`, `.vague`, `.basic`, `.familiar`, `.easy`  
Algorithm: `interval = baseIntervals[count] × masteryMultiplier(performance)`  
When count exceeds array: `interval = lastInterval × growthFactor^excess`

See [Packages/ReviewKit/ARCHITECTURE.md](Packages/ReviewKit/ARCHITECTURE.md#2-reviewscheduler-核心算法) for details.

### 3. Image Storage

- **CaptureKit** handles async I/O via `ImageStorageService` (actor)
- Files stored in App Groups shared directory: `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`
- Images saved with UUID-based names: `{itemId}_{timestamp}.jpg`
- **Debug mode**: Orphaned image cleanup runs in `NotBadApp.init()` (see [NotBad/App/NotBadApp.swift](NotBad/App/NotBadApp.swift#L33))

### 4. Package Structure

Each package has modular targets (example from ReviewKit):

```
ReviewKit (umbrella)
  ├── ReviewKitCore (pure algorithm, no SwiftData)
  ├── ReviewKitModels (@Model entities)
  ├── ReviewKitPersistence (Configuration, ImageStorageService)
  └── ReviewKitCLI (executable for testing pure logic)
```

This allows ReviewKitCore to be reused in CLI/server contexts without SwiftData.

## Development Workflows

### Building the App

```bash
# Open in Xcode (required for iOS/macOS builds)
open NotBad.xcodeproj

# Build in Xcode: Cmd+B
# Run on simulator: Cmd+R
```

**Build Fix**: If missing CaptureKit/ProcessKit dependencies, add them in Xcode:  
Target → General → Frameworks → `+` → Add `CaptureKit` and `ProcessKit`  
(See [BUILD_FIX.md](BUILD_FIX.md) for details)

### Running Tests

```bash
# Test specific package
cd Packages/ReviewKit && swift test

# With verbose output
swift test --verbose

# CI runs on self-hosted macOS ARM64 runner
# Trigger: Push to Packages/ReviewKit/** or manual workflow dispatch
```

### Git Flow

- **main**: Production releases only
- **develop**: Main development branch (current default)
- **feature/**: New features branch from develop
- **release/**: Pre-release testing
- **hotfix/**: Emergency fixes from main

## Common Tasks

### Adding a New Review Item

1. Use `CaptureKit` to get OCR text and save image:
   ```swift
   let result = try await captureService.captureAndSave(image: img, itemId: id)
   ```
2. Create `ReviewItemModel` with result data
3. Insert into `modelContext`: `modelContext.insert(item)`

### Implementing Image Processing

- Add methods to `ProcessKit.ImageProcessor` (actor)
- Input/output must be generic types (`UIImage`, `CGImage`)
- Never import ReviewKit or CaptureKit
- Call from app layer after capture: `let cleaned = await processor.removeColoredInk(from: image, colors: [.blue])`

### Modifying Review Algorithm

- Edit `ReviewScheduler` in `ReviewKitCore` (stays pure Swift)
- Update tests in `ReviewSchedulerTests.swift`
- Remember: `reviewCount` is 0-based in scheduler API
- Run full test suite before committing changes

## Pitfalls to Avoid

1. **Don't** import packages into each other (breaks blind box design)
2. **Don't** use `Int` for mastery—use `ReviewPerformance` enum (strongly typed)
3. **Don't** forget 0-based/1-based conversion when calling `ReviewScheduler`
4. **Don't** add UI dependencies to packages (keep them platform-agnostic)
5. **Don't** skip `@Sendable` annotations (strict concurrency will fail)
6. **Don't** create temporary files for data flow—use pipes/streams in terminal commands

## Key Files to Reference

- Architecture overview: [NotBad/ARCHITECTURE.md](NotBad/ARCHITECTURE.md)
- ReviewKit algorithm: [Packages/ReviewKit/ARCHITECTURE.md](Packages/ReviewKit/ARCHITECTURE.md)
- Package philosophy: [Packages/README.md](Packages/README.md)
- Refactoring backlog: [docs/REFACTORING_ISSUES.md](docs/REFACTORING_ISSUES.md)

## Debugging Tips

- Check `PersistenceController` initialization if SwiftData crashes
- Verify App Groups entitlements: `NotBad.entitlements` should have `group.com.yimingliao.NotBad`
- For image loading issues, check `ImageStorageService` logs (uses `os.log`)
- CI failures: Ensure self-hosted runner is online ([CI_SETUP.md](CI_SETUP.md))

---

**When in doubt**: Read the blind box principle. If a package needs to know about another package's types, you're doing it wrong—pass generic types instead.
