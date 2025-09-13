# 🚀 NotBad 开发工作流程 (GitHub Flow)

## 📋 分支策略

### 分支结构
```
main (生产环境)
├── feature/功能名称 (功能开发)
├── bugfix/问题描述 (问题修复)
└── milestone/* (里程碑分支)
```

### 分支说明

| 分支类型 | 命名规范 | 用途 | 合并目标 |
|----------|----------|------|----------|
| `main` | - | 生产环境，始终可部署 | - |
| `feature/*` | `feature/功能名称` | 新功能开发 | `main` |
| `bugfix/*` | `bugfix/问题描述` | 问题修复 | `main` |
| `milestone/*` | `milestone/里程碑名称` | 重要里程碑记录 | - |

## 🔄 开发流程

### 1. 日常功能开发

```bash
# 1. 从main分支创建功能分支
git checkout main
git pull origin main
git checkout -b feature/user-authentication

# 2. 开发功能
# ... 编写代码 ...

# 3. 提交代码
git add .
git commit -m "feat: 添加用户认证功能"

# 4. 推送功能分支
git push origin feature/user-authentication

# 5. 创建Pull Request (main ← feature/user-authentication)
# 在GitHub上创建PR，等待CI/CD测试通过

# 6. 合并到main
# PR通过后合并到main分支

# 7. 删除功能分支
git checkout main
git pull origin main
git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

### 2. 问题修复

```bash
# 1. 从main分支创建修复分支
git checkout main
git pull origin main
git checkout -b bugfix/memory-leak-fix

# 2. 修复问题
# ... 修复代码 ...

# 3. 提交修复
git add .
git commit -m "fix: 修复内存泄漏问题"

# 4. 推送修复分支
git push origin bugfix/memory-leak-fix

# 5. 创建Pull Request (main ← bugfix/memory-leak-fix)
# 在GitHub上创建PR，等待测试通过

# 6. 合并到main
# PR通过后合并到main分支

# 7. 删除修复分支
git checkout main
git pull origin main
git branch -d bugfix/memory-leak-fix
git push origin --delete bugfix/memory-leak-fix
```

### 3. 发布管理

```bash
# GitHub Flow 中，main分支始终可部署
# 当需要发布时，直接创建标签即可

# 1. 确保main分支是最新的
git checkout main
git pull origin main

# 2. 创建发布标签
git tag -a v1.0.0 -m "Release version 1.0.0

- 新功能: 用户认证系统
- 修复: 内存泄漏问题
- 优化: 性能提升20%"

# 3. 推送标签
git push origin v1.0.0

# 4. 在GitHub上创建Release
# 使用标签创建正式的Release发布
```

## 🧪 CI/CD 集成

### 自动化测试

- **main分支**: 运行完整测试套件 + 构建归档
- **功能分支**: 运行基础测试（代码质量 + 单元测试 + 集成测试）

### 测试覆盖

| 分支 | 代码质量 | 单元测试 | 集成测试 | 性能测试 | UI测试 | 构建归档 |
|------|----------|----------|----------|----------|--------|----------|
| `main` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `feature/*` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `bugfix/*` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

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
