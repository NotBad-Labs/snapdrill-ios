---
last_verified: 2026-05-25
layer: contract
scope: path-c-reflection
freshness:
  max_age_days: 30
  decay_trigger: [stage_6_ratified]
override_rationale: |
  路径 C Stage 6 元规则反思报告。基于 Stage 1-5 全过程实证（user-decision-log #016-#019）识别 M-000 / M-005 在 skill 治理场景暴露的 3 个盲点。
  密度证明：(1) 每个 patch 候选必须含路径 C 实证锚定 + 原文片段 + 修订文本 + Overrule 范围，缺任一项无法支持 ratify；(2) §3 反思方法论是 Stage 7 M-003 起草的核心输入，不可压缩；(3) §4 决策点是帅哥裁决输入，必须显式列出（不能让 DeepSeek 主笔自由发挥）。
---

# 路径 C Stage 6 元规则反思报告

> 基于路径 C Stage 1-5 实证（[#016](../meta/user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环) → [#019](../meta/user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 全过程）反思 M-000 v2.0 / M-005 v2 在 skill 治理场景的盲点，产出 3 个修订候选。

## §1 反思方法论

Stage 6 不是从零起草新元规则，而是用路径 C **实证数据**审 M-000/M-005 现有条款：

| 路径 C 实证 | 暴露的 M-000/M-005 盲点 | 修订候选 |
|---|---|---|
| 82% skill 改变形态（46% MERGE + 13% DELETE + 13% DOWNGRADE + 10% PROMOTE）| M-000 §6 把 skill 列为下沉去向之一，未区分优选 vs 兜底 | **P1: M-000 §6 下沉优先级** |
| #017 45 项裁决 + Stage 5 批量执行实战 | M-005 §G docaudit check 升降级机制（§G.4）未覆盖 skill 升降级 | **P2: M-005 §G 扩展 skill 升降级双轨** |
| Claude Stage 2 给治理 skill KEEP（自己用过的）→ 异源 + 用户裁决纠偏 | M-005 §B 伪共识识别未识别"主笔消费偏向"信号 | **P3: M-005 §B 新增主笔消费偏向信号** |
| docaudit 5 类 error + legacy_whitelist + expires_on 机制成功豁免大重构 | M-005 §G docaudit check 设计原则未含"重构期间豁免机制" | （并入 P2 一并修订）|

**反思纪律**：
- ❌ 不引用"未发生的假设场景"（M-005 §E.3 + #018 反思预测点）
- ✅ 每个 patch 必须有路径 C 具体实证锚定
- ✅ 每个 patch 给出精确修订文本（不是方向性描述）

## §2 三个修订候选（patch 候选）

### P1: M-000 §6 下沉优先级修订

**实证锚定**：

路径 C 实证（[#019](../meta/user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 裁决 A-D）：
- 52 个 skill 中只有 11 个保留 skill 形态（21%）
- 24 个 MERGE / 7 DELETE / 12 个 PROMOTE/DOWNGRADE 到 standards/templates = **79% skill 被识别为非 optimal 形态**
- 治理 skill 12 个中只有 3 个 KEEP（25%），其余被 DOWNGRADE/MERGE/DELETE

**M-000 v2.0 §6 当前文本**（行 75-78）：
```
M-000 不预设字数上限。正文长度由信息密度、冷启动成本和不可下沉证明共同决定。frontmatter `override_rationale` 字段是密度证明而非破例申请——作者必须论证：当前长度的每一段内容为什么不能下沉、为什么不能压缩、为什么不能省略。代码块、译本等不单独设立预算，由同一密度证明覆盖。具体冗余检测信号、密度证明判据与同 PR 修订路径下沉 M-005 §J（M-005 §J.4 已明确删除代码块独立预算和英文译本固定乘数作为默认规则）。

新增条款必须先证明无法下沉到 M-001~M-006、standards、skills、ADR、STATUS stub 或工具。若条款只是执行步骤、模板、例子、命令、检查脚本或当前状态，应下沉。

知识库治理不使用固定文件数量作为单一门槛。新增文档必须说明预期消费者；4 周无 incoming refs 的活跃文档进入 archive 候选但不自动归档。判断信号包括 Boot/Action Gate 字符预算、incoming refs、访问或修改频率、重复权威定义、维护成本和是否可由工具生成。
```

**问题诊断**：
"下沉去向"列表 `M-001~M-006、standards、skills、ADR、STATUS stub 或工具` 把 skills 与 standards/工具 平级列出，没有优先级。路径 C 实证证明 **skill 不应该是元规则下沉的优选去向**——它是「需要 LLM 动态判断的少数场景」的兜底，其他场景应优先 standards / templates / hook / 工具。

**P1 修订文本**（替换 §6 第二段）：

```
新增条款必须先证明无法下沉。下沉优先级（从高到低）：
1. **standards**（静态规范，docs/standards/）：规则、约束、规范——不需 LLM 动态判断
2. **templates**（静态模板，docs/templates/）：代码片段、配置模板、checklist——纯模板可 cp 修改
3. **hook / CI 自动化**：可机械检查的规则下沉到 .claude/hooks / .github/workflows / Scripts
4. **工具脚本**：复杂校验或转换逻辑下沉到 Scripts/
5. **M-001~M-006 / ADR**：跨多个执行单元的协作规则
6. **skills**（仅用于需要 LLM 动态判断且不可静态化的场景）：trigger 条件依赖上下文推理，无法机械化

若条款只是执行步骤、模板、例子、命令、检查脚本或当前状态，应下沉至 standards / templates / hook，**不应保留为 skill**。skill 是元规则下沉的**末位优选**，仅在前 5 项均不适用时使用。
```

**Overrule 范围**：精化（非 Overrule）M-000 v2.0 §6 第二段——保留"必须先证明无法下沉"精神，新增下沉优先级列表。

**风险与例外**：
- 现有 11 个 active skill 全部受 §6 新优先级约束——下次复审时若发现某 skill 实际可下沉为 standards/template，应触发降级
- 例外：路径 C 已经走过完整审计的 11 个 KEEP/REWRITE skill 短期内（≤6 个月）不重审，避免治理过载

---

### P2: M-005 §G docaudit check 设计原则扩展为 skill 升降级双轨

**实证锚定**：

路径 C 实证（[#017](../meta/user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) Stage 3.5 + [#018](../meta/user-decision-log.md#018-skill-审计-final-ratified--路径-c-stage-44-完成) Stage 4 + [#019](../meta/user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) Stage 5）：
- 52 个 skill 升降级 6 种 Verdict（KEEP/MERGE/DELETE/PROMOTE/DOWNGRADE/REWRITE）= skill 升降级实证数据集
- legacy_whitelist + expires_on 机制让大规模重构期间的 docaudit error 可控豁免（路径 C Stage 5 实证 2 项豁免）
- skill 升降级的判据（元规则对齐分 / 使用频率 / 4 家异源审）路径 C 中实际使用

**M-005 v2 §G 当前文本**（行 267-302）：
- §G.1 每个 check 必须有真实事故来源或风险模型
- §G.2 核心 check 进入阻塞门的判据
- §G.3 可选 check 的存在价值
- §G.4 新增 check 的提案流程（升级与降级双向）

**问题诊断**：
§G 仅覆盖 docaudit check 的升降级。skill 升降级与 docaudit check 升降级**同源**（都是元规则执行层组件的生命周期管理），但 §G 未明文扩展到 skill。路径 C 是 skill 升降级的首次大规模实战，但没有现有 M-005 条款承载这套机制。

**P2 修订文本**（在 §G 末尾追加新章节 §G.5）：

```markdown
### G.5 skill 升降级机制（路径 C #019 实证扩展）

skill 升降级采用与 docaudit check 升降级（§G.1~§G.4）**同源**的双轨机制。skill 特有判据：

**§G.5.1 6 种 Verdict 体系**（路径 C #017 实证）：
- **KEEP**：保留 skill 形态。要求：需要 LLM 动态判断 + 不可下沉到 standards/template/hook + 触发频率高 + 元规则对齐分 ≥4
- **REWRITE**：保留 skill 形态但内容重写。要求：方向正确但措辞过期/不一致
- **MERGE**：合并到容器 skill 或 standards/template 文件。要求：与另一组件功能重叠 + 合并后认知负担更低
- **PROMOTE_TO_STANDARDS**：内容升 standards/，删除 skill。要求：内容是规则/约束/规范 + 不需 LLM 介入
- **DOWNGRADE_TO_TEMPLATE**：内容降 templates/，删除 skill。要求：内容是纯模板/代码片段 + trigger 条件不需推理
- **DELETE**：归档至 docs/archive/skills/<date>/。要求：装饰性 / 过时 / 形式合规但实质空洞 / 已被其他组件覆盖

**§G.5.2 skill 触发周期审计**：
- 每 90 天审计一次 .claude/skills/ active 清单
- 连续 ≥2 个季度无实际触发的 skill → 自动降格为候选（标 skill_audit_verdict: candidate）
- 候选 ≥1 季度仍无触发 → 升降级提案

**§G.5.3 大规模 skill 重构的 baseline + expires_on 机制**：
- skill 大规模重构（如路径 C，影响 ≥10 个 skill）期间，docaudit 必然抓出 frontmatter/links/skill-* 类批量 error
- 修复策略：legacy_whitelist 加豁免 + expires_on（≤30 天）+ reason 引用 user-decision-log #编号
- expires_on 强制周期性复审，避免技术债隐藏（路径 C #019 实证）

**§G.5.4 主笔消费偏向警示**（与 §B 联动）：
- 主笔（含 Claude 主分支会话）对自己消费过的治理 skill 自审时，KEEP/REWRITE 判定**默认折扣 0.5 权重**（参 §B.1 thinking 模式权重折扣机制）
- 路径 C 实证：Claude Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP，帅哥裁决全部 DOWNGRADE/MERGE/DELETE——Claude 同源偏向被异源 + 用户裁决纠偏。

**§G.5.5 与 M-001 主笔轮换的衔接**：
skill 审计的主笔提名规则与 M-005 §H 主笔轮换原则同源——避免连续同源主笔审 skill 累积同源偏向。
```

**Overrule 范围**：精化（非 Overrule）M-005 v2 §G——新增 §G.5 章节，原 §G.1~§G.4 保留不变。

---

### P3: M-005 §B 伪共识识别新增主笔消费偏向信号

**实证锚定**：

路径 C 实证：
- Claude Stage 2 audit 给 KEEP 的 34 个 skill 中，含 cross-audit / sprint-contract / decision-closeout / knowledge-health 等"Claude 主分支会话用过的治理 skill"
- 帅哥裁决（#017）这 4 个 skill 全部 DOWNGRADE/MERGE/DELETE
- Claude Stage 4 v2 sign-off **显式撤回** Stage 2 KEEP 立场（自反性 sanity check 应用）
- Gemini Stage 4 v2 sign-off 同样自反性撤回 Stage 2 立场，明言"如果本轮只有我单方进行 sign-off，上述 4 处严重偏离用户裁决的硬伤就会带入主分支"

**M-005 v2 §B.1 当前文本**（行 105-112）：
```
当以下任一信号出现时，**同源警告升级为自动用户裁决**，不等待异源方显式反对：

1. **连续同源主笔**：同一 vendor 连续担任主笔 ≥ 3 版（实证：M-000 v1.0/v1.1/v1.2/v2.0 连续 4 版 Codex 主笔...）
2. **多实例同训练 cutoff**：来自同一 cutoff 日期的多个模型实例给出方案同向...
3. **同 vendor 的多端点聚合**：同一厂商的多个 API endpoint 被当作「多家异源」使用...
4. **thinking/reasoning 模式加剧的自我身份漏泄**：...该模型的独立判断**建议折扣 0.5 权重**...
```

**问题诊断**：
§B.1 4 个信号都是「智能体之间的同源」，但**没有覆盖"主笔与自己消费过的工具/skill 的同源"**——这是路径 C 暴露的新维度。

**P3 修订文本**（在 §B.1 追加第 5 条信号）：

```markdown
5. **主笔消费偏向**（路径 C #019 实证）：当主笔在自审中给某个治理 skill / 工具 / 流程 KEEP/REWRITE 判定，且该主笔在历史会话中消费过该 skill / 工具 / 流程时，**KEEP/REWRITE 判定建议折扣 0.5 权重**；折扣应在折叠报告显式标注，**不强制阻塞**。
   - 实证：Claude 路径 C Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP（4 个 Claude 主分支会话用过的治理 skill），#017 帅哥裁决全部 DOWNGRADE/MERGE/DELETE。Claude 同源偏向被异源 + 用户裁决纠偏。
   - 触发动作：折叠主笔在 consensus 报告中显式列出"主笔自审 + 自己消费过的组件"配对，提示帅哥关注同源偏向。
   - 与 §H 衔接：路径 C #019 §G.5.4 已扩展 §G 以承载此机制（同源信号），§B 与 §G 在 skill 审计场景双向引用。
```

**Overrule 范围**：精化（非 Overrule）M-005 v2 §B.1——保留原 4 个信号，新增第 5 个。

---

## §3 路径 C Stage 7 M-003 起草输入（基于本反思）

Stage 6 反思识别的 3 个修订点同时也是 Stage 7 M-003 起草的核心输入：

| 反思点 | 对 M-003 的输入 |
|---|---|
| P1 下沉优先级 | M-003 §核心机制：skill 是 standards/templates/hook 之外的"末位优选"，不是默认下沉去向 |
| P2 skill 升降级机制 | M-003 §升降级章节：直接采纳 §G.5 6 种 Verdict + 季度审计 + baseline 机制 |
| P3 主笔消费偏向 | M-003 §主笔与 skill 消费的隔离要求 |

M-003 起草时必须显式引用本反思报告作为实证输入。

## §4 致帅哥的决策点

按 [#005](../meta/user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 批准权机制，元规则修订属结构性决定，需帅哥显式批准。提供 3 种处理路径：

### 方式 A：3 个 patch 全部接受 + 启动 Stage 6.2（修订流程）
帅哥批准全部 3 个 patch → DeepSeek 主笔产 patch final → 3 家 sign-off → ratify (#020) → 同 PR 修订 M-000 v2.0 §6 + M-005 v2 §B §G

### 方式 B：选择性接受 + 调整 patch 内容
帅哥逐个 patch 裁决（接受 / 拒绝 / 精化）→ 调整后走 Stage 6.2 修订流程

### 方式 C：推迟修订 + 仅记录反思
仅 commit 本反思报告作为 Stage 7 M-003 起草输入，不立即修订 M-000/M-005。等 M-001~M-006 全部 ratify 后批量评估 M-000/M-005 修订需求。

**Claude 推荐**：**方式 A**——3 个 patch 均有充分路径 C 实证锚定，且修订内容精确（替换/追加段落级别）。立即落地能让后续 M-001~M-006 起草直接受益于新规则（特别是 P1 下沉优先级 + P3 主笔消费偏向警示）。

## §5 后续路径

| 步骤 | 内容 |
|---|---|
| 6.1 反思报告 ratify | 本报告 commit 后等帅哥裁决（方式 A/B/C） |
| 6.2 修订流程（若方式 A/B）| DeepSeek 主笔产 patch final → 3 家 sign-off → ratify (#020) → 同 PR 修订 M-000/M-005 |
| 6.3 backlog 整理 | 路径 C 暴露的 legacy_whitelist 豁免（skill-links + home-path-refs，2026-06-30 到期）→ 落 backlog |
| Stage 7 M-003 起草 | 基于本反思 + 路径 C 全实证起草 M-003 |

## 关联文档

- [user-decision-log #016~#019](../meta/user-decision-log.md) 路径 C 全流程
- [skill-audit-final.md](skill-audit-final.md) DeepSeek 主笔 final（含 §5 元规则反思预测点）
- [M-000 v2.0 §6](../meta/M-000-meta-vision.md) - P1 修订对象
- [M-005 v2 §B / §G](../meta/M-005-quality-criteria.md) - P2/P3 修订对象
