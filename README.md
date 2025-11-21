# NotBad 错题本 App

> 一个简洁、本地优先、注重隐私的 K12 错题管理工具

## 📱 MVP 核心功能

1. **错题录入** - 拍照 + OCR + 手动编辑
2. **错题管理** - 查看、搜索、删除
3. **复习系统** - 卡片式复习 + 掌握度标记

## 🎯 设计原则

- **本地优先** - 数据存储在设备本地，无需登录
- **隐私保护** - 不上传用户数据，可选 iCloud 私有同步
- **免费无广告** - 核心功能永久免费
- **简洁易用** - 专注学习体验，拒绝功能臃肿

## 🛠 技术栈

- **平台**: iOS 26.0+
- **语言**: Swift 6.0+
- **框架**: SwiftUI + SwiftData
- **工具**: Xcode 26.0+

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/yourusername/NotBad.git

# 打开项目
cd NotBad
open NotBad.xcodeproj

# 在 Xcode 中 ⌘+R 运行
```

## 📂 项目结构

```
NotBad/
├── Domain/Models/          # 数据模型
├── Presentation/           # UI 层
│   ├── Capture/           # 录入功能
│   ├── Library/           # 题库管理
│   ├── Review/            # 复习系统
│   ├── Dashboard/         # 数据看板
│   └── Profile/           # 用户设置
└── NotBadApp.swift        # 应用入口
```

## 🎨 当前状态

**开发模式**: 敏捷迭代  
**代码行数**: ~900 行  
**文件数**: 8 个 Swift 文件  
**编译状态**: ✅ Build Success

## 📝 开发路线

- [x] 项目初始化
- [x] 基础 UI 框架
- [x] 数据模型设计
- [ ] 图片拍摄与选择
- [ ] OCR 文字识别
- [ ] 错题列表与搜索
- [ ] 复习卡片系统
- [ ] 数据持久化

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License - 详见 [LICENSE](LICENSE)

---

**Made with ❤️ for better learning**
