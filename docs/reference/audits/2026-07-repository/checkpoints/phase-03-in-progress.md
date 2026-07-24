# Phase 03 In-Progress Checkpoint

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Pause State

- paused_at: `2026-07-10`（PO 临时暂停）
- product base: `origin/develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- audit worktree: `/private/tmp/snapdrill-repository-audit`
- branch: `codex/repository-audit-program`
- phase start HEAD: `0b3c1349511fc7e59a415b15b3d592b50f8775e6`
- 主 checkout 仍为 `develop@d62fead8`，仅有原有未跟踪 `agent-reports/`；未触碰
- Phase 03 未完成，不得把下列 candidate 当作 verified finding

## Inventory Completed

- 4 个 SPM package：Core、Data、UI、Features
- production package targets：Core ×1、Data ×1、UI ×1、Feature ×5
- package test targets：4
- native Xcode targets：SnapDrill、SnapDrillUITests、SnapDrillShare、SnapDrillShareTests
- production Swift files：Core 58、Data 28、UI 16、Capture 19、Library 23、Review 12、Dashboard 8、Settings 21
- compile graph：无 cycle / reverse edge；Core 无第三方 package；Share Extension 无 SnapDrill package import
- third-party ownership：Mantis → UI；ZIPFoundation → Data；SnapshotTesting 仅 Features test target

## Briefs

- `phases/03a-dependency-graph-brief.md`
- `phases/03b-runtime-flow-brief.md`
- `phases/03c-abstraction-debt-brief.md`

三个 brief 已完成并保持只读边界；没有产品代码改动。

## Reviewer Progress

- Claude Fable 5：03a / 03b / 03c 全部完成，只读。
- Antigravity `Gemini 3.5 Flash (High)`：03a / 03b 完成；第一次参数误解析的输出已作废；03c 第一次执行报错，第二次在 PO 暂停时终止，未完成。
- Grok 4.5：尚未启动。
- Codex C1：完成 graph/import/DI 初步 inventory；尚未完成 candidate 复现、去重和 severity 裁决。
- raw agent output 未入仓；下方只保存可续跑的 candidate 摘要。

## Candidate Queue

| Candidate | Current claim | Required C1 verification |
|---|---|---|
| CAND-03-001 | App target 直接 import Core/Data/UI，但 `packageProductDependencies` 只列 5 个 Feature products | 检查 explicit-module/build behavior，确认是可修声明缺口而非 Xcode 合法产品传递语义 |
| CAND-03-002 | `ProfileManagerKey.defaultValue = ProfileManager(inMemory: true)` 的构造会清标准 UserDefaults Profile keys；SwiftUI environment setter 可能在生产注入时触发 getter | 用独立 SwiftUI key-path setter probe 证明求值顺序，再核对真实冷启动/测试；未复现前不得定 P1 |
| CAND-03-003 | `ProfileManager.switchProfile` 只检查 `AppActivityTracker.shared`，注入非 shared tracker 时守卫失效 | 写最小独立实例测试或现有测试证据；区分 production 默认同一性与 test seam 缺陷 |
| CAND-03-004 | ServiceContainer 的 ocr/captureDraft/contentTagging/questionSplitting/reviewScheduler 等缝没有 production reader，Feature 仍用 concrete/shared fallback | exhaustive grep 每个服务的 reader/constructor；判断 finish 还是 retire，不一刀切复活抽象 |
| CAND-03-005 | 架构文档宣称后台调用 `DeletionScheduler.commitImmediately()`，但 App scenePhase 没有 caller，且 scheduler 无直接测试 | 复核用户可见语义与现有 ViewModel tests；查历史删除测试是否含该 oracle |
| CAND-03-006 | SmartPaper 文档称复用 `ReviewScheduler + SM2State`，实现实际在 Repository 按 raw review fields 排序 | 复核 spec/代码边界，若仅叙述错误则降为 docs finding |
| CAND-03-007 | removed Domain/UseCase 层尚未发现必须恢复的业务规则；部分 tests 在 `aa5e1de8` 删除 | 对旧 ReviewUseCase/TaxonomyUseCase tests 与当前 Repository/ViewModel tests 做规则级映射；不能从删除行数推断损失 |

Antigravity 03b 越界提出的 restore/image/preferences 数据正确性候选未进入本阶段队列；如经 C1 初筛仍成立，路由 Phase 04，不在 Architecture 阶段裁决。

## Rejected So Far

- Apple frameworks 不属于 Core 第三方依赖违规。
- Review/Dashboard/Settings → FeatureLibrary 的 declared edges 本身不是 cycle；是否应下沉共享 UI 需实际 change-cost 证据。
- SettingsView 的 `ModelContext` 仅用于 `#if DEBUG` seeder；其他直接 `ModelContainer` 命中位于 previews，当前不作为 production violation。
- 不因旧 Domain/UseCase package 被删除就建议恢复 Clean Architecture 层。
- 未被引用的休眠服务不能直接删除；QuestionSplitting 仍有 #626 / feature owner 时先分类为 defer/keep candidate。

## Resume Order

1. 确认 worktree clean、`origin/develop` 仍为固定 base；若移动，遵守 `rebaseline-contract.md`，不静默 rebase。
2. 按 `../agent-invocation-protocol.md` 调用外部 reviewer；恢复前的三条 smoke test 已通过，Grok debug 已确认实际 `grok-4.5` high。
3. 执行 CAND-03-002 的独立 SwiftUI Environment setter probe；这是当前最高优先级候选。
4. 重跑 Antigravity 03c；再运行 Grok 03a / 03b / 03c，只允许 read-only tools。
5. C1 对所有 candidate 做 live `path:line`、调用链、focused test / build 复核。
6. 仅把 verified / pending-po 项写入 `findings.md` 和 `phases/03-results.md`；补正式 `checkpoints/phase-03.md` 后跑全门禁与 AllTests build。
