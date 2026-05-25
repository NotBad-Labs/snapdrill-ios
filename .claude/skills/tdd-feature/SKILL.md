---
name: tdd-feature
description: Red-green-refactor scaffold for building new features with TDD. Write failing tests first, then implement to pass. Use when building new features test-first.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TDD Feature

Build new features using the red-green-refactor cycle. Tests define the spec, AI generates the implementation, tests verify correctness.

## When This Skill Activates

Use this skill when the user:
- Wants to "TDD a new feature" or "build test-first"
- Says "I want tests before code"
- Asks for "red-green-refactor" workflow
- Wants AI to generate code that's provably correct
- Is building a new module, service, or feature from scratch

## Why TDD for New Features with AI

```
Traditional:     AI generates code → You hope it's correct → Ship → Find bugs
TDD with AI:     You write tests (spec) → AI generates code to pass → Proven correct
```

The test is your **acceptance criteria in code form**. AI excels at going from failing test to passing implementation — it's a concrete, unambiguous target.

## Process

### Phase 1: Define the Feature

Before writing any code or tests, understand:

1. **What does this feature do?** (user story or requirement)
2. **What are the inputs?** (parameters, user actions, data)
3. **What are the outputs?** (return values, state changes, UI updates)
4. **What are the edge cases?** (empty, nil, error, boundary)
5. **What dependencies does it need?** (network, storage, other services)

### Phase 2: Design the API Surface

Sketch the public interface before writing tests:

```swift
// Example: Designing a FavoriteManager
protocol FavoriteManaging {
    func add(_ item: Item) async throws
    func remove(_ item: Item) async throws
    func isFavorite(_ item: Item) -> Bool
    var favorites: [Item] { get }
    var count: Int { get }
}
```

This doesn't need to compile yet — it's the contract you'll test against.

### Phase 3: RED — Write Failing Tests

Write tests for each behavior. Start with the simplest case and build up.

#### Order of Tests (Simple → Complex)

1. **Construction** — can you create the object?
2. **Happy path** — does the basic operation work?
3. **State verification** — does state update correctly?
4. **Edge cases** — empty, nil, boundaries
5. **Error handling** — what fails and how?
6. **Integration** — does it work with dependencies?

#### Template: Feature Test Suite

```swift
import Testing
@testable import YourApp

@Suite("FavoriteManager")
struct FavoriteManagerTests {

    // 1. Construction
    @Test("starts with empty favorites")
    func startsEmpty() {
        let manager = FavoriteManager()
        #expect(manager.favorites.isEmpty)
        #expect(manager.count == 0)
    }

    // 2. Happy path
    @Test("can add a favorite")
    func addFavorite() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.add(item)

        #expect(manager.count == 1)
        #expect(manager.isFavorite(item))
    }

    // 3. State verification
    @Test("can remove a favorite")
    func removeFavorite() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")
        try await manager.add(item)

        try await manager.remove(item)

        #expect(manager.count == 0)
        #expect(!manager.isFavorite(item))
    }

    // 4. Edge cases
    @Test("adding duplicate does not increase count")
    func addDuplicate() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.add(item)
        try await manager.add(item)

        #expect(manager.count == 1)
    }

    @Test("removing non-existent item does nothing")
    func removeNonExistent() async throws {
        let manager = FavoriteManager()
        let item = Item(id: "1", title: "Test")

        try await manager.remove(item)

        #expect(manager.count == 0)
    }

    // 5. Error handling
    @Test("throws when storage is full")
    func storageFullError() async {
        let manager = FavoriteManager(maxCapacity: 2)
        let items = (1...3).map { Item(id: "\($0)", title: "Item \($0)") }

        await #expect(throws: FavoriteError.capacityExceeded) {
            for item in items {
                try await manager.add(item)
            }
        }
    }

    // 6. Ordering
    @Test("favorites are in insertion order")
    func insertionOrder() async throws {
        let manager = FavoriteManager()
        let items = ["C", "A", "B"].map { Item(id: $0, title: $0) }

        for item in items {
            try await manager.add(item)
        }

        #expect(manager.favorites.map(\.title) == ["C", "A", "B"])
    }
}
```

**Run tests — they should ALL fail** (the type doesn't even exist yet).

### Phase 4: GREEN — Implement to Pass

Now implement the feature. Pass the **tests as context to AI**:

```
Prompt to Claude: "Here are my failing tests for FavoriteManager.
Implement the FavoriteManager class to make all tests pass.
Follow the protocol FavoriteManaging."
```

#### Implementation Rules

- **One test at a time** — make the first test pass, then the second, etc.
- **Write the simplest code** that passes each test
- **Don't anticipate future tests** — only satisfy current failing tests
- **Run tests after each change**

```bash
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/FavoriteManagerTests"
```

### Phase 5: REFACTOR

With all tests green, clean up the implementation:

- Extract helper methods
- Improve naming
- Remove duplication
- Optimize performance (if tests cover perf requirements)

**Run tests after every refactor step.** If any test fails, you've changed behavior — revert.

### Phase 6: Integration

Once the unit is solid, write integration tests:

```swift
@Suite("FavoriteManager Integration")
struct FavoriteManagerIntegrationTests {

    @Test("persists favorites across sessions")
    func persistence() async throws {
        let store = InMemoryStore()

        // Session 1: Add favorite
        let manager1 = FavoriteManager(store: store)
        try await manager1.add(Item(id: "1", title: "Test"))

        // Session 2: Verify it persists
        let manager2 = FavoriteManager(store: store)
        await manager2.loadFavorites()

        #expect(manager2.count == 1)
    }
}
```

## TDD Rhythm

```
RED    → Write one failing test (30 seconds - 2 minutes)
GREEN  → Make it pass with simplest code (1 - 5 minutes)
REFACTOR → Clean up while tests stay green (1 - 3 minutes)
REPEAT → Next test
```

**Cadence matters.** If you're spending more than 5 minutes on GREEN, the test might be too big. Break it into smaller tests.

## Test Categories by Feature Type

### ViewModel Feature

```swift
@Suite("SearchViewModel")
struct SearchViewModelTests {
    @Test("starts in idle state")
    @Test("searching updates state to loading")
    @Test("successful search shows results")
    @Test("empty search shows empty state")
    @Test("failed search shows error")
    @Test("debounces rapid input")
    @Test("cancels previous search on new input")
}
```

### Data Layer Feature

```swift
@Suite("ItemRepository")
struct ItemRepositoryTests {
    @Test("fetches items from remote")
    @Test("caches fetched items locally")
    @Test("returns cached items when offline")
    @Test("syncs local changes to remote")
    @Test("handles conflict resolution")
    @Test("deletes expire cached items")
}
```

### Business Logic Feature

```swift
@Suite("SubscriptionManager")
struct SubscriptionManagerTests {
    @Test("free user has basic access")
    @Test("pro user has full access")
    @Test("expired subscription reverts to free")
    @Test("family member inherits subscription")
    @Test("trial period grants pro access")
    @Test("grace period maintains access after lapse")
}
```

## Output Format

```markdown
## TDD Feature: [Feature Name]

### API Design
```swift
// Protocol / public interface
```

### Tests Written (RED)
1. `startsEmpty` — Initial state
2. `addFavorite` — Happy path
3. `removeFavorite` — State change
4. `addDuplicate` — Edge case
5. `removeNonExistent` — Edge case
6. `storageFullError` — Error handling

### Implementation (GREEN)
**File**: `Sources/Features/FavoriteManager.swift`
All [X] tests passing.

### Refactoring Done
- Extracted storage logic to private method
- Renamed internal property for clarity

### Next Steps
- [ ] Add integration tests with persistence
- [ ] Wire up to ViewModel
- [ ] Add UI for favorite toggle
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Writing too many tests before implementing | Overwhelming; can't see progress | Write 2-3 tests, implement, repeat |
| Tests that test implementation | Brittle; break on refactor | Test behavior and outcomes only |
| Skipping the refactor step | Accumulating technical debt | Refactor every 3-5 green cycles |
| AI implementing beyond the tests | Untested code in production | Only implement what tests require |
| Not running tests after each change | Silent regressions | `xcodebuild test` after every edit |

## References

- Kent Beck, *Test-Driven Development: By Example*
- `testing/test-contract/` — for protocol-level test suites
- `testing/test-data-factory/` — for reducing test setup boilerplate
- `generators/test-generator/` — for standalone test generation

---

## Bug Fix Scenario (吸纳自 tdd-bug-fix)


# TDD Bug Fix

Fix bugs the right way: reproduce first, fix second, verify always. Especially critical when using AI to generate fixes — the test ensures the AI actually solved the problem.

## When This Skill Activates

Use this skill when the user:
- Reports a bug and wants it fixed
- Says "this is broken" or "this doesn't work"
- Asks to "fix and add a test" or "fix with TDD"
- Wants to ensure a bug doesn't come back
- Is skeptical of AI-generated fixes ("how do I know it's actually fixed?")

## Why TDD for Bug Fixes

```
Without TDD:           With TDD:
Bug reported           Bug reported
  → AI generates fix     → Write failing test (RED)
  → Deploy               → AI generates fix (GREEN)
  → Hope it works        → Test passes — confirmed fixed
  → Bug returns later    → Test prevents regression forever
```

## Process

### Phase 1: Understand the Bug

Gather information:

1. **What's the expected behavior?**
2. **What's the actual behavior?**
3. **Steps to reproduce?**
4. **Which code is involved?**

```
Grep: "[relevant keyword]" to find the source
Read: the suspected file(s)
```

Identify:
- [ ] The function/method where the bug lives
- [ ] The input that triggers the bug
- [ ] The incorrect output/behavior
- [ ] The correct expected output/behavior

### Phase 2: RED — Write the Failing Test

Write a test that **fails because of the bug**. This proves the bug exists.

#### Template: Logic Bug

```swift
import Testing
@testable import YourApp

@Suite("Bug Fix: [Brief description]")
struct BugFix_DescriptionTests {

    @Test("should [expected behavior] — was [actual behavior]")
    func reproduceBug() {
        // Arrange — set up the conditions that trigger the bug
        let calculator = PriceCalculator()

        // Act — perform the operation that's broken
        let result = calculator.applyDiscount(price: 100, percent: 50)

        // Assert — what it SHOULD return (this will FAIL now)
        #expect(result == 50.0)  // Currently returns 0.5 (bug: divides by 100 twice)
    }
}
```

#### Template: Async Bug

```swift
@Test("should return cached items when network fails — was crashing")
func reproduceBug() async throws {
    let mockNetwork = MockNetworkClient(shouldFail: true)
    let mockCache = MockCache(items: [.sample])
    let service = DataService(network: mockNetwork, cache: mockCache)

    // This should return cached data, but currently crashes
    let items = try await service.fetchItems()

    #expect(items.count == 1)
}
```

#### Template: State Bug

```swift
@Test("should update count after deletion — was showing stale count")
func reproduceBug() {
    let manager = ItemManager()
    manager.addItem(Item(title: "Test"))

    manager.deleteItem(at: 0)

    #expect(manager.count == 0)     // Currently still returns 1
    #expect(manager.items.isEmpty)  // Currently still contains item
}
```

#### Template: Edge Case Bug

```swift
@Test("should handle empty input — was crashing with index out of range")
func reproduceBug() {
    let parser = CSVParser()

    // This crashes with empty string
    let result = parser.parse("")

    #expect(result.rows.isEmpty)
    #expect(result.columns.isEmpty)
}
```

#### Template: UI State Bug

```swift
@Test("should show error state when API fails — was showing infinite spinner")
func reproduceBug() async {
    let failingAPI = MockAPI(shouldFail: true)
    let viewModel = ListViewModel(api: failingAPI)

    await viewModel.loadData()

    #expect(viewModel.state == .error)  // Currently stuck on .loading
    #expect(viewModel.isLoading == false)
}
```

**Run the test — it MUST fail.** If it passes, you haven't reproduced the bug.

```bash
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/BugFix_DescriptionTests"
```

### Phase 3: GREEN — Fix the Bug

Now fix the code to make the test pass. The fix should be **minimal** — only change what's needed.

#### Fix Guidelines

- **Change as little code as possible** to make the test pass
- **Don't refactor while fixing** — that's the next step
- **Don't fix other issues** you notice — file them separately
- **AI should target the specific test** — give Claude the failing test as context

```
Prompt to Claude: "Here's a failing test that reproduces a bug.
Fix the source code to make this test pass without breaking
any existing tests."
```

**Run the test — it MUST pass now.**

```bash
# Run the bug fix test
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/BugFix_DescriptionTests"

# Run ALL tests to check for regressions
xcodebuild test -scheme YourApp
```

### Phase 4: REFACTOR (Optional)

If the fix introduced duplication or the code could be cleaner:

1. **Refactor only with all tests passing**
2. **Run tests after each change**
3. **Keep the bug fix test** — it's now a permanent regression test

### Phase 5: Verify Completeness

Checklist before marking the bug as fixed:

- [ ] Failing test written that reproduces the bug
- [ ] Fix implemented — test now passes
- [ ] All existing tests still pass (no regressions)
- [ ] Edge cases covered (empty, nil, boundary values)
- [ ] Test is clearly named and documents the bug
- [ ] Fix is minimal — no unrelated changes

## Multiple Related Bugs

If a bug has multiple symptoms, write multiple tests:

```swift
@Suite("Bug Fix: Discount calculation errors")
struct BugFix_DiscountCalculationTests {

    @Test("50% discount on $100 should be $50")
    func fiftyPercentDiscount() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 100, percent: 50) == 50.0)
    }

    @Test("0% discount should return original price")
    func zeroDiscount() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 100, percent: 0) == 100.0)
    }

    @Test("100% discount should return 0")
    func fullDiscount() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 100, percent: 100) == 0.0)
    }

    @Test("discount on $0 should return $0")
    func zeroPrice() {
        let calc = PriceCalculator()
        #expect(calc.applyDiscount(price: 0, percent: 50) == 0.0)
    }
}
```

## Output Format

```markdown
## Bug Fix: [Description]

### Bug Summary
- **Expected**: [What should happen]
- **Actual**: [What was happening]
- **Root cause**: [Why it was broken]

### Test (RED)
```swift
// Failing test that reproduces the bug
```

### Fix (GREEN)
**File**: `path/to/file.swift:XX`
```swift
// Before (buggy)
// After (fixed)
```

### Verification
- [x] Bug test fails before fix
- [x] Bug test passes after fix
- [x] All existing tests still pass
- [x] Edge cases covered: [list]

### Regression Prevention
Test added: `Tests/BugFixes/BugFix_DescriptionTests.swift`
This test will catch any future regression of this bug.
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Test passes before fix | You didn't reproduce the bug | Make assertions more specific |
| Fix breaks other tests | Fix was too broad | Revert and use smaller, targeted change |
| Test is too specific | Brittle, breaks on unrelated changes | Test behavior, not implementation details |
| Skipping the red step | No proof the test catches the bug | Always verify test fails first |
| Fixing multiple bugs at once | Can't isolate regressions | One bug = one test + one fix |

## References

- `testing/tdd-feature/` — for new features (not bug fixes)
- `testing/characterization-test-generator/` — for capturing existing behavior first
- `generators/test-generator/` — for general test generation

---

## Refactor Scenario (吸纳自 tdd-refactor-guard)


# TDD Refactor Guard

A safety gate that runs before any AI-assisted refactoring. Ensures tests exist to catch regressions. If coverage is insufficient, generates characterization tests first.

## When This Skill Activates

Use this skill when the user:
- Says "refactor this" or "clean this up"
- Wants AI to "restructure" or "reorganize" code
- Asks to "extract", "inline", "rename", or "simplify" existing code
- Plans to migrate between patterns (e.g., MVC → MVVM, CoreData → SwiftData)
- Wants AI to "improve" or "modernize" existing code

## Why This Guard Exists

```
Without guard:               With guard:
"Claude, refactor this"      "Claude, refactor this"
  → AI rewrites code           → Guard checks for tests
  → Something breaks           → Tests missing → generate them
  → You don't know what        → Tests pass → proceed with refactor
  → Debugging nightmare         → Tests fail → exact regression found
```

## Process

### Step 1: Identify Scope

What code is being refactored?

```
Ask user: "Which files/classes are you planning to refactor?"
```

Or detect from context:
```
Glob: [files mentioned in conversation]
Read: each file to understand scope
```

Determine:
- [ ] Files involved
- [ ] Public API surface (methods, properties)
- [ ] Dependencies (what calls this code, what it calls)
- [ ] Side effects (network, disk, notifications, UI updates)

### Step 2: Check Existing Test Coverage

```
Grep: "class.*Tests.*XCTestCase|@Suite.*Tests|struct.*Tests" in test targets
Grep: "@Test|func test" that reference the classes being refactored
```

#### Coverage Assessment

| Level | Criteria | Action |
|-------|----------|--------|
| Good (> 80%) | Most public methods have tests for happy + error paths | Proceed with refactoring |
| Partial (40-80%) | Some methods tested, missing edge cases | Add characterization tests for uncovered methods |
| Minimal (< 40%) | Few or no tests | Generate full characterization test suite first |
| None (0%) | No test file exists | STOP — create characterization tests before any refactoring |

### Step 3: Evaluate Test Quality

Even if tests exist, check quality:

```swift
// ❌ Low-quality test — doesn't actually verify behavior
@Test("test items")
func testItems() {
    let vm = ViewModel()
    vm.loadItems()
    #expect(true)  // Always passes, tests nothing
}

// ❌ Tests implementation, not behavior
@Test("calls repository")
func testCallsRepo() {
    let vm = ViewModel()
    vm.loadItems()
    #expect(mockRepo.fetchCallCount == 1)  // Brittle
}

// ✅ Tests observable behavior
@Test("loads items into published array")
func testLoadsItems() async {
    let vm = ViewModel(repo: MockRepo(items: [.sample]))
    await vm.loadItems()
    #expect(vm.items.count == 1)
    #expect(vm.items.first?.title == "Sample")
}
```

**Quality checklist:**
- [ ] Tests verify **outputs/state**, not implementation details
- [ ] Both happy path and error paths covered
- [ ] Edge cases (empty, nil, boundary) tested
- [ ] Async behavior properly awaited
- [ ] No `#expect(true)` or always-passing assertions

### Step 4: Generate Missing Tests

If coverage is insufficient, use `characterization-test-generator/`:

```markdown
Before refactoring [ClassName], generate characterization tests:
1. Read the source file
2. Identify all public methods
3. Generate tests that capture CURRENT behavior
4. Run and verify all pass
```

### Step 5: Green Light / Red Light

#### Green Light — Proceed

```markdown
## Refactor Guard: ✅ PROCEED

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: Good (12 tests covering 8/9 public methods)
**Test quality**: Adequate — tests verify behavior, not implementation

Safe to refactor. Run tests after each change:
`xcodebuild test -scheme YourApp`
```

#### Yellow Light — Needs Work

```markdown
## Refactor Guard: ⚠️ NEEDS TESTS

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: Partial (5 tests covering 4/9 public methods)
**Missing coverage**:
- `ItemManager.sort()` — no test
- `ItemManager.filter(by:)` — no test
- `ItemRepository.sync()` — no test
- Error paths for `save()` and `delete()` — not tested

**Action**: Generate characterization tests for uncovered methods before refactoring.
Use `characterization-test-generator` skill.
```

#### Red Light — Stop

```markdown
## Refactor Guard: 🔴 STOP

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: None (0 tests found)

**Action**: Do NOT refactor until characterization tests exist.
Refactoring without tests is like surgery without monitoring —
you won't know if you killed the patient.

Run `characterization-test-generator` on:
1. ItemManager (7 public methods)
2. ItemRepository (5 public methods)

Then re-run this guard.
```

### Step 6: Post-Refactor Verification

After refactoring is complete:

```bash
# Run all tests
xcodebuild test -scheme YourApp

# Check specifically for regressions
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/ItemManagerCharacterizationTests"
```

- [ ] All pre-existing tests still pass
- [ ] Characterization tests still pass
- [ ] No new warnings or errors
- [ ] Public API surface unchanged (unless intentionally changed)

## Refactoring Safeguards

### Safe Refactorings (Low Risk)

These typically don't change behavior:
- Rename variable/method/type
- Extract method/function
- Inline temporary variable
- Move method to another type (keeping same behavior)
- Extract protocol from class

### Risky Refactorings (Need Good Coverage)

These can change behavior:
- Change method signature
- Reorder operations
- Replace algorithm
- Merge/split classes
- Change data structure
- Introduce async/await to sync code
- Migration between frameworks (CoreData → SwiftData)

### Migration Refactorings (Need Comprehensive Coverage)

Full contract tests recommended:
- Architecture change (MVC → MVVM)
- Framework migration (UIKit → SwiftUI)
- Storage migration (UserDefaults → SwiftData)
- Concurrency model change (GCD → async/await)

## Output Format

```markdown
## Refactor Guard Report

**Scope**: [Files/classes to be refactored]
**Verdict**: ✅ PROCEED / ⚠️ NEEDS TESTS / 🔴 STOP

### Coverage Summary
| Class | Public Methods | Tests | Coverage | Verdict |
|-------|---------------|-------|----------|---------|
| ItemManager | 9 | 12 | 89% | ✅ |
| ItemRepository | 5 | 2 | 40% | ⚠️ |

### Missing Coverage
- [ ] `ItemRepository.sync()` — needs characterization test
- [ ] Error path for `ItemRepository.delete()` — untested

### Recommendations
1. [Action item]
2. [Action item]
```

## References

- `testing/characterization-test-generator/` — generates tests this guard may require
- `testing/tdd-feature/` — for building new code during refactor
- Martin Fowler, *Refactoring: Improving the Design of Existing Code*

---

## Integration Test Scenario (吸纳自 integration-test-scaffold)


# Integration Test Scaffold Adapter

Shared skill source:

`../../../.agents/skills/integration-test-scaffold/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

---

## Refactor Safety Net (吸纳自 characterization-test-generator)


# Characterization Test Generator Adapter

Shared skill source:

`../../../.agents/skills/characterization-test-generator/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

---

## Visual Regression Scenario (吸纳自 snapshot-testing)


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
- `snapshot-diff-review` skill (项目本地) — baseline 变更审查流程

---

## Snapshot Diff Review (吸纳自 snapshot-diff-review, 经 snapshot-testing 链式合并)


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
- `docs/protocol.md:127` — Snapshot baseline 变更必须 git diff 确认

## 关联文档

- `docs/standards/testing.md` — 测试规则
- `docs/protocol.md` §CI — CI 与本地一致性
