---
description: 配置项目所需的 On-Demand Resources (ODR) 模型资源
---

# ODR 资源配置工作流

本工作流旨在规范资源文件作为 On-Demand Resources (ODR) 的引入、标记和校验过程。

## 背景

大尺寸模型或特定资源通过 ODR 减小初始包体积。

## 执行步骤

1. **资源准备**:
   - 确认资源文件已放置在 `SnapDrill/Resources/` 下。
   - 运行校验脚本检查必要文件。

2. **Xcode 手动配置 (关键)**:
   - 将文件夹拖入 Xcode。
   - 在 `File Inspector` 中设置 `On-Demand Resource Tags`。
   - 在 `Build Settings` 中搜索 `Prefetch On-Demand Resources` 确保包含对应 Tags。

3. **代码链接校验**:
   - 检查资源加载逻辑（如 `NSBundleResourceRequest`）中的 Tags 是否与 Xcode 中的配置匹配。

4. **自动化健康检查**:

   ```bash
   # 检查是否有大型文件误入 Git (应由 ODR/LFS 管理)
   find . -size +50M -not -path '*/.*'
   ```

## 注意事项

- 严禁将超过 50MB 的非代码文件直接提交至普通 Git 仓库（除非是必要的 Assets）。
