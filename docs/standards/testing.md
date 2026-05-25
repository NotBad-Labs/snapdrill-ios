---
last_verified: 2026-05-25
layer: pattern
---
# 测试策略与执行规则

## 分层策略

| 层 | 策略 |
|---|---|
| 纯算法 / Extension | TDD |
| Service | Test-after，direct test；必要时用 controlled input / temp dir / mock boundary |
| Repository | in-memory ModelContainer |
| ViewModel | Test-after |
| Data infrastructure（Migration / Backup / DTO / Persistence / Profile） | Test-after |
| View / UI 组件 | Smoke test only |

## 测试设计原则

1. **测试隔离** — 每个测试创建自己的状态，不共享。Repository 测试用 in-memory `ModelContainer`，ViewModel 测试用 mock service。测试之间无隐式依赖
2. **测试写给人看** — 用中文描述性命名：`@Test("fetchOrCreateModel 不存在时创建新标签")`。测试名描述业务场景，不描述实现细节
3. **边界优先** — 优先测试已知会崩的边界（`#Predicate` many-to-many 运行时崩溃、`ModelContainer` 局部变量提前释放），不堆砌 happy path。FAILURE 模型见 QA 工程师 skill
4. **编译器能拦的不写测试** — typed throws 保证 exhaustive error handling，strict concurrency 保证 actor 隔离，SPM 包边界保证依赖方向。这些由编译器强制，无需运行时测试验证

## 运行方式

CI 与本地统一走 `AllTests.xctestplan`，两步切分避免重复编译：

- **编译测试**：`xcodebuild build-for-testing -scheme AllTests -testPlan AllTests -derivedDataPath ./DerivedData -destination 'platform=iOS Simulator,name=iPhone 17'`
- **执行测试**：`xcodebuild test-without-building -xctestrun $(find ./DerivedData/Build/Products -name 'AllTests_*.xctestrun' | head -1) -only-test-configuration CI -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO`
- **重录 baseline**：同上但 `-only-test-configuration SnapshotRecord`（对应 `SNAPSHOT_TESTING_RECORD=all`，swift-snapshot-testing 原生 env key）
- **禁止**：`swift test`（SPM 仅声明 iOS 平台，macOS 环境不匹配会报错或 SIGTRAP）
- **禁止**：`xcodebuild build`（不编译测试 target）
- **禁止**：`xcodebuild test` 单步（替换为两步 build-for-testing + test-without-building，见 `docs/tech/deployment.md`）

## async / MainActor 测试约束

- 项目启用 `defaultIsolation(MainActor.self)`，测试代码也受此影响
- 异步测试用 Swift Testing 的 `@Test` + `await`，不用 `XCTestExpectation`
- 需要验证 MainActor 隔离行为时用 `MainActor.run {}`
- Task 生命周期测试：验证 `cancelTasks()` 后 Task 确实停止，不泄漏
- 详见 `coding.md` 并发段和 `../tech/api-pitfalls.md` defaultIsolation 陷阱段

## SwiftData 测试约束

- Repository 测试用 in-memory `ModelContainer`（`ModelConfiguration(isStoredInMemoryOnly: true)`）
- `#Predicate` 中的 many-to-many 过滤会运行崩溃 → 测试也要覆盖这个边界（详见 `../tech/api-pitfalls.md`）
- 跨 ModelContext 写后立即读 → 测试中同样禁止（详见 `coding.md` 禁止段）

## XCUITest（端到端 UI 测试，PR #598 实现）

### 测试隔离

- `app.launchArguments = ["--uitesting"]` 触发 `DependencyContainer` in-memory 模式
- `DependencyContainer.isUITesting` 为 true 时：跳过 Firebase、使用 `ProfileManager(inMemory: true)`、注入 `MockServiceContainer`
- NSUserDefaults launch arguments 跳过引导和 Tip：`-hasCompletedOnboarding YES`、`-tip.fieldConfig.v1.seen YES`

### Swift 6.3 并发兼容

- UITests target 在 `project.pbxproj` 中覆盖 `OTHER_SWIFT_FLAGS`，移除 `-default-isolation MainActor`（XCTestCase 生命周期方法与 MainActor 隔离不兼容）
- 测试类标注 `@MainActor`（XCUIElement API 需要 MainActor）
- `app` 属性用 `nonisolated(unsafe)`（setUp 从 nonisolated 上下文访问）

### 元素定位

- 优先用 `accessibilityIdentifier`（不随语言变化）
- Tab 可用 `app.tabBars.buttons.element(boundBy: index)`
- identifier 通过 View 修饰符或组件参数传入，确保在 XCUITest 的 accessibility 层级中可见

## 接口变更后测试同步

- 修改 struct/class/protocol 的 init 或方法签名后：`grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- 详见 `coding.md` 接口变更段

## Snapshot 视觉回归（PR #688 后 Stage C 引入）

### 框架与位置

- 依赖：`pointfreeco/swift-snapshot-testing`（SnapDrillFeatures/Package.swift 引入）
- 测试文件：
  - `SnapshotRegressionTests.swift` —— SnapDrillUI 层 **public** View（7 tests）
  - `FeatureSnapshotTests.swift` —— Features 层 **internal** View（9 tests，通过 `@testable import` 访问）
- 基线图：`Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/__Snapshots__/<Class>/*.png`（入 git）
- 覆盖：16 个 View × 总计 ~1.4 MB baseline
  - SnapDrillUI 层 7：SnapDrillButton / ProgressLoadingView×2 / ErrorMessageView×2 / ContextualErrorView / TipPopoverContent
  - Features 层 9：ReviewHeroCard×3（空/有待复习/全完成）/ BentoCard×2 / CaptureMethodCard / CornerBracketShape / SettingsRow×2
- 位置选择理由：Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM `SnapDrillUITests` 命名冲突，且 AllTests scheme 只纳入 Core/Data/FeaturesTests，故放 FeaturesTests 以确保 CI 真实执行
- swift-testing 形态（Issue #699 PR #5 迁移）：`@Suite + struct SnapshotRegressionTests`，struct 默认 nonisolated 不需手写；`.snapshots` trait 启用原生 record mode 传递；测试函数名保留 `test` 前缀以维持 baseline 路径不变
- 注：旧版规格（XCTestCase 子类 + 显式 `nonisolated final class` 标注）已被 swift-testing 形态替代；上述描述对齐当前代码

### 新增/修改 View 的工作流

1. **新增 public View**：DoD 一项是"同时加 snapshot 测试"（先写测试，首次跑会自动 record baseline + 失败，提交前再跑一次确认稳定）
2. **修改现有 View**：
   - Snapshot 失败时**先人眼审**差异图（xcresult bundle 内 `Attachments/*.png` 或 diff 工具）
   - 若是**有意变更** → 删对应基线 `.png` 文件让它重新 record（不要全文件设 `isRecording = true`，那会盲目覆盖所有 baseline）
   - 若是**非预期回归** → 修代码让 snapshot 与基线一致
3. **禁止盲目 record** — 等同 test evasion（F-014 纪律），Review 见到一次性更新 >3 张 baseline 必须质询合理性

### 稳定性与 flaky 防护

- Snapshot 对 Xcode 版本敏感 → 项目固定 Xcode 26.5，CI 用 self-hosted Mac mini（已定）
- 模拟器固定 `iPhone 17`（对齐 `STATUS.md` 执行门命令）
- 用 `.image(layout: .sizeThatFits)` 或显式 `.frame(width:height:)`，避免依赖设备 config preset
- 首次 record 后第二次跑必须 0 diff，否则该测试天然不稳定，不入基线

### CI 集成（PR-7 已落地）

- CI 跑 `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` + `xcodebuild test-without-building -xctestrun ... -only-test-configuration CI -resultBundlePath TestResults.xcresult` 两步自动执行 snapshot 测试
- Test step 失败时 `Upload xcresult on failure` 把 `TestResults.xcresult` 打成 artifact，保留 7 天
- Artifact 命名：`xcresult-<run_id>-<attempt>`
- 下载与解包见 `docs/tech/deployment.md`
