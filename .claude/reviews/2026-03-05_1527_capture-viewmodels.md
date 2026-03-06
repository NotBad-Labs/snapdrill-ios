# 审查请求：CaptureViewModel + CaptureResultViewModel

**日期**：2026-03-05 15:27（北京时间）
**审查文件**：

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Capture/CaptureViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Capture/CaptureResultViewModel.swift`
**审查人**：Google Antigravity（Gemini 3.1 Pro）
**状态**：待审查

---

## 项目背景

iOS 间隔重复学习 App（SnapDrill），Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+，单用户本地优先，无后端。所有 ViewModel 均为 `@Observable @MainActor final class`。

`CaptureResultViewModel.saveResult()` 已于 PR #64 修复以下问题：

- `isSaved` 不再提前置 true（现在保存成功后才置 true，失败时回滚为 false）
- 新写入图片若 `saveContext()` 失败，catch 中主动调用 `imageStorage.deleteImage()` 清理孤儿文件

本次审查聚焦于**上次修复之外的遗留问题**，以及 `CaptureViewModel` 本身。

## 关键文件

- `CaptureViewModel.swift` — 相机/图库入口，处理 OCR、照片加载、剪贴板
- `CaptureResultViewModel.swift` — 题目保存表单，含图片上传和 SwiftData 写入
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Services/ImageStorage.swift` — 图片文件读写

## 已知的 nonisolated(unsafe) 模式

两个文件均使用以下模式管理异步任务句柄：

```swift
// CaptureViewModel.swift
nonisolated(unsafe) private var ocrTask: Task<Void, Never>?
nonisolated(unsafe) private var photoLoadTask: Task<Void, Never>?

// CaptureResultViewModel.swift（请自行确认是否也有此标注）
private var recognitionTask: Task<Void, Never>?
```

## 审查问题

1. **CaptureViewModel 的 `nonisolated(unsafe)` Task 句柄**：`ocrTask` 和 `photoLoadTask` 均标注为 `nonisolated(unsafe)`。在 `@MainActor` 类中，`deinit` 是 nonisolated 的，若 ViewModel 在非主线程释放时主线程仍在读写这两个属性，是否构成数据竞争？与上一轮审查中 `LibraryEditViewModel.ocrTask` 的结论一致吗？

2. **`processScannedImage` 的 fire-and-forget Task**：`processScannedImage(_ image:router:)` 内部直接 `Task { await processImageOCR(...) }` 而不保存句柄。若用户快速切走页面，此 Task 是否会在 ViewModel 释放后继续执行？与 `photoLoadTask` 的处理方式一致吗？

3. **`CaptureResultViewModel.recognitionTask`**：该属性是否也标注了 `nonisolated(unsafe)`？与 `CaptureViewModel` 相比，生命周期管理是否更安全（例如是否在 `deinit` 或视图消失时取消）？

4. **`saveResult()` 的剩余问题**：PR #64 修复了 `isSaved` 提前设置和孤儿图片问题。请检查修复后的 `saveResult()` 是否还存在：
   - 标签创建（`fetchOrCreateModel`）失败后是否有 rollback？
   - `insertAndSave` 失败后 catch 的清理顺序是否正确（先清图片文件，再 rollback，顺序影响数据一致性）？
   - catch 块是否调用了 `rollbackContext()`？

---

## 审查结果

> 请将审查结果直接写在下方，保留标题层级，每个问题单独一节。
> 使用以下标记：🔴 严重 / 🟡 警告 / 🟢 建议 / ✅ 无问题
> 每个问题末尾注明具体文件和行号（如可定位）。

### 问题 1：CaptureViewModel nonisolated(unsafe) Task 句柄

🔴 **严重**

- **文件与行号**：`CaptureViewModel.swift` L:141-145, L:155-158
- **分析**：由于 `deinit` 在 actor 中执行必然是 `nonisolated` 的环境。如果 ViewModel 在切走界面或者其他情况下在后台线程里发生了释放回收（或者手动提早设为 null 且触发了回收），但主线程依然在执行内部方法对 `ocrTask` 或 `photoLoadTask` 进行赋值（比如 `loadPhoto` 里的 L:64，`processImageOCR` 里的 L:109），就会导致主线程和回收线程产生读取修改同一内存引用的**数据竞争（Data Race）**，引发闪退崩溃。这与上一轮审查得出的结论完全一致，滥用 `nonisolated(unsafe)` 进行强行压制警告留下了隐患。

### 问题 2：processScannedImage fire-and-forget Task

🟡 **警告**

- **文件与行号**：`CaptureViewModel.swift` L:99-104
- **分析**：这是一个典型的 Fire-and-Forget 任务（L:101-103）。因为任务并未关联到生命周期或者储存句柄，所以即使立即退出 Capture 界面（ViewModel 被销毁），`Task { await processImageOCR(image, router: router) }` 仍然会在后台**不受控制地独立存活和执行**。
- **与 `photoLoadTask` 对比**：`loadPhoto` 虽然将任务分配给 `photoLoadTask` 以期望被 `cancel` 打断，但也并未与视图的正式生命周期做深入绑定；而 `processScannedImage` 甚至完全放弃了引用保存。二者都有泄露长时任务的风险。

### 问题 3：CaptureResultViewModel.recognitionTask 生命周期

🔴 **严重**

- **文件与行号**：`CaptureResultViewModel.swift` L:74-75, L:161-164
- **分析**：`recognitionTask` **没有**使用 `nonisolated(unsafe)` 进行压制，但因为它根本没有编写 `deinit` 方法！这就意味着当退出这个预览编辑页面时，即使用户在裁切后狂刷重新识别，只要退出了页面，这个发起的 `Task { await reRecognizeText... }` **永远不会被 cancel 掉**，这是一个隐式的长时任务泄露。
- **建议**：需要一个规范的、与 UI 生命周期绑定（例如 SwiftUI `.task(id:)`）或者由 actor/class 管理任务取消与超时打断的方案。

### 问题 4：saveResult() PR #64 修复后的剩余问题

🔴 **严重**

- **文件与行号**：`CaptureResultViewModel.swift` L:180-258
- **分析**：`saveResult()` 的执行流程上仍然有显著的事务性破绽：
  1. **标签创建无回滚（L:199-203）**：如果新增标签 `fetchOrCreateModel` 途中发生异常中断，前面已经插入 SwiftData 容器的新标签没被 `try modelContext.save()` 落盘却还脏在那里。但随后的 `catch` 没有调用 `rollbackContext()`。
  2. **`insertAndSave` 抛错后的灾难现场（L:227, 245-257）**：它本身是调用的（`modelContext.insert()` + `modelContext.save()`）。如果落盘 `save()` 爆炸了抛错，程序直接进 catch 开始物理删盘里的新图片。但**因为丢失了 `rollbackContext()`**，这个刚 `insert` 失败的“问题题目”作为脏状态留存在主上下文中。当用户稍微改改别的或者后续有任意一处引发 Context 的存盘操作，这个没有图片的幽灵题目就会**被意外静默存储进数据库**。
  3. **清理顺序无所谓的错觉**：由于根本就没调用 `rollbackContext()`，所以也无所谓和 `imageStorage.deleteImage` 谁先谁后的顺序。一旦加上 `rollbackContext()`，必须放在最紧要处第一顺位清空脏数据，避免意外连带错误。### 综合评估

🔴 **严重：未通过审查**。

遗留隐患包括并发竞争与缺乏完整的异常回滚。最优先修复项：

1. **彻底修复 save()` 回滚**：在 `catch` 块首行务必加上 `repositories.review.rollbackContext()`；将`try repositories.review.insertAndSave()` 结构拆除，统一在 `saveResult` 末尾最后一步接管上下文的 `try saveContext()` 动作。
2. **生命周期彻底翻新**：废弃手动赋值 Task 变量然后再利用 `nonisolated` 绕过编译器的野路子（存在数据竞争）。采用结合 SwiftUI `task/onDisappear` 或者封装一个轻量级的受限 actor 工具箱进行彻底隔离取消。
