---
last_verified: 2026-05-13
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# Codex 交接清单 — 2026-05-08

> 致 Codex CLI：这是你的接手文档。DeepSeek v4 Pro 在 2026-05-07→08 完成了 Phase 2 最后 8 个 PR，
> 软件内部零阻塞。以下是你需要知道的一切。
> 2026-05-08 Codex 接手后补 Phase 2.N 收尾：切断生产调用路径中的旧同步容器残留。

## 第一步：环境检查（3 分钟）

```bash
cd /Users/yiming/Developer/snapdrill-ios
git status                    # 应在 develop，clean
swiftlint --strict            # 218 files, 0 violations
python3 Scripts/audit/docaudit.py all  # exit 0
xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' | tail -1
```

## 第二步：认知加载（按序读）

1. **STATUS.md** → 知道什么完成了、什么阻塞中
2. **docs/memory/handoff.md** → 完整上下文
3. **docs/standards/coding.md** → 并发规则、禁止项
4. **docs/standards/testing.md** → 测试规范
5. **docs/tech/api-pitfalls.md** → 已知陷阱
6. **docs/memory/feedback.md** → 项目纪律

## 第三步：理解当前状态

**Phase 2 全部完成。软件内部零阻塞。**

上次会话完成的工作：
- #599 死锁 根除（DataExecutor actor + createOffMainActor）
- ProfileManager 与全 Profile 备份临时容器迁移到 DataExecutor（生产调用路径不再依赖 PersistenceController）
- staged migration V2 模板（含 Apple 官方文档指导）
- docaudit 正则加固（LINK_RE title + PATH_REF_RE 路径约束）
- Data 层并发回归网 9 tests

**仅剩外部阻塞**（不要推进，只记录）：
- Apple 开发者账号 $99 待缴 → StoreKit/CloudKit/TestFlight 全部阻塞
- #626 QuestionSplittingService 需真机 + Apple Intelligence

## 关键命令

```bash
# 质量门
swiftlint --strict
xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test-without-building -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17'
python3 Scripts/audit/docaudit.py all

# 创建分支和 PR
git checkout -b feat/<description>
# ... 编码 ...验证质量门...
git add <specific files> && git commit -m "<conventional commit>"
git push -u origin <branch>
gh pr create --title "<title>" --body "<body>"

# 合并（CI 绿后）
gh pr merge <number> --squash --delete-branch
```

## 关键文件地图

| 当需要 | 去读 |
|---|---|
| 改 SwiftData 相关 | `DataExecutor.swift`, `Persistence.swift`, `RepositoryContainer.swift` |
| 改 Repository | `ReviewRepository.swift` (模板), 其他 4 个类似 |
| 改 Profile 逻辑 | `ProfileManager.swift` |
| 改测试 | 测试在 `Packages/*/Tests/`，用 Swift Testing (`@Test` / `#expect`) |
| 改 docaudit | `Scripts/audit/docaudit.py` + policy.yaml |
| 查看迁移计划 | `MigrationPlan.swift`（V1 基线 + V2 模板文档） |

## 架构约束（违反会编译报错）

- `defaultIsolation(MainActor)` — 所有代码默认 MainActor
- 禁止手写 `@MainActor`（冗余）
- `nonisolated` 用于跨 actor 的纯值类型（struct/enum）
- `nonisolated(unsafe)` 仅用于 Apple SDK 类型（需附注释说明理由）
- ViewModel: `@Observable final class`
- Task 闭包内禁止直接访问 MainActor 属性（需 `let local = prop` 捕获）
- SwiftData ModelContext 非 Sendable，Repository 在 MainActor 使用

## DataExecutor 使用模式

```swift
// 生产代码（磁盘存储，MainActor 安全）
let executor = DataExecutor(storeURL: storeURL)
let repos = RepositoryContainer(executor: executor)

// 测试代码（内存，createOffMainActor 避免 #599）
let executor = await DataExecutor.createOffMainActor(inMemory: true)
let repos = RepositoryContainer(executor: executor)

// 获取 ModelContext（在 MainActor 上）
let ctx = executor.container.mainContext
```

## 三方协作（你作为主力时的规则）

- 你是 **Codex 主锚点**：写代码 + 自审
- **Gemini CLI** 是次锚点：独立审查，不写代码
- F-008: Gemini 接收与你完全相同的任务
- F-016: Gemini 发现问题后，必须由 Gemini 复核你的修复
- sync 类 docs-only PR：CI 绿后直接合并

## 如有疑问

- 项目决策：`docs/memory/decisions.md`
- 历史 checkpoint：`docs/memory/checkpoints/`
- agent-harness 抽仓理由：`docs/memory/decisions.md` D-003
- DeepSeek 会话记录：Claude Code transcript（本会话上下文）

---

> 📝 由 DeepSeek v4 Pro 编写，2026-05-08 收工前交接
