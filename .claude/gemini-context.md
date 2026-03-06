# SnapDrill — Gemini 审查上下文

本文件供 Gemini 全项目审查使用，注入项目基本事实与当前架构约束。
所有约束均标注了**制定理由**和**可修改触发条件**——这些约束是基于当前项目规模的
工程决策，不是永久禁令。随着项目增长，若触发条件成立，约束可以修改。

---

## 项目基本事实

- **技术栈**：Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+
- **规模**：5 个 SPM 包，~160 个 Swift 文件，单开发者维护
- **产品定位**：本地优先单用户间隔重复学习 App，无后端，无多设备同步
- **核心算法**：SM-2（SuperMemo 2）间隔重复调度
- **并发模型**：Swift 6 strict concurrency，所有 ViewModel 为 `@Observable @MainActor final class`

## 包结构（依赖单向，严格禁止反向）

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore（零依赖）
        │                                      ▲
        └──────────► SnapDrillUI ──────────────┘
SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

---

## 当前架构约束（附理由与修改条件）

以下约束基于当前项目规模制定。Gemini 审查时若发现代码已触及"可修改触发条件"，
**应明确指出"建议重新评估该约束"，而不是简单报告为违规**。

### 约束 1：禁止新增 Domain 层或 Domain struct

**理由**：`@Model` 类直接作为领域对象，避免 `@Model → Domain struct → ViewModel`
的映射层。当前 App 单用户本地优先，无网络 DTO 转换需求，映射层只增加维护成本
（每改一个字段要动 5+ 个文件，而直接用 @Model 只需改 3 个文件以内）。

**可修改触发条件**（满足任一即可重新评估）：
- 引入后端 API，需要将网络 DTO 与本地 @Model 解耦
- 多设备同步场景，同一概念在本地与云端有不同表示
- 单个 @Model 超过 20 个属性，领域逻辑复杂度明显上升

### 约束 2：禁止新增 UseCase 层

**理由**：当前 ViewModel 直接调用 Repository，UseCase 只是透传，零收益。
5 个功能模块（Capture/Library/Review/Dashboard/Settings），业务逻辑集中且简单，
UseCase 只会把"改一个功能需要动 3 个文件"变成"动 5 个文件"。

**可修改触发条件**（满足任一即可重新评估）：
- 同一业务逻辑需要被 3 个以上 ViewModel 共享（不是 2 个）
- 出现跨 Repository 的复杂编排逻辑（如：操作 A 成功才能做操作 B，且涉及 2 个以上 Repository）
- 引入 Widget/Shortcut/Share Extension 等需要复用核心业务逻辑的 Extension Target

### 约束 3：Repository 使用具体类，禁止 Repository 协议

**理由**：当前每个 Repository 只有一个实现。"为可测试性加协议"的需求已被
in-memory `ModelContainer` 满足——测试直接用内存数据库，无需 Mock Repository。
只有一个实现的协议是纯维护负担。

**可修改触发条件**（满足任一即可重新评估）：
- 同一个 Repository 接口出现第二个实现（如：本地实现 + 云端实现并存）
- 需要在不启动 SwiftData 的环境下测试（如：纯 macOS CLI 测试）

### 约束 4：禁止 `any` existentials、force unwrap `!`、`@unchecked Sendable`

**理由**：Swift 6 并发安全的基本要求，与项目规模无关。这三项是**硬性禁止**，
不受项目增长影响，无修改触发条件。

**`any` existentials 的已批准例外（必须在代码中注释说明理由）：**

- **Exception 1**：`EnvironmentKey.Value` 持有跨模块协议类型（如 `any ServiceContainer`）。
  消除 `any` 需打破 Features → Core 的依赖方向，违反更核心的架构规则，故允许。
- **Exception 2**：无 associated type / Self 约束的协议作为集合元素类型，例如
  `[any PDFExportable]`。SwiftData 或 API 设计要求异构集合时允许，非设计懒惰。
  典型位置：`PDFExportService.createPDF(from items: [any PDFExportable], ...)`。

**`force unwrap !` / `try!` 的已批准例外：**

- **Preview-only 初始化**：`PreviewRepositoryContainer.init()` 中的
  `try! ModelContainer(for: schema, configurations: [config])`（`isStoredInMemoryOnly: true`
  的 ModelContainer 在运行时不可能失败，失败意味着内存分配错误，属不可恢复程序错误）。
  必须配合 `// swiftlint:disable:next force_try` 注释标注。

**`.v26` SPM 版本后缀说明（非错误）：**

- 项目所有 SPM 包的 `Package.swift` 均使用 `.package(url: "...", exact: ".v26")` 格式，
  `.v26` 是该项目对 Xcode 26 / Swift 6.2 兼容包的版本命名约定，**不是版本号错误**，
  审查时请勿标记为问题。

### 约束 5：禁止 `print()`，必须使用 `SnapDrillLogger`

**理由**：`print()` 在生产环境不可过滤，`SnapDrillLogger`（基于 `os.Logger`）
支持按 subsystem/category 过滤，与 Console.app 集成。这是**硬性要求**，
不受项目增长影响，无修改触发条件。

---

## 审查优先级说明

Gemini 审查时请按以下优先级排序问题：

1. **🔴 严重**：逻辑错误（崩溃、数据丢失、状态不一致）
2. **🔴 严重**：Swift 6 并发安全违规（跨 actor 数据竞争）
3. **🟡 警告**：SwiftData 使用错误（跨 context 写入、错误的 actor 上调用）
4. **🟡 警告**：硬性禁止项违规（force unwrap、print、any existential）
5. **🟢 建议**：代码质量优化（冗余逻辑、命名不清晰等）
6. **🔵 规模评估**：若发现某约束的"可修改触发条件"已成立，单独列出说明

**请勿建议**：引入当前规模不需要的抽象层（Domain/UseCase/Repository 协议），
除非明确说明触发条件已满足并附具体证据。

---

## 测试审查补充标准

审查测试文件时，额外关注：

- 测试是否在验证**行为**（输入→输出）而非**实现细节**（内部状态）
- 核心路径是否有测试覆盖：SM-2 调度、saveContext 失败回滚、分页边界
- 是否存在"永远通过"的假测试（断言恒真、空 test body）
- 测试是否使用 in-memory `ModelContainer`（禁止在测试中访问真实磁盘）
