# SnapDrill 协作流程

> 「怎么协作」——Git 工作流、Code Review、优先级。「怎么想」见 `principles.md`。

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

**例外**：STATUS.md / session-log.md 允许直推 develop（状态追踪文件，不需要 review）。

---

## Code Review

**所有 PR 必须完成三方 review 后，由用户确认再合并。**

1. **Gemini**（自动）：PR push 触发，Claude 主动轮询 `gh pr view --json comments,reviews`
2. **Antigravity / Xcode**（手动）：Claude 写提示词（见 `review-prompt-guide.md`），用户触发
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
- `try?` 静默吞掉保存错误且用户已离开 → S0（不可逆）
- 保存失败但弹窗提示且状态保留可重试 → S1（可恢复）
- 编辑后保存失败且补的答案丢失 → S0（不可逆）
**同级排序**：采集 > 管理 > 导出 > 复习 > 设置（按用户频率）。
**执行**：S0 清零 → S1 → S2 → S3，严格按序。
