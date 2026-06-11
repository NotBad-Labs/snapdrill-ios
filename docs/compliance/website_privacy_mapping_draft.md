# 官网隐私政策修改与 App 实证逐行映射草案

> **[!IMPORTANT]**
> **正文修改须律师定稿**
> 本文件仅作为开发团队（Antigravity）基于 App 现有“端侧零采集、本地优先”实际情况整理的隐私政策逐行映射及修改建议草案，**不构成最终法律文本**。涉及到的政策正文及条款改写必须由公司法务/律师最终审阅并定稿。

---

## 1. 官网 privacy.md 8 处失实陈述映射与修改建议

目前官网 [privacy.md](file:///Users/yiming/Developer/notbad-website/src/pages/privacy.md) 依然按“包含 Firebase 采集、ATT 授权及美国服务器存储”来编写，这与 App 生产环境的“零采集”现状严重违背。以下为 8 处失实陈述的详细映射与修改建议：

### en:19 (英文第 19 行)
- **官网原文**：
  `Anonymous Usage Data: Via Firebase Analytics, we collect anonymous events (screen views, feature usage) to improve the product. No personally identifiable information is included. On iOS, this is only enabled after you grant App Tracking Transparency (ATT) permission.`
- **App 生产实证**：
  - **生产端零调用**：全仓唯一实际调用点位于 [FirebaseBootstrap.swift:33](file:///Users/yiming/Developer/snapdrill-compliance/Packages/SnapDrillInfrastructure/Sources/SnapDrillInfrastructure/FirebaseBootstrap.swift#L33) 的 `FirebaseApp.configure()`，该包在生产中并未装配（Composition root 均不引入），且已随 PR #803 连同整个 `SnapDrillInfrastructure` 包彻底删除。
  - **NoOpAnalyticsService 注入**：[DependencyContainer.swift:48](file:///Users/yiming/Developer/snapdrill-compliance/SnapDrill/App/Composition/DependencyContainer.swift#L48) 中注入的是空服务 `NoOpAnalyticsService`，其内部所有行为统计方法均为空实现，未执行任何采集逻辑。
  - **ATT 框架已移除**：根据 [ADR-002](file:///Users/yiming/Developer/snapdrill-compliance/docs/decisions/ADR-002-remove-att-authorization.md)，ATT 授权弹窗已从 App 内部完全移除，不存在任何跟踪逻辑。
- **修改建议**：
  建议整段删除。替换为说明“SnapDrill 秉持本地优先设计，不收集任何用户使用行为数据，亦不启用任何应用跟踪或遥测统计”。

### en:20 (英文第 20 行)
- **官网原文**：
  `Crash Reports: Via Firebase Crashlytics, we collect technical data at the time of a crash (device model, iOS version, stack trace) to diagnose and fix issues.`
- **App 生产实证**：
  - **Firebase 未配置**：项目中未配置任何 `GoogleService-Info.plist` 证书，Firebase SDK 无法正常建立网络连接。
  - **零网络回传**：根据抓包与 OSLog 调试，应用在崩溃或首启时，绝对没有向 Firebase/Google 服务器发送任何数据包。
- **修改建议**：
  建议整段删除。替换为说明“为了解决崩溃问题，本应用仅使用 Apple 官方提供的原生匿名聚合统计服务（如 Xcode Organizer 崩溃日志），该服务完全由 Apple OS 自动聚合，本应用不收集且不向自建服务器或第三方回传任何崩溃堆栈”。

### en:35 (英文第 35 行)
- **官网原文**：
  `Third-party services we use (Firebase, provided by Google) are subject to their own privacy policies.`
- **App 生产实证**：
  - **依赖完全剔除**：Firebase 编译层彻底剔除已由 Claude 工程线完成，落 PR #803 待合并，二进制中不再链接任何 Firebase SDK。
- **修改建议**：
  建议修改为“我们不会与任何第三方服务商共享您的个人数据或使用内容。应用本身完全独立运行，不引入活跃的行为分析或遥测数据收集平台”。

### en:39 (英文第 39 行)
- **官网原文**：
  `Crash reports and anonymous analytics are stored by Firebase (US servers) under industry-standard security practices.`
- **App 生产实证**：
  - **零出境/本地存储**：数据（拍的题、错题本、OCR 提取内容）完全存储在用户本机的本地数据库 SwiftData 中，不进行任何云端存储（包括 Firebase 美国服务器）。
- **修改建议**：
  建议修改为“由于我们不收集您的题目数据、图片或使用遥测，因此不涉及将您的任何信息存储在我们的服务器或任何第三方境外服务器上。所有题目数据和图片均保留在您的 iPhone 本地”。

### zh:65 (中文第 65 行)
- **官网原文**：
  `匿名使用数据：通过 Firebase Analytics 收集页面访问、功能使用等匿名行为事件，用于改善产品体验。此数据不含任何可识别您身份的信息。在 iOS 上，此功能需要您通过"应用跟踪透明度（ATT）"授权后才会启用。`
- **App 生产实证**：
  - 与 **en:19** 映射相同。
- **修改建议**：
  建议整段删除。替换为：“SnapDrill 秉持‘本地优先’设计，不收集任何用户使用行为数据，亦不启用任何广告跟踪或第三方行为遥测统计。”

### zh:66 (中文第 66 行)
- **官网原文**：
  `崩溃报告：通过 Firebase Crashlytics 收集应用崩溃时的设备型号、iOS 版本、崩溃堆栈等技术信息，用于排查和修复问题。`
- **App 生产实证**：
  - 与 **en:20** 映射相同。
- **修改建议**：
  建议整段删除。替换为：“我们不收集任何个人崩溃数据。关于应用异常中断等崩溃诊断，完全通过 Apple 官方提供的 iOS 系统级原生匿名聚合分析进行，本应用不引入活跃的第三方分析 SDK 进行传输。”

### zh:81 (中文第 81 行)
- **官网原文**：
  `我们使用的第三方服务商（Firebase，由 Google 提供）受其自身隐私政策约束。`
- **App 生产实证**：
  - 与 **en:35** 映射相同。
- **修改建议**：
  建议修改为：“我们不会将您的个人数据、题目或图片共享给任何第三方。本应用不存在向任何行为分析或三方统计平台回传的场景。”

### zh:85 (中文第 85 行)
- **官网原文**：
  `崩溃报告和匿名使用数据由 Firebase（美国服务器）存储，符合行业标准的安全规范。`
- **App 生产实证**：
  - 与 **en:39** 映射相同。
- **修改建议**：
  建议修改为：“本应用的所有学习数据与照片均保留在您的设备本地，不进行任何云端上传。我们不运行任何后端存储或云服务器，您的隐私安全完全受 iOS 系统级本地安全机制保护。”

---

## 2. 通用效率工具重定位（COPPA / PIPL 通用受众 General-Audience 论证支点）

> [!NOTE]
> **PO 最新定位决策对齐 (2026-06-11)**
>
> 根据 PO 2026-06-11 最新决策，SnapDrill 整体定位已转向**「通用效率工具 —— 扫描、归档、整理任何题目与文档」**（包含职业证书、培训资料、竞赛试卷、票据、日常打印文档等），从而在法律属性上切入通用受众 (General-Audience) 范畴，弱化针对特定儿童受众 (directed-to-children) 的属性，以此规避 COPPA 法律风险并扩大市场。

### 官网草案文案映射（去 K-12 与儿童化叙事）

为了在官网全面落实这一通用定位并消除“面向儿童”的合规硬伤，以下是将官网现有“K-12/学生/孩子作业”措辞映射到“通用归档整理”的修改建议草案：

1. **主页 Showcase 描述修改映射**：
   - **原主页原文** [index.astro:89](file:///Users/yiming/Developer/notbad-website/src/pages/index.astro#L89)：
     `"SnapDrill (In Development): Snap your mistakes. Drill them right. A smart study companion for K-12 students. Simply snap a photo of any wrong answer..."`
   - **重定位修改草案**（供 PO 定稿，建议彻底移出 K-12 及 wrong answer 错题字眼）：
     `"SnapDrill (In Development): Snap any document. Organize it right. A smart filing and drill companion for learners, professionals, and exam takers. Simply snap a photo of any question sheet, certificate coursework, training material, or printed receipt..."`
   - **修改原因**：通过引入 “professionals, exam takers” 等成人化与通用化群体，并将用例范围拓宽到 “certificate coursework, training material, printed receipt”，使得在对外营销宣传中确立 App 的 **General-Audience (通用受众)** 属性，从而为隐私政策中“不针对 13 岁以下儿童采集数据”的声明提供强有力的事实支撑。

2. **隐私政策中“不面向 13 岁以下”的法律逻辑对齐**：
   - **原 privacy.md:43/89 条款**：
     `"The App is not directed at children under 13."` / `"本应用不面向 13 周岁以下的儿童"`。
   - **重定位后的合规论证**：
     由于 App 已经重新定性为通用效率工具，并不针对 13 岁以下儿童进行特定设计或定制服务，亦不包含任何针对儿童的诱导元素。因此，隐私政策中关于“不面向 13 岁以下收集”的条款在全球版通用定位下得到了事实印证。

### ⚖️ 律师判定与定性核实建议 (Legal-Gated)
虽然通用定位极大地降低了被认定为“针对儿童的 App”的风险，但由于用户仍可能用其翻拍孩子作业，因此最终的法律免责口径（包括是否可以在无需建立 COPPA 专章的前提下完全豁免儿童合规义务，或是否必须在用户引导流程中加设通用受众声明）仍需要由律师最终审阅并定稿。
