---
name: Bug 报告
about: 报告一个需要修复的问题
title: "fix: "
labels: bug
assignees: ""
---

## 问题描述

<!-- 简要描述遇到的问题 -->

## 复现步骤

1.
2.
3.

## 期望行为

<!-- 你期望发生什么 -->

## 实际行为

<!-- 实际发生了什么 -->

## 权威 / Oracle

<!-- 期望来自哪一条 Release Contract、feature/data/privacy contract、平台规范或回归测试？ -->

## Current Admission

<!-- 历史材料只作证据。Green 默认填五行；Yellow / Red、T4、历史恢复或跨 lane 才追加 expanded admission。 -->

- **Base / current evidence**：`origin/develop@<full-sha>` + 复现 / path:line（PO 可留空，由 owning agent 在准入时补全）
- **Authority / outcome**：
- **Owner / scope / red lines**：
- **Acceptance / validation**：
- **Routing / dependencies / unresolved gates**：

## Severity

- [ ] S0（数据不可逆丢失）/ [ ] S1（流程完全阻断）/ [ ] S2（能完成但有摩擦）/ [ ] S3（更好但不紧急）

## Appetite

- [ ] Small（1-2 天）/ [ ] Medium（3-5 天）/ [ ] Large（1-2 周）

## Scope（做什么）

-

## No-Go（不做什么）

-

## 验证等级

- [ ] T0 / [ ] T1 / [ ] T2 / [ ] T3 / [ ] T4
- 最小复现 / fixture / targeted test：

## PO / legal / fact gates

<!-- 修复是否会改变产品语义、公开文案、数据/wire、签名或发布边界？ -->

## 环境

- iOS 版本：
- 设备型号：
- App 版本：

## 验收标准（Given-When-Then）

1. Given [前置条件]
   When [用户操作]
   Then [预期结果]
