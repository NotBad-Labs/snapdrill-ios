---
name: 功能需求
about: 提出新功能或改进建议
title: "feat: "
labels: enhancement
assignees: ""
---

## 需求描述

<!-- 简要描述需要什么功能 -->

## 用户场景

<!-- 这个功能解决什么问题？对应 docs/product/product-journeys.md 中的哪个旅程（旅程 0-7）？ -->

## MoSCoW

- [ ] Must / [ ] Should / [ ] Could

## Appetite

- [ ] Small（1-2 天）/ [ ] Medium（3-5 天）/ [ ] Large（1-2 周）

## Severity

- [ ] S0（数据不可逆丢失）/ [ ] S1（流程完全阻断）/ [ ] S2（能完成但有摩擦）/ [ ] S3（更好但不紧急）

## Scope（做什么）

-

## No-Go（不做什么）

-

## 风险与不确定性

<!-- 已知的坑、技术风险、需要调研的问题 -->
-

## 方案建议

<!-- 如果有具体实现想法，请描述 -->

## 影响范围（涉及文件预估）

<!-- 涉及哪些模块？Core / Data / UI / Features / Infrastructure / App。预计改动的文件/模块列表，帮助 AI agent 约束 scope -->

## 验收标准（Given-When-Then）

1. Given [前置条件]
   When [用户操作]
   Then [预期结果]

## Sprint Contract（Claude 开工前以 Issue comment 回填，机器校验字段化体例）

<!--
F-018：Claude 在动第一行代码前以 Issue comment 写入字段化 contract（Scripts/audit/sprint_contract_gate.py 校验）。
编码过程中若发现预期与现实不符，必须先改 contract 再继续。Scope Creep 实时防御：编辑文件超出 Touches 或落在
No-Touch 即被 .claude/hooks/pre-edit-sprint-contract.sh 阻断。详见 docs/protocol.md / S-D7-003 共识。
-->

字段化体例（直接 `gh issue comment` 贴下方块）：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #<num>
Issue Type: enhancement
Appetite: Small | Medium | Large
Status: Building
Touches:
- <相对路径>
No-Touch:
- <相对路径 / glob>
Interface Delta:
- <public 签名 或 "none">
Test Additions:
- <测试用例名 或 "none">
DoD Minimum:
- <命令 / check>
Uncertainties:
- <已知未知 或 "none">
Contract Author: claude
```

Appetite = Small (chore) 可简化为 Touches / No-Touch / DoD Minimum 三字段。详见 `.claude/skills/sprint-contract/SKILL.md`。
