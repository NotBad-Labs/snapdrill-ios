<!-- last updated: 2026-04-13 -->
# 项目待办与阻塞

> 长期待办和外部阻塞的追踪，不是临时任务列表。

## 外部阻塞

### Apple Developer 公司账号（2026-04-01 提交）

NotBad Labs L.L.C. 的 Apple Developer Program Enrollment 等待审核。

- Enrollment ID：83VZW7VJKK
- DUNS：143987148

**阻塞的功能**：
- StoreKit 付费墙（#479）
- iCloud 同步（#485）
- App Store 提交（#490）
- TestFlight External 分发
- Share Extension 的 App Group 正式配置

**不受阻塞的工作**：代码开发、Simulator 测试、真机调试、PR Review。

## 技术探索方向

### Foundation Models Framework

设备端 LLM 做题目结构化解析（题号/题干/选项分离），比纯 Vision OCR 更智能。`@Generable` 宏可确保输出类型安全。
与 product-requirements.md 的 "一图多题演进路径" 和 "端上 AI 集成" 对齐。评估时间：v1.5+。

### App Intents + Semantic Indexing

让 Siri 能说"今天有哪些题要复习"，提升系统级可见性。
核心实体（DrillItem、ReviewItem）暴露为 AppEntity。评估时间：v1.5+。

## Open PRs 待处理

- #582: Share Extension 后台读图 + AppActivityTracker 全链路接线（代码完成，待 review）
- #584: CI Swift Testing 计数识别 + issue 标签守卫（CI 改进，待 review）
- #585: 误导性文档审计 Batch 1（需要 re-scope，受项目主权重组影响）
