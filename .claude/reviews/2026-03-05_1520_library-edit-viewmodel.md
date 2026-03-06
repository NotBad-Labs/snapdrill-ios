# 审查请求：LibraryEditViewModel 数据一致性

**日期**：2026-03-05 15:20（北京时间）
**审查文件**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Library/LibraryEditViewModel.swift`
**审查人**：Google Antigravity（Gemini 3.1 Pro）
**状态**：待审查

---

## 项目背景

iOS 间隔重复学习 App（SnapDrill），Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+，单用户本地优先，无后端。所有 ViewModel 均为 `@Observable @MainActor final class`。

图片通过 `ImageStorage`（封装文件系统操作）独立于 SwiftData 存储，路径记录在 `ReviewItemModel.imagePath` 和 `answerImagePath` 字段中。`rollbackContext()` 只能回滚 SwiftData 的内存状态，**不能撤销已写入文件系统的图片文件**。

## 关键文件

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Library/LibraryEditViewModel.swift` — 题目编辑 ViewModel，核心方法是 `save() async`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Services/ImageStorage.swift` — 图片文件读写，`saveImage()` 写磁盘，`deleteImage()` 删文件

## save() 执行顺序

1. 处理标签：`tag.fetchOrCreateModel()` 更新 `item.tags`
2. 若有新正面图片：`imageStorage.saveImage(newImage)` → 写文件 → `item.imagePath = newPath`
3. 若有新答案图片：`imageStorage.saveImage(answerImg)` → 写文件 → `item.answerImagePath = newPath`
4. 若用户主动清除答案图片：`item.answerImagePath = nil`
5. 最终：`repositories.review.saveContext()`

## 审查问题

1. **孤儿图片风险**：步骤 2/3 写入了新图片文件并更新了 `item.imagePath`，但步骤 5 的 `saveContext()` 失败时，catch 是否有 `rollbackContext()`？`item.imagePath` 已被改写，旧图片路径已丢失——旧文件是否成为无法引用的孤儿文件？新写入的文件是否也应该删除？

2. **替换图片时的旧文件清理**：用户替换正面图片（原来有 `imagePath`，现在上传新图），`save()` 写入新文件后，旧文件是否被主动删除？还是静默泄漏为孤儿文件？

3. **`nonisolated(unsafe) var ocrTask`**：OCR 任务句柄标注为 `nonisolated(unsafe)`，在 `@MainActor` 类中对它的读写（`ocrTask?.cancel()`、`ocrTask = Task {...}`）是否安全？`Task { ... }` 内部 `await ocrService.recognizeText` 挂起后恢复时的 actor 上下文是否正确？

4. **图片写入失败后继续 saveContext**：代码对图片保存失败似乎有独立 catch（只 log 不 return），写图片失败后仍继续调用 `saveContext()`。这种设计是有意为之还是潜在 bug？用户会看到有路径但实际图片不存在的记录吗？

---

## 审查结果

> 请将审查结果直接写在下方，保留标题层级，每个问题单独一节。
> 使用以下标记：🔴 严重 / 🟡 警告 / 🟢 建议 / ✅ 无问题
> 每个问题末尾注明具体文件和行号（如可定位）。

### 问题 1：孤儿图片风险

🔴 **严重**

- **文件与行号**：`LibraryEditViewModel.swift` L:179-185
- **分析**：如果步骤 2 或 3 (`imageStorage.saveImage`) 执行成功，图片已经物理写入磁盘，且改变了内存中的 `item.imagePath`。如果步骤 5 中的 `saveContext()` 抛错，内存中的脏数据未提交，但代码**未调用 `rollbackContext()`**，也**没有主动抓取错误去删除刚写入的图片文件**。这导致：
  1. 产生的图片文件变成永远游离在于数据库记录以外的**孤儿文件**，引发存储泄露。
  2. 失败未执行回滚导致内存上下文污染，脏数据可能会在将来的其他写入中被意外带入数据库。

### 问题 2：替换图片时的旧文件清理

🔴 **严重**

- **文件与行号**：`LibraryEditViewModel.swift` L:158-166, L:168-177
- **分析**：当用户替换一张已有的图片或“主动清除”图片时，代码直接进行了 `item.imagePath = newPath` 的重新赋值或者 `item.answerImagePath = nil`（L:176）。代码完全没有任何主动去调用 `imageStorage.deleteImage(path: oldPath)` 的动作。
这造成不管替换多少次图片，或者删减过多少次图片，原有的废弃图片文件会由于没有任何记录再引用它，而在磁盘中发生**静默泄漏**（变为孤儿文件）。

### 问题 3：nonisolated(unsafe) ocrTask 并发安全

🔴 **严重 / 🟡 警告**

- **文件与行号**：`LibraryEditViewModel.swift` L:51-52, L:103-118, L:120-122
- **分析**：为了在 class (引用类型) 销毁时清理任务，开发者在 `deinit` 内部读取了 `ocrTask` 变量。然而在 Swift 6 中 `@MainActor class` 的 `deinit` 执行上下文是 `nonisolated` 的，与处于 `@MainActor` 隔离的 `handleNewImage` 一起访问同一内存变量属于并发竞争，因此加入了 `nonisolated(unsafe)` 进行强制忽略警告。
这会引起**实质性的数据竞争（Data Race）**：如果后台释放 ViewModel 的同时，主界面恰好正在主线程给 `ocrTask` 赋值或者写入，读写同一引用变量有可能导致内存崩溃。
- **建议**：可使用局部的以某种形式隔离的 Actor 或者引用状态包装器存放此任务，亦或者是依赖 SwiftUI 的 `.task` modifier（与视图生命周期绑定）来管理异步 OCR 请求的打断，从而避免使用 `nonisolated(unsafe)` 掩耳盗铃。

### 问题 4：图片写入失败后继续 saveContext

🟡 **警告**

- **文件与行号**：`LibraryEditViewModel.swift` L:162-164, L:172-174
- **分析**：代码对于图片上传抛错只做出了 `try...catch` 然后仅仅执行 `SnapDrillLogger.generic.error` 记录日志，并没有 `return` 中断。错误被生吞（swallowed），程序流程继续流转到结尾的 `repositories.review.saveContext()`。
这一设计违背了“事务原子性”。一旦发生磁盘塞满等导致图片写不进去的问题，题目文本被保存了，但是关联的 `imagePath` 却没有更新（如果原本就是覆盖或新建图片就会出现丢图）。系统向 UI 虚假上报 `isSavedNormally = true`，这极易引起“图片不翼而飞”的客诉。应该向外抛出抛错中断或者对状态进行回滚处理。

### 综合评估

🔴 **严重：未通过审查**。
该文件在异常恢复机制及生命周期管理上存在严重疏忽。最优先需要修复：

1. **持久化与文件 I/O 一致性**：修改图片和删除废弃文件必须与 SwiftData 的存取进行两阶段保障。必须清理替换后泄露的旧文件；
2. **错误响应机制**：图片存储失败不应当能够继续达成后续的 Context 持久化和刷新通知环节，应中断并弹窗。 catch 异常必须清理现场并搭配 `rollbackContext()`。
3. **并发隐患**：彻底移除 `nonisolated(unsafe) var ocrTask` 的实现，改为利用 SwiftUI 的原生 `@State` + `.task` 控制任务取消更正统或者采取严谨并发锁模式。
