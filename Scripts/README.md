# Scripts & Tools

包含用于通过自动化改善**开发者体验 (DX)** 的脚本。

## 脚本说明

| 脚本 | 用途 |
|---|---|
| `lint.sh` | 调用 SwiftLint 进行代码风格检查 |
| `setup.sh` | 新开发者入职的一键环境配置（待完善） |
| `pre-commit` | Git pre-commit hook，自动触发 lint |
| `check_headers.py` | 检查 Swift 文件头部版权声明是否规范 |
| `add_assets.rb` | 向 Asset Catalog 批量添加资源 |
| `add_swiftlint_phase.rb` | 为 Xcode Target 自动添加 SwiftLint Build Phase |
| `fix_duplicate_assets.rb` | 清理 Asset Catalog 中的重复资源 |
| `inspect_project.rb` | 检查 `.xcodeproj` 项目文件结构 |
| `ci-local.sh` | 本地模拟 CI 流程（lint + build） |
| `gemini_review.py` | Gemini Code Review GitHub Action 脚本 |
| `gemini_project_review.py` | Gemini 全项目级 Review 脚本 |
| `gemini_utils.py` | Gemini Review 共享工具函数 |
| `post_review.sh` | 将 Review 结果发布到 GitHub PR |

此目录不包含任何生产环境代码。
