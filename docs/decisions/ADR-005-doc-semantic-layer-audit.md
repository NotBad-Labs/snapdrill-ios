---
last_verified: 2026-05-20
layer: decision
---
# ADR-005: 文档体系语义层审计方法论（Phase 10 立项）

> 状态：**提议** | 日期：2026-05-20 | 决策者：用户（PO）+ Claude Opus 4.7 主导 + Codex GPT-5.5 + Antigravity(Gemini 3.5) 三方对抗

## 背景

[[ADR-004]] 在 2026-05-19/20 完成了文档体系**结构层**收官（共识基线 commit `4883d6b6`，Gemini 3 Pro Preview 全周期 FULL PASS），并在 backlog 段显式声明：

- 结构层 ≠ 语义层；本轮覆盖的是 frontmatter / 链接 / 计数 / 算术 / docaudit 11 check 等机械可校验维度
- 语义层（跨文档链条、反向溯源、内部冲突、standards 实际约束力、skill description↔body、F-rule 实际遵守度）作为 **Phase 10** 独立立项，预计新建 ADR-005

本 ADR 即兑现该承诺。

**新变量（2026-05-20）**：Google 发布 Gemini 3.5 Flash（Antigravity 桌面端可调用），ChatGPT 桌面端 Codex 模式同期可用作 GUI 二审通道。这改变了 ADR-004 第 186 行原定的「Gemini 不参与判断」工作假设——见下方「研究摘要」。

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A | Claude 单家审 7 维度，不动 Codex/Gemini | 成本最低 | 单家盲区无对抗校验，回到 Phase 0 前的状态 |
| B | Claude 主导 + Codex 二意见，Gemini 不参与（ADR-004 原定） | 规避 Gemini over-endorse 已知病灶 | Gemini 3.5 是否仍存在该偏误未验证；放弃一个 GUI 通道 |
| **C** | **三方对抗 7 维度：Claude（CLI）+ Codex（桌面端）+ Antigravity(Gemini 3.5)** | **完整对抗覆盖；3.5 新模型可借机验证 over-endorse 是否消除** | **成本最高；若 3.5 仍 over-endorse 需 fallback 到 B（cross-audit-consensus 降权重）** |

## 研究摘要

### 工具配置变更依据

- ADR-004 line 186 设「Gemini 不参与判断」基于 2026-05-19/20 Gemini 3 Pro Preview 实测：52 文档 verdict 100% VALID（over-endorse），按 [[cross-audit-consensus]] 降权重处理
- 2026-05-20 Gemini 3.5 发布 + Antigravity 桌面端 GA。新模型尚未在本项目验证；用户决定以 Phase 10 作为首批实测场景
- 若 7 维度跑完后 Gemini 3.5 verdict 与 Claude/Codex 显著背离（仍是高 VALID 率），按 [[cross-audit-consensus]] 评分权重段降权重，但保留输出作为参考视角

### 三方角色分工（沿用 F-008「相同完整任务、不分工」纪律）

- **三家独立审完整 7 维度**，不切片分工
- folding 用 [[cross-audit-consensus]] skill 输出共识 / 单家独有 / 冲突三类
- Claude（CLI）主笔最终 verdict + ADR-005 收官段；Codex 桌面端 + Antigravity 各产一份独立报告附录到 audit-ledger

### 模型版本注（2026-05-20 基线，易变事实，复审触发：见下方 gap_due）

> ⚠️ 本节描述的具体模型版本会随上游迭代变化，**不锚定为永久事实**。沿用 ADR-004 §防漂移机制的 `gap_due` 模式标外部条件到期触发复审。

| 项 | 当前基线 (2026-05-20) | 备注 |
|---|---|---|
| **Antigravity 版本** | Antigravity 2.0 (Google I/O 2026 发布) | standalone desktop app |
| **当前选用模型** | **Gemini 3.5 Flash (High reasoning)** | Antigravity 模型下拉菜单实际选项 |
| **Antigravity 可选模型清单** | Gemini 3.5 Flash (High/Medium) / Gemini 3.1 Pro (High/Low) / Claude Sonnet 4.6 (Thinking) / Claude Opus 4.6 (Thinking) / GPT-OSS 120B (Medium) | 截至本文撰写日截图实测 |
| **Codex 桌面端** | ChatGPT 桌面端 Codex 模式（GPT-5.5） | — |
| **Claude CLI** | Claude Opus 4.7 (1M context) | — |
| **gap_due (复审触发)** | `gemini_3_5_pro_release` (预计 2026-06) | Gemini 3.5 Pro 发布后维度 4-7 启动时复审本表 + over-endorse 监控基线 |

**记号约定**：本文档及下游审计报告 `Antigravity (Gemini 3.5 Flash (High))` 简称该完整组合；正文叙事性提及「Gemini 3.5」时指模型家族而非特定版本。

## 决策

**选项 C**：Phase 10 文档体系语义层审计采用 Claude + Codex 桌面端 + Antigravity(Gemini 3.5) 三方对抗模式，7 维度全量覆盖。

**supersedes**：[ADR-004 backlog 段 line 186](ADR-004-doc-system-deep-clean.md#待后续-phase-实施backlog) 原工具配置「Gemini 不参与判断」局部失效；其余 ADR-004 内容仍生效。

### 7 个语义维度（实施清单）

| # | 维度 | 判据 | 预估 |
|---|---|---|---|
| 1 | 跨文档语义链条 | ✅ 已完成（2026-05-20 三方对抗：Claude CLI / Codex 桌面端 / Antigravity；共识报告 [semantic-audit-dim1-consensus.md](../audits/semantic-audit-dim1-consensus.md) + Antigravity 单家 [semantic-audit-dim1-findings.md](../audits/semantic-audit-dim1-findings.md) + ledger [audit-ledger-semantic-2026-05.tsv](../audits/audit-ledger-semantic-2026-05.tsv)；22 OPEN finding（HIGH×3 MEDIUM×6 LOW×12 INFO×1）+ 2 REJECTED/WAIVED） | 实际 ≈ 90 min（三方对抗） |
| 2 | 反向溯源 | ✅ 已完成（2026-05-20 三方对抗：Claude CLI / Codex 桌面端 / Antigravity；共识报告 [semantic-audit-dim2-consensus.md](../audits/semantic-audit-dim2-consensus.md) + Antigravity 单家 [semantic-audit-dim2-findings.md](../audits/semantic-audit-dim2-findings.md) + ledger 追加；11 OPEN finding（HIGH×1 MEDIUM×2 LOW×6 INFO×2）+ 3 REJECTED；Claude 自驳 3 项含分享卡片 REJECTED 升为 MEDIUM 共识） | 实际 ≈ 60 min（三方对抗）|
| 3 | 内部冲突扫描 | ✅ 已完成（2026-05-20 三方对抗：Claude CLI / Codex 桌面端 / Antigravity；共识报告 [semantic-audit-dim3-consensus.md](../audits/semantic-audit-dim3-consensus.md) + Antigravity 单家 [semantic-audit-dim3-findings.md](../audits/semantic-audit-dim3-findings.md) + ledger 追加 11 行；10 OPEN finding（HIGH×1 MEDIUM×3 LOW×4 INFO×2）+ 1 WAIVED；**Codex 与 Antigravity 6/6 完全一致**，对抗一致度三轮最高） | 实际 ≈ 60 min（三方对抗） |
| 4 | 技术↔产品对齐 | tech/* 决策是否真服务「采集 > 管理 > 导出」价值链；偏离的需要 ADR 解释 | 45-60 min |
| 5 | standards 约束力 | 每条 `docs/standards/*.md` 规则是否真被 code/skill/CI 执行（grep 触发证据，不仅是引用） | 60-90 min |
| 6 | skill description ↔ body 一致性 | 14 governance + 21 Claude-only + 16 shared 全量逐个核对 description 与 body 是否同义 | 60-90 min |
| 7 | F-rule 实际遵守度 | F-001 ~ F-019 在 git log 是否真有触发证据；空载 F-rule 标候选废止 | 45-60 min |

**总预估**：6-9 小时单方工作量 × 3 家 = 三方并行下用户视角约 8-12 小时跨 2-3 session（Codex / Antigravity 后台跑，Claude 主线推进）。

### 文档新陈代谢约束（连续性 vs 更新的协调机制）

Phase 10 每个维度收尾时**必须**同步触动以下字段，否则不算该维度完成（DoD 硬性条款）：

1. **STATUS.md「当前状态」段**：状态描述从「Phase 9 结构层收官」滚动到「Phase 10 维度 N 已收，剩 7-N 待办」
2. **handoff.md「下一会话方向」**：当前维度收完后翻面到下一维度的具体启动指令
3. **ADR-004 backlog 第一条**：Phase 10 整体完成时将 ✅ 状态字符串升级为「✅ 实施完成（见 ADR-005 §收官）」
4. **ADR-005 本身**：状态字段「提议」→ 7 维度全部收完后置「已决策」，回填实际耗时 + 三家对抗结果汇总表

**违反机制**：任何维度收尾 commit 若只动了维度对应文件、未动上述 4 处之一，premerge-checklist hook 要能拦截（依赖下方 2 新 docaudit check 实现后生效；本会话暂以人审兜底）。

### 配套的 2 个新 docaudit check 设计稿（不本会话实现，沉到 ADR-004 backlog）

| check name | 检测什么 | 实现要点 |
|---|---|---|
| `superseded-by-reverse-link` | ADR 内任何 `superseded_by: ADR-X` 标注必须在 ADR-X 找到对应 `supersedes:` 反向链 | 扫 docs/decisions/*.md，正则匹配两个字段，bipartite 配对验证 |
| `backlog-item-staleness` | ADR / STATUS / handoff 内的 backlog bullet 若引用一个已 merge 的 phase / issue / commit 仍标 ⏳ 或 ❌，告警 | 扫 backlog 段 + git log/gh issue 状态对账；候选清单 → warning 级别 |

两个 check 沉到 [ADR-004 §待后续 phase 实施](ADR-004-doc-system-deep-clean.md#待后续-phase-实施backlog) 与原 4 个 check 设计稿（ssot-cross-check / dep-map-reality / terminology-glossary / snapshot-freshness）并列，每个 1-2 小时实现。

### 终态判据

- 7 维度各产出一份独立 finding 清单（VALID / VALID_WITH_GAP / NEEDS_REVISION / DRIFT）
- audit-ledger 追加语义层段（不复用结构层 224 行 ledger，新开 `docs/audits/audit-ledger-semantic-2026-05.tsv`）
- 真 finding 落 PR 修复；可保留的 GAP 写明 `gap_due`
- 收官时本 ADR 状态从「提议」→「已决策」，回填实际耗时 + 三家对抗结果汇总

## 后果

### 立即生效

- ADR-004 backlog 段 line 186 工具配置声明被本 ADR superseded（在 ADR-004 内打 `superseded_by: ADR-005` 标记，沿用 Round 7 模板）
- STATUS.md 产品决策索引表追加 ADR-005 行
- handoff.md「下一会话方向」改为「执行 Phase 10 实施（按本 ADR 7 维度逐个清单化）」

### 需要更新

- `docs/decisions/ADR-004-doc-system-deep-clean.md` line 186（工具配置）
- `STATUS.md`（ADR 索引 + 当前状态段）
- `docs/memory/handoff.md`（下一会话方向）

### 后续 phase（backlog）

- Phase 10 实施收官后回填本 ADR「决策」段实际数据 + 状态置「已决策」
- ~~若 Antigravity(Gemini 3.5) 在 7 维度上仍呈 over-endorse 模式，更新 [[cross-audit-consensus]] 评分权重段~~ — **维度 1 实测未复现 over-endorse**（详见下方 §维度 1 收官观察）；继续在维度 2-7 监控，复现再触发
- 语义层 ledger 模板沉淀到 `docs/audits/README.md`

### 维度 1 收官观察（2026-05-20）

三方对抗输出分布：Claude 8 / Codex 15 / Antigravity 12，三家折叠后 22 项可采纳 finding（HIGH×3）。

**Gemini 3.5 over-endorse 病灶验证**：

| 指标 | 结果 |
|---|---|
| 100% VALID 倾向 | ❌ 未出现（HIGH 占比 33%） |
| 抓到致命独家 finding | ✅ Dynamic Type 概念混淆（F-D1-010 / S-D1-003） |
| 误判数 | 2（偏严，非偏松） |

**结论**：维度 1 实测，Gemini 3.5 经 Antigravity **未复现 Gemini 3 Pro Preview 的 over-endorse 病灶**，偏严风格反而填补了 Claude/Codex 盲区。三方对抗角色维持。需在维度 2-7 持续观察。

### 维度 2 收官观察（2026-05-20）

三方对抗输出分布：Claude 6 / Codex 7 / Antigravity 6，三家折叠后 11 项可采纳 finding（HIGH×1 MEDIUM×2 LOW×6 INFO×2）+ 3 REJECTED。Claude 自驳 3 项含「分享卡片 REJECTED」被 Codex/Antigravity 翻盘升为 MEDIUM 共识。

**Gemini 3.5 over-endorse 持续监控**：

| 指标 | 维度 1 | 维度 2 |
|---|---|---|
| HIGH 占比 | 33% (4/12) | 17% (1/6) |
| 100% VALID 倾向 | ❌ | ❌ |
| 抓到独家致命 finding | ✅ Dynamic Type 混淆 | ✅ CSV 导入违反「图片是真相」（论证最深）|
| 误判数 | 2 | 0 |
| 新增行为 | — | 加「正面典型」段（3 个完美承接案例）|

**累计结论**：仍未复现 over-endorse 病灶。Antigravity 维度 2 新加「正面典型」段是行为变化点，标记为待观察信号——如果后续出现「finding 越来越少 + 正面段越来越长」趋势再触发降权重。

**累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) = **43 项**，按用户决策跑完 7 维度集中入 PR。

### 维度 3 收官观察（2026-05-20）

三方对抗输出分布：Claude 6 / Codex 6 / Antigravity 6，三家折叠后 10 项可采纳 finding（HIGH×1 MEDIUM×3 LOW×4 INFO×2）+ 1 WAIVED。**Codex 与 Antigravity 6/6 完全对应**，是三轮里对抗一致度最高的一次；Claude CLI 形态明显不同——抓的都是「文档表述层小瑕疵」，错过了 vision 假设层和商业层深层冲突。

**Gemini 3.5 over-endorse 持续监控**：

| 指标 | 维度 1 | 维度 2 | 维度 3 |
|---|---|---|---|
| HIGH 占比 | 33% (4/12) | 17% (1/6) | 17% (1/6) |
| 100% VALID 倾向 | ❌ | ❌ | ❌ |
| 独家/深度发现 | ✅ Dynamic Type 混淆 | ✅ CSV 违反「图片是真相」 | ✅ H2 vs SM-2 翻卡死锁（Codex 同步命中）|
| 误判数 | 2 | 0 | 0 |
| 工作流违规 | — | — | ⚠️ **抢跑落档**（未等三方齐就独立写 ledger/STATUS/handoff/ADR-005）|

**累计结论**：Gemini 3.5 三轮实测**未复现 over-endorse 病灶**，对抗能力反向越来越锋利（维度 3 与 Codex 6/6 一致是强信号）。但维度 3 暴露了 Antigravity 工作流违规——未等三方齐就独立写共识落档；已通过改进提示词模板（明文「严禁操作」段）封堵，沉淀到 [`docs/audits/single-vendor-audit-prompt-template.md`](../audits/single-vendor-audit-prompt-template.md)，维度 4-7 适用。三方对抗角色继续维持。

### 维度 3 元教训（Meta-Finding）

本会话还暴露了一个**元层级**的内部冲突：**Phase 10 自产文档把易变模型版本号 (Gemini 3.5 / Antigravity 桌面端) 写死了**，违反了结构层审计 Phase 4 已建立的 `last_verified / gap_due / external-gap-expiry` 反漂移机制（[[ADR-004]] §防漂移机制）。

具体表现：
- ADR-005 / consensus 报告里把「Antigravity (Gemini 3.5 High)」当固定事实
- 没标 `gap_due` 字段触发未来复审
- 知识截止 2026-01 的助手凭直觉否认 Gemini 3.5 存在（实际 2026-05-19 I/O 发布）—— 双重失误：没搜 + 没标易变

**修复机制（已生效）**：
1. 新增本 ADR §模型版本注 段（上方），声明易变性 + `gap_due` 触发器
2. 「Antigravity (Gemini 3.5 High)」全量改为「Antigravity (Gemini 3.5 Flash (High))」准确称谓
3. 元教训记入维度 3 收官（本段），作为内部冲突扫描的反面教材：制定规则的人不遵守自己规则

**关联**：此发现没有进入维度 3 共识 ledger（因为是元层级、自指向），单独沉淀在本段。

### 元数据

- 本 ADR 决策者：用户批准三方对抗 + 先立项再实施流程；Claude 起草 ADR-005；Codex/Antigravity 实施阶段加入
- 关联 ADR：[[ADR-004]]（结构层方法论 + 本 ADR 的 backlog 立项依据）
- 关联 skill：[[cross-audit]] / [[cross-audit-consensus]] / [[verify-audit-report]]
