# 重构优先级矩阵（NotBad）

更新时间：2025-09-22

优先级定义：

- Critical：影响功能或稳定性，必须立即修复
- High：影响可维护性/可测性，建议本周完成
- Medium：影响可读性/一致性，建议本月完成
- Low：优化类，有空时推进

## 任务列表

| 文件/模块 | 问题 | 优先级 | 预估 | 价值 | 建议方案 |
|---|---|---|---|---|---|
| 测试体系 | 覆盖率未固化与可视化 | High | 2h | 质量门禁 | 开启 `-enableCodeCoverage YES` 与报告导出，纳入 CI |
| 监控/日志 | 日志未统一结构化 | Medium | 2h | 排障效率 | 引入 `Logger` 域（如 app.lifecycle、nav.route、domain.service）|
| Service/UseCase | 仅具体类型缺协议 | Medium | 4h | 可替换/可测 | 为 `ReviewItemService`/UseCase 增协议，默认实现保持不变 |
| 预览数据注入 | 直接造数据 vs Provider | Low | 1h | 一致性 | 预览改用 `MockDataProvider`，与契约测试复用 |
| Xcode 资源 | 重复拷贝 README | Critical | 已修复 | 稳定性 | 已在 pbxproj 排除冲突路径 |

## 执行节奏建议

1. 本周：覆盖率报告 + 日志统一方案最小集（核心场景）
2. 下周：Service/UseCase 抽协议（逐步改造、先接口后替换）
3. 持续：预览数据源一致化、文档与仪表盘同步更新
