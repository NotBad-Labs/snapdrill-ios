---
name: dod-checklist
description: PR 完成前逐项检查 Definition of Done。当用户说"检查 DoD/自检/验收/准备合并"或 PR 即将提交 Review 时触发。按改动类型（代码/文档/UI）加载对应子集。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
context: fork
disable-model-invocation: false
user-invocable: true
---

# /dod-checklist — PR 完成前 DoD 自检

## 一句话

逐项检查当前 PR 是否满足 Definition of Done。按改动类型自动筛选相关检查项。

## 触发场景

- 用户说："检查 DoD / 自检 / 验收 / 准备合并"
- 代码写完准备提交 Review 前
- sprint-contract 完成后，push 前

## 检查项

> 权威源：`docs/workflow.md` § Definition of Done。本 skill 为执行器。

### 代码质量（所有 PR）

- [ ] `swiftlint --strict` 0 violations
- [ ] `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` 0 errors
- [ ] CI test 通过（已有测试不得回归）
- [ ] 改接口签名后 grep 测试同步
- [ ] 涉及新 API/新交互时 PR 描述留有研究证据
- [ ] 新增抽象有明确必要性（原则 2：删掉比添加好）
- [ ] 功能不超出 Issue scope（原则 3：不为假设需求写代码）
- [ ] 跨模块边界有明确的契约定义（原则 5）
- [ ] 复杂业务状态由 ViewModel 集中编排（原则 6）
- [ ] 不可逆决策有记录（原则 7）—— 重大走 ADR，小决策在 PR 描述说明
- [ ] Codex 对抗性审查通过
- [ ] Xcode Review 核实通过（UI 改动必须）
- [ ] AI 反模式检查通过

### 功能完整性（feature/chore）

- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步（所有 PR）

- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 术语与 `product-glossary.md` 一致
- [ ] 合并后立即更新 `STATUS.md`
- [ ] `api-pitfalls.md` 已更新（实现中发现新 API 陷阱）
- [ ] `apple-limits.md` 已更新（实现中发现 Apple 平台新限制）
- [ ] `architecture.md` 已更新（新增/移除/重命名模块）
- [ ] `non-functional-requirements.md` 已评估（触及性能/内存边界时）

### Review 留痕（所有 PR）

- [ ] Review 结论已留痕（PR comment 或 PR 描述）

## 改动类型筛选

| 改动类型 | 必检项 |
|---|---|
| 纯代码（无 UI） | 代码质量 + 文档同步 + Review 留痕 |
| 代码 + UI | 代码质量 + 文档同步 + Review 留痕（含 Xcode Review） |
| 纯文档 | 文档同步 + Review 留痕（无需 swiftlint/build/Xcode Review） |
| bug fix | 代码质量 + 功能完整性 + Review 留痕 |

## 执行步骤

1. 判断当前 PR 的改动类型
2. 按类型加载对应的检查子集
3. 逐项验证并报告未通过项
4. 未通过项修复后才提交 Review

## 上游文档

- `docs/workflow.md` § Definition of Done — 完整 DoD 权威定义
- `docs/standards/engineering.md` — 7 条工程原则
- `docs/standards/execution-gates.md` — 执行门禁总表
