---
paths:
  - "CLAUDE.md"
  - "STATUS.md"
---

<!-- last verified: 2026-04-09 -->
# 智能体协作架构

## 工具链总览

| 工具 | 引擎 | 入口 | 上下文 | 适合场景 |
|---|---|---|---|---|
| **终端 Claude Code** | Opus 4.6 | CLI / 桌面 App | 1M token | 主力开发、协调、规划、重构、审计 |
| **Claude 子 agent（Haiku）** | Haiku 4.5 | 终端内委派 | 200K token | 注释撰写、翻译、格式化、轻量生成 |
| **Claude 子 agent（Sonnet）** | Sonnet 4.6 | 终端内委派 | 1M token | 中等复杂度代码生成、重构建议 |
| **Codex 插件** | GPT-5.4 | 终端内 | 1.1M token | 对抗性 Review、独立审计、深度研究 |
| **Codex 桌面** | GPT-5.4 | 独立 App | 1.1M token | 大型独立任务 |
| **Xcode** | Claude + Codex | IDE | 200K token | UI Review、Apple 文档查询、SwiftUI Preview |
| **Antigravity** | Gemini + 其他 | IDE | — | 独立第三方视角、架构审计 |

## 日常开发（终端内闭环）

```
Claude Opus（主力）
  |-- Haiku 子 agent ── 注释、翻译、格式化（低成本高速）
  |-- Sonnet 子 agent ── 中等复杂度代码生成、重构
  |-- Codex 插件 ───── 对抗性 Review、独立验证
```

选择原则：
- **需要大上下文** → 终端 Claude Opus
- **需要看 UI 或查 Apple 文档** → Xcode
- **对抗性独立验证** → Codex（不同模型家族，盲区不重叠）
- **第三方独立视角** → Antigravity（Gemini，架构审计或重大变更）
- **轻量批量任务** → Haiku 子 agent（注释、翻译，节省成本和速度）

## 子 agent 委派原则

### Claude 子 agent（Haiku / Sonnet）

通过 Agent 工具的 `model` 参数委派：
- `model: "haiku"` — 注释撰写、文案翻译、格式化、简单代码生成
- `model: "sonnet"` — 中等复杂度代码生成、重构建议、文档起草

子 agent 共享项目文件访问权限，但不继承当前对话上下文。委派时需给足背景信息。

### Codex

通过 Codex 插件委派。详细规范见 `codex-delegation.md`。
核心：每次调用是全新会话，prompt 必须包含文件读取指令 + 关键约束摘要 + 输出约束。

### Antigravity

用户在 Antigravity IDE 中手动操作。Claude 提供结构化审计提示词，用户粘贴执行。
适合：需要完全独立的第三方视角（不同模型家族 + 不同工具链）。

## 交叉审计

文档审计、代码审查等质量验证任务采用**多 Agent 全量交叉审计**模式。

### 三方审计组合

```
Claude Opus ──独立审计──┐
Codex GPT-5.4 ──独立审计──|-- 交叉比对 -- 统一修复 -- 各方独立 Review
Antigravity Gemini ──独立审计──┘
```

### 核心原则

**每个 Agent 独立审计完整集合，不是各审一半拼起来。**冗余是刻意的：正因为都看同样的东西，才能通过"你发现了我没发现的"暴露盲区。

### 流程

1. **Claude、Codex、Antigravity 各自独立审计同一批全部文档/代码**（范围完全相同）
2. **代码验证**：所有事实性声明（API 存在性、类型名、方法签名）必须用 grep/read 验证
3. **交叉比对**：按文档逐项比较三份独立报告，分为"共同发现"、各 Agent 独有发现
4. **统一修复**：合并所有发现后一次性修复，避免来回返工
5. **修复 Review**：修复后由三方各自独立 Review 修复结果，再次交叉比对

### 为什么有效

- Claude、Codex、Antigravity 使用不同模型家族（Anthropic / OpenAI / Google），盲区不重叠
- 全量冗余审计保证不会因分工遗漏：任何问题至少被一方发现
- Codex 擅长深度代码-文档一致性验证（shell 命令级别）
- Antigravity 能直接读项目文件（IDE 级别），无 API token 截断限制

## Review 流程

| 阶段 | 执行者 | 触发条件 |
|---|---|---|
| 代码 Review | Codex 对抗性审查 | 每个 PR |
| UI Review | Xcode | UI 改动 |
| 架构/第三方视角 | Antigravity | 重大变更或审计任务 |
| 核实汇总 | Claude Opus | 汇总所有 finding，验证真实性 |

## 交流方式

- 终端 ↔ Xcode：GitHub Issue comment（两个入口都能读写）
- 终端 ↔ Antigravity：用户手动中转（结构化提示词）
- 终端 ↔ Codex：插件直接调用
