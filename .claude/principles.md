# SnapDrill 架构原则

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
- 目标包数：4 个 SPM 包（Core / Data / UI / Features）
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

## 编写代码前的流程

1. 简要说明方案
2. 明确影响的模块
3. 确认并发安全性

## 禁止事项

- 禁止为"可测试性"添加只有一个实现的协议（测试用 in-memory `ModelContainer`）
- 禁止 `@unchecked Sendable`、force unwrap `!`、`any` existentials
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

### Gemini Review 铁律（2026-03-05 确立）

**所有由 Claude 创建的 PR，必须等待 Gemini 自动 review comment 出现后，由用户确认再合并。**

- Gemini Review 由 `.github/workflows/gemini-review.yml` 自动触发（PR opened/synchronize）
- 使用 `ubuntu-latest` runner，不占用 Mac mini 资源
- Review 结果以 comment 形式贴回 PR，🔴 严重问题必须修复后重新提交
- 4 月 1 日 GitHub Pro 生效后，同步启用 Branch Protection（require 1 approval）
