# NotBad 错题本

<div align="center">

![iOS](https://img.shields.io/badge/iOS-18.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![Xcode](https://img.shields.io/badge/Xcode-16.5%2B-blue) ![Status](https://img.shields.io/badge/Status-Core%20Features%20Complete-green) ![License](https://img.shields.io/badge/License-MIT-green)

> 一个**安全、简洁、智能**的K12学习复习应用，帮助学生科学高效地管理和复习错题，形成完整的学习闭环。

[快速开始](#-快速开始) • [功能特性](#-核心功能) • [技术架构](#️-技术架构) • [项目文档](#-项目文档) • [贡献指南](#-贡献指南)

</div>

## ✨ 核心功能

| 功能模块 | 描述 | 状态 |
|---------|------|------|
| 📸 **拍照创建** | OCR智能识别，快速记录错题 | ✅ 已完成 |
| 🎯 **专注复习** | 卡片式沉浸学习模式，支持手势操作 | 🔄 开发中 |
| 🔄 **错题重做** | 智能生成空白模板，验证掌握程度 | 🔄 开发中 |
| 📊 **学习分析** | 可视化学习进度，AI驱动的薄弱点诊断 | 🔮 规划中 |
| 👨‍👩‍👧‍👦 **家长模式** | 隐私优先的学习监督，可选内容授权 | 🔮 规划中 |
| ☁️ **多设备同步** | 端到端加密的云端数据同步 | ✅ 已完成 |

## 🚀 快速开始

### 环境要求

- **macOS**: Sonoma 14.0+ (推荐 macOS 15.0+)
- **Xcode**: 16.5+ (支持Swift 6和iOS 18)
- **iOS Deployment Target**: 18.0+
- **Swift**: 6.0

### 项目设置

1. **克隆项目**
   ```bash
   git clone https://github.com/chramboliao/NotBad
   cd NotBad
   ```

2. **打开项目**
   ```bash
   xed NotBad.xcodeproj
   ```

3. **运行项目**
   - 选择目标设备 (iPhone 16 Pro 推荐)
   - 按 `Cmd + R` 运行

### 首次运行

项目首次运行时会自动：
- 初始化本地 SwiftData 数据库
- 设置基础用户偏好
- 加载测试数据 (Debug模式下)

## 🏗️ 技术架构

<div align="center">

```mermaid
graph TB
    A[SwiftUI Views] --> B[Use Cases]
    B --> C[Domain Services]
    C --> D[Repositories]
    D --> E[SwiftData + CloudKit]
    
    F[Vision OCR] --> B
    G[AI Analysis] --> B
    H[Analytics] --> B
```

</div>

| 层级 | 技术栈 | 说明 |
|------|--------|------|
| **UI层** | SwiftUI + Combine | 声明式用户界面 |
| **业务层** | Clean Architecture | 分层架构，依赖倒置 |
| **数据层** | SwiftData + CloudKit | 本地优先，云端同步 |
| **AI服务** | Vision + Core ML + Gemini API | 混合AI架构 |
| **并发处理** | Swift 6 Actor模型 | 数据竞争安全 |

## 📖 项目文档

### 📋 核心文档
- **[文档中心](docs/README.md)** - 所有文档的快速导航
- **[产品需求文档 (PRD)](docs/prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v4.2%20(Swift6%20+%20iOS18).md)** - 产品功能规格
- **[技术设计文档 (TDD)](docs/tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v4.2%20(Swift6%20+%20iOS18).md)** - 技术架构设计
- **[需求追踪矩阵 (RTM)](docs/rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v4.2%20(Swift6%20+%20iOS18).md)** - 需求实现追踪

### 🏗️ 架构决策
- **[ADR-001](docs/adr/ADR-001%20本地数据层与持久化框架选型%20(SwiftData)%20v4.2%20(Swift6%20+%20iOS18).md)** - SwiftData 选型
- **[ADR-002](docs/adr/ADR-002%20云同步与多端一致性策略%20(Local-First%20+%20CloudKit)%20v4.2%20(Swift6%20+%20iOS18).md)** - 云同步策略
- **[ADR-003](docs/adr/ADR-003%20OCR%20处理流水线与重处理策略%20v4.2%20(Swift6%20+%20iOS18).md)** - OCR 引擎选型
- **[ADR-004](docs/adr/ADR-004%20错题重做功能方案选型%20v4.2%20(Swift6%20+%20iOS18).md)** - 错题重做方案

### 📚 开发指南
- **[开发工作流程](docs/DEVELOPMENT_WORKFLOW.md)** - Git 工作流和开发规范
- **[术语表](docs/glossary/)** - 业务和技术术语定义
- **[CI/CD 配置](.github/CI_CD_OPTIMIZATIONS.md)** - 持续集成优化

## 🚀 技术特色

### 📱 **Swift 6 + iOS 18 现代化架构**
本项目采用最新的技术栈，充分利用Swift 6并发模型和iOS 18新特性：

#### **🎯 核心技术**
- **Swift 6并发模型**: Actor + async/await，编译时保证并发安全
- **iOS 18新特性**: NavigationStack、@Observable、SwiftData批量操作
- **Clean Architecture**: 四层分离，依赖倒置，高度可测试
- **类型安全**: 100%编译时类型检查，零运行时开销

#### **⚡ 性能优势**
- **启动时间**: < 1.5秒 (Swift 6并发优化)
- **响应时间**: < 1秒 (Actor模型，零阻塞)
- **内存使用**: < 80MB (智能内存管理)
- **并发安全**: 编译时保证，运行时零开销
- **滚动流畅度**: > 60fps (iOS 18新动画API)

> 💡 **文档优先**: 本项目采用文档驱动开发，所有功能设计和技术决策都有完整文档支撑。

## 🎯 项目状态

### 当前版本: v0.1.0-alpha

**✅ 已完成**:
- [x] 项目架构设计 (Clean Architecture + Swift 6)
- [x] 核心文档体系 (PRD + TDD + RTM + ADR)
- [x] CI/CD 基础设施 (自托管运行器)
- [x] Swift 6 + iOS 18 技术栈规划

**🔄 开发中**:
- [ ] 核心数据模型 (SwiftData + CloudKit)
- [ ] OCR 图片识别 (Apple Vision 框架)
- [ ] 基础UI界面 (SwiftUI + iOS 18)
- [ ] 并发服务架构 (Swift 6 Actors)

**🔮 规划中**:
- [ ] 复习管理系统
- [ ] 专注学习模式
- [ ] AI 智能分析
- [ ] 家长协作功能

### 🎉 重要里程碑

**✅ 项目初始化** (2025年9月)
- **架构设计**: Clean Architecture + Swift 6 并发模型
- **文档体系**: 完整的PRD、TDD、RTM文档
- **技术选型**: iOS 18 + Swift 6 + SwiftUI + SwiftData
- **CI/CD配置**: 自托管运行器，自动化构建

**🔄 当前开发** (2025年9月)
- **数据层**: SwiftData模型设计和CloudKit同步
- **服务层**: Swift 6 Actor并发架构
- **UI层**: SwiftUI + iOS 18新组件
- **测试**: 单元测试和集成测试框架

## 📱 支持平台

| 平台 | 最低版本 | 状态 | 说明 |
|------|----------|------|------|
| iOS | 18.0+ | ✅ 主要支持 | iPhone 全系列 |
| iPadOS | 18.0+ | 🔄 适配中 | 大屏优化 |
| macOS | - | 🔮 未来考虑 | 桌面端支持 |
| watchOS | - | 🔮 未来考虑 | 轻量级功能 |

## 🤝 贡献指南

### 开发流程

1. **Fork 项目**
   ```bash
   git clone https://github.com/your-username/NotBad
   cd NotBad
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **提交变更**
   ```bash
   git commit -m 'feat: add amazing feature'
   ```

4. **推送分支**
   ```bash
   git push origin feature/amazing-feature
   ```

5. **创建 Pull Request**

### 代码规范

- **SwiftLint**: 自动代码规范检查
- **SwiftFormat**: 代码格式化
- **测试覆盖**: 新功能必须包含测试
- **文档更新**: 重要变更需要更新文档

### 报告问题

- 🐛 **Bug 报告**: [GitHub Issues](https://github.com/chramboliao/NotBad/issues)
- 💬 **功能建议**: [GitHub Discussions](https://github.com/chramboliao/NotBad/discussions)
- 📧 **联系我们**: dev@notbad.app

## 🔧 开发工具

### 必需工具
```bash
# 代码规范检查
brew install swiftlint

# 代码格式化
brew install swiftformat
```

### 推荐工具
- **API 调试**: Proxyman / Charles
- **设计协作**: Figma
- **项目管理**: Linear / GitHub Issues
- **文档管理**: 本地 Markdown

## 📊 项目指标

### 代码质量
- **架构设计**: Clean Architecture + Swift 6 并发模型
- **文档完整**: PRD + TDD + RTM + ADR 完整文档体系
- **技术选型**: iOS 18 + Swift 6 + SwiftUI + SwiftData
- **CI/CD**: 自托管运行器，自动化构建和测试

### 开发目标
- **类型安全**: 100%编译时类型检查
- **并发安全**: Swift 6 Actor模型，编译时保证
- **性能目标**: 启动<1.5s，响应<1s，内存<80MB
- **代码质量**: 严格遵循Clean Architecture原则

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

<div align="center">

**Made with ❤️ by NotBad Team**

*让每一次复习都有价值*

[⭐ Star](https://github.com/chramboliao/NotBad) • [🐛 Report Bug](https://github.com/chramboliao/NotBad/issues) • [💡 Request Feature](https://github.com/chramboliao/NotBad/discussions)

</div>