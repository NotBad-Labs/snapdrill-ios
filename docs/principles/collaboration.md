<!-- last_verified: 2026-04-16 -->
<!-- layer: pattern -->
# 智能体协作架构

## 工具链总览

| 工具 | 引擎 | 入口 | 上下文 | 适合场景 |
|---|---|---|---|---|
| **终端 Claude Code** | Opus 4.7 | CLI / 桌面 App | 1M token | 主力开发、协调、规划、重构、审计 |
| **Claude 子 agent（Haiku）** | Haiku 4.5 | 终端内委派 | 200K token | 注释撰写、翻译、格式化、轻量生成 |
| **Claude 子 agent（Sonnet）** | Sonnet 4.6 | 终端内委派 | 1M token | 中等复杂度代码生成、重构建议 |
| **Codex 插件** | GPT-5.4 系列 | 终端内 | 1.1M token | 对抗性 Review、独立审计、深度研究 |
| **Codex 桌面** | GPT-5.4 系列 | 独立 App | 1.1M token | 大型独立任务 |
| **Xcode** | Claude + Codex | IDE | 200K token | UI Review、Apple 文档查询、SwiftUI Preview |
| **Gemini CLI** | Gemini 3 (Auto) | 终端内 Bash | 1M+ token | 第三方独立审计、交叉验证 |
| **Antigravity** | Gemini + 其他 | IDE | -- | 独立第三方视角（手动中转，Gemini CLI 的备选） |

## 日常开发（终端内闭环）

```
Claude Opus（主力）
  |-- Haiku 子 agent -- 注释、翻译、格式化（低成本高速）
  |-- Sonnet 子 agent -- 中等复杂度代码生成、重构
  |-- Codex 插件 ----- 对抗性 Review、独立验证（OpenAI 家族）
  |-- Gemini CLI ------ 第三方审计、交叉验证（Google 家族）
```

选择原则：
- **需要大上下文** → 终端 Claude Opus
- **需要看 UI 或查 Apple 文档** → Xcode
- **对抗性独立验证** → Codex（OpenAI 家族，盲区不重叠）
- **第三方独立视角** → Gemini CLI（Google 家族，终端内自动化）
- **轻量批量任务** → Haiku 子 agent（注释、翻译，节省成本和速度）
- **Gemini CLI 不可用时** → Antigravity IDE（手动中转，作为 fallback）

## 交叉审计

文档审计、代码审查等质量验证任务采用**多 Agent 全量交叉审计**模式。

### 三方审计组合（终端内全自动化）

```
Claude Opus --独立审计（主对话内）--+
Codex GPT-5.4 --独立审计（插件委派）--+-- Claude 汇总比对 -- 统一修复 -- 各方独立 Review
Gemini 3 --独立审计（Bash 调用）--+
```

三个模型家族（Anthropic / OpenAI / Google）全部在终端内闭环，零手动中转。

### 核心原则

**每个 Agent 独立审计完整集合，不是各审一半拼起来。**冗余是刻意的：正因为都看同样的东西，才能通过"你发现了我没发现的"暴露盲区。

### 流程

1. **并行委派**：Claude 在主对话内审计的同时，并行委派 Codex（Agent 工具）和 Gemini（Bash 调用 `gemini -p`），三方审计同一批完整文件
2. **代码验证**：所有事实性声明（API 存在性、类型名、方法签名）必须用 grep/read 验证
3. **汇总比对**：Claude 汇总三份报告，生成比对表格：共同发现 / 各方独有发现
4. **统一修复**：合并所有发现后一次性修复，避免来回返工
5. **修复 Review**：修复后由三方各自独立 Review 修复结果
6. **回灌到约束体系**：每次 cross-audit 发现的问题，修复后评估根因并更新对应文档：
   - 约束缺失 → 更新 `docs/principles/*.md` 或新增 `feedback.md` 规则
   - 检查遗漏 → 更新 `docs/workflow.md` DoD 或 `.github/workflows/ci.yml`
   - 反复出现（同类问题 3 次以上）→ 提升为自动化门禁（lint rule / CI step）
   - 闭环验证：下一次同类任务中确认改进生效

### 汇总表格模板

```markdown
| 发现 | Claude | Codex | Gemini | 共识 |
|---|---|---|---|---|
| [发现描述] | [严重度] | [严重度] | [严重度] | N/3 |
```

## AI 特有反模式检查

Cross-audit 和 PR Review 时，除通用代码质量外，必须额外检查以下 AI 特有的缺陷模式。每项检查必须提供具体证据（grep/read/diff 结果），不得仅凭印象判断。

| 反模式 | 检查方法 | 证据要求 |
|---|---|---|
| **Over-generation** — 添加未被要求的功能/代码 | 对照 Issue scope，diff 中是否有 scope 外的新增 | 列出 scope 外的具体文件/函数 |
| **Assumption-filling** — 需求空白处做隐含假设 | 检查是否有未在 Issue 中定义的业务逻辑 | 指出假设内容及其在代码中的位置 |
| **Brute-force fix** — 用 workaround 替代 root cause fix | 是否有 @ObservationIgnored / try? 等绕行 | grep 结果 + 根因分析 |
| **Scope creep** — 小修改扩成大重写 | diff 行数是否远超预期，是否改了不相关文件 | 统计新增/删除行数对比 |
| **Pattern divergence** — 新代码模式与项目既有模式不一致 | 对比同类文件的实现方式 | 贴出新旧模式对比 |
| **Hallucinated API** — 使用不存在的 API/方法 | grep 验证每个新引入的外部调用确实存在 | grep 结果 |
| **Test evasion** — 通过删除/跳过/绕过测试让 CI 变绿 | 检查 diff 中是否有 skipped/disabled/deleted 测试 | diff 截取 |

来源：Fowler AI Autonomy 实验（2026）、Python Dev Guide AI 准则、Architecture drift 研究、AI bug 分类学（3864 bugs 论文）。

## Review 流程

| 阶段 | 执行者 | 触发条件 |
|---|---|---|
| 代码 Review | Codex 对抗性审查 | 每个 PR |
| UI Review | Xcode | UI 改动 |
| 第三方审计 | Gemini CLI（终端内） | 每次交叉审计 |
| 架构/第三方视角 | Antigravity（fallback） | Gemini CLI 不可用时 |
| 核实汇总 | Claude Opus | 汇总所有 finding，验证真实性 |

## Agent 冲突裁决

当三方审计结论矛盾时，使用标准化模板记录裁决过程：

| 维度 | 内容 |
|---|---|
| 冲突描述 | [一句话描述分歧点] |
| Claude 主张 | [观点 + 证据] |
| Codex 主张 | [观点 + 证据] |
| Gemini 主张 | [观点 + 证据] |
| 裁决 | [采纳哪方] |
| 理由 | [为什么采纳，排除方案的具体缺陷] |

证据等级（高到低）：编译/测试/日志结果 > 官方文档引用 > 代码分析推断 > 经验性判断。

裁决权归人类。无人类在场时，以高等级可验证证据为准，不以"多数投票"为准。冲突未解决时默认阻塞合并，升级至人类裁决。

## 交流方式

- 终端 <-> Xcode：GitHub Issue comment（两个入口都能读写）
- 终端 <-> Codex：插件直接调用
- 终端 <-> Gemini CLI：Bash 直接调用（`gemini -p`）
- 终端 <-> Antigravity：用户手动中转（仅 fallback）
