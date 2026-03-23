# SnapDrill 架构决策

> 包结构和依赖方向见各 Package.swift。本文件只记录**代码中读不出来的决策理由**。

## 设计决策（不得擅自推翻）

| 决策 | 结论 | 重新评估条件 |
|---|---|---|
| Domain 层 | **已删除**。@Model 直接作领域对象 | 引入后端 API 或多设备同步 |
| UseCase 层 | **已删除**。ViewModel 直接调 Repository | 3+ ViewModel 共享同一逻辑 |
| Repository 协议 | **已删除**。in-memory ModelContainer 替代测试 | 出现第二个实现 |
| 持久化框架 | SwiftData（非 CoreData / SQLite / Realm） | — |
| DI 模式 | DependencyContainer 唯一单例 + @Environment | — |
| Infrastructure 隔离 | Firebase 封装在独立包，仅 App 可 import | — |
| 复习算法 | SM-2 | — |

## 技术声明（防止 AI 产生错误假设）

- Vision OCR 强项是**印刷体**，无独立中文手写识别模型
- Math Notes 是 Calculator App 私有能力，**无公开 API**
- Smart Script 是屏幕手写输入，不是照片 OCR
- Foundation Models 擅长文本理解，**不擅长数学推理**

## 技术债

| ID | 描述 | 偿还条件 |
|---|---|---|
| TD-1 | tags 过滤在内存端（#Predicate 不支持 many-to-many） | Apple 完善 SwiftData Predicate |
| TD-2 | 5 个 .shared 单例待迁移到 DI | Core → Core + Services 拆包时 |
| TD-3 | NotificationCenter 跨模块刷新 | @Query 引入更多 View 后消解 |
