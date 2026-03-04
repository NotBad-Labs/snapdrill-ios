# SnapDrill 全量代码审计报告（历史存档）

> **存档说明**：本报告为 2026-03-03 全量审计的历史快照（164 文件，~19,275 行）。
> 完整原始报告含 118 个问题（🔴14 / 🟡64 / 🟢40），已归档，不再维护。
> 本文件仅保留**尚未修复的 🔴 严重问题**，修复后在此处更新状态。

---

## 未解决的严重问题（⏳ 待修复）

| # | 文件 | 问题描述 | 类别 |
|---|---|---|---|
| 1 | `AppConfiguration.swift:35` | `registerRemoteProvider()` 修改 `@MainActor` 隔离状态但自身无 `@MainActor` 标注 | C4 |
| 2 | `PerformanceMonitoringExtensions.swift:60` | 阈值超出回调中 `Task { }` 无句柄，fire-and-forget I/O | E1 |
| 3 | `SourceRepository.swift` | 数据变更（insert/delete/update）后未发 `reviewDataDidChange` 通知 | D1 |
| 4 | `DataSeeder.swift:20` | 注释"生成约 100 条"但实际 mockData 只有 50 条（后续修改数量需同步更新注释） | A1 |
| 5 | `Routable.swift` / `Navigation.swift` | 两个文件都定义了 Router 协议，存在接口重复 | D1 |
| 6 | `GradeManagerView.swift` | `struct` 缺 `public`，与其他 ManagerView 访问控制不一致（需确认同包使用是否合法） | C1 |
| 7 | `SourceManagerView.swift` | 同上 | C1 |
| 8 | `SubjectManagerView.swift` | 同上 | C1 |
| 9 | `SettingsView.swift` | 生成测试数据的 `Task { }` 无句柄存储 | E1 |
| 10 | `DataAndSyncSettingsView.swift:45` | clearCache 的 `Task { }` 无句柄存储 | E1 |
| 11 | `NotificationSettingsView.swift:80` | DatePicker onChange 触发的 `Task { }` 无句柄存储 | E1 |

---

## 已修复的严重问题（✅）

| # | 文件 | 问题 | 修复时间 |
|---|---|---|---|
| — | `SettingsViewModel.swift` | `clearAllData()` 漏发 `reviewDataDidChange` 通知 | 2026-03-03 |
| — | `ExportOptionsSheet.swift` | 两个僵尸 `@State` 属性（showingWordShare, wordExportURL） | 2026-03-03 |
| — | `ExportPreviewView.swift` | 文件头误标"已废弃" | 2026-03-03 |
| — | `ReviewComponents.swift` | 空占位符文件（无实际代码） | 2026-03-03 |
| — | `DashboardComponents.swift` | 空占位符文件（无实际代码） | 2026-03-03 |

---

*原始完整报告生成于 2026-03-03，审计标准见 `audit-checklist.md`*
