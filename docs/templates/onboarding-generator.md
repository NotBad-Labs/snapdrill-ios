---
last_verified: 2026-05-25
layer: pattern
scope: template
name: onboarding-generator
description: Generates multi-step onboarding flows with persistence for iOS/macOS apps. Use when user wants to add onboarding, welcome screens, or first-launch experience.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Onboarding Generator

Generate a complete, customizable onboarding flow with persistence, animations, and accessibility support.

## When This Skill Activates

Use this skill when the user:
- Asks to "add onboarding" or "create onboarding"
- Mentions "welcome screens" or "first launch"
- Wants to "show intro on first launch"
- Asks about "onboarding flow" or "tutorial screens"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing onboarding implementations
- [ ] Identify if SwiftUI or UIKit project
- [ ] Find App entry point location
- [ ] Check deployment target (TabView paging requires iOS 14+)

### 2. Conflict Detection
Search for existing onboarding:
```
Glob: **/*Onboarding*.swift, **/*Welcome*.swift
Grep: "hasCompletedOnboarding" or "isFirstLaunch"
```

If found, ask user:
- Replace existing onboarding?
- Keep existing, add new flow?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Navigation style?**
   - Paged (horizontal swipe with dots)
   - Stepped (Next/Back buttons)

2. **Number of screens?**
   - 2-5 screens (recommend 3-4)

3. **Skip option?**
   - Allow skip button
   - Mandatory completion

4. **Presentation style?**
   - Full screen cover (modal)
   - Inline (embedded in view hierarchy)

5. **Include animations?**
   - Animated transitions
   - Static transitions

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `OnboardingView.swift` - Main container
2. `OnboardingPageView.swift` - Individual page template
3. `OnboardingPage.swift` - Page data model
4. `OnboardingStorage.swift` - Persistence
5. `OnboardingModifier.swift` - View modifier for easy integration

### Step 2: Customize Based on Configuration

**Paged Navigation:**
```swift
TabView(selection: $currentPage) {
    ForEach(pages) { page in
        OnboardingPageView(page: page)
            .tag(page.id)
    }
}
.tabViewStyle(.page(indexDisplayMode: .always))
```

**Stepped Navigation:**
```swift
VStack {
    OnboardingPageView(page: pages[currentPage])

    HStack {
        if currentPage > 0 {
            Button("Back") { currentPage -= 1 }
        }
        Spacer()
        Button(isLastPage ? "Get Started" : "Next") {
            if isLastPage {
                completeOnboarding()
            } else {
                currentPage += 1
            }
        }
    }
}
```

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Onboarding/`
- If `App/` exists → `App/Onboarding/`
- Otherwise → `Onboarding/`

## Output Format

After generation, provide:

### Files Created
```
Sources/Onboarding/
├── OnboardingView.swift           # Main container
├── OnboardingPageView.swift       # Page template
├── OnboardingPage.swift           # Data model
├── OnboardingStorage.swift        # @AppStorage persistence
└── OnboardingModifier.swift       # .onboarding() modifier
```

### Integration Steps

**Option 1: View Modifier (Recommended)**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onboarding()  // Automatically shows on first launch
        }
    }
}
```

**Option 2: Manual Control**
```swift
@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                }
        }
    }
}
```

### Customization

**Add Your Content:**
```swift
// In OnboardingStorage.swift or OnboardingView.swift
static let pages: [OnboardingPage] = [
    OnboardingPage(
        title: "Welcome",
        description: "Your app description here",
        imageName: "hand.wave",  // SF Symbol or asset name
        accentColor: .blue
    ),
    // Add more pages...
]
```

### Testing Instructions
1. Delete app from simulator (to reset UserDefaults)
2. Run app - onboarding should appear
3. Complete onboarding
4. Relaunch app - onboarding should NOT appear
5. Reset via Settings or delete app to test again

### Debug/Testing Reset
```swift
// Add to Settings or debug menu
Button("Reset Onboarding") {
    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
}
```

## References

- **onboarding-patterns.md** - Best practices and design patterns
- **templates/** - All template files

---

## TipKit 提示 (吸纳自 tipkit-generator)


# TipKit Generator

Generate a complete TipKit setup for contextual tips and feature discovery, including tip definitions, rules, display frequency, inline and popover presentation, and testing utilities.

## When This Skill Activates

Use this skill when the user:
- Asks to "add tips" or "add TipKit"
- Mentions "contextual tips" or "feature discovery"
- Wants "popover tips" or "inline tips"
- Asks about "coach marks" or "user education"
- Mentions "onboarding hints" or "tip prompts"
- Wants to "highlight new features" or "guide users"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (TipKit requires iOS 17+ / macOS 14+)
- [ ] Identify if SwiftUI or UIKit project
- [ ] Find App entry point location for Tips.configure()
- [ ] Check for existing TipKit implementations

### 2. Conflict Detection
Search for existing TipKit usage:
```
Glob: **/*Tip*.swift
Grep: "import TipKit" or "Tips.configure"
```

If found, ask user:
- Extend existing tip infrastructure?
- Replace existing tips?

## Configuration Questions

Ask user via AskUserQuestion:

1. **What features need tips?**
   - List the features or UI elements that should have tips
   - Example: "search bar, filter button, swipe-to-delete gesture"

2. **Tip presentation style?** (per tip or general preference)
   - Inline (TipView embedded in layout)
   - Popover (attached to a control)
   - Both

3. **Rule types needed?**
   - Parameter-based (show after user meets condition, e.g., has viewed a screen 3 times)
   - Event-based (show after user performs an action N times)
   - Both

4. **Display frequency?**
   - Immediate (tips show as soon as eligible)
   - Hourly
   - Daily
   - Weekly
   - Monthly

5. **Tip ordering?**
   - Independent (tips show whenever eligible)
   - Ordered (use TipGroup to show tips in sequence)

## Generation Process

### Step 1: Read Templates

Read the templates file for code patterns:
```
Read("skills/generators/tipkit-generator/templates.md")
```

### Step 2: Create Core Files

Generate these files based on configuration:
1. `Tips/` directory with one file per tip (e.g., `SearchTip.swift`, `FilterTip.swift`)
2. `Tips/TipEvents.swift` - Centralized event definitions
3. `Tips/TipsConfiguration.swift` - Tips.configure() setup and testing utilities

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists -> `Sources/Tips/`
- If `App/` exists -> `App/Tips/`
- Otherwise -> `Tips/`

### Step 4: Integrate Tips

- Add `Tips.configure()` call in App entry point
- Add `TipView` or `.popoverTip()` at the appropriate view locations
- Wire up event donation at action sites
- Wire up tip invalidation where appropriate

## Output Format

After generation, provide:

### Files Created
```
Sources/Tips/
├── SearchTip.swift            # Tip with rules and options
├── FilterTip.swift            # Another tip definition
├── TipEvents.swift            # Centralized event definitions
└── TipsConfiguration.swift    # Tips.configure() + testing helpers
```

### Integration Steps

**App Entry Point (Required):**
```swift
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
```

**Inline Tip:**
```swift
import TipKit

struct SearchView: View {
    let searchTip = SearchTip()

    var body: some View {
        VStack {
            TipView(searchTip)
            SearchBar()
        }
    }
}
```

**Popover Tip:**
```swift
import TipKit

struct ToolbarView: View {
    let filterTip = FilterTip()

    var body: some View {
        Button("Filter", systemImage: "line.3.horizontal.decrease.circle") {
            // action
        }
        .popoverTip(filterTip)
    }
}
```

**Event Donation (at action site):**
```swift
Button("Search") {
    performSearch()
    SearchTip.searchPerformed.donate()
}
```

**Tip Invalidation (when tip is no longer relevant):**
```swift
func onFeatureUsed() {
    // User discovered the feature, invalidate the tip
    searchTip.invalidate(reason: .actionPerformed)
}
```

### Testing Instructions

1. **Reset DataStore between runs:**
   ```swift
   // Add to a debug menu or call in preview
   try? Tips.resetDatastore()
   ```

2. **Show all tips for testing:**
   ```swift
   // Ignores rules and frequency -- shows everything
   Tips.showAllTipsForTesting()
   ```

3. **Show specific tips for testing:**
   ```swift
   Tips.showTipsForTesting([SearchTip.self])
   ```

4. **Test scenarios:**
   - Launch app fresh -- eligible tips should appear per display frequency
   - Perform actions that donate events -- event-based tips should appear when thresholds met
   - Tap tip close button -- tip should not reappear
   - Invalidate tip programmatically -- tip should dismiss and not reappear

## Common Gotchas

1. **Forgetting Tips.configure()** -- Tips will never appear if you do not call `Tips.configure()` before any tip is displayed. This must happen early, typically in the App `body` or `.task`.

2. **Rules not evaluating** -- Parameter-based rules require you to set the parameter value explicitly. If you define `@Parameter static var hasSeenFeature = false` but never set it to `true`, the rule never passes.

3. **DataStore conflicts in tests** -- If you run unit tests and the app simultaneously, they may share the same DataStore. Use `.datastoreLocation(.url(...))` to isolate them.

4. **Display frequency blocking tips** -- If you set `.displayFrequency(.daily)` and a tip was already shown today, no new tips will appear until tomorrow. Use `.immediate` during development.

5. **Tips not dismissing after invalidation** -- You must hold a reference to the tip instance and call `.invalidate(reason:)` on that instance. Creating a new instance and invalidating it does nothing to the displayed tip.

6. **TipGroup ordering ignored** -- Tips in a TipGroup only show in order if their rules are all satisfied. If Tip B's rules pass but Tip A's do not, neither will show (Tip A blocks Tip B).

## Patterns

### Good Patterns

- One tip struct per file for clarity
- Centralize event definitions in a single file
- Use `.actionPerformed` invalidation reason when the user completes the action the tip describes
- Use `TipGroup` when tips should appear in a logical sequence
- Provide a debug/testing menu that calls `Tips.resetDatastore()`
- Use meaningful tip IDs that describe the feature

### Bad Patterns

- Defining all tips in a single massive file
- Forgetting to call `Tips.configure()` in the App entry point
- Using `.immediate` display frequency in production (overwhelming users)
- Hardcoding tip text instead of using localized strings for shipped apps
- Creating a new tip instance to invalidate instead of using the displayed instance
- Placing `TipView` inside a `ScrollView` without considering layout impact

## References

- **templates.md** - Code templates for tips, rules, configuration, and TipGroup
