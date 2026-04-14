<!-- last_verified: 2026-04-14 -->
<!-- layer: pattern -->
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

## 接口变更后测试同步

- 修改 struct/class/protocol 的 init 或方法签名后：`grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- 详见 `coding.md` 接口变更段
