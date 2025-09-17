# NotBad 错题本 App

## 🚀 生产分支 (Production Branch)

这是 NotBad 错题本 App 的生产分支，只包含经过充分测试、准备发布的稳定代码。

## 📋 Git Flow 工作流程

本项目采用标准的 Git Flow 工作流程：

- **main** - 生产分支（当前分支）：只包含稳定的可发布版本
- **develop** - 开发分支：主要开发和集成分支
- **feature/** - 功能分支：新功能开发
- **release/** - 发布分支：发布前的测试和修复
- **hotfix/** - 热修复分支：生产环境紧急修复

## 🔄 开发流程

1. **开发新功能**：从 `develop` 分支创建 `feature/xxx` 分支
2. **功能完成**：合并到 `develop` 分支
3. **准备发布**：从 `develop` 创建 `release/vx.x.x` 分支
4. **发布上线**：将 `release` 分支合并到 `main` 并打标签
5. **紧急修复**：从 `main` 创建 `hotfix/xxx` 分支，修复后合并到 `main` 和 `develop`

## 📖 文档

完整的项目文档和开发指南请查看 `develop` 分支的 `docs/` 目录。

---

> 注意：此分支仅用于发布，开发工作请在 `develop` 分支进行。
