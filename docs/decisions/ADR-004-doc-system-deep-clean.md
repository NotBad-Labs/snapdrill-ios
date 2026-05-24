---
last_verified: 2026-05-24
layer: decision
status: active
supersession_status: partially_superseded
superseded_by_partial: docs/meta/M-000-meta-vision.md
archived_implementation: docs/archive/audits/structural-cleanup-historical-record.md
---

> ⚠️ **M-000 v1.2 ratified 后部分内容已被新体系接管（user-decision-log #007 激进拆分；#008 撤回 R1 STATUS_ENUM 修改方向）**
>
> - 多方协作原则与工具选型由 M-000 §3/§7.2 + user-decision-log #002/#006 接管
> - 详细 Phase 0-9 实施与工具实测见 [structural-cleanup-historical-record.md](../archive/audits/structural-cleanup-historical-record.md)
> - 本文保留结构层方法论 + 防漂移机制 + 覆盖层级声明（执行层 SSOT）
> - `supersession_status: partially_superseded` 为侧通道字段，保留 `status: active` 以兼容下游消费 `status` 字段的脚本（user-decision-log #008）

# ADR-004: 文档体系深度清洁方法论 + 防漂移机制

> 状态：**部分被新体系接管** | 日期：2026-05-19 | 决策者：用户（PO）+ Claude Opus 4.7 + Codex GPT-5.5 second-opinion

## 背景

2026-05-19 用户提出「局部最优 ≠ 全局最优」的关切：之前的几轮修复都是点漂移修补（F-rule 4 处脱节、14 skill 8 finding），缺乏系统级卫生大扫除。

本会话从修 5 个 governance skill 起步，一路滚到 F 规则索引/定义脱节、14 skill 治理审计、52 文档审计接管、SSOT 自洽体检、三方 verdict 决议、跨文档结构性扫描、二意见对抗。

需要一个可复用的方法论 + 防漂移机制，避免 6 个月后又一样脏。

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A | 一次性大扫除，不留方法论 | 立刻干净 | 6 个月后再漂移，每次都是 from-scratch |
| B | 加 docaudit 6 个新 check 全部实现 | 防漂移最彻底 | 工程量大（每个 check 1-2 小时），ROI 递减 |
| **C** | **本会话 verify 全 52 文档 + 实现 2 个高 ROI check + 4 个 check 留设计稿 + ADR-004 记录方法论** | **平衡 ROI 与工程量；可逆决策（4 个 check 设计稿可后续实施）** | **设计稿可能被遗忘——靠本 ADR + handoff backlog 兜底** |

## 决策

**采取选项 C**。

### 方法论（可复用）

**5 Phase 主线流程**（Phase 0 + 1-4；本会话另含 Phase 5-9 全量补审与 skill 拆分作为延伸落地，未列入复用模板）：

1. **Phase 0 — 接管**：检查是否有前序审计产物（rubric / ledger / batches），不重做已有工作
2. **Phase 1 — SSOT 自洽**：先修 SSOT 自身 bug（编号 / 互相对账 / 文件清单 vs 实际 ls）。地基错了上面全错
3. **Phase 2 — verdict 决议**：多方对抗下 verdict，folding 用 `cross-audit-consensus` skill
4. **Phase 3 — 跨文档结构性扫描**：contradiction / orphan / ghost ref / 二意见对抗
5. **Phase 4 — 治理升级**：把发现的漂移模式机械化到 docaudit；新增 ADR 记录方法论

> **决策上下文注记（2026-05-19 时点）**：本案 Phase 2 引入 `cross-audit-consensus` skill 的工程动机，源于当时 Gemini 3 Pro Preview 在语义验证中的 over-endorse 漂移特征，需要通过加权共识机制做防御性对冲。该具体模型版本观察已归档至 [structural-cleanup-historical-record.md](../archive/audits/structural-cleanup-historical-record.md)；当前异源策略由 M-000 §7.2 + user-decision-log #006 接管，本 ADR 不再保留具体 LLM 介入点细则（user-decision-log #007 Q2=B2 裁决）。

### 何时再触发本方法论

- 触发条件 1：累计 ≥ 10 次本地修复未做全局 audit
- 触发条件 2：跨文档 contradiction 命中 ≥ 3 次（自动由 `verdict-sync` / `external-gap-expiry` check 提示）
- 触发条件 3：软上限触线（≥ 45 文件，由 `knowledge-health` skill Step 2a 提示）
- 触发条件 4：每年至少 1 次（freshness 季节性复审）

### 防漂移机制（已实施）

**docaudit 9 → 11 check**（已落 2 个 `verdict-sync` + `external-gap-expiry`；另 4 个设计稿留作 backlog，未实施）：

| Check | 状态 | ROI | 说明 |
|---|---|---|---|
| ✅ `verdict-sync` | 已实现 | P5（实测命中 STATUS/handoff drift） | 检测 verdict 分布跨文件漂移；行级关键词锚定防 FP |
| ✅ `external-gap-expiry` | 已实现 | P5（4 文件 VALID_WITH_GAP 缺机械触发） | 强制 VALID_WITH_GAP 文件 frontmatter 含 gap_type / gap_due / gap_owner |
| ⏳ `ssot-cross-check` | 设计稿 | P4 | 扫描所有「SSOT/权威源」声明能映射到唯一 authority key（防多文件自称 SSOT） |
| ⏳ `dep-map-reality` | 设计稿 | P4 | 检查 DOC_DEPENDENCY_MAP 声称的上下游至少一侧存在实际引用 |
| ⏳ `terminology-glossary` | 设计稿 | P4 | 从 product-glossary 维护 canonical terms + banned aliases 扫旧词漂移 |
| ⏳ `snapshot-freshness` | 设计稿 | P3 | 对 layer:snapshot 强制 freshness；pattern 文件含「当前/版本/账号/提交前」警告 |

**KNOWLEDGE_MAP 新增门槛**：
- 新增文档前必须列出 ≥ 1 个预期引用方
- 4 周无 incoming refs 转入 archive 候选
- 软上限触线（≥ 45）时必须一进一出

**skill 体系定位**：
- **skill 不是顶层概念，是执行器分类**。`docs/standards/` 定义「应该做什么」，`.claude/skills/` 是「怎么做」的执行包装
- 文档体系入口顺序：`AGENTS.md` → `docs/protocol.md` → `docs/KNOWLEDGE_MAP.md` → 按需进入 standards / product / tech / memory，skill 只在需要时被引用
- `skill-architecture` / `skill-source-ledger` 作为 docs/standards/ 子集存在

## 覆盖层级声明（关键边界）

本 ADR 主体收官的「文档体系深度清洁」仅覆盖**结构层**。Phase 10 语义层审计已另由 ADR-005 承接，历史 findings 见 [phase10-semantic-audit-snapshot.md](../archive/audits/phase10-semantic-audit-snapshot.md)。

| 层级 | 范围 | 本轮是否覆盖 |
|---|---|---|
| **结构层** | frontmatter 完整 / 链接存在 / 引用真实 / 计数一致 / 跨文件路径统一 / ledger 算术对账 / docaudit 11 check 全绿 | ✅ 已完成（Phase 0-9 + Codex Round 1-9 + Gemini 终审） |
| **语义层** | 跨文档语义链条 / 反向溯源 / 内部冲突扫描 / standards 实际约束力 / skill description↔body / F-rule 实际遵守度 | ✅ 已由 ADR-005 / Phase 10 承接 |

**为什么结构层不等于语义层**：
- 结构层判断「VALID」标准是「frontmatter 正确 + 引用存在 + 与项目状态一致」，是机械检查
- 语义层需要回答「vision 每条价值主张是否在 design 都有实现？requirements 中的功能能否反推回 vision 价值主张？tech 决策是否真服务采集>管理>导出？」——这是判断题，不是机械检查
- 因此结构层方法论必须保留独立 SSOT，不被语义层 findings 稀释

## 持续生效（防漂移）

- docaudit 11 check 持续监控（PostToolUse hook + pre-push hook 已绑定）
- KNOWLEDGE_MAP 新增门槛拦截无引用新文档
- `verdict-sync` 自动提示 STATUS/handoff/ledger 数字漂移
- `external-gap-expiry` 自动提示 VALID_WITH_GAP 文件到期

## 受影响文档

- `docs/KNOWLEDGE_MAP.md`（新增门槛 + 软上限规则）
- `Scripts/audit/docaudit.py` + `Scripts/audit/policy.yaml`（2 新 check）
- 4 个 VALID_WITH_GAP 文件（结构化 gap 字段）
- `STATUS.md` + `docs/memory/handoff.md`（Phase 4 完工状态）
- `docs/audits/audit-ledger-2026-05.tsv` + `docs/audits/README.md`（事实裁决 ledger 从 Claude 私有空间迁入 repo，作为外审可独立复核的 SSOT）

## 元数据

- 本 ADR 决策者：用户（PO）批准本方法论；Claude 起草 + 实施；Codex second-opinion 提供盲区候选 + check 推荐
- 详细 Phase 0-9 实施记录、旧工具选型立场与 commit 列表见 [structural-cleanup-historical-record.md](../archive/audits/structural-cleanup-historical-record.md)
- 本文当前职责：结构层方法论 + 防漂移机制 + 覆盖层级声明（执行层 SSOT）
