# ReviewKit

NotBad 的核心复习算法库，完全独立于 UI。

## 特性

- ✅ **纯 Swift** - 无 UIKit/SwiftUI 依赖
- ✅ **跨平台** - iOS, macOS, watchOS, CLI 均可使用
- ✅ **Sendable** - Swift 6 并发安全
- ✅ **可配置** - 支持自定义间隔和倍率

## 使用方法

```swift
import ReviewKit

// 创建调度器
let scheduler = ReviewScheduler()

// 计算下次复习日期
let nextDate = scheduler.calculateNextReviewDate(
    performance: .good,
    reviewCount: 3
)

// 或者使用掌握程度 (0-3)
let nextDate2 = scheduler.calculateNextReviewDate(
    currentMastery: 2,
    reviewCount: 3
)

// 只获取间隔天数
let days = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 3)
```

## 集成到 NotBad 主工程

### 方法 1: 本地 Package（推荐）

1. 打开 `NotBad.xcodeproj`
2. File → Add Package Dependencies
3. 点击 "Add Local..."
4. 选择 `Packages/ReviewKit` 目录
5. 添加到 NotBad target

### 方法 2: 直接添加到工程

将 ReviewKit 拖入 Xcode 左侧 Project Navigator 中的 NotBad 工程。

## CLI 验证

```bash
cd Packages/ReviewKit
swift run ReviewKitCLI
```

如果输出复习日程表，说明核心算法完全独立于 UI。

## 测试

```bash
cd Packages/ReviewKit
swift test
```

## 架构意义

ReviewKit 代表了"物理隔离"架构理念：

| 对比 | 文件夹分层 | Package 隔离 |
|------|-----------|-------------|
| 约束 | 靠自律 | 靠编译器 |
| 违反代价 | 代码审查被说一句 | **编译不过** |
| 复用性 | 需要手动复制 | `import ReviewKit` |

## 未来扩展

- [ ] 添加 SM-2 算法
- [ ] 支持自定义复习策略
- [ ] 添加复习统计分析
