# NotBad 错题本

> 一个**安全、简洁、智能**的K12学习复习应用，帮助学生科学高效地管理和复习错题，形成完整的学习闭环。

![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.2-orange) ![Xcode](https://img.shields.io/badge/Xcode-26%2B-blue) ![Status](https://img.shields.io/badge/Status-Refactoring-yellow)
![Coverage](https://img.shields.io/badge/coverage-65.38%25-brightgreen) ![Logic](https://img.shields.io/badge/logic-92.37%25-brightgreen) ![Threshold](https://img.shields.io/badge/threshold-65%25-blue)

## ✨ 核心功能

- 📸 **拍照创建**：OCR智能识别，快速记录错题
- 🎯 **专注复习**：卡片式沉浸学习模式，支持手势操作
- 🔄 **错题重做**：智能生成空白模板，验证掌握程度
- 📊 **学习分析**：可视化学习进度，AI驱动的薄弱点诊断 (Pro)
- 👨‍👩‍👧‍👦 **家长模式**：隐私优先的学习监督，可选内容授权 (Pro)
- ☁️ **多设备同步**：端到端加密的云端数据同步 (Pro)

## 🚀 快速开始

### 环境要求

- **macOS**: macOS Tahoe 26.0+
- **Xcode**: 26+
- **iOS Deployment Target**: 26.0+
- **Swift**: 6.2

> 平台基线：本仓库统一以 iOS 26 / Xcode 26 / Swift 6.2 为标准开发环境；推荐模拟器设备：iPhone 17 Pro。

### 项目设置

1. **克隆项目**

   ```bash
   git clone https://github.com/chramboliao/NotBad.git
   cd NotBad
   ```

2. **安装开发工具**

   ```bash
   # 安装 pre-commit hooks

   brew install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg

   # 安装 SwiftLint（如果未安装）

   brew install swiftlint
   ```

3. **运行质量检查**

   ```bash
   # 运行完整质量门槛检查

   ./Scripts/quality_gate.sh
   ```

4. **打开项目**

   ```bash
   open NotBad.xcodeproj
   ```

### 首次运行

1. 打开 `NotBad.xcodeproj`
2. 选择目标设备 (iPhone 17 Pro 推荐)
3. 按 `Cmd + R` 运行

项目首次运行时会自动：

- 初始化本地 SwiftData 数据库
- 设置基础用户偏好
- 加载测试数据 (Debug模式下)

> 💡 **最小可用配置参考**: 如需了解项目的最简化结构，可查看 [`milestone/single-entry-success`](https://github.com/chramboliao/NotBad/tree/milestone/single-entry-success) 分支，该版本展示了单一入口文件架构 + 完整CI/CD的最小配置示例。

## 🏗️ 技术架构

| 层级 | 技术栈 | 说明 |
|------|--------|------|
| **UI层** | SwiftUI + Swift 6.2 | 声明式用户界面，严格并发安全 |
| **业务层** | Clean Architecture + Coordinator Pattern | 分层架构，依赖倒置 |
| **数据层** | SwiftData + CloudKit | 本地优先，云端同步 |
| **AI服务** | Vision + Core ML + Gemini API | 混合AI架构 |
| **并发处理** | Swift 6 Actor模型 | 数据竞争安全 |

## 🎯 项目状态

### 当前阶段: 重构准备 (2025年9月)

**重构目标**:

- [x] GitHub Flow 架构重组

> 提示：PRD 是本项目的单一事实来源（SSoT）。平台版本、范围、NFR 与指标以 PRD 为准：`docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md`

- [x] 质量门槛系统建立
- [x] 项目结构清理
- [ ] Swift 6.2 严格并发模式迁移
- [ ] iOS 26 新特性集成
- [ ] 简化的导航协调器实现

**重构后MVP目标**:

- [ ] 核心错题管理功能
- [ ] 拍照OCR识别
- [ ] 基础复习模式
- [ ] SwiftData本地存储

## 📖 项目文档

### 核心文档

- 📋 **[质量门槛指南](docs/QUALITY_GATES.md)** - 代码质量标准和流程
- 📖 **[开发工作流程](docs/DEVELOPMENT_WORKFLOW.md)** - GitHub Flow 和开发规范
- 🔧 **[Scripts工具集](Scripts/README.md)** - 质量保障脚本说明

### 历史文档 (重构前)

- 📄 **产品需求文档 (PRD)**: `docs/prd/` - 完整的功能需求
- 🏗️ **技术设计文档 (TDD)**: `docs/tdd/` - 系统架构设计
- 📊 **需求追踪矩阵 (RTM)**: `docs/rtm/` - 需求实现追踪
- 📚 **术语表**: `docs/glossary/` - 业务和技术术语
- 🧠 **架构决策记录 (ADR)**: `docs/adr/` - 技术决策历史

> 💡 **注意**: `docs/` 目录下的文档反映重构前的设计，部分内容可能已过时。

## 🔄 Git 分支与发布流程（Git Flow）

### 分支与流程（main ← release/\* ← develop ← feature/\*）

```text
main                (生产稳定分支，随时可发布)
release/<version>   (预发布分支，版本冻结/回归修复)
develop             (日常集成分支，功能汇聚与回归验证)
feature/<name>      (基于 develop 的特性分支，小步快跑)
hotfix/<name>       (基于 main 的紧急修复，修复后回灌 develop)
```

### 开发与发布流程

1) Feature 开发（Feature → Develop）
   - 从 `develop` 创建 `feature/xxx`
   - 完成开发并本地通过 `./Scripts/quality_gate.sh`
   - 提交 PR 到 `develop`，等待 CI 绿灯与评审通过

2) Release 准备（Develop → Release → Main）
   - 从 `develop` 切出 `release/x.y.z`，进入版本冻结，仅允许修复与文档/版本号变更
   - 在 `release/x.y.z` 上完成版本号、变更日志与最后回归
   - 提交 PR 到 `main`（main ← release/x.y.z），合并后在 `main` 打标签并产出构建（如 TestFlight/App Store）
   - 将 `release/x.y.z` 变更回灌到 `develop`

3) Hotfix 紧急修复（Main → Hotfix → Main + Develop）
   - 从 `main` 创建 `hotfix/x.y.z+1`
   - 修复后提交 PR 到 `main`，合并并打标签发布
   - 将 `hotfix/x.y.z+1` 回灌到 `develop`

## ⚡ 质量门槛

本项目实施严格的代码质量标准：

### 自动化检查

- **Pre-commit Hooks**: 提交时自动代码检查
- **SwiftLint**: 代码风格和最佳实践验证
- **测试覆盖率**: 最低80%覆盖率要求
- **CI/CD验证**: GitHub Actions自动化测试

### 质量标准

- ✅ **编译检查**: 0 errors
- ✅ **代码风格**: SwiftLint 合规
- ✅ **测试覆盖率**: ≥ 80%
- ✅ **性能回归**: ≤ 10%
- ✅ **提交规范**: Conventional Commits

### 本地质量检查

```bash

# 运行完整质量检查

./Scripts/quality_gate.sh

# 查看质量标准详情

cat docs/QUALITY_GATES.md
```

## 🛠️ CI/CD 基础设施

### 自托管运行器

- **硬件**: Mac mini M4 (16GB RAM)
- **状态**: ✅ 在线运行
- **性能**: 比GitHub托管运行器快2-3倍
- **成本**: 年节省 $5,400+ CI/CD费用

### 工作流程

- **代码质量检查**: 每次push到develop分支
- **完整测试套件**: 每个Pull Request
- **自动化部署**: 合并到main分支

## 📱 支持平台

| 平台 | 最低版本 | 状态 |
|------|----------|------|
| iOS | 26.0+ | 🎯 主要目标 |
| iPadOS | 26.0+ | 🔮 未来支持 |
| macOS | - | ❌ 暂不支持 |
| watchOS | - | ❌ 暂不支持 |

## 🤝 贡献指南

### 提交代码

1. Fork本仓库
2. 切换到develop分支: `git checkout develop`
3. 创建功能分支: `git checkout -b feature/amazing-feature`
4. 提交变更: `git commit -m 'feat: add amazing feature'`
5. 推送分支: `git push origin feature/amazing-feature`
6. 创建Pull Request到develop分支

### 提交信息规范

使用 [Conventional Commits](https://conventionalcommits.org/) 规范：

```text
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式化
refactor: 重构
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 报告问题

使用 [GitHub Issues](https://github.com/chramboliao/NotBad/issues) 报告bug或提出功能建议。

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

## 📞 联系方式

- 📧 **邮箱**: <dev@notbad.app>
- 💬 **讨论**: [GitHub Discussions](https://github.com/chramboliao/NotBad/discussions)
- 🐛 **Bug报告**: [GitHub Issues](https://github.com/chramboliao/NotBad/issues)

---

### Made with ❤️ for education

### 让每一次复习都有价值
