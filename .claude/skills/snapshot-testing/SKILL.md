---
name: snapshot-test-setup
description: Set up SwiftUI visual regression testing with swift-snapshot-testing. Generates snapshot test boilerplate and CI configuration. Use for UI regression prevention.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Snapshot Test Setup

Generate SwiftUI snapshot/visual regression tests using Point-Free's swift-snapshot-testing library. Catches unintended UI changes by comparing rendered views against reference images.

## When This Skill Activates

Use this skill when the user:
- Wants "snapshot tests" or "visual regression tests"
- Says "I want to catch UI regressions"
- Asks about "screenshot testing" or "preview testing"
- Wants to verify SwiftUI views don't change unexpectedly
- Mentions "swift-snapshot-testing" or "Point-Free"

## Why Snapshot Tests

```
Without snapshots:        With snapshots:
Change a modifier         Change a modifier
  → Looks fine locally      → Snapshot test fails
  → Push to main            → Shows exact visual diff
  → User reports UI bug     → Fix before merging
  → Embarrassing             → Confidence in UI changes
```

## Pre-Setup Checks

### 1. Project Context

```
Glob: **/Package.swift or **/*.xcodeproj
Grep: "swift-snapshot-testing" (already added?)
Grep: "SnapshotTesting" in test files
```

### 2. Configuration Questions

Ask via AskUserQuestion:

1. **Package manager?**
   - Swift Package Manager
   - CocoaPods
   - Tuist

2. **Platform?**
   - iOS
   - macOS
   - Both

3. **What to test?**
   - Specific views (user provides names)
   - All screens
   - Component library

## Setup Process

### Step 1: Add Dependency

#### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        from: "1.17.0"
    )
]

// Test target
.testTarget(
    name: "YourAppTests",
    dependencies: [
        "YourApp",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
    ]
)
```

#### Xcode Project

1. File → Add Package Dependencies
2. URL: `https://github.com/pointfreeco/swift-snapshot-testing`
3. Add `SnapshotTesting` to your test target

### Step 2: Create Snapshot Test Base

```swift
import Testing
import SnapshotTesting
import SwiftUI
@testable import YourApp

// MARK: - Snapshot Configuration

enum SnapshotConfig {
    // iOS devices to test
    static let iPhoneConfigs: [String: ViewImageConfig] = [
        "iPhone_SE": .iPhoneSe,
        "iPhone_16": .iPhone13,       // Similar dimensions
        "iPhone_16_Pro_Max": .iPhone13ProMax
    ]

    // macOS window sizes
    static let macOSConfigs: [String: CGSize] = [
        "compact": CGSize(width: 400, height: 600),
        "regular": CGSize(width: 800, height: 600),
        "wide": CGSize(width: 1200, height: 800)
    ]

    // Color schemes to test
    static let colorSchemes: [ColorScheme] = [.light, .dark]
}
```

### Step 3: Generate Snapshot Tests

#### iOS View Snapshot

```swift
@Suite("Snapshots: HomeView")
struct HomeViewSnapshotTests {

    @Test("matches reference - light mode")
    func lightMode() {
        let view = HomeView(items: Item.sampleList)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }

    @Test("matches reference - dark mode")
    func darkMode() {
        let view = HomeView(items: Item.sampleList)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }

    @Test("matches reference - empty state")
    func emptyState() {
        let view = HomeView(items: [])

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }

    @Test("matches reference - dynamic type XXL")
    func dynamicTypeXXL() {
        let view = HomeView(items: Item.sampleList)
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)

        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }
}
```

#### macOS View Snapshot

```swift
@Suite("Snapshots: SettingsView")
struct SettingsViewSnapshotTests {

    @Test("matches reference - standard size")
    func standardSize() {
        let view = SettingsView()
            .frame(width: 500, height: 400)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: CGSize(width: 500, height: 400))
        )
    }

    @Test("matches reference - dark mode")
    func darkMode() {
        let view = SettingsView()
            .frame(width: 500, height: 400)
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: CGSize(width: 500, height: 400))
        )
    }
}
```

#### Component Snapshot (Reusable)

```swift
@Suite("Snapshots: ItemCard")
struct ItemCardSnapshotTests {

    @Test("default state")
    func defaultState() {
        let view = ItemCard(item: .sample)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }

    @Test("selected state")
    func selectedState() {
        let view = ItemCard(item: .sample, isSelected: true)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }

    @Test("long title wraps")
    func longTitle() {
        let item = Item(title: "This is a very long title that should wrap to multiple lines")
        let view = ItemCard(item: item)
            .frame(width: 300)

        assertSnapshot(of: view, as: .image)
    }
}
```

### Step 4: Recording Reference Images

First run records reference images (golden masters):

```bash
# Record all snapshots (first run)
xcodebuild test -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Important:** Reference images are stored in `__Snapshots__/` directories next to test files. Commit these to git.

```
Tests/SnapshotTests/
├── __Snapshots__/
│   └── HomeViewSnapshotTests/
│       ├── lightMode.1.png
│       ├── darkMode.1.png
│       ├── emptyState.1.png
│       └── dynamicTypeXXL.1.png
├── HomeViewSnapshotTests.swift
└── ItemCardSnapshotTests.swift
```

### Step 5: Re-record When Intentional Changes

When you intentionally change a view:

```swift
// Temporarily set record mode
@Test("matches reference - light mode")
func lightMode() {
    withSnapshotTesting(record: .all) {
        let view = HomeView(items: Item.sampleList)
        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(on: .iPhone13)
        )
    }
}
```

Or use environment variable:
```bash
SNAPSHOT_TESTING_RECORD=all xcodebuild test -scheme YourApp
```

## What to Snapshot

### High Value (Always Snapshot)
- Screens/pages with multiple states (empty, loaded, error)
- Reusable components in all configurations
- Dark mode vs. light mode
- Dynamic type at standard and accessibility sizes

### Medium Value (Selectively Snapshot)
- Navigation flows (each step)
- Onboarding screens
- Paywall/subscription views
- Settings screens

### Low Value (Skip)
- Views that are 100% system components (plain List, NavigationStack)
- Views that change frequently during active development
- Views dependent on live data

## CI Integration

### GitHub Actions

```yaml
- name: Run Snapshot Tests
  run: |
    xcodebuild test \
      -scheme YourApp \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
      -only-testing "YourAppTests/Snapshots" \
      -resultBundlePath TestResults.xcresult

- name: Upload Failed Snapshots
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: failed-snapshots
    path: "**/Failures/**"
```

### Xcode Cloud

```bash
# ci_scripts/ci_post_xcodebuild.sh
if [ "$CI_XCODEBUILD_ACTION" = "test" ]; then
    # Upload snapshot failures as artifacts
    if [ -d "$CI_DERIVED_DATA_PATH" ]; then
        find "$CI_DERIVED_DATA_PATH" -name "Failures" -type d \
            -exec cp -r {} "$CI_RESULT_BUNDLE_PATH/" \;
    fi
fi
```

## Output Format

```markdown
## Snapshot Tests Setup

### Dependency Added
swift-snapshot-testing 1.17.0 via SPM

### Tests Generated
| View | Configurations | Tests |
|------|---------------|-------|
| HomeView | light, dark, empty, XXL type | 4 |
| SettingsView | light, dark | 2 |
| ItemCard | default, selected, long title | 3 |
| **Total** | | **9** |

### Files Created
- `Tests/SnapshotTests/HomeViewSnapshotTests.swift`
- `Tests/SnapshotTests/SettingsViewSnapshotTests.swift`
- `Tests/SnapshotTests/ItemCardSnapshotTests.swift`

### Next Steps
1. Run tests once to record reference images
2. Commit `__Snapshots__/` directories to git
3. Add snapshot test step to CI pipeline
```

## References

- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- `generators/test-generator/` — for unit/integration test generation
- `testing/tdd-feature/` — for TDD workflow with UI features
---
name: snapshot-diff-review
description: Snapshot 测试 baseline 变更审查。当 snapshot 测试产生新的 baseline 或 baseline 变更时，git diff 图片确认视觉变化是有意的再提交。当用户说"snapshot 变了/baseline 更新/快照测试/snapshot test/record snapshots"时触发。
allowed-tools:
  - Bash
  - Read
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /snapshot-diff-review — Snapshot Baseline 审查

## 一句话

Snapshot baseline 变更是二进制图片，git diff 看不出内容。必须逐张确认视觉变化是有意为之，再提交。

## 触发场景

- 运行 snapshot 测试后 baseline 发生变化
- `SNAPSHOT_TESTING_RECORD=1` 模式录制了新 baseline
- 用户说："snapshot 变了 / baseline 更新 / 快照测试 / record snapshots"
- CI 报告 snapshot 测试失败（baseline mismatch）

## 工作流

### Step 1：确认变更范围

```bash
# 查看哪些 baseline 文件变更了
git diff --name-only | grep -i "snapshot\|baseline\|Snapshots"

# 或查看所有未提交的 baseline 变更
git status | grep -i "snapshot\|baseline"
```

### Step 2：逐张 diff

对每个变更的 baseline 图片：

```bash
# 查看图片 diff（如果 git 支持）
git diff <path-to-baseline-image>

# 或者用 Finder 预览新旧对比
open <path-to-baseline-image>
```

基线位置通常在：
```
Packages/*/Tests/**/__Snapshots__/
```

### Step 3：判断变更是否合理

| 情况 | 处理 |
|---|---|
| **有意的 UI 改进** | 确认无误，纳入 commit |
| **无意的回归** | 回退代码变更，不更新 baseline |
| **仅环境差异**（字体渲染、分辨率） | 检查是否需要在 CI 环境 record |
| **无法判断** | 保留变更，标注待 Xcode Review 确认 |

### Step 4：确认后提交

```bash
# 如果所有变更都是有意的
git add <baseline-files>
git commit -m "test: update snapshot baselines for <reason>"
```

**禁止盲目 `SNAPSHOT_TESTING_RECORD=1` 全量录制后直接提交。** 必须逐张看过。

### Step 5：文档记录

在 PR 描述中说明 baseline 变更理由：
```
Snapshot baseline 更新：
- <文件名>: <变更原因>
```

## 注意事项

- Snapshot 图片是二进制文件，git 无法逐行 diff — 必须肉眼确认
- CI 环境的 snapshot 可能与本地不同（分辨率/字体），以 CI 为准
- 不要 `git add .` 混入 baseline 之外的变更

## 反模式

- ❌ `SNAPSHOT_TESTING_RECORD=1` 全量录制后直接 git add 所有 baseline
- ❌ 不看图片 diff 就提交 baseline 变更
- ❌ CI snapshot 失败后直接 record 覆盖，不排查原因

## 上游文档

本 skill 的上游权威定义在：
- `docs/standards/testing.md:90-97` — Snapshot 视觉回归工作流（人工审查要求、禁止盲目 record）
- `docs/workflow.md:127` — Snapshot baseline 变更必须 git diff 确认

## 关联文档

- `docs/standards/testing.md` — 测试规则
- `docs/workflow.md` §CI — CI 与本地一致性
