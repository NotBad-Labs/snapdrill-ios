# NotBad 发布检查清单

> 每次发布新版本前，请逐项确认

---

## 📋 代码质量

- [ ] 所有单元测试通过 (`xcodebuild test -testPlan UnitTestPlan`)
- [ ] 所有 UI 测试通过 (`xcodebuild test -testPlan UITestPlan`)
- [ ] 无编译警告
- [ ] SwiftLint 检查通过

## 📱 功能验证

- [ ] 拍照录入功能正常
- [ ] 相册选择功能正常
- [ ] OCR 识别功能正常
- [ ] 复习卡片滑动流畅
- [ ] 筛选/搜索功能正常
- [ ] PDF 导出功能正常
- [ ] Widget 数据显示正确
- [ ] Siri 快捷指令可用

## 🌍 本地化

- [ ] 中文简体 UI 完整
- [ ] 英文 UI 完整
- [ ] 日文 UI 完整
- [ ] 韩文 UI 完整
- [ ] 繁体中文 UI 完整

## 📊 性能

- [ ] 冷启动 < 2 秒
- [ ] 列表滚动 60fps
- [ ] 复习页滑动流畅
- [ ] 内存无明显泄漏

## 🔐 隐私与合规

- [ ] 隐私政策已更新
- [ ] 相机权限描述准确
- [ ] 相册权限描述准确
- [ ] 通知权限描述准确

## 📦 App Store 资源

- [ ] 应用图标 1024x1024
- [ ] iPhone 截图 (6.9")
- [ ] iPad 截图 (13")
- [ ] 版本说明已撰写
- [ ] 关键词已优化

## ⚙️ 版本配置

- [ ] Marketing Version 已更新
- [ ] Build Number 已递增
- [ ] 发布分支已创建

---

## 发布流程

```bash
# 1. 创建发布分支
git checkout -b release/v1.x.x

# 2. 更新版本号
# Xcode > NotBad > General > Version & Build

# 3. 运行完整测试
xcodebuild test -scheme NotBad -testPlan UnitTestPlan
xcodebuild test -scheme NotBad -testPlan UITestPlan

# 4. 构建归档
xcodebuild archive -scheme NotBad -archivePath build/NotBad.xcarchive

# 5. 导出 IPA
xcodebuild -exportArchive -archivePath build/NotBad.xcarchive -exportPath build -exportOptionsPlist ExportOptions.plist

# 6. 上传至 App Store Connect
xcrun altool --upload-app -f build/NotBad.ipa -t ios -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD

# 7. 合并到 main
git checkout main
git merge release/v1.x.x
git tag v1.x.x
git push origin main --tags
```

---

*最后更新: 2025年12月4日*
