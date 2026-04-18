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

## Sprint Contract（Appetite >= Small 时必填）

<!-- 详见 docs/workflow.md 《编码前契约》；由 Claude 在开工前 Issue comment 回填 -->

- **Touches**：会修改哪些文件
- **No-Touch**：显式不动哪些文件
- **DoD 最小集**：从 `docs/workflow.md` DoD 中选本 Issue 必须满足的条目
