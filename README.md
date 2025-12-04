# NotBad 错题本 App

> 一个简洁、本地优先、注重隐私的 K12 错题管理工具

## 📱 核心功能

| 功能 | 说明 |
|------|------|
| 📸 **错题录入** | 拍照 + 相册 + OCR 智能识别 |
| 📚 **题库管理** | 浏览、搜索、筛选、编辑、删除 |
| 🔄 **卡片复习** | 滑动卡片 + 掌握度标记 + 间隔重复 |
| 📊 **数据看板** | 统计图表 + 学习进度可视化 |

## 🎯 设计原则

- **本地优先** - 数据存储在设备本地，无需登录
- **隐私保护** - 不上传用户数据
- **免费无广告** - 核心功能永久免费
- **简洁易用** - 专注学习体验

## 🛠 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| iOS | 26.0+ | 最低支持版本 |
| Swift | 6.2+ | 开发语言 |
| Xcode | 26.0+ | 开发工具 |
| SwiftUI | - | 声明式 UI |
| SwiftData | - | 数据持久化 |
| Vision | - | OCR 文字识别 |

### 平台策略

本项目仅支持 **iOS 26.0+**。

- **技术驱动**: 全面采用 SwiftData、Swift 6 严格并发检查、@Observable 宏。
- **产品体验**: 利用最新 Vision API 提供高精度 OCR，无需维护旧版本兼容代码。
- **开发效率**: 无需 `#available` 检查，代码库保持清洁。

## 📋 Git Flow 工作流程

本项目采用标准的 Git Flow 工作流程：

| 分支 | 用途 |
|------|------|
| **main** | 生产分支：只包含稳定的可发布版本 |
| **develop** | 开发分支：主要开发和集成分支 |
| **feature/** | 功能分支：新功能开发 |
| **release/** | 发布分支：发布前的测试和修复 |
| **hotfix/** | 热修复分支：生产环境紧急修复 |

```
main ←──────────────────────────────────────── 稳定发布
  ↑                                              ↑
  └── release/v1.0.0 ←── develop ←── feature/xxx
                              ↑
                          hotfix/xxx ──→ main
```

## 🏗 架构设计

采用 **Clean Architecture + MVVM + DDD 值对象** 模式：

```
NotBad/
├── Domain/                 # 领域层（核心业务）
│   ├── Entities/           # 实体 (ReviewItem + 4个扩展)
│   ├── ValueObjects/       # 值对象 (13个)
│   ├── Education/          # 多国教育体系 (6国支持)
│   └── Protocols/          # 协议定义
├── Data/                   # 数据层
│   └── Repository/         # 仓储实现
├── Infrastructure/         # 基础设施
│   ├── OCR/               # OCR 服务
│   ├── Scanner/           # 实时文本扫描
│   ├── Camera/            # 相机组件
│   └── Widget/            # Widget 数据同步
└── Presentation/           # 表现层
    ├── Common/             # 通用组件/样式
    └── Features/           # 功能模块 (6个, MVVM)
```

## 🚀 快速开始

```bash
# 克隆项目
git clone https://github.com/chramboliao/NotBad.git
cd NotBad

# 切换到开发分支
git checkout develop

# 打开项目
open NotBad.xcodeproj

# 在 Xcode 中 ⌘+R 运行
```

### 系统要求

- macOS 15.0+ (Sequoia)
- Xcode 26.0+
- iOS 26.0+ 模拟器或真机

## 📖 文档

| 文档 | 说明 |
|------|------|
| [项目结构](docs/PROJECT_STRUCTURE.md) | 完整目录结构说明 |
| [编码规范](docs/CODING_STANDARDS.md) | Swift 6 / SwiftUI / SwiftData 工程手册 |
| [术语表](docs/GLOSSARY.md) | 项目统一语言定义 (DDD) |
| [发布清单](RELEASE_CHECKLIST.md) | 发布前检查清单 (含 App Store 审核) |
| [贡献指南](CONTRIBUTING.md) | 如何参与贡献 |

## 📄 License

MIT License - 详见 [LICENSE](LICENSE)

---

**Made with ❤️ for better learning**
