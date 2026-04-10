---
paths:
  - "**/*Tests*/**"
  - "**/*Test*"
---

<!-- last verified: 2026-04-09 -->
<!-- freshness: max_age_days=60, decay_trigger=[swift_update, xcode_release], layer=snapshot -->
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
