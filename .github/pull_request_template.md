# Pull Request 模板

## 概述

简要说明本 PR 的目的与变更范围。

> 提交分支：请优先向 `develop` 发起 PR；经集成验证后再合并到 `main`。

## 变更内容

- [ ] 代码变更
- [ ] 文档更新（PRD/TDD/RTM/Glossary/ADR）
- [ ] 脚本/CI 配置

## 核对清单

- [ ] 基线版本与设备引用统一为 iOS 26 / Xcode 26 / Swift 6.2 / iPhone 17 系列
- [ ] PRD 链接：`docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md`
- [ ] TDD/RTM/Glossary 交叉链接正确，无历史后缀漂移
- [ ] 本地通过 `Scripts/quality_gate.sh`
- [ ] `markdownlint` 和链接检查通过
- [ ] 如涉及术语或架构变更，已更新 Glossary/ADR

## 相关问题/文档

关联的 Issue 或设计文档链接：
