# NotBad 术语表 (Glossary)

> 统一语言（Ubiquitous Language）是 DDD 的核心实践。本文档定义项目中所有术语的**唯一**含义，避免歧义和沟通摩擦。

---

## 📚 核心领域术语

### ReviewItem（错题条目）

| 术语 | 中文 | 定义 | 注意 |
|------|------|------|------|
| **ReviewItem** | 错题条目 | 用户录入的一道错题，是系统的核心实体 | ❌ 不叫 Question、Problem、WrongAnswer |
| **Review** | 复习 | 对错题进行回顾学习的行为 | ❌ 不叫 Study、Learn |
| **Capture** | 采集 | 录入一道新错题的过程 | ❌ 不叫 Add、Create、Input |

### 为什么叫 ReviewItem 而不是 WrongQuestion？

1. **ReviewItem** 强调"复习"这个核心动作，而不是"错误"这个负面标签
2. 心理学上，正向命名有助于用户坚持使用
3. 未来可扩展为"好题"、"难题"等，不仅限于错题

```swift
// ✅ 正确命名
let reviewItem = ReviewItem(title: "二次函数求最值")
let items: [ReviewItem] = repository.fetchAll()

// ❌ 错误命名
let question = ReviewItem(...)    // 不叫 question
let wrongItem = ReviewItem(...)   // 不叫 wrongItem
```

---

## 🧠 学习理论术语

### 艾宾浩斯遗忘曲线（Ebbinghaus Forgetting Curve）

| 术语 | 中文 | 定义 |
|------|------|------|
| **Retention** | 记忆保持率 | 学习后某时刻仍能回忆的内容比例（0-100%） |
| **ReviewInterval** | 复习间隔 | 两次复习之间的时间间隔 |
| **Spaced Repetition** | 间隔重复 | 按递增间隔复习以强化记忆的学习方法 |
| **Overdue** | 逾期 | 超过计划复习日期仍未复习的状态 |
| **Reschedule** | 重排 | 逾期复习后，基于实际复习日期重新计算下次间隔 |
| **Urgency** | 紧迫程度 | 复习的紧急程度（1-5级） |

```swift
// 记忆保持率计算示例
let interval = ReviewInterval.calculate(reviewCount: 3, mastery: .good)
print(interval.estimatedRetention)  // 0.85 (85%记忆保持率)
print(interval.retentionDescription) // "记忆良好"
print(interval.isOverdue)           // false
print(interval.urgencyDescription)  // "本周复习"
```

### 标准复习间隔序列

| 复习次数 | 标准间隔 | 说明 |
|---------|---------|------|
| 第1次 | 1天 | 24小时后第一次复习 |
| 第2次 | 2天 | 巩固短期记忆 |
| 第3次 | 4天 | 向长期记忆转化 |
| 第4次 | 7天 | 一周后检验 |
| 第5次 | 15天 | 两周后深化 |
| 第6次 | 30天 | 一个月后巩固 |
| 第7次+ | 60-365天 | 长期维护 |

> 注：实际间隔会根据 `MasteryLevel` 动态调整，掌握越好间隔越长。

---

## 🎯 值对象术语

### 学业相关

| 代码 | 中文 | 定义 | 示例 |
|------|------|------|------|
| **Subject** | 学科 | K12 教育中的课程科目 | 语文、数学、英语、物理... |
| **SubjectCategory** | 学科分类 | 学科的大类划分 | 语言类、理科类、人文类、技术类 |
| **Grade** | 年级 | 学生所在的年级 | 一年级、七年级、高一... |
| **GradeStage** | 学段 | 年级的大类划分 | 小学、初中、高中 |

```swift
// Subject 使用示例
let subject = Subject.math
print(subject.displayName)    // "数学"
print(subject.category)       // .science (理科类)
print(subject.stages)         // [.primary, .middle, .high] 全学段开设

// Grade 使用示例
let grade = Grade.grade10
print(grade.displayName)      // "高一"
print(grade.stage)            // .high (高中)
print(grade.shortName)        // "高一"

// 判断学科是否适用于某学段
if subject.isAvailable(for: .primary) {
    print("小学开设数学课")
}
```

### 题目相关

| 代码 | 中文 | 定义 | 注意 |
|------|------|------|------|
| **ReviewItemType** | 题型 | 题目的形式分类 | ❌ 不叫 QuestionType（已废弃）|
| **ReviewItemCategory** | 题型分类 | 题型的大类划分 | 客观题、主观题、综合题 |
| **Difficulty** | 难度 | 题目的难易程度 | 送分、简单、中等、困难、压轴 |
| **Source** | 来源 | 题目的出处 | 课本、考试、作业、真题... |
| **SourceCategory** | 来源分类 | 来源的大类划分 | 官方、学校、课外、其他 |
| **KnowledgePoints** | 知识点 | 题目涉及的知识点集合 | ["函数", "不等式", "导数"] |

```swift
// KnowledgePoints（知识点）使用示例 - 不可变操作
let points = KnowledgePoints(["函数", "导数"])
let newPoints = points.adding("极限")           // 返回新 KnowledgePoints，原 points 不变
let merged = points.merging(with: ["积分"])   // 合并多个知识点

print(points.contains("函数"))   // true
print(points.count)              // 2
print(points.rawValue)           // "函数, 导数" (用于存储)

// 遍历知识点（实现了 Sequence 协议）
for point in points {
    print(point)
}

// 获取学科推荐知识点
let suggestions = KnowledgePoints.suggestions(for: .math)
// ["代数", "几何", "函数", "方程", "不等式", ...]
```

### 学习状态相关

| 代码 | 中文 | 定义 | 值域 |
|------|------|------|------|
| **MasteryLevel** | 掌握程度 | 学生对该题的掌握状态 | 不会(0) → 完全掌握(4) |
| **ErrorType** | 错误类型 | 做错的根本原因 | 概念不清、计算错误、粗心大意... |
| **ErrorCategory** | 错误分类 | 错误类型的大类划分 | 知识类、方法类、习惯类、客观类 |
| **ReviewInterval** | 复习间隔 | 基于艾宾浩斯曲线计算的下次复习时间 | - |

```swift
// MasteryLevel 使用示例
let mastery = MasteryLevel.partial
print(mastery.displayName)    // "似懂非懂"
print(mastery.stars)          // 3 (⭐⭐⭐)
print(mastery.progress)       // 0.5 (50%进度)
print(mastery.color)          // Color.yellow
print(mastery.needsReview)    // true (需要重点复习)
print(mastery.isMastered)     // false

// 可比较
if mastery < .good {
    print("需要继续加油！")
}

// Difficulty 使用示例
let difficulty = Difficulty.hard
print(difficulty.displayName)     // "困难"
print(difficulty.emoji)           // "🔥"
print(difficulty.coefficient)     // 1.5 (用于权重计算)
```

---

## 🏗️ 架构术语

### 分层架构

| 层 | 职责 | 包含内容 |
|------|------|------|
| **App** | 应用入口 | NotBadApp.swift |
| **Domain** | 领域逻辑 | Entities、ValueObjects、Protocols |
| **Data** | 数据持久化 | Repository 实现 |
| **Infrastructure** | 基础设施 | DI、OCR、Camera、Scanner |
| **Presentation** | 用户界面 | Views、ViewModels、Components |

```text
NotBad/
├── App/                        # 应用层
│   └── NotBadApp.swift
├── Domain/                     # 领域层（核心业务逻辑）
│   ├── Entities/               # 实体
│   │   └── ReviewItem.swift
│   ├── ValueObjects/           # 值对象
│   │   ├── MasteryLevel.swift
│   │   ├── Subject.swift
│   │   └── ...
│   └── Protocols/              # 协议/接口 (5个)
│       ├── ReviewItemRepositoryProtocol.swift
│       ├── ReviewItemDataProviding.swift
│       ├── OCRServiceProtocol.swift
│       ├── PDFExportServiceProtocol.swift
│       └── ImageCompressorProtocol.swift
├── Data/                       # 数据层
│   ├── Repository/
│   │   └── ReviewItemRepository.swift
│   └── Provider/
│       └── SwiftDataReviewItemProvider.swift
├── Infrastructure/             # 基础设施层
│   ├── DI/                     # 依赖注入
│   │   ├── Dependencies.swift
│   │   ├── EnvironmentKeys.swift
│   │   └── DataProviderFactory.swift
│   ├── OCR/
│   ├── Camera/
│   └── Scanner/
└── Presentation/               # 表现层
    ├── Navigation/
    ├── Common/Components/
    └── Features/
        ├── Capture/
        ├── Library/
        ├── Review/
        └── Dashboard/
```

### 设计模式

| 术语 | 中文 | 定义 |
|------|------|------|
| **Entity** | 实体 | 有唯一标识的领域对象（如 ReviewItem） |
| **Value Object** | 值对象 | 无标识、不可变的领域对象（如 Tags、MasteryLevel） |
| **Repository** | 仓储 | 数据持久化的抽象层 |
| **DataProvider** | 数据提供者 | 响应式数据访问层，支持 DI |
| **ViewModel** | 视图模型 | View 的状态和逻辑封装 |

```swift
// Entity vs Value Object 区别

// Entity（实体）- 有唯一标识，可变
@Model
final class ReviewItem {
    var id: UUID           // ✅ 有唯一标识
    var title: String      // ✅ 状态可变
    var mastery: MasteryLevel
}

// Value Object（值对象）- 无标识，不可变
struct KnowledgePoints: Equatable {
    private let items: [String]  // ✅ 不可变
    
    func adding(_ point: String) -> KnowledgePoints {  // ✅ 返回新实例
        KnowledgePoints(items + [point])
    }
}

// Repository 使用示例
protocol ReviewItemRepositoryProtocol {
    func fetchAll() throws -> [ReviewItem]
    func save(_ item: ReviewItem) throws
    func delete(_ item: ReviewItem) throws
}
```

---

## 📱 功能模块术语

| 模块 | 中文 | 功能描述 | 核心操作 |
|------|------|----------|---------|
| **Capture** | 采集 | 拍照/相册录入错题 | 拍照、裁剪、OCR识别、保存 |
| **Library** | 错题库 | 查看、搜索、管理所有错题 | 浏览、筛选、搜索、编辑、删除 |
| **Review** | 复习 | 按计划复习错题，更新掌握程度 | 查看、自评、更新掌握度 |
| **Dashboard** | 仪表盘 | 统计概览、学习数据可视化 | 查看统计、趋势分析 |
| **Profile** | 个人中心 | 用户设置、数据管理 | 设置、导出、备份 |

### 用户操作术语

| 操作 | 英文 | 定义 | 代码中使用 |
|------|------|------|----------|
| 采集 | Capture | 新录入一道错题 | `captureItem()` |
| 筛选 | Filter | 按条件缩小列表范围 | `filterItems(by:)` |
| 搜索 | Search | 按关键词查找 | `searchItems(query:)` |
| 复习 | Review | 重新学习一道错题 | `reviewItem(_:)` |
| 自评 | Self-Assess | 复习后自我评估掌握程度 | `updateMastery(_:)` |
| 归档 | Archive | 将已掌握的错题归档 | `archiveItem(_:)` |

```swift
// ViewModel 中的操作命名示例
@MainActor
@Observable
final class LibraryViewModel {
    // ✅ 动词 + 名词，清晰表达意图
    func filterItems(by subject: Subject) { ... }
    func searchItems(query: String) { ... }
    func deleteItem(_ item: ReviewItem) { ... }
    
    // ❌ 避免模糊命名
    func filter() { ... }        // filter 什么？
    func handle(_ item: ReviewItem) { ... }  // handle 是什么操作？
}
```

---

## ⚠️ 易混淆术语对照

### ❌ 禁用术语 → ✅ 正确术语

| 禁用 | 原因 | 正确术语 | 代码示例 |
|------|------|----------|----------|
| Question | 太泛化 | ReviewItem | `let reviewItem: ReviewItem` |
| QuestionType | 已重命名 | ReviewItemType | `reviewItem.reviewItemType: ReviewItemType` |
| WrongQuestion | 负面标签 | ReviewItem | - |
| Problem | 歧义（问题/难题） | ReviewItem | - |
| Error | 与 ErrorType 冲突 | ReviewItem | - |
| Level | 歧义（等级/关卡） | MasteryLevel / Difficulty | `reviewItem.mastery` / `reviewItem.difficulty` |
| Type | 歧义 | 明确前缀 | `ReviewItemType` / `ErrorType` |
| Category | 歧义 | 明确前缀 | `SubjectCategory` / `ErrorCategory` |
| Status | 歧义 | MasteryLevel | `reviewItem.mastery` |
| Score | 本项目不涉及分数 | MasteryLevel | - |

### 同义词统一

| 统一用语 | 禁用同义词 | 代码中 |
|----------|-----------|--------|
| 采集 (Capture) | 录入、添加、创建、输入 | `CaptureView`, `captureItem()` |
| 复习 (Review) | 学习、温习、回顾 | `ReviewView`, `reviewItem()` |
| 掌握 (Mastery) | 熔练、精通、会了 | `MasteryLevel`, `mastery` |
| 知识点 (KnowledgePoints) | 考点、要点、标签 | `KnowledgePoints`, `knowledgePoints` |
| 错题条目 (ReviewItem) | 错题、题目、问题 | `ReviewItem` |
| 错题库 (Library) | 题库、收藏、列表 | `LibraryView` |

---

## 🔢 枚举值命名规范

### MasteryLevel（掌握程度）

| rawValue | case | 中文 | 用户可见文本 | 颜色 | 星级 |
|----------|------|------|-------------|------|------|
| 0 | `.none` | 不会 | "完全不会" | 红色 | ⭐ |
| 1 | `.glimpse` | 一知半解 | "看答案后能懂" | 橙色 | ⭐⭐ |
| 2 | `.partial` | 似懂非懂 | "能做对但不确定" | 黄色 | ⭐⭐⭐ |
| 3 | `.good` | 基本掌握 | "能独立完成" | 薄荷 | ⭐⭐⭐⭐ |
| 4 | `.mastered` | 完全掌握 | "能举一反三" | 绿色 | ⭐⭐⭐⭐⭐ |

```swift
// MasteryLevel 完整示例
let mastery = MasteryLevel.partial

// 基础属性
mastery.rawValue        // 2
mastery.displayName     // "似懂非懂"
mastery.shortLabel      // "似懂"
mastery.detailText      // "能做对但不确定，解题思路不清晰"

// 视觉属性
mastery.stars           // 3
mastery.progress        // 0.5
mastery.color           // Color.yellow
mastery.icon            // "questionmark.circle.fill"

// 业务属性
mastery.reviewIntervalDays  // 3 (基础复习间隔)
mastery.reviewPriority      // 3 (越低越优先)
mastery.needsReview         // true
mastery.isMastered          // false

// 可比较
MasteryLevel.partial < .good  // true
```

### Difficulty（难度）

| rawValue | case | 中文 | 用户可见文本 | emoji | 系数 |
|----------|------|------|-------------|-------|------|
| 0 | `.basic` | 送分 | "送分题" | 🎁 | 0.5 |
| 1 | `.easy` | 简单 | "简单" | 🌱 | 0.75 |
| 2 | `.medium` | 中等 | "中等" | ⚡ | 1.0 |
| 3 | `.hard` | 困难 | "困难" | 🔥 | 1.5 |
| 4 | `.extreme` | 压轴 | "压轴" | 💎 | 2.0 |

### ErrorType（错误类型）

| case | 中文 | 分类 | 说明 |
|------|------|------|------|
| `.conceptUnclear` | 概念不清 | 知识类 | 基础概念理解有误 |
| `.formulaForgotten` | 公式遗忘 | 知识类 | 忘记公式或定理 |
| `.methodUnknown` | 方法不会 | 方法类 | 不知道解题方法 |
| `.logicError` | 逻辑错误 | 方法类 | 推理过程有误 |
| `.calculationError` | 计算错误 | 习惯类 | 计算过程出错 |
| `.careless` | 粗心大意 | 习惯类 | 看错、抄错、漏写 |
| `.incompleteAnswer` | 答案不全 | 习惯类 | 遗漏步骤或结论 |
| `.timeInsufficient` | 时间不足 | 客观类 | 考试时间不够 |
| `.questionMisread` | 题意理解偏差 | 客观类 | 审题不准确 |
| `.other` | 其他 | 其他 | 未分类的错误 |

### Grade（年级）

| 学段 | 年级范围 | case 示例 |
|------|---------|----------|
| 小学 | 1-6年级 | `.grade1` ~ `.grade6` |
| 初中 | 7-9年级 | `.grade7` ~ `.grade9` |
| 高中 | 10-12年级 | `.grade10` ~ `.grade12` |

```swift
// Grade 完整示例
let grade = Grade.grade10

grade.displayName   // "高一"
grade.shortName     // "高一"
grade.stage         // .high (GradeStage.high)
grade.stage.displayName  // "高中"

// 年级比较
Grade.grade7 < .grade10  // true
```

---

## 📝 命名规范

### 文件命名

```text
实体:      ReviewItem.swift
值对象:    MasteryLevel.swift, Difficulty.swift
视图:      CaptureView.swift, LibraryView.swift
视图模型:  CaptureViewModel.swift
仓储协议:  ReviewItemRepositoryProtocol.swift
仓储实现:  ReviewItemRepository.swift
组件:      MasteryBadge.swift
```

### 变量命名

```swift
// ✅ 正确 - 清晰表达类型和用途
let reviewItem: ReviewItem
let masteryLevel: MasteryLevel
let selectedSubject: Subject
let filteredItems: [ReviewItem]
let overdueCount: Int

// ❌ 错误 - 太模糊或有歧义
let item: ReviewItem      // 什么 item？
let level: MasteryLevel   // 什么 level？
let data: [ReviewItem]    // data 太泛化
let list: [ReviewItem]    // list 太泛化
```

### SwiftData 存储字段命名

由于 SwiftData 不直接支持自定义值对象类型，我们使用 `Raw` 后缀表示存储字段：

```swift
@Model
final class ReviewItem {
    // 存储字段（带 Raw 后缀）
    var subjectRaw: String          // 存储 Subject.rawValue
    var gradeRaw: String            // 存储 Grade.rawValue
    var masteryLevel: Int           // 存储 MasteryLevel.rawValue
    var knowledgePointsRaw: String  // 存储逗号分隔的知识点
    var difficultyRaw: Int          // 存储 Difficulty.rawValue
    var errorTypeRaw: String        // 存储 ErrorType.rawValue
    var sourceRaw: String           // 存储 Source.rawValue
    var reviewItemTypeRaw: String   // 存储 ReviewItemType.rawValue
    
    // 值对象访问器（计算属性）
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    
    var knowledgePoints: KnowledgePoints {
        get { KnowledgePoints(from: knowledgePointsRaw) }
        set { knowledgePointsRaw = newValue.rawValue }
    }
}
```

### 函数命名

```swift
// ✅ 动词开头，清晰表达行为
func captureItem(from image: UIImage) -> ReviewItem
func filterItems(by subject: Subject) -> [ReviewItem]
func updateMastery(_ level: MasteryLevel, for item: ReviewItem)
func calculateNextReviewDate() -> Date

// ❌ 避免
func getItem()          // get 太泛化
func process()          // 不知道处理什么
func handle(_ item: ReviewItem)  // 不知道如何处理
```

---

## 🔄 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2025-11-25 | 初始版本，定义所有核心术语 |
| 1.1 | 2025-11-25 | 添加业务术语、学习理论术语、代码示例 |
| 1.2 | 2025-11-25 | Tags 重命名为 KnowledgePoints，消除歧义 |
| 1.3 | 2025-11-27 | 添加相关文档链接，同步审计文档 |
| 1.4 | 2025-12-04 | 更新架构图，添加 DI、DataProvider 等新术语 |

---

## 📚 相关文档

| 文档 | 用途 |
|------|------|
| [项目架构](./PROJECT_STRUCTURE.md) | 了解项目结构和分层 |
| [编码规范](./CODING_STANDARDS.md) | Swift 6 / 值对象 / 错误处理规范 |
| [发布清单](../RELEASE_CHECKLIST.md) | 发布检查 (含 App Store 审核) |

---

## 📋 如何使用本文档

1. **新成员入职**：必读文档，理解项目术语
2. **代码评审**：检查命名是否符合术语表
3. **需求讨论**：使用统一术语沟通
4. **文档编写**：引用术语表中的定义

### 快速参考卡片

```text
┌─────────────────────────────────────────────────────┐
│  NotBad 核心术语速查                                  │
├─────────────────────────────────────────────────────┤
│  错题条目  →  ReviewItem (不叫 Question/Problem)      │
│  采集      →  Capture (不叫 Add/Create)              │
│  复习      →  Review (不叫 Study/Learn)              │
│  掌握程度  →  MasteryLevel (5级: none→mastered)      │
│  知识点    →  KnowledgePoints (不叫 Tags/标签)       │
│  题型      →  ReviewItemType (不叫 QuestionType)     │
│  错题库    →  Library (不叫题库/收藏)                 │
└─────────────────────────────────────────────────────┘
```

> 💡 **原则**：如果你不确定某个术语的含义，先查本文档；如果文档没有，提出来一起讨论并补充。
