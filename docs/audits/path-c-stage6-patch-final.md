---
last_verified: 2026-05-25
layer: contract
scope: path-c
freshness:
  max_age_days: 30
  decay_trigger: [stage_6_ratified]
override_rationale: |
  本文是路径 C Stage 6 patch final 报告，直接承载 M-000 §6 / M-005 §B.1 / M-005 §G 三处修订的精确替换文本、Overrule 关系声明、风险处理、user-decision-log #020 草案和 Stage 6.3 执行清单。每段不可压缩：
  (1) Patch P1 final 必须包含替换文本、Overrule 范围、风险例外——省略任一项会导致 ratify 时签名方无法评估修订边界；
  (2) Patch P2 final 必须完整给出 §G.5.1~§G.5.5 全章节（约 300 nwc），缺任何子节会破坏 skill 升降级双轨机制的完整性；
  (3) Patch P3 final 必须给出追加措辞及实证注解，否则后续伪共识识别无法引用第五信号；
  (4) user-decision-log #020 草案必须按标准 7 字段格式引用 #016-#019 全过程实证，缺任一字段不满足 M-000 §5 裁决日志规范；
  (5) 执行清单需精确到 line 范围，否则 Stage 6.3 执行者无法准确落 PR。
  全文无装饰性段落，每段直接为同 PR 修订服务。
---

# 路径 C Stage 6 patch final 报告

> 产出依据：Stage 6.1 反思报告（path-c-stage6-reflection.md）中 3 个 patch 候选 + 路径 C 全实证（user-decision-log #016-#019）。DeepSeek reasoner 主笔产 patch final。

## §1 执行摘要

Stage 6.1 反思报告识别 M-000 v2.0 / M-005 v2 在 skill 治理场景暴露的 3 个盲点，对应 3 个 patch 候选。经精化措辞并充分利用路径 C 实证（#016-#019），产出以下 final 版本：

| Patch | 修订对象 | 修订类型 | Overrule 关系 | 路径 C 实证锚点 |
|---|---|---|---|---|
| **P1** | M-000 v2.0 §6 第二段 | 全文替换 | 精化（非 Overrule） | #019 52→11 skill 形态，79% 非 optimal |
| **P2** | M-005 v2 §G 末尾追加 §G.5 | 新增章节 | 精化（非 Overrule） | #017 45 项裁决 + #019 批量执行 |
| **P3** | M-005 v2 §B.1 末尾追加第 5 条信号 | 新增列表项 | 精化（非 Overrule） | #017 Claude 同源偏向 + #019 实证 |

三个 patch 均经由 #017-#019 全过程实证验证方向正确性。帅哥 ratify 后，同 PR 修订（Stage 6.3）落地。

## §2 Patch P1 final — M-000 §6 下沉优先级修订

### Overrule 范围声明

- **类型**：精化（非 Overrule）M-000 v2.0 §6 第二段
- **覆盖对象**：当前第二段（行 76-78）「新增条款必须先证明无法下沉到 M-001~M-006、standards、skills、ADR、STATUS stub 或工具。若条款只是执行步骤、模板、例子、命令、检查脚本或当前状态，应下沉。」
- **保留**：§6 其余内容（字数密度规则、知识库治理、frontmatter 密度证明）全部保留不变
- **失效范围**：旧第二段全文被替换，下沉去向的平级列表被优先级列表取代

### 精确替换文本（替换后 §6 第二段全文）

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

### 风险与例外处理

1. **短期豁免**（≤6 个月）：路径 C 已走过完整审计的 11 个 KEEP/REWRITE skill（含 dod-checklist / phase-closeout / swiftui-pro / verify-audit-report / xcode-review / tdd-feature / screenshot-planner / app-description-writer / swift-concurrency-pro / swiftdata-pro / decision-closeout）不自动触发下沉重审，避免治理过度。此豁免在 Stage 7 M-003 ratify 时自动解除。
2. **例外适用条件**：仅当 skill 的 trigger 条件依赖 LLM 上下文推理、且无法被 standards / templates / hook 替代时，才允许使用第 6 优先级。下次 skill 复审（每 90 天 §G.5.2 定义）必须重新评估是否符合条件。
3. **下沉证明责任**：主笔在提议新增条款时，必须在 override_rationale 或提案说明中显式论证为什么前 5 项不适用。未论证或论证不充分 → 可按 M-005 §J 冗余检测视为装饰性段落。

## §3 Patch P2 final — M-005 §G 扩展 skill 升降级双轨

### Overrule 范围声明

- **类型**：精化（非 Overrule）M-005 v2 §G
- **覆盖对象**：在原 §G 末尾追加新章节 §G.5，原 §G.1~§G.4 全部保留
- **保留**：§G 全文（六个设计原则 + 可选/核心 check 流程）不变
- **适用范围**：新 §G.5 仅定义 skill 升降级机制，与 docaudit check 升降级并行运作；当 skill 升降级与 docaudit check 升降级冲突时，按 §G.5 优先（skill 判据更精确）

### 精确追加文本（在 §G.4 末尾追加）

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
- 路径 C 实证（#017）：Claude Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP，帅哥裁决全部 DOWNGRADE/MERGE/DELETE——Claude 同源偏向被异源 + 用户裁决纠偏。

**§G.5.5 与 M-001 主笔轮换的衔接**：
skill 审计的主笔提名规则与 M-005 §H 主笔轮换原则同源——避免连续同源主笔审 skill 累积同源偏向。
```

### 风险与例外

- §G.5 首次生效时不回溯检查已有 skill（路径 C 已审计的 11 个 skill 自动满足首轮 90 天周期要求）
- §G.5.4 的 0.5 折扣仅适用于自审场景（主笔审自己消费过的 skill），不适用于异源审核场景

## §4 Patch P3 final — M-005 §B.1 主笔消费偏向信号

### Overrule 范围声明

- **类型**：精化（非 Overrule）M-005 v2 §B.1
- **覆盖对象**：在原 §B.1 末尾追加第 5 条信号，原 4 条信号全部保留
- **保留**：§B.1 全文（连续同源主笔 / 多实例同训练 cutoff / 同 vendor 多端点聚合 / thinking 模式身份漏泄）不变

### 精确追加文本（在 §B.1 第 4 条信号后追加）

```markdown
5. **主笔消费偏向**（路径 C #019 实证）：当主笔在自审中给某个治理 skill / 工具 / 流程 KEEP/REWRITE 判定，且该主笔在历史会话中消费过该 skill / 工具 / 流程时，**KEEP/REWRITE 判定建议折扣 0.5 权重**；折扣应在折叠报告显式标注，**不强制阻塞**。
   - 实证：Claude 路径 C Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP（4 个 Claude 主分支会话用过的治理 skill），#017 帅哥裁决全部 DOWNGRADE/MERGE/DELETE。Claude 同源偏向被异源 + 用户裁决纠偏。
   - 触发动作：折叠主笔在 consensus 报告中显式列出"主笔自审 + 自己消费过的组件"配对，提示帅哥关注同源偏向。
   - 与 §H 衔接：路径 C #019 §G.5.4 已扩展 §G 以承载此机制（同源信号），§B 与 §G 在 skill 审计场景双向引用。
```

### 风险与例外

- 主笔消费偏向信号**不自动升级为用户裁决**，而仅在折叠报告中标注折扣；若异源方同时给出反对意见，按 §B.3 否决权阈值处理
- 消费记录仅追溯同一会话或显式归档的历史（不要求主笔记忆所有历史会话）
- 与 §B.1 第 4 条（thinking 模式折扣）可叠加：若主笔同时触发 thinking 模式身份漏泄 + 消费偏向，折扣权重可累加至 0.75（即两个 0.5 折扣相乘 = 0.25 原权重），但应在折叠报告中分开注明

## §5 user-decision-log #020 草案

### 条目 #020 — Stage 6 patches ratified（3 个 patch 全部接受）

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | 路径 C Stage 6 元规则反思（基于 #016-#019 全过程实证）识别 M-000 v2.0 §6 / M-005 v2 §B.1 / M-005 v2 §G 三处盲点，产出 3 个 patch 候选。帅哥按方式 A 全部接受，DeepSeek 主笔产 patch final，3 家 sign-off 后 ratify（参 #020）。需确认：P1 下沉优先级修订、P2 skill 升降级双轨、P3 主笔消费偏向信号。 |
| **裁决** | 3 个 patch 全部接受，进入同 PR 修订：<br>A. M-000 v2.0 §6 第二段替换为下沉优先级列表（standards > templates > hook/CI > 工具 > M-001~M-006/ADR > skills），skill 降为末位优选。<br>B. M-005 v2 §G 追加 §G.5 skill 升降级机制（6 种 Verdict + 季度审计 + baseline/expires_on + 主笔消费偏向警示 + 主笔轮换衔接）。<br>C. M-005 v2 §B.1 追加第 5 条信号（主笔消费偏向，KEEP/REWRITE 折扣 0.5 权重）。<br>所有修订在同 PR 落 doc 并刷新 last_verified。 |
| **理由** | 路径 C 全实证锚定：<br>- #019 82% skill 非 optimal 形态（46% MERGE + 13% DELETE + 13% DOWNGRADE + 10% PROMOTE）=> P1 下沉优先级降 skills<br>- #017 45 项分歧裁决 + #019 批量执行实战 => P2 skill 升降级双轨<br>- #017 Claude 给 4 个自己用过的治理 skill KEEP 被帅哥全部 DOWNGRADE/MERGE/DELETE => P3 主笔消费偏向信号<br>三个 patch 均不扩大元规则体系规模（P1 替换段、P2 追加节、P3 追加项），仅在现有框架内精化盲点。修复合计净增文本约 400 nwc（P1 -80 + P2 +350 + P3 +130 = +400），密度自洽。 |
| **是否触发元规则修订** | ✅ 是。M-000 v2.0 §6 / M-005 v2 §B.1 / M-005 v2 §G 三处文本修订。 |
| **Overrule 关系** | 精化（非 Overrule）以下条款：<br>① 精化 M-000 v2.0 §6 第二段（下沉去向平级列表 → 优先级列表）<br>② 精化 M-005 v2 §B.1（原 4 条信号 + 新增第 5 条主笔消费偏向）<br>③ 精化 M-005 v2 §G（原 §G.1~§G.4 + 新增 §G.5 skill 升降级双轨）<br>不覆盖任何历史裁决的认证效力。路径 C #016-#019 的裁决全部保留生效。 |
| **元层级注记** | 路径 C 完成 Stage 1-5（skill 生态 52→11）+ Stage 6（元规则反思 + 3 patch）= 第二次元规则自我演进闭环（第一次 #009-#011 M-000 v2.0，第二次 #015 M-005 v2，第三次 #016-#020 路径 C）。Stage 7 M-003 起草将基于路径 C 全实证，包括本文三个 patch 的修订原则。 |

## §6 Stage 6.3 执行清单

### 6.1 M-000 v2.0 §6 第二段替换

- **文件**：`docs/meta/M-000-meta-vision.md`
- **操作**：将 §6 第二段（从「新增条款必须先证明无法下沉到 M-001~M-006、standards、skills、ADR、STATUS stub 或工具。若条款只是执行步骤、模板、例子、命令、检查脚本或当前状态，应下沉。」）全文替换为 P1 final 替换文本（见 §2）
- **line 范围**：在当前 ratified 版本中，第二段落起始于 "新增条款" 一句，结束于 "应下沉。" ——替换该段全部内容。替换后段落的起始行不变（保持与第一段空行间隔）
- **同步部分**：无需修改其他段落；需确认 frontmatter 中 `freshness` 字段
- **frontmatter 删除**：`default_word_budget: 2500` 已在 #015 同 PR 删除，不需额外操作
- **last_verified 刷新**：更新为 `2026-05-25`
- **decay_trigger 更新**：新增 `stage_6_ratified`（若未包含则追加）

### 6.2 M-005 v2 §B.1 追加第 5 条

- **文件**：`docs/meta/M-005-quality-criteria.md`
- **操作**：在 §B.1 触发信号清单末尾（第 4 条信号「thinking/reasoning 模式加剧的自我身份漏泄」之后）追加第 5 条信号文本（见 §4）
- **line 范围**：原 §B.1 结束于第 4 条信号的末行（含 "合规授权下 thinking 模式仍是有效推理。" 句）。在该句后空一行，追加第 5 条信号
- **last_verified 刷新**：更新为 `2026-05-25`

### 6.3 M-005 v2 §G 末尾追加 §G.5

- **文件**：`docs/meta/M-005-quality-criteria.md`
- **操作**：在 §G.4 末尾（「阈值注释：§G.2 与 §G.4 的误报率阈值均为 <20%……」段落后）追加 §G.5 全文（见 §3）
- **line 范围**：原 §G 结束于 §G.4 最后一个段落（阈值注释）。在该段落后追加新章节
- **last_verified 刷新**：更新为 `2026-05-25`

### 6.4 各文件 `last_verified` 刷新

| 文件 | 原值 | 新值 | 备注 |
|---|---|---|---|
| `docs/meta/M-000-meta-vision.md` | 2026-05-25 | 2026-05-25 | 仅替换段落不涉及全文重审，但 last_verified 刷新标记变更 |
| `docs/meta/M-005-quality-criteria.md` | 2026-05-25 | 2026-05-25 | 追加 §B.1 第 5 条 + §G.5，需刷新 |
| `docs/audits/path-c-stage6-reflection.md` | 2026-05-25 | 2026-05-25 | 作为本 patch 的依据，状态不变，可延后修改 |
| `docs/meta/user-decision-log.md` | 2026-05-25 | 2026-05-25 | 追加 #020 条目 |

### 6.5 执行顺序与验证

1. 在单独分支上完成以上三处修订
2. 运行 docaudit 验证 frontmatter schema / link integrity / skill provenance 通过（预期旧 §6 第二段被替换后未引起链接悬挂，§B.1 新增第 5 条不影响已有引用，§G.5 无交叉引用问题）
3. 确认无 `default_word_budget` 残留引用（已在 #015 清除）
4. 同 PR commit，merge 到主分支
5. Stage 6.3 完成后，路径 C Stage 6 正式关闭，进入 Stage 7 M-003 起草