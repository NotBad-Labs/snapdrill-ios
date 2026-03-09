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

## 编写代码前的强制流程（每次必走，无例外）

### 第 0 步：研究声明（非平凡决策必须）

在提出任何方案前，必须先输出研究声明。格式：

```
研究确认：
- Apple 文档：[查了什么 / 不适用（原因）]
- 现有代码库：[找到的参考模式]
- HIG / 行业惯例：[查了什么 / 不适用（原因）]
```

跳过研究 = 违反铁律。用户可随时说「铁律？」要求补充声明。

### 第 1–3 步

1. 简要说明方案
2. 明确影响的模块
3. 确认并发安全性

## 禁止事项

- 禁止为"可测试性"添加只有一个实现的协议（测试用 in-memory `ModelContainer`）
- 禁止 `@unchecked Sendable`、force unwrap `!`、`any` existentials，以下两种场景除外，且须加注释说明理由：
  1. `EnvironmentKey.Value` 为跨模块协议类型（消除 `any` 需打破依赖方向边界，后者是更核心的规则）
  2. 无 associated type / Self 约束的协议作为集合元素类型（`[any PDFExportable]`，框架限制，非设计懒惰）
- 禁止跨 `ModelContext` 写入后立即读取（竞态）
- 禁止在 DEBUG 工具里引入生产级复杂度
- 禁止新增 Domain 层或 DomainKit（已删除，2026-03-03）
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

#### Review 存档

所有 review 结果以 **GitHub PR comment** 形式永久存储，不再保存本地 `.claude/reviews/` 文件。

- 4 月 1 日 GitHub Pro 生效后，同步启用 Branch Protection（require 1 approval）
