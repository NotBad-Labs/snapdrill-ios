# Views

SwiftUI 视图层设计指南。

## Overview

视图层采用 SwiftData 原生驱动，直接使用 `@Query` 获取数据。

## 视图结构

```
Views/
├── ContentView.swift          # TabView 主容器
├── Dashboard/
│   └── DashboardView.swift    # 首页仪表盘
├── Library/
│   ├── LibraryView.swift      # 题库列表
│   └── ItemRow.swift          # 列表行组件
├── Capture/
│   └── CaptureView.swift      # 错题录入
├── Review/
│   └── ReviewView.swift       # 复习模式
└── Settings/
    └── SettingsView.swift     # 设置页面
```

## 状态管理

### @Query - 数据读取

```swift
@Query(sort: \ReviewItemModel.createdAt, order: .reverse)
private var items: [ReviewItemModel]
```

### @State - 视图私有状态

```swift
@State private var isLoading = false
@State private var showImagePicker = false
```

### @Bindable - 模型编辑

```swift
@Bindable var item: ReviewItemModel
```

### @Environment - 环境依赖

```swift
@Environment(\.modelContext) private var modelContext
```

## 最佳实践

### 1. 视图职责单一

每个视图只做一件事，超过 200 行考虑拆分。

### 2. 提取子视图

```swift
var body: some View {
    List(items) { item in
        ItemRow(item: item)  // 独立组件
    }
}
```

### 3. 无障碍支持

```swift
Button(action: scan) {
    Image(systemName: "camera")
}
.accessibilityLabel("扫描题目")
.accessibilityHint("双击打开相机")
```

### 4. 空状态处理

```swift
if items.isEmpty {
    ContentUnavailableView(
        "还没有错题",
        systemImage: "tray",
        description: Text("点击录入添加第一道错题")
    )
}
```

## See Also

- <doc:Architecture>
