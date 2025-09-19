# NotBad 静态资源管理 v6.0

> **版本**: v6.0
> **最后更新**: 2025年9月19日

本目录用于存放文档中引用的各类静态资源，如架构图、流程图、数据模型图、UI设计稿等。

## 📁 资源分类

### 架构与技术图表

- **系统架构图**: 整体技术架构、Clean Architecture分层
- **数据模型图**: SwiftData模型、CloudKit同步架构
- **流程图**: CI/CD流程、用户任务流程
- **Discovery社区**: 匿名化架构、内容审核流程

### UI/UX设计资源

- **线框图**: 页面布局和信息架构
- **视觉设计**: 色彩系统、组件设计
- **交互流程**: 用户体验流程图
- **ProMotion Max**: 120fps动效参考

## 📋 命名规范

### 文件命名格式

```
<文档类型>-<功能模块>-<描述>-v6.<扩展名>
```

### 命名示例

**架构图**:
- `tdd-clean-architecture-layers-v6.png`
- `tdd-discovery-community-flow-v6.svg`
- `tdd-swiftdata-cloudkit-sync-v6.drawio`

**设计稿**:
- `ux-discovery-post-card-v6.png`
- `ux-ocr-preview-component-v6.svg`
- `ux-color-system-tokens-v6.svg`

**流程图**:
- `prd-user-journey-student-v6.drawio`
- `cicd-github-actions-flow-v6.png`
- `compliance-privacy-audit-flow-v6.svg`

## 🔗 引用方式

### Markdown文档中引用

```markdown
![Clean Architecture分层图](../assets/tdd-clean-architecture-layers-v6.png)
![Discovery社区流程](../assets/tdd-discovery-community-flow-v6.svg)
```

### 相对路径说明

- 从`docs/prd/`引用: `../assets/filename`
- 从`docs/tdd/`引用: `../assets/filename`
- 从`docs/design/`引用: `../assets/filename`

## 🛠️ 技术建议

### 推荐格式

1. **矢量图优先**: `.svg`, `.drawio` 便于编辑和缩放
2. **网络友好**: `.png` 用于复杂图像，`.jpg` 用于照片
3. **文档友好**: `.pdf` 用于正式设计文档

### 质量标准

- **分辨率**: 最低1920x1080，Retina屏优化
- **压缩**: 平衡质量和文件大小
- **色彩**: 支持浅色/深色模式
- **文字**: 保证在GitHub上可读

## 📊 Swift 6.2 + iOS 26 特殊要求

### Enhanced Actor图表

- 并发架构图需要清晰显示Actor边界
- 标注@MainActor和自定义Actor的使用场景

### iOS 26特性图表

- ProMotion Max 120fps动效时序图
- Advanced Vision Framework处理流程
- Enhanced SwiftData + CloudKit集成架构

### Discovery社区资源

- 匿名化数据流程图
- 内容审核状态机图
- COPPA/GDPR合规流程图

## 🔄 版本管理

### 版本命名

- 所有资源文件包含`-v6`版本标识
- 重大更新时递增版本号
- 保持与文档版本一致

### 更新流程

1. 创建新版本文件（如`-v6.1`）
2. 更新引用文档中的链接
3. 确认旧版本是否需要保留
4. 提交时包含变更说明

## 📋 当前资源清单

### 架构图 (TDD相关)

- [ ] Clean Architecture分层图
- [ ] Discovery社区数据架构
- [ ] Enhanced Actor并发模型
- [ ] SwiftData + CloudKit同步架构

### 设计资源 (UX相关)

- [ ] Discovery社区组件设计
- [ ] OCR预览组件设计
- [ ] iOS 26 Material效果示例
- [ ] ProMotion Max动效参考

### 流程图 (PRD相关)

- [ ] 用户注册和隐私同意流程
- [ ] Discovery内容审核流程
- [ ] COPPA年龄验证流程

### CI/CD图表

- [ ] GitHub Actions工作流图
- [ ] 自托管运行器架构图
- [ ] 质量门禁流程图

---

**维护责任**: 设计团队 + 技术团队
**工具推荐**: Figma, Draw.io, Sketch, Adobe Illustrator
**版本同步**: 与PRD v6.0、TDD v6.0、UX Spec v6.0保持一致
