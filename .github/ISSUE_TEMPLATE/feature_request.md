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

<!-- 这个功能解决什么问题？对应 product-requirements.md「用户旅程」中的哪个旅程？ -->

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

## Sprint Contract（Claude 开工前回填，commit 前回读）

<!--
由 Claude 在动第一行代码前以 Issue comment 写入；编码过程中若发现预期与现实不符，
必须先改 contract 再继续。Reviewer 与三方审计方（Codex / Gemini / Xcode Review）
以此为 scope 比对基准。详见 docs/workflow.md 《编码前契约》与 feedback.md F-018。
Appetite = Small 可简化填写；Medium/Large 必须逐条填写。
-->

- **Touches**：会新增/修改哪些文件（路径列表）
- **No-Touch**：显式不动哪些文件/模块（防 scope creep）
- **Interface Delta**：新增或修改的 public 接口签名预期（函数名 + 参数 + 返回类型）
- **Test Additions**：预期新增的测试用例（粒度到用例名）
- **DoD 最小集**：本 Issue 必须满足的 DoD 子集（从 `docs/workflow.md` DoD 中选）
- **预期不确定点**：哪些决策留给实现阶段自主判断
