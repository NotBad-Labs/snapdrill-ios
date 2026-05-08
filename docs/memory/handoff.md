---
last_verified: 2026-05-08
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, branch_change]
---
# Handoff

## 当前接手状态

- **当前主力**：Codex CLI（2026-05-08 接手）
- **上一主力**：DeepSeek v4 Pro（Claude Code CLI 框架，2026-05-07→08）
- **辅审**：Gemini CLI 0.41.2（优先显式 `gemini-3-pro-preview`）
- **主分支**：`develop`（clean）
- **仓库分支**：本地 + 远程 develop/main 纯净

## Boot 序列（新会话必读）

按顺序读取，不要跳过：

| 序号 | 文件 | 为什么读 |
|---|---|---|
| 1 | `STATUS.md` | 项目状态快照 — 当前焦点、Open Issue、阻塞项 |
| 2 | `docs/workflow.md` | 流程规范、DoD、Review 规范 |
| 3 | `docs/principles/coding.md` | 编码规范、并发禁止项 |
| 4 | `docs/principles/testing.md` | 测试规则 |
| 5 | `docs/principles/api-pitfalls.md` | 已知 API 陷阱 |
| 6 | `docs/principles/apple-native.md` | Apple 原生 UI 模式 |
| 7 | `docs/memory/feedback.md` | 项目纪律（所有智能体共遵） |
| 8 | `docs/memory/decisions.md` | 关键决策记录 |

## Phase 2 全链路完工（2026-05-08）

DeepSeek v4 Pro 从 5/7 度假回归起完成 Phase 2 剩余全部工作：

| PR | 内容 | 合并日期 |
|---|---|---|
| #728 | #6 typed throws（节前） | 4/23 |
| #729 | sync: 解除暂停 + 状态同步 | 5/07 |
| #730 | #8a: Data 层并发回归网 9 tests | 5/07 |
| #731 | #8b: DataExecutor actor 根除 #599 死锁 | 5/07 |
| #732 | #7: staged migration V2 模板 | 5/08 |
| #733 | ProfileManager → DataExecutor 迁移 | 5/08 |
| #734 | #710: docaudit 正则鲁棒性加固 | 5/08 |
| #736 | Phase 2.N: DataExecutor 收尾审计修复（生产路径切断旧同步容器残留） | 5/08 |

**#599 死锁** 完整闭环：
workaround (TestModelContainer) → 测试安全网 (#8a) → actor 根因修复 (#8b) → 生产代码迁移 (#733)

## 新增基础设施（本次会话）

- `DataExecutor` actor — 拥有 ModelContainer，createOffMainActor() 消除 MainActor+XPC 死锁
- 5 个 Repository 新增 `init(executor:)`，保留旧 `init(modelContext:)`
- `RepositoryContainer` 新增 `init(executor:)`
- `ProfileManager` 持有 `DataExecutor` + `isUsingInMemoryFallback` + `syncFallbackStatus()`
- 全 Profile 备份路径使用临时 `DataExecutor`，不再从生产路径构造 `PersistenceController`
- `AppRootView` 降级横幅改用 `profileManager.isUsingInMemoryFallback`
- `MigrationPlan` V2 模板文档（Apple SchemaMigrationPlan 官方模式）
- `docaudit.py` LINK_RE 支持 title 语法 + PATH_REF_RE 路径感知约束

## 当前状态 — 零内部阻塞

软件内部所有工作已完成。仅剩外部阻塞：

| 阻塞项 | 说明 | 解锁条件 |
|---|---|---|
| Apple 开发者账号 (#163) | Enrollment 已通过，$99 年费待缴 | 用户缴费 |
| StoreKit 付费墙 (#479) | 需 App Store Connect | ← #163 |
| iCloud CloudKit (#485) | 需 CloudKit Container | ← #163 |
| Word 导出 (#486) | Pro 功能 | ← #163 |
| App Store 提交 (#490) | ASO 文案已预备 | ← #163 |
| TestFlight Build 6 (#161) | 版本 bump + Archive | ← #163 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 真机验证 |

## 环境

- **Xcode**: 26.4 / **Swift**: 6.3 / **iOS**: 26.0+
- **真机**: iPhone 17
- **defaultIsolation**: MainActor.self
- **SwiftLint**: --strict, 218 files, 0 violations
- **测试**: 420 total（418 passed, 2 skipped, AllTests scheme / CI 配置）
- **CI**: Mac mini `ssh admin@192.168.1.224`, self-hosted runner
- **版本号**: `Configs/Shared.xcconfig` 单一来源
- **Build**: 5（TestFlight Internal）

## 工具链

| 工具 | 版本 | 命令 |
|---|---|---|
| Codex CLI | 0.121.0 | `codex` |
| Gemini CLI | 0.41.2 | `gemini -m gemini-3-pro-preview` |
| Node | v25.6.0 | |
| npm | 11.8.0 | |

## 质量门

```bash
swiftlint --strict                    # 0 violations
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'  # 0 errors
xcodebuild test-without-building \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'  # all pass
python3 Scripts/audit/docaudit.py all   # exit 0
```

测试用 AllTests scheme（非 SnapDrill scheme）—— SnapDrillData 是 SPM 包，在 AllTests xctestplan 中。

## 关键架构要点

- **仓库注入链**: DependencyContainer → ProfileManager → RepositoryContainer → @Environment(\.repositories) → ViewModels
- **并发**: defaultIsolation(MainActor) + BackupService(actor) + DataExecutor(actor) + CameraStateActor
- **DataExecutor**: actor 拥有 ModelContainer，nonisolated let container，createOffMainActor() 工厂
- **Repo 双 init**: `init(executor:)` (推荐) + `init(modelContext:)` (向后兼容)
- **ProfileManager**: @Observable，持有 executor + activeContainer + activeRepositories
- **PersistenceController**: 已废弃兼容类型；生产调用路径走 DataExecutor，测试/Preview 可显式传 `ModelContext`

## 基线审计（2026-05-08）

DeepSeek v4 Pro（Claude Code CLI）完成全量基线审计：
- 覆盖：56 文档 + 218 Swift 源文件 + 15 配置/脚本 = ~45,500 行，逐字全读
- 结果：0 Critical / 3 Warning / 8 Info，无阻塞缺陷
- 3 Warning 为代码卫生：NSError→typed throws、PersistenceController 加 deprecated 标记、ProfileManager force_unwrap 消除
- 完整报告：`docs/memory/checkpoints/2026-05-08-baseline-audit.md`

## 三方协作纪律

- **F-008**: Codex/Gemini 接收完全相同任务，只读不写，独立审计
- **F-016**: Codex/Gemini 发现的问题，必须提交回原发现方复核才能合并
- **评分方权重**: Codex 主锚点 / Gemini 守纪律次锚点 / Claude/DeepSeek 实施方自审为参考
- **Retry 阈值**: 综合 < 7.0 或 方差 > 2.5
- **sync PR**: docs-only PR CI 绿后直接合并

## 相关仓库

- [agent-harness](https://github.com/NotBad-Labs/agent-harness) — public, MIT, main
- snapdrill-ios 是 agent-harness 的 consumer（`.agent-harness/` 契约声明）
