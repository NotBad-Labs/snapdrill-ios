---
last_verified: 2026-05-25
layer: principle
scope: standards
freshness:
  max_age_days: 90
  decay_trigger: [ios_sdk_update, skill_audit_ratified]
derived_from: [M-005 §A]
---
# SwiftUI 模式集合 (Patterns Standards)

> 路径 C #018 ratify 后新建的 standards 文件，吸纳 3 个 *-patterns skill 内容。


---

## 动画模式 (吸纳自 animation-patterns)


# Animation Patterns

Correct API shapes and patterns for SwiftUI animations. Prevents the most common mistakes: mixed spring parameter generations, wrong PhaseAnimator/KeyframeAnimator closure signatures, and using matchedGeometryEffect where matchedTransitionSource is needed.

## When This Skill Activates

Use this skill when the user:
- Asks to add, fix, or review **animation** code
- Mentions **spring**, **bounce**, or **snappy** animations
- Wants **view transitions** (insertion/removal, hero, zoom)
- Asks about **PhaseAnimator** or **KeyframeAnimator**
- Wants **SF Symbol effects** (bounce, pulse, wiggle, breathe)
- Mentions **matchedGeometryEffect** or **matchedTransitionSource**
- Asks about **reduce motion** / animation accessibility
- Wants to sequence or chain animations
- Mentions **withAnimation**, **animation completions**, or **Transaction**

## Decision Tree

Choose the right reference file based on what the user needs:

```
What are you animating?
│
├─ A state change (opacity, position, color)
│  └─ → core-animations.md
│     ├─ withAnimation { } — explicit animation
│     ├─ .animation(_:value:) — implicit animation
│     └─ Spring configuration — .spring, .bouncy, .snappy, .smooth
│
├─ A multi-step / sequenced animation
│  └─ → phase-keyframe-animators.md (PhaseAnimator)
│     └─ Cycles through discrete phases automatically or on trigger
│
├─ A complex multi-property animation (scale + rotation + offset)
│  └─ → phase-keyframe-animators.md (KeyframeAnimator)
│     └─ Timeline-based keyframes with per-property tracks
│
├─ A view appearing / disappearing
│  └─ → transitions.md
│     ├─ .transition() — insertion/removal
│     ├─ .contentTransition() — text/symbol changes
│     └─ .asymmetric() — different in/out
│
├─ A hero / zoom navigation transition
│  └─ → transitions.md (matchedTransitionSource section)
│     ├─ iOS 18+: matchedTransitionSource + .navigationTransition(.zoom)
│     └─ iOS 14+: matchedGeometryEffect (NOT for NavigationStack)
│
├─ An SF Symbol animation
│  └─ → symbol-effects.md
│     └─ .symbolEffect(.bounce), .pulse, .wiggle, .breathe, .rotate
│
└─ Spring physics / timing configuration
   └─ → core-animations.md (Spring Configurations section)
```

## API Availability

| API | Minimum Version | Reference |
|-----|----------------|-----------|
| `withAnimation` | iOS 13 | core-animations.md |
| `.animation(_:value:)` | iOS 13 | core-animations.md |
| `.spring(response:dampingFraction:)` | iOS 13 | core-animations.md |
| `.matchedGeometryEffect` | iOS 14 | transitions.md |
| `.transition(.push(from:))` | iOS 16 | transitions.md |
| `.contentTransition(.numericText())` | iOS 16 | transitions.md |
| `PhaseAnimator` | iOS 17 | phase-keyframe-animators.md |
| `KeyframeAnimator` | iOS 17 | phase-keyframe-animators.md |
| `.spring(duration:bounce:)` | iOS 17 | core-animations.md |
| Spring presets (`.bouncy`, `.snappy`, `.smooth`) | iOS 17 | core-animations.md |
| `withAnimation(_:completionCriteria:_:completion:)` | iOS 17 | core-animations.md |
| `.symbolEffect()` | iOS 17 | symbol-effects.md |
| `.transition(.blurReplace)` | iOS 17 | transitions.md |
| `.contentTransition(.symbolEffect(.replace))` | iOS 17 | transitions.md |
| `.matchedTransitionSource` | iOS 18 | transitions.md |
| `.navigationTransition(.zoom)` | iOS 18 | transitions.md |

## Top 5 Mistakes — Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | `spring(response:bounce:)` — mixing parameter generations | Use either `spring(response:dampingFraction:)` (iOS 13) or `spring(duration:bounce:)` (iOS 17) | core-animations.md |
| 2 | `.animation(.spring())` without `value:` parameter | Always pass `value:` — the no-value variant is deprecated (iOS 15) | core-animations.md |
| 3 | Wrong PhaseAnimator closure signature | `PhaseAnimator(phases) { content, phase in }` — not `{ phase in }` | phase-keyframe-animators.md |
| 4 | Using `matchedGeometryEffect` for NavigationStack transitions | Use `matchedTransitionSource` + `.navigationTransition(.zoom)` on iOS 18+ | transitions.md |
| 5 | Using `withAnimation` for SF Symbol effects | Use `.symbolEffect()` modifier instead | symbol-effects.md |

## Review Checklist

When reviewing animation code, verify:

- [ ] **Reduce motion** — animations respect `AccessibilityMotionEffect` or `UIAccessibility.isReduceMotionEnabled`; provide non-motion alternatives
- [ ] **Duration limits** — no animation exceeds ~0.5s for UI feedback; longer only for decorative/ambient effects
- [ ] **Spring vs linear** — springs for interactive/physical motion; linear/easeInOut only for opacity fades or progress indicators
- [ ] **No deprecated APIs** — `.animation(.spring())` without `value:` is deprecated; `.animation(nil)` is replaced by `withTransaction`
- [ ] **Correct spring generation** — parameter names match the same API generation (never mix `response` with `bounce`)
- [ ] **Completion handlers** — using `withAnimation(_:completionCriteria:_:completion:)` (iOS 17+), not inventing `.onAnimationCompleted`
- [ ] **Transition scope** — `.transition()` only affects views inside `if`/`switch` controlled by state; not for views that are always present

## Reference Files

| File | Content |
|------|---------|
| `core-animations.md` | withAnimation, springs, completions, transactions, timing curves |
| `phase-keyframe-animators.md` | PhaseAnimator, KeyframeAnimator, custom animations |
| `transitions.md` | View transitions, matched geometry, navigation transitions |
| `symbol-effects.md` | SF Symbol effects, accessibility |

注：上述 references 文件已随 animation-patterns 归档至 `docs/archive/skills/2026-05-25/animation-patterns/`（但原 skill 只含 SKILL.md，references 未单独建立——上表为 SKILL.md 中的占位结构）。

---

## 迁移模式 (吸纳自 migration-patterns)


# Migration Patterns

Comprehensive guides for migrating between Apple framework generations. Each guide covers the full before/after mapping, coexistence strategies, and common pitfalls.

## When This Skill Activates

- User asks how to migrate from CoreData to SwiftData
- User is moving UIKit code to SwiftUI (or embedding one in the other)
- User needs to update from ObservableObject/Combine to @Observable/AsyncSequence
- User is converting XCTest tests to Swift Testing
- User asks about coexistence strategies (running old and new frameworks side by side)
- User wants to know whether a migration is worth doing for their situation
- User is migrating Objective-C code to Swift (bridging headers, incremental migration)
- User is migrating from StoreKit 1 to StoreKit 2 (in-app purchases, subscriptions)
- User encounters errors during a framework migration

## Decision Tree

```
What are you migrating?
|
+-- Data persistence layer
|   +-- CoreData --> SwiftData
|   |   See coredata-to-swiftdata.md
|   |   Min: iOS 17 / macOS 14
|   |
|   +-- Still need CoreData features SwiftData lacks?
|       Stay on CoreData or use coexistence mode
|
+-- UI framework
|   +-- UIKit --> SwiftUI
|   |   See uikit-to-swiftui.md
|   |   Min: iOS 13 (basic), iOS 16+ (modern navigation)
|   |
|   +-- Full rewrite or incremental?
|       Incremental is almost always better -- adopt screen by screen
|
+-- State management / observation
|   +-- ObservableObject --> @Observable
|   |   See observable-migration.md
|   |   Min: iOS 17 / macOS 14
|   |
|   +-- Combine publishers --> AsyncSequence
|       Also covered in observable-migration.md
|
+-- Programming language
|   +-- Objective-C --> Swift
|   |   See objc-to-swift.md
|   |   Incremental: migrate leaves first, trunks last
|   |
|   +-- Mixed-language project?
|       Both languages coexist via bridging headers
|
+-- In-app purchases
|   +-- StoreKit 1 --> StoreKit 2
|   |   See storekit-migration.md
|   |   Min: iOS 15
|   |
|   +-- Using a third-party SDK (RevenueCat, etc.)?
|       Check if SDK already supports StoreKit 2 internally
|
+-- Testing framework
    +-- XCTest --> Swift Testing
        See xctest-to-swift-testing.md
        Min: Xcode 16 / Swift 6.0
```

## Quick Reference

| Migration | Reference File | Minimum OS | Risk Level |
|-----------|---------------|------------|------------|
| CoreData to SwiftData | `coredata-to-swiftdata.md` | iOS 17 / macOS 14 | High (data layer) |
| UIKit to SwiftUI | `uikit-to-swiftui.md` | iOS 13+ | Medium (incremental) |
| ObservableObject to @Observable | `observable-migration.md` | iOS 17 / macOS 14 | Low-Medium |
| Objective-C to Swift | `objc-to-swift.md` | Any | Medium (incremental) |
| StoreKit 1 to StoreKit 2 | `storekit-migration.md` | iOS 15 | Medium-High (payments) |
| XCTest to Swift Testing | `xctest-to-swift-testing.md` | Xcode 16 | Low |

## Process

### 1. Assess the Migration

Before starting, determine:
- What is the minimum deployment target? Many migrations require iOS 17+.
- How large is the surface area? (number of models, screens, test files)
- Can you adopt incrementally or is it all-or-nothing?
- Are there third-party dependencies that assume the old framework?

### 2. Load Relevant Reference File

Based on the migration type, read from this directory:
- `coredata-to-swiftdata.md` -- NSManagedObject to @Model, migration stages, coexistence
- `uikit-to-swiftui.md` -- UIHostingController, Representable, incremental adoption
- `observable-migration.md` -- @Observable macro, @Environment injection, AsyncSequence
- `objc-to-swift.md` -- Bridging headers, @objc, incremental file-by-file migration
- `storekit-migration.md` -- StoreKit 2 async/await purchases, Transaction.currentEntitlements, JWS
- `xctest-to-swift-testing.md` -- @Test, #expect, #require, parameterized tests

### 3. Review the User's Code

Scan for old-framework patterns and map each to its modern equivalent using the reference file. Check for:

- [ ] Deprecated API usage that has a direct modern replacement
- [ ] Custom workarounds that are no longer needed with the new framework
- [ ] Third-party dependencies that may conflict with the migration
- [ ] Coexistence requirements (both frameworks running simultaneously)

### 4. Recommend a Migration Strategy

For each migration, decide between:

- **Full migration**: Replace all old-framework code at once. Best for small codebases or when old framework is causing problems.
- **Incremental migration**: Migrate piece by piece while both frameworks coexist. Best for large codebases, production apps, or when timeline is flexible.
- **No migration**: The old framework is still appropriate. See "When NOT to Migrate" in each reference file.

## General Migration Principles

1. **Migrate tests first.** If you are migrating both app code and tests, migrate tests to Swift Testing first. This gives you a safety net for the app-code migration.

2. **One migration at a time.** Do not migrate CoreData to SwiftData and ObservableObject to @Observable in the same PR. Each migration should be independently reviewable and revertible.

3. **Keep the old code compiling.** During incremental migration, both old and new code must compile and run. Use coexistence patterns from each reference file.

4. **Feature-flag large migrations.** For production apps, consider gating new-framework code behind a feature flag so you can roll back without a code revert.

5. **Write migration tests.** For data-layer migrations (CoreData to SwiftData), write tests that verify data roundtrips correctly through both stacks.

## References

- [Migrating from CoreData to SwiftData](https://developer.apple.com/documentation/coredata/migrating-from-core-data-to-swiftdata)
- [Migrating to new navigation types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types)
- [Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Migrating a test from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [Migrating an app from StoreKit 1](https://developer.apple.com/documentation/storekit/in-app_purchase/implementing_a_store_in_your_app_using_the_storekit_api)

---

## 导航架构模式 (吸纳自 navigation-patterns)


# Navigation Patterns Skill Adapter

Shared skill source:

`../../../.agents/skills/navigation-patterns/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.
