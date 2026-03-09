# SnapDrill 全量代码审计报告（历史存档）

> **存档说明**：本报告为 2026-03-03 全量审计的历史快照（164 文件，~19,275 行）。
> 完整原始报告含 118 个问题（🔴14 / 🟡64 / 🟢40），已归档，不再维护。
> 本文件仅保留**尚未修复的 🔴 严重问题**，修复后在此处更新状态。
>
> 最后核实：2026-03-09

---

## 未解决的严重问题（⏳ 待修复）

| # | 文件 | 问题描述 | 类别 |
|---|---|---|---|
| 2 | `PerformanceMonitoringExtensions.swift:60` | 阈值超出回调中 `Task { }` 无句柄，fire-and-forget I/O | E1 |
| 3 | `SourceRepository.swift` | 数据变更（insert/delete/update）后未发 `reviewDataDidChange` 通知 | D1 |

---

## 已修复的严重问题（✅）

| # | 文件 | 问题 | 修复时间 |
|---|---|---|---|
| 1 | `AppConfiguration.swift:35` | `registerRemoteProvider()` 无 `@MainActor` 标注 | 2026-03-09 核实：方法在 `@MainActor struct FeatureFlags` 内，已继承隔离 |
| 4 | `DataSeeder.swift:20` | 注释"生成约 100 条"与实际不符 | 2026-03-09 核实：DocC 已更新为"不足 count 时循环复用 mockData 填满" |
| 5 | `Routable.swift` / `Navigation.swift` | Router 协议重复 | 2026-03-09 核实：`Routable.swift` 已删除，仅保留 `FeatureRouter` |
| 6 | `GradeManagerView.swift` | 缺 `public` | 2026-03-09 核实：已改为 `public struct` |
| 7 | `SourceManagerView.swift` | 同上 | 2026-03-09 核实：已改为 `public struct` |
| 8 | `SubjectManagerView.swift` | 同上 | 2026-03-09 核实：已改为 `public struct` |
| 9 | `SettingsView.swift` | 生成测试数据 Task 无句柄 | 2026-03-09 核实：已添加 `seedTask` 句柄 + `onDisappear` 取消 |
| 10 | `DataAndSyncSettingsView.swift:45` | clearCache Task 无句柄 | 2026-03-09 核实：已添加 `cacheClearTask` 句柄 + `onDisappear` 取消 |
| 11 | `NotificationSettingsView.swift:80` | DatePicker onChange Task 无句柄 | 2026-03-09 核实：已添加句柄 + `onDisappear` 取消 |
| — | `SettingsViewModel.swift` | `clearAllData()` 漏发通知 | 2026-03-03 |
| — | `ExportOptionsSheet.swift` | 两个僵尸 `@State` 属性 | 2026-03-03 |
| — | `ExportPreviewView.swift` | 文件头误标"已废弃" | 2026-03-03 |
| — | `ReviewComponents.swift` | 空占位符文件 | 2026-03-03 |
| — | `DashboardComponents.swift` | 空占位符文件 | 2026-03-03 |

---

*原始完整报告生成于 2026-03-03，审计标准见 `audit-checklist.md`*
