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

## Appetite
- [ ] Small（1-2 天）/ Medium（3-5 天）/ Large（1-2 周）

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
- [ ] 改接口签名后 `grep -rn "TypeName(" Tests/` 检查测试同步
- [ ] Xcode Review 核实通过（UI 改动必须）

### 功能完整性
- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步
- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] `api-reference.md` 已更新（新增/变更 public 接口）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 合并后立即更新 `STATUS.md`

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

**同级排序**：采集 > 管理 > 导出 > 复习 > 设置。
**执行**：S0 → S1 → S2 → S3，严格按序。

---

## 交叉审计（Cross-Audit）

文档审计、代码审查等质量验证任务采用**多 Agent 交叉审计**模式，降低单一视角的盲区。

### 流程

1. **Claude 和 Codex 同时独立审计同一批文档/代码**
2. **交叉比对**：按文档逐项比较两方发现，标注"共同发现"和"独有发现"
3. **代码验证**：所有事实性声明（API 存在性、类型名、方法签名）必须用 grep/read 验证
4. **外部专家**：遇到架构决策分歧时，写结构化提示词请用户咨询外部专家（其他 AI 模型或人类专家）

### 发现归类

| 严重度 | 标准 | 处理 |
|---|---|---|
| 严重 | 幽灵类型/API、事实性错误 | 必须修复 |
| 中等 | 过时描述、文档间不一致、缺失内容 | 应修复 |
| 轻微 | 措辞优化、格式统一 | 可修复 |

### 为什么有效

- Codex 和 Claude 使用不同模型，盲区不重叠
- Batch 2 实证：Claude 发现 8 个问题，Codex 独有 9 个，交叉审计多发现 53%
- 外部专家在架构决策上提供独立视角（如 DocC internal 类型策略）
