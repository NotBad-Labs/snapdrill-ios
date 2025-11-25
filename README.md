# NotBad 错题本 App

> 一个简洁、本地优先、注重隐私的 K12 错题管理工具

## 📱 核心功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 📸 **错题录入** | ✅ | 拍照 + 相册 + OCR 智能识别 |
| �� **题库管理** | ✅ | 浏览、搜索、筛选、编辑、删除 |
| 🔄 **卡片复习** | ✅ | 滑动卡片 + 掌握度标记 + 间隔重复 |
| 📊 **数据看板** | ✅ | 统计图表 + 学习进度可视化 |

## 🎯 设计原则

- **本地优先** - 数据存储在设备本地，无需登录
- **隐私保护** - 不上传用户数据
- **免费无广告** - 核心功能永久免费
- **简洁易用** - 专注学习体验

## 🛠 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| iOS | 26.0+ | 目标平台 |
| Swift | 6.0+ | 开发语言 |
| SwiftUI | - | 声明式 UI |
| SwiftData | - | 数据持久化 |
| Vision | - | OCR 文字识别 |

## 🏗 架构设计

采用 **Light Clean Architecture + DDD 值对象** 模式：

```
NotBad/
├── App/                    # 应用入口
├── Domain/                 # 领域层（核心业务）
│   ├── Entities/           # 实体 (ReviewItem)
│   ├── ValueObjects/       # 值对象 (9个)
│   └── Protocols/          # 协议定义
├── Data/                   # 数据层
│   └── Repository/         # 仓储实现
├── Infrastructure/         # 基础设施
│   ├── OCR/               # OCR 服务
│   └── Camera/            # 相机组件
└── Presentation/           # 表现层
    └── Features/           # 功能模块
        ├── Capture/        # 录入
        ├── Library/        # 题库
        ├── Review/         # 复习
        └── Dashboard/      # 看板
```

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/chramboliao/NotBad.git
cd NotBad

# 打开项目
open NotBad.xcodeproj

# 在 Xcode 中 ⌘+R 运行
```

### 系统要求

- macOS 15.0+ (Sequoia)
- Xcode 26.0+
- iOS 26.0+ 模拟器或真机

## 📖 文档

- [术语表 (Glossary)](GLOSSARY.md) - 项目统一语言定义
- [贡献指南](CONTRIBUTING.md) - 如何参与贡献

## 📊 项目状态

| 指标 | 数值 |
|------|------|
| MVP 完成度 | 100% ✅ |
| 编译状态 | ✅ Build Success |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License - 详见 [LICENSE](LICENSE)

---

**Made with ❤️ for better learning**
