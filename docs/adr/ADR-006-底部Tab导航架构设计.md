# **ADR-006: 底部Tab导航架构设计**

**状态**: 已接受  
**日期**: 2025-09-13  
**决策者**: 产品团队 & 技术团队  

## 背景

在NotBad错题本App的设计过程中，需要确定主界面的导航架构。作为K12学习工具，应用的导航设计直接影响用户体验和学习效率。

## 决策

采用**底部Tab导航**作为主界面架构，包含5个核心功能模块。

### 最终Tab设计

| 序号 | 中文名称 | 英文名称 | 图标 | 功能定位 |
|------|----------|----------|------|----------|
| 1 | 首页 | Home | 🏠 house.fill | 学习总览、进度概览、快速入口 |
| 2 | 题库 | Question Bank | 📚 book.fill | ReviewItem管理、分类筛选、复习跟踪 |
| 3 | 录入 | Capture | 📷 camera.fill | OCR拍照识别、批量导入、智能分类 |
| 4 | 发现 | Discover | 🌟 lightbulb.fill | 轻度社交、学习资源、AI助手 |
| 5 | 我的 | Me | 👤 person.fill | 个人设置、账户管理、Pro订阅 |

### 技术实现

```swift
TabView {
    // 首页 - 学习总览
    NavigationView { HomeTabView() }
    .tabItem {
        Image(systemName: "house.fill")
        Text("首页")
    }
    
    // 题库 - ReviewItem管理
    NavigationView { QuestionBankTabView() }
    .tabItem {
        Image(systemName: "book.fill")
        Text("题库")
    }
    
    // 录入 - OCR功能
    NavigationView { CaptureTabView() }
    .tabItem {
        Image(systemName: "camera.fill")
        Text("录入")
    }
    
    // 发现 - 学习社区
    NavigationView { DiscoverTabView() }
    .tabItem {
        Image(systemName: "lightbulb.fill")
        Text("发现")
    }
    
    // 我的 - 个人中心
    NavigationView { ProfileTabView() }
    .tabItem {
        Image(systemName: "person.fill")
        Text("我的")
    }
}
```

## 决策理由

### 1. 术语准确性
- **题库** vs 复习项：使用"题库"更直观，符合用户认知习惯
- **ReviewItem**：在代码中保持术语表定义的准确性
- **我的** vs 我：中文表达更自然亲切

### 2. 功能完整性
- 覆盖PRD中定义的所有核心功能模块
- 符合学习工具的用户使用流程
- 为未来功能扩展留有空间

### 3. 用户体验
- 符合iOS设计规范
- 图标选择直观易懂
- 导航层次清晰合理

### 4. 架构一致性
- 与Clean Architecture分层设计一致
- 支持协调器模式的导航管理
- 便于模块化开发和测试

## 替代方案

### 方案A: 抽屉式导航
- **优点**: 节省屏幕空间
- **缺点**: 不符合iOS用户习惯，学习工具需要快速访问

### 方案B: 顶部Tab导航
- **优点**: 内容区域更大
- **缺点**: 在iPhone上操作不便，不符合移动端设计规范

### 方案C: 3个Tab设计
- **优点**: 更简洁
- **缺点**: 功能过于集中，不符合学习工具的复杂需求

## 影响

### 正面影响
- ✅ 提升用户学习效率
- ✅ 符合移动端设计规范
- ✅ 支持功能模块化开发
- ✅ 便于后续功能扩展

### 潜在风险
- ⚠️ 功能入口较多，需要良好的引导
- ⚠️ 需要平衡各Tab的功能复杂度

## 缓解措施
1. **用户引导**: 通过Onboarding流程介绍各Tab功能
2. **功能平衡**: 确保各Tab功能价值均衡
3. **性能优化**: 采用懒加载和预加载策略
4. **用户反馈**: 持续收集用户使用数据优化导航

## 相关文档
- [PRD v4.2](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v4.2%20(Swift6%20+%20iOS18).md)
- [TDD v4.2](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v4.2%20(Swift6%20+%20iOS18).md)
- [业务术语表 v4.2](../glossary/NotBad%20App%20-%20业务术语表%20v4.2%20(Swift6%20+%20iOS18).md)
- [ADR-005: 导航协调器模式](ADR-005-导航协调器模式.md)

## 实施计划
1. **Sprint 1**: 实现基础Tab框架和占位视图
2. **Sprint 2**: 实现核心功能模块
3. **Sprint 3**: 优化用户体验和性能

---
**审核**: 产品经理、技术负责人  
**版本**: v1.0  
**下次审查**: 2025-10-01
