---
last_verified: 2026-05-25
layer: pattern
audit_note: 2026-05-19 验证 — gemini-cli v0.41.2 与文件声明一致；gemini-3-pro-preview 已落地
derived_from: [M-001]
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, downstream_change]
---
# Gemini CLI 委派规范

> 本文件是 agent-agnostic 的委派规范。任何主线程委派 Gemini CLI 时遵循本规则。
> 历史来源为旧 `.claude/rules/gemini-delegation.md`（2026-04-17 PR #642 迁移）。当前权威源是本文档；`.claude/rules/` 不再作为现役指针层。

Gemini CLI（google-gemini/gemini-cli v0.41.2+）通过 Bash 非交互模式在主线程内调用，提供第三个独立模型家族（Google Gemini）的审计视角。
与 Codex 不同，Gemini 通过 `-p` 参数直接传递 prompt，不是插件体系。

## 调用方式

```bash
gemini -p "<prompt>" 2>&1
```

- 默认不加 `--sandbox`（性能更好，审计类 prompt 不会触发写入）
- `--sandbox`：只读模式，禁止写文件。仅在 prompt 可能触发代码修改时使用
- `-m gemini-3-pro-preview`：优先模型（强推理，长上下文）；`-m gemini-2.5-pro` 作为备选

### sandbox 性能影响（2026-04-09 实测）

sandbox 模式显著降低性能，复杂任务可能卡死：

| 场景 | 无 sandbox | 有 sandbox | 差异 |
|---|---|---|---|
| 6 文件简单总结 | 81 秒 | 167 秒 | 2.1x |
| 6 文件完整审计 | **119 秒** | **7 分+ 卡死** | >3.5x |

**规则**：审计/Review/研究等只读任务不加 `--sandbox`；仅在 prompt 要求 Gemini 修改文件时加 `--sandbox` 保护。

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
| 代码审计/Review | gemini-3-pro-preview（优先）| 强推理，长上下文 |
| 快速校验/格式检查 | gemini-2.5-pro（`-m gemini-2.5-pro`） | 备选，节省配额 |

### iOS 26 知识缺口

Gemini 训练数据不覆盖 iOS 26（自评"不知道"）。应对策略：
- prompt 中**必须内联**项目约束：`iOS 26.0+ / SwiftUI / SwiftData / Swift 6.3 / defaultIsolation(MainActor)`
- Gemini 能基于 prompt 约束正确推理，但不会主动发现 iOS 26 特有的 API 变更
- 对 iOS 26 新 API 的审计结论需要 Claude 或 Xcode 交叉验证

## 委派 prompt 结构

与 Codex 委派相同的原则：每次调用是无状态的，prompt 必须自包含。

### 1. 文件读取指令

Gemini CLI 在 `--sandbox` 模式下可以读取项目文件。在 prompt 中明确指定要读取的文件路径。

### 2. 关键约束摘要

构造委派 prompt 前，先读取 `docs/standards/shared-constraints.md` 并将其全文内联到 prompt 中。
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

项目约束：iOS 26.0+ / SwiftUI / SwiftData / defaultIsolation(MainActor)
输出：结构化报告，按严重度排序（Critical > Warning > Info）。中文回复。" 2>&1
```

### 三方交叉审计（与 Claude + Codex 并行）

Claude、Codex、Gemini 各自独立审计同一批文件，然后由主线程汇总比对：
1. 主线程直接审计（主对话内）
2. Codex 通过插件委派审计
3. Gemini 通过 Bash 调用审计
4. 主线程汇总三份报告，分类：共同发现 / 各方独有发现

## 限制

- 非交互模式不支持多轮对话（每次调用独立）
- `--sandbox` 下无法执行 shell 命令（只能读文件）
- 不继承主线程的项目上下文，prompt 必须自包含

### 大型审计超时防护

Gemini 在复杂审计（多文件 + 多条审计标准）时可能超时卡死。根因不是 sandbox，而是生成阶段超时。

**防护策略**：
1. **分批次**（推荐）：每批 2-3 个文件，每批独立 prompt，主线程汇总。避免单次 prompt 超过 5 个长文件
2. **超时包装**：Bash 调用外套 `& GEMINI_PID=$!; sleep 120; kill $GEMINI_PID 2>/dev/null` 或后台运行 + 定期检查
3. **降级处理**：Gemini 超时后由主线程接手整理，不阻塞审计进度

**实测基准（2026-04-09）**：
- 2 文件简单任务：~22 秒
- 6 文件简单任务：~170 秒
- 10 文件完整审计：~180 秒（Layer 0，正常完成）
- 6 文件完整审计 + 交叉对照：7 分+（Layer 1，卡死）

## 反模式

- 只读任务加 `--sandbox` — 白白损失一半以上性能，复杂任务可能卡死
- prompt 不含项目约束 — Gemini 会给出脱离项目上下文的泛泛建议
- 单次 prompt 塞太多文件 — 超出 token 限制后输出质量下降
- 复杂审计不设超时 — 进程卡死浪费时间且阻塞工作流

## 评分任务纪律（rubric 4 维场景）

Harness Stage A+B 实战发现 Gemini 在 `cross-audit-consensus` 4 维 rubric 评分上存在**整体偏高**问题（3/5 PR 打 10.0，比 Codex 高 1-4 分）。根因是 Gemini 对定性维度敏感但对 scope 漂移弱，倾向看"方向是否对"而非"与 plan 明文逐条是否吻合"。

**委派评分 prompt 必须强制**：

- **每维度引用 plan 锚点**：Scope Fidelity 引用 Issue Sprint Contract 的 Touches/No-Touch/Interface Delta；Architecture Fit 引用 `engineering.md` 具体原则条目；禁止"看起来不错"式打分
- **无 plan 可对照 → 降权或 N/A**：若某维度在当次审查中确实没有明文锚点（如纯研究归档无 plan），标 N/A 并说明，不折算为 10.0
- **10.0 分硬门槛**：仅在"plan 每一条都明文命中 + 无任何 scope 外增量 + 架构严格遵守"时给；默认从 8.0 起评，每个正向证据 +1，每个负向证据 -1
- **方差自检**：Gemini 评分若与 Codex 差 ≥ 2 分，需在报告里显式说明"为什么我比 Codex 高 X 分"——这个反思本身可能暴露锚点不足

**Consensus 裁决权重**：锚点层级与具体方差阈值以 `.claude/skills/cross-audit-consensus/SKILL.md` §2.5 "评分方权重" 表为 SSOT；本段简述：

- Gemini 遵守评分纪律 → **次锚点**（进入裁决但弱于主锚点 Codex）
- Gemini 不守纪律 → **参考**（与 Claude 自审同级，不进入裁决计算）
- **Codex 始终是主锚点**（对照 plan 明文逐条打分的严格度最高）

"次锚点" 不等于 "平权"——任何情况下 Codex 都保持主锚点地位，这是为避免共识时 Claude 用 Gemini 虚高分"刷过阈值"。

**来源**：Harness Engineering Stage A+B 复盘 + `feedback_gemini_adversarial.md` + PR #682 吃狗粮验证。
