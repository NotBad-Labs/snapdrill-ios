---
last_verified: 2026-05-26
layer: snapshot
scope: audit
derived_from: [M-003 §11]
freshness:
  max_age_days: 180
  decay_trigger: [upstream_swiftui_pro_update, skill_reselect]
---
# Goal H6 — skill-links 26 error 上游策略决策（2026-05-26）

> Goal H 健康度收敛 sprint H6。**结论**：长期豁免（2026-12-31），半年复审。

## 1. 真实问题（grep verify）

`.agents/skills/swiftui-pro/SKILL.md` 第 139-185 行**裸文件名引用** 4 个文件：

```
+- Read body-reevaluation.md
+- Read lazy-loading.md
+- Read view-identity.md
+- Read common-pitfalls.md
| `Self._printChanges()` | iOS 15 | body-reevaluation.md |
| `@Observable` | iOS 17 / macOS 14 | body-reevaluation.md |
[... 共 26 处引用 ...]
```

`.agents/skills/swiftui-pro/references/` 实际含 9 个不同的 references：
```
accessibility.md / api.md / data.md / design.md / hygiene.md /
navigation.md / performance.md / swift.md / views.md
```

**实际 broken_skill_ref**：`body-reevaluation` / `lazy-loading` / `view-identity` / `common-pitfalls` 4 个文件**不存在**于 references/。

## 2. 根因

来源：`twostraws/swiftui-agent-skill` 上游仓库（commit `db6c88d8...` skills-lock.json `computedHash`）。**上游 SKILL.md 写了引用但实际未创建对应 references 文件** —— 上游 bug，本地无 SSOT 控制权。

## 3. 三选一决策矩阵

| 方案 | 可行性 | 成本 | 风险 |
|---|---|---|---|
| (a) 修上游 PR | ⚠️ 不可控 | 需 fork + 写 4 文件 + 等 upstream merge | PR 接受时间未知；twostraws 活跃度不可控 |
| (b) 修本地 SKILL.md | ❌ 破坏 lockfile | 改 SKILL.md 引用 → blob 改变 → `managed_local_blob_mismatch` | 与 path-d / Goal D 修复机制冲突；每次上游 sync 都会重复 |
| (c) 长期豁免 + 半年复审 | ✅ 可行 | 改 policy.yaml expires_on + audit 报告说明 | 26 errors 长期 suppressed；如上游修了则 docaudit 自动通过 |

## 4. 决策：**Option (c) 长期豁免**

**修改**：`Scripts/audit/policy.yaml` legacy_whitelist 中 skill-links 豁免：
- `expires_on: 2026-06-30` → `expires_on: 2026-12-31`（半年复审）
- reason 字段升级：明确标注上游 bug + 本地无控制权 + 修本地会破坏 blob

**触发复审条件**：
- 2026-12-31 expires_on 自然到期
- `decay_trigger: upstream_swiftui_pro_update`（如 twostraws 发布新版本）
- `decay_trigger: skill_reselect`（如决定换其他 swiftui skill 替代 twostraws）

## 5. 副作用与边界

- ✅ docaudit `--strict --baseline` 模式继续 exit 0（豁免有效）
- ✅ 不破坏 skill-provenance check（不修 SKILL.md = blob 不变）
- ⚠️ swiftui-pro 在实际使用时引用到 broken refs 会失败（用户读 SKILL.md 看到「Read body-reevaluation.md」会找不到文件）
  - 缓解：审视使用模式 — 如果 swiftui-pro 实际未在 production agent loop 中被 read，则影响最小
  - 缓解 B：在 docs/standards/skill-source-ledger.md tdd-feature 等条目附近加注「swiftui-pro 上游 references 不全，使用时跳过裸文件名引用」

## 6. 后续 follow-up

- 2026-06 / 2026-12 复审时：grep `twostraws/swiftui-agent-skill` GitHub 看 4 个 references 是否被补
- 如上游不补，考虑：
  - Fork twostraws 并独立维护
  - 或换其他 swiftui skill（社区有多个）
  - 或自建 `.claude/skills/swiftui-snapdrill/` 替代

## 7. 元层级注记

skill-provenance + skill-links 两个 check 共同治理上游 community skill 完整性，但**上游 bug 是不可控变量**：
- skill-provenance：blob hash 校验（防本地误改）
- skill-links：引用完整性（防上游 SKILL.md 引用不到位）

理想做法是 fork community skill 后本地维护，但成本极高。**当前阶段优先豁免 + 监控复审节奏**，避免治理过度。

---

*主笔: Claude Opus 4.7 (1M context) | 2026-05-26 Goal H6*
*引用: docs/audits/h7-standards-content-audit-20260526.md / docs/standards/skill-source-ledger.md / Scripts/audit/policy.yaml*
