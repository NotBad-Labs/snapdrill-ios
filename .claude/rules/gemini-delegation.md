---
paths:
  - "CLAUDE.md"
  - "STATUS.md"
  - ".claude/rules/collaboration.md"
---

<!-- last verified: 2026-04-09 -->
# Gemini CLI 委派规范

Gemini CLI（google-gemini/gemini-cli v0.37.0）通过 Bash 非交互模式在 Claude Code 内调用，提供第三个独立模型家族（Google Gemini 3）的审计视角。
与 Codex 不同，Gemini 通过 `-p` 参数直接传递 prompt，不是插件体系。

## 调用方式

```bash
gemini -p "<prompt>" --sandbox 2>&1
```

- `--sandbox`：只读模式，禁止写文件（审计场景必加）
- 去掉 `--sandbox` 可执行代码修复（需谨慎）
- `-m gemini-2.5-flash`：切换为快速模型（默认 Gemini 3 Auto）

## 认证模式

| 模式 | 配额 | 适用场景 |
|---|---|---|
| Google 账号登录（推荐） | 1500 RPD 免费（Pro 订阅） | 日常审计 |
| API Key（`GEMINI_API_KEY`） | 按量计费，扣 Cloud 赠金 | 超额 fallback |

切换认证：在终端运行 `gemini`（交互模式）→ 选择登录方式。
当前配置存储在 `~/.gemini/settings.json`。

## 任务类型与模型选择

| 任务类型 | 模型 | 理由 |
|---|---|---|
| 代码审计/Review | Gemini 3 Auto（默认） | 强推理，长上下文 |
| 快速校验/格式检查 | gemini-2.5-flash（`-m gemini-2.5-flash`） | 快速响应，节省配额 |

### iOS 26 知识缺口

Gemini 训练数据不覆盖 iOS 26（自评"不知道"）。应对策略：
- prompt 中**必须内联**项目约束：`iOS 26+ / SwiftUI / SwiftData / Swift 6.3 / defaultIsolation(MainActor)`
- Gemini 能基于 prompt 约束正确推理，但不会主动发现 iOS 26 特有的 API 变更
- 对 iOS 26 新 API 的审计结论需要 Claude 或 Xcode 交叉验证

## 委派 prompt 结构

与 Codex 委派相同的原则：每次调用是无状态的，prompt 必须自包含。

### 1. 文件读取指令

Gemini CLI 在 `--sandbox` 模式下可以读取项目文件。在 prompt 中明确指定要读取的文件路径。

### 2. 关键约束摘要

构造委派 prompt 前，先读取 `.claude/rules/shared-constraints.md` 并将其全文内联到 prompt 中。
该文件是约束的唯一来源，此处不再硬编码，避免漂移。

### 3. 输出约束

- 语言：中文，技术术语保留英文
- 不加 emoji
- 明确要求输出格式

## 典型调用示例

### 代码审计

```bash
gemini -p "读取以下文件并审计代码质量：
- Packages/SnapDrillCore/Sources/SnapDrillCore/Service/DeletionScheduler.swift

审计标准：
1. 并发安全（MainActor 隔离、Task 生命周期）
2. 内存管理（循环引用、闭包捕获）
3. 错误处理（是否有 try? 吞错误）

项目约束：iOS 26+ / SwiftUI / SwiftData / defaultIsolation(MainActor)
输出：结构化报告，按严重度排序（Critical > Warning > Info）。中文回复。" --sandbox 2>&1
```

### 三方交叉审计（与 Claude + Codex 并行）

Claude、Codex、Gemini 各自独立审计同一批文件，然后由 Claude 汇总比对：
1. Claude 直接审计（主对话内）
2. Codex 通过插件委派审计
3. Gemini 通过 Bash 调用审计
4. Claude 汇总三份报告，分类：共同发现 / 各方独有发现

## 限制

- 非交互模式不支持多轮对话（每次调用独立）
- `--sandbox` 下无法执行 shell 命令（只能读文件）
- 长输出可能被截断，大型审计建议拆分文件批次
- 不继承 Claude Code 的项目上下文，prompt 必须自包含

## 反模式

- 不加 `--sandbox` 做审计 — 意外写入文件的风险
- prompt 不含项目约束 — Gemini 会给出脱离项目上下文的泛泛建议
- 单次 prompt 塞太多文件 — 超出 token 限制后输出质量下降
