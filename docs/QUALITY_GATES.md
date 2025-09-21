---
title: NotBad 质量门槛指南
version: v6.0
lastUpdated: 2025-09-21
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---

## NotBad 质量门槛指南

## 🎯 概述

本文档描述了 NotBad 项目的代码质量门槛和检查流程。所有代码在合并到 `main` 分支之前都必须通过这些质量检查。

## 🔍 质量检查项目

### 1. 🪝 Pre-commit Hooks

在每次提交时自动运行：

- **SwiftFormat** - 代码格式化
- **SwiftLint** - 代码风格和最佳实践检查
- **文件检查** - 去除多余空白、检查文件大小等
- **提交信息检查** - 确保符合 Conventional Commits 规范

### 2. 📝 代码风格 (SwiftLint)

- **最低要求**: 0 errors, 允许少量 warnings
- **覆盖范围**: 所有 Swift 源代码
- **检查项目**:
  - 代码风格一致性
  - 命名规范
  - 代码复杂度控制
  - 最佳实践遵循

### 3. 🧪 测试覆盖率

- **最低要求**: 80% 代码覆盖率
- **检查范围**: 除 UI 测试外的所有源代码
- **测试类型**:
  - 单元测试 (Unit Tests)
  - 集成测试 (Integration Tests)
  - UI 测试 (UI Tests)

### 4. 🏗️ 编译检查

- **要求**: 必须无编译错误
- **平台**: iOS 模拟器和真机
- **配置**: Debug 和 Release 配置都必须编译成功

### 5. ⚡ 性能检查

- **启动时间**: < 3秒
- **内存使用**: 合理范围内
- **无性能回归**: 相比基准版本性能不能下降超过10%

## 🛠️ 本地开发流程

### 设置开发环境

```bash
# 1. 安装 pre-commit
brew install pre-commit

# 2. 在项目中安装 hooks
pre-commit install
pre-commit install --hook-type commit-msg

# 3. 首次运行检查所有文件
pre-commit run --all-files
```

### 日常开发

```bash
# 1. 开发功能
git checkout develop
git checkout -b feature/new-feature

# 2. 提交代码（会自动运行 pre-commit 检查）
git add .
git commit -m "feat: add new feature"

# 3. 运行完整质量检查
./Scripts/quality_gate.sh

# 4. 推送到远程
```bash
git push origin feature/new-feature
```

### 提交信息规范

使用 [Conventional Commits](https://conventionalcommits.org/) 规范：

```plaintext
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 类型 (Type)

- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式化
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动
- `perf`: 性能优化
- `ci`: CI配置文件和脚本的变动
- `build`: 影响构建系统或外部依赖的更改

#### 示例

```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve memory leak in image cache"
git commit -m "docs: update API documentation"
git commit -m "test: add unit tests for user service"
```

## 🚨 质量门槛失败处理

### Pre-commit 检查失败

```bash
# 查看失败原因
git status

# 修复问题后重新提交
git add .
git commit -m "fix: resolve linting issues"
```

### CI 检查失败

1. 查看 GitHub Actions 的详细日志
2. 本地运行 `./Scripts/quality_gate.sh` 复现问题
3. 修复问题后推送新的提交

### 测试覆盖率不足

```bash
# 查看覆盖率报告
python3 Scripts/check_coverage.py --detailed

# 添加测试
# 重新运行测试
xcodebuild test -project NotBad.xcodeproj -scheme NotBad -enableCodeCoverage YES
```

## 📊 质量指标监控

### 定期检查

- **每周**: 检查代码覆盖率趋势
- **每月**: 审查 SwiftLint 规则和违规情况
- **每季度**: 评估和更新质量标准

### 工具和报告

- **SwiftLint**: 代码风格报告
- **Xcode Code Coverage**: 测试覆盖率报告
- **Performance Tests**: 性能基准报告
- **GitHub Actions**: CI/CD 成功率统计

## 🔧 自定义配置

### SwiftLint 配置

编辑 `.swiftlint.yml` 文件来调整规则：

```yaml
# 禁用特定规则
disabled_rules:
  - line_length

# 自定义规则参数
line_length:
  warning: 120
  error: 200
```

### Pre-commit 配置

编辑 `.pre-commit-config.yaml` 文件来调整检查项目。

## 🆘 获取帮助

如果遇到质量门槛相关问题：

1. 查看本文档的相关章节
2. 检查项目的 `Scripts/` 目录中的工具脚本
3. 查看 GitHub Issues 中的已知问题
4. 在团队群组中寻求帮助

---

> 💡 **提示**: 质量门槛的目标是提高代码质量，而不是阻碍开发。如果某个检查过于严格，请及时反馈并讨论调整。
