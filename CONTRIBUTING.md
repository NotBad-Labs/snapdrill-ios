# 贡献指南

感谢你对 NotBad 项目的关注与贡献！本指南帮助你高效参与协作并保持文档与代码质量一致。

## 分支与提交（Git Flow）

- 分支模型：`main ← release/* ← develop ← feature/*`，紧急修复走 `hotfix/*`（main 基上切出，合并回 main 并回灌 develop）
- 命名规范：
  - `feature/<scope>-<short-desc>`（例：`feature/docs-v6.0-modernization`）
  - `release/x.y.z`（例：`release/1.0.0`）
  - `hotfix/x.y.z+1`（例：`hotfix/1.0.1`）
- PR 目标：
  - Feature → Develop（`develop ← feature/*`）
  - Release → Main（`main ← release/*`，发布后回灌 `develop`）
  - Hotfix → Main（`main ← hotfix/*`，合并后回灌 `develop`）
- 提交信息遵循约定式：`feat: ...` `fix: ...` `docs: ...` `chore: ...`

## 文档规范

- 基线平台：iOS 26+ / Xcode 26 / Swift 6.2；设备：iPhone 17 系列
- 参考单一事实来源（SSoT）：`docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md`
- 在 PRD/TDD/RTM/Glossary 之间保持交叉链接正确且无后缀漂移
- 遵循 markdownlint 规则；在 PR 前本地执行：`npm exec markdownlint "**/*.md" -c .markdownlint.jsonc`

## 质量检查

- 运行 `Scripts/quality_gate.sh`，确保：
  - SwiftLint 通过
  - 可在 iPhone 17 Pro (iOS 26) 模拟器上编译并通过单测
  - 覆盖率不低于 80%
  - markdownlint 和链接检查通过
  - 文档一致性检查通过

## 提交 PR

- 勾选 PR 模板中的核对项，附带关键文档链接（PRD/TDD/RTM）
- 如涉及术语变更，更新 `docs/glossary/`
- 如涉及架构或重要技术决策，提交 ADR 到 `docs/adr/`

## 讨论与支持

- 通过 Issue 讨论提案或问题
- 对于 CI/Runner 相关问题，参见 `docs/ci-cd/README.md`

欢迎你的贡献！
