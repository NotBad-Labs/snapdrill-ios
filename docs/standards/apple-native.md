---
last_verified: 2026-05-15
layer: pattern
---
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
| 加载状态 | Skeleton placeholder / `ProgressView` | 全屏 spinner |
| 分享 | `ShareLink` | 自制分享 UI |

## Anti-Patterns（禁止模式）

| 禁止 | 原因 | 替代 |
|---|---|---|
| Hamburger 侧边栏菜单 | 降低功能可发现性 | `TabView` 3-5 个 Tab |
| 全屏 loading spinner | 阻断交互，用户焦虑 | Skeleton placeholder / inline ProgressView |
| 堆叠 Modal（Modal 中弹 Modal） | 导航混乱，dismiss 路径不明 | 单层 Sheet 或 NavigationStack push |
| 隐藏 Tab Bar | 用户丢失导航上下文 | Tab Bar 在 push 导航中保持可见 |
| 手势是唯一入口 | VoiceOver 无法触发 | 手势 + 按钮双入口 |
| 启动 Logo 闪屏 | 拖慢首次体验 | 直接进入内容 |
| 覆盖系统 back swipe | 破坏 iOS 导航预期 | 保留左边缘返回手势 |
| 首次启动请求全部权限 | 用户不理解为什么需要 | Point-of-use 请求 + 预解释 |

## 布局基线

- **触控目标 >= 44pt**（Apple HIG 标准，不是像素是 point）
- **8pt 间距网格**：padding/spacing/margin 对齐 8 的倍数（8/16/24/32/40/48），4pt 用于微调
- **主操作放 thumb zone**（屏幕下半部分）
- **内容在 Safe Area 内**：`.ignoresSafeArea()` 仅用于背景填充，不用于文本或交互元素
- **支持所有屏幕尺寸**：iPhone SE (375pt) 到最新 Pro Max，用 Size Classes 适配
- **iPad 适配**：使用 `sidebarAdaptable` TabView 样式 + 动态 grid 列数（horizontalSizeClass 响应）

## Typography 与 Dynamic Type

- 使用语义字体样式：`.headline`、`.body`、`.caption`
- 自定义字体必须 `Font.custom(_:size:relativeTo:)` 配合语义样式缩放
- 最小字号 11pt
- Accessibility size 下允许布局重排（如 HStack → VStack）
- 不截断关键信息——用 `numberOfLines = 0` 或 `lineLimit(nil)`

## 语义色系统

| 用途 | 颜色 |
|---|---|
| 主背景 | `.systemBackground` |
| 卡片/分组背景 | `.secondarySystemBackground` |
| 嵌套内容背景 | `.tertiarySystemBackground` |
| 主文本 | `.label` / `.primary` |
| 次要文本 | `.secondaryLabel` / `.secondary` |
| 占位文本 | `.placeholderText` |
| 分隔线 | `.separator` |
| 交互元素 | 单一 accent color |

- 自定义颜色必须在 Asset Catalog 提供 Light/Dark 变体
- 不能仅靠颜色传达信息（必须配合图标或文字）
- 对比度：正文 >= 4.5:1，大字 >= 3:1

## Accessibility 基线

- 所有交互元素必须有 `.accessibilityLabel()`
- 复习卡片翻转、操作结果必须 VoiceOver 公告
- 支持 Bold Text 偏好
- 支持 Reduce Motion（关闭装饰性动画）
- 支持 Increase Contrast
- 复杂手势必须有非手势替代入口（按钮）
- 阅读顺序用 `.accessibilitySortPriority()` 控制

## 权限请求

- **Point-of-use**：在用户触发功能时请求，不在首次启动
- **Pre-permission explanation**：系统弹窗前先展示自定义预解释页面（说明为什么需要）
- **尊重拒绝**：权限被拒后降级体验，不反复弹窗

## iOS 26

Liquid Glass 是视觉材质层，不改 API 结构。编译 iOS 26 SDK 后以下组件自动获得新外观：
- Navigation bars、Toolbars、Tab bars → Liquid Glass 材质
- `Tab(role: .search)` → 自动分离到 Tab Bar trailing end
- `tabBarMinimizeBehavior(.onScrollDown)` → 滚动时最小化 Tab Bar
