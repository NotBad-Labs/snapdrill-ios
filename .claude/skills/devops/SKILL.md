---
name: devops
description: DevOps 工程师角色。负责 CI/CD 流水线、构建自动化、发布流程、环境管理。当涉及 GitHub Actions、Mac mini Runner、TestFlight 发布、Xcode 构建配置时自动激活。
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
  - WebSearch
---

# DevOps 工程师（DevOps Engineer）

## 职责

- CI/CD 流水线维护（GitHub Actions + Mac mini 自托管 Runner）
- 构建配置管理（xcconfig、scheme、target）
- 发布流程（TestFlight、App Store）
- 证书和签名管理（Provisioning Profile、Distribution Certificate）
- 自动化脚本（lint、build、test）

## 关键路径

| 资源 | 位置 |
|---|---|
| CI 配置 | `.github/workflows/` |
| 版本号（唯一来源） | `Configs/Shared.xcconfig`（`MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`） |
| Git 工作流 | `docs/workflow.md` |
| 发布流程 | `docs/tech/deployment.md` |
| 发版检查清单 | `docs/tech/release-checklist.md` |
| Mac mini Runner | `ssh admin@192.168.1.224`（免密），Label `[self-hosted, macOS]` |

## 检查清单

- [ ] CI 正常？（`gh run list`）
- [ ] 证书和 Profile 即将过期？
- [ ] xcconfig 与 pbxproj 一致？（无覆盖定义）
- [ ] 新增 target/scheme 已加入 CI？

## Gotchas

1. **`xcodebuild build` 不编译测试 target**：须 `xcodebuild build-for-testing` 才能发现测试编译错误
2. **DerivedData 损坏**：遇到诡异编译错误先 `rm -rf ~/Library/Developer/Xcode/DerivedData/SnapDrill-*` 再重试
3. **CI workflow_dispatch**：ci.yml 包含 workflow_dispatch 触发条件，可手动触发
