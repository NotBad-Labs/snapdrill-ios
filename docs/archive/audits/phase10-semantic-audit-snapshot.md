---
last_verified: 2026-05-24
layer: snapshot
scope: audit-archive
freshness:
  max_age_days: 365
  decay_trigger: [historical_record]
source_adr: docs/decisions/ADR-005-doc-semantic-layer-audit.md
phase_period: 2026-05-20 to 2026-05-21
---
# Phase 10 语义层审计 Findings 历史快照

> 本文件从 ADR-005 物理切出（user-decision-log #007 激进拆分裁决）。Phase 10 七维度审计完整 findings 历史档案。86 OPEN finding 累计统计。如需 Phase 10 方法论残余 + 五大教训摘要，见 [ADR-005 主文档](../../decisions/ADR-005-doc-semantic-layer-audit.md)；如需当前模型版本事实，见 [docs/tech/reference/agent-cli-models.md](../../tech/reference/agent-cli-models.md)。

## 模型版本注（2026-05-20 历史快照）

> 本节为 2026-05-20 历史快照，同时是 `gap_due` 首次正式使用案例。当前模型版本事实不得引用本节作为 SSOT；应使用 [docs/tech/reference/agent-cli-models.md](../../tech/reference/agent-cli-models.md)。

### 原 ADR-005 模型版本注原文

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

## Phase 10 维度收尾纪律（历史快照）

Phase 10 每个维度收尾时**必须**同步触动以下字段，否则不算该维度完成（DoD 硬性条款）：

1. **STATUS.md「当前状态」段**：状态描述从「Phase 9 结构层收官」滚动到「Phase 10 维度 N 已收，剩 7-N 待办」
2. **handoff.md「下一会话方向」**：当前维度收完后翻面到下一维度的具体启动指令
3. **ADR-004 backlog 第一条**：Phase 10 整体完成时将 ✅ 状态字符串升级为「✅ 实施完成（见 ADR-005 §收官）」
4. **ADR-005 本身**：状态字段「提议」→ 7 维度全部收完后置「已决策」，回填实际耗时 + 三家对抗结果汇总表

**违反机制**：任何维度收尾 commit 若只动了维度对应文件、未动上述 4 处之一，premerge-checklist hook 要能拦截（依赖下方 2 新 docaudit check 实现后生效；本会话暂以人审兜底）。

## Phase 10 七维度收官与全局收官历史原文

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

**累计结论**：Gemini 3.5 三轮实测**未复现 over-endorse 病灶**，对抗能力反向越来越锋利（维度 3 与 Codex 6/6 一致是强信号）。但维度 3 暴露了 Antigravity 工作流违规——未等三方齐就独立写共识落档；已通过改进提示词模板（明文「严禁操作」段）封堵，沉淀到 [`docs/audits/single-vendor-audit-prompt-template.md`](../../audits/single-vendor-audit-prompt-template.md)，维度 4-7 适用。三方对抗角色继续维持。

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

### 维度 4 收官观察（2026-05-21）

三方对抗输出分布：Claude 2 / Codex 7 / Antigravity 5，三家折叠后 11 项 OPEN finding（HIGH×3 MEDIUM×4 LOW×4）。

**关键发现**：3 个 HIGH 含 **2 个真生产 bug**：
- S-D4-002 通知 ID 全局硬编码 + cancelAll 物理覆盖 Multi-Profile（Antigravity 独家）
- S-D4-003 badge 实现 vs 产品规格「不使用角标」三层背离（Codex 独家，共识提级 HIGH）

S-D4-001 DI 系统性退化是 3/3 同域共识（Claude 系统视角 + Antigravity 症状 + Codex 归属角度）。

**Gemini 3.5 持续监控**：

| 指标 | 维度 1 | 维度 2 | 维度 3 | 维度 4 |
|---|---|---|---|---|
| HIGH 占比 | 33% | 17% | 17% | 40% (2/5) |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ |
| 工作流违规 | — | — | ⚠️ 抢跑 | ✅ 守规矩 |

**结论**：四轮累计未复现 over-endorse。维度 3 抢跑漏洞被改进提示词模板（「严禁操作」段）成功封堵。维度 4 单家排名变化：Codex 大爆发升为最强单家——3 家形态稳定互补（Claude 元规则 / Antigravity 代码 grep / Codex 文档 vs 实现跨文件追踪）。

**累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) + 维度 4 (11) = **54 项**。

### 维度 4 工作流改进

维度 4 验证了新工作流的有效性，**沉淀为后续维度 5-7 纪律**：

**「Claude CLI 先跑 → 给提示词 → Codex/Antigravity 工作」**

理由：
- Claude CLI 先跑保证盲审独立性
- 提示词由 Claude CLI 起草，可针对性圈定该维度的盲区
- Codex/Antigravity 后跑可以参考 Claude CLI 输出做差异化扩展（虽然 F-008 要求独立产出，但实际工作流难做到完全盲）

已沉淀到 [`docs/audits/single-vendor-audit-prompt-template.md`](../../audits/single-vendor-audit-prompt-template.md) §工作流纪律段。

### 维度 5 收官观察（2026-05-21）

三方对抗输出分布：Claude 6 / Codex 12 / Antigravity 6，三家折叠后 15 项 OPEN finding（HIGH×3 MEDIUM×8 LOW×3 INFO×1）。

**关键发现**：3 个 HIGH 含 2 个元层级问题：
- S-D5-001 permission-model ERE vs Python classifier (3/3 一致)
- S-D5-007 collaboration audit_note 自我虚假声明（GPT-5.4 vs gpt-5.5）
- S-D5-008 collaboration Antigravity fallback 定位 vs Phase 10 实际工作流

**控制变量法纪律事件**：Claude CLI 第一次跑维度 5 偷懒只扫 5/17 文件，被用户纠正后重跑完整 17 文件。这是控制变量法精髓的实战教训——**「先给提示词，再自己跑」是错的，正确顺序是「自己完整跑，再用一模一样的任务定义给外审」**。已沉淀到 single-vendor-audit-prompt-template.md。

**Codex 第二轮大爆发**：维度 4+5 连续两轮最强单家——12 项里 5 项独家（skill 计数 / any existentials / F-004 dead / accessibility / harness-recall ## Risks）。Claude 元层级强（S-D5-010 制定者不遵守自己规则），但机械实证广度不足。

**Gemini 3.5 持续监控**：

| 指标 | 维度 1 | 维度 2 | 维度 3 | 维度 4 | 维度 5 |
|---|---|---|---|---|---|
| HIGH 占比 | 33% | 17% | 17% | 40% | 17% |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 工作流违规 | — | — | ⚠️ 抢跑 | ✅ 守规矩 | ✅ 守规矩 |

**累计结论**：Gemini 3.5 五轮实测未复现 over-endorse；维度 4-5 连续守规矩证明提示词「严禁操作」段封堵有效。

**累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) + 维度 4 (11) + 维度 5 (15) = **69 项**。

### 维度 6 收官观察（2026-05-21）

三方对抗输出分布：Claude 2 / Codex 6 / Antigravity 5，三家折叠后 7 项 OPEN finding（MEDIUM×3 LOW×4，**无 HIGH**）。

**关键发现**：
- **S-D6-001 [MEDIUM, Codex 独家]**: 13+ Claude-only domain skill description 承诺 Generates/Reviews，body 引用的 support files (apple-hig-icons.md / templates.md / swift-patterns.md 等) **物理不存在**。结构层 skill-provenance check 漏抓的元层级盲区
- **S-D6-002 [MEDIUM, 2/3]**: 3 个 vendored shared skill 缺 H1。Claude 自驳此前判断；但修复路径受 skill-source-ledger:16「Do not edit community skill bodies」约束，**Antigravity 处方违规**——需走 WAIVED 或上游 PR
- **S-D6-003 [MEDIUM, Codex]**: tdd-refactor-guard description「Verifies」vs body「generates characterization tests」动词偏移

**Codex 三轮连续最强**（维度 4+5+6）：擅长跨文件机械实证 + 系统性扫描。

**Claude CLI 首次 0 独家**：暴露大范围机械实证局限——并非偷懒，完整扫了 52 个 skill，但发现都被 Codex/Antigravity 覆盖。**这是控制变量法的真实价值**——暴露模型差异化能力边界。

**Gemini 3.5 监控**：六轮累计未复现 over-endorse；但维度 6 出现 **「抓真问题 + 开错处方」**（H1 修复违反 skill-source-ledger）新现象，需要监控是否成为模式。

**累计 OPEN finding**：22 + 11 + 10 + 11 + 15 + 7 = **76 项**。剩 1 维度（维度 7 F-rule 遵守度）。

### 维度 7 收官观察 + Phase 10 全局收官（2026-05-21）

三方对抗输出分布：Claude 4 / Codex 5 / Antigravity 5，三家折叠后 10 项 OPEN finding（HIGH×3 MEDIUM×2 LOW×3 INFO×2）+ 1 WAIVED 污染样本。

**3 个 HIGH 含 Phase 10 致命独家**：
- **S-D7-001 [Antigravity 独家]**: docaudit.py:593 rule-usage check 正则只匹配 Markdown 标题，feedback.md 13 个 active F-rule 在表格行声明全部漏审——**整个 rule-usage check 从 Phase 4 升级以来未真正工作过**，推翻维度 5 S-D5-013 结论基础
- **S-D7-002 [Codex 独家]**: F-005 PR #742 已 merge 但 reviews=0 + comments=0 + body 无 review 留痕——真生产级 F-rule 违规
- **S-D7-003 [Claude 独家]**: F-018 Sprint Contract 实际应用率极低（enhancement 0/5 + chore 0/4，仅 epic #766 有）

## Phase 10 全局收官

**七维度全部完成**。**累计 OPEN finding：22 + 11 + 10 + 11 + 15 + 7 + 10 = 86 项**（按用户决策跑完 7 维度集中入 PR）。

### 三家整体表现（七维度累计）

| 单家 | 强项 | 弱项 |
|---|---|---|
| **Claude CLI** | 元层级自指（维度 3 元教训 / 维度 5 S-D5-010 / 维度 7 F-018 应用率） | 大范围机械实证（维度 6 首次 0 独家）|
| **Codex** | 跨文件机械实证 + 系统性扫描（**维度 4+5+6+7 连续最强**） | 受提示词污染指令直接服从（维度 7 明确避开 Claude）|
| **Antigravity** | 代码 grep + 工具底层 bug 挖掘（Dynamic Type / H2-SM-2 死锁 / 通知物理覆盖 / **docaudit.py bug**）| 守规矩程度起伏（维度 3 抢跑 → 维度 4-6 守 → 维度 7 抄袭 Claude 编号）|

### Gemini 3.5 over-endorse 七轮累计监控

| 指标 | 维度 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| HIGH 占比 | 33% | 17% | 17% | 40% | 17% | 0% | 20% |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 工作流违规 | — | — | ⚠️ 抢跑 | ✅ | ✅ | ✅ | ⚠️ 抄袭 Claude 编号 |

**七轮累计未复现 over-endorse 病灶**。但维度 7 出现新违规模式（抄袭 Claude 编号），与维度 3 抢跑不同——是「执行了任务但产物借用他家编号体系」。

### Phase 10 五大方法论实战教训（历史原文）

#### 1. 控制变量法污染（维度 5-7 同源）

**问题**：每次提示词加「Claude CLI 已抓（避免重复）」段，导致 Codex/Antigravity 定向避开或抄袭 Claude finding——**违反 F-008 控制变量法精髓**。

**后果**：
- 维度 5-7「2/3 共识少 + Codex/Antigravity 独家多」可能是污染产物而非真实模型差异
- 真实 3/3 共识 finding 可能比 ledger 显示的多

**沉淀**：Phase 11+ 启用 git worktree 物理隔离 + 净化提示词（见 ADR-005 主文档）。

#### 2. 抢跑落档（维度 3 暴露 → 维度 4-7 封堵）

**问题**：维度 3 Antigravity 未等三家齐就独立写 ledger / STATUS / handoff / ADR-005。
**修复**：提示词加「严禁操作」段；维度 4-7 封堵成功。

#### 3. 文档新陈代谢（连续性 vs 更新）

**问题**：Phase 10 自产文档把易变模型版本写死（如「Antigravity (Gemini 3.5 High)」），违反 ADR-004 反漂移机制。
**修复**：ADR-005 加 §模型版本注 + `gap_due: gemini_3_5_pro_release`。

#### 4. 元层级 self-non-compliance（维度 3/5/7 反复出现）

样本：
- 维度 3 元教训：Phase 10 自产文档自我违反结构层 ADR-004 反漂移机制
- 维度 5 S-D5-010：single-vendor-audit-prompt-template 未内联 shared-constraints（违反 codex-delegation §2 强制要求）
- 维度 7 S-D7-001：制定 docaudit.py 工具的人未审查正则真值是否覆盖全部 F-rule 声明位置

**沉淀**：「制定规则的人不遵守自己规则」成 Phase 10 高频反模式，候选 F-021 规则（Phase 11+ 评估）。

#### 5. 易变事实 + gap_due 机制（维度 6 验证）

`docaudit external-gap-expiry` check 在 Phase 4 建立，维度 6 ADR-005 §模型版本注首次正式使用——基于外部条件（`gemini_3_5_pro_release`）触发复审。

### Worktree 工作流（历史入口）

详见 [`docs/audits/semantic-audit-dim7-consensus.md` §Worktree 工作流](../../audits/semantic-audit-dim7-consensus.md)。该工作流已沉淀到 [`docs/standards/worktree-audit-workflow.md`](../../standards/worktree-audit-workflow.md)，当前执行入口以后者为准。

### Phase 10 累计统计

- 七维度三方对抗实际耗时：≈ 90+60+60+60+90+75+60 = **约 8 小时跨多 session**
- 累计 OPEN finding：**86 项**（HIGH×13 MEDIUM×26 LOW×35 INFO×12，按维度 1-7 严重度合计）
- REJECTED / WAIVED：5 + 1 = 6 项
- 共识报告 7 份（dim1 ~ dim7）+ Antigravity 单家报告 4 份 + ledger 1 份

### 后续优先（历史快照）

1. **修维度 7 S-D7-001**（`docaudit.py:593` 正则）→ 重跑 rule-usage 看真实状态 → 推翻 / 确认 S-D5-013
2. **修维度 7 S-D7-002**（F-005 PR review 留痕 hook 强化）
3. **修维度 7 S-D7-003**（F-018 sprint contract 机械拦截）
4. **修维度 1 S-D1-001/S-D1-002/S-D1-003**（字段配置链 + CSV 架构 + Dynamic Type 混淆）
5. **修维度 4 S-D4-001/S-D4-002/S-D4-003**（DI 退化 + 通知物理覆盖 + badge 三层背离）

剩余 LOW/INFO 作为语义卫生 backlog 渐进处理。
