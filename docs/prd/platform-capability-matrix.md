# 平台能力与降级矩阵

**文档版本**: v6.0  
**最后更新**: 2025-09-18  
**关联文档**: [PRD v6.0](./NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0%20(Swift6.2%20+%20iOS26).md)

## 概述

本文档定义了 NotBad 错题本 App 在不同 iOS 版本和设备上的功能支持矩阵，以及相应的降级策略，确保在不同平台环境下都能提供优良的用户体验。

## 平台支持策略

### 最低支持版本
- **最低 iOS 版本**: iOS 16.0+（商业覆盖优先）
- **目标 iOS 版本**: iOS 18.0+（完整功能体验）
- **未来 iOS 版本**: iOS 26.0+（最新特性）

### 设备支持范围
- **iPhone**: iPhone 8 及以上（iOS 16.0+ 支持的所有设备）
- **iPad**: iPad Air 2 及以上，iPad mini 4 及以上
- **基准测试设备**: iPhone 12, iPhone SE (2022), 当前旗舰机型

## 功能支持矩阵

### 核心功能（Must Have）

| 功能 | iOS 16.0+ | iOS 17.0+ | iOS 18.0+ | iOS 26.0+ | 降级策略 |
|------|-----------|-----------|-----------|-----------|----------|
| 拍照录入 | ✅ 基础相机 | ✅ 同左 | ✅ 增强相机 | ✅ 同左 | 系统相机调用 |
| OCR 识别 | ✅ Vision 基础 | ✅ Vision 优化 | ✅ Vision 高级 | ✅ Vision AI | 云端 OCR 备选 |
| 错题管理 | ✅ 完整支持 | ✅ 同左 | ✅ 同左 | ✅ 同左 | 无需降级 |
| 本地存储 | ✅ Core Data | ✅ SwiftData 基础 | ✅ SwiftData 完整 | ✅ 同左 | Core Data 兜底 |
| 基础复习 | ✅ 完整支持 | ✅ 同左 | ✅ 同左 | ✅ 同左 | 无需降级 |

### 高级功能（Should Have）

| 功能 | iOS 16.0+ | iOS 17.0+ | iOS 18.0+ | iOS 26.0+ | 降级策略 |
|------|-----------|-----------|-----------|-----------|----------|
| CloudKit 同步 | ✅ 基础同步 | ✅ 增强同步 | ✅ 完整同步 | ✅ 智能同步 | 本地存储 |
| 智能复习 | ✅ 基础算法 | ✅ 机器学习 | ✅ Core ML 优化 | ✅ Proactive Intelligence | 静态算法 |
| 通知系统 | ✅ 本地通知 | ✅ 同左 | ✅ 智能通知 | ✅ 预测性通知 | 定时通知 |
| 无障碍支持 | ✅ VoiceOver | ✅ 增强支持 | ✅ 完整支持 | ✅ 同左 | 基础支持 |

### 实验性功能（Could Have）

| 功能 | iOS 16.0+ | iOS 17.0+ | iOS 18.0+ | iOS 26.0+ | 降级策略 |
|------|-----------|-----------|-----------|-----------|----------|
| AR 录入 | ❌ 不支持 | ⚠️ 有限支持 | ✅ 基础 AR | ✅ 完整 AR | 常规录入 |
| 3D 知识图谱 | ❌ 不支持 | ❌ 不支持 | ⚠️ 基础 3D | ✅ 完整 3D | 2D 图表 |
| 空间计算 | ❌ 不支持 | ❌ 不支持 | ❌ 不支持 | ✅ visionOS | 平面界面 |
| Proactive Intelligence | ❌ 不支持 | ❌ 不支持 | ⚠️ 基础预测 | ✅ 完整预测 | 规则算法 |

## 技术实现策略

### 1. 能力检测机制

#### 1.1 iOS 版本检测
```swift
struct FeatureAvailability {
    static let swiftDataSupport = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17
    static let proactiveIntelligence = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
    static let enhancedAR = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 18
    
    static func supportsFeature(_ feature: AppFeature) -> Bool {
        switch feature {
        case .swiftData:
            return swiftDataSupport
        case .proactiveIntelligence:
            return proactiveIntelligence
        case .advancedAR:
            return enhancedAR && ARWorldTrackingConfiguration.isSupported
        }
    }
}
```

#### 1.2 设备能力检测
```swift
struct DeviceCapability {
    static let supportsARKit = ARWorldTrackingConfiguration.isSupported
    static let supportsCoreML = MLModel.available
    static let supportsNeuralEngine = isNeuralEngineAvailable()
    
    static func performanceLevel() -> PerformanceLevel {
        let deviceModel = UIDevice.current.model
        let processorInfo = ProcessInfo.processInfo
        
        // 基于设备型号和性能返回级别
        return .medium // .low, .medium, .high, .premium
    }
}
```

### 2. 条件编译策略

#### 2.1 iOS 版本条件编译
```swift
#if canImport(SwiftData)
    import SwiftData
    typealias DataStore = SwiftDataStore
#else
    import CoreData
    typealias DataStore = CoreDataStore
#endif

// 运行时条件编译
func createDataStore() -> DataStoreProtocol {
    if #available(iOS 17.0, *) {
        return SwiftDataStore()
    } else {
        return CoreDataStore()
    }
}
```

#### 2.2 功能模块条件编译
```swift
@available(iOS 18.0, *)
class ProactiveReviewManager {
    // iOS 18+ 专用的 Proactive Intelligence 实现
}

class LegacyReviewManager {
    // iOS 16+ 兼容的基础实现
}

// 工厂模式选择实现
func createReviewManager() -> ReviewManagerProtocol {
    if #available(iOS 18.0, *) {
        return ProactiveReviewManager()
    } else {
        return LegacyReviewManager()
    }
}
```

### 3. 性能优化分级

#### 3.1 基准设备性能目标

| 设备级别 | 代表设备 | 启动时间目标 | 内存限制 | 功能级别 |
|----------|----------|--------------|----------|----------|
| 入门级 | iPhone SE (2022) | P95 < 1.5s | < 50MB | 核心功能 |
| 中端 | iPhone 12 | P95 < 1.2s | < 60MB | 完整功能 |
| 高端 | iPhone 15 Pro | P95 < 1.0s | < 100MB | 增强功能 |
| 旗舰 | iPhone 15 Pro Max | P95 < 0.8s | < 150MB | 全部功能 |

#### 3.2 动态性能调整
```swift
class PerformanceManager {
    static let shared = PerformanceManager()
    
    func adjustPerformanceSettings() {
        let level = DeviceCapability.performanceLevel()
        
        switch level {
        case .low:
            OCREngine.setQuality(.fast)
            ImageProcessor.setCompression(.high)
            AnimationManager.setReducedMotion(true)
            
        case .medium:
            OCREngine.setQuality(.balanced)
            ImageProcessor.setCompression(.medium)
            
        case .high:
            OCREngine.setQuality(.accurate)
            ImageProcessor.setCompression(.low)
            ARManager.enableAdvancedFeatures(true)
            
        case .premium:
            OCREngine.setQuality(.premium)
            ImageProcessor.setCompression(.minimal)
            ARManager.enableAdvancedFeatures(true)
            ProactiveManager.enableFullPrediction(true)
        }
    }
}
```

## 降级策略详述

### 1. OCR 识别降级

#### 1.1 降级层次
1. **最优**: iOS 26+ Vision AI + 神经引擎
2. **良好**: iOS 18+ Vision 高级 + Core ML
3. **标准**: iOS 17+ Vision 优化
4. **基础**: iOS 16+ Vision 基础
5. **兜底**: 云端 OCR API

#### 1.2 实现策略
```swift
class OCRManager {
    func performOCR(on image: UIImage) async throws -> OCRResult {
        // 尝试最佳选项
        if #available(iOS 26.0, *), DeviceCapability.supportsNeuralEngine {
            return try await performAIOCR(image)
        }
        
        // 降级到 Core ML
        if #available(iOS 18.0, *), DeviceCapability.supportsCoreML {
            return try await performMLOCR(image)
        }
        
        // 降级到基础 Vision
        if #available(iOS 16.0, *) {
            return try await performVisionOCR(image)
        }
        
        // 最后兜底到云端
        return try await performCloudOCR(image)
    }
}
```

### 2. 数据存储降级

#### 2.1 SwiftData → Core Data
```swift
protocol DataStoreProtocol {
    func save(_ item: ReviewItem) async throws
    func fetch() async throws -> [ReviewItem]
    func delete(_ item: ReviewItem) async throws
}

@available(iOS 17.0, *)
class SwiftDataStore: DataStoreProtocol {
    private let modelContext: ModelContext
    // SwiftData 实现
}

class CoreDataStore: DataStoreProtocol {
    private let persistentContainer: NSPersistentContainer
    // Core Data 实现
}
```

### 3. UI 组件降级

#### 3.1 SwiftUI 新组件降级
```swift
struct ReviewCardView: View {
    var body: some View {
        if #available(iOS 17.0, *) {
            // 使用 iOS 17+ 的新组件
            ReviewCardModernView()
        } else {
            // 使用兼容组件
            ReviewCardLegacyView()
        }
    }
}
```

### 4. 通知系统降级

#### 4.1 智能通知 → 定时通知
```swift
class NotificationManager {
    func scheduleReviewReminder(for item: ReviewItem) {
        if #available(iOS 26.0, *) {
            scheduleProactiveNotification(item)
        } else if #available(iOS 18.0, *) {
            scheduleIntelligentNotification(item)
        } else {
            scheduleBasicNotification(item)
        }
    }
}
```

## 测试矩阵

### 1. 设备测试覆盖

| 设备类型 | iOS 版本 | 测试优先级 | 测试内容 |
|----------|----------|------------|----------|
| iPhone SE (2022) | iOS 16.0 | P0 | 核心功能 + 性能 |
| iPhone 12 | iOS 17.0 | P0 | 完整功能 |
| iPhone 13 | iOS 18.0 | P1 | 增强功能 |
| iPhone 15 Pro | iOS 18.0 | P1 | 全部功能 |
| iPad Air | iOS 16.0 | P2 | 适配测试 |

### 2. 功能兼容性测试

#### 2.1 自动化测试
```swift
class CompatibilityTests: XCTestCase {
    func testOCRCompatibility() {
        let image = TestImages.sampleMathProblem
        
        XCTAssertNoThrow(
            try await OCRManager().performOCR(on: image),
            "OCR should work on all supported iOS versions"
        )
    }
    
    func testDataStorageCompatibility() {
        let dataStore = DataStoreFactory.create()
        let testItem = ReviewItem.sample
        
        XCTAssertNoThrow(
            try await dataStore.save(testItem),
            "Data storage should work with current iOS version"
        )
    }
}
```

## 发布策略

### 1. 分阶段发布

#### Phase 1: 基础兼容 (iOS 16.0+)
- 核心功能完整支持
- 性能达到基准要求
- 基础降级策略验证

#### Phase 2: 增强功能 (iOS 17.0+)
- SwiftData 集成
- 增强 OCR 功能
- 改进用户体验

#### Phase 3: 智能特性 (iOS 18.0+)
- Core ML 集成
- 智能通知
- 基础 AR 功能

#### Phase 4: 未来特性 (iOS 26.0+)
- Proactive Intelligence
- 完整 AR 支持
- 空间计算集成

### 2. 质量保证

#### 2.1 兼容性质量门禁
- 所有支持的 iOS 版本都能正常启动
- 核心功能在所有版本上可用
- 性能指标在基准设备上达标
- 降级功能用户体验可接受

#### 2.2 回归测试
- 每个版本发布前进行全矩阵测试
- 重点测试版本边界和降级路径
- 用户反馈的兼容性问题优先修复

---

**实施注意事项**:
1. 优先保证低版本设备的稳定性
2. 高版本特性采用渐进增强策略
3. 定期评估支持矩阵，适时淘汰过旧版本
4. 用户升级引导和教育
5. 详细的兼容性文档和开发者指南