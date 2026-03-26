# 工程哲学

## 元原则

1. **战术勤奋不掩盖战略懒惰** — 先问全局有没有未解决的战略问题
2. **局部最优 ≠ 全局最优** — 从全局视角审视
3. **设计阶段成本最低** — 先讨论透再动手
4. **方法论持续优化** — 实证驱动修订，不固守教条

## 决策前研究铁律

**不确定就先研究，禁止想当然写代码。**

- UI/UX：Apple 原生 App → 行业标杆 → HIG
- 技术：Apple 文档 → WWDC → 现有代码库
- 用户触发词：「铁律？」

## Apple 原生优先

**UI 改动必须先找 Apple 原生 App 或 HIG 中的对应模式。禁止自创交互。**

| 场景 | 用 | 不用 |
|---|---|---|
| Form 选值（短） | `Picker(.menu)` | `Menu` 包整行 |
| Form 选值（长） | `NavigationLink` → 勾选列表 | 自制 Sheet |
| 破坏性确认 | `confirmationDialog` | 自制弹窗 |
| 编辑取消确认 | `.interactiveDismissDisabled` + 系统确认 | 自制拦截 |
| 导航详情 | `NavigationLink` | `Button` + push |
| 删除 | `.onDelete` / 左滑 | 自制手势 |
| 功能提示 | TipKit（评估迁移中） | 自制气泡 |
| 搜索 | `.searchable` 修饰符 | 自制搜索栏 |

### iOS 26 新增（2026-03-26 补充）

Liquid Glass 是视觉材质层，不改 API 结构。编译 iOS 26 SDK 后以下组件自动获得新外观：
- Navigation bars、Toolbars、Tab bars → Liquid Glass 材质
- `Tab(role: .search)` → 自动分离到 Tab Bar trailing end
- `tabBarMinimizeBehavior(.onScrollDown)` → 滚动时最小化 Tab Bar
- Toolbar grouping → `ToolbarItem` 自动按材质分组

## 奥卡姆剃刀

新增抽象前必答：解决什么具体问题？有没有更简单的方式？删掉还能工作吗？改一个需求动 N 个文件？N > 3 是警告。

## 测试策略

| 层 | 策略 |
|---|---|
| 纯算法 | TDD |
| ViewModel | Test-after |
| Repository | in-memory ModelContainer |
| View / 胶水 | 不测 |
