---
last_verified: 2026-05-19
layer: decision
---
# ADR-004: 文档体系深度清洁方法论 + 防漂移机制

> 状态：**已决策** | 日期：2026-05-19 | 决策者：用户（PO）+ Claude Opus 4.7 + Codex GPT-5.5 second-opinion

## 背景

2026-05-19 用户提出"局部最优 ≠ 全局最优"的关切：之前的几轮修复都是点漂移修补（F-rule 4 处脱节、14 skill 8 finding），缺乏系统级卫生大扫除。

本会话从修 5 个 governance skill 起步，一路滚到 F 规则索引/定义脱节、14 skill 治理审计、52 文档审计接管、SSOT 自洽体检、三方 verdict 决议、跨文档结构性扫描、二意见对抗。

总规模（2026-05-19 触发本 ADR 时的历史快照，非当前事实）：
- docs/ 57 .md / ~7,014 行
- .claude/ 52 .md（54 skill + adapter）
- 根 + .github/ ~10 .md
- **合计 ~119 markdown 文件**

> 当前快照（2026-05-20，Phase 0-9 收官后）：docs/ 61 .md / 7565 行；skill 52；规模随收官增长，KM/STATUS 是 SSOT，本处数字仅记录触发时刻基线。

需要一个可复用的方法论 + 防漂移机制，避免 6 个月后又一样脏。

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A | 一次性大扫除，不留方法论 | 立刻干净 | 6 个月后再漂移，每次都是 from-scratch |
| B | 加 docaudit 6 个新 check 全部实现 | 防漂移最彻底 | 工程量大（每个 check 1-2 小时），ROI 递减 |
| **C** | **本会话 verify 全 52 文档 + 实现 2 个高 ROI check + 4 个 check 留设计稿 + ADR-004 记录方法论** | **平衡 ROI 与工程量；可逆决策（4 个 check 设计稿可后续实施）** | **设计稿可能被遗忘——靠本 ADR + handoff backlog 兜底** |

## 研究摘要

### 三方对抗参与

- **Claude Opus 4.7**（主线程）：执行所有 Phase 工作
- **Codex GPT-5.5**：5/18 完成 52 文档 verdict 提案；5/19 second-opinion review 发现 1 处当前 bug（verdict artifact drift）+ 9 类未扫盲区候选 + 6 个 docaudit check 推荐
- **Gemini 3 Pro Preview**：5/19 完成 52 文档独立 verdict（5 batches），但 100% VALID 显示 over-endorse 模式，按 cross-audit-consensus 权重规则降为参考
- **DeepSeek V4 Pro**：5/19 尝试 second-opinion review，26 分钟无输出后 kill；与之前会话开头 tool_uses=36 提前收尾是同类问题

### 工具稳定性观察（非常重要的副产物）

| 工具 | 用途 | 本次稳定性 | 后续选型建议 |
|---|---|---|---|
| Claude Opus 4.7 (主线程) | 全程执行 | 稳定 | 主线程主力 |
| Codex GPT-5.5 | verdict + second-opinion | 稳定（5 batches + 1 review 全成功） | second-opinion 首选 |
| Gemini 3 Pro Preview | verdict | 稳定但 over-endorse | verdict 类对抗任务慎用；适合差异化任务（代码 review） |
| DeepSeek V4 Pro | second-opinion | **卡死 26 min** | 暂不再作为对抗 reviewer；适合定向小任务 |

### Phase 0-3 实施总结

| Phase | 时长 | Commit | 关键产出 |
|---|---|---|---|
| Phase 0 | 30 min | （报告） | 接管 52-doc 审计成果，三方提案汇总 |
| Phase 1 | 1.5 h | f40fcdcf | SSOT 自洽体检（KM §1 §4 跳号 + Dep Map §1 缺号 + 漏列文件补全 + 软上限触线机制）|
| Phase 2 | 3 h | bdb7cbc6 + fcb288a0 + 5d8b904e | 52 文档 verdict 终态 47/4/1/0 |
| Phase 3 | 1 h | 18d59a7f + fdcbf92b | 跨文档 contradiction / orphan / ghost ref（1 修复）+ Codex 二意见 |
| Phase 4 | 1.5 h | （本 commit） | docaudit 2 个新 check 实现 + 4 文件结构化 gap 字段 + KM 治理规则 + ADR-004 |

## 决策

**采取选项 C**。

### 方法论（可复用）

**5 Phase 主线流程**（Phase 0 + 1-4；本会话另含 Phase 5-9 全量补审与 skill 拆分作为延伸落地，未列入复用模板）：

1. **Phase 0 — 接管**：检查是否有前序审计产物（rubric / ledger / batches），不重做已有工作
2. **Phase 1 — SSOT 自洽**：先修 SSOT 自身 bug（编号 / 互相对账 / 文件清单 vs 实际 ls）。地基错了上面全错
3. **Phase 2 — verdict 决议**：三方对抗（Claude + Codex + Gemini）下 verdict，folding 用 `cross-audit-consensus` skill。Gemini 若出现 over-endorse 降权重
4. **Phase 3 — 跨文档结构性扫描**：contradiction / orphan / ghost ref / 二意见对抗
5. **Phase 4 — 治理升级**：把发现的漂移模式机械化到 docaudit；新增 ADR 记录方法论

**对抗性 LLM 介入点**：
- Phase 0/1：Claude 单家（机械任务）
- Phase 2 verdict：三方对抗（判断题环节）
- Phase 3：Claude + 二意见（首选 Codex；DeepSeek 已被实测不稳定）
- Phase 4：Claude + 用户裁决

**何时再触发本方法论**：
- 触发条件 1：累计 ≥ 10 次本地修复未做全局 audit
- 触发条件 2：跨文档 contradiction 命中 ≥ 3 次（自动由 `verdict-sync` / `external-gap-expiry` check 提示）
- 触发条件 3：软上限触线（≥ 45 文件，由 `knowledge-health` skill Step 2a 提示）
- 触发条件 4：每年至少 1 次（freshness 季节性复审）

### 防漂移机制（已实施）

**docaudit 9 → 11 check**（本 commit 落 2 个 `verdict-sync` + `external-gap-expiry`；另 4 个设计稿留作 backlog，未实施）：

| Check | 状态 | ROI | 说明 |
|---|---|---|---|
| ✅ `verdict-sync` | 已实现 | P5（实测命中 STATUS/handoff drift） | 检测 verdict 分布跨文件漂移；行级关键词锚定防 FP |
| ✅ `external-gap-expiry` | 已实现 | P5（4 文件 VALID_WITH_GAP 缺机械触发） | 强制 VALID_WITH_GAP 文件 frontmatter 含 gap_type / gap_due / gap_owner |
| ⏳ `ssot-cross-check` | 设计稿 | P4 | 扫描所有"SSOT/权威源"声明能映射到唯一 authority key（防多文件自称 SSOT） |
| ⏳ `dep-map-reality` | 设计稿 | P4 | 检查 DOC_DEPENDENCY_MAP 声称的上下游至少一侧存在实际引用 |
| ⏳ `terminology-glossary` | 设计稿 | P4 | 从 product-glossary 维护 canonical terms + banned aliases 扫旧词漂移 |
| ⏳ `snapshot-freshness` | 设计稿 | P3 | 对 layer:snapshot 强制 freshness；pattern 文件含 "当前/版本/账号/提交前" 警告 |

**KNOWLEDGE_MAP 新增门槛**：
- 新增文档前必须列出 ≥ 1 个预期引用方
- 4 周无 incoming refs 转入 archive 候选
- 软上限触线（≥ 45）时必须一进一出

**skill 体系定位**（per plan + 用户决策）：
- **skill 不是顶层概念，是执行器分类**。`docs/standards/` 定义"应该做什么"，`.claude/skills/` 是"怎么做"的执行包装
- 文档体系入口顺序：`AGENTS.md` → `docs/workflow.md` → `docs/KNOWLEDGE_MAP.md` → 按需进入 standards / product / tech / memory，skill 只在需要时被引用
- `skill-architecture` / `skill-source-ledger` 作为 docs/standards/ 子集存在（Phase 1.2 已落地，KM 模式层已列）

### 工具选型决策

- **DeepSeek**：暂停作为对抗 reviewer（稳定性问题）；适合定向小任务（如代码片段 review）
- **Gemini**：verdict 类对抗任务慎用（over-endorse 模式）；适合代码 review / 差异化视角任务；按 cross-audit-consensus 评分权重段处理
- **Codex**：second-opinion 首选；本次实测最稳定

## 后果

### 已落地（本会话 commits）

- `f40fcdcf` Phase 1 SSOT 自洽
- `bdb7cbc6` Phase 2.1-2.5 partial（verdict + 批量刷 + 归档 A019）
- `fcb288a0` Phase 2.4 A+B 13 文档闭环
- `5d8b904e` Phase 2.4 C 5 文档闭环
- `18d59a7f` Phase 3.3 ghost ref 修
- `fdcbf92b` Phase 3.4 Codex 二意见 + verdict drift 修
- 本 commit：Phase 4 全部（docaudit 2 新 check + 4 文件 gap 字段 + KM 治理 + ADR-004）

### 持续生效（防漂移）

- docaudit 9 → **11 check** 持续监控（PostToolUse hook + pre-push hook 已绑定）；另 4 个设计稿 check 留作 backlog
- KNOWLEDGE_MAP 新增门槛拦截无引用新文档
- `verdict-sync` 自动提示 STATUS/handoff/ledger 数字漂移
- `external-gap-expiry` 自动提示 VALID_WITH_GAP 文件到期

### 待后续 phase 实施（backlog）

- ssot-cross-check / dep-map-reality / terminology-glossary / snapshot-freshness 4 个 check 实现（每个 1-2 小时）
- VALID_WITH_GAP 文件 gap_due 到期时复审流程（apple-limits gap_due = wwdc_2026 / product-business gap_due = app_store_submission 等）
- skill 体系最终定位：本 ADR 已声明"降位为 docs/standards 子集"是工作假设；实施中无摩擦 → 转为正式定位；后续 phase 若发现摩擦可回滚到"保持并列"

### 受影响文档

- `docs/KNOWLEDGE_MAP.md`（新增门槛 + 软上限规则）
- `Scripts/audit/docaudit.py` + `Scripts/audit/policy.yaml`（2 新 check）
- 4 个 VALID_WITH_GAP 文件（结构化 gap 字段）
- `STATUS.md` + `docs/memory/handoff.md`（Phase 4 完工状态）

### 元数据

- 本 ADR 决策者：用户（PO）批准本方法论；Claude 起草 + 实施；Codex second-opinion 提供 9 类盲区候选 + 6 个 check 推荐
- 本次大扫除累计 commit 数：7（97e266b4 + ed8cbd1e + f40fcdcf + bdb7cbc6 + fcb288a0 + 5d8b904e + 18d59a7f + fdcbf92b + 本 commit）
- 本次大扫除累计文件触动：~30 个（22 个 docs/ + 8 个 .claude/skills/ + Scripts/audit/）
- 累计审计 LLM 调用：~7 次（Gemini 5 batch + Codex 5 batch + Codex second-opinion + DeepSeek 卡死 1 次）
- 实际耗时：本会话 ~5 小时（plan 预估 6-11 小时，超出 unders shoot 因为 Codex 已有 5/18 产物可接管）
