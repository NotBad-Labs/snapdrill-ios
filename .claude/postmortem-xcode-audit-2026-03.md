# Xcode 8 维度审计复盘报告

> **日期**：2026-03-21
> **审计来源**：Issue #376，Xcode Intelligence 8 维度全量代码审计
> **审计结果**：141 个发现 → 11 个 Issue → 12 个 PR（#392-#403）全部合并
> **核心问题**：为什么这些问题在之前的 Claude 主导的 #305 全链路终审中未被发现？

---

## 一、数据概览

| 维度 | 发现数 | 真实 Bug | Claude 遗漏原因分类 |
|---|---|---|---|
| 1. Swift 6.2 / iOS 26 现代化 | 10 | 2 | API 知识盲区 |
| 2. SwiftUI 生命周期 | 8 | 1 | 框架行为理解不足 |
| 3. SwiftData 模式 | 11 | 3 | 迁移机制理解不足 |
| 4. 代码一致性 | ~350 | 0（规范违反） | 自我审计盲区 |
| 5. Apple HIG 合规 | 17 | 5 | 设计规范执行力 |
| 6. 性能与内存 | 8 | 3 | 性能意识缺失 |
| 7. 错误处理健壮性 | 8 | 6 | 用户视角缺失 |
| 8. DocC 文档健康 | 8 | 4 | 文档维护惰性 |

**Xcode review 过程中额外发现的 Bug（非初始审计）：7 个**
- NavigationStack 双层嵌套（Sheet→push 迁移遗漏）
- 答案图删除后 ProgressView 卡死（async 迁移副作用）
- sensoryFeedback 在条件分支内失效（modifier 生命周期）
- #Index/#Unique 需要 SchemaV3（WWDC25 迁移要求）
- ISO8601 FormatStyle 使用 UTC 而非本地时区
- RelativeDateTimeFormatter "今天"→"现在" 语义偏移
- 英文复数 "1 weeks" 语法错误

---

## 二、根因分析（7 类系统性盲区）

### 盲区 1：新 API 感知力不足

**症状**：
- OCR 使用 `VNRecognizeTextRequest`（iOS 13 回调风格），iOS 18+ 已有 `RecognizeTextRequest`（async 原生）
- TabView 使用 `.tabItem/.tag`，iOS 18+ 已有 `Tab` struct（Liquid Glass）
- `DateFormatter` 未迁移到 `Date.formatted()` FormatStyle API

**根因**：我在维护现有代码时，不会主动检查「当前 SDK 是否有更新的原生替代方案」。只在写新代码时考虑新 API，对已有代码采取「能跑就不动」的惰性策略。

**教训**：`principles.md` 的「决策前研究铁律」要求「每次非平凡改动前，额外检查当前 SDK 是否有新原生方案」，但这条规则在维护阶段未被执行——它被理解为「新功能开发时的规则」而非「每次触碰代码时的规则」。

**对策**：
- 每次 touch 一个文件时，检查该文件使用的 API 是否有 iOS 26 更新版本
- 定期（每个 TestFlight 发版前）全量扫描已废弃 API

---

### 盲区 2：「自己写的代码不审计」

**症状**：
- conventions.md 明确要求「注释全部使用简体中文」，但 200+ 处英文注释存在
- principles.md 明确要求「NavigationLink 用于导航」，但 LibraryListView 用 Button+push
- 星级评分用 `onTapGesture` 而非 `Button`，VoiceOver 完全不可用

**根因**：我在写代码时遵循规则，但从不回头审计已有代码是否符合后来建立的规则。规则是增量添加的——先写了代码，后建立了规则，但没有回溯执行。

**类比**：这就像公司先建了楼，后制定了消防规范，但从不检查旧楼是否达标。

**对策**：
- 每次规则变更（conventions.md / principles.md 更新）时，Grep 扫描已有代码的违反情况
- 建立规则时同步创建 compliance check Issue

---

### 盲区 3：SwiftData Schema 迁移机制理解不足

**症状**：
- 直接在 SchemaV2 中添加 `#Index`/`#Unique`，未创建 SchemaV3
- BackupManifest 和 SwiftData Schema 版本独立管理但无文档说明
- 删除操作先删图片再 save DB（顺序风险）

**根因**：对 SwiftData 的 VersionedSchema 机制理解停留在「声明 → 迁移计划 → 完成」的表面层，不理解 Schema hash 如何计算、宏如何影响 hash、以及 WWDC25 对此的明确指导。

**教训**：SwiftData 是 2023 年新框架，文档和最佳实践仍在快速演进。WWDC 每年都有新指导，不能依赖初始学习。

**对策**：
- 每次修改 @Model 类时，检查是否需要新 VersionedSchema
- 将 WWDC 新 session 的关键变更同步到 `skills/swiftdata-patterns` gotchas

---

### 盲区 4：性能意识缺失（「能跑就行」）

**症状**：
- 复习卡片加载 2000px 全分辨率图片，实际显示区域仅 400px（每张浪费 ~8MB 内存）
- `loadDownsampledImage` API 已存在但从未在复习模块使用
- LibraryEditViewModel 同步 I/O 阻塞主线程

**根因**：写代码时关注「功能是否正确」，不关注「性能是否合理」。特别是图片加载——`loadImage` 和 `loadDownsampledImage` 都能让图片显示出来，功能上等价，但内存占用差 10 倍。

**教训**：性能问题在开发阶段不会表现为崩溃或错误，只在用户积累数据后（200+ 题）才暴露。测试阶段数据量小，掩盖了问题。

**对策**：
- 图片加载统一使用 `loadDownsampledImage`，`loadImage` 仅用于需要原始分辨率的场景（导出/OCR）
- 新增图片加载代码时，必须评估显示尺寸 vs 加载分辨率

---

### 盲区 5：错误处理的「用户视角」缺失

**症状**：
- PDF 导出失败只设 `isLoading = false`，用户看到死胡同
- Library 加载失败只 log，用户看到空列表不知道出了什么问题
- 6 个 catch 块只写日志不更新 UI 状态

**根因**：错误处理从「开发者视角」出发——「日志里有了，调试时能看到」。但用户看不到日志。错误处理的终极目标是「用户知道发生了什么 + 知道该怎么办」，不是「开发者能排查」。

**教训**：`principles.md` 的错误处理规则（关键路径禁止 try?）关注的是「不丢数据」，但没有关注「告知用户」。两者都重要。

**对策**：
- 每个 catch 块必须回答：用户会看到什么？用户能做什么？
- 如果答案是「用户看到空白/无反应」→ 必须添加 error state + UI 反馈

---

### 盲区 6：SwiftUI modifier 生命周期理解不够深

**症状**：
- `.sensoryFeedback` 挂在 `if let` 条件分支内，View 移除时 modifier 失效
- Sheet→NavigationLink 迁移时未考虑子 View 内部的 NavigationStack
- async 迁移后 `displayedImage == nil` 短暂闪现错误状态

**根因**：SwiftUI 的声明式范式让人容易忽略 View 生命周期。`if let { ... }` 看起来只是「有条件显示」，但实际上是「View 创建/销毁」，modifier 生命周期与 View 绑定。

**教训**：每次改变 View 的呈现方式（Sheet→push、sync→async、添加条件分支）时，必须审查该 View 及其 modifier 的完整生命周期。

**对策**：
- `.sensoryFeedback`、`.task`、`.onReceive` 等有生命周期的 modifier 应挂在稳定的父 View 上
- 改变呈现方式时，列出受影响的 modifier 并逐一验证

---

### 盲区 7：文档维护是「一次性行为」

**症状**：
- DocC landing page 引用已删除的 `NetworkMonitor`（删代码时没更新文档）
- Infrastructure.docc 引用不存在的 `CrashReportingService`（重构时文档未同步）
- Settings.docc 声明依赖 Dashboard（实际是 Library，架构重组时未更新）

**根因**：文档被视为「写完就好」的一次性工件。代码改了，文档没人改——因为文档不参与编译，不会报错。

**教训**：`workflow.md` 的文档治理规则（Last verified + 发版前扫描）是正确的，但在日常 PR 中没有执行「改了代码就查一下文档」。

**对策**：
- 删除/重命名公开类型时，Grep DocC 文件确认无残留引用
- infrastructure.md 的「新增 API 时同步更新」规则扩展到「删除/重命名 API 时同步更新」

---

## 三、为什么 Claude 的 #305 全链路终审没发现这些？

### 3.1 审计方法论的局限

**#305 终审采用的方法**：7 顶帽子（产品/安全/UX/QA/性能/数据/用户代言人），每个帽子从自己的视角审查。

**Xcode 审计采用的方法**：8 个技术维度，逐文件逐行扫描。

**差异**：
- #305 是「自上而下」——从需求出发，验证代码是否满足需求
- Xcode 审计是「自下而上」——从代码出发，检查每行是否符合规范
- 两者互补，不可替代

**#305 能发现的**：S0 数据丢失（try? 吞错误）、S1 流程阻断（EXIF GPS 泄漏）、用户文案问题
**#305 不能发现的**：API 过时、注释语言不一致、DocC ghost symbols、性能浪费

### 3.2 「同一模型戴不同帽子」的根本限制

这已在 `workflow.md` 的「多方独立审计铁律」中记录：

> 同一模型戴不同帽子，知识边界和偏见是共享的。

具体到这次：
- 我不知道 `RecognizeTextRequest` 存在 → 戴任何帽子都不会发现 OCR 用了旧 API
- 我写了 `Button+router.push` → 戴 HIG 帽子时不会质疑自己的实现
- 我对 SwiftData Schema hash 理解不足 → 戴架构师帽也不会发现 #Index 需要 V3

**结论**：多方独立审计不是「锦上添花」，是发现盲区的**唯一有效手段**。

### 3.3 审计频率的问题

#305 是一次性终审。但代码在终审后继续演进（PR #336-#379），新引入的模式没有被再次审计。

**对策**：审计应该是周期性的，不是一次性的。每个重大里程碑（如 TestFlight 发版前）应触发全量审计。

---

## 四、流程改进（已落地）

| 改进 | 来源 | 落地状态 |
|---|---|---|
| 发现即追踪铁律 | 审计排除发现未建 Issue | ✅ workflow.md 已更新 |
| /update-status skill | STATUS.md 推送滞后 | ✅ 已创建并使用 |
| Review 提示词必须读模板 | 两次违反提示词规范 | ✅ memory 已更新 |
| 验收铁律严格执行 | 一度试图自审自批 | ✅ 每次 fix 都经 Xcode 验收 |
| SchemaV3 迁移 | #Index 需要新版本 | ✅ PR #399 |
| 删除操作顺序 | 先 DB 再图片 | ✅ PR #399 |

---

## 五、未来审计建议

### 5.1 审计节奏

| 时机 | 审计方式 | 范围 |
|---|---|---|
| 每个 PR | Gemini（自动）+ Xcode/Antigravity（手动，视复杂度） | diff 级别 |
| TestFlight 发版前 | Xcode 8 维度全量审计 | 全代码库 |
| 规则变更后 | Grep compliance check | 已有代码 |
| WWDC 后 | 新 API 对照扫描 | 已有代码 |

### 5.2 审计维度建议扩展

Xcode 的 8 维度已经很全面，但可以考虑增加：
- **维度 9：本地化完整性**（hardcoded strings、.strings 对称性）
- **维度 10：测试覆盖度**（新增功能的测试跟进）

### 5.3 Xcode Intelligence 的独特价值

本次审计证明 Xcode Intelligence 在以下方面显著优于 Claude 自审：
1. **API 知识时效性**：掌握 WWDC25 最新变更（RecognizeTextRequest、SchemaV3）
2. **框架行为精确验证**：通过 ExecuteSnippet 实际运行代码验证行为（ISO8601 时区、RelativeDateTimeFormatter 语义）
3. **跨文件影响分析**：Sheet→push 迁移时检查子 View 的 NavigationStack
4. **规范合规扫描**：逐行检查注释语言、MARK 规范、文件头格式

---

## 六、核心教训（一句话）

**写代码的人审不出自己代码的问题，正如校对自己文章的人看不到自己的错别字。多方独立审计不是流程负担，是质量的唯一保障。**

---

> 本报告由 Claude Opus 4.6 撰写，基于 2026-03-20~21 两天密集修复 11 个 Issue（12 个 PR）的实际经验。
> Xcode Intelligence 在 review 过程中累计发现 7 个 Claude 未预见的真实 Bug，验证了多方审计的不可替代价值。
