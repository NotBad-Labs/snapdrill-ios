# SnapDrill 协作流程

> 「怎么协作」——开发闭环、Git 工作流、Code Review、优先级。「怎么想」见 `principles.md`。

---

## 开发闭环：Personal Kanban + Shape Up 精华

### 看板四列

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Shaped   │  │ Building │  │ Reviewing│  │ Done     │
│ (待做)    │  │ (进行中)  │  │ (验证中)  │  │ (已完成)  │
│          │  │ WIP ≤ 2  │  │          │  │          │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

**无固定周期**。1 人 + 2 AI 不需要同步节奏——做完一个拉下一个。

### 一个任务的完整生命周期

| 步骤 | 谁做 | 做什么 | 完成标志 |
|---|---|---|---|
| **1. Shape** | 产品负责人 | 创建 Issue：问题 + appetite + 验收标准 + no-go | Issue 进入 Shaped 列 |
| **2. Pull** | 产品负责人 | 从 Shaped 拉入 Building（WIP ≤ 2） | 开始工作 |
| **3. Plan** | Claude Code | 方案设计 → 产品负责人确认 | 方案确认 |
| **4. Build** | Xcode Intelligence 执行 + Claude Code 复核 | 写代码 + 测试 | PR 创建 + lint + build-for-testing 通过 |
| **5. Review** | Gemini + Claude Code 核实 | 三方 review | Review 通过 |
| **6. Merge** | 产品负责人确认 | PR 合并 + Issue 关闭 + STATUS 更新 | Issue 进入 Done 列 |

**什么算"做完了"：Done 列里的 Issue 数 = 你想做的 Issue 数。**

### Issue 模板（Shape 阶段的 DoD）

```markdown
## 问题
[用户遇到了什么问题？]

## Appetite
- [ ] Small（1-2 天）
- [ ] Medium（3-5 天）
- [ ] Large（1-2 周）

## Scope（做什么）
-

## No-Go（明确不做什么）
-

## 验收标准
1.
```

### Scope 控制三层防线

1. **Appetite 预算**：Small=1-2 天 / Medium=3-5 天 / Large=1-2 周。超预算砍 scope，不加时间
2. **No-Go 清单**：Issue 模板明确列出不做什么
3. **发现即建 Issue**：Build 中范围外的新发现立即建新 Issue，不在当前 PR 处理

### 节奏

- **无固定周期**——不搞 sprint planning、不搞 retro 仪式
- **做完一批 Issue 后自然冷静**：整理文档、清理技术债、学习新 API
- **STATUS.md 只记录当前进行中的任务**，不记录完整历史

---

## 协作模式

| 角色 | 职责 | 优势 |
|---|---|---|
| **产品负责人** | Shape Issue、Pull 任务、最终验收 | 产品判断 |
| **Claude Code（主 agent）** | 规划方案、复核产出、统筹全局 | 1M 上下文、跨模块分析 |
| **Xcode Intelligence** | 代码执行、Apple 文档查询、编译测试 | Apple 生态 MCP |

**交流方式**：GitHub Issue comment（双方可见，产品负责人不需要复制粘贴）。

---

## 角色系统

每个角色是独立 Skill 文件（`.claude/skills/`），按需加载。回复开头标注 `[帽子：架构师]`。

**核心角色**（v1.0 阶段）：architect、developer、security-engineer、qa-engineer、ux-designer、user-advocate、devops、pr-review-workflow、update-status

**多方独立审计铁律**：安全/UX 审计必须引入多方（Claude + Antigravity + Xcode Intelligence），同一模型换帽子不算独立。

---

## 编写代码前

1. 研究声明（详见 `principles.md`）
2. 简要说明方案 + 影响模块 + 并发安全性确认

---

## Git 工作流

```
main ← App Store，只接受 develop 的 PR
develop ← TestFlight，只接受 feature/fix/chore 分支的 PR
```

**铁律**：禁止直推 develop/main。每个任务：Issue → 分支 → PR（`Closes #N`）→ Review → 合并。

**PR 合并前检查清单**：
- [ ] `xcodebuild build-for-testing` 零 error（含测试 target）
- [ ] `swiftlint --strict` 零 violations
- [ ] 新增 public API 有 DocC 注释
- [ ] 影响到的文档已同步
- [ ] 范围外发现已建 Issue（不在本 PR 处理）
- [ ] PR description 包含：变更摘要 + 测试计划

**例外**：STATUS.md 允许直推 develop（状态追踪文件，不需要 review）。

---

## Code Review

**所有 PR 必须完成三方 review 后，由用户确认再合并。**

1. **Gemini**（自动）：PR push 触发，Claude 主动轮询 `gh pr view --json comments,reviews`
2. **Antigravity / Xcode**（手动）：Claude 写提示词，用户触发
3. **Claude 核实**：每条 finding 读源文件确认真实性

**PR 纪律**：
- PR 创建后立即写 review 提示词（不写 = review 无法启动）
- PR 未合并前禁止推进下一任务
- 禁止自审自批——fix 后必须让原 reviewer 验收
- 范围外发现立即建 Issue（"后续处理"不建 Issue = 事实上遗忘）
- 轮询查 `comments` + `reviews` 两处
- PR 合并后立即更新 STATUS.md

---

## 决策变更收尾

产品决策变更（功能推迟/删除/行为变更）时，**同一回复中** Grep 影响范围 → 创建执行 Issue。
Issue 未关闭 = 收尾未完成。

---

## 工作优先级（S0-S3）

按「用户失去了什么」排序：

| 级别 | 含义 | 典型场景 |
|---|---|---|
| **S0** | 数据不可逆丢失 | 保存静默失败、备份损坏、恢复后图片丢失 |
| **S1** | 流程完全阻断 | 崩溃、功能不可用、OOM |
| **S2** | 能完成但有摩擦 | OCR 不准、搜索不准、卡顿 |
| **S3** | 更好但不紧急 | UI 打磨、测试补充、重构 |

**S0 vs S1 区分**：用户还能重试 = S1；数据已不可逆消失 = S0。

**同级排序**：采集 > 管理 > 导出 > 复习 > 设置（按用户频率）。
**执行**：S0 清零 → S1 → S2 → S3，严格按序。
