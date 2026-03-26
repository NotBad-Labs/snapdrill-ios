# Xcode Intelligence 审计复核提示词

> 将以下提示词粘贴到 Xcode Intelligence 对话框中，让它对 PR #429 的修改进行交叉验证。

---

## 提示词

请检查以下 6 个文件的最近修改（PR #429 audit fixes），逐项验证：

### 1. HeaderView.swift（S0 修复）

检查 `HeaderView` 中的头像加载逻辑：
- 确认不再有同步的 `ImageStorage().loadImage()` 调用
- 确认使用了 `@State private var avatarImage: UIImage?` + `.task(id: userAvatar)` + `loadImageAsync()` 模式
- 确认 `.task(id:)` 在 `userAvatar` 变化时会重新触发（如用户更换头像）
- 确认 `userAvatar` 不含 `"images/"` 时正确清空 `avatarImage = nil`
- 检查是否有内存泄漏风险（UIImage 持有 + View 重绘周期）

### 2. EditProfileView.swift + DataAndSyncSettingsView.swift（S2 修复）

检查 catch 块中的 Logger 调用：
- 确认错误场景使用 `SnapDrillLogger.generic.error()` 而非 `.info()`
- 确认 error 参数使用 `.localizedDescription` 而非直接插值 `\(error)`（避免泄露内部错误信息到 OSLog）

### 3. DashboardViewModel.swift / AppRouter.swift / DependencyContainer.swift（S2 修复）

检查所有 `try?` 用法：
- 确认每个 `try?` 前都有 `// best-effort: [原因]` 注释
- 评估每个 `try?` 是否真的属于 best-effort（即失败不影响正确性）：
  - `Task.sleep` 防抖延迟 → 取消只是跳过延迟，功能不受影响 ✓
  - Share Extension 文件读取 → 文件可能已被系统清理，属于正常情况 ✓
  - 临时文件删除 → 清理失败不影响功能 ✓
  - RemoteConfig fetchAndActivate → 本地默认值兜底 ✓

### 4. 全局检查

- 在整个项目中搜索 `ImageStorage().loadImage(` 在 View body 中的同步调用，确认没有遗漏的同步图片加载
- 搜索 `\.info\(.*[Ff]ail` 模式，确认没有其他使用 `.info()` 记录错误的地方
- 搜索无注释的 `try?`（排除 `// best-effort` 后面的），确认规范一致性
