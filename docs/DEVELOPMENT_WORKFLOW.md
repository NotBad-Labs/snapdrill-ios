---
title: NotBad 开发工作流程（Git Flow）
version: v6.0
lastUpdated: 2025-09-21
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---

## 🚀 NotBad 开发工作流程（Git Flow）

## 📋 分支策略

### 分支结构

```plaintext
main                 生产稳定分支（可随时发布）
release/x.y.z        预发布分支（版本冻结，仅允许修复）
develop              日常集成分支（功能汇聚与回归验证）
feature/<name>       功能分支（基于 develop）
hotfix/x.y.z+1       紧急修复分支（基于 main）
```

### 分支说明

| 分支类型 | 命名规范 | 用途 | 合并目标 |
|----------|----------|------|----------|
| `main` | - | 生产环境，始终可部署 | - |
| `develop` | - | 日常集成与回归验证 | `release/*` |
| `feature/*` | `feature/功能名称` | 新功能开发 | `develop` |
| `release/*` | `release/x.y.z` | 预发布冻结与回归修复 | `main`（发布后回灌`develop`） |
| `hotfix/*` | `hotfix/x.y.z+1` | 线上紧急修复 | 合并到`main`并回灌`develop` |

## 🔄 开发与发布流程

### 1. 日常功能开发（Feature → Develop）

```bash
# 1. 从 develop 分支创建功能分支
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication

# 2. 开发功能
# ... 编写代码 ...

# 3. 提交代码
git add .
git commit -m "feat: 添加用户认证功能"

# 4. 推送功能分支
git push origin feature/user-authentication

# 5. 创建 Pull Request（develop ← feature/user-authentication）
# 在 GitHub 上创建 PR，等待 CI 测试通过

# 6. 合并到 develop
# PR 通过后合并到 develop 分支

# 7. 删除功能分支
git checkout develop
git pull origin develop
git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

### 2. 预发布与发布（Develop → Release → Main）

```bash
# 1. 从 develop 切出 release 分支
git checkout develop
git pull origin develop
git checkout -b release/1.0.0

# 2. 冻结版本并进行回归修复
# 仅允许修复问题、版本号、文档与元数据

# 3. 提交修复
git add .
git commit -m "fix: 修复内存泄漏问题"

# 4. 推送修复分支
git push origin bugfix/memory-leak-fix

# 5. 创建 Pull Request（main ← release/1.0.0）
# 在 GitHub 上创建 PR，等待完整测试通过

# 6. 合并到 main 并打标签发布

# 7. 删除修复分支
git checkout main
git pull origin main
git branch -d bugfix/memory-leak-fix
git push origin --delete bugfix/memory-leak-fix
```

### 3. 紧急修复（Hotfix → Main + Develop）

```bash
# 1. 从 main 创建 hotfix 分支
git checkout main
git pull origin main
git checkout -b hotfix/1.0.1

# 2. 修复问题并创建 PR（main ← hotfix/1.0.1）
# 合并到 main 后打标签发布

# 3. 将 hotfix 回灌到 develop
git checkout develop
git merge --no-ff hotfix/1.0.1
git push origin develop
```

## 🧪 CI/CD 集成

### 自动化测试

- `feature/*`：代码质量 + 单元 + 集成
- `develop`：完整测试套件（回归）
- `release/*`：完整测试 + 构建归档
- `main`：完整测试 + 打包/归档（可选）

### 测试覆盖

| 分支 | 代码质量 | 单元测试 | 集成测试 | 性能测试 | UI测试 | 构建归档 |
|------|----------|----------|----------|----------|--------|----------|
| `main` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `release/*` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `develop` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `feature/*` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

## 📝 提交信息规范

### 提交类型

- `feat:` 新功能
- `fix:` 问题修复
- `docs:` 文档更新
- `style:` 代码格式调整
- `refactor:` 代码重构
- `test:` 测试相关
- `chore:` 构建过程或辅助工具的变动

### 示例

```bash
git commit -m "feat: 添加用户登录功能"
git commit -m "fix: 修复内存泄漏问题"
git commit -m "docs: 更新API文档"
git commit -m "refactor: 重构数据访问层"
```

## 🔍 代码审查

### Pull Request 规范

1. **标题**: 清晰描述变更内容
2. **描述**: 详细说明变更原因和影响
3. **测试**: 确保所有测试通过
4. **文档**: 更新相关文档

### 审查检查清单

- [ ] 代码质量符合标准
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] 没有破坏性变更
- [ ] 性能影响评估

## 🚨 最佳实践

### 分支管理

1. **保持分支更新**: 定期从develop拉取最新代码
2. **及时删除分支**: 合并后立即删除功能分支
3. **使用有意义的分支名**: 清晰描述功能或修复
4. **小步提交**: 频繁提交，保持历史清晰

### 代码质量

1. **遵循代码规范**: 使用SwiftLint检查
2. **编写测试**: 新功能必须包含测试
3. **文档更新**: 重要变更需要更新文档
4. **性能考虑**: 关注内存和性能影响

### 发布管理

1. **版本标签**: 使用语义化版本号
2. **变更日志**: 维护详细的变更记录
3. **回滚准备**: 准备好回滚策略
4. **监控部署**: 密切关注部署后的状态

---

**这个工作流程确保了代码质量、团队协作和发布稳定性。** 🎯
