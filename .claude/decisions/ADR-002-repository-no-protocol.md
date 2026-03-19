---
id: ADR-002
status: Accepted
date: 2026-03-03
implementation: Complete
verified: 2026-03-19
---

# ADR-002: Repository 无协议（in-memory ModelContainer 替代测试）

## 背景

传统 MVVM 架构中，Repository 层通常定义协议（Protocol），ViewModel 依赖协议而非具体实现，测试时注入 Mock Repository。

但 SwiftData 提供了 `ModelConfiguration(isStoredInMemoryOnly: true)` 的 in-memory 模式，可以创建完全功能的内存数据库用于测试，无需 Mock。

## 决策

**Repository 使用具体类，不定义协议。测试通过 in-memory ModelContainer 创建真实 Repository 实例。**

此决策是 `principles.md` 协议判断标准的具体应用：有替代测试手段的场景，不需要协议。

## 被否决的方案

### 方案 A：定义 Repository 协议 + Mock 实现

- **为什么否决**：每个 Repository 协议只有一个生产实现（具体 Repository 类），Mock 实现是额外的维护负担。in-memory ModelContainer 提供的是**真实的 SwiftData 行为**（包括 Predicate 查询、关系、级联删除），Mock 反而可能掩盖真实 bug
- **补充证据**：PR #249 的 Gemini Review 曾发现 Mock 测试通过但实际行为不一致的问题，印证了 in-memory 测试优于 Mock 测试
- **何时重新评估**：如果 SwiftData in-memory ModelContainer 在某些场景下无法模拟生产行为（如特定迁移路径），需要 Mock 作为补充

### 方案 B：跨包时用协议，包内用具体类

- **为什么否决**：当前 Repository 从 SnapDrillData 暴露给 SnapDrillFeatures，确实跨包。但 Repository 有 in-memory ModelContainer 这一替代测试手段，属于 `principles.md` 协议判断标准的明确例外。跨包 ≠ 必须协议，关键是有无替代测试手段
- **何时重新评估**：如果需要多种数据源后端（如 CloudKit + 本地混合查询），Repository 协议可为不同后端提供统一接口

## 后果

**正面**：
- 消除了 5 个 Repository 协议文件和对应的 Mock 文件
- 测试更可靠——in-memory ModelContainer 行为与生产一致
- 新增 Repository 方法时只改一处（具体类），不需要同步更新协议

**负面**：
- ViewModel 直接依赖具体 Repository 类，编译器无法强制依赖方向（靠包结构和 import 规则约束）
- 如果未来需要多种数据源（如 CloudKit + 本地混合），可能需要重新引入协议

**技术债**：无。
