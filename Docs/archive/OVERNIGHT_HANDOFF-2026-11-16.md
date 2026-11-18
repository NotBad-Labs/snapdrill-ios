# 过夜授权 · 交接说明（PO 睡醒后读）

> **已归档**（2026-11-18）：仅作历史记录。现行任务见 [`ENGINEERING.md`](../ENGINEERING.md) 与 [`GOVERNANCE.md`](../GOVERNANCE.md)。

## 你能期待什么 / 不能期待什么

| 能 | 不能 |
|---|---|
| 本回合内 **Slice 2 首块**：`CapturePipelineLive` + `LibrarySaveService` 真入库 | **无人值守 6–7 小时**连续 Agent（本地无 Cloud Timer；Cursor 会话休眠即停） |
| `xcodebuild test` 绿后 **commit + push** `greenfield/rebuild-from-zero` | Loop `/loop 6h` 除非你 **IDE 常开 + 本会话仍存活**（不建议整夜烧 token） |
| 下文 **明天 15 分钟 Dogfood 清单** | 相机 / VisionKit（留给下一 PR） |

若要真正过夜循环：醒来后在 Cursor **Automations** 设「每 90m 检查 `ENGINEERING` + 开下一边界 PR」，或 Cloud Agent + `subscribe_timer`（本环境未暴露）。

---

## 本回合已完成（见 `git log -1`）

- **CapturePipelineLive**：从 Stub 拆出；导入时 **GPS 剥离**；增强/框选/预览与 Stub 一致。
- **LibrarySaveService**：`commitSave` → SwiftData `MistakeItem` + `MistakeImageStore` 落盘。
- **CaptureFlowView**：科目 Picker；保存后进库（非 stub 计数）。
- **测试**：`LibrarySaveServiceTests` + 既有 Capture 合同测试。

---

## 明天 15 分钟 Dogfood（iPhone 17）

1. `git pull` → Xcode Run 真机。
2. 首页空本 → 点 **Capture** → 相册选 1 张 → 下一步到保存 → 选科目 → **Save**。
3. 回 **Notebook**：「All mistakes」计数应 **+N**（N = 框数，默认每页 1 框）。
4. 再录一张：确认科目记住上次选择（当前为会话内 State，未 UserDefaults — 已知局限）。

未做：**列表缩略图**、**详情看图**、**相机**。保存成功以计数与 SwiftData 为准。

---

## 建议下一 PR（你点头后 Agent 开工）

| PR | 内容 |
|---|---|
| `feat/capture-camera` | `UIImagePicker`/VisionKit；仍只经 `CapturePipelineServing` |
| `feat/home-thumbnails` | 读 `MistakeImageStore` 显示错题图 |
| `docs/arch-library-serving` | 若 UI 第二处写库再抽 `LibrarySaveServing` protocol |

---

## 授权记录

PO 2026-11-16 睡前授权：Plan/Loop/Agent 推进 **轨道 A · Slice 2**；允许 **push**（无 force）。本文件为当次授权范围快照。