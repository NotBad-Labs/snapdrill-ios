---
last_verified: 2026-04-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-20 现代化 Sprint Phase 1（基础工作三件套）

## Goal

打通 Epic #699「现代化 Sprint Phase 1-4 + Firebase 升级」的基础工作门：
Swift 6.3 toolchain 统一、xctestplan + CI test-without-building、PBXGroup → Sync Group 全量。
Phase 1 是所有下游 PR（swift-testing 迁移 / typed throws / iOS 26 platform 特性 / Firebase 12 / Mantis 升级）的前置条件。

## Done

- **PR #698**（2026-04-20 02:35Z merged，+927/-108）— `SnapDrillShare` 单元测试覆盖（14 用例 + OOM 防护硬化）
  - W1 #3 的前置铺垫：PBX 迁移前先建护栏
  - 抽 `SnapDrillShare/ShareHelpers.swift`（Downsampler / DeepLinkBuilder / ContainerImageWriter 3 helper），`ShareViewController` 简化
  - 新增 `SnapDrillShareTests` unit test bundle（host = SnapDrill app，绕过 .appex 限制）
  - 修真实 bug：`UIGraphicsImageRenderer` 默认屏幕 scale (3x) 让 120MB OOM 防护实际失效，显式 `format.scale = 1` 修复
  - 三方共识：Codex（Xcode native target）vs Gemini（SPM 抽离），裁决采纳 Codex（Gemini 方案让 Features 持有 Share 逻辑违反 SoC）

- **PR #700**（2026-04-20 07:05Z merged，+17/-14）— Swift toolchain 6.2 → 6.3 统一（W1 #1）
  - 修 Codex 三方调研发现的 toolchain **半升级状态**：pbxproj 三个 target 已 6.3，但 `Configs/Shared.xcconfig` + 5 个 SPM `Package.swift` 的 `swift-tools-version` 仍 6.2
  - 统一后解锁 W2/W3 的 #14 Mantis / #17 Firebase 12 升级的 `Package.resolved` resolve 路径
  - `xcodebuild -resolvePackageDependencies` 验证 `Package.resolved` 无抖动

- **PR #701**（2026-04-20 10:01Z merged，+44/-274，净 -230）— SnapDrillShare + Tests PBXGroup → Sync Group（W1 #3）
  - 4/5 目录已用同步组，仅 `SnapDrillShare/` 与 `SnapDrillShareTests/` 遗留传统 PBXGroup，本 PR 统一
  - 通过 `PBXFileSystemSynchronizedBuildFileExceptionSet` 排除 Info.plist / .entitlements 出自动成员（避免与 `INFOPLIST_FILE` / `CODE_SIGN_ENTITLEMENTS` 重复处理），跨 target 共享 3 个 helper 给 `SnapDrillShareTests` 编译
  - 删除三个不再需要的 Ruby 脚本（`add_share_tests_target.rb` / `create_share_tests_scheme.rb` / `refactor_share_helpers_to_files.rb`）
  - 收益：未来 `SnapDrillShare/` 加新 .swift 不再改 pbxproj；解锁 W2 #10 (WidgetKit) 新 extension target

- **PR #702**（2026-04-21 03:10Z merged，+207/-44）— W1 #2 xctestplan 引入 + CI test-without-building 切换
  - **Commit A** `AllTests.xctestplan` + `AllTests.xcscheme` 引用 plan
  - **Commit B** xctestplan env var 对齐框架原生 `SNAPSHOT_TESTING_RECORD`（反思：Codex 独家方案"SnapshotRecordMode.swift helper"实施时查框架源码发现不需要，简化为直接用框架 env key）
  - **Commit C** CI workflow 切 `build-for-testing` + `test-without-building`
  - **Commit D** testing.md / workflow.md / deployment.md 文档同步
  - 本地验证：395 passed / 0 failed / 2 skipped（40s），pre-commit hook + swiftlint --strict 全绿
  - Xcode Intelligence 协作生成 plan JSON 初版（session 20260420）

## Open

- **Epic #699 Phase 1 已关闭**：三件套 PR #700 / #701 / #702 全合并，W1 critical path 解锁
- Phase 2/3/4 + Firebase 升级（共 14 PR backlog）待用户排期
- **#626 PoC 真机验证**：`QuestionSplittingService` 边界准确率 ≥ 80%（需 iOS 26 真机 + Apple Intelligence）
- **Apple 账号开闸链**（用户主动延迟到 2026-05）：#163/#479/#485/#486/#490/#161 六个下游解锁

## Decisions

- **Sprint W1 扫尾顺序**：#698（补护栏）→ #700（toolchain 先行）→ #701（PBX 迁移）→ #702（test plan 收官）
  - 关键 insight：PBX 迁移（#701）前先补测试（#698）是 risk mitigation，不是独立功能，但事后证明顺手修到真 bug（OOM 3x scale）
- **toolchain 半升级发现路径**：Codex 三方调研发现 pbxproj 与 SPM 端不一致，单独列 PR 独立治理而非夹带
- **xctestrun 路径 glob `AllTests_*.xctestrun`**：采用 glob 而非硬编码，未来 Xcode 命名变化时 CI fail-fast 而非静默坏掉
- **SnapshotRecord configuration 仅本地用**：CI 强制 `-only-test-configuration CI` 避免误 record
- **SnapDrillShareTests 测试方案**：采纳 Codex Xcode native test target + 最小重构（拒绝 Gemini SPM 抽离 — 违反 SoC，Features 不应持有 Share 逻辑）
- **SnapshotRecordMode helper 简化**：Codex 独家方案查框架源码后发现框架已原生支持 `SNAPSHOT_TESTING_RECORD` env，删除自造 helper — **"查源码优先于相信 reviewer 方案"** 实战一次

## Risks

- **Xcode 版本更新兼容性**（PR #702 待审查焦点）：
  - SPM target identifier 格式（xctestplan 里用 target name 作 identifier，Xcode 26.4 生成），Xcode 升级时需验证
  - xctestrun 路径 glob 未来 Xcode 命名模式变化时 CI fail-fast 会触发（属可控失败）
- **W2/W3 `Package.resolved` 并发竞争**：#14 Mantis + #17 Firebase 12 同争 workspace `Package.resolved`，需串行合并
- **Sprint W1 critical path 已解锁**：所有阻塞 W2 之后的门都清了，下一波 PR 可并行（除 `Package.resolved` 争抢）

## Next

按 Epic #699 顺序推进（用户排期）：

1. **Phase 2 内核现代化**（5 PR）：
   - PR #4 swift-testing 全量迁移（Core + Data）
   - PR #5 swift-testing 全量迁移（Features 含 snapshot suites）
   - PR #6 typed throws 业务 API（DataError / BackupError / ProfileError）
   - PR #7 staged migration V2 模板预建
   - PR #8 ModelExecutor + 根除 Issue #599 残留 hack（含 ci.yml `simctl erase` 清理）

2. **Phase 3 iOS 26 平台特性**（4 PR）：App Intents / WidgetKit / Controls API / DataScannerViewController

3. **Phase 4 清理与诊断**（4 PR）：Privacy Manifest / Mantis 2.31.x / CloudKit `.none` 显式关闭 / OSSignposter + MXMetricManager

4. **Firebase 升级**（1 PR）：11.15.0 → 12.x major + opt-in 默认关闭

**Apple 账号阻塞解除后**：#163 缴费开闸 → #479 StoreKit → #485 CloudKit / #486 Word 导出 / #490 App Store 提交 / #161 TestFlight Build 6

## Metrics

- 本 phase tool call 总数：1560（`.claude/session-metrics.tsv`，跨 sprint 累计含 Harness 尾段）
- 调用最频繁的 tool（top-3）：Bash × 823 / Read × 245 / Edit × 134
- session 起止时间（UTC）：2026-04-18T15:23:11Z → 2026-04-21T03:12:16Z
- session 时长：~59.8 小时（跨 Harness Stage C 收尾 + Codex 3 PR 方案 + Phase 1 三件套，未清零）

> 注：`.claude/session-metrics.tsv` 自 Harness Stage A 以来未重置，本 Metrics 段涵盖三个 sprint 尾巴。若需纯 Phase 1 数据可于本 checkpoint 合并后 `truncate -s 0`。
