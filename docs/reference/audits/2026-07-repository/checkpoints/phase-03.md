# Phase 03 Checkpoint

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## T0

- product base：`origin/develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- 主 checkout：同一 SHA；只存在原有未跟踪 `agent-reports/`，未触碰
- worktree：`/private/tmp/snapdrill-repository-audit`
- branch：`codex/repository-audit-program`
- phase start HEAD：`0b3c1349511fc7e59a415b15b3d592b50f8775e6`
- resumed checkpoint HEAD：`9fb3fe7954c24dceddcb97f8cb6e761750eed117`
- audit write WIP：1

## Coverage

- compile graph：4 SPM packages、8 production package targets、4 package test targets
- native graph：App、UITests、Share、ShareTests
- runtime graph：DependencyContainer、ServiceContainer、ProfileManager、RepositoryContainer、DataExecutor、Feature construction
- state seams：activity tracker、capture draft、deletion scheduler、analytics、Profile environment
- abstraction debt：protocols、coordinators、static facades、removed Domain/UseCase history
- dependency ownership：Mantis、ZIPFoundation、SnapshotTesting 与 4 个 lockfiles
- slices：`03a` graph、`03b` runtime flow、`03c` abstraction debt

## Agent Status

- Claude Fable 5：03a / 03b / 03c complete；safe read-only invocation contract 已补入仓。
- Antigravity `Gemini 3.5 Flash (High)`：03a / 03b / 03c complete；废弃参数误解析与暂停前 partial run 均未作为证据。
- Grok 4.5：03a / 03b / 03c complete；03c 无 shell，Git history 明确未覆盖，由 C1 独立核验。
- Codex C1：逐项重开 live path、运行 SwiftUI hosting probe、对比三个历史简化 commit 与当前 tests。
- raw transcript、debug/auth log、brain artifacts 未入仓或私有 memory。

## Verified Results

- findings：10（1×P1，5×P2，4×P3）
- P1：Profile Environment fallback 的 direct in-memory initializer 在正常 App 启动清真实 per-profile UserDefaults。
- P2：App implicit products、activity tracker 双所有权、ServiceContainer 半迁移、background delete 未提交、Capture transaction failure oracle 缺失。
- P3：架构图/DI current-state 漂移、SmartPaper implementation prose、四份 lockfile 漂移、Live container mock analytics default。
- keep：4-package topology、Core invariant、coordinators、real system-service protocols、removed Domain/UseCase 保持删除。
- repair/retire/defer 分类见 `phases/03-results.md`；未授权任何产品代码修复。

## Corrections To Agent Output

- `simctl spawn defaults` 默认写 Simulator user domain，不能证明 App sandbox 偏好；改用 `get_app_container` + `CFFIXED_USER_HOME` 后，旧 normal launch `1 -> missing`，P1 成立。
- production activity tracker 当前因 `.shared` 默认收敛，不是已发生的切换守卫失效；定 P2 而非外部报告的 P1。
- ServiceContainer 半迁移是结构/测试替换风险，不等于六个服务都应继续挂容器；按 finish/retire/defer 分开。
- SmartPaper 使用 SM-2-derived fields，但未直接复用 `ReviewScheduler + SM2State`；只判 current How prose 错误。
- 删除的 Domain/UseCase assertions 已有当前 oracle；不因 2,067 行删除而推断规则丢失或建议复活。

## Validation

- direct-construction sentinel：旧代码红测；App-container launch：旧 normal `1 -> missing`、fixed normal `1 -> 1`、fixed UI-test `1 -> missing`。
- feature status / intent traceability、8 generator tests、docs health、Capture contract、25 script tests：通过；docs health 仅既有 warnings。
- `swiftlint --strict`：245 files，0 violations。
- focused architecture tests：45 passed。
- `AllTests build-for-testing`：`TEST BUILD SUCCEEDED`。
- `git diff --check`：clean。

## Recovery

- result：`phases/03-results.md`
- ledger：`findings.md`
- invocation protocol：`agent-invocation-protocol.md`
- historical pause point：`checkpoints/phase-03-in-progress.md`
- next command：冻结 Phase 04 的 models/profile/backup/image inventory；先复核已路由数据候选，不读取本轮 raw agent output
