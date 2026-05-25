---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# SnapDrill 文档体系语义层审计报告【维度 5：standards 约束力】

本报告是由 **Antigravity** 独立完成的 SnapDrill 文档体系语义层【维度 5：standards 约束力】单家审计报告。我们完整覆盖了 `docs/standards/` 目录下的全部 17 个规范文件，通过 `grep`、物理文件走读、模拟运行等实证方式，对规范中的每条规则是否被代码（Swift）、Shell 脚本、Git 工作流或 CI 门禁物理执行进行了逐一审计。

当前审计状态：**Snapshot 验证进行中**（保持持续跟踪与演进，未结案）。

---

## 1. 审计综述

经过全量 17 个文件的规则与物理实现比对，项目的规则执行度总体较高。例如 `coding.md` 对 `nonisolated(unsafe)` 与 `print()` 的硬性上限约束在 Packages 核心代码中被 100% 严格执行（经 grep 证实全仓仅有 4 处 `nonisolated(unsafe)`，而唯一命中的 `print` 仅作为 Mock 数据的题目文本存在）。

然而，审计依然发现了一些不容忽视的结构性漂移、死规则、影子规则以及审计命令失效问题。这表明“制定规则的人/工具与物理执行层”在以下几个节点上存在脱节。

---

## 2. Findings 结构化清单

以下为本次审计发掘的 6 个核心 Findings，涵盖严重度、漂移类型以及具体的实证证据。

### 🔴 Finding 1：受限 Bash 拦截器审计命令与物理实现严重脱节 (HIGH)
- **规则锚点**：[permission-model.md](../standards/permission-model.md#L33-L37) (§2 & §5)
- **实证状态**：未命中。
- **漂移类型**：审计命令漂移 / 规则与实现不一致
- **发现描述**：
  `permission-model.md` §2 声称 `.claude/hooks/block-dangerous-bash.sh` 是通过单条 `DANGEROUS_RE` 环境变量的 ERE 正则表达式拦截危险命令，并给出了审计命令 `grep '^DANGEROUS_RE=' .claude/hooks/block-dangerous-bash.sh`。
  但物理文件 [.claude/hooks/block-dangerous-bash.sh](../../.claude/hooks/block-dangerous-bash.sh#L29-L50) 中**根本不存在 `DANGEROUS_RE` 变量**，而是调用了一个复杂的**嵌入式 Python 脚本进行词法解析 token 化**，并做分支防护与 git 危险命令解析。这导致文档中的审计指令完全失效。
- **推荐处理**：修订 `permission-model.md`，删除过时的 `DANGEROUS_RE` 描述，更新为真实的 Python 词法分析解释，同步更新 §5 的审计命令。

### 🟡 Finding 2：治理类 Skill 授权矩阵与物理 SKILL.md 声明不一致 (MEDIUM)
- **规则锚点**：[permission-model.md](../standards/permission-model.md#L80-L106) (§4 治理类 Skill `allowed-tools` 矩阵)
- **实证状态**：部分命中。
- **漂移类型**：SSOT 漂移
- **发现描述**：
  在 `permission-model.md` §4 中定义的治理类 Skill 工具矩阵，与物理 `.claude/skills/` 下的 `SKILL.md` 存在两处偏差：
  1. `xcode-review`：在 SSOT 矩阵中写着被赋予了 `Read, Grep, Glob, Write, Bash` 权限，但物理 [.claude/skills/xcode-review/SKILL.md](../../.claude/skills/xcode-review/SKILL.md#L4-L7) 中仅注册了 `Bash, Read, Grep`。
  2. `api-research`：在 SSOT 矩阵中未勾选 `Grep` 权限，但物理 [api-research SKILL.md（已归档至路径 C #018）](../archive/skills/2026-05-25/api-research/SKILL.md) 中实际声明并注册了 `Grep` 权限。
- **推荐处理**：以 `permission-model.md` 为 SSOT 权威源，修订物理 `SKILL.md` 里的 `allowed-tools` 列表，实现双向自洽。

### 🟡 Finding 3：跨 Agent 共识 Skill 中遗留过时参数导致虚假合规 (MEDIUM)
- **规则锚点**：[cross-audit-consensus SKILL.md（已归档至路径 C #018）](../archive/skills/2026-05-25/cross-audit-consensus/SKILL.md) §2.5 / 行 81 与 [codex-delegation.md](../standards/codex-delegation.md#L14-L26) (§模型与参数选择)
- **实证状态**：未命中。
- **漂移类型**：SSOT 漂移 / audit_note 虚假合规
- **发现描述**：
  `codex-delegation.md` 中指出 Codex CLI 0.130.0+ 已经完全移除了 `--effort` 标志，并且在 `audit_note` 宣称“下游 cross-audit / cross-audit-consensus skill 已同步”。
  然而，物理 `.claude/skills/cross-audit-consensus/SKILL.md` 第 81 行的评分方权重中，依然保留了 `Codex（gpt-5.5 --effort high）` 的历史残余。这直接导致 `codex-delegation.md` 的 `audit_note` 自我声明成了“虚假合规” (False compliance)。
- **推荐处理**：修改 `.claude/skills/cross-audit-consensus/SKILL.md` 移除过时的 `--effort high` 参数描述，确保两处文档完全对齐。

### 🟡 Finding 4：执行门禁 SSOT 中遗漏两个强制性 CI 门禁 (MEDIUM)
- **规则锚点**：[execution-gates.md](../standards/execution-gates.md#L10-L17) (§1 CI 门禁)
- **实证状态**：未物理登记。
- **漂移类型**：影子规则
- **发现描述**：
  物理 🔴 [.github/workflows/ci.yml](../../.github/workflows/ci.yml) 中配置了两个核心且硬性阻断的步骤，但在 `execution-gates.md` 的单一真相源中**完全没有进行登记和原理解释**：
  1. `Validate docs frontmatter`：运行 `python3 Scripts/validate_frontmatter.py --check --strict` 全局校验文档元数据。
  2. `Check Package Dependencies`：全仓反向依赖流强阻断校验（Core/Data/UI/Features/Infrastructure/ShareExtension 依赖树流向）。这导致核心门禁游离在架构文档的视野之外。
- **推荐处理**：在 `execution-gates.md` §1 CI 门禁表格中补齐登记这两个重要门禁，并解释它们背后的设计意图。

### 🟢 Finding 5：视觉回归测试规范落后于现代 Swift Testing 迁移 (LOW)
- **规则锚点**：[testing.md](../standards/testing.md#L88) (§Snapshot 视觉回归 / 行 88)
- **实证状态**：部分命中.
- **漂移类型**：SSOT 漂移 / 规范更新滞后
- **发现描述**：
  `testing.md` 行 88 仍将 `SnapshotRegressionTests` 描述为 `nonisolated final class SnapshotRegressionTests: XCTestCase` 子类，并详尽讨论了其 nonisolated 标注与 `XCTestCase` 基类 init 冲突的处理。
  然而，物理代码中 `SnapshotRegressionTests.swift` 已经完全随 Issue #699 / PR #5 迁移至了 `@Suite + struct` (Swift Testing) 现代测试框架，struct 默认 nonisolated 故不再存在 XCTestCase init 冲突。这属于文档描述滞后于代码实现的漂移。
- **推荐处理**：修订 `testing.md`，更新 `SnapshotRegressionTests` 的描述为现代 Swift Testing 模式，移除对旧 `XCTestCase` 的特殊规避描述。

### 🟢 Finding 6：Harness Recall 机制在日常维护中退化为死规则 (LOW)
- **规则锚点**：[harness-recall.md](../standards/harness-recall.md#L12) (§一句话 & §Step 1)
- **实证状态**：未命中。
- **漂移类型**：死规则 / 元层级 self-non-compliance
- **发现描述**：
  `harness-recall.md` 提出了极佳的“自进化闭环机制”，要求每次 phase-closeout 或接手新会话时，主动扫描 `docs/memory/handoff.md` 的 `Risks` 章节来寻找重复发生的问题模式（出现 ≥3 次触发新规则提案）。
  然而，在实际更新 `docs/memory/handoff.md` 时，物理文件上**自始至终没有产出 `## Risks` 章节**。这使得该项自进化检测在输入源层面被完全切断，导致“制定规则的元层级本身在日常文档更新中没有遵守产出 Risks 的纪律”，Recall 机制沦为死规则。
- **推荐处理**：在 `handoff.md` 的标准模板中强制约束必须加入 `## Risks & Anti-patterns` 段以提供数据源，或者修订 `harness-recall.md` 以从 STATUS.md 等其他高频变动文件中提取 Risks 信息。

---

## 3. 维度 5 审计结论与演进建议

本次审计表明，SnapDrill 规范体系具有很强的工程控制力（如 swiftlint 和 docaudit 本身极其顺畅且高分运行），但在 **Agent 与 Agent 委派细节**、**新测试框架升级同步** 以及 **高频变动的 Handoff 自进化机制**上存在少许裂缝。

### 修正行动建议清单：
1. **实现补齐与双向同步**：
   - 依照 `permission-model.md` 的 SSOT 矩阵，修正物理 `xcode-review/SKILL.md` 和 `api-research/SKILL.md` 声明以消除工具层越权/少权行为。
   - 修正 `.claude/skills/cross-audit-consensus/SKILL.md` 抹除过时的 `--effort` 标志，使 `codex-delegation.md` 的 `audit_note` 重新达成“诚实合规”。
2. **规范修订**：
   - 在 `permission-model.md` 中将 `DANGEROUS_RE` 的说明重写，详细解释 Python `shlex` 词法解析及分支过滤的原理，并更正审计命令。
   - 在 `execution-gates.md` 中追认登记 `Validate docs frontmatter` 和 `Check Package Dependencies` 两个隐形成员。
   - 更新 `testing.md` 视觉回归段以反映 `@Suite + struct` 的现代化演进。
3. **流程机制校准**：
   - 校准 `handoff.md` 模板，恢复 `## Risks & Anti-patterns` 数据区，让 Harness Recall 能够重新“呼吸”并物理落地。
