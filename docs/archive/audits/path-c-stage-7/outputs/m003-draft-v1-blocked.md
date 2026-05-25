---
last_verified: 2026-05-25
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
override_rationale: |
  文档总字数 2480 nwc，未超 M-005 §J 2500 上限，无需 override。
---

# M-003 技能库治理（v1 draft）

> **状态**：draft（Stage 7.3，待帅哥裁决 D1‑D5 并 Stage 7.4 sign‑off）
> **实证锚**：路径 C [#016](#016) ~ [#020](#020) 全过程，详见各节引用。
> **前置依赖**：M‑000 v2.0 §6（下沉优先级，skill 末位）、M‑005 §G.5（升降级双轨）为底层判据，M‑003 扩展为完整治理体系。

## §1 定位与接口

M‑003 定义 SnapDrill skill 生态的治理规范，是 M‑001~M‑006 体系中**第二个 ratify 的派生规则**（M‑005 第一，#016 排他性条款解除后顺序）。

- **上下承接**：吸收 M‑000 §6「skill 是下沉末位优选」原则（#020 修订实证）与 M‑005 §G.5 升降级双轨，补充新建、命名空间、CI 监控等 §G.5 未覆盖场景。
- **边界**：不进入 skill 提案审议流程（归 M‑002）、skill 触发日志 schema（归 `docs/standards/skill-telemetry.md`）、skill 文档格式（归 `docs/standards/skill-document-format.md`）。

## §2 skill vs 其他下沉去向的判定（回答 Q1）

**§2.1 判定流程（决策树）**

1. **内容是否“规则/约束/规范”且不需要 LLM 动态判断？** 是 → **`PROMOTE_TO_STANDARDS`**（→ `docs/standards/`）。
2. **是否为纯代码模板、配置片段，无需实时推理即用？** 是 → **`DOWNGRADE_TO_TEMPLATE`**（→ `docs/templates/`）。
3. **是否可被 hook/CI 机械检查或脚本自动化？** 是 → 下沉至 `.claude/hooks`、`.github/workflows` 或 `Scripts/`。
4. **trigger 条件是否依赖实时的上下文推理且无法替代？** 是 → 保留 skill 形态（进 §4 生命周期纳管）；若否 → 返回前 3 步。

**判据**（skill‑audit‑final §6.2.1）：trigger 依赖 LLM 实时推理 → skill；可被静态文档或脚本取代 → 下沉。

**§2.2 可验伪信号**

- 季度审计时若发现 skill 的 trigger 描述可机械化（如“当文件包含 `import SwiftUI` 时触发”），则自动标记候选降格。
- 若某 skill 连续 2 个季度无实际触发 → 强制进入降格评估（§G.5.2）。

**§2.3 反例 3 条（来自 #017/#019 裁决）**

- **保留 skill**：`dod-checklist` — 需 LLM 动态判断检查点完成状态并适配迭代节奏，无法静态化（#017 共识 KEEP）。
- **下沉 standards**：`coding-best-practices` — 纯规范，升 `docs/standards/swift-coding.md`（#017 PROMOTE）。
- **下沉 templates**：`cross-audit` — 审计工作流步骤可写成静态模板，无需 LLM 介入，降 `docs/templates/cross-audit-workflow.md`（#017 帅哥 DOWNGRADE）。

## §3 命名空间与目录布局（回答 Q2）

**§3.1 SSOT 与运行入口**

- **`.agents/skills/`** 为跨智能体的 portable skill **单一 SSOT**（#019 执行后清单、skill‑audit‑final §6.3）。
- **`.claude/skills/`** 存放 Claude 运行入口，采用 **symlink 或 manifest 引用** SSOT，禁止独立维护重复副本。
- 当前 11 个 active skill（#019 结果）分属：
  - 工具：`swiftui-pro`、`swift-concurrency-pro`、`swiftdata-pro`、`tdd-feature`、`xcode-review`、`screenshot-planner`、`app-description-writer`
  - 治理：`dod-checklist`、`phase-closeout`、`verify-audit-report`、`decision-closeout`（M‑002 接管后迁移）

**§3.2 治理/工具隔离**（D1 待裁决，见 §5）

- 选项 A：仅 frontmatter `category: governance|tool`
- 选项 B：物理子目录 `governance/` vs `tools/`
- 选项 C：A+B 同时
- 选项 D：不强制隔离
- 利弊：物理隔离阻止同源互审（#017 Claude 给治理 skill KEEP 被纠偏），但增加目录复杂度；frontmatter 标记灵活但无物理约束。M‑003 建议 **B 或 C**，最终由帅哥裁决。

## §4 生命周期（回答 Q3）

**§4.1 状态机**

```
创建提案 ──▶ active ──▶ 候选 (candidate) ──▶ 降格/归档
                ▲            │
                └──── 升级 ──┘
```

**入口/出口条件**（每步可机械检查）：

| 转换 | 条件 |
|---|---|
| 提案 → active | 通过 M‑002 审议流程 + 至少一次异源 sign‑off |
| active → 候选 | 连续 2 个季度无触发（§G.5.2）或季度审计 Verdict 为候选 |
| 候选 → 降格/归档 | 候选 ≥1 季度仍无触发 → 执行 DOWNGRADE/DELETE |
| 降格/归档 → 提案 | 需要重新走创建流程 |
| 升级（候选 → active） | 季度审计中触发频率达标且误报率 < 20%（引用 §G.2 阈值） |

**§4.2 触发频率监控最小实现**（D3 待裁决）

- 选项 A：Claude Code hook 写 `.claude/skill-audit.log`（需验证当前 hook 能力，#002 要求 WebSearch，此处留裁决）
- 选项 B：手动季度审计（owner 翻 git log + 会话记忆）
- 选项 C：A+B 组合
- 输出格式最低要求：`[timestamp] skill_name trigger_result`；采集机制推荐 hook 自动，但现阶段允许 B，纳入 §G.5.2 审计。

## §5 待裁决决策点（D1‑D5）

以下五个决策点主笔**仅列选项与利弊**，最终由帅哥在 Stage 7.3 review 时裁决。

**D1 命名空间隔离粒度**（选项 A‑D 见 §3.2）—— 物理隔离（B/C）能强制减少同源互审风险，但需同步调整 AGENTS.md/CLAUDE.md 路由；纯标记（A）灵活但无约束力。

**D2 SSOT 路径**  
- A：`.agents/skills/` SSOT，`.claude/skills/` symlink（当前 CLAUDE.md 描述方向）  
- B：`.claude/skills/` SSOT，`.agents/skills/` 出口  
- C：两侧均为 SSOT，按类型决定  
利弊：A 避免漂移（#019 发现双份存在），B 更符合 Claude 运行习惯；C 维护成本高。

**D3 触发日志采集机制**（见 §4.2）—— A 自动化但有 hook 支持风险；B 低成本但可能遗漏；C 平衡。

**D4 大规模 skill 重构触发阈值**  
- A：影响 ≥10 个 skill（§G.5.3 当前标准，引用 #019）  
- B：≥20% active skill（动态）  
- C：显式 user‑decision‑log 立项  
B 适应 skill 总量缩减后阈值下移，C 最灵活但可能延后；建议 B 作为自动信号，C 用于明确决策。

**D5 11 active skill 6 个月豁免处理**  
- A：维持豁免至 2026‑11‑25（M‑000 §6 当前条款）  
- B：M‑003 ratify 即解除，立即纳管  
- C：仅 KEEP 维持，REWRITE 立即纳管  
利弊：A 尊重历史裁决，B 尽早全面治理，C 折中。

## §6 升降级流程（§G.5 扩展）

**§6.1 引用与增量**  
直接引用 M‑005 §G.5.1（6 种 Verdict）、§G.5.2（季度审计）。M‑003 新增：

- **新建 skill 提案模板**（结构）：
  1. 动机（为何无法下沉至前 5 级）  
  2. trigger 条件（含示例）  
  3. 预期消费者与频率  
  4. 元规则对齐论证  
  模板存入 `docs/templates/skill-proposal.md`，审议流程归 M‑002。
- **大规模重构 baseline 流程**（参考 #019）：  
  - 受影响的 skill 清单 + 重建的 standards/templates 目标；  
  - `legacy_whitelist` 加豁免并设 `expires_on ≤ 30 天`；  
  - 执行后同步更新 `skill-architecture.md`、`skill-source-ledger.md`、`skills-lock.json`；  
  - 季度审计 owner 验证缓存过期。

**§6.2 触发频率统计与误报率**  
升级到 active 需满足 ≥3 次审计运行 + 30 天 + 误报率 < 20%（同 §G.2 阈值）。若 active skill 连续 2 次审计误报率 > 20%，启动降级评估。

## §7 与主笔体系的隔离要求（§G.5.4 执行化）

- **主笔起草元规则期间**（含 M‑003 起草本身），**禁止使用** `.claude/skills/` 下任何 governance 类 skill（#016 自举循环破解 + 本任务 §9 自反性约束）。
- **可用范围**：工具 skill（swiftui-pro / swiftdata-pro 等）及 standards/templates。
- **CI 集成**（可选）：若启用 hook，CI 可校验当前 session 调用的 skill 列表，标记 governance 调用并警告（需 D3 落地）。
- **主笔消费偏向折扣**：与 M‑005 §B.1 信号 5 双向引用；主笔自审自己消费过的治理 skill 时，KEEP/REWRITE 权重 ×0.5。

## §8 与下游 M‑001 / M‑002 / M‑004 的接口

- **M‑001**：skill 审计主笔提名规则继承 M‑005 §H 轮换原则（§G.5.5）；M‑003 定义 skill 审计的执行周期和判据，M‑001 负责具体提名流程。
- **M‑002**：skill 提案审议、分歧裁决归 M‑002；M‑003 仅提供“提议是否合规（下沉优先、判据）”的初始过滤。
- **M‑004**：可能承接 skill 触发日志的操作格式和 CI hook 配置，M‑003 不定义 schema。
- **不重复定义**：M‑005 §G.5 的 Verdict 定义、季度审计间隔、baseline 机制均为底层判据，M‑003 引用而非重写。

## §9 自反性标注

**起草过程使用工具清单**：直接 API 调用，无工具（zero‑context 任务）。本草案未调用任何 `.claude/skills/` governance skill，符合 §7 隔离要求；WebSearch 验证 D3 hook 可行性 @ 2026‑05‑25 未实际执行，留待决策点裁决后补充。

> **实证速查**：
> - Q1 判据与反例：skill‑audit‑final §6.2.1 + #017 裁决
> - Q2 命名空间与同源偏向：skill‑audit‑final §6.2.2 + #017 Claude KEEP 被全军覆没
> - Q3 生命周期与 52→11：skill‑audit‑final §6.2.3 + #019 批量执行
> - 下沉优先级降 skill 末位：M‑000 §6（#020 修订）
> - 6 种 Verdict + 季度审计：M‑005 §G.5（#020 新增）

*本草案由 DeepSeek V4‑Pro 基于路径 C #016~#020 全实证起草，待帅哥裁决 D1‑D5 后进入 Stage 7.4 sign‑off。*
