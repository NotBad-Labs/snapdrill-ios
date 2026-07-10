# Phase 02 Results: Tracked Truth and Guardrails

## Outcome

Phase 02 在固定 `develop@d62fead8` 上审查规范链、实证链、生成状态、协作/发布说明、脚本入口与 UI 证据。三个 slice 均由 Codex C1、Claude Fable、Antigravity `Gemini 3.5 Flash (High)` 和 Grok 4.5 独立覆盖；C1 只保留能在 live tree、Git history 或当前 PO 指令上复核的结论。

当前仓库不是“没有 SSOT”：feature frontmatter、生成状态、意图索引、AGENTS 规则和窄 validators 已形成可用骨架。主要问题是下游叙述、发布草案和旧操作模型没有随 2026-07 的产品/工作流变化收敛，导致 validator 可以全绿而人读结论仍互相冲突。

本阶段只记录事实，不修改产品代码、发布配置、产品文案或流程权威文档。

## Frozen Inventory

| Surface | Count / size | Interpretation |
|---|---:|---|
| `docs/explanations/*.md` | 9 | 产品规范链与背景解释 |
| `docs/decisions/*.md` | 6 | ADR + PO 决策日志 |
| active feature specs | 9 | feature frontmatter 是状态输入 |
| backlog feature specs | 5 | 含已实现子集但未完全完成的 feature |
| `docs/how-to/*.md` | 5 | setup、协作、发布操作面 |
| top-level reference docs | 10 | 术语、NFR、平台边界、metadata 等 |
| `docs/ui-redesign/*.md` | 6 | UI 冻结、合同与历史记录 |
| UI evidence files | 138 / 35,424 KiB | 2026-06-21/22 为主的截图证据 |
| `Scripts/` files | 20 | generator、validator、hook 与辅助脚本 |
| `.claude/` files | 9 | 本地 hook / agent 配置 |
| GitHub workflow | 1 | 当前主 CI workflow |
| shared schemes / test plans | 5 | Xcode 测试入口 |

15 个 UI evidence 文件没有被其他 tracked 文档逐文件引用。这个静态计数不能证明它们无价值或可删除；其所有权与 current/historical 标签留给 Phase 08。

## Authority Assessment

### What is working

- `AGENTS.md:31-38` 已把规范链与实证链分开，且明确 PO 最新意图和 live evidence 的优先级。
- feature status 与 intent traceability 由 frontmatter 生成，validator 能发现结构漂移。
- `docs/reference/glossary.md:18-26` 已记录 2026-07-05 的“资料 / 资料库”裁决，并保留 SmartPaper 域词边界。
- 历史区域 ADR 已明确降级；当前签名/发行事实集中在 README 与 release guide。

### Structural gap

现有生成器只验证“字段可生成、引用可解析”，不会验证自然语言是否仍与代码、配置、最新 PO 指令一致。因此 business model、NFR、ASO、UI matrix 和 lane DRI 均可在 docs gates 全绿时保持错误。解决方向是修具体权威链，不是再造一套全库语义 validator。

## Verified Findings

### RA-02-001 — P2 — Business model falsely blocks the implemented free SmartPaper path

- `docs/explanations/business-model.md:54` 仍称“智能组卷基础体验”被 StoreKit #479 总闸阻塞。
- `docs/features/backlog/feat-smartpaper.md:18,33-47,54-62` 明确免费 3 次/月路径已实现、从 Library 可达，只有 Pro 精准组卷仍被 #479 阻塞。
- `LibraryView.swift:127-131,218-223` 有实际入口和 destination；相关 ViewModel/test 已覆盖免费配额。
- 影响：商业分层说明会把已交付免费能力误报为不可用，干扰发布范围和 dogfood。
- 最小修复：只纠正 business model 的现状句；保留 feature 的 `in-progress` / Pro blocker 模型。

### RA-02-002 — P2 — Compatibility NFR contradicts the shipping target and release checklist

- `docs/reference/non-functional-requirements.md:66-70` 要求 iPhone + iPad、自适应 regular width、iPad Split View，并把 iPhone 定义为仅竖屏。
- live app/share build setting 在 `project.pbxproj:1014,1050,1085,1274` 为 `TARGETED_DEVICE_FAMILY = 1`；iPhone orientations 在 `:1038,1073` 同时包含横屏。
- README 与 `release-and-ci.md:134` 明确当前发行是 iPhone-only，但 `release-and-ci.md:151` 仍要求 iPad 12.9-inch 商店截图。
- 影响：NFR、测试范围和商店准备口径不一致，可能制造无效 iPad 工作或漏验实际 iPhone 横屏行为。
- 最小修复：把 current shipping requirement 与 future iPad aspiration 分栏；按当前 target 修 release checklist。是否支持 iPhone 横屏需 PO/UI dogfood 决定。

### RA-02-003 — P2 — App Store metadata draft describes the retired education-first product

- `docs/reference/appstore-metadata.md:25,38-43,52-67,71-86,94-107` 仍以“练习题、错题本、homework、personal question bank”为核心叙事。
- 当前权威定位在 `positioning-and-audience.md:14-24`：面向一般受众的扫描、归档、整理效率工具，不对外呈现为儿童教育 App。
- metadata `:29` 还写“含 App 内购买”，而 README `:26,34` 明确本期不接 StoreKit、无法购买。
- 影响：该 tracked draft 不能直接用于 App Store submission，且会把审核与用户预期带回旧定位。
- 边界：frontmatter 已声明 PO / legal / ASO gate，因此不是当前 P1 发布事故；修订必须由 PO/ASO/legal 审核，不能由本审计擅改。

### RA-02-004 — P2 — Normative feature and design prose lag the approved terminology

- glossary `:18-24` 与 live L10n 已统一“资料 / 资料库”，SmartPaper 域内保留“题 / 试卷 / 组卷”。
- `design-principles.md:74,86,94-104`、`feat-library.md:3,16,23,28-37`、`feat-export.md:27-32,53`、`feat-onboarding.md:34` 仍把通用 Library 表面写成“题库 / 题目 / 每页题数”。
- live `L10n+Foundation.swift:17-22` 为“资料库”，`L10n+Library.swift:223` 为“每页资料数”。
- 影响：产品规范会引导新实现重新引入已裁决的旧文案，并使 feature spec 与用户可见面脱节。
- 最小修复：做一次仅限通用资料系文案的 docs slice；不得改 SmartPaper 域词、标识符、wire key 或内部命名。

### RA-02-005 — P2 — Vision slim-down orphaned downstream success and free-tier constraints

- `design-principles.md:46,52-65`、`user-journeys.md:39`、`analytics-events.md:7` 继续引用 `vision.md` 的“原则冲突裁决 / 成功信号”。当前 `vision.md` 已没有这些章节。
- Git history 显示 `fa118bec` 删除了 8 项成功信号及“免费层现有能力不得降级需 PO”约束，但没有迁移到新的权威文档。
- 影响：下游仍按一组不可定位的 oracle 设计和验收，免费层降级约束也失去可追溯的 normative owner。
- 状态：`pending-po`。PO 需决定恢复、迁移还是显式废弃这些约束；不能由 C1 根据旧文本自动复活。

### RA-02-006 — P2 — Steady-state DRI and private-memory instructions lag the latest PO operating model

- PO 2026-07-10 的最新明确指令是：Codex C1 承担统筹，C2/C3/C4 暂挂；Claude/Gemini/Grok 是 C1 可调用的独立 reviewer，不再由 Claude 主导规划或发布收口；事实优先入仓，私有 memory 暂停重新积累。
- `parallel-lanes.md:38-50,66-76,78-102,138`、`release-and-ci.md:12,110-117,175,189-202` 和 `po-decision-log.md:48` 仍把 Claude 定义为工程/发布/规划 DRI。
- `release-and-ci.md:348-351` 仍把 Claude Auto Memory 检查列为每次发版必做项。
- 影响：tracked operating model 会把协调责任交给已被 PO 撤销的主导角色，并鼓励恢复当前明确暂停的私有记忆流程。
- 最小修复：在独立 process slice 中记录当前 steady-state DRI、external-review 边界和 memory-disabled 状态；保留 PO 合并/发布授权与 write WIP/串行合并硬约束。

### RA-02-007 — P2 — The active UI freeze matrix falsely marks SmartPaper as unreachable

- `UI-FREEZE-QA-MATRIX.md:3-5` 把自身标为 active checklist；`:103` 却称 SmartPaper 没有从 `LibraryView` / router 的 release route。
- live `LibraryView.swift:127-131,218-223` 已提供入口和 route；feature spec `:18` 同样声明免费路径可达。
- matrix `:119` 还把“编辑题目”列为当前标题，而 live terminology 已改为“编辑资料”。
- 影响：UI 审计会跳过真实可达屏幕，并把旧截图/旧命名误当当前 release evidence。
- 最小修复：Phase 08 把 matrix 行逐项标为 current / historical / needs recapture；补 SmartPaper 当前截图。138 个现有证据文件在完成归类前不删除。

### RA-02-008 — P2 — `ci-local.sh` can report success without running package tests

- `Scripts/ci-local.sh:12,35-52` 使用 `SnapDrill` scheme，跳过 UITest 后打印“本地 CI 全部通过”。
- `AGENTS.md:53-56` 明确 `SnapDrill` scheme 不含 SPM package tests，必须使用 `AllTests` scheme + test plan。
- Phase 00 已在固定 base 上复现 README 的无 selector 命令会同时执行 `CI` 与 `SnapshotRecord` 两个 test configuration；`-only-test-configuration CI` 后才只执行一次。
- 影响：贡献者可得到 false green，另一个官方命令又重复执行同一 suite。
- 最小修复：Phase 09 统一一个 canonical local CI entry point，并验证其与 GitHub required jobs 的覆盖映射。

### RA-02-009 — P3 — PO decision log depends on machine-local evidence

- `po-decision-log.md:30,32,40` 记录 Q2 defect pool、四方 scorecard 与 Slice 2 report；其中 scorecard 指向 `~/Developer/snapdrill-agent-reports/...`。
- tracked tree 与 GitHub issue search 均找不到这三份支撑材料；scorecard 只存在当前机器的未跟踪目录。
- 影响：决策本身已入仓，但后续审阅者无法复核当时的 go/no-go 证据和边界。
- 最小修复：为仍影响发布的结论保存最小 tracked summary/commit/PR pointer；不把整份 agent transcript 或私有 memory 搬入仓库。

### RA-02-010 — P3 — The root TestFlight upload script is an unusable, unowned entry point

- `upload_testflight.sh:2-5` 自称可直接执行的自动上传脚本，tracked docs 和 CI 没有 caller。
- `:61-65` 在询问上传方式前先用 `YOUR_API_KEY` / `YOUR_ISSUER_ID` 执行 validation；`set -e` 使脚本无法到达 `:73-104` 的 Organizer/API 选择流程。
- 影响：发布人员按脚本头部执行会在归档后必然失败，并可能误以为这是当前 canonical release path。
- 最小修复：Phase 11 选择修复并纳入 release guide，或在确认无用户后删除；不得与其他发布脚本并行保留多个无 owner 入口。

### RA-02-011 — P3 — Apple platform reference carries stale blocker wording and an overdue review gap

- `apple-platform-limits.md:2-11` 的 WWDC 2026 review gap 已到期但未完成。
- `:34,41` 仍把“需要 Apple 开发者账号”标作 #485/#479/#486 的 blocker；README `:33-36` 已确认美国公司账号 active，当前阻塞是 CloudKit container / App Store Connect product / PO defer，Word 为独立 Pro work item。
- 影响：技术边界文档会把已解除的账户前置误报为当前工程阻塞，并可能遗漏 WWDC 后变化。
- 最小修复：Phase 11 用 Apple 官方资料和真机证据更新 blocker 原因与 `last_verified`；本阶段不猜测 API 变化。

### RA-02-012 — P3 — Two unreferenced xcconfig files duplicate the live build configuration

- Xcode project 只引用根 `Debug.xcconfig` / `Release.xcconfig`（`project.pbxproj:60-61,189-190,1091,1158`）。
- `Configs/Debug.xcconfig` / `Configs/Release.xcconfig` 没有 tracked caller；除 `#include` 的相对路径外，与根文件内容相同。
- 影响：两套看似权威的配置入口会让维护者修改错误副本；当前构建不受影响。
- 最小修复：Phase 11 在 `xcodebuild -showBuildSettings` 复核后删除死副本，或显式切换工程引用，只保留一套。

## Pending PO Decisions

1. **“回顾”还是“复习”**：glossary/positioning 使用“回顾”，shipped tab 与大量文档使用“复习”。2026-07-05 裁决只覆盖“资料 / 资料库”，不足以自动裁决这个词。
2. **Vision orphan 的归属**：8 项成功信号和免费层非降级约束应恢复到 vision、迁到 NFR/business model，还是正式废弃。
3. **设备与方向**：当前 iPhone-only 是实证；是否支持 iPhone 横屏、何时重启 iPad 是产品/UI 决策，不由 NFR 旧文本反推。

## Routed Candidates

1. Phase 03：检查内部注释/命名中的教育旧语义是否只是无害历史，还是影响架构边界；不在术语 slice 顺手改 identifier。
2. Phase 08：重建 UI evidence ownership，补 SmartPaper/新 onboarding/新术语截图，并给旧截图加 historical 标签。
3. Phase 09：把 RA-02-008、RA-00B-001 和 hook 安装/prerequisite 合成一个 fresh-machine control-plane slice。
4. Phase 11：集中处理 ASO、iPad screenshot、Apple platform snapshot、upload script 和 xcconfig dead copies。

## Rejected Claims

- **“iOS 26 在 2026 仍不可能，所以所有平台文档无效”**：Antigravity 的该判断与 live Xcode 26.5、成功构建和固定 base 不符，拒绝。
- **“general-audience 意味着 Declared Age Range API 必然不适用”**：这是未经法律/平台核验的绝对结论，拒绝；年龄与合规仍走 legal/fact gate。
- **“SmartPaper 全 feature 状态错误”**：拒绝。当前 spec 有意表达“免费子集已实现 + Pro 子集被阻塞”；只有 business model 的现状句错误。
- **“未被文档逐文件引用的 15 张截图都可删除”**：拒绝。缺静态引用不等于无审计价值。
- **“旧日期本身就是 finding”**：拒绝。只有能证明 current claim 已失效、owner 缺失或 freshness gate 到期时才记录。
- **“README 要求 Xcode 26.5、CI 最低 26.4+ 是已证实 bug”**：缺 26.4 实机/runner build 证据，保留给 Phase 09，不进入 ledger。
- **“缺 Share Extension 单独 NFR budget 是当前矛盾”**：这是改进建议，不是已证实的错误，拒绝。

## Agent Challenge Notes

- Claude、Antigravity、Grok 在 SmartPaper、术语、NFR、UI matrix 和 control-plane drift 上有多方重合；C1 仍逐项回到 live tree 复核。
- Grok 首次 model metadata 请求出现 TLS warning；随后 `grok models` 已确认 `grok-4.5` 可用并完成三份报告。该握手噪声不影响被 C1 独立复核的 finding。
- 外部 final output 在本阶段内归一化后丢弃；没有把 raw transcript、agent memory 或重复报告入仓。

## Validation

- feature status / intent traceability `--check`：通过。
- documentation generators：8 tests passed。
- docs health / Capture contract：通过；docs health 保留既有人工复核 warnings，无 error。
- script regression tests：25 passed。
- `swiftlint lint --strict`：245 files，0 violations。
- `AllTests build-for-testing`：`TEST BUILD SUCCEEDED`。
- `git diff --check`：clean。

## Recovery

- briefs：`02a-authority-brief.md`、`02b-guardrails-brief.md`、`02c-stale-claims-brief.md`
- ledger：`../findings.md`
- checkpoint：`../checkpoints/phase-02.md`
- next：Phase 03 Architecture，先冻结 package/target dependency graph，再审 runtime data flow 和废弃抽象
