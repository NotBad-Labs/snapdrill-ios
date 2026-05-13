---
last_verified: 2026-05-10
layer: pattern
---
# 委派共享约束（Canonical Source）

> 本文件是智能体委派 prompt 中"关键约束摘要"的唯一来源。
> 构造委派 prompt 时，必须先读取本文件并将以下约束全文内联到 prompt 中。
> 修改约束时只改本文件，各智能体的委派配置不再硬编码。

## 关键约束

- **产品定位**：效率工具，不是教育平台。核心价值链：采集 → 管理 → 导出/打印（复习是可选留存层，智能组卷是 Pro 增值延伸）
- **工程哲学**：见 `engineering.md` 7 条核心原则（先判断方向、删减优先、YAGNI、编译拦截、边界契约、状态流、可逆性）
- **编码铁律**：swiftlint --strict 0 violations + xcodebuild build-for-testing 0 errors
- **数据安全**：零注册、核心内容数据纯本地、图片是真相、Profile 隔离；匿名 usage/crash telemetry 默认不采集，用户可 opt-in
- **开发纪律**：**修改代码前必须先读相关产品文档确认需求**；改接口签名后必须 grep 测试同步；UI 改动必须经 Xcode Review；PR 未合并前禁止推进下一任务；Review 结论必须留痕
- **优先级**：S0（数据丢失）> S1（流程阻断）> S2（有摩擦）> S3（不紧急）
- **技术栈**：iOS 26.0+ / SwiftUI / SwiftData / Swift 6.3 / defaultIsolation(MainActor)
