---
name: navigation-patterns
description: SwiftUI navigation architecture patterns including NavigationStack, NavigationSplitView, TabView, programmatic navigation, and custom transitions. Use when reviewing or building navigation, fixing navigation bugs, or architecting app flow.
---

# Navigation Patterns

Comprehensive guide for SwiftUI navigation architecture on iOS, iPadOS, and macOS. Covers modern navigation APIs with self-contained patterns for common and advanced use cases.

## When This Skill Activates

- User is building or reviewing navigation architecture
- User has navigation-related bugs such as stack state loss, back button issues, or route mismatch
- User asks about NavigationStack, NavigationSplitView, TabView, NavigationPath, or navigationDestination
- User needs programmatic navigation such as push, pop, or pop-to-root
- User is implementing deep links that must resolve into navigation state
- User asks about navigation transitions or app flow architecture

## Decision Tree

Use this to pick the right navigation container:

```
What is the app structure?
|
+-- Flat sections, usually 3-5 top-level areas
|   `-- TabView
|
+-- Hierarchical drill-down, list to detail
|   `-- NavigationStack
|
+-- Sidebar plus content, usually iPad or macOS
|   +-- Two columns: NavigationSplitView
|   `-- Three columns: NavigationSplitView
|
`-- Combined structure
    +-- TabView with one NavigationStack per tab
    `-- NavigationSplitView with stack-style detail content
```

## Quick Reference

| Pattern | Container | Min OS | Notes |
|---|---|---:|---|
| Simple drill-down | `NavigationStack` | iOS 16 | Prefer value-based routes and a single destination registry |
| Value-based links | `NavigationLink(value:)` | iOS 16 | Pair with `.navigationDestination(for:)` |
| Programmatic push/pop | `NavigationPath` or typed route array | iOS 16 | Keep path in stable state owned by the feature/router |
| Pop to root | `path = NavigationPath()` or `routes.removeAll()` | iOS 16 | Avoid reconstructing the whole view tree only to clear navigation |
| State restoration | `NavigationPath.CodableRepresentation` or codable route enum | iOS 16 | Prefer typed routes when possible |
| Two-column layout | `NavigationSplitView` | iOS 16 | Sidebar + detail |
| Three-column layout | `NavigationSplitView` | iOS 16 | Sidebar + content + detail |
| Column visibility | `NavigationSplitViewVisibility` | iOS 16 | Use for adaptive iPad/macOS controls |
| Tab bar | `TabView` | iOS 13 | Keep each tab's navigation state independent |
| Customizable tabs | `Tab` + `TabView` | iOS 18 | Useful for user-configurable app sections |
| Sidebar tabs | `.tabViewStyle(.sidebarAdaptable)` | iOS 18 | iPad-friendly tab/sidebar adaptation |
| Zoom transition | `.navigationTransition(.zoom)` | iOS 18 | Pair with matched transition source |

## Review Process

### 1. Identify Navigation Needs

Read the user's code or requirements to determine:

- App structure: flat, hierarchical, sidebar-based, or combined
- Target platforms: iOS only, iPad adaptive, macOS, or multi-platform
- Whether route state must be programmatic, restorable, or deep-linkable
- Whether multiple independent navigation stacks are required
- Whether navigation state belongs in view state, a router, or a feature model

### 2. Select the Route Model

Prefer typed routes for application flows:

```swift
enum LibraryRoute: Hashable {
    case source(id: UUID)
    case reviewItem(id: UUID)
    case editItem(id: UUID)
}
```

Use `NavigationPath` when the route set is heterogeneous or hard to model, but do not hide unrelated feature state inside the path.

### 3. Register Destinations Once Per Stack

Keep destination registration near the owning stack:

```swift
NavigationStack(path: $routes) {
    LibraryView()
        .navigationDestination(for: LibraryRoute.self) { route in
            switch route {
            case .source(let id):
                SourceDetailView(sourceID: id)
            case .reviewItem(let id):
                ReviewItemDetailView(itemID: id)
            case .editItem(let id):
                EditReviewItemView(itemID: id)
            }
        }
}
```

Avoid scattering destination registration across unrelated child views. It makes deep links and route restoration harder to reason about.

### 4. Keep Tab Stacks Independent

For tab-based apps, each tab should own its own route state:

```swift
TabView(selection: $selectedTab) {
    NavigationStack(path: $libraryRoutes) {
        LibraryRootView()
    }
    .tabItem { Label("Library", systemImage: "books.vertical") }
    .tag(AppTab.library)

    NavigationStack(path: $reviewRoutes) {
        ReviewRootView()
    }
    .tabItem { Label("Review", systemImage: "rectangle.stack") }
    .tag(AppTab.review)
}
```

Do not share one path across all tabs unless cross-tab route replacement is the explicit product behavior.

### 5. Handle Deep Links Through the Router

Deep links should decode into typed routes or tab + route pairs:

```swift
struct AppRoute: Hashable {
    var tab: AppTab
    var route: LibraryRoute?
}
```

The deep-link handler should update navigation state in one place rather than directly constructing destination views.

## Common Mistakes

- [ ] Using deprecated `NavigationView` instead of `NavigationStack` or `NavigationSplitView`
- [ ] Using `NavigationLink(destination:)` for complex flows instead of value-based routes
- [ ] Registering `.navigationDestination` in multiple competing places for the same route type
- [ ] Placing independent `NavigationStack` values inside every row or card
- [ ] Sharing one navigation path across unrelated tabs
- [ ] Treating route state as private local state when deep links or restoration need access
- [ ] Encoding full model objects in route values instead of stable identifiers
- [ ] Mutating navigation state from background tasks without main-actor isolation

## Cross-Skill Hints

- For URL parsing and external entry points, use the `deep-linking` skill.
- For motion and transition review, use the `animation-patterns` skill.
- For SwiftUI performance concerns, use the `swiftui-pro` or `swiftui-performance-audit` skill when available.

## References

- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath)
- [TabView](https://developer.apple.com/documentation/swiftui/tabview)
- [Migrating to new navigation types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types)
