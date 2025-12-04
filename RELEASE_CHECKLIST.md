# NotBad 开发路线图

> 最后更新: 2025年12月3日  
> 版本: v1.0

---

## 📊 当前进度总览

| 阶段 | 名称 | 状态 | 完成度 |
|------|------|------|--------|
| 阶段 1 | 发布准备 | ✅ 已完成 | 100% |
| 阶段 2 | 用户体验优化 | ✅ 已完成 | 100% |
| 阶段 3 | 功能增强 | ✅ 已完成 | 100% |
| 阶段 4 | 技术完善 | 🔄 进行中 | 80% |

---

## ✅ 阶段 1：发布准备（已完成）

### 1.1 文档与托管

| 任务 | 状态 | 文件/说明 |
|------|------|----------|
| GitHub Pages 配置 | ✅ | `docs/_config.yml` |
| App Store 文案 | ✅ | `docs/APP_STORE_LISTING.md` (中英日韩) |
| 隐私政策 | ✅ | `docs/privacy-policy.html` + `privacy-policy-en.html` |
| 支持页面 | ✅ | `docs/support.html` + `support-en.html` |

### 1.2 用户引导

| 任务 | 状态 | 说明 |
|------|------|------|
| 空状态引导设计 | ✅ | `EmptyStateView.noItems()` 增强版 |
| Tab 切换通知 | ✅ | `Notification+Names.swift` 添加 Navigation Events |
| 首次使用引导 | ✅ | 3 个功能提示 + 渐变操作按钮 |
| 本地化字符串 | ✅ | 6 个新字符串 (中英日韩繁) |

---

## ✅ 阶段 2：用户体验优化（已完成）

### 2.1 已有功能确认

| 功能 | 状态 | 位置 |
|------|------|------|
| 本地复习提醒 | ✅ 已有 | `NotificationSettingsView.swift` |
| Haptic 触感反馈 | ✅ 已有 | 7+ 处使用 `sensoryFeedback` |
| 动画效果 | ✅ 已有 | 48+ 处 spring/transition 动画 |

### 2.2 新增功能

| 功能 | 状态 | 文件 |
|------|------|------|
| TipKit 集成 | ✅ | `AppTips.swift` |
| 拍照提示 | ✅ | `CaptureView.swift` |
| 复习手势提示 | ✅ | `ReviewView.swift` |
| 提示本地化 | ✅ | 16 个新字符串 (中英日韩繁) |

---

## ✅ 阶段 3：功能增强（已完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | Widget 小组件 | ✅ 已有 | `NotBadWidget.swift` (469行，小/中/大/锁屏) |
| 2 | PDF 导出 | ✅ | `PDFExportService.swift` |
| 3 | 搜索历史 | ✅ | `SearchHistoryManager.swift` + `SearchHistoryView.swift` |
| 4 | 批量操作 | ✅ | `LibraryView.swift` 编辑模式 + 批量标记/删除 |
| 5 | Siri Shortcuts | ✅ | `AppShortcuts.swift` (3个快捷指令) |

---

## 🔄 阶段 4：技术完善（已完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 补充单元测试 | ✅ | 新增 SearchHistoryManagerTests + PDFExportServiceTests |
| 2 | 统一错误处理 | ✅ | `AppError.swift` + `ErrorAlertView.swift` |
| 3 | OSLog 日志 | ✅ | `Logger+Extensions.swift` |
| 4 | iPad 适配 | ✅ | `AdaptiveNavigationView.swift` (NavigationSplitView) |
| 5 | iCloud 同步 | ✅ 已有 | SwiftData 自动同步已启用 |

---

## 📱 App Store 发布准备

### 资源清单

| 资源 | 状态 | 备注 |
|------|------|------|
| 应用图标 (1024x1024) | ⚠️ 待设计 | 交给设计师 |
| App Store 截图 | ⚠️ 待准备 | 5 张 iPhone + 5 张 iPad |
| 隐私政策 URL | ⏳ 待托管 | GitHub Pages 启用后可用 |
| 支持邮箱 | ⏳ 待确认 | 建议使用专用邮箱 |

### 技术配置

| 配置项 | 当前值 | 状态 |
|--------|--------|------|
| Bundle ID | `com.LIAOYIMING.NotBad` | ✅ |
| Marketing Version | `1.0` | ✅ |
| Deployment Target | `iOS 26.0+` | ✅ |
| Swift Version | `6.2+` | ✅ |

---

## 🚀 发布建议

### 版本规划

| 版本 | 内容 | 时间点 |
|------|------|--------|
| v1.0 | 阶段 1-2 完成后提交审核 | 准备好图标/截图后 |
| v1.1 | 阶段 3 功能增强 | 上架后 1-2 周 |
| v1.2 | 阶段 4 技术完善 | 收集用户反馈后 |
| v2.0 | iCloud 同步 + 更多功能 | 长期规划 |

### 待用户操作

1. **启用 GitHub Pages**
   - 仓库 → Settings → Pages → Source: `main` / `/docs`
   
2. **设计应用图标**
   - 1024x1024 PNG，无透明度
   
3. **准备 App Store 截图**
   - iPhone 6.9": 1320 x 2868
   - iPad Pro 13": 2064 x 2752

---

*更新日期：2025年12月3日*  
*适用版本：NotBad v1.0*
