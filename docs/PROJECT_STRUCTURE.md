# NotBad 项目架构文档

> 最后更新: 2025年12月2日  
> 版本: 1.1  
> 分支: minimal

## 📊 项目概览

| 指标 | 数值 |
|------|------|
| 总代码行数 | ~22,000 行 |
| Swift 文件数 | 89 个 |
| 测试文件数 | 15 个 |
| 测试用例数 | 365+ |
| 最低系统 | iOS 26.0+ (已确定，详见 README.md) |
| 技术栈 | Swift 6.2.1 / SwiftUI / SwiftData |

---

## 📁 完整目录结构

```
NotBad/
├── 📄 文档文件
│   ├── README.md                          # 项目说明
│   ├── CONTRIBUTING.md                    # 贡献指南
│   ├── RELEASE_CHECKLIST.md               # 发布检查清单
│   └── docs/
│       ├── PROJECT_STRUCTURE.md           # 本文件
│       ├── CODING_STANDARDS.md            # 编码规范与工程手册
│       └── GLOSSARY.md                    # 术语表
│
├── 📄 测试计划
│   ├── UnitTestPlan.xctestplan            # 单元测试计划
│   ├── IntegrationTestPlan.xctestplan     # 集成测试计划
│   ├── UITestPlan.xctestplan              # UI 测试计划
│   └── PerformanceTestPlan.xctestplan     # 性能测试计划
│
├── 📁 NotBad/                             # 主应用 Target
│   ├── Info.plist                         # 应用配置
│   ├── NotBad.entitlements                # 权限配置
│   │
│   ├── 📁 App/                            # 应用入口
│   │   └── NotBadApp.swift                # @main 入口点
│   │
│   ├── 📁 Assets.xcassets/                # 资源文件
│   │   ├── Contents.json
│   │   ├── AccentColor.colorset/          # 主题色
│   │   ├── AppIcon.appiconset/            # 应用图标
│   │   └── Colors/                        # 品牌色系
│   │       ├── BrandPrimary.colorset/     # 主色 (橙色)
│   │       ├── BrandSecondary.colorset/   # 次色 (蓝色)
│   │       ├── BrandSuccess.colorset/     # 成功色 (绿色)
│   │       ├── BrandWarning.colorset/     # 警告色 (黄色)
│   │       └── BrandError.colorset/       # 错误色 (红色)
│   │
│   ├── 📁 Domain/                         # 领域层
│   │   ├── Notification+Names.swift       # 通知名称定义
│   │   │
│   │   ├── 📁 Education/                  # 多国教育体系支持 (8个)
│   │   │   ├── EducationSystem.swift      # 教育体系协议
│   │   │   ├── EducationSystemManager.swift # 教育体系管理器
│   │   │   ├── ChinaEducationSystem.swift # 中国教育体系
│   │   │   ├── USEducationSystem.swift    # 美国教育体系
│   │   │   ├── JapanEducationSystem.swift # 日本教育体系
│   │   │   ├── KoreaEducationSystem.swift # 韩国教育体系
│   │   │   ├── SingaporeEducationSystem.swift # 新加坡教育体系
│   │   │   └── InternationalEducationSystem.swift # 国际教育体系
│   │   │
│   │   ├── 📁 Entities/                   # 实体
│   │   │   ├── ReviewItem.swift           # 核心实体 (@Model)
│   │   │   ├── ReviewItem+Accessors.swift # 值对象访问器
│   │   │   ├── ReviewItem+Actions.swift   # 行为方法
│   │   │   ├── ReviewItem+Computed.swift  # 计算属性
│   │   │   └── ReviewItem+Display.swift   # 显示属性
│   │   │
│   │   ├── 📁 Protocols/                  # 协议
│   │   │   └── ReviewItemRepositoryProtocol.swift
│   │   │
│   │   └── 📁 ValueObjects/               # 值对象 (13个)
│   │       ├── Difficulty.swift           # 难度等级
│   │       ├── ErrorType.swift            # 错误类型
│   │       ├── ErrorCategory.swift        # 错误分类
│   │       ├── Grade.swift                # 年级
│   │       ├── GradeStage.swift           # 学段 (小学/初中/高中)
│   │       ├── KnowledgePoints.swift      # 知识点集合
│   │       ├── MasteryLevel.swift         # 掌握程度
│   │       ├── ReviewInterval.swift       # 复习间隔
│   │       ├── ReviewItemType.swift       # 题目类型
│   │       ├── ReviewItemCategory.swift   # 题型分类
│   │       ├── Source.swift               # 题目来源
│   │       ├── SourceCategory.swift       # 来源分类
│   │       └── Subject.swift              # 学科
│   │
│   ├── 📁 Data/                           # 数据层
│   │   ├── ReviewItemMigrationPlan.swift  # 数据迁移计划
│   │   └── 📁 Repository/
│   │       └── ReviewItemRepository.swift # 数据仓库实现
│   │
│   ├── 📁 Infrastructure/                 # 基础设施层
│   │   ├── 📁 Camera/
│   │   │   └── ImagePicker.swift          # 相机/相册选择器
│   │   │
│   │   ├── 📁 Localization/
│   │   │   └── LocalizationKeys.swift     # 本地化字符串键
│   │   │
│   │   ├── 📁 OCR/
│   │   │   └── OCRService.swift           # OCR 识别服务
│   │   │
│   │   ├── 📁 Scanner/                    # 扫描器 (3个)
│   │   │   ├── LiveTextScannerView.swift  # 实时文本扫描视图
│   │   │   ├── LiveTextScannerContainer.swift # 扫描器容器
│   │   │   └── ScannerConfiguration.swift # 扫描器配置
│   │   │
│   │   ├── 📁 Utils/
│   │   │   └── ImageCompressor.swift      # 图片压缩工具
│   │   │
│   │   └── 📁 Widget/
│   │       └── WidgetDataSync.swift       # Widget 数据同步
│   │
│   └── 📁 Presentation/                   # 表现层
│       ├── 📁 Navigation/
│       │   └── MainTabView.swift          # 主 Tab 导航
│       │
│       ├── 📁 Common/                     # 通用组件
│       │   ├── 📁 Components/             # UI 组件 (7个)
│       │   │   ├── EmptyStateView.swift   # 空状态视图
│       │   │   ├── FlowLayout.swift       # 流式布局
│       │   │   ├── InfoCard.swift         # 信息卡片
│       │   │   ├── LoadingView.swift      # 加载视图
│       │   │   ├── MasteryBadge.swift     # 掌握度徽章
│       │   │   ├── SubjectTag.swift       # 学科标签
│       │   │   └── ToastView.swift        # Toast 提示
│       │   │
│       │   ├── 📁 Layout/
│       │   │   └── AdaptiveLayout.swift   # iPad 自适应布局
│       │   │
│       │   ├── 📁 Styles/                 # 样式定义 (4个)
│       │   │   ├── Accessibility.swift    # 无障碍支持
│       │   │   ├── ButtonStyles.swift     # 按钮样式
│       │   │   ├── CardStyles.swift       # 卡片样式
│       │   │   └── Theme.swift            # 主题/设计令牌
│       │   │
│       │   └── 📁 Views/
│       │       └── LaunchScreenView.swift # 启动页面
│       │
│       └── 📁 Features/                   # 功能模块 (6个)
│           ├── 📁 Dashboard/              # 首页模块 (4个)
│           │   ├── DashboardView.swift
│           │   ├── DashboardViewModel.swift
│           │   ├── DashboardModels.swift  # 数据模型
│           │   └── 📁 Components/
│           │       ├── DashboardCharts.swift
│           │       └── DashboardComponents.swift
│           │
│           ├── 📁 Library/                # 题库模块 (7个)
│           │   ├── LibraryView.swift
│           │   ├── LibraryViewModel.swift
│           │   ├── ItemDetailView.swift
│           │   ├── AdvancedSearchView.swift
│           │   ├── AdvancedSearchModels.swift # 搜索数据模型
│           │   ├── AdvancedSearchComponents.swift # 搜索组件
│           │   └── 📁 Components/
│           │       └── ItemDetailComponents.swift
│           │
│           ├── 📁 Capture/                # 录入模块 (7个)
│           │   ├── CaptureView.swift
│           │   ├── CaptureView+Sections.swift  # 表单分区
│           │   ├── CaptureViewModel.swift
│           │   ├── CaptureViewModel+Image.swift # 图片处理
│           │   ├── CaptureViewModel+OCR.swift   # OCR 处理
│           │   ├── CaptureViewModel+Save.swift  # 保存逻辑
│           │   └── 📁 Components/
│           │       └── ImageSelectionCard.swift # 图片选择卡片
│           │
│           ├── 📁 Review/                 # 复习模块 (5个)
│           │   ├── ReviewView.swift
│           │   ├── ReviewViewModel.swift
│           │   ├── ReviewModels.swift     # 复习数据模型
│           │   └── 📁 Components/
│           │       ├── EmptyReviewState.swift
│           │       ├── ReviewCard.swift
│           │       └── ReviewComponents.swift
│           │
│           ├── 📁 Onboarding/             # 新手引导模块 (3个)
│           │   ├── OnboardingView.swift   # 引导主视图
│           │   ├── OnboardingModels.swift # 引导数据模型
│           │   └── OnboardingComponents.swift # 引导组件
│           │
│           └── 📁 Profile/                # 个人中心模块 (8个)
│               ├── ProfileView.swift
│               └── 📁 Views/              # 子页面
│                   ├── AppearanceSettingsView.swift
│                   ├── DataManagementView.swift
│                   ├── DataManagementView+Export.swift # 导出功能
│                   ├── DataManagementView+Import.swift # 导入功能
│                   ├── FeedbackView.swift
│                   ├── HelpCenterView.swift
│                   └── NotificationSettingsView.swift
│
├── 📁 NotBadWidget/                       # Widget Target
│   ├── Info.plist
│   ├── NotBadWidget.swift                 # Widget 实现
│   └── NotBadWidgetBundle.swift           # Widget Bundle
│
├── 📁 NotBadTests/                        # 单元测试 Target
│   ├── 📁 Entities/
│   │   └── ReviewItemTests.swift
│   │
│   ├── 📁 Repository/
│   │   └── ReviewItemRepositoryTests.swift
│   │
│   ├── 📁 ValueObjects/                   # 值对象测试 (9个)
│   │   ├── DifficultyTests.swift
│   │   ├── ErrorTypeTests.swift
│   │   ├── GradeTests.swift
│   │   ├── KnowledgePointsTests.swift
│   │   ├── MasteryLevelTests.swift
│   │   ├── ReviewIntervalTests.swift
│   │   ├── ReviewItemTypeTests.swift
│   │   ├── SourceTests.swift
│   │   └── SubjectTests.swift
│   │
│   └── 📁 ViewModels/                     # ViewModel 测试 (4个)
│       ├── CaptureViewModelTests.swift
│       ├── DashboardViewModelTests.swift
│       ├── LibraryViewModelTests.swift
│       └── ReviewViewModelTests.swift
│
└── 📁 NotBad.xcodeproj/                   # Xcode 项目文件
```

---

## 🏗️ 架构分层说明

### 1. Domain Layer (领域层)
核心业务逻辑，不依赖任何外部框架。

| 组件 | 文件 | 职责 |
|------|------|------|
| **ReviewItem** | `ReviewItem.swift` + 4个扩展 | 核心实体，SwiftData @Model |
| **Value Objects** | 13个文件 | 不可变业务概念封装 |
| **Education** | 8个文件 | 多国教育体系配置 |
| **Protocols** | `ReviewItemRepositoryProtocol.swift` | 仓库抽象接口 |
| **Notifications** | `Notification+Names.swift` | 应用内通知定义 |

### 2. Data Layer (数据层)
数据持久化和访问。

| 组件 | 文件 | 职责 |
|------|------|------|
| **Repository** | `ReviewItemRepository.swift` | SwiftData 操作封装 |
| **Migration** | `ReviewItemMigrationPlan.swift` | 数据库版本迁移 |

### 3. Infrastructure Layer (基础设施层)
系统服务和工具。

| 组件 | 文件 | 职责 |
|------|------|------|
| **Camera** | `ImagePicker.swift` | UIKit 相机/相册桥接 |
| **OCR** | `OCRService.swift` | Vision 框架 OCR |
| **Scanner** | 3个文件 | VisionKit 实时扫描 |
| **Utils** | `ImageCompressor.swift` | 图片压缩处理 |
| **Widget** | `WidgetDataSync.swift` | App Group 数据同步 |
| **Localization** | `LocalizationKeys.swift` | 本地化字符串管理 |

### 4. Presentation Layer (表现层)
SwiftUI 视图和 ViewModel。

#### 4.1 通用组件 (Common)

| 类别 | 组件 | 职责 |
|------|------|------|
| **Components** | EmptyStateView, FlowLayout, InfoCard, LoadingView, MasteryBadge, SubjectTag, ToastView | 可复用 UI 组件 |
| **Layout** | AdaptiveLayout | iPad/iPhone 自适应 |
| **Styles** | Theme, ButtonStyles, CardStyles, Accessibility | 设计系统 |
| **Views** | LaunchScreenView | 启动页面 |

#### 4.2 功能模块 (Features)

| 模块 | View | ViewModel | Components |
|------|------|-----------|------------|
| **Dashboard** | DashboardView | DashboardViewModel | DashboardCharts, DashboardComponents, DashboardModels |
| **Library** | LibraryView, ItemDetailView, AdvancedSearchView | LibraryViewModel | ItemDetailComponents, AdvancedSearchModels, AdvancedSearchComponents |
| **Capture** | CaptureView (+Sections) | CaptureViewModel (+Image, +OCR, +Save) | ImageSelectionCard |
| **Review** | ReviewView | ReviewViewModel | EmptyReviewState, ReviewCard, ReviewComponents, ReviewModels |
| **Onboarding** | OnboardingView | - | OnboardingModels, OnboardingComponents |
| **Profile** | ProfileView | - | 8个子视图 (含导入导出扩展) |

---

## 🎨 设计系统

### 设计令牌 (Design Tokens)

```swift
// 间距系统 (与 Theme.swift 保持一致)
DesignTokens.Spacing.xs   // 4pt
DesignTokens.Spacing.sm   // 8pt
DesignTokens.Spacing.md   // 12pt
DesignTokens.Spacing.lg   // 16pt
DesignTokens.Spacing.xl   // 24pt
DesignTokens.Spacing.xxl  // 32pt

// 圆角系统
DesignTokens.CornerRadius.sm      // 6pt
DesignTokens.CornerRadius.md      // 12pt
DesignTokens.CornerRadius.lg      // 16pt
DesignTokens.CornerRadius.xl      // 24pt
DesignTokens.CornerRadius.full    // .infinity

// 动画系统
DesignTokens.Animation.fast       // 0.15s
DesignTokens.Animation.standard   // 0.25s
DesignTokens.Animation.slow       // 0.4s
DesignTokens.Animation.spring     // spring response 0.35
```

### 品牌色系 (Brand Colors)

```swift
Color.brand.primary     // 橙色 #FF9500
Color.brand.secondary   // 蓝色 #007AFF
Color.brand.success     // 绿色 #34C759
Color.brand.warning     // 黄色 #FFCC00
Color.brand.error       // 红色 #FF3B30
```

### 按钮样式

```swift
.buttonStyle(.primaryAction)     // 主操作按钮
.buttonStyle(.secondaryAction)   // 次操作按钮
.buttonStyle(.destructiveAction) // 危险操作按钮
```

### 卡片样式

```swift
.cardStyle(.standard)   // 标准卡片
.cardStyle(.elevated)   // 悬浮卡片
.cardStyle(.outlined)   // 描边卡片
```

---

## 🧪 测试覆盖

### 测试文件清单

| 类别 | 测试文件 | 覆盖范围 |
|------|----------|----------|
| **Entities** | ReviewItemTests | 实体创建、属性、方法 |
| **Repository** | ReviewItemRepositoryTests | CRUD 操作 |
| **Value Objects** | 9个测试文件 | 所有值对象 |
| **ViewModels** | 4个测试文件 | 所有 ViewModel |

### 测试统计

- 总测试用例: **365+**
- 值对象测试: **100%** 覆盖
- ViewModel 测试: **100%** 覆盖
- 实体测试: **100%** 覆盖

---

## 📱 功能模块详情

### Dashboard (首页)
- 数据统计卡片 (总数/待复习/掌握率/今日复习)
- 复习进度环形图
- 学科分布饼图
- 最近添加列表
- 快速操作入口

### Library (题库)
- 错题列表展示
- 学科快速筛选
- 关键词搜索
- 高级搜索 (多条件组合)
- 排序选项 (8种)
- 滑动删除
- 详情页查看/编辑

### Capture (录入)
- 相机拍照
- 相册选择
- 实时文本扫描
- OCR 文字识别
- 信息编辑表单
- 保存确认

### Review (复习)
- 智能复习算法 (艾宾浩斯)
- 卡片式复习界面
- 掌握程度评估
- 复习统计
- 空状态提示

### Profile (个人中心)
- 用户统计信息
- 通知设置
- 数据管理 (导出/导入/清除)
- 外观设置
- 帮助中心
- 意见反馈

---

## 🔧 技术特性

### Swift 6 并发
- 所有 ViewModel 使用 `@MainActor`
- `@Observable` 宏替代 ObservableObject
- `Sendable` 协议遵循
- `nonisolated` 计算属性

### SwiftData
- `@Model` 实体定义
- `@Query` 数据查询
- `ModelContainer` 配置
- `SchemaMigrationPlan` 迁移

### SwiftUI
- iOS 26 新特性
- `@Environment` 环境值
- 自定义 ViewModifier
- 动画和过渡效果

### 无障碍支持
- VoiceOver 标签
- 动态字体
- 减少动画适配
- 高对比度支持

---

## 📝 待办事项

### 即将发布前需完成
- [ ] 配置 App Group (Widget 数据共享)
- [ ] 添加 Widget Target 到 Xcode 项目
- [ ] 真机测试所有功能
- [ ] 性能优化 (大数据量)

### 后续版本规划
- [ ] iCloud 同步
- [ ] Apple Watch 应用
- [ ] Siri 快捷指令
- [ ] AI 智能分析

---

## 📚 相关文档

- [编码规范与工程手册](./CODING_STANDARDS.md) - 包含 Swift 6、值对象、错误处理、日志规范
- [术语表](./GLOSSARY.md) - 统一语言定义
- [发布检查清单](../RELEASE_CHECKLIST.md) - 含 App Store 审核清单
- [贡献指南](../CONTRIBUTING.md)

---

*文档更新时间: 2025年12月2日*
