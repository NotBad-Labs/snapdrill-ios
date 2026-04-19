---
last_verified: 2026-04-14
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

- **编译测试**：`xcodebuild build-for-testing -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'`
- **执行测试**：`xcodebuild test -scheme SnapDrillFeaturesTests -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO`
- **禁止**：`swift test`（SPM 仅声明 iOS 平台，macOS 环境不匹配会报错或 SIGTRAP）
- **禁止**：`xcodebuild build`（不编译测试 target）

## async / MainActor 测试约束

- 项目启用 `defaultIsolation(MainActor.self)`，测试代码也受此影响
- 异步测试用 Swift Testing 的 `@Test` + `await`，不用 `XCTestExpectation`
- 需要验证 MainActor 隔离行为时用 `MainActor.run {}`
- Task 生命周期测试：验证 `cancelTasks()` 后 Task 确实停止，不泄漏
- 详见 `coding.md` 并发段和 `api-pitfalls.md` defaultIsolation 陷阱段

## SwiftData 测试约束

- Repository 测试用 in-memory `ModelContainer`（`ModelConfiguration(isStoredInMemoryOnly: true)`）
- `#Predicate` 中的 many-to-many 过滤会运行崩溃 → 测试也要覆盖这个边界（详见 `api-pitfalls.md`）
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
- 测试文件：`Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SnapshotRegressionTests.swift`
- 基线图：`Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/__Snapshots__/SnapshotRegressionTests/*.png`（入 git）
- 覆盖：当前 7 个 SnapDrillUI 层 public View（SnapDrillButton / ProgressLoadingView×2 / ErrorMessageView×2 / ContextualErrorView / TipPopoverContent）
- 位置选择理由：Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM `SnapDrillUITests` 命名冲突，且 AllTests scheme 只纳入 Core/Data/FeaturesTests，故放 FeaturesTests 以确保 CI 真实执行
- nonisolated 标注：`nonisolated final class SnapshotRegressionTests: XCTestCase`，因 `defaultIsolation(MainActor)` 与 XCTestCase 基类 init nonisolated 要求冲突；单测试方法按需加 `@MainActor`

### 新增/修改 View 的工作流

1. **新增 public View**：DoD 一项是"同时加 snapshot 测试"（先写测试，首次跑会自动 record baseline + 失败，提交前再跑一次确认稳定）
2. **修改现有 View**：
   - Snapshot 失败时**先人眼审**差异图（xcresult bundle 内 `Attachments/*.png` 或 diff 工具）
   - 若是**有意变更** → 删对应基线 `.png` 文件让它重新 record（不要全文件设 `isRecording = true`，那会盲目覆盖所有 baseline）
   - 若是**非预期回归** → 修代码让 snapshot 与基线一致
3. **禁止盲目 record** — 等同 test evasion（F-014 纪律），Review 见到一次性更新 >3 张 baseline 必须质询合理性

### 稳定性与 flaky 防护

- Snapshot 对 Xcode 版本敏感 → 项目固定 Xcode 26.4，CI 用 self-hosted Mac mini（已定）
- 模拟器固定 `iPhone 17`（对齐 `STATUS.md` 执行门命令）
- 用 `.image(layout: .sizeThatFits)` 或显式 `.frame(width:height:)`，避免依赖设备 config preset
- 首次 record 后第二次跑必须 0 diff，否则该测试天然不稳定，不入基线

### CI 集成（PR-7 落地）

- CI 跑 `xcodebuild test -scheme AllTests` 自动执行 snapshot 测试
- 失败时上传 `*.xcresult` artifact（包含 diff 附件）供下载审查
- 详见 PR-7（本段随 PR-7 合并后补链接）
