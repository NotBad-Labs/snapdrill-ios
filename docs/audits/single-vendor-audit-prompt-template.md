---
last_verified: 2026-05-21
layer: pattern
---
# 单家语义审计提示词模板（Phase 10 维度 4-7 适用）

> 用于 Codex 桌面端 / Antigravity 等 GUI 单家工具的标准提示词。
> 触发于 ADR-005 §7 个语义维度实施清单的维度 4-7。
> 设计原因：维度 3 Antigravity 出现「抢跑落档」工作流违规——未等三方齐就独立写 ledger / STATUS / handoff / ADR-005；改进提示词加「严禁操作」段封堵。

## 工作流纪律（维度 4 沉淀，维度 5-7 适用）

**「Claude CLI 先跑 → 起草提示词 → Codex/Antigravity 跑」**

执行顺序：
1. **Claude CLI 先跑**该维度的独立 finding（盲审，不参考他家）
2. **Claude CLI 起草**给 Codex/Antigravity 的提示词（基于本模板），针对该维度盲区做差异化引导
3. **用户触发**外审（Codex 桌面端 + Antigravity）
4. **Claude CLI 主笔**三方 cross-audit-consensus 折叠 + 落档（ledger + 共识报告 + STATUS/handoff/ADR-005）

理由：
- Claude CLI 先跑保证盲审独立性，避免被 Antigravity/Codex 输出污染
- 提示词由 Claude CLI 起草，可针对性圈定该维度的视角盲区（Claude CLI 已审完知道自己漏了什么角度）
- F-008「相同完整任务、不分工」纪律继续适用——外审三家各审完整任务，但 Claude CLI 的「先跑」是流程顺序，非分工切片
- Codex/Antigravity 后跑可参考 Claude CLI 输出做差异化扩展（实际工作流难做到完全盲审）

## 标准模板（复制贴 Codex / Antigravity）

```text
以三方对抗模式审计 SnapDrill 文档体系语义层【维度 N：XXX】。

仓库：/Users/yiming/Developer/snapdrill-ios
范围：[根据维度填写具体文件清单]

任务：[具体审计任务，引用 ADR-005 §7 个语义维度实施清单的判据列]

输出要求：
- 输出 finding 清单（每条含 防线锚点 / 违反点 / 严重度 / 类型 / 推荐处理）
- 可选：写一份单家原始报告到 docs/audits/semantic-audit-dimN-findings.md
  （仅你这家的 finding，不做折叠；文件头必须带 frontmatter:
   ---
   last_verified: 2026-05-20
   layer: snapshot
   freshness:
     max_age_days: 30
     decay_trigger: [pr_merge]
   ---
  ）

==== 严禁操作（关键，违反会被回退）====
1. 禁止修改 docs/audits/audit-ledger-semantic-2026-05.tsv
   原因：ledger 是三方共识落档，必须等三家齐了由 Claude CLI 主笔做
   cross-audit-consensus 后统一追加。
2. 禁止修改 STATUS.md / docs/memory/handoff.md
   原因：状态滚动由 Claude CLI 在共识收尾时统一同步。
3. 禁止修改 docs/decisions/ADR-005-doc-semantic-layer-audit.md
   原因：§7 个语义维度实施清单 / §维度 N 收官观察 / 状态字段均由
   Claude CLI 共识收尾时回填。
4. 禁止指向「下一维度」或修改「下一会话方向」
5. 禁止在 ledger 或任何文件写「✅ 已完成 / 已收官」类终态标记

==== F-008 纪律 ====
完整覆盖任务范围，不分工不切片。
独立产出，不参考其他家的输出（参考基线除外）。
不要重复列入维度 1-(N-1) 已有的 finding（参考 ledger S-D*-* 编号）。

==== 参考基线（只读）====
- docs/audits/audit-ledger-semantic-2026-05.tsv
- docs/audits/semantic-audit-dim1-consensus.md
- docs/audits/semantic-audit-dim2-consensus.md
- docs/audits/semantic-audit-dim3-consensus.md (维度 4 启动时)
- docs/audits/semantic-audit-dim4-consensus.md (维度 5 启动时)
- docs/decisions/ADR-005-doc-semantic-layer-audit.md
```

## 适配各维度的模板填充

| 维度 N | 范围 | 任务 |
|---|---|---|
| 4 技术↔产品对齐 | docs/tech/architecture.md / non-functional-requirements.md + 代码 (Packages/SnapDrillCore + SnapDrillData) | tech 决策是否真服务「采集 → 管理 → 导出」价值链；偏离需 ADR 解释 |
| 5 standards 约束力 | docs/standards/*.md (~15 文件) + code/skill/CI 实证 | 每条 standards/*.md 规则是否真被 code/skill/CI 执行（grep 触发证据，不仅引用）|
| 6 skill desc↔body | .claude/skills/ + .agents/skills/ (~52 个 skill) | description 和 body 是否同义；14 governance + 21 Claude-only + 16 shared 全量逐个核对 |
| 7 F-rule 遵守度 | docs/memory/feedback.md (F-001 ~ F-019) + git log | 每条 F-rule 在 git log 是否真有触发证据；空载 F-rule 标候选废止 |

## 历史回溯

- 维度 1-2 提示词没有「严禁操作」段，但因为 Codex 桌面端工作模式偏文本输出、Antigravity 维度 1-2 也只是写单家报告未抢跑，未触发问题
- 维度 3 Antigravity 抢跑写 ledger + ADR-005 + STATUS + handoff，触发本模板创建
- 维度 4 「严禁操作」段首次正式使用，Antigravity + Codex 都守规矩，**封堵成功**
- 维度 4 「Claude CLI 先跑」工作流纪律首次沉淀（本会话提议 + 落档），维度 5-7 适用

## 关联

- [[ADR-005-doc-semantic-layer-audit]] §维度 3 收官观察 / §文档新陈代谢约束
- [[audit-ledger-semantic-2026-05]] 共识 ledger SSOT
- [[F-008]] 「相同完整任务、不分工」纪律
