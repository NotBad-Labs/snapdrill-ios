# ADR-006: 实用主义架构（废弃 Clean Architecture）

## 状态
**已采纳** — 废弃 ADR-001、ADR-003、ADR-005

## 日期
2025年12月6日

## 上下文

项目最初采用 Clean Architecture（见 ADR-001），包含：
- 4 层物理分离：Domain / Application / Data / Presentation
- Use Cases 模式（见 ADR-003）
- DI Factory（见 ADR-005）
- Entity ↔ Mapper ↔ Model 转换

### 实践中发现的问题

1. **过度抽象**：100+ Swift 文件，~28,000 行代码，但核心功能只需 1/3
2. **SwiftData 不兼容**：SwiftData 的 `@Model` 本身就是持久化+领域实体，强制分离导致大量 Mapper 代码
3. **内存问题**：图片存 SwiftData（即使用 `.externalStorage`）导致列表滚动内存暴涨
4. **Apple 工程师建议**：参考 WWDC SwiftData 示例项目，均采用 `@Model` + `@Query` 直连 View

### 触发因素

苹果工程师的实用主义建议：
> "SwiftData is designed to work directly with SwiftUI. Don't fight the framework."

## 决策

采用 **实用主义架构**：

```
┌─────────────────────────────────────────┐
│              Views (SwiftUI)            │
│  @Query 自动刷新 │ @Bindable 直接修改    │
├─────────────────────────────────────────┤
│          Models (@Model 充血模型)        │
│   数据定义 + 业务属性 + 状态变更方法      │
├─────────────────────────────────────────┤
│            Services (纯 Swift)          │
│  核心算法 | 文件操作 | AI/OCR 服务       │
└─────────────────────────────────────────┘
```

### 核心原则

1. **模型即领域**：`@Model` 就是领域实体，无需 Mapper
2. **查询即驱动**：UI 由 `@Query` 驱动，非 ViewModel 的 `@Published`
3. **服务即逻辑**：复杂算法抽取到 Service，保持可测试性
4. **图片存磁盘**：FileManager 存图片，数据库只存路径

### 目录结构

```
NotBad/
├── App/NotBadApp.swift           # 入口 + Tab 导航
├── Models/
│   ├── ReviewItemModel.swift     # 充血模型
│   ├── ValueObjects.swift        # Subject、Grade 等枚举
│   └── AppError.swift            # 统一错误类型
├── Services/
│   ├── ImageStorageService.swift # FileManager 图片存储
│   └── ReviewScheduler.swift     # 复习算法（纯函数）
├── Views/                        # SwiftUI 视图
├── Infrastructure/               # OCR、AI 等外部服务
└── Data/
    └── ReviewItemMigrationPlan.swift # 迁移计划
```

## 废弃的模式

| 废弃 | 替代 |
|------|------|
| `Domain/Entities/ReviewItem.swift` (贫血) | `Models/ReviewItemModel.swift` (充血) |
| `Domain/ValueObjects/*.swift` (20+ 文件) | `Models/ValueObjects.swift` (1 文件) |
| `Application/UseCases/*.swift` | 直接在 View/Service 中实现 |
| `Data/Mappers/*.swift` | 删除，无需转换 |
| `Data/Repository/*.swift` | `modelContext` 直接操作 |
| `Infrastructure/DI/*.swift` | 删除，使用 `@Environment` 或单例 |
| `Presentation/ViewModels/*.swift` | `@Query` + `@State` 替代 |

## 选项考虑

### 选项 A: 保持 Clean Architecture，修复问题
- ❌ 修复成本高，仍与 SwiftData 理念冲突
- ❌ 维护负担重

### 选项 B: 实用主义架构（采纳）
- ✅ 代码量减少 45%（100+ → 55 文件）
- ✅ 与 SwiftData/SwiftUI 原生理念一致
- ✅ 内存问题彻底解决（图片存磁盘）
- ✅ 开发效率大幅提升
- ⚠️ 需要更新文档和团队培训

### 选项 C: 迁移到 TCA
- ❌ 学习成本高
- ❌ 与 SwiftData 集成复杂

## 后果

### 正面
1. **代码精简**：28,000 行 → ~12,000 行
2. **内存安全**：图片不再进入 SwiftData
3. **开发效率**：新功能直接 `@Query` + View
4. **符合 Apple 范式**：与 WWDC 示例一致

### 负面
1. **文档需更新**：Code Review 指南、ADR
2. **测试需调整**：Mock 策略变化
3. **过渡期**：旧代码需逐步迁移

## 迁移计划

1. ✅ 创建 `ImageStorageService`（FileManager 存储）
2. ✅ 创建充血 `ReviewItemModel`（imagePath 替代 imageData）
3. ✅ 删除 Domain/Application/Data 旧代码
4. ✅ 更新 Code Review 指南
5. ⏳ 重建 Views（使用 @Query）
6. ⏳ 更新测试策略

## 参考

- [WWDC23: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [WWDC24: What's new in SwiftData](https://developer.apple.com/videos/play/wwdc2024/10137/)
- [Apple Sample: Backyard Birds](https://developer.apple.com/documentation/swiftui/backyard-birds-sample)
