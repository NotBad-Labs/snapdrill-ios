---
last_verified: 2026-04-22
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-22 — 自主迭代系统 Phase C 基线清洁收官

## Goal

执行 Phase A 三方独立审计发现的 Critical / High / Medium 修复（见 `~/.claude/plans/phase-b-consensus-20260421.md`），完成 Phase B 基础设施建成后的第一次实战验证。

## Done（5 PR + 1 本地清理）

| PR | SHA | 内容 |
|---|---|---|
| #715 PR-α1 | 85b1c10f | FR-01: F-020 合并入 F-005《Auto mode 强化》段；FB-01: Claude 私有 feedback_codex_report_timeout 合并退役（不入 git） |
| #717 PR-α2 | 1796f758 | RS-01/RS-02: `docs/research/` → `docs/archive/research/` + 19 处硬引用修复 + docaudit basename 匹配移除（顺手修 Issue #710 High 3）+ 新测试 |
| #719 PR-β | e3d70033 | FR-02: F-007/F-015 合并为《CI 双时点门禁》（pre-merge + post-merge）+ Gemini Point 2（抽出快照层 CI 配置指向 workflow.yml SSOT）；MAP-01: KNOWLEDGE_MAP ↔ DOC_DEPENDENCY_MAP 互链 |
| #721 PR-δ | d062a4cf | FR-04: F-003/F-009/F-010 墓碑 + 目标文档补齐 F-003/F-010 内容（Gemini 抓 "空墓碑" hardship）+ handoff 计数修正 15+5；FB-04: 私有 audit 纪律退役（会话内） |
| PR-γ（本 PR） | TBD | 本地 `~/.claude/plans/` 清理：删 8 失效 / 归档 15 到 `~/.claude/plans/archive/` / 保留 4 UNCERTAIN + phase-b-consensus |

## Phase A→B→C 链路

```
Phase A 摸底审计（2026-04-21）
    ↓
    Critical 3 + High 8 + Medium 13 + Low 9
    Consensus 归档：~/.claude/plans/phase-b-consensus-20260421.md
    ↓
Phase B 基础设施建成（3 PR，2026-04-21~22）
    ↓
    PR-1 #709: docaudit 引擎 + policy.yaml SSOT + 29 self-test
    PR-2 #712: CI docs job（ubuntu-latest）+ PostToolUse/PreToolUse hooks + /knowledge-health skill
    PR-3 #713: workflow 审计命中处置协议 + memory-routing + PR 模板留痕
    ↓
Phase C 基线清洁实战（5 PR，2026-04-22）← 本 phase
    ↓
    PR-α1 / α2 / β / δ / γ 逐个落地，Phase B 基础设施首次验证
```

## Decisions

- **墓碑 > 物理删除**：所有退役 F 规则保留编号作为墓碑指针（F-003/F-009/F-010/F-015/F-020），避免历史 checkpoints/handoff/api-pitfalls/STATUS 外部引用断链
- **archived_sources 语义改为旧路径检测**（PR-α2）：research 迁移后 archived_sources 指向旧路径（`docs/research/*`）作为 deprecated path 硬编码检测，新路径（`docs/archive/research/*`）合法叙述引用不触发
- **docaudit basename 匹配移除**（PR-α2）：解决 Issue #710 High 3，完整路径匹配更精确，避免新归档路径被误判
- **legacy_whitelist 彻底清理**（PR-α2）：Phase A 的 archived-refs 18/16 处豁免全部真修复后，条目整条删除（体现 Phase C 清理 PR 的纪律：每个 PR 同步移除对应白名单条目）
- **F-002 作为 meta-principle 保留**：rule-usage 会标 0 external ref 但不退役（隐性最高原则"产品文档优先"的特性就是没人显式引用）
- **CI 双时点门禁**：F-007 扩展为 pre-merge（原 F-015 "CI 失败立即阻塞"）+ post-merge（原 F-007 "合并后必须检查 CI"），含"合并前所有 CI check 都绿（具体配置指向 ci.yml SSOT，不在规则硬编码）"
- **γ 不是代码 PR**：本地 plans 清理产物（8 删 / 15 归档）不入 git，只 checkpoint 入 git 作为交接记录

## Risks

- **Gemini 429 频发**：本 phase 多次 Gemini 3-pro-preview API rate limit，降级到 Flash / 2.5-pro 也耗尽。影响：PR-α2/PR-β/PR-δ 的 Gemini 次锚 Review 时间分散，部分 review 偏短（但都给出了实质发现）
- **codex-companion 笔记本挂起**：PR-2 Codex 第二轮复核 stall 于合盖期间；已固化 `feedback_laptop_lid_agent_stall.md`
- **Mac mini runner half-broken**：PR #712 build queue 卡死 40+ min，SSH `svc.sh stop && start` 修复；已固化 `reference_runner_halfbroken_diagnosis.md`
- **F-002 未来可能真的 dead**：docaudit rule-usage 始终标 0 ref，若未来人手审计判定确实过时，可以改墓碑；当前保留是有理由的决定

## Next

### 立即（本 session 内可能完成）

- [ ] PR-γ 合并（当前 PR）
- [ ] `/knowledge-health` skill 首次实测（/phase-closeout 建议跑一次）

### 短期（Phase D 规划）

Consensus Phase D 是 "建第一批技术 Skills（Swift 6.3 / SwiftData / iOS 26 / Architecture）"，范围要重新设计。Phase C 过程中发现的 follow-up：

- Issue #710：Gemini Review 的 3 High + 3 Low（Markdown 正则鲁棒性加固）— Phase C PR-α2 已修 1 个（basename），剩 2 个 High + 3 Low
- `validate_frontmatter.py` 扩展识别墓碑标签（Gemini PR-α1 建议）
- `rule-usage` 语义感知：区分规范性引用 vs 实战引用（Gemini PR-α2 建议）

### 长期（Phase E 规划）

Consensus Phase E 是 "建自省 skill（月度/按需体检 + 闭环机制）"。Phase B `/knowledge-health` 已部分覆盖，但需闭环机制。

## Metrics

| 维度 | 数值 |
|---|---|
| Phase 持续 | 2026-04-22 一天内（Phase B 结束后立即） |
| 合并 PR | 5（α1/α2/β/δ/γ） |
| 涉及 file | ~30 个（含 17 文件引用替换 + 4 feedback F 规则改写 + 2 MAP 互链 + docaudit + policy + tests + archive README + checkpoint） |
| 本地 plans 清理 | 28 → 5 + 15 archive |
| F 规则活跃/退役 | 15 活跃 + 5 退役（Phase 前 20 活跃） |
| docaudit 基线 | `all --strict --baseline` exit 0（Phase A 16 archived-refs + 47 home-path-refs + 1 orphan + 5 dead rule 全部处置） |
| 三方 Review 轮次 | 平均每 PR 1.5 轮 Codex + 1 轮 Gemini（Gemini 429 频繁降级） |
| Session 时长 | 估算 8 小时（跨 Phase B 合并后立即接续） |

## 方法论反思

- **三方独立起草的实证价值再次验证**：PR-δ 中 Gemini 次锚发现 Codex 主锚漏的 2 个 Critical（墓碑内容缺失），证明 F-008 "相同完整任务不分工" 纪律在 Review 阶段同样有效 — 不是 Codex 总比 Gemini 强
- **墓碑机制 vs 物理删除**：consensus 起草时没明确讨论，Phase C 实战中发现墓碑保外部引用追溯的价值巨大（否则 5 处引用会突然 broken）
- **"空墓碑" 是需要警惕的反模式**：PR-δ 首轮我写了 3 个墓碑都声明"已落地到 X"，但实际 X 里缺失内容。Gemini 抓出后补齐。这是规则迁移的正确做法：先 verify 目标，再写墓碑
- **Mac mini runner + 笔记本合盖是本地工具链脆弱点**：已固化 memory；建议长期跑 Phase 级工作时用 `caffeinate` 或固定电源

## Phase A/B/C 全链路收官

Phase B 基础设施（docaudit + hooks + skill + workflow 协议）首次在 Phase C 实战中全量使用：
- `docaudit all --strict --baseline` 作为每个 PR 的准入条件（本地 + CI 两层）
- `legacy_whitelist` finding 级 post-filter 在 PR-α2 前 archived-refs 命中被精准豁免，PR-α2 后 legacy_whitelist 条目移除的纪律被遵守
- `/knowledge-health` 暂未实测（下 phase 启动）
- workflow 审计命中处置协议被 PR-α2/PR-β/PR-δ 合理引用

机制真实可用，不是摆设。Phase B 投入产出比正向。

---

**下一步决策权在用户**：是否立即启动 Phase D 或保留当前稳定状态一段时间观察。
