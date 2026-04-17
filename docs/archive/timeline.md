---
last_verified: 2026-04-13
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, issue_change, milestone_change]
---
# Timeline

| 日期 | 事件 | 证据 |
|---|---|---|
| 2026-04-09 | 四层基线审计启动，进入跨 agent 交叉验证周期 | `git log`（`8cbce147` 起） |
| 2026-04-10 | 创建 Issue `#578`，要求 Codex 独立全量审计 Claude 审计质量 | <https://github.com/NotBad-Labs/snapdrill-ios/issues/578> |
| 2026-04-10 | ATT 授权链路移除落地（PR #577 合并） | commit `25262f28` |
| 2026-04-11 上午 | 文档基线重构推进：`PRD` 建立、`docs/tech/design/` 建立、`architecture/api-reference/STATUS` 降级为映射或快照层 | 工作区改动 + `STATUS.md` 当前焦点 |
| 2026-04-11 | Codex 正式接手：读取项目文档、Issue 列表、关键代码（DeletionScheduler）并建立 `docs/memory/` | 本目录提交记录 |
| 2026-04-11 | 文档依赖治理落地：新增 `docs/DOC_DEPENDENCY_MAP.md`，补齐多份文档上游依赖声明并接入 `README/workflow/KNOWLEDGE_MAP` | 当前工作区改动 |
| 2026-04-11 | 产品文档分批重构启动：新增（现归档）`docs/archive/2026-04-baseline-v1/product/PRODUCT_DOC_REFACTOR_PLAN.md`，并按“内容语义优先”修复首个口径冲突（Analytics 默认值） | 当前工作区改动 |
| 2026-04-11 | 完成产品文档首轮一致性审读：新增（现归档）`docs/archive/2026-04-baseline-v1/product/PRODUCT_DOC_AUDIT_20260411.md`，修复口径残留与实现细节泄漏 | 当前工作区改动 |
| 2026-04-11 | Phase 2 批次推进：`requirements/cases/design/glossary/journeys` 完成第二轮“实现细节降噪” | 当前工作区改动 |
| 2026-04-11 | Phase 3 回归完成：新增 `docs/product/README.md` 与（现归档）`docs/archive/2026-04-baseline-v1/product/PRODUCT_DOC_PHASE3_REGRESSION_20260411.md`，并修复 COPPA memo 残留口径 | 当前工作区改动 |
| 2026-04-11 | 仓库级文档治理收口：新增（现归档）`docs/archive/2026-04-baseline-v1/DOC_GOVERNANCE_CLOSURE_20260411.md`，明确“仅治理第一方文档，第三方开源文档排除”并完成链接/路径校验 | 当前工作区改动 |
| 2026-04-12 | `#574` 本地修复落地：DeletionScheduler 改为可抛错执行器 + `commitImmediately` 返回可等待句柄，并新增 `DeletionSchedulerTests` 草案；`LibraryViewModel` 删除批处理改为聚合失败并抛错 | 当前工作区改动 + `xcodebuild build -scheme SnapDrill` 成功 + `xcodebuild test -scheme SnapDrillFeaturesTests -only-testing:LibraryViewModelTests` 通过 |
| 2026-04-12 | 文档治理 Phase 2 收口：统一 Gemini sandbox 规则冲突；将 `.claude/worktrees/**` 明确排除出治理范围；建立三段遍历执行基线（现归档）`docs/archive/2026-04-baseline-v1/memory/repo-traversal-plan.md` | 当前工作区改动 |
| 2026-04-12 | Phase 3 Batch A 启动并完成首个代码修复：`DeletionScheduler.scheduleDeletion` 对空输入改为 no-op，并补充对应单测；iOS 构建通过 | 当前工作区改动 + `xcodebuild build -scheme SnapDrillCore` 成功 + `xcodebuild build -scheme SnapDrill` 成功 |
| 2026-04-12 | 建立风险追踪 issue：`#579`（Share Extension 主线程图片读取）与 `#580`（AppActivityTracker 调用链补全） | <https://github.com/NotBad-Labs/snapdrill-ios/issues/579> / <https://github.com/NotBad-Labs/snapdrill-ios/issues/580> |
| 2026-04-12 | Phase 3 Batch B 启动：完成 `SnapDrillData/SnapDrillUI` 首轮静态扫描，产出（现归档）`docs/archive/2026-04-baseline-v1/memory/code-audit-batch-b-20260412.md` | 当前工作区改动 |
| 2026-04-12 | Batch B 发现项建单：`#581`（Data 层静默失败路径治理，ProfileManager/ProfileMigration） | <https://github.com/NotBad-Labs/snapdrill-ios/issues/581> |
| 2026-04-12 | 记忆层精简：删除 `.claude/compact-reminder.md`，并将工具私有记忆（Auto Memory / session-log）口径统一为“默认排除治理输入” | 当前工作区改动 |
| 2026-04-12 | Batch B 第二轮完成并落地首批修复：`ProfileManager/ProfileMigration/RepositoryContainer` 失败路径改为显式日志；`OnboardingManager` 去除 `try?` 静默吞错 | 当前工作区改动 + `xcodebuild build -scheme SnapDrillData` 成功 + `xcodebuild build -scheme SnapDrillUI` 成功 |
| 2026-04-12 | Batch C1 启动并完成首批修复：Capture 链路静默失败点（PDF 读取、Vision 执行、孤儿图清理）补齐可观测日志 | 当前工作区改动 + `xcodebuild build -scheme SnapDrillFeatureCapture` 成功 |
| 2026-04-12 | Batch C1 第二轮完成并收口：修复 Dashboard 监听生命周期缺口（离开页面取消监听后重新进入不恢复）并将 SwipeCard 动画回调切换为可取消 Task | 当前工作区改动 + `xcodebuild build -scheme SnapDrill` 成功 |
| 2026-04-12 | Batch C2 首轮启动并完成首批修复：Library/Settings 的 Profile 删除、缓存清理、备份文件清理、头像导入、ZIP 导出预清理补齐可观测日志 | 当前工作区改动 + `docs/archive/2026-04-baseline-v1/memory/code-audit-batch-c2-20260412.md` + `xcodebuild build -scheme SnapDrill` 成功 |
| 2026-04-12 | `SnapDrillFeaturesTests` 回归通过：先发现 Dashboard 监听启动时机测试失败，兼容修复后 125 tests 全量通过 | `xcodebuild test -scheme SnapDrillFeaturesTests`（iPhone 17） |
| 2026-04-12 | `#579` 代码落地：Share Extension 入站图片读取/解码迁移后台线程，主线程仅保留路由更新，并补齐异常日志 | 当前工作区改动 + `SnapDrill/App/AppRouter.swift` + `xcodebuild build -scheme SnapDrill` 成功 |
| 2026-04-12 | `#580` 代码落地：AppActivityTracker 增加同类活动引用计数并接线 Capture/Export/Print/BackupRestore 关键链路 | 当前工作区改动 + `AppActivityTracker.swift` + 多个 Feature ViewModel |
| 2026-04-12 | `#581` 第二阶段落地：`ProfileManager.createProfile` 改为 must-succeed（失败回滚并上抛），调用方接入显式错误处理 | 当前工作区改动 + `ProfileManager.swift` + `ProfileListView.swift` + `SettingsViewModel.swift` |
| 2026-04-12 | Batch D 首轮完成：全仓 TODO/FIXME 可信度复核，新增（现归档）`docs/archive/2026-04-baseline-v1/memory/code-audit-batch-d-20260412.md` | 当前工作区改动 + `rg TODO/FIXME` 结果 |
| 2026-04-12 | 向 `#579/#580/#581` 回写实现进展评论并附验证命令 | issue comments `4231560902/4231561741/4231562417` |
| 2026-04-12 | 向 `#579/#580/#581` 追加第二轮验收评论：同步 `#581` 第三阶段结果与 128 tests 回归 | issue comments `4231740926/4231740873/4231740208` |
| 2026-04-12 | 向 `#579/#580` 追加“保持 OPEN、待手工回归”评论 | issue comments `4231749097/4231748840` |
| 2026-04-12 | 按验收结论关闭 `#581`（Data 层静默失败治理） | <https://github.com/NotBad-Labs/snapdrill-ios/issues/581> |
| 2026-04-12 | `#581` 第三阶段落地：`ProfileMigration` 建立 must-fail / best-effort 分层，失败时清理半成品目录，fallback 创建结果显式判定并记录日志 | 当前工作区改动 + `Packages/SnapDrillData/Sources/SnapDrillData/ProfileMigration.swift` |
| 2026-04-12 | `AppActivityTracker` 行为测试可执行化：测试从 `SnapDrillCoreTests` 迁移到 `SnapDrillFeaturesTests`，`xcodebuild test` 回归提升至 128 tests | 当前工作区改动 + `Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/AppActivityTrackerTests.swift` |
| 2026-04-12 | 回归验证刷新：`SnapDrillFeaturesTests`（128 tests）通过，`SnapDrill` 构建通过 | `xcodebuild test -scheme SnapDrillFeaturesTests` + `xcodebuild build -scheme SnapDrill` |
| 2026-04-12 | `#580` 自动化验收增强：补充 `switchBlockReason` 聚合断言与 `ProfileSwitchBlockingTests`，`SnapDrillFeaturesTests` 基线提升至 130 tests | 当前工作区改动 + `AppActivityTrackerTests.swift` + `ProfileSwitchBlockingTests.swift` + `xcodebuild test -scheme SnapDrillFeaturesTests` |
| 2026-04-12 | `#579` 补充可复现回归：`SIMCTL_CHILD_SNAPDRILL_SHARE_TEST_FILE` 启动注入可消费删除大图；`simctl openurl snapdrill://share?file=...` 路径在当前环境仍未稳定复现同结果，issue 保持 OPEN | simulator 命令记录（`simctl launch/openurl` + 共享容器文件存在性检查） |
| 2026-04-12 | 向 `#579/#580` 回写续轮状态评论：同步“DEBUG 注入通过、openurl 路径不稳定”与“阻断语义自动化增强” | issue comments `4233274974/4233275816` |
| 2026-04-12 | `#574` 收口修复：`LibraryViewModel.refreshData/loadMore` 增加 pending 删除过滤，`cancelTasks` 不再清空恢复材料，并新增 2 条回归测试 | 当前工作区改动 + `LibraryViewModel.swift` + `LibraryViewModelTests.swift` |
| 2026-04-12 | 关闭 `#574`：定向回归 `LibraryViewModelTests`（13 tests）通过后关单 | <https://github.com/NotBad-Labs/snapdrill-ios/issues/574> |
| 2026-04-13 | 文档执行入口迁移：新增 `CODEX.md`，删除 `CLAUDE.md`，并建立 `docs/agent/README.md` + `docs/agent/CODEX_BASELINE_20260413.md` | 当前工作区改动 |
| 2026-04-13 | 规则文档迁移完成：`.claude/rules/*.md` 全量迁入 `docs/agent/rules/*.md`，`workflow/KNOWLEDGE_MAP/DOC_DEPENDENCY_MAP` 引用同步 | 当前工作区改动 |
| 2026-04-13 | 历史技能文档清理：`.claude/skills/**/*.md` 删除为 0；发布检查单迁移到 `docs/agent/references/release-checklist.md` | 当前工作区改动 |
| 2026-04-13 | 建立里程碑 `Codex Baseline v1（文档治理）`（milestone #2，due 2026-04-20） | <https://github.com/NotBad-Labs/snapdrill-ios/milestone/2> |
| 2026-04-13 | 建立里程碑主 issue `#583` 并将 `#578` 归入该里程碑 | <https://github.com/NotBad-Labs/snapdrill-ios/issues/583> / <https://github.com/NotBad-Labs/snapdrill-ios/issues/578> |
| 2026-04-13 | **项目主权重组定稿（PR #587）**：回滚 Codex 的 `docs/agent/` 方案，建立 `docs/principles/` 为 agent-agnostic 唯一规则源。CLAUDE.md/CODEX.md 恢复为对称指针。`.claude/rules/` 保留为薄指针。上方第 46-48 行记录的操作（删除 CLAUDE.md、迁入 docs/agent/、清理 skills）已被本次重组取代，未进入 develop | <https://github.com/NotBad-Labs/snapdrill-ios/pull/587> |
| 2026-04-13 | 关闭 PR #582/#584/#585：历史分支清零，以 #587 为新基线向前推进 | 用户决策 |

## 待补时间线（下次更新）

- `#574` 修复 PR 编号与验证结果
- Apple 账号阻塞解除时间（影响 `#479/#485/#486/#490/#161`）
