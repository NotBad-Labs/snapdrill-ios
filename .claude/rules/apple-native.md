---
paths:
  - "**/*.swift"
---

<!-- last verified: 2026-04-03 -->
# Apple 原生优先

**UI 改动必须先找 Apple 原生 App 或 HIG 中的对应模式。禁止自创交互。**

| 场景 | 用 | 不用 |
|---|---|---|
| Form 选值（短） | `Picker(.menu)` | `Menu` 包整行 |
| Form 选值（长） | `NavigationLink` → 勾选列表 | 自制 Sheet |
| 破坏性确认 | `confirmationDialog` | 自制弹窗 |
| 编辑取消确认 | `.interactiveDismissDisabled` + 系统确认 | 自制拦截 |
| 导航详情 | `NavigationLink` | `Button` + push |
| 删除 | `.onDelete` / 左滑 | 自制手势 |
| 功能提示 | TipKit | 自制气泡 |
| 搜索 | `.searchable` 修饰符 | 自制搜索栏 |

## iOS 26

Liquid Glass 是视觉材质层，不改 API 结构。编译 iOS 26 SDK 后以下组件自动获得新外观：
- Navigation bars、Toolbars、Tab bars → Liquid Glass 材质
- `Tab(role: .search)` → 自动分离到 Tab Bar trailing end
- `tabBarMinimizeBehavior(.onScrollDown)` → 滚动时最小化 Tab Bar
