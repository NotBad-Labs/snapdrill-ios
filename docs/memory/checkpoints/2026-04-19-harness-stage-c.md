---
last_verified: 2026-04-19
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-19 Harness Engineering Stage C

## Goal

给 agent 补上 SwiftUI 视觉回归 evaluator —— Anthropic 2026-03-24 《Harness design for long-running apps》蓝本里 Playwright MCP 的 iOS 等价物最小成本版。plan 原定 Stage C 2 PR（PR-6 SnapshotTesting + 15 个 baseline / PR-7 CI 集成 xcresult artifact），用户初次决定另开会话推进，2026-04-19 晚上半场 Stage A+B + 其他 tech-debt PR 合并后明确要求"现在开始 Stage C"，2 个 PR 全部落地。源自 `~/.claude/plans/resilient-floating-quasar.md` PR-6/PR-7 章。

## Done（2 PR 全合并）

| PR | 主题 | 关键改动 | 受影响 layer |
|---|---|---|---|
| **#690** | Stage C/PR-6 SnapshotTesting + 7 baseline | `SnapDrillFeatures/Package.swift` 加 `pointfreeco/swift-snapshot-testing 1.17+`；`SnapDrillUI/Package.swift` trailing comma cleanup；`SnapDrillFeaturesTests/SnapshotRegressionTests.swift`（105 行，7 测试）；`__Snapshots__/SnapshotRegressionTests/*.png`（7 张 PNG / 217 KB）；`docs/principles/testing.md` 《Snapshot 视觉回归》章节；顺手修 `.claude/hooks/swift-autolint.sh` 的 Issue #666 残留（Package.swift / DataSeeder.swift 假阳性阻塞）| pattern + snapshot |
| **#691** | Stage C/PR-7 CI 集成 xcresult artifact | `.github/workflows/ci.yml` Test step 加 `-resultBundlePath TestResults.xcresult` + 新增 `Upload xcresult on failure` step（`if: failure()` + `actions/upload-artifact@v4`，保留 7 天）；`.gitignore` 加 `TestResults.xcresult/`；`docs/workflow.md` 新增《CI 与本地一致性》章节（~40 行）；`docs/principles/testing.md` Snapshot CI 子段从"PR-7 落地"更新为"已落地" | pattern + snapshot |

## Open

- **Stage C 已全部落地**，无 Open 条目从本 phase 继承
- Harness 三阶段 9 PR 整体收官（A+B 7 PR + C 2 PR）

## Decisions

- **测试放 SnapDrillFeaturesTests 而非 SnapDrillUITests(SPM)**：三重约束下的最优解 —— (a) Xcode 原生 `SnapDrillUITests` (XCUITest target) 与 SPM `SnapDrillUITests` 命名冲突，`-only-testing:` 会误匹配；(b) AllTests scheme 只含 Core/Data/FeaturesTests，SPM UITests 实际 CI orphan；(c) FeaturesTests 已依赖 Core/Data，加 SnapDrillUI 是自然的 transitive 链
- **Swift 6.3 隔离写法**：`nonisolated final class SnapshotRegressionTests: XCTestCase` + 方法级 `@MainActor` —— `defaultIsolation(MainActor)` 会把 class 默认转 MainActor，但 XCTestCase 基类 init 要求 nonisolated；这是此冲突的标准解法（Xcode Review G-1 明确认可）
- **用 `.image(layout: .sizeThatFits)` / 显式 `.frame()`，不用设备 preset**：SnapshotTesting 无 `.iPhone17` config preset，且项目已锁 Xcode 26.4 + iPhone 17 Simulator，避免依赖 library 预设更稳
- **首批 7 个而非 plan 原定 15 个**：plan 描述不准确（如 "SnapDrillButton 3 变体" 实际只有 1 种 `.borderedProminent`；Features 层 5 个 View 都是 `internal`，需 `@testable`）；YAGNI + 奥卡姆剃刀先 MVP 跑通，Features 层后续 PR 用 `@testable` 扩展
- **顺手修 Issue #666 hook 残留**（PR-6 内）：`.claude/hooks/swift-autolint.sh` 在 PR #667 方案 A 修过一次（过滤 file_length 等 4 规则），但单文件 lint 不读 `.swiftlint.yml` 的 excluded 导致 Package.swift 仍被假阳性阻塞。本轮修法：hook 显式 skip `*/Package.swift` + DataSeeder.swift，与 excluded 列表对齐；加双向注释锚定（hook 指 yml 行号，yml 提醒同步 hook）。根治 Issue #666 的 hook 假阳性
- **拆 2 独立 PR 而非单 PR 多 commit**：PR-6 scope 大（依赖 + 测试 + baseline + 文档），PR-7 pure CI（workflow + docs），分开 review 更聚焦，PR-7 可在 PR-6 验收通过后立刻跟进
- **不本地模拟失败路径验证 artifact 结构**：修 baseline / View 源码以触发失败属于 test evasion（F-014），安全规则正确拦截；`actions/upload-artifact@v4 + if: failure()` 是社区标准 pattern 逻辑自证；首次真实失败即验证，不对则 hotfix
- **Features 层 internal View snapshot 留后续**：ReviewHeroCard / BentoCard / CaptureMethodCard / CornerBracketShape / SettingsRow 都是 `internal`，需 `@testable import SnapDrillFeature*`。后续 PR 分模块扩展，避免一次性引入大批 `@testable` 依赖

## Risks

- **未本地验证失败路径 artifact 结构**：安全规则拦截 baseline tampering + View 修改。降级路径是首次真实 snapshot 失败时验证，不对开 hotfix。`upload-artifact@v4 + if: failure()` 社区 pattern 可信度高
- **SnapshotTesting 对渲染环境敏感**：不同 Xcode 版本 / iOS Simulator 版本下 SwiftUI 渲染可能有像素差异。缓解：CI 锁 Xcode 26.4 + iPhone 17 Simulator；基线重录前先确认是有意变更
- **覆盖仅 7/~15**：SnapDrillUI 层 7 个 public View 已覆盖，Features 层 internal View 未覆盖。下次真实改动 Features 层 View 时缺 snapshot 守护。缓解：后续 PR 分模块用 `@testable import` 扩展覆盖
- **`nonisolated class` + 方法级 `@MainActor` 模式可能扩散**：项目现有 Swift Testing `@Test` 方式（如 PerformanceTests）与本 PR 的 XCTestCase 混用。未来新增 snapshot 测试时需注意采用哪种 Framework。缓解：`testing.md` 已明确 SnapshotTesting 用 XCTestCase + `nonisolated class` 模式
- **session-metrics 数据采集不全**：本 Phase 只有 PR-6 + PR-7 合并的 3 小时左右 wall-clock，`.claude/session-metrics.tsv` 记录正常但跨 PR phase 时有 Claude Code 重启导致 metrics 断续

## Next

Harness 三阶段 9 PR 整体收官。无紧接后续任务从本 phase 继承。按 ROI 排序：

1. **[最高 ROI，零成本]** 下次改动 SwiftUI View 时验证 snapshot 守护实际效用 —— 若无意变更被挡住/有意变更顺利 record，说明机制就位
2. **[高 ROI，半天]** 首次真实 snapshot 失败时验证 CI artifact 管道 —— 确认 xcresult bundle 下载 + xcresulttool 解包 + diff 图可读
3. **[中 ROI，1-2 天]** Features 层 internal View snapshot 扩展（@testable import 分模块，如 Dashboard 先做 ReviewHeroCard + BentoCard）
4. **[低 ROI，观望]** Meta-harness 方向（Anthropic 蓝本里 5-15 轮审美迭代）—— iOS 构建节奏不适配，暂不做
5. **[低 ROI]** 给 `actions/upload-artifact@v4` 加 xcresult 自动解包 + diff 图作为 GitHub Actions 步骤输出（MCP 封装）—— 当前人眼审够用

**Harness 9 PR 合流的下游效益**：接下来真实 feature / tech-debt PR 都能用到 Sprint Contract（F-018）+ cross-audit rubric 4 维 + 反模式启发式（F-019）+ snapshot evaluator 的完整链路。链路实战若干 PR 后再做一次 meta-review。

**阻塞链不变**：Apple 账号 $99 缴费（用户延迟至 2026-05），释放后解锁 #163/#479/#485/#486/#490/#161 六个下游 Issue。

## Metrics

> 数据来源：`.claude/session-metrics.tsv`（PR #678 session-metrics hook 记录）。本 Phase 跨会话连续推进（Stage A+B 合并 → 其他 tech-debt → Stage C），metrics 文件持续写入但 phase boundary 不显式标记。粗估覆盖 Stage C 开始（PR #690 开工）至 PR #692 sync 合并的 window。

- 2 PR 合并 wall-clock：~2.5 小时（PR-6 ~1.8 小时含 hook fix / PR-7 ~0.7 小时）
- Xcode Review 轮次：PR-6 两轮（首轮 1🟡 Y-1 hook/swiftlint 双向锚定 → 第二轮验收通过）；PR-7 一轮（0🔴+0🟡+8🟢 直接通过）
- 新增 baseline：7 张 PNG / 217 KB（最大 ContextualErrorView 53 KB / 最小 SnapDrillButton 1.7 KB）
- SnapshotTesting 依赖 pin：1.19.2（Package.resolved）
- 新增文档：`docs/principles/testing.md` +33 行《Snapshot 视觉回归》；`docs/workflow.md` +41 行《CI 与本地一致性》

## 吃自己狗粮的反馈

| Stage A+B 机制 | Stage C 实施中的使用情况 |
|---|---|
| **Sprint Contract (F-018)** | **未显式填**（Stage C plan 已经很详细，直接开工）—— 说明 F-018 对超小 scope 的 issue/phase 不必强推，和 F-018 原文"Appetite >= Small 才强制"一致 |
| **cross-audit rubric 4 维** | **未触发**（Xcode Review 已 0🔴，无需 cross-audit 对抗）—— 说明三方对抗不是"每个 PR 必做"，用户可按 PR 风险/scope 判断 |
| **反模式启发式 (F-019)** | PR #690 合并后 `post-merge-checkpoint.sh` 应该触发（PR 含 15+ 文件因为 baseline 图多），但启发式阈值可能偏低。若后续多个 snapshot PR 都被误报，需调阈值或加白名单（baseline PNG 不算 "scope 膨胀"）|
| **Permission Model (#677)** | 本轮因修 `.claude/hooks/swift-autolint.sh` 触发 Permission 首次拦截 —— 用户授权后修改生效，SSOT 覆盖自身的机制（C-1）有效 |
| **session-metrics hook (#678)** | 持续记录，本 checkpoint 是第二次消费数据（第一次是 Stage A+B checkpoint）|
| **cross-audit-consensus §2.5 权重 SSOT (#682)** | 未触发（无 cross-audit 场景）|
| **snapshot evaluator (本 phase 新增)** | 作为未来机制基础设施落地，等下次 View 改动才真正吃狗粮 |

**核心教训（本 phase）**：
1. **Plan 字数 vs 实施复杂度不线性**：plan PR-6 章写得详尽但实施时还是遇到 3 个未预见的摩擦（测试命名冲突 / `defaultIsolation` 隔离冲突 / hook 假阳性）。实施过程暴露的问题更有价值，plan 不必追求"一次性穷举所有风险"
2. **顺手修（side-quest）的 ROI**：修 hook 假阳性是"做 PR-6 时被挡了于是顺手修"，没拆单独 PR。事后证明这是高价值修复（Issue #666 残留彻底了结），YAGNI + 不过度规划反而高效
3. **安全规则阻止 evasion 的具体案例**：用户的 permission 系统挡下了两次问题操作 —— 自改 hook（需要授权）+ swap baseline 验证失败路径（test tampering）。两次都是**正确拦截**，推动我用更合规的方案（用户授权 / 逻辑自证）

## Harness 三阶段总结（A+B+C 9 PR）

Anthropic 蓝本 5 个断点全部覆盖：

| 断点 | Plan 对应 PR | Stage | 现状 |
|---|---|---|---|
| 编码前契约缺失 | PR-1 #675 Sprint Contract | A | ✅ F-018 落地 |
| 三方对抗产出全定性 | PR-2 #679 rubric | A | ✅ §2.5 量化评分 + Retry 阈值 |
| 反模式检测全手动 | PR-3 #676 启发式 | A | ✅ anti-pattern-scan.sh + F-019 |
| 权限白名单散落 | PR-4 #677 Permission Model | B | ✅ SSOT + 3 tier 分层 |
| 成本/耗时追踪 | PR-5 #678 session-metrics | B | ✅ TSV 记录（不含 token）|
| **iOS UI 无视觉回归** | **PR-6/#690 + PR-7/#691** | **C** | ✅ **SnapshotTesting + CI artifact** |

**agent 现在拥有的 harness 能力**（合并后）：
- **Planner 层**：Sprint Contract 做编码前约束，Issue 模板引导
- **Generator 层**：Claude/Codex/Gemini 实现代码
- **Evaluator 层**：cross-audit rubric（逻辑）+ swift-autolint hook（风格）+ CI（编译）+ SnapshotTesting（视觉）+ Xcode Review（人 + AI 混合审）
- **反馈回流**：F-008~F-020 feedback 规则 + post-merge 反模式启发式 + phase-closeout checkpoint

下一步是**用几个真实 feature PR 端到端验证** harness 链路实际价值（见 Next #1）。Meta-review 可在 3-5 个真实 feature PR 后做。
