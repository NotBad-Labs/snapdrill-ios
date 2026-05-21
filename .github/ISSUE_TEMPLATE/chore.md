---
name: 工程任务
about: 文档更新、重构、CI/CD、依赖升级等非功能性任务
title: "chore: "
labels: chore
assignees: ""
---

## 任务描述

<!-- 简要描述需要做什么 -->

## 动机

<!-- 为什么需要做这个 -->

## Severity

- [ ] S0（数据不可逆丢失）/ [ ] S1（流程完全阻断）/ [ ] S2（能完成但有摩擦）/ [ ] S3（更好但不紧急）

## Appetite

- [ ] Small（1-2 天）/ [ ] Medium（3-5 天）/ [ ] Large（1-2 周）

## Scope（做什么）

-

## No-Go（不做什么）

-

## 影响范围

<!-- 涉及哪些文件或模块 -->

## 验收标准（Given-When-Then）

1. Given [前置条件]
   When [用户操作]
   Then [预期结果]

## Sprint Contract（机器校验字段化体例，S-D7-003 共识）

<!--
F-018：由 Claude 在开工前以 Issue comment 写入字段化 contract（Scripts/audit/sprint_contract_gate.py 校验）。
trivial 改动（单行 typo/注释/日志）走机器可读豁免。
-->

Small chore 简化版：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #<num>
Issue Type: chore
Appetite: Small
Status: Building
Touches:
- <相对路径>
No-Touch:
- <相对路径 / glob>
DoD Minimum:
- <命令 / check>
Contract Author: claude
```

Medium / Large 需补 Interface Delta / Test Additions / Uncertainties 三字段。trivial 走 `Contract Required: exempt + Contract Exemption: trivial`。详见 `.claude/skills/sprint-contract/SKILL.md` + `.github/sprint-contract-policy.yml`。
