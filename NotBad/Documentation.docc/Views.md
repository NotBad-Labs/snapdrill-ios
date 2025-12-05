# Views

NotBad 的 SwiftUI 视图设计。

## Overview

NotBad 使用 SwiftUI 构建所有 UI，遵循组件化和可复用原则。

## 视图层级

```
App
├── DashboardView          # 首页仪表盘
│   ├── StatisticsCard
│   └── QuickActions
├── LibraryView            # 错题库
│   ├── ReviewItemList
│   └── ReviewItemRow
├── ReviewView             # 复习流程
│   ├── ReviewCard
│   └── ReviewProgress
└── SettingsView           # 设置
```

## 视图设计原则

### 1. 小而专注

每个视图只负责一个功能：

```swift
// ✅ 好：小而专注
struct ReviewItemRow: View {
    let item: ReviewItem
    
    var body: some View {
        HStack {
            Text(item.question)
            Spacer()
            MasteryBadge(level: item.masteryLevel)
        }
    }
}
```

### 2. 使用 ViewModel

复杂视图使用 ViewModel 管理状态：

```swift
struct ReviewListView: View {
    @State private var viewModel: ReviewListViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            ReviewItemRow(item: item)
        }
    }
}
```

### 3. 组件复用

提取可复用组件：

```swift
// 可复用的掌握度徽章
struct MasteryBadge: View {
    let level: MasteryLevel
    
    var body: some View {
        Text(level.displayName)
            .padding(.horizontal, 8)
            .background(level.color)
            .clipShape(Capsule())
    }
}
```

## 常用组件

### MasteryBadge

显示掌握度级别：

```swift
MasteryBadge(level: .good)
```

### ReviewItemCard

错题卡片展示：

```swift
ReviewItemCard(item: reviewItem) {
    // 点击操作
}
```

### StatisticsChart

统计图表：

```swift
StatisticsChart(data: statistics)
```

## 响应式设计

### 适配不同屏幕

```swift
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if sizeClass == .regular {
            // iPad 布局
            HStack { ... }
        } else {
            // iPhone 布局
            VStack { ... }
        }
    }
}
```

### 动态字体

```swift
Text("标题")
    .font(.headline)  // 自动适配用户偏好
```

## See Also

- <doc:ViewModels>
- <doc:Architecture>
