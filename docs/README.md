---
title: NotBad 文档中心 v6.0
version: v6.0
lastUpdated: 2025-09-19
---

# NotBad 文档中心 v6.0
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---

## NotBad 文档中心 v6.0

> **版本**: v6.0
> **技术栈**: Swift 6.2 + iOS 26 + Xcode 26
> **最后更新**: 2025年9月19日

本文档中心为 NotBad 项目提供完整的产品与技术文档生态系统，实现需求、设计、实现、测试的全流程追踪。

> 平台基线：所有文档与实现统一基于 iOS 26 / Xcode 26 / Swift 6.2；推荐开发与测试设备：iPhone 17 系列（iPhone 17 Pro）。

## 📋 核心文档 (v6.0)

### 产品与技术规范

| 文档类型 | 文档名称 | 版本 | 状态 |
|----------|----------|------|------|
| **PRD** | [产品需求文档 v6.0](prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md) | v6.0 | ✅ 当前版本 |
| **TDD** | [技术设计文档 v6.0](tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md) | v6.0 | ✅ 当前版本 |
| **RTM** | [需求追踪矩阵 v6.0](rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md) | v6.0 | ✅ 当前版本 |
| **UX Spec** | [用户体验设计规范 v6.0](design/UX_SPEC.md) | v6.0 | ✅ 当前版本 |

### 术语与词汇管理

| 类型 | 文档名称 | 版本 | 覆盖范围 |
|------|----------|------|----------|
| **业务术语** | [业务术语表 v6.0](glossary/NotBad%20App%20-%20业务术语表%20v6.0.md) | v6.0 | 产品功能、用户场景 |
| **技术术语** | [技术术语表 v6.0](glossary/NotBad%20App%20-%20技术术语表%20v6.0.md) | v6.0 | Swift 6.2、iOS 26 |
| **代码映射** | [术语代码索引 v6.0](glossary/NotBad%20App%20-%20术语到代码索引%20v6.0.md) | v6.0 | 术语到代码追踪 |

## 🏛️ 架构决策记录 (ADR)

- **ADR 索引**: [adr/README.md](adr/README.md)
- **Swift 6.2升级决策**: [ADR-004 Swift 6.2 架构升级决策](adr/ADR-004%20Swift%206.2%20架构升级决策.md)
- **导航协调器模式**: [ADR-005 导航协调器模式](adr/ADR-005%20导航协调器模式.md)
- **底部Tab导航架构**: [ADR-006 底部Tab导航架构设计](adr/ADR-006%20底部Tab导航架构设计.md)

## 🚀 CI/CD 自动化

- **CI/CD 配置中心**: [ci-cd/README.md](ci-cd/README.md)
- **完整配置指南**: [CI/CD Configuration v6.0](ci-cd/NotBad-CI-CD-Configuration-v6.0.md)
- **自托管运行器**: [完整部署指南](ci-cd/self-hosted-runner-complete-guide.md)

## 🎨 设计系统

- **设计系统索引**: [design/README.md](design/README.md)
- **UX 设计规范**: [UX_SPEC.md](design/UX_SPEC.md) - Swift 6.2 + iOS 26组件库

## 🔒 合规与隐私

- **合规文档中心**: [compliance/README.md](compliance/README.md)
- **隐私合规检查清单**: [隐私和合规检查清单](compliance/privacy-and-compliance-checklist.md)

## 📊 质量保证

- **质量门禁**: [QUALITY_GATES.md](QUALITY_GATES.md)
- **开发工作流**: [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md)

## 🎯 支持资源

### 静态资源

- **图片资源**: [assets/README.md](assets/README.md) - 架构图、流程图等静态文件

### 会议记录

- **会议纪要**: [meetings/README.md](meetings/README.md) - 项目会议与决策记录

## 📈 版本历史

### v6.0 (2025-09-19) - 当前版本

- ✨ 技术栈升级: Swift 6.2 + iOS 26 + Xcode 26
- 🌟 Discovery社区: 匿名化社区功能模块
- ⚡ 性能优化: Enhanced Actor + ProMotion Max支持
- 🛠️ CI/CD现代化: 完整自动化构建流程
- 📚 文档治理: 统一版本管理和追踪体系

### 历史版本

- v5.0: Swift 6.2基础架构
- v4.0: 初始MVP功能规范
- v3.0-v1.0: 早期迭代版本

## 🔗 快速导航

### 按角色分类

#### 产品经理

- [PRD v6.0](prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md) - 产品需求和功能规范
- [RTM v6.0](rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md) - 需求追踪和验收

#### 设计师

- [UX_SPEC.md](design/UX_SPEC.md) - 完整设计规范
- [设计系统](design/README.md) - 组件库和设计原则

#### 开发工程师

- [TDD v6.0](tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md) - 技术架构和实现
- [ADR-004](adr/ADR-004%20Swift%206.2%20架构升级决策.md) - Swift 6.2架构决策

#### DevOps工程师

- [CI/CD v6.0](ci-cd/NotBad-CI-CD-Configuration-v6.0.md) - 完整自动化配置
- [自托管指南](ci-cd/self-hosted-runner-complete-guide.md) - M4 Mac mini部署

#### QA工程师

- [质量门禁](QUALITY_GATES.md) - 测试标准和流程
- [RTM v6.0](rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md) - 验收标准追踪

## 📝 文档贡献

### 更新原则

1. **版本一致性**: 所有文档保持v6.0版本一致
2. **技术对齐**: 确保与Swift 6.2 + iOS 26技术栈对齐
3. **追踪完整**: 保持PRD→TDD→RTM的完整追踪链
4. **质量标准**: 遵循文档质量标准和格式规范

### 维护责任

- **产品文档**: 产品团队
- **技术文档**: 开发团队
- **设计文档**: 设计团队
- **CI/CD文档**: DevOps团队

---

**建议**: 将此文档作为项目文档的统一入口，通过仓库根目录的 `README.md` 链接到此页面，便于团队快速访问。
