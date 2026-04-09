---
paths:
  - "CLAUDE.md"
  - "STATUS.md"
---

<!-- last verified: 2026-04-09 -->
# 委派共享约束（Canonical Source）

> 本文件是 Codex / Gemini 委派 prompt 中"关键约束摘要"的唯一来源。
> 构造委派 prompt 时，必须先读取本文件并将以下约束全文内联到 prompt 中。
> 修改约束时只改本文件，codex-delegation.md 和 gemini-delegation.md 不再硬编码。

## 关键约束

- **产品定位**：效率工具，不是教育平台。价值链：采集 > 管理 > 导出/打印（复习是独立附加值）
- **工程哲学**：奥卡姆剃刀，先研究再动手，N > 3 是警告
- **编码铁律**：swiftlint --strict 0 violations + xcodebuild build-for-testing 0 errors
- **数据安全**：零注册、核心内容数据纯本地、图片是真相、Profile 隔离；匿名 usage/crash telemetry 默认开启，用户可关闭
- **开发纪律**：**修改代码前必须先读相关产品文档确认需求**；改接口签名后必须 grep 测试同步；UI 改动必须经 Xcode Review；PR 未合并前禁止推进下一任务；Review 结论必须留痕
- **优先级**：S0（数据丢失）> S1（流程阻断）> S2（有摩擦）> S3（不紧急）
- **技术栈**：iOS 26.0+ / SwiftUI / SwiftData / Swift 6.3 / defaultIsolation(MainActor)
