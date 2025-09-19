# Pull Request 模板（Git Flow）

## 概述

简要说明本 PR 的目的与变更范围。

> 提交流向：

- 功能：`develop ← feature/*`
- 预发布：`main ← release/*`（发布后回灌 `develop`）
- 紧急修复：`main ← hotfix/*`（合并后回灌 `develop`）

## 变更内容

- [ ] 代码变更
- [ ] 文档更新（PRD/TDD/RTM/Glossary/ADR）
- [ ] 脚本/CI 配置

## 核对清单

- [ ] 基线版本与设备统一：iOS 26 / Xcode 26 / Swift 6.2 / iPhone 17 系列
- [ ] PRD 链接：`docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md`
- [ ] TDD/RTM/Glossary 交叉链接正确，无历史后缀漂移
- [ ] 本地通过 `Scripts/quality_gate.sh`
- [ ] 如为 Release PR：包含版本号与变更日志更新
- [ ] 如为 Hotfix PR：计划回灌 `develop`
- [ ] 可选：已使用 `Scripts/generate_changelog_from_git.py` 生成并整理 CHANGELOG 草稿
- [ ] `markdownlint` 和链接检查通过
- [ ] 如涉及术语或架构变更，已更新 Glossary/ADR

## 相关问题/文档

关联的 Issue 或设计文档链接：
