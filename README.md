# NotBad 错题本

> 一个**安全、简洁、智能**的K12学习复习应用，帮助学生科学高效地管理和复习错题，形成完整的学习闭环。

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-blue) ![Status](https://img.shields.io/badge/Status-In%20Development-yellow)

## ✨ 核心功能

- 📸 **拍照创建**：OCR智能识别，快速记录错题
- 🎯 **专注复习**：卡片式沉浸学习模式，支持手势操作
- 🔄 **错题重做**：智能生成空白模板，验证掌握程度
- 📊 **学习分析**：可视化学习进度，AI驱动的薄弱点诊断 (Pro)
- 👨‍👩‍👧‍👦 **家长模式**：隐私优先的学习监督，可选内容授权 (Pro)
- ☁️ **多设备同步**：端到端加密的云端数据同步 (Pro)

## 🚀 快速开始

### 环境要求

- **macOS**: Sonoma 14.0+
- **Xcode**: 15.0+
- **iOS Deployment Target**: 17.0+
- **Swift**: 6.0

### 项目设置

1. **克隆项目**
   ```bash
   git clone https://github.com/chramboliao/NotBad
   cd NotBad
   ```

2. **解析依赖**
   ```bash
   # Swift包依赖会自动解析
   xed NotBad.xcodeproj
   ```

3. **运行项目**
   - 打开 `NotBad.xcodeproj`
   - 选择目标设备 (iPhone 15 Pro 推荐)
   - 按 `Cmd + R` 运行

### 首次运行配置

项目首次运行时会自动：
- 初始化本地 SwiftData 数据库
- 设置基础用户偏好
- 加载测试数据 (Debug模式下)

## 🏗️ 技术架构

| 层级 | 技术栈 | 说明 |
|------|--------|------|
| **UI层** | SwiftUI + Combine | 声明式用户界面 |
| **业务层** | Clean Architecture | 分层架构，依赖倒置 |
| **数据层** | SwiftData + CloudKit | 本地优先，云端同步 |
| **AI服务** | Vision + Core ML + Gemini API | 混合AI架构 |
| **并发处理** | Swift 6 Actor模型 | 数据竞争安全 |

## 📖 项目文档

### 核心文档
- � **[文档索引 (Docs Index)](docs/README.md)** - 所有主要文档的快速跳转
- 📋 **产品需求文档 (PRD)**: `docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v4.0.md`
- 🔧 **技术设计文档 (TDD)**: `docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v4.0.md`
- 📊 **需求追踪矩阵 (RTM)**: `docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v2.0.md`
- 🧾 **业务术语表**: `docs/glossary/NotBad App - 业务术语表 v1.1.md`
- 🧪 **技术术语表**: `docs/glossary/NotBad App - 技术术语表 v1.1.md`
- 🔗 **术语→代码索引**: `docs/glossary/NotBad App - 术语到代码索引 v1.0.md`

### 开发指南
- 🎨 **[UI设计规范](docs/ui-guidelines.md)** - 界面设计和交互规范
- 🔒 **[隐私安全指南](docs/privacy-security.md)** - 数据保护和合规要求
- 🧪 **[测试策略](docs/testing-strategy.md)** - 质量保证和测试方法

> 💡 **文档优先**: 本项目采用文档驱动开发，所有功能设计和技术决策都有完整文档支撑。

## 🎯 项目状态

### 当前版本: v1.0.0-alpha (开发中)

**MVP 目标 (2025 Q2)**:
- [x] 项目架构搭建
- [x] 核心文档完成
- [ ] 拍照OCR功能 (90%)
- [ ] 复习管理系统 (70%)
- [ ] 专注学习模式 (60%)
- [ ] 基础数据分析 (40%)

### 北极星指标
- 📈 **WAIC**: 周活跃复习项创建数月增长率 > 15%
- 🎓 **WLLCR**: 周学习闭环完成率 > 30%
- 💎 **转化率**: Pro版转化率 > 5%

## 👥 团队协作

### 开发流程
- **分支策略**: GitFlow (main/develop/feature/*)
- **代码规范**: SwiftLint + 团队编码规范
- **提交规范**: Conventional Commits
- **Review**: 所有代码必须经过Code Review

### 角色分工
- **产品经理**: PRD维护，需求管理
- **技术负责人**: TDD维护，架构决策
- **iOS开发**: 功能实现，代码质量
- **UI设计师**: 界面设计，用户体验
- **QA工程师**: 测试策略，质量保证

## 🔧 开发工具

### 必需工具
```bash
# SwiftLint (代码规范检查)
brew install swiftlint

# SwiftFormat (代码格式化)
brew install swiftformat
```

### 推荐工具
- **API调试**: Proxyman / Charles
- **设计协作**: Figma
- **项目管理**: Linear / GitHub Issues
- **文档管理**: Notion / 本地Markdown

## 📱 支持平台

| 平台 | 最低版本 | 状态 |
|------|----------|------|
| iOS | 17.0+ | ✅ 主要支持 |
| iPadOS | 17.0+ | ✅ 适配中 |
| macOS | - | ❌ 暂不支持 |
| watchOS | - | 🔮 未来考虑 |

## 🤝 贡献指南

### 提交代码
1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交变更 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

### 报告问题
使用 [GitHub Issues](https://github.com/chramboliao/NotBad/issues) 报告bug或提出功能建议。

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

## 📞 联系我们

- 📧 **邮箱**: dev@notbad.app
- 💬 **讨论**: [GitHub Discussions](https://github.com/chramboliao/NotBad/discussions)
- 🐛 **Bug报告**: [GitHub Issues](https://github.com/chramboliao/NotBad/issues)

---

<div align="center">

**Made with ❤️ by NotBad Team**

*让每一次复习都有价值*

</div>

# NotBad

一个用于管理与复习“错题”的 iOS 应用（SwiftUI + SwiftData + CloudKit）。

## 文档索引
详见 `docs/README.md` 获取 PRD、TDD、RTM、术语表、ADR 等导航。

## 文档更新流程
1. 修改或新增文档内容（确保语义清晰，必要时更新相关交叉链接）。
2. 如为架构/技术选型或重要原则变更：
   - 进入 `docs/ard/` 参考模板创建新的 `ADR-XXX <标题>.md`。
   - 更新 `docs/ard/README.md` 索引表格（追加行，勿重排历史）。
3. 执行自动编辑历史脚本（示例）：
   ```bash
   ./scripts/update_edit_history.py --author "Your Name" --summary "简述变更" docs/prd/NotBad\ 错题本\ App\ -\ 产品需求文档\ \(PRD\)\ v4.0.md
   ```
   可一次传入多个文件；脚本会在对应“编辑历史”表插入新行。
4. Git 提交：
   - Commit message 采用前缀：`docs: ...` 或 `adr: ...`。
5. 代码 / 文档评审：
   - 重要决策的 ADR 需在 PR 讨论区获得至少 1 位审核者同意。
6. 合并后禁止回写已采纳 ADR 的历史内容（除错别字）；若决策被替代，创建新 ADR 并在旧 ADR 标记“已取代 → ADR-YYY”。

## 许可
TBD
