# PR #152 审查报告：Settings Telegram 风格重构

## 总览

+198/-178，15 文件。核心变更：`SettingsRow` 从单色改为双色渐变图标、Profile 区引入 iOS 26 `glassEffect()`、全局最低版本 iOS 18 → iOS 26。

---

## 🔴 严重

### 1. `SettingsView.swift:289` — fire-and-forget Task（clearAllData）

```swift
Task { await vm.clearAllData() }
```

该 Task 未保存句柄，是典型的 fire-and-forget。清空数据是**破坏性操作**，一旦用户快速离开页面，Task 无法被取消，且无法追踪执行状态。

**建议**：保存到 `@State private var clearTask: Task<Void, Never>?`，在 `onDisappear` 中取消。

### 2. `SettingsView.swift:267` — `avatarView` 中每次渲染重建 `ImageStorage()`

```swift
if userAvatar.contains("images/"), let image = ImageStorage().loadImage(path: userAvatar) {
```

每次 SwiftUI 重新计算 body 都会创建一个新的 `ImageStorage` 实例。如果 `ImageStorage` 有初始化开销（文件系统操作等），会造成性能问题。而 `EditProfileView` 中使用 `private let imageStorage = ImageStorage()` 作为实例属性是正确做法。

**建议**：与 `EditProfileView` 保持一致，将 `ImageStorage()` 提升为 View 的实例属性。

### 3. `DataAndSyncSettingsView.swift:200` — `checkAccountStatus()` 中 Task 未保存句柄

```swift
Task { @MainActor in
    let status = try await CKContainer.default().accountStatus()
    ...
}
```

该 Task 没有保存句柄，无法在 `onDisappear` 中取消。虽然影响比清空数据小，但仍违反项目铁律「Task 必须保存句柄」。

**建议**：增加 `@State private var accountCheckTask: Task<Void, Never>?`，并在 `onDisappear` 中取消。

### 4. `SettingsView.swift:253` — `glassEffect()` 无 `#available` 保护

```swift
.glassEffect()
```

`glassEffect()` 是 iOS 26+ API。虽然本 PR 已将最低版本提升至 iOS 26，但如果未来需要回退最低版本，此处会直接编译失败。且该 API 极新，建议加上 `if #available(iOS 26, *)` 保护以增强前向兼容性。

**上下文补充**：如果团队已确认永远不回退到 iOS 26 以下，此条可降级为 🟢。

---

## 🟡 警告

### 5. `SettingsView.swift:156` — 「反馈与支持」交互可优化

点击后弹出 `.alert` 只有「复制邮箱」和「以后再说」两个选项。理想的反馈入口应使用 `MFMailComposeViewController`（如果设备支持）或 `mailto:` link。

**建议**：在 `.alert` 按钮中增加「打开邮件」选项（通过 `mailto:` URL），仅当 `canSendMail()` 为 false 时降级为「复制邮箱」。

### 6. `SettingsView.swift:133-150` — 数据管理行使用 `Button` + `.sheet`

管理学科/来源/年级使用 `Button` + `sheet`（modal），而其他设置行使用 `NavigationLink`（push）。请确认这是设计意图。

**上下文不足，无法确认**：需确认 `SubjectManagerView` 等是否有自己的 `NavigationStack`。

### 7. SKILL.md 最低版本未同步

`.agent/skills/snapdrill-swift-standards/SKILL.md` 第 12 行仍显示 iOS 18.0，但本 PR 已将所有目标提升至 iOS 26.0。文档与代码不一致。

---

## 🟢 建议

### 8. `SettingsRow.swift` — 缺少 `#Preview`

核心 UI 组件无 Preview，建议添加以便独立调试渐变效果。

### 9. `SettingsRow.swift` — 建议补充英文 DocC 注释

仅有中文 DocC，按项目规范核心组件应提供中英双语文档。

### 10. `SettingsView.swift:261-283` — `avatarView` 渐变色数组与 `EditProfileView` 重复

两处定义了相同的渐变色数组，建议提取为共享组件避免漂移。

### 11. `LanguageSettingsView.swift:26-36` — 渐变图标尺寸与 SettingsRow 不一致

手动创建了 48×48 cornerRadius 12 的渐变图标，而 `SettingsRow` 是 30×30 cornerRadius 8。建议在 `SettingsRow` 上增加 `size` 参数统一管理。

---

## ✅ 无问题

| 文件 | 说明 |
|---|---|
| `Package.swift × 5` | iOS 18 → 26 变更正确一致 |
| `project.pbxproj` | 4 处 DEPLOYMENT_TARGET 正确 |
| `SettingsRow.swift` 渐变实现 | 实现干净 |
| `SettingsView.swift` Section 结构 | 分组清晰，separator 全局一致 |
| `SettingsView.swift` clearAlert | 使用 destructive Button 确认，符合规范 |
| `EditProfileView / NotificationSettingsView` | 仅格式化，无实质变更 |
| `ReviewAppearanceSettingsView` | 新增 `.inline` title mode，合理 |
| `LicenseView / PrivacySettingsView` | 格式化 + `.inline` title mode |

## 统计：🔴 4 · 🟡 3 · 🟢 4 · ✅ 10
