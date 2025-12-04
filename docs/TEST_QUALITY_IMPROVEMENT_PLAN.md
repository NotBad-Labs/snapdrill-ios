# 测试质量改进计划

## 审计结论

当前测试存在**系统性质量问题**，主要表现为：

1. **假数据与真实场景脱节** - 使用 1-2 字节数据测试图片处理
2. **性能测试几乎为零** - 1497 个测试中仅 3 个 measure
3. **View 组件零覆盖** - 所有 UI 组件都没有测试
4. **只测 Mock 不测真实** - OCR、PDF 等服务只测了 Mock

## 问题分类

### 🔴 P0 - 立即修复（已发现线上问题）

| 问题 | 影响 | 状态 |
|------|------|------|
| ItemRow 图片解码 | 题库卡顿 | ✅ 已修复 |
| 图片性能测试缺失 | 无法预防性能回归 | ✅ 已添加 |

### 🟠 P1 - 高优先级（可能引发线上问题）

| 问题 | 风险 | 建议 |
|------|------|------|
| 大数据量测试缺失 | 数据多时可能卡顿 | 添加 100+ 条数据测试 |
| PDF 导出性能 | 导出大文件可能卡死 | 添加大图片导出测试 |
| OCR 真实测试缺失 | 识别质量无保障 | 添加真实图片 OCR 测试 |
| 内存压力测试缺失 | 可能内存泄漏 | 添加内存监控测试 |

### 🟡 P2 - 中优先级（代码质量问题）

| 问题 | 影响 | 建议 |
|------|------|------|
| View 组件无测试 | 重构风险 | 添加 ViewInspector 测试 |
| 假数据泛滥 | 测试价值低 | 创建真实测试数据工厂 |
| 集成测试缺失 | 组件配合问题 | 添加端到端测试 |

## 改进行动

### 阶段 1：测试基础设施（1-2 天）

1. **创建真实测试数据工厂**
```swift
struct TestDataFactory {
    /// 生成真实尺寸的 JPEG 图片
    static func createRealImage(size: CGSize) -> UIImage
    
    /// 生成指定大小的 Data
    static func createImageData(sizeKB: Int) -> Data
    
    /// 创建带真实图片的 ReviewItem
    static func createReviewItemWithImage() -> ReviewItem
}
```

2. **添加性能测试基类**
```swift
class PerformanceTestCase: XCTestCase {
    func measureMainThreadBlock(_ block: () -> Void)
    func measureMemoryUsage(_ block: () -> Void)
    func assertPerformance(baseline: Double, tolerance: Double)
}
```

### 阶段 2：补充关键性能测试（2-3 天）

- [ ] 列表滚动性能测试
- [ ] 大数据量筛选测试
- [ ] 图片压缩性能测试
- [ ] PDF 导出性能测试
- [ ] 数据库查询性能测试

### 阶段 3：真实场景测试（3-5 天）

- [ ] 使用真实图片的 OCR 测试
- [ ] 使用真实数据的导出测试
- [ ] 100+ 条记录的集成测试
- [ ] 内存压力测试

### 阶段 4：View 组件测试（可选）

使用 ViewInspector 或 Snapshot Testing：
- [ ] ItemRow 渲染测试
- [ ] FilterChip 交互测试
- [ ] DashboardCard 数据绑定测试

## 测试质量门槛

今后所有 PR 必须满足：

1. **图片/数据相关代码**：必须使用真实尺寸测试数据
2. **性能敏感代码**：必须包含 `measure` 性能测试
3. **主线程代码**：必须验证不阻塞
4. **新 View 组件**：建议添加渲染测试

## 代码审查检查清单

- [ ] 测试数据是否接近真实场景？
- [ ] 是否有性能测试（如涉及大数据）？
- [ ] 主线程操作是否被测试？
- [ ] Mock 是否配合真实服务测试？
