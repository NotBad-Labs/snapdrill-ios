# SnapDrill 架构原则

## 决策前研究铁律（2026-03-06 确立，永不变更）

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

## Apple 原生优先铁律（2026-03-06 确立，永不变更）

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
4. **这个协议有几个实现？** 只有一个实现的协议，通常是不必要的。
5. **新增文件是否造成"改一个需求需要动 N 个文件"？** N > 3 是警告信号。

## Swift / SwiftData 原生优先

| 不要 | 要 |
|---|---|
| 手动 NotificationCenter + fetch | `@Query` 响应式更新 |
| 独立 Domain 实体 struct + 映射代码 | `@Model` 直接作为领域对象 |
| 只有一个实现的 Repository 协议 | 具体 Repository 类 |
| Task.detached 绕过 MainActor | `@MainActor` 直接操作 |
| UseCase 透传 Repository 方法 | ViewModel 直接调用 Repository |

### 核心哲学：@Model = 领域对象（2026-03-03 确认）

SwiftData 的 `@Model` 是轻量的，不是 NSManagedObject。对于本地优先的单体 App：
- `@Model` 直接就是领域对象，不需要映射为 Domain struct
- Domain struct + `toEntity()` 映射层 = 零收益的纯维护成本
- 每改一个字段最多改 3 个文件是警戒线；Domain 层会把它变成 5+ 个文件

"只有亲手建过重度架构并深受其害的人，才能真正领悟极简的精髓。" — 接受教训，不后悔，继续前进。

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

## 技术债标记

**`NotificationCenter.reviewDataDidChange`**：跨模块刷新通知。当 @Query 被引入到更多 View 后，大部分通知调用会自然消解（SwiftData 自动响应写入）。这是有意为之的渐进式清理路径，不是设计缺陷。

## 这个 app 的合理规模感

- 功能：Capture / Library / Review / Dashboard / Settings（5个）
- 用户：单用户，本地优先，无后端
- 目标包数：5 个 SPM 包（Core / Data / UI / Features / Infrastructure）
- 每新增一个字段，最多改动 3 个文件

## 并发规则

- Swift 6 strict concurrency，优先 actor isolation，不用锁
- 所有 ViewModel：`@Observable @MainActor final class`
- Prefer async/await；`Task` 必须保存句柄，禁止 fire-and-forget

## 依赖注入

- 依赖通过 SwiftUI `@Environment` 注入，不散落在 View 构造器
- `DependencyContainer` 是唯一被接受的单例（组合根，`@MainActor`，明确理由）
- 禁止其他全局状态

## View 层约束

- View = 纯渲染，不含业务逻辑，不做网络/持久化调用
- 状态全部在 ViewModel 中

## 角色换帽制度（2026-03-11 确立，同日扩展至九顶帽子）

> **设计原理**：独立开发者最大的风险是「同一个人在同一时刻只戴一顶帽子」。
> 完整的产品开发链路包含市场→产品→设计→工程→质量→运维→数据七层，
> 每一层都有不同的首要优化目标。帽子制度强制在不同阶段激活对应视角，
> 防止所有决策都混在「写代码」这一步里。

### 九顶帽子

| 帽子 | 对应层 | 核心问题 | 首要优化目标 |
|---|---|---|---|
| 市场分析师 | 市场/商业 | 「竞品怎么做？行业趋势如何？定价合理吗？」 | 机会识别、差异化定位 |
| 产品经理 | 产品 | 「这解决用户的什么问题？不做会怎样？」 | 用户价值、需求优先级 |
| UX 设计师 | 设计 | 「信息层次对吗？交互流程自然吗？注意力引导合理吗？」 | 交互流畅性、信息架构 |
| 架构师 | 工程 | 「删掉方案的一半，还能解决问题吗？」 | 解耦、可维护性 |
| 开发者 | 工程 | 「最简实现是什么？」 | 极简、正确 |
| QA / 魔鬼代言人 | 质量 | 「用户在什么情况下会触发异常路径？」 | 健壮性、边界覆盖 |
| DevOps | 运维 | 「构建/测试/发布流程有卡点吗？自动化够吗？」 | 流程效率、发布可靠性 |
| 数据分析师 | 数据 | 「我们在度量什么？数据支持这个决策吗？该埋什么点？」 | 数据驱动、可量化 |
| 用户代言人 | 贯穿 | 「35 岁妈妈第一次用，会困惑吗？」 | 真实使用体验 |

### 全链路流转

```
市场分析师 → 产品经理 → UX 设计师 → 架构师 → 开发者 → QA → DevOps → 数据分析师
     ↑                                                                    │
     └────────────────────── 反馈循环 ──────────────────────────────────────┘
                        用户代言人（贯穿全程）
```

### Claude 的换帽规则

**每次回复前，Claude 必须先判断当前对话需要哪顶帽子，并在回复开头标注。**

标注帽子 = 激活该角色的首要优化目标，思考路径必须与角色吻合。

格式（简洁，一行即可）：
```
[帽子：架构师] ...
```

换帽时机：
- 讨论新功能是否值得做、竞品如何、定价 → **市场分析师帽**（授权使用 WebSearch 进行调研）
- 用户提出需求/想法 → **产品经理帽**，追问「为什么要做、不做会怎样」
- 涉及页面布局、导航流程、信息层次、状态转换 → **UX 设计师帽**
- 用户确认要做 → **架构师帽**，提出最简方案 + 研究声明（第 0 步归属架构师）
- 方案确认后 → **开发者帽**，实现代码
- 开发中发现深水区（预期外的复杂度、框架限制、并发陷阱）→ 主动停下，换回**架构师帽**重新评估，切忌在开发者模式下强行糊代码
- 代码写完后 → **QA 帽**，自检异常路径
- CI/CD 配置、发版流程、环境问题 → **DevOps 帽**
- 功能上线评估、埋点设计、指标定义 → **数据分析师帽**
- 涉及 UI/UX 改动的最终确认 → **用户代言人帽**，从家长视角审视

允许在同一次回复中切换视角，但**必须分段并重新标注帽子**，确保视角的物理隔离。禁止同一段文字中思维混杂。

## 编写代码前的强制流程（每次必走，无例外）

### 第 0 步：研究声明（归属架构师帽）

详见本文件顶部「决策前研究铁律」章节（含研究流程、判断框架、输出格式）。

### 第 1–3 步

1. 简要说明方案
2. 明确影响的模块
3. 确认并发安全性

## 编码规范（唯一定义，CLAUDE.md 指向此处）

**日志**
- 使用 `SnapDrillLogger`（封装 `os.Logger`），禁止 `print()`

**错误处理**
- 关键路径（save/init）：禁止 `try?`，必须 `do/catch`
- 清理路径（delete temp file）：允许 `try?`，但必须加日志或注释 `// best-effort: [原因]`

**代码组织（MARK 顺序）**
1. `// MARK: - Properties`
2. `// MARK: - Initialization`
3. `// MARK: - Public API`
4. `// MARK: - View Body / Lifecycle`
5. `// MARK: - Private Helpers`
6. `// MARK: - Preview`

**文件头**
每个文件必须有标准 Xcode 版权头 + 一行功能描述：
```swift
//  一句话描述该文件的功能。
```

**注释**
- 全部使用简体中文
- `public` API 用 DocC（`///`）+ 中文描述；参数名可保留英文
- `private`/`internal` 用 `//` 即可

**孤儿功能禁止**
每个 Repository 方法或 ViewModel 公开属性必须有明确的 UI 调用链。已实现但 UI 未接入的须标记 `// TODO: UI Integration Pending`。

## 禁止事项

- 禁止为"可测试性"添加只有一个实现的协议（测试用 in-memory `ModelContainer`）
- 禁止 `@unchecked Sendable`、force unwrap `!`、`any` existentials，以下两种场景除外，且须加注释说明理由：
  1. `EnvironmentKey.Value` 为跨模块协议类型（消除 `any` 需打破依赖方向边界，后者是更核心的规则）
  2. 无 associated type / Self 约束的协议作为集合元素类型（`[any PDFExportable]`，框架限制，非设计懒惰）
- 禁止跨 `ModelContext` 写入后立即读取（竞态）
- 禁止在 DEBUG 工具里引入生产级复杂度
- 当前阶段不需要 Domain 层 / UseCase 层 / Repository 协议（已删除，2026-03-03）。未来出现明确信号（跨平台复用、多 Repository 实现、复杂业务编排）时重新评估
- 禁止用值类型 struct 作领域对象（`@Model` 必须是 class）

## Git 工作流规范（2026-03-04 确立）

### 分支结构

```
main      ← 生产环境（App Store），只接受来自 develop 的 PR，每次发布打 tag
develop   ← TestFlight 集成分支，只接受来自 feature/fix/chore 分支的 PR
feat/xxx  ← 新功能，从 develop 分叉
fix/xxx   ← Bug 修复，从 develop 分叉
chore/xxx ← 工具/配置/发布，从 develop 分叉
hotfix/xxx← 紧急修复，从 main 分叉，PR 合并到 main + develop
```

### 铁律

- **禁止直接向 `develop` 或 `main` 提交任何内容**（commit / push / merge）
- 每个任务必须：建 Issue → 建分支 → 改代码 → PR → CI → 合并
- PR 必须关联 Issue（`Closes #N`）
- 发布到 App Store 时：develop → PR → main → 打 tag（v1.x.0）

### 每次任务 SOP

```bash
git checkout develop && git pull          # 基于最新 develop
gh issue create                           # 建 Issue
git checkout -b fix/xxx                   # 新建工作分支
# 改代码...
swiftlint --strict && xcodebuild build    # 本地验证
git add <具体文件>                         # 精确 stage
git commit -m "fix: ... Closes #N"
git push -u origin fix/xxx
gh pr create --base develop               # 建 PR，触发 Mac mini CI + Gemini Review
```

### Code Review 铁律（2026-03-05 确立，2026-03-07 更新）

**所有由 Claude 创建的 PR，必须完成三方 review 后，由用户确认再合并。**

#### 1. Gemini GitHub Action（自动，diff 级别）

- 由 `.github/workflows/gemini-review.yml` 自动触发（PR opened/synchronize）
- 使用 `ubuntu-latest` runner，不占用 Mac mini 资源
- 只看 diff，可能因缺乏上下文产生误判（如看不到文件头部的 `@Observable` 标注）
- Review 结果以 PR comment 形式自动贴回
- **Claude 负责主动轮询**（`gh pr view --comments`），不得要求用户通知

#### 2. Antigravity 全量 Review（手动，全代码库级别）

- Claude 撰写包含架构约束的 review 提示词，用户在 Antigravity IDE 中触发
- 可访问完整代码库，误判率低于纯 diff review
- Review 完成后，将结果以 comment 形式**手动发布到对应 GitHub PR**（不保存本地文件）

#### 3. Claude 独立核实（每条 finding 必走）

无论 Gemini 还是 Antigravity 的结论，Claude 必须独立核实后再给出判断：
1. 读源文件确认问题是否真实存在
2. 对照 CLAUDE.md 确认是否属于已批准例外
3. 必要时查 Apple 文档或 Swift 规范

#### 判断规则

- 三方均无 🔴 严重问题 → 可合并
- 任一方有 🔴 → 修复后重新提交，重新触发 review 循环
- Gemini 与 Antigravity 结论冲突 → 以 Antigravity 为准（上下文更完整），但 Claude 须独立核实，不可盲从

#### fix 提交后的 re-review 规则（2026-03-07 确立）

修复提交推送后：

**Gemini**：自动重新触发，Claude 主动轮询确认，无需用户干预。

**Antigravity 二次 review**：
- **需要**：fix 引入新业务逻辑、新跨模块依赖、新文件（非纯结构性）
- **不需要**：纯结构性修复（文件拆分/重命名、访问控制修饰符、import 调整），且 Gemini re-review 无 🔴，Claude 已独立核实
- Claude 须在 PR comment 或回复中说明"不需要二次 review"的理由，用户最终确认合并

**验收铁律**：reviewer 提出建议 → 开发者采纳修改 → **必须让同一 reviewer 验收实现是否符合意图**。这是验收，不是自审。禁止以「采纳了 reviewer 自己的建议所以不需要 re-review」为由跳过验收。

#### Review 存档

所有 review 结果以 **GitHub PR comment** 形式永久存储，不再保存本地 `.claude/reviews/` 文件。

- 4 月 1 日 GitHub Pro 生效后，同步启用 Branch Protection（require 1 approval）

#### Review 发现的技术债追踪铁律（2026-03-10 确立）

**每次 PR review 核实后，凡是"有效但不在本 PR 范围"的问题，必须立即创建 GitHub Issue 追踪。禁止只说"不采纳"就丢掉。**

具体流程：
1. Claude 独立核实每条 review finding
2. 对于判定为"真实问题，但不属于本 PR 范围"的 finding，**必须在合并前创建 Issue**
3. Issue 标题格式：`chore: {问题描述}`，body 中注明来源 PR 编号和 review 原文
4. 相似主题的 finding 合并为一个 Issue（避免碎片化）
5. PR 合并 comment 或回复中列出新建的 Issue 编号，形成闭环

**违反后果**：技术债无追踪 = 技术债不存在 = 永远不会修复。这比 review 本身不发现问题更危险。

## 工作优先级框架（2026-03-11 重写，取代原「金字塔铁律」）

> **设计原理**：优先级不是功能模块的属性，而是「用户失去了什么」的函数。
> 备份里的数据丢失和采集里的保存失败是同一严重度，不因模块归属不同而区别对待。
>
> 本框架从用户真实使用流程推导而来（参见 `product.md` 旅程 1-5），
> 并参考 ISO 25010:2023（质量分类法）、Google SRE SEV levels、PagerDuty SEV-1~5、Microsoft SDL Bug Bar。

### 严重度分级（唯一排序轴）

按「用户失去了什么」从重到轻，共四级：

| 级别 | 含义 | 判定标准 | 举例 |
|---|---|---|---|
| **S0 数据丢失** | 用户数据不可逆丢失或损坏 | 保存/备份/同步/恢复流程中数据消失或损坏，用户无法自行恢复且无法重试 | 采集保存失败静默丢弃（用户已离开页面）、备份文件损坏、恢复覆盖后数据不完整、编辑保存失败且状态未保留、并发竞争导致数据库写入错乱 |
| **S1 流程阻断** | 用户完全无法完成某个任务 | 核心流程崩溃或关键功能完全不可用，无合理绕过方式 | 采集流程崩溃、题库列表加载不出来、搜索完全无结果且手动翻列表也找不到、PDF 导出失败（考前急用）、保存失败但弹窗提示且状态保留可重试、OOM/ANR 导致 App 被系统杀死 |
| **S2 体验受损** | 能完成但有明显摩擦 | 功能可用但结果不准确、性能差、或需要额外步骤绕过 | OCR 识别率低需大量手动修正、搜索不准但手动翻列表能找到、过滤结果不准、复习间隔计算偏差、错误信息暴露系统内部细节（隐私摩擦）、卡顿但不崩溃 |
| **S3 打磨优化** | 更好但不紧急 | 不影响任何任务完成，属于体验提升或代码质量改进 | Dashboard 统计数字偏差、设置页布局优化、轻微掉帧、测试覆盖补充、代码可维护性重构、理论上可能但实际未触发的并发风险 |

**S0 vs S1 的关键区分**：用户操作的结果是否还在（内存/UI 状态中）。如果用户还能重试 = S1；如果数据已不可逆消失 = S0。

### 同严重度内的排序规则

当多个问题处于同一严重度时，按**用户流程频率**排序——高频流程中的问题优先：

```
采集（每天多次）> 查找/管理（每周多次）> 导出/备份（偶发但后果重大）> 复习（因人而异）> 设置/外观（极少）
```

注意：这个频率排序**仅用于同严重度内的 tiebreaker**。S0 级的备份数据丢失永远优先于 S2 级的采集 OCR 不准。

### 判级示例

| 场景 | 模块 | 严重度 | 理由 |
|---|---|---|---|
| `try?` 静默吞掉保存错误，用户已离开页面 | 采集 | S0 | 数据不可逆丢失 |
| 备份文件写入损坏 | 备份 | S0 | 用户以为有备份实际没有 |
| 恢复后部分图片丢失 | 备份 | S0 | 不可逆数据丢失 |
| 并发竞争导致数据库写入错乱 | 全局 | S0 | 数据损坏 |
| 编辑题目后保存失败，状态未保留 | 管理 | S0 | 补的答案不可逆丢失 |
| 采集保存失败，弹窗提示且状态保留可重试 | 采集 | S1 | 流程阻断但数据仍在内存 |
| 采集流程崩溃 | 采集 | S1 | 无法完成最核心任务 |
| 搜索和手动翻列表都找不到已有题目 | 管理 | S1 | 所有入口都无法触达 |
| PDF 导出失败 | 导出 | S1 | 考前急用导不出 |
| 复习界面崩溃 | 复习 | S1 | 功能不可用 |
| OOM / ANR 导致 App 被系统杀死 | 全局 | S1 | 等同崩溃 |
| OCR 识别率低 | 采集 | S2 | 手动改一下，能忍 |
| 搜索不准但手动翻列表能找到 | 管理 | S2 | 有合理绕过方式 |
| 过滤结果不准 | 管理 | S2 | 手动翻一翻 |
| SM-2 间隔计算偏差 | 复习 | S2 | 用户短期无感知 |
| 错误信息暴露系统内部细节 | 全局 | S2 | 隐私摩擦，非数据泄露 |
| Dashboard 数字偏差 | 仪表盘 | S3 | 不影响任何功能 |
| 列表轻微掉帧 | 全局 | S3 | 不影响任务完成 |
| 设置页 UI 细节 | 设置 | S3 | 纯打磨 |
| 测试覆盖补充 | 全局 | S3 | 代码质量改进 |
| 理论并发风险（未实际触发） | 全局 | S3 | 预防性改进 |

### 执行规则

1. **严重度优先**：S0 全部处理完毕后方可处理 S1，依此类推
2. **Fast-Track 例外**：当高级别 issue 因调研或等待上游而阻塞时，允许利用阻塞期间快速修复（Quick Win）低级别 issue。阻塞解除后必须立即回到高级别
3. **状态声明**：每次开始一个 issue 前，输出当前严重度级别的完整状态：
   ```
   === S{N} 状态（{级别名}）===
   ✅ #xxx — {已完成的}
   🔄 #xxx — {当前正在做的}
   ⏳ #xxx — {待做的}
   🚫 #xxx — {blocked，原因：...}
   ```
4. **级别清零确认**：一个级别全部完成后，输出清零声明，用户确认后进入下一级别
5. **新发现问题归级与中断**：工作中新发现的问题，按严重度归级。发现 S0 时必须立即中断当前工作评估影响；发现 S1 时评估是否需要中断。中断时在状态声明中标注 `[Interrupted by #xxx]`
