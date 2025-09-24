# 协调器模式实现报告

## 概述

本报告记录了 NotBad 应用中实现协调器模式的完整过程，成功实现了导航逻辑的解耦。

## 实现的组件

### 1. 核心协调器架构

#### Coordinator 协议 (`Presentation/Coordinators/Coordinator.swift`)

```swift
@MainActor
protocol Coordinator: ObservableObject {
    var id: UUID { get }
    func start()
    func coordinate(to route: Route)
    func goBack()
    func cleanup()
    func removeChild(_ coordinator: any Coordinator)
}
```

#### BaseCoordinator 基类

- 提供子协调器管理
- 实现父子协调器关系
- 提供默认的导航逻辑

#### Route 枚举

定义了所有可能的导航路径：

- 标签页路由：`.home`, `.capture`, `.library`, `.discovery`, `.profile`
- 详情页路由：每个标签页对应的详情路由
- 通用路由：`.alert`, `.loading`, `.error`

### 2. 主协调器 (MainCoordinator)

**职责：**

- 管理 TabView 的标签切换
- 创建和管理各个标签页的子协调器
- 处理跨标签页的导航逻辑

**核心功能：**

```swift
func getTabCoordinator(at index: Int) -> (any Coordinator)?
func switchToTab(_ tab: TabType)
```

### 3. 标签页协调器

每个标签页都有独立的协调器：

#### HomeCoordinator

- 管理首页内的导航
- 支持详情页跳转和统计页面

#### CaptureCoordinator

- 管理拍照流程
- 处理相机/相册选择
- 控制 OCR 结果页面跳转

#### LibraryCoordinator

- 管理题库浏览
- 处理题目详情和分类筛选
- 支持练习模式

#### DiscoveryCoordinator

- 管理发现页功能
- 处理社区详情和用户资料页面

#### ProfileCoordinator

- 管理个人中心
- 处理设置和帮助页面

### 4. 视图层改造

#### MainTabView

- 移除了强制解包，改用安全的可选绑定
- 通过协调器获取各标签页的视图
- 支持动态标签内容

#### 各个标签页视图

- 移除了直接的 NavigationView 依赖
- 通过协调器参数接收导航能力
- 使用 NavigationStack 替代已弃用的 NavigationView

### 5. 应用入口点 (NotBadApp.swift)

```swift
@StateObject private var mainCoordinator = MainCoordinator()

var body: some Scene {
    WindowGroup {
        MainTabView(coordinator: mainCoordinator)
            .onAppear {
                mainCoordinator.start()
            }
    }
}
```

## 解耦成果

### 前后对比

**重构前：**

- 视图直接包含 NavigationView
- 导航逻辑分散在各个视图中
- 视图间紧耦合，难以测试
- 导航状态管理混乱

**重构后：**

- 协调器统一管理导航逻辑
- 视图只负责 UI 展示
- 清晰的职责分离
- 易于测试和维护

### 架构优势

1. **单一职责：** 视图专注 UI，协调器专注导航
2. **可测试性：** 协调器可以独立测试导航逻辑
3. **可维护性：** 导航逻辑集中管理，易于修改
4. **可扩展性：** 新增导航功能只需扩展协调器
5. **解耦合：** 视图间通过协调器通信，降低耦合度

## 技术细节

### 线程安全

- 所有协调器标注 `@MainActor` 确保主线程执行
- `@Published` 属性自动在主线程更新 UI

### 内存管理

- 使用弱引用避免循环引用
- 协调器生命周期管理清晰

### SwiftUI 集成

- 使用 `NavigationStack` 替代过时的 `NavigationView`
- 支持 SwiftUI 的声明式导航

## 构建验证

- ✅ 编译成功无错误
- ✅ 架构完整性验证
- ✅ 协调器正确初始化
- ✅ 视图层安全绑定

## 总结

协调器模式的实现成功地解耦了 NotBad 应用的导航架构，提高了代码的可维护性、可测试性和可扩展性。重构后的代码结构更加清晰，职责分离明确，为后续功能开发奠定了良好的架构基础。

---

**实施日期：** 2025年9月21日
**实施者：** GitHub Copilot
**状态：** ✅ 完成并验证
