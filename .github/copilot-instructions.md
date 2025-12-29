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
# NotBad Copilot 使用说明（中文）

## 项目概览

NotBad 是一款基于 iOS/macOS 的间隔重复记忆（spaced-repetition）学习应用（中文名：错题本），使用 **SwiftUI**、**SwiftData** 及 **Swift 6 严格并发（strict concurrency）** 构建。项目采用“盲盒设计”（blind box design）模式，将应用拆成若干相互依赖最小的 Swift Package，由上层 App 负责组装。

## 架构要点

### 盲盒设计原则（Blind Box Design）

核心规则：各 Package 尽量处理通用类型并保持最小依赖，上层 App 负责协作与组装。

示意结构：

```
NotBad App (UI + Assembly)
  ├── StorageKit (基础设施：文件存储，0 依赖)
  ├── ReviewKit (领域：模型、持久化、调度算法 → 依赖 StorageKit)
  ├── ProcessKit (工具：图像处理，0 依赖)
  ├── CaptureKit (服务：OCR、扫描，0 依赖)
  └── PaperKit (专业化：纸张 OCR → 依赖 CaptureKit + ProcessKit)
     ↑ 最小化交叉依赖 ↑
```

示例数据流：

```swift
let result = await captureService.capture(image)  // CaptureKit → CaptureResult
let cleaned = await processor.clean(image)        // ProcessKit → UIImage
let fileName = try await storage.saveImage(img, id: itemId)  // StorageKit → String
let item = ReviewItemModel(content: result.text, imagePath: fileName)  // ReviewKit
modelContext.insert(item)
```

注意：Infrastructure 层（例如 StorageKit）不应被服务层（CaptureKit）直接引用；只有领域层（ReviewKit）可以依赖 StorageKit。

### 模块职责

- `StorageKit`：基础设施层（示例类型：`ImageStorageService` actor、`StorageConfiguration`），零外部依赖（Foundation、CoreGraphics）。
- `ReviewKit`：领域层（示例：`ReviewItemModel`、`ReviewScheduler`），依赖 `StorageKit`。
- `ProcessKit`：工具层（示例：`ImageProcessor` actor、`ColorBasedEraser`），零外部依赖（CoreImage、CoreML）。
- `CaptureKit`：服务层（示例：`CaptureResult`、`OCRService`），零外部依赖（Vision、VisionKit）。
- `PaperKit`：专业化包，依赖 `CaptureKit` 与 `ProcessKit`。
- `NotBad App`：UI 与组装层，依赖所有包。

依赖层级（自底向上）：StorageKit → ProcessKit → CaptureKit → ReviewKit → PaperKit → NotBad App

## 关键约定

### Swift 6 严格并发

- 所有 Package 使用 Swift 6 模式（在 `Package.swift` 中设置 `.swiftLanguageMode(.v6)`）。
- 回调使用 `@Sendable` 标注（例如 `ReviewScheduler.masteryMultiplierFn`）。
- I/O 服务使用 `actor` 封装（示例：`ImageStorageService`、`ImageProcessor`）。
- 仅在 UI 层使用 `@MainActor`，包内代码避免使用。

### SwiftData 使用

- 使用 App Groups 共享 `ModelContainer`（标识：`group.com.yimingliao.NotBad`）。
- 通过 `PersistenceController.shared.container` 获取容器（在 `ReviewKit` 中定义）。
- 在视图中使用 `@Query`，写入请使用 `modelContext.insert()`。
- 模型位于 `ReviewKitModels` 目标中（参见 `Packages/ReviewKit/Package.swift`）。

### 测试策略

- `ReviewKit` / `CaptureKit` 使用 Swift Testing 框架（`import Testing`）。
- `ProcessKit` 在迁移期间混合使用 `XCTest` 与 Swift Testing。
- 运行测试示例：

```
swift test --package-path Packages/ReviewKit
```

CI 使用 GitHub Actions 的自托管 macOS ARM64 runner（详见 `CI_SETUP.md`）。

## 关键模式

### 1. 充血模型（Rich Domain Model）

`ReviewItemModel` 应包含业务逻辑方法，例如：

```swift
@Model
public final class ReviewItemModel {
  public func recordReview(performance: ReviewPerformance) {
    // 使用 ReviewScheduler 更新 nextReviewDate、reviewCount 等
  }
}
```

该逻辑不要放在 ViewModel 或 Service 层。

### 2. ReviewScheduler 算法要点

- 使用 0-based 索引：`reviewCount` 在调度器中为 0 起始（对应 `baseIntervals[0]`）。
- 性能等级（Performance enum，5 级）：`.forgot`、`.vague`、`.basic`、`.familiar`、`.easy`。
- 公式示例：`interval = baseIntervals[count] * masteryMultiplier(performance)`；当 `count` 超出数组时，使用几何增长策略。

详见：`Packages/ReviewKit/ARCHITECTURE.md` 中的 ReviewScheduler 部分。

### 3. 图片存储

- `CaptureKit` 使用 `ImageStorageService`（actor）进行异步 I/O。
- 文件存储在 App Groups 共享目录，使用 `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`。
- 图片以 `{itemId}_{timestamp}.jpg` 格式命名并保存。

## 开发与工作流

### 构建应用

在 Xcode 中打开：

```
open NotBad.xcodeproj
```

在 Xcode 中构建：`Cmd+B`；运行模拟器：`Cmd+R`。

若缺少 CaptureKit / ProcessKit 依赖，可在 Target → General → Frameworks 中添加。

### 运行测试

```
cd Packages/ReviewKit && swift test
```

或使用 `swift test --verbose` 获取更详细输出。

### Git Flow（推荐）

- `main`：生产分支，仅用于发布。
- `develop`：开发主分支。
- `feature/`：从 `develop` 分支创建用于新功能开发。
- `release/`：发布前的修复与测试。
- `hotfix/`：从 `main` 创建的紧急修复分支。

## 常见任务示例

添加新复习项（示例）：

```swift
let result = try await captureService.captureAndSave(image: img, itemId: id)
let item = ReviewItemModel(content: result.text, imagePath: fileName)
modelContext.insert(item)
```

实现图像处理建议：在 `ProcessKit.ImageProcessor`（actor）中添加方法，输入输出使用通用类型（`UIImage` / `CGImage`）。

修改 Review 算法时，请在 `ReviewKitCore` 中更新 `ReviewScheduler`，并更新对应测试用例。

## 避免的坑

1. 不要在包之间随意互相引用（会破坏盲盒设计）。
2. 不要用 `Int` 表示 mastery，使用类型安全的 `ReviewPerformance` 枚举。
3. 注意 0-based 与 1-based 的转换。
4. 包代码应保持平台无关，不引入 UI 依赖。
5. 严格遵守 `@Sendable` 注释以通过并发检查。

## 参考文件

- `NotBad/ARCHITECTURE.md`
- `Packages/ReviewKit/ARCHITECTURE.md`
- `Packages/README.md`
- `docs/REFACTORING_ISSUES.md`

---

如有疑问，可参考盲盒设计原则：若一个包需要另一个包的具体类型，请改为传递通用类型以保持解耦。

