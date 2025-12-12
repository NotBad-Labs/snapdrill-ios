> **Archived**: not part of public documentation; may be outdated.

# Swift 6.2 迁移计划

> 创建日期：2025-12-08  
> 状态：**规划中**  
> 当前 Swift 版本：6.2.1（已安装）  
> 目标 Package swift-tools-version：**6.2**  
> 当前 Package swift-tools-version：5.9

---

## 一、现状分析

### 1.1 Kit 清单

| Kit | swift-tools-version | 严格并发 | 平台要求 | LOC | 状态 |
|-----|---------------------|----------|----------|-----|------|
| ReviewKit | 6.2 | ✅ `StrictConcurrency` | iOS 17+ / macOS 14+ | ~900 | ✅ 已完成 |
| CaptureKit | 6.2 | ✅ `StrictConcurrency` | iOS 17+ / macOS 14+ | ~700 | ✅ 已完成 |
| ProcessKit | 6.2 | ✅ `StrictConcurrency` | iOS 17+ / macOS 14+ | ~200 | ✅ 已完成 |

### 1.2 待升级项

- [x] Package.swift 升级到 `swift-tools-version: 6.2`
- [x] 所有 Kit 启用严格并发
- [ ] 继续优化 CaptureKit 和 ProcessKit 的功能和测试
- [ ] 迁移到 Swift Testing 框架
- [ ] 采用 typed throws（明确错误类型）
- [ ] 评估 @Observable 替换 @ObservableObject（App 层）

---

## 二、迁移步骤

### 阶段 1：基础升级（预计 1-2 天）

#### Step 1.1：升级 ReviewKit（已有严格并发，风险最低）

```bash
# 1. 修改 Package.swift
# swift-tools-version: 5.9 → swift-tools-version: 6.2

# 2. 运行测试验证
cd Packages/ReviewKit && swift test
```

**检查清单：**
- [x] 修改 `swift-tools-version: 6.2`
- [x] 确认 `StrictConcurrency` 无警告
- [x] 所有测试通过

#### Step 1.2：升级 CaptureKit

```bash
# 1. 添加严格并发设置
swiftSettings: [
    .enableExperimentalFeature("StrictConcurrency")
]

# 2. 修复可能的并发警告
# 3. 运行测试
cd Packages/CaptureKit && swift test
```

**检查清单：**
- [x] 添加 `StrictConcurrency`
- [x] 修复 `Sendable` 警告
- [x] 确认 `ImageStorageService` 线程安全
- [x] 所有测试通过

#### Step 1.3：升级 ProcessKit

```bash
cd Packages/ProcessKit && swift test
```

**检查清单：**
- [x] 添加 `StrictConcurrency`
- [x] 确认图像处理相关并发安全
- [x] 所有测试通过

---

### 阶段 2：功能优化（预计 2-3 天）

#### Step 2.1：CaptureKit 功能完善

已完成将 OCRKit 和 ImageKit 的功能整合到 CaptureKit 中，形成统一的录入链路。

**当前功能：**
- ✅ 图片存储服务（ImageStorageService）
- ✅ OCR 文字识别（OCRService）
- ✅ 文档扫描（Scanner/DraftScan）
- ✅ 实时文档检测（LiveDocumentDetector）

#### Step 2.2：ProcessKit 功能优化

**当前功能：**
- ✅ 图像处理器（ImageProcessor）
- ✅ 颜色擦除（ColorBasedEraser）
- ⏳ Core ML 模型集成（规划中）

---

### 阶段 3：Swift 6.2 新特性采用（预计 1 周）

#### Step 3.1：迁移到 Swift Testing

**Before (XCTest):**
```swift
import XCTest

final class ReviewSchedulerTests: XCTestCase {
    func testCalculateNextReview() {
        XCTAssertEqual(result, expected)
    }
}
```

**After (Swift Testing):**
```swift
import Testing

@Suite("ReviewScheduler Tests")
struct ReviewSchedulerTests {
    @Test("Calculate next review date")
    func calculateNextReview() {
        #expect(result == expected)
    }
}
```

**检查清单：**
- [x] ReviewKit 测试迁移
- [ ] CaptureKit 测试迁移
- [ ] ProcessKit 测试迁移

#### Step 3.2：Typed Throws

**Before:**
```swift
func scan(image: CGImage) throws -> String
```

**After:**
```swift
enum ScanError: Error {
    case noTextFound
    case recognitionFailed(underlying: Error)
}

func scan(image: CGImage) throws(ScanError) -> String
```

**适用位置：**
- [ ] `OCRService.recognizeText()`
- [ ] `ImageStorageService.save()` / `.load()`
- [ ] `ReviewScheduler.calculateNextReview()`

#### Step 3.3：@Observable（App 层）

**Before:**
```swift
class SomeViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

**After:**
```swift
@Observable
class SomeViewModel {
    var items: [Item] = []
}
```

**检查清单：**
- [ ] 识别 App 层所有 `@ObservableObject`
- [ ] 逐个替换为 `@Observable`
- [ ] 更新 View 中的 `@ObservedObject` → 直接引用

---

### 阶段 4：App 主工程升级（预计 2-3 天）

#### Step 4.1：Xcode 项目设置

1. 打开 `NotBad.xcodeproj`
2. Build Settings → Swift Language Version → Swift 6
3. Build Settings → Strict Concurrency Checking → Complete

#### Step 4.2：修复并发警告

常见问题：
- `@MainActor` 标注
- `Sendable` 协议遵循
- `Task` / `async` 边界处理

#### Step 4.3：验证

```bash
# 全量构建
xcodebuild -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16' build

# 运行测试
xcodebuild test -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 三、风险与回退

### 3.1 风险点

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 并发警告过多 | 阻塞开发 | 可暂时用 `@preconcurrency` 标注 |
| 第三方库不兼容 | 编译失败 | 检查依赖是否支持 Swift 6 |
| 测试框架迁移遗漏 | 覆盖率下降 | 迁移前后对比测试数量 |

### 3.2 回退方案

```bash
# 如果升级失败，回退到之前的 commit
git checkout <previous-commit-hash> -- Packages/
```

---

## 四、验收标准

- [x] 所有 Kit 使用 `swift-tools-version: 6.2`
- [x] 所有 Kit 启用 `-strict-concurrency=complete`
- [x] 零编译警告（或有明确的 `@preconcurrency` 注释说明）
- [x] 所有现有测试通过
- [x] App 主工程编译通过
- [ ] UI 测试通过

---

## 五、进度跟踪

| 日期 | 完成项 | 备注 |
|------|--------|------|
| 2025-12-08 | 创建迁移计划 | |
| 2025-12-08 | ReviewKit 升级 Swift 6.2 | 14 测试通过，修复 Sendable 问题 |
| 2025-12-08 | CaptureKit 升级 Swift 6.2 | 整合 ImageKit/OCRKit 功能，测试通过 |
| 2025-12-08 | ProcessKit 升级 Swift 6.2 | 图像处理功能，测试通过 |
| 2025-12-08 | App 主工程构建验证 | ✅ 构建成功（Swift 6 模式） |
| 2025-12-08 | NotBadTests 单元测试 | ✅ 30 测试通过 |
| | | |

---

## 六、参考资料

- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/migrationguide/)
- [Swift Testing](https://developer.apple.com/documentation/testing)
- [Typed Throws](https://github.com/apple/swift-evolution/blob/main/proposals/0413-typed-throws.md)
- [Observable Macro](https://developer.apple.com/documentation/observation)
