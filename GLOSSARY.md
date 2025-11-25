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

---

## 🎯 值对象术语

### 学业相关

| 代码 | 中文 | 定义 | 示例 |
|------|------|------|------|
| **Subject** | 学科 | K12 教育中的课程科目 | 语文、数学、英语、物理... |
| **SubjectCategory** | 学科分类 | 学科的大类划分 | 语言类、理科类、人文类、技术类 |
| **Grade** | 年级 | 学生所在的年级 | 一年级、七年级、高一... |
| **GradeStage** | 学段 | 年级的大类划分 | 小学、初中、高中 |

### 题目相关

| 代码 | 中文 | 定义 | 注意 |
|------|------|------|------|
| **ReviewItemType** | 题型 | 题目的形式分类 | ❌ 不叫 QuestionType（已废弃）|
| **ReviewItemCategory** | 题型分类 | 题型的大类划分 | 客观题、主观题、综合题 |
| **Difficulty** | 难度 | 题目的难易程度 | 送分、简单、中等、困难、压轴 |
| **Source** | 来源 | 题目的出处 | 课本、考试、作业、真题... |
| **SourceCategory** | 来源分类 | 来源的大类划分 | 官方、学校、课外、其他 |
| **Tags** | 知识点标签 | 题目涉及的知识点集合 | ["函数", "不等式", "导数"] |

### 学习状态相关

| 代码 | 中文 | 定义 | 值域 |
|------|------|------|------|
| **MasteryLevel** | 掌握程度 | 学生对该题的掌握状态 | 不会(0) → 完全掌握(4) |
| **ErrorType** | 错误类型 | 做错的根本原因 | 概念不清、计算错误、粗心大意... |
| **ErrorCategory** | 错误分类 | 错误类型的大类划分 | 知识类、方法类、习惯类、客观类 |
| **ReviewInterval** | 复习间隔 | 基于艾宾浩斯曲线计算的下次复习时间 | - |

---

## 🏗️ 架构术语

### 分层架构

| 层 | 职责 | 包含内容 |
|------|------|------|
| **App** | 应用入口 | NotBadApp.swift |
| **Domain** | 领域逻辑 | Entities、ValueObjects、Protocols |
| **Data** | 数据持久化 | Repository 实现 |
| **Infrastructure** | 基础设施 | OCR、Camera、Scanner |
| **Presentation** | 用户界面 | Views、ViewModels、Components |

### 设计模式

| 术语 | 中文 | 定义 |
|------|------|------|
| **Entity** | 实体 | 有唯一标识的领域对象（如 ReviewItem） |
| **Value Object** | 值对象 | 无标识、不可变的领域对象（如 Tags、MasteryLevel） |
| **Repository** | 仓储 | 数据持久化的抽象层 |
| **ViewModel** | 视图模型 | View 的状态和逻辑封装 |

---

## 📱 功能模块术语

| 模块 | 中文 | 功能描述 |
|------|------|------|
| **Capture** | 采集 | 拍照/相册录入错题 |
| **Library** | 错题库 | 查看、搜索、管理所有错题 |
| **Review** | 复习 | 按计划复习错题，更新掌握程度 |
| **Dashboard** | 仪表盘 | 统计概览、学习数据可视化 |
| **Profile** | 个人中心 | 用户设置、数据管理 |

---

## ⚠️ 易混淆术语对照

### ❌ 禁用术语 → ✅ 正确术语

| 禁用 | 原因 | 正确术语 |
|------|------|------|
| Question | 太泛化 | ReviewItem |
| QuestionType | 已重命名 | ReviewItemType |
| WrongQuestion | 负面标签 | ReviewItem |
| Problem | 歧义（问题/难题） | ReviewItem |
| Error | 与 ErrorType 冲突 | ReviewItem |
| Level | 歧义（等级/关卡） | MasteryLevel / Difficulty |
| Type | 歧义 | 明确前缀：ReviewItemType / ErrorType |
| Category | 歧义 | 明确前缀：SubjectCategory / ErrorCategory |
| Status | 歧义 | MasteryLevel |
| Score | 本项目不涉及分数 | MasteryLevel |

### 同义词统一

| 统一用语 | 禁用同义词 |
|------|------|
| 采集 (Capture) | 录入、添加、创建、输入 |
| 复习 (Review) | 学习、温习、回顾 |
| 掌握 (Mastery) | 熟练、精通、会了 |
| 知识点 (Tags) | 考点、要点、标签 |

---

## 🔢 枚举值命名规范

### MasteryLevel（掌握程度）

| rawValue | case | 中文 | 用户可见文本 |
|----------|------|------|-------------|
| 0 | `.none` | 不会 | "完全不会" |
| 1 | `.glimpse` | 一知半解 | "看答案后能懂" |
| 2 | `.partial` | 似懂非懂 | "能做对但不确定" |
| 3 | `.good` | 基本掌握 | "能独立完成" |
| 4 | `.mastered` | 完全掌握 | "能举一反三" |

### Difficulty（难度）

| rawValue | case | 中文 | 用户可见文本 |
|----------|------|------|-------------|
| 0 | `.basic` | 送分 | "送分题" |
| 1 | `.easy` | 简单 | "简单" |
| 2 | `.medium` | 中等 | "中等" |
| 3 | `.hard` | 困难 | "困难" |
| 4 | `.extreme` | 压轴 | "压轴" |

---

## 📝 命名规范

### 文件命名

```
实体:      ReviewItem.swift
值对象:    MasteryLevel.swift, Difficulty.swift
视图:      CaptureView.swift, LibraryView.swift
视图模型:  CaptureViewModel.swift
仓储协议:  ReviewItemRepositoryProtocol.swift
仓储实现:  ReviewItemRepository.swift
```

### 变量命名

```swift
// ✅ 正确
let reviewItem: ReviewItem
let masteryLevel: MasteryLevel
let selectedSubject: Subject

// ❌ 错误
let item: ReviewItem      // 太模糊
let level: MasteryLevel   // 歧义
let subject: Subject      // 可以，但 selectedSubject 更清晰
```

---

## 🔄 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2025-11-25 | 初始版本，定义所有核心术语 |

---

## 📋 如何使用本文档

1. **新成员入职**：必读文档，理解项目术语
2. **代码评审**：检查命名是否符合术语表
3. **需求讨论**：使用统一术语沟通
4. **文档编写**：引用术语表中的定义

> 💡 **原则**：如果你不确定某个术语的含义，先查本文档；如果文档没有，提出来一起讨论并补充。
