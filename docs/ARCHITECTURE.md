# SnapDrill 架构

- 状态：目标架构与当前实现差异
- 最后核实：2026-07-25

本文承接 [PRD.md](PRD.md)，只定义实现边界。产品需求高于架构；当前代码不能反向扩大产品范围。

## 1. 目标

SnapDrill 采用原生 SwiftUI、SwiftData 和 Swift concurrency。首版只有一个生产 runtime、一个
用户可见资料库和四个公开表面：

```text
SnapDrill.app
  -> Dashboard
  -> Capture
  -> Library
  -> Settings
```

正常启动必须一次性打开真实资料库。数据库不可用时进入明确恢复界面，不能先显示空库、创建
临时生产 store 或注入测试替身。

## 2. 模块与依赖

```text
SnapDrill.app             composition root
  -> SnapDrillFeatures    用户流程与界面状态
      -> SnapDrillUI      公共 SwiftUI 组件、路由协议
      -> SnapDrillData    SwiftData、Repository、文件、备份与恢复
          -> SnapDrillCore领域类型、服务协议、纯算法、日志
```

允许的补充边：

```text
SnapDrill.app -> SnapDrillUI / SnapDrillData / SnapDrillCore
SnapDrillUI  -> SnapDrillCore
```

约束：

- Core 不依赖 Data、UI、Features 或第三方 SDK。
- Data 不依赖 UI 或 Features。
- View 不直接持有 `ModelContext`，不拼接资料库路径。
- App target 只做组合、生命周期和顶层路由，不承载业务规则。
- 不为单一实现创建透传 protocol；跨模块稳定边界或系统 API 才使用协议。

`Scripts/ci_github.py dependencies` 是依赖方向的可执行门禁。

## 3. 数据流与并发

```text
View
  -> local view state / workflow owner
  -> RepositoryContainer
  -> DataExecutor actor
  -> SwiftData models
```

- 简单界面状态使用 `@State`；共享可观察状态使用 `@Observable`。
- 跨步骤写入、错误恢复和通知监听使用明确 workflow owner。
- Repository 保存失败必须 rollback，不能向上报告成功。
- 生命周期异步使用 `.task` 和 `async/await`，不以 Combine 包装简单异步。
- 图片 I/O、PDF 渲染、备份和恢复不得在主线程全量加载。

## 4. 生产组合

目标 composition root 只构造一次：

- 一个 local-library runtime；
- 一个 `ModelContainer` 和 actor-owned `DataExecutor`；
- 一个 `RepositoryContainer`；
- 一个资料库作用域的 `ImageStorage`；
- 一个 complete-operation coordinator；
- 一组系统服务。

资料库初始化必须 all-or-nothing。任何成员失败时不发布部分 runtime。

## 5. 用户表面

- **Dashboard**：任务入口和本地事实概览，不是行为统计面板。
- **Capture**：采集、裁剪、OCR、元数据和保存。
- **Library**：搜索、筛选、详情、编辑、删除和选择。
- **Settings**：语言、外观、数据所有权、备份和恢复。

Review、SmartPaper、Pro 和高级统计可以暂时作为不可达源码存在，但公开构建不得注册导航、
deep link、通知、后台任务或其他副作用。

## 6. 当前实现差异

以下是 2026-07-25 对 live code 的核实结果，不是产品授权：

| 差异 | 代码证据 | 收敛目标 |
|---|---|---|
| App 启动仍由 `ProfileManager` 和 `activeProfileId` 驱动 | `SnapDrill/App/AppRootView.swift`、`Packages/SnapDrillData/.../ProfileManager.swift` | 改为一个 local-library runtime |
| Settings 与备份仍按 Profile 组织 | `SnapDrillFeatureSettings`、`BackupDTO.swift` | 单资料库、无 Profile wire |
| App 仍链接 Review target | `SnapDrill/App/SnapDrillApp.swift`、`Packages/SnapDrillFeatures/Package.swift` | 首版公开 shell 不注册 Review |
| Library 仍可进入 SmartPaper | `SnapDrillFeatureLibrary/LibraryView.swift` | 首版公开构建不可达且无副作用 |
| Dashboard 仍含 Pro analytics 实现 | `DashboardAnalyticsViewModel.swift` | 从公开组合中移除 |
| App 仍嵌入 Share Extension 并共享 App Group | `SnapDrillShare/`、App 与 Extension entitlements | 首版不发布该入口；移除或经新产品决策批准 |
| 当前备份仍是开发期 Profile 格式 | `BackupDTO.swift`、`BackupService.swift` | 在外部分发前实现稳定单资料库格式 |

这些差异应按核心链路和数据风险排序逐步删除，不为保留历史代码修改 PRD。

## 7. 测试边界

| 层级 | 应证明什么 |
|---|---|
| Core unit | 纯规则、路径、限制和错误分类 |
| Data contract | Repository、图片、删除、备份、恢复和原子性 |
| Composition integration | 只有一个 runtime；正常与恢复 shell 不混淆 |
| Feature integration | 输入、编辑、保存、搜索、导出和失败反馈 |
| UI / AX | 中英文、Dynamic Type、VoiceOver、viewport 和系统面板 |
| Device | 相机、文档扫描、真实打印、签名安装和启动 |

测试 oracle 来自 PRD 和 [DATA.md](DATA.md)，不能从旧实现倒推。
