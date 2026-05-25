---
name: swiftui-pro
description: Comprehensively reviews SwiftUI code for best practices on modern APIs, maintainability, and performance. Use when reading, writing, or reviewing SwiftUI projects.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.1"
---

Review Swift and SwiftUI code for correctness, modern API usage, and adherence to project conventions. Report only genuine problems - do not nitpick or invent issues.

Review process:

1. Check for deprecated API using `references/api.md`.
1. Check that views, modifiers, and animations have been written optimally using `references/views.md`.
1. Validate that data flow is configured correctly using `references/data.md`.
1. Ensure navigation is updated and performant using `references/navigation.md`.
1. Ensure the code uses designs that are accessible and compliant with Apple’s Human Interface Guidelines using `references/design.md`.
1. Validate accessibility compliance including Dynamic Type, VoiceOver, and Reduce Motion using `references/accessibility.md`.
1. Ensure the code is able to run efficiently using `references/performance.md`.
1. Quick validation of Swift code using `references/swift.md`.
1. Final code hygiene check using `references/hygiene.md`.

If doing a partial review, load only the relevant reference files.


## Core Instructions

- iOS 26 exists, and is the default deployment target for new apps.
- Target Swift 6.2 or later, using modern Swift concurrency.
- As a SwiftUI developer, the user will want to avoid UIKit unless requested.
- Do not introduce third-party frameworks without asking first.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Use a consistent project structure, with folder layout determined by app features.


## Output Format

Organize findings by file. For each issue:

1. State the file and relevant line(s).
2. Name the rule being violated (e.g., "Use `foregroundStyle()` instead of `foregroundColor()`").
3. Show a brief before/after code fix.

Skip files with no issues. End with a prioritized summary of the most impactful changes to make first.

Example output:

### ContentView.swift

**Line 12: Use `foregroundStyle()` instead of `foregroundColor()`.**

```swift
// Before
Text("Hello").foregroundColor(.red)

// After
Text("Hello").foregroundStyle(.red)
```

**Line 24: Icon-only button is bad for VoiceOver - add a text label.**

```swift
// Before
Button(action: addUser) {
    Image(systemName: "plus")
}

// After
Button("Add User", systemImage: "plus", action: addUser)
```

**Line 31: Avoid `Binding(get:set:)` in view body - use `@State` with `onChange()` instead.**

```swift
// Before
TextField("Username", text: Binding(
    get: { model.username },
    set: { model.username = $0; model.save() }
))

// After
TextField("Username", text: $model.username)
    .onChange(of: model.username) {
        model.save()
    }
```

### Summary

1. **Accessibility (high):** The add button on line 24 is invisible to VoiceOver.
2. **Deprecated API (medium):** `foregroundColor()` on line 12 should be `foregroundStyle()`.
3. **Data flow (medium):** The manual binding on line 31 is fragile and harder to maintain.

End of example.


## References

- `references/accessibility.md` - Dynamic Type, VoiceOver, Reduce Motion, and other accessibility requirements.
- `references/api.md` - updating code for modern API, and the deprecated code it replaces.
- `references/design.md` - guidance for building accessible apps that meet Apple’s Human Interface Guidelines.
- `references/hygiene.md` - making code compile cleanly and be maintainable in the long term.
- `references/navigation.md` - navigation using `NavigationStack`/`NavigationSplitView`, plus alerts, confirmation dialogs, and sheets.
- `references/performance.md` - optimizing SwiftUI code for maximum performance.
- `references/data.md` - data flow, shared state, and property wrappers.
- `references/swift.md` - tips on writing modern Swift code, including using Swift Concurrency effectively.
- `references/views.md` - view structure, composition, and animation.

---

## Performance Debugging (吸纳自 swiftui-debugging)


# SwiftUI Performance Debugging

Systematic guide for diagnosing and fixing SwiftUI performance problems: unnecessary view re-evaluations, identity issues, expensive body computations, and lazy loading mistakes.

## When This Skill Activates

Use this skill when the user:
- Reports slow or janky SwiftUI views
- Sees excessive view re-renders or body re-evaluations
- Asks about `Self._printChanges()` or view debugging
- Has scrolling performance issues with lists or grids
- Asks why a view keeps updating when nothing changed
- Mentions `@Observable` or `ObservableObject` performance differences
- Wants to understand SwiftUI view identity or diffing
- Uses `AnyView` and asks about performance implications
- Has a hang or stutter traced to SwiftUI rendering

## Decision Tree

```
What SwiftUI performance problem are you seeing?
|
+- Views re-render when they should not
|  +- Read body-reevaluation.md
|     +- Self._printChanges() to identify which property changed
|     +- @Observable vs ObservableObject observation differences
|     +- Splitting views to narrow observation scope
|
+- Scrolling is slow / choppy (lists, grids)
|  +- Read lazy-loading.md
|     +- VStack vs LazyVStack, ForEach without lazy container
|     +- List prefetching, grid cell reuse
|
+- Views lose state unexpectedly / animate when they should not
|  +- Read view-identity.md
|     +- Structural vs explicit identity
|     +- .id() misuse, conditional view branching
|
+- Known pitfall (AnyView, DateFormatter in body, etc.)
|  +- Read common-pitfalls.md
|     +- AnyView type erasure, object creation in body
|     +- Over-observation, expensive computations
|
+- General "my SwiftUI app is slow" (unknown cause)
|  +- Start with body-reevaluation.md, then common-pitfalls.md
|  +- Use Instruments SwiftUI template (see Debugging Tools below)
```

## API Availability

| API / Technique | Minimum Version | Reference |
|----------------|-----------------|-----------|
| `Self._printChanges()` | iOS 15 | body-reevaluation.md |
| `@Observable` | iOS 17 / macOS 14 | body-reevaluation.md |
| `@ObservableObject` | iOS 13 | body-reevaluation.md |
| `LazyVStack` / `LazyHStack` | iOS 14 | lazy-loading.md |
| `LazyVGrid` / `LazyHGrid` | iOS 14 | lazy-loading.md |
| `.id()` modifier | iOS 13 | view-identity.md |
| Instruments SwiftUI template | Xcode 14+ | SKILL.md |
| `os_signpost` | iOS 12 | SKILL.md |

## Top 5 Mistakes -- Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | Large `ForEach` inside `VStack` or `ScrollView` without lazy container | Wrap in `LazyVStack` -- eager `VStack` creates all views upfront | lazy-loading.md |
| 2 | Using `AnyView` to erase types | Use `@ViewBuilder`, `Group`, or concrete generic types -- `AnyView` defeats diffing | common-pitfalls.md |
| 3 | Creating objects in `body` (`DateFormatter()`, `NumberFormatter()`) | Use `static let` shared instances or `@State` for mutable objects | common-pitfalls.md |
| 4 | Observing entire model when only one property is needed | Split into smaller `@Observable` objects or extract subviews | body-reevaluation.md |
| 5 | Unstable `.id()` values causing full view recreation every render | Use stable identifiers (database IDs, UUIDs), never array indices or random values | view-identity.md |

## Debugging Tools

### Self._printChanges()

Add to any view body to see what triggered re-evaluation:

```swift
var body: some View {
    let _ = Self._printChanges()
    // ... view content
}
```

Output reads: `ViewName: @self, @identity, _propertyName changed.`
See body-reevaluation.md for full interpretation guide.

### Instruments SwiftUI Template

1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **SwiftUI** template (includes View Body, View Properties, Core Animation Commits)
3. Record, reproduce the slow interaction, stop
4. **View Body** lane shows which views had their body evaluated and how often
5. **View Properties** lane shows which properties changed

### os_signpost for Custom Measurement

```swift
import os

private let perfLog = OSLog(subsystem: "com.app.perf", category: "SwiftUI")

var body: some View {
    let _ = os_signpost(.event, log: perfLog, name: "MyView.body")
    // ... view content
}
```

View in Instruments with the **os_signpost** instrument to count body evaluations per second.

## Review Checklist

### View Identity
- [ ] No unstable `.id()` values (random, Date(), array index on mutable arrays)
- [ ] Conditional branches (`if`/`else`) do not cause unnecessary view destruction
- [ ] `ForEach` uses stable, unique identifiers from the model

### Body Re-evaluation
- [ ] Views observe only the properties they actually use
- [ ] `@Observable` classes preferred over `ObservableObject` (iOS 17+)
- [ ] No unnecessary `@State` changes that trigger body re-evaluation
- [ ] Large views split into smaller subviews to narrow observation scope

### Lazy Loading
- [ ] Large collections use `LazyVStack` / `LazyHStack`, not `VStack` / `HStack`
- [ ] `List` or lazy stack used for 50+ items
- [ ] No `.frame(maxHeight: .infinity)` on children inside lazy containers (defeats laziness)

### Common Pitfalls
- [ ] No `AnyView` type erasure (use `@ViewBuilder` or `Group`)
- [ ] No object allocation in `body` (`DateFormatter`, `NSPredicate`, view models)
- [ ] Expensive computations moved to background with `task { }` or `Task.detached`
- [ ] Images use `AsyncImage` or `.resizable()` with proper sizing, not raw `UIImage` decoding in body

## Reference Files

| File | Content |
|------|---------|
| [view-identity.md](view-identity.md) | Structural vs explicit identity, `.id()` usage, conditional branching |
| [body-reevaluation.md](body-reevaluation.md) | What triggers body, `_printChanges()`, `@Observable` vs `ObservableObject` |
| [lazy-loading.md](lazy-loading.md) | Lazy vs eager containers, `List`, `ForEach`, grid performance |
| [common-pitfalls.md](common-pitfalls.md) | `AnyView`, object creation in body, over-observation, expensive computations |
| [../profiling/SKILL.md](../profiling/SKILL.md) | General Instruments profiling (Time Profiler, Memory, Energy) |

---

## HIG Review & Accessibility (吸纳自 ui-review)


# UI Review Skill

Performs comprehensive UI/UX review of SwiftUI code against Apple's Human Interface Guidelines, font best practices, and accessibility standards for iOS and watchOS.

## When This Skill Activates

Use this skill when the user:
- Asks to review UI/UX code
- Mentions HIG compliance or Apple guidelines
- Requests accessibility audit
- Wants font usage checked
- Asks about Dynamic Type support
- Requests design review against Apple standards

## Review Process

### 1. Identify Files to Review

- If user specifies files/views, review those
- Otherwise, ask which views to review or scan recent SwiftUI files
- Prioritize user-facing views over components

### 2. Load Reference Materials

Before starting the review, familiarize yourself with the reference materials by reading the following files in `.claude/skills/ui-review/`:

- **hig-checklist.md** - Comprehensive HIG compliance checklist for iOS and watchOS
- **font-guidelines.md** - Font usage, Dynamic Type, and typography best practices
- **accessibility-quick-ref.md** - Quick reference for accessibility implementation

You may also reference the official Apple guidelines using WebFetch when needed:
- **iOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- **watchOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

### 3. Review Categories

Apply these review categories based on the code type:

**HIG Compliance:**
- Layout & spacing (tap targets, safe areas, padding)
- Navigation patterns (NavigationStack, sheets, alerts)
- Colors & visuals (semantic colors, dark mode, contrast)
- Platform-specific requirements (iOS vs watchOS)
- Loading/empty/error states

**Font Usage:**
- Dynamic Type support
- System text styles vs fixed sizes
- Font hierarchy and semantic usage
- Custom fonts scaling properly
- Text formatting and truncation

**Accessibility:**
- Labels and hints for interactive elements
- Traits and roles
- VoiceOver navigation order
- Custom actions
- Dynamic content announcements
- Testing with assistive technologies

### 4. Common Issues to Flag

**Anti-patterns:**
- Hardcoded colors (`.foregroundColor(.black)`)
- Fixed font sizes (`.font(.system(size: 14))`)
- Missing accessibility labels on icon-only buttons
- Tap targets smaller than 44pt (iOS) or 40pt (watchOS)
- Important info conveyed by color only
- Missing loading/error states
- Direct UIColor usage (use `Color(.systemBackground)`)
- `.frame()` without considering Dynamic Type expansion
- Missing keyboard shortcuts (iPad/Mac)

**Good Patterns:**
- Semantic color usage
- System font styles with Dynamic Type
- Comprehensive accessibility labels
- Clear visual hierarchy
- Consistent spacing
- Proper error handling
- Responsive layouts

## Output Format

Provide review in this structure:

### ✅ HIG Compliance
- List items that comply well
- Highlight good practices

### ⚠️ HIG Issues Found
- Specific line references: `filename.swift:lineNumber`
- Description of issue
- Suggested fix with code example

### ✅ Font Usage
- Proper Dynamic Type usage
- Good font hierarchy

### ⚠️ Font Issues Found
- Hardcoded sizes or missing Dynamic Type support
- Suggested fixes

### ✅ Accessibility
- Well-implemented accessibility features
- Good label/hint usage

### ⚠️ Accessibility Issues Found
- Missing labels or hints
- Incorrect traits
- Navigation problems
- Suggested fixes with code examples

### 📋 Testing Recommendations
- Specific tests to run (VoiceOver, Dynamic Type, Dark Mode)
- Accessibility Inspector checks
- Device/simulator testing suggestions

## Example Review Output

```
Reviewing: AddOrUpdateExpenseView.swift

✅ HIG Compliance
- Good use of semantic colors throughout
- Proper NavigationStack implementation
- Safe area handling is correct

⚠️ HIG Issues Found
1. AddOrUpdateExpenseView.swift:145 - Delete button tap target may be small
   Suggested fix: Ensure .frame(minWidth: 44, minHeight: 44)

2. AddOrUpdateExpenseView.swift:203 - Hardcoded color
   Current: .foregroundColor(.red)
   Suggested: .foregroundColor(Color(.systemRed))

✅ Font Usage
- Excellent use of .headline for section headers
- Proper .body for content text

⚠️ Font Issues Found
1. AddOrUpdateExpenseView.swift:178 - Hardcoded font size
   Current: .font(.system(size: 14))
   Suggested: .font(.subheadline)

✅ Accessibility
- Good labels on most form fields
- Proper form structure

⚠️ Accessibility Issues Found
1. AddOrUpdateExpenseView.swift:92 - Icon button missing label
   Current: Button { } label: { Image(systemName: "calendar") }
   Suggested: Add .accessibilityLabel("Select date")

📋 Testing Recommendations
1. Test with VoiceOver enabled
2. Test at largest Dynamic Type size (Accessibility → Display)
3. Verify in Dark Mode
4. Use Accessibility Inspector to check contrast ratios
```

## References

Always reference these when in doubt:
- [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [watchOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Accessibility on Apple platforms](https://developer.apple.com/accessibility/)

## Notes

- Be constructive and specific
- Provide code examples for fixes
- Reference exact line numbers
- Prioritize user-impacting issues
- Consider context (some exceptions are valid)

---

## Accessibility Generator (吸纳自 accessibility-generator)


# Accessibility Generator Skill Adapter

Shared skill source:

`../../../.agents/skills/accessibility-generator/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.
