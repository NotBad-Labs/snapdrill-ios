# SnapDrill 协作流程

> 开发闭环、Git 工作流、Code Review、优先级。工程哲学见 `agent/rules/engineering.md`，协作模式见 `agent/rules/collaboration.md`。
> 产品文档阅读入口见 `docs/product/README.md`。

---

## 文档裁决顺序

文档冲突时按以下顺序裁决：

1. `docs/product/product-vision.md`
2. `docs/product/PRD.md`
3. 相关 `docs/decisions/ADR-*`
4. `docs/product/product-design.md` / `docs/product/product-business.md` / `docs/tech/compliance.md` / `docs/tech/non-functional-requirements.md`
5. `docs/product/product-cases.md` / `docs/product/product-journeys.md` / `docs/product/product-glossary.md` / `docs/tech/design/*.md`
6. `docs/tech/architecture.md` / `docs/tech/api-reference.md` / `STATUS.md` / 审计报告

**硬规则**：
- `architecture.md`、`api-reference.md`、`STATUS.md`、审计报告属于映射/快照层，不得反向定义事实。
- `product-cases.md` 定义验收，不单独扩张产品承诺。
- `docs/tech/design/*.md` 负责把上游要求收敛成技术方案，不替代 PRD 或 ADR。
- 文档属性按内容语义判定，不按文件名判定。若命名与内容冲突，以内容语义为准并先修正文档边界声明。
- 文档治理默认仅覆盖第一方文档；第三方开源文档不纳入重构范围。
- `.claude/worktrees/**` 下的镜像文档不纳入治理与审计统计（仅作为临时执行副本）。

具体上下游传播关系见 `docs/DOC_DEPENDENCY_MAP.md`（改一处时按该图同步下游，避免返工）。

---

## Baseline 切换策略（2026-04-13 / #583）

自 `Codex Baseline v1（文档治理）` 起，历史 issue/PR 默认按“参考证据”处理，不自动继承为当前执行承诺。

硬规则（2026-04-13 起）：

- 以 `#583` 为执行基线，`#583` 之前的 issue/PR 一律视为参考轨道，不进入当前主线待办。
- 唯一例外是“外部依赖阻塞项”（例如账号、商店配置、第三方平台开通）且仍与当前目标直接相关。

执行规则：

- 历史 issue/PR 的原结论只可作为背景，不可直接转化为当前执行任务。
- 需要延续时，必须以当前 SoT 重新建单并明确“外部阻塞”事实链路。
- 裁决与回写优先进入第一方文档与当前 issue，不写入工具私有记忆。

---

## 开发闭环（Personal Kanban）

```
Shaped → Building (WIP≤2) → Reviewing → Done
```

无固定周期。做完一个拉下一个。

### Issue 模板（Shape 阶段）

```markdown
## 问题
[用户遇到了什么问题？]

## MoSCoW
- [ ] Must / [ ] Should / [ ] Could

## Severity
- [ ] S0（数据不可逆丢失）/ [ ] S1（流程完全阻断）/ [ ] S2（能完成但有摩擦）/ [ ] S3（更好但不紧急）

## Appetite
- [ ] Small（1-2 天）/ [ ] Medium（3-5 天）/ [ ] Large（1-2 周）

## Scope（做什么）
-

## No-Go（不做什么）
-

## 验收标准（Given-When-Then）
1. Given [前置条件]
   When [用户操作]
   Then [预期结果]
```

### Issue 标签规范

新建或整理 Issue 时统一使用以下三段式标签：

- `type:*`（任务类型）：`type:bug` / `type:enhancement` / `type:tech-debt` / `type:docs`
- `priority:*`（优先级）：`priority:S0` / `priority:S1` / `priority:S2` / `priority:S3`
- `agent:*`（来源归属）：`agent:codex` / `agent:claude`

执行约束：

- 每个 Open Issue 必须且仅保留 1 个 `type:*`。
- 每个 Open Issue 必须且仅保留 1 个 `priority:*`。
- 每个 Open Issue 必须且仅保留 1 个 `agent:*`（历史来源可追溯）。
- 模板只预置 `type:*`，`priority:*` 与 `agent:*` 在 triage 时补齐。
- 旧标签 `bug` / `enhancement` / `chore` / `S0..S3` / `claude-code` / `codex-code` 仅保留历史检索价值，不再用于新建或更新。

### Scope 控制

1. **Appetite 预算**：超预算砍 scope，不加时间
2. **No-Go 清单**：Issue 明确不做什么
3. **发现即建 Issue**：Build 中范围外的新发现不在当前 PR 处理

---

## Git 工作流

```
main ← App Store，只接受 develop 的 PR
develop ← TestFlight，只接受 feature/fix/chore 分支的 PR
```

**铁律**：禁止直推 develop/main。每个任务：Issue → 分支 → PR（`Closes #N`）→ Review → 合并。

**例外**：STATUS.md 允许直推 develop。

---

## Definition of Done（PR 合并前检查清单）

### 代码质量
- [ ] `swiftlint --strict` 0 violations
- [ ] `xcodebuild build-for-testing` 0 errors
- [ ] `xcodebuild test` 通过（已有测试不得回归）
- [ ] 改接口签名后 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- [ ] Codex 对抗性审查通过（每个 PR 必须）
- [ ] Xcode Review 核实通过（UI 改动必须）

### 功能完整性
- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步
- [ ] `docs/product/PRD.md` 已更新（当前版本范围、边界或承诺变化）
- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] 需要时已新增或更新 `docs/tech/design/*.md`（跨模块 / 持久化 / 状态流 / 合规变更）
- [ ] `api-reference.md` 已更新（新增/变更 public 接口）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 文档治理与重构仅作用于第一方文档；第三方开源文档保持原样
- [ ] 术语与 `product-glossary.md` 一致（新增或修改产品概念时）
- [ ] 合并后立即更新 `STATUS.md`

### Review
- [ ] Review 结论已留痕（PR comment 或 PR 描述）

---

## Code Review

**所有 PR 必须完成 review 后，由用户确认再合并。Review 结论必须留痕。**

1. **Xcode Review**：由 Codex 或其他审计工具生成提示词，用户在 Xcode 触发
2. **执行者核实**：每条 finding 必须读源文件确认真实性
3. **留痕**：Review 结论必须记录在 PR comment 或 PR 描述中

**纪律**：
- PR 未合并前禁止推进下一任务
- 禁止自审自批
- 范围外发现立即建 Issue
- PR 合并后立即更新 STATUS.md
- Review 无留痕的 PR 不得合并

---

## 决策变更收尾

产品决策变更时，同一回复中 Grep 影响范围 → 创建执行 Issue。Issue 未关闭 = 收尾未完成。

---

## 文档触发规则

### 什么时候更新 `docs/product/PRD.md`

- 当前版本范围变化
- 免费 / Pro 边界变化
- 核心价值链边界变化
- 当前产品承诺发生变化

### 什么时候必须新增或更新 `docs/tech/design/*.md`

满足以下任一条件：

- 跨 Package / Target 改动
- 涉及持久化、备份/恢复、迁移、Profile 隔离
- 涉及关键状态流、导航主路径或长生命周期任务
- 涉及合规、隐私、Tracking、遥测语义
- 涉及 S0 / S1 风险链路

### 什么时候必须写 ADR

- 产品或架构层出现多个可选方案，需要正式裁决
- 决策将影响多个文档或多个实现面

### 什么时候只更新映射/快照层文档

- 未改变产品承诺，只是更新实现映射
- 未改变设计语义，只是补充接口签名、状态记录、架构全景说明

---

## 工作优先级（S0-S3）

按「用户失去了什么」排序：

| 级别 | 含义 | 典型场景 |
|---|---|---|
| **S0** | 数据不可逆丢失 | 保存静默失败、备份损坏 |
| **S1** | 流程完全阻断 | 崩溃、功能不可用、OOM |
| **S2** | 能完成但有摩擦 | OCR 不准、搜索不准、卡顿 |
| **S3** | 更好但不紧急 | UI 打磨、测试补充、重构 |

**同级排序**（按模块重要性）：采集 > 管理 > 导出 > 复习 > 设置。
**执行**：S0 → S1 → S2 → S3，严格按序。

---

## 交叉审计（Cross-Audit）

详细的交叉审计组合、流程、工具链见 `agent/rules/collaboration.md`。

核心原则：**每个 Agent 独立审计完整集合，不是各审一半拼起来。** 多方全量冗余审计同一批文档/代码，交叉比对暴露盲区。

当前阶段执行口径（2026-04-13 起）：

- `Codex` 负责任务分解、验收标准与最终裁决。
- 同一批次采用单写入者模式，默认由 `Claude CLI` 落地修改。
- `Gemini CLI` 默认只读复审，不直接改同批文件。
- 外部工具调用启用“记忆隔离”：
  - Claude：`--bare --no-session-persistence`，禁用 `resume/continue`
  - Gemini：禁用 `--resume`，默认 `--approval-mode plan`
