# SnapDrill 协作流程

> 开发闭环、Git 工作流、Code Review、优先级。工程哲学见 `../.claude/rules/engineering.md`，协作模式见 `../CLAUDE.md`。

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
- [ ] 改接口签名后 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- [ ] Xcode Review 核实通过（UI 改动必须）

### 功能完整性
- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步
- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] `api-reference.md` 已更新（新增/变更 public 接口）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 术语与 `product-glossary.md` 一致（新增或修改产品概念时）
- [ ] 合并后立即更新 `STATUS.md`

### Review
- [ ] Review 结论已留痕（PR comment 或 PR 描述）

---

## Code Review

**所有 PR 必须完成 review 后，由用户确认再合并。Review 结论必须留痕。**

1. **Xcode Review**：Claude Code 写提示词，用户在 Xcode 触发
2. **Claude Code 核实**：每条 finding 读源文件确认真实性
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

文档审计、代码审查等质量验证任务采用**多 Agent 全量交叉审计**模式，降低单一视角的盲区。

### 核心原则

**每个 Agent 独立审计完整集合，不是各审一半拼起来。**

三方的工作范围必须完全相同——都是全量审计同一批文档/代码，各自产出独立报告，然后交叉比对。冗余是刻意的：正是因为三方独立看同样的东西，才能通过"你发现了我没发现的"暴露盲区。

### 三方审计组合

| Agent | 引擎 | 优势 |
|---|---|---|
| Claude | Opus 4.6（Anthropic） | 大上下文全局分析、代码实现 |
| Codex | GPT-5.4（OpenAI） | 深度代码-文档一致性验证（shell 命令级别） |
| Antigravity | Gemini（Google） | IDE 级项目访问、独立第三方视角 |

### 流程

1. **Claude、Codex、Antigravity 各自独立审计同一批全部文档/代码**（范围完全相同）
2. **代码验证**：所有事实性声明（API 存在性、类型名、方法签名）必须用 grep/read 验证
3. **交叉比对**：按文档逐项比较三份独立报告，分为"共同发现"、各 Agent 独有发现
4. **统一修复**：合并所有发现后一次性修复，避免来回返工
5. **修复 Review**：修复后由三方各自独立 Review 修复结果，再次交叉比对

### 发现归类

| 严重度 | 标准 | 处理 |
|---|---|---|
| 严重 | 幽灵类型/API、事实性错误、与代码直接冲突 | 必须修复 |
| 中等 | 过时描述、文档间不一致、缺失内容 | 应修复 |
| 轻微 | 措辞优化、格式统一 | 可修复 |

### 为什么有效

- Claude、Codex、Antigravity 使用不同模型家族（Anthropic / OpenAI / Google），盲区不重叠
- 全量冗余审计保证不会因分工遗漏：任何问题至少被一方发现
- Codex 擅长深度代码-文档一致性验证（shell 命令级别）
- Antigravity 能直接读项目文件（IDE 级别），无 API token 截断限制
