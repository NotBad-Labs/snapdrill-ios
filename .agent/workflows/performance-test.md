---
description: 使用 Instruments 进行标准性能分析与测试
---

# 性能测试工作流 (Performance Testing)

## 执行步骤

### 1. 自动化基准测试

// turbo
运行以下命令进行 Release 环境构建与单元测试性能收集：

```bash
xcodebuild test -scheme SnapDrill -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 2. Instruments 手动分析

按照以下路径识别资源瓶颈：

- **Time Profiler**: 检查 `SM-2` 算法计算或 `OCR` 处理是否消耗过量 CPU。
- **Allocations**: 验证单次图片保存或模型加载内存增量是否保持在 10MB 以内。
- **Leaks**: 检查 `@MainActor` 类、Repository 或闭包中是否存在循环引用。

### 3. 数据同步

测试完成后，请根据结果更新架构文档中的性能目标值。
