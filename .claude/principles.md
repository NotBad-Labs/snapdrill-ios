# SnapDrill 工程哲学

> **上游依赖**：`product-vision.md`（产品定位）、`product-requirements.md`（功能需求）
>
> 本文件定义「怎么想」——决策框架和工程哲学。
> 「怎么协作」见 `workflow.md`，「怎么写代码」见 `conventions.md`。

---

## 战略元原则（2026-03-13 确立）

**这三条原则高于本文件中的所有其他原则。当其他原则与这三条冲突时，以这三条为准。**

1. **战术上的勤奋不能掩盖战略上的懒惰**
   不能因为在局部细节上做得很勤快（修 bug、写测试、优化 UI），就忽略全局架构和包结构这种战略问题。每次开始新工作前先问：战略层面有没有未解决的问题？

2. **局部最优解不一定是全局最优解**
   单个包内部看起来合理，不代表整体包结构合理。单个文件改得漂亮，不代表模块边界正确。决策时必须从全局视角审视。

3. **规划设计阶段的最大成本也是最小成本**
   没有真正发布前，永远可以完全推倒重来。设计阶段多花时间思考，远比发布后返工便宜。不要急于动手写代码——先把设计讨论透。

4. **方法论本身必须持续正向优化**
   铁律不是教条。「一以贯之」不是千篇一律地执行固定规则，而是持续朝着同一个方向——
   更简洁、更可靠、更少摩擦——迭代改进。当实践证明某条规则有更好的表达或更精准的边界时，
   应该修订它，而非固守原文。修订必须满足三个条件：
   (a) 有实证（实际遇到的问题、review 发现的盲区、用户反馈）
   (b) 修订后严格更优（更清晰、更少歧义、覆盖更完整），禁止以优化为名降低标准
   (c) 记录变更理由（日期 + 一句话说明为什么改）

**工程标准不因团队规模打折**：项目有多个 AI 协作者（Claude、Gemini、Antigravity），不规范的架构和文档会给所有协作者增加认知摩擦。应该拆包就拆包，应该加协议就加协议，不能因为「单人项目」或「改动太大」就降低标准。

---

## 决策前研究铁律（2026-03-06 确立，核心精神不变，表述持续优化）

**在写任何不确定的实现前，必须先做研究，再决定方案。禁止想当然写代码。**

适用范围：UI/UX 交互、技术方案选型、并发模式、系统框架 API 行为——凡是不确定的，必走研究流程。

### UI/UX 决策研究流程

1. **Apple 原生 App**：Settings / Contacts / Notes / Reminders / Files / Photos 如何解决同类问题？
2. **行业标杆 App**：同类场景在微信、支付宝、Notion、Things 3、Spotify 等高质量 App 中怎么做？
3. **Apple HIG 文档**：[developer.apple.com/design/human-interface-guidelines](https://developer.apple.com/design/human-interface-guidelines) 有无明确推荐？
4. **综合判断**：Apple 理念高度参考，但不刻板遵循；原则性与灵活性相统一。

### 技术实现研究流程

1. **Apple 官方开发者文档**：[developer.apple.com/documentation](https://developer.apple.com/documentation) — 目标 API/框架的行为、线程安全性、官方推荐用法是什么？
2. **WWDC Sessions**：有无相关 session 讲解最佳实践？
3. **现有代码库**：项目内已有类似问题的处理方式是什么？保持一致。
4. **综合判断**：文档说什么就用什么，不凭经验推测系统行为。

### 判断框架

- Apple 文档有明确推荐 → 直接采用
- Apple 文档无明确推荐 + 行业有惯例 → 采用惯例，注释说明理由
- Apple 推荐 + 行业有更好实践（UI/UX）→ 选更好实践，注释说明理由
- 完全自创 → 有明确理由才允许，否则必须先研究再开工

### 研究声明输出格式

凡涉及「不确定的实现」（见上方适用范围）必须输出，格式：

```
研究确认：
- Apple 文档：[查了什么 / 不适用（原因）]
- 现有代码库：[找到的参考模式]
- HIG / 行业惯例：[查了什么 / 不适用（原因）]
```

跳过研究 = 违反铁律。用户可随时说「铁律？」要求补充声明。

**可免声明的情况**（必须说明免声明理由）：
- typo 修正
- 用户明确指定了具体改法的机械改动
- 纯文档/注释修改（不涉及代码行为变更）

---

## Apple 原生优先铁律（2026-03-06 确立，核心精神不变，表述持续优化）

**所有 UX/UI/交互改动，必须先找到苹果官方 App 或 HIG 文档中的对应模式，照搬。禁止自创交互。**

> 单人团队无法在设计上胜过苹果。照抄苹果原生 = 用户零学习成本 + 最高品质下限。

### 检查顺序（每次改 UI 前必走）

1. **找参考 App**：Settings / Contacts / Reminders / Notes / Photos / Calendar 是最权威的参考
2. **查 HIG**：[developer.apple.com/design/human-interface-guidelines](https://developer.apple.com/design/human-interface-guidelines)
3. **查 SwiftUI 文档**：优先用平台原生控件，禁止自己实现已有控件的功能

### 常用模式速查（经过确认的正确做法）

| 场景 | 正确做法 | 禁止做法 |
|---|---|---|
| Form 中选择一个值（短列表） | `Picker(.menu)` | `Menu` 包裹整行 |
| Form 中选择一个值（长列表） | `NavigationLink` → 勾选列表 | 自制 Sheet |
| 非 Form 上下文内联选择（无新建） | `Picker(.menu)`，点击区为右侧控件 | 全行 `Menu` label |
| 非 Form 上下文内联选择（含新建） | `Menu`，label 仅覆盖右侧（值+chevron），左侧标签在 HStack 外 | 全行作为 Menu label |
| 破坏性操作确认 | `confirmationDialog` / `.alert` | 自制弹窗 |
| 分享 / 导出 | `ShareLink` / `confirmationDialog` | 自制底部 Sheet |
| 列表批量选择 | `List(selection:)` + 长按进入 `editMode` | 自制 checkbox |
| 导航到详情 | `NavigationLink` | `Button` + 手动 push |
| 删除列表项 | `.onDelete` / 左滑删除 | 自制滑动手势 |
| 全行可点 = 整行是点击区 | 仅用于 `NavigationLink`（有 `>` 箭头） | 把整行作为 `Menu` / `Picker` label |

### 核心心智模型

- **整行可点击 + `>` 箭头** = 语义是"会导航到新页面"，用 `NavigationLink`
- **右侧值 + 小箭头** = 语义是"原地选择"，用 `Picker(.menu)`
- **从底部弹出列表** = 语义是"选择一个操作/确认破坏性行为"，用 `confirmationDialog`
- **Sheet** = 语义是"临时全屏子流程"，不用于简单选值

---

## 奥卡姆剃刀检查清单

在新增任何抽象、协议、层、文件之前，必须能回答这些问题：

1. **这个抽象解决了哪个具体问题？** 如果答案是"未来可能有用"，则不加。
2. **有没有更简单的方式实现同样效果？** Swift 原生能做到的不造轮子。
3. **删掉这一层，代码是否还能正常工作？** 如果是，这层就不应该存在。
4. **这个协议的目的是什么？** 按以下标准判断：
   - **Repository 协议**（有 in-memory ModelContainer 替代测试手段）：不加
   - **跨包边界的服务协议**（无替代测试手段 + 需要依赖方向控制）：必须加
   - **包内使用的类型**：不加，除非有明确的多实现需求
5. **新增文件是否造成"改一个需求需要动 N 个文件"？** N > 3 是警告信号。

---

## Swift / SwiftData 原生优先

> 完整决策记录见 `decisions/ADR-006`（SwiftData 选型理由和被否决方案）。

| 不要 | 要 |
|---|---|
| 手动 NotificationCenter + fetch | `@Query` 响应式更新 |
| 独立 Domain 实体 struct + 映射代码 | `@Model` 直接作为领域对象 |
| Task.detached 绕过 MainActor | `@MainActor` 直接操作 |
| UseCase 透传 Repository 方法 | ViewModel 直接调用 Repository |

### 核心哲学：@Model = 领域对象（2026-03-03 确认）

> 完整决策记录见 `decisions/ADR-001`（含被否决方案和重新评估条件）。

SwiftData 的 `@Model` 是轻量的，不是 NSManagedObject。对于本地优先的单体 App：
- `@Model` 直接就是领域对象，不需要映射为 Domain struct
- Domain struct + `toEntity()` 映射层 = 零收益的纯维护成本
- 每改一个字段最多改 3 个文件是警戒线；Domain 层会把它变成 5+ 个文件

"只有亲手建过重度架构并深受其害的人，才能真正领悟极简的精髓。" — 接受教训，不后悔，继续前进。

---

## @Query 使用原则

### 适合用 @Query 的场景
- 列表展示（LibraryView 全量列表、简单排序）
- 实时聚合统计（Dashboard 里的 totalCount、dueCount）
- 简单条件过滤（按单一字段过滤）

### @Query 失效的三个边界（与代码行数无关，与业务上下文有关）

**原则 A：需要复杂业务规则二次计算时**
数据库层 Predicate 无法表达的逻辑（如遗忘曲线加权推荐、多维算法排序），必须 `Repository.fetch()` + 纯算法处理。

**原则 B：跨多源聚合时**
SwiftData + 网络 API 混合数据，@Query 无法监听网络源。

**原则 C：处于状态机流程中时**
`ReviewViewModel` 是典型反例——复习会话是状态机（展示→评估→保存→切换），任何底层数据库变更不应触发复习界面无序刷新。

### LibraryViewModel 的特殊情况（2026-03-03）
LibraryView 有三维动态过滤（searchText + subjects + tags）+ 分页。Tags 过滤受 SwiftData many-to-many `#Predicate` 限制必须内存端处理，这是**框架限制**，不是业务复杂度。当 SwiftData 完善 many-to-many Predicate 支持后，可重新评估引入 @Query。

---

## 包边界与依赖方向原则（2026-03-13 确立）

> 完整决策记录见 `decisions/ADR-003`（5 包结构）、`decisions/ADR-005`（Infrastructure 隔离）。

### 包划分标准

- 包的划分依据是**职责边界**，不是文件数量
- 每增一个包必须回答：它与现有包的职责区分是什么？
- 包数应与产品功能边界对齐，不硬编码具体数字

### 跨包依赖规则

- 依赖必须**严格单向**，编译器强制守住边界
- 上游包（被依赖方）只暴露**协议和值类型**给下游
- 下游包（依赖方）通过协议访问上游能力，不引用具体实现
- **包内**可以用具体类型；**跨包**必须用协议（Repository 例外，见下方判断标准表）

### 协议的判断标准

> 完整决策记录见 `decisions/ADR-002`（Repository 无协议的理由和重新评估条件）。

| 场景 | 是否需要协议 | 理由 |
|---|---|---|
| SwiftData Repository | 否 | 有 in-memory ModelContainer 替代测试 |
| 跨包服务（文件 I/O、系统框架封装） | 是 | 无替代测试手段 + 依赖方向控制 |
| 包内使用的工具类 | 否 | 无跨包边界需求 |
| DI 容器中暴露的服务 | 是 | ServiceContainer 协议只应引用协议类型 |

---

## 依赖注入原则（2026-03-13 确立）

> 完整决策记录见 `decisions/ADR-004`（含 4 个被否决的反模式和理由）。

### 唯一正确的 DI 模式

```
1. 协议定义在上游包（Core）
2. 具体实现在下游包（Infrastructure；未来拆出 Services 包后亦同）
   // 当前实际：部分具体实现（CaptureDraftService、PDFExportService 等）暂留 Core，待拆包后迁移
3. 组合根（DependencyContainer）构造所有实例 — 唯一被接受的单例
4. 通过 @Environment 注入到 View 层
5. View 传递给 ViewModel — ViewModel 只知道协议
```

### 禁止的 DI 反模式

| 反模式 | 为什么禁止 | 正确做法 |
|---|---|---|
| `.shared` 单例直接调用 | 绕过 DI，隐式全局状态 | 通过 @Environment 注入 |
| ViewModel 默认参数 `= ConcreteType()` | 隐式耦合具体实现 | View 从 @Environment 取，传给 ViewModel |
| View 直接调用服务方法 | 违反 View = 纯渲染 | 通过 ViewModel 调用 |
| `@Environment(ConcreteType.self)` 注入具体类型 | 绕过协议抽象 | 通过 ServiceContainer 协议属性访问 |

**DependencyContainer 是唯一被接受的单例**（组合根，`@MainActor`）。所有其他 `.shared` 单例都是技术债，应逐步迁移到 DI 注入。

---

## 文档治理（2026-03-19 确立）

> **研究基础**：Google g3doc 新鲜度系统、GitLab SSOT 声明、Nygard ADR 不可变快照哲学、
> AWS ADR 生命周期、Martin Fowler 文档形状论。

### 文档分类

| 类型 | 示例 | 新鲜度追踪 | 理由 |
|---|---|---|---|
| **活文档** | architecture.md、infrastructure.md、conventions.md、technical-debt-ledger.md、definition-of-done.md | 加 `Last verified: YYYY-MM-DD` | 会随代码变化而过时 |
| **快照** | decisions/ADR-*.md、session-log.md | 不加新鲜度字段 | ADR 是不可变的时间点决策记录（Nygard 哲学） |
| **产品文档** | product-vision.md、product-requirements.md 等 | 不加 | 产品负责人领域，按发版节奏更新 |
| **Memory** | memory/*.md | 不加 | frontmatter 已含元数据 |

### 三条治理规则

1. **活文档加 `Last verified`**：仅在实际 review 内容与代码一致性后更新日期。改 typo ≠ verified。自动更新 timestamp 会污染信号
2. **ADR 不可变 + Status 生命周期**：`Proposed → Accepted → Superseded`。决策变了就新建 ADR supersede 旧的，不修改原文。加 `implementation: Complete / Partial / Not Started` 和 `verified: YYYY-MM-DD` 字段追踪实施状态
3. **发版前全量扫描**：每次准备 TestFlight/App Store 发布时，扫描所有 `.claude/` 文档是否与代码一致。事件驱动，不设日历节奏（1 人 + AI 团队靠事件驱动更高效）

### SSOT 规则

- **API 签名、配置值**：严格 SSOT，唯一真值在 `infrastructure.md`
- **概念解释、架构概述**：允许摘要性复制 + 指回权威源（阅读体验优先于 DRY）
- **多处提到同一信息时**：标注哪份是权威文档（已有的 `> 上游依赖` 声明即是）

---

## 测试策略（2026-03-19 确立）

> **研究基础**：Kent Beck「Canon TDD」(2023)、DHH「TDD is Dead」(2014)、Beck-DHH-Fowler 三方辩论结论、
> Google Testing Philosophy、Rich Hickey「Simple Made Easy」、Apple WWDC24 Swift Testing、
> SnapDrill 项目实际经验（#347 flaky tests、ADR-002 Repository 无协议）。

### 核心原则

- **测试行为（behavior），不测试实现（implementation）**（Google 测试哲学）
- **好架构比好测试更重要**——"A bad design with a complete test suite is still a bad design."（Rich Hickey）
- **TDD 是方式之一，不是唯一方式**——Beck/Fowler/DHH 三方辩论的共识
- **不为 mock 而加协议**——"test-induced design damage"（DHH）是真实风险，SnapDrill 的 ADR-002 已规避

### 推荐流程

```
需求 → 关键接口草案（仅跨包协议）→ 核心逻辑 TDD → 外围代码补测试 → 接口随实现迭代
```

不是严格线性流程，而是思考方向。写着写着才发现接口该怎么设计是正常的——过早固化接口反而是负担。

### 分层策略：在对的层次用对的方法

| 代码层 | 测试策略 | 理由 |
|---|---|---|
| **纯算法**（SM-2、CSV 转义、间隔计算） | **TDD（test-first）** | 输入输出明确，TDD 回报最高 |
| **ViewModel 状态机**（Review、Capture 等） | **Test-after**（实现稳定后补测试） | 接口在开发中频繁变化，test-first 会产生大量废弃测试 |
| **Repository CRUD** | **Test-after**（用 in-memory ModelContainer） | 行为简单，不需要协议，不需要 mock |
| **跨包协议契约** | **Contract-first**（先写 DocC 契约文档） | 先定义"承诺什么"，再实现 |
| **SwiftUI View** | **不写单元测试** | Preview + 手动验证；测试 View = 测试框架本身 |
| **胶水代码 / 配置** | **不写单元测试** | ROI 太低 |
| **探索性原型** | **不写测试** | 方案不确定时硬写测试只会产生废弃测试，稳定后再补 |

### SwiftData 测试的正确姿势

```swift
// 用 in-memory ModelContainer，不需要 Repository 协议，不 mock SwiftData
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
let repo = ReviewRepository(modelContext: container.mainContext)
```

- **不 mock 你不拥有的类型**（Google 原则）——不 mock SwiftData、不 mock UIKit
- ViewModel 测试直接实例化，注入 in-memory Repository，不经过 SwiftUI

### 禁止事项

- 禁止为了可测试性添加只有一个实现的协议（已有 in-memory 替代手段时）
- 禁止对 SwiftUI View 层写单元测试（用 Preview + Snapshot 替代）
- 禁止在探索阶段强制 test-first（等方案稳定后补测试）
- 禁止追求覆盖率数字而写无价值测试（"几乎不提供价值的测试，可能因脆弱性和 flakiness 产生净负面影响"——Google）

---

## 技术债标记

> 详见 `technical-debt-ledger.md`（架构级技术债台账）
