---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 5 — 三方对抗共识报告（standards 约束力）

> **日期**：2026-05-21 | **维度**：5 standards 约束力（每条 docs/standards/*.md 规则是否真被 code/skill/CI 执行）| **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」+ 控制变量法精髓——三家完整扫 17 个 standards 文件 + grep/命令实证。[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (6 finding：2H/3M/1L)
> - Codex 桌面端：本会话上下文 (12 finding：0H/7M/4L/1I)
> - Antigravity：[`semantic-audit-dim5-findings.md`](semantic-audit-dim5-findings.md) (6 finding：1H/3M/2L)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D5-001 ~ S-D5-015

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 总 finding 数 | 6 | 12 | 6 |
| HIGH | 2 | 0 | 1 |
| MEDIUM | 3 | 7 | 3 |
| LOW | 1 | 4 | 2 |
| INFO | 0 | 1 | 0 |
| 工作流违规 | — | — | ✅ 无（守规矩） |

**形态对比**：
- **Codex** 偏「机械实证 + 数字精度」（skill 计数 / allowed-tools 矩阵 / grep 命令实跑 / CI 步骤对照）—— **覆盖广度最强**，维度 4+5 连续两轮最强单家
- **Claude CLI** 偏「元层级自指」（C5.5 制定规则的人不遵守规则 / C5.3+C5.4 collaboration audit_note 与实际工作流背离）—— 深度独家
- **Antigravity** 偏「代码 grep + skill 文件实证」+ 守规矩（提示词「严禁操作」段封堵成功）

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **3/3 全共识** | 1 | HIGH×1 |
| **2/3 共识** | 8 | HIGH×2 MEDIUM×5 LOW×1 |
| **1/3 单家可采纳** | 6 | MEDIUM×1 LOW×3 INFO×1 + Antigravity 独家 LOW×1 |
| **合计 OPEN** | **15** | HIGH×3 MEDIUM×8 LOW×3 INFO×1 |

## 3/3 全共识

### S-D5-001 [HIGH, 3/3] — permission-model ERE 正则 vs Python classifier

`permission-model.md §2 line 37`「`.claude/hooks/block-dangerous-bash.sh` 通过**单条 ERE 正则**拦截」+ §5 line 124 审计命令 `grep '^DANGEROUS_RE='` vs **实际脚本用 Python classifier**（line 29 `CLASSIFICATION=$(python3 - "$COMMAND" "$CURRENT_BRANCH" <<'PY'`）。审计命令直接 grep 不出来——SSOT 表述漂移 + 审计命令失效。

Antigravity 标 HIGH 取最严（Claude/Codex 标 MEDIUM）。

**修复**：重写 §2/§5 为「parser classifier + 测试用例/关键函数 grep」。

## 2/3 共识

### S-D5-007 [HIGH, 2/3 Claude+Codex] — collaboration audit_note 虚假合规

`collaboration.md:4` audit_note 自我声明「2026-05-19 验证 tool specs 与 codex-delegation / gemini-delegation 一致（gpt-5.5）」与正文 L15/16/47「**GPT-5.4 系列**」字面背离——audit_note 虚假合规声明，比单纯漂移更严重（元层级 audit_note 不该说谎）。

### S-D5-008 [HIGH, 2/3 Claude+Codex] — collaboration Antigravity fallback 定位 vs 实际工作流

`collaboration.md` 反复定位 Antigravity 为「Gemini CLI 的 fallback」（L19/35/37/101/141 共 5 处），但 Phase 10 实测 4 轮（dim1-4）全用 Antigravity 当主审之一，Gemini CLI 从未启用——standards 描述与实际工作流严重背离。

### S-D5-002 [MEDIUM, 2/3 Codex+Antigravity] — permission-model skill 矩阵 vs SKILL.md frontmatter 不一致

`xcode-review` 矩阵写 `Read,Grep,Glob,Write,Bash`，实际 SKILL.md frontmatter 只有 `Bash,Read,Grep`；`api-research` 实际多 `Grep`。

### S-D5-003 [MEDIUM, 2/3 Codex+Antigravity] — cross-audit-consensus --effort 残留

`codex-delegation.md:4` audit_note 声明「下游 cross-audit / cross-audit-consensus skill 已同步」+ L16/L26 说 effort 已移除，但 cross-audit-consensus/SKILL.md:81 + cross-audit/SKILL.md:32/50 **仍写 `--effort high`** —— audit_note 虚假合规。

### S-D5-004 [MEDIUM, 2/3 Codex+Antigravity] — harness-recall.md ## Risks 段不存在

harness-recall.md:24 要 `grep -A 50 '^## Risks' docs/memory/handoff.md`，但实跑 exit 1——handoff.md 已无 `## Risks` 段（**元层级 self-non-compliance + 审计命令漂移**）。

### S-D5-005 [MEDIUM, 2/3 Codex+Antigravity] — execution-gates 影子规则

`execution-gates.md §1` CI 门禁表只列 Docs Audit / Build & Test / SwiftLint，实际 `.github/workflows/ci.yml` 还有 `Validate docs frontmatter` (L80) + `Check Package Dependencies` (L86)——CI 真实门禁未完整登记。

### S-D5-006 [MEDIUM, 2/3 Claude+Codex] — coding ViewModel @MainActor 死规则

coding.md §并发「ViewModel 不需要 @MainActor」vs 实际 ViewModel 多处显式 @MainActor（DashboardAnalyticsViewModel:47 / DashboardViewModel:19 / CaptureViewModel:22 / ReviewViewModel:39 等，总仓 44 处）——死规则。

### S-D5-009 [LOW, 2/3 Claude+Codex] — 委派规范模型/工具漂移

codex-delegation.md 写 Codex CLI 0.130+ vs Phase 10 实际用 **Codex 桌面端**；gemini-delegation 写 gemini-3-pro-preview vs 实际用 Antigravity Gemini 3.5 Flash——委派规范落后于 ADR-005 §模型版本注。

## 1/3 单家可采纳

### S-D5-010 [MEDIUM, 1/3 Claude 独家] — 元层级 self-non-compliance（制定规则的人不遵守自己规则）

codex-delegation §2 / gemini-delegation §2 强制要求「构造委派 prompt 前先读取 `shared-constraints.md` 并将其全文内联到 prompt 中」，但 `single-vendor-audit-prompt-template.md` **没全文内联 shared-constraints.md**，只在「参考基线」列了路径。

与维度 3 元教训呼应——制定规则的人不遵守自己规则的样本又一例。

### Codex 独家（4 项）

| ID | Sev | 描述 |
|---|---|---|
| S-D5-011 | MEDIUM | permission-model skill 计数 54 distinct / 14 governance / 40 community vs 实测 52 / 15 / 漏 snapshot-diff-review |
| S-D5-012 | LOW | coding §禁止 any existentials vs 实际 `any ProEntitlementProvider` 不在 3 例外内 |
| S-D5-013 | LOW | execution-gates rule-usage 实跑 F-004 has 0 external references — dead rule |
| S-D5-014 | INFO | apple-native/ux-design accessibility 强约束无 lint/CI audit 支撑 — 人审规则未机械化 |

### Antigravity 独家（1 项）

| ID | Sev | 描述 |
|---|---|---|
| S-D5-015 | LOW | testing.md §Snapshot 视觉回归 line 88 「nonisolated XCTestCase ... 与 defaultIsolation(MainActor) 冲突」描述 vs 实际测试已全量迁移到 Swift Testing @Suite + struct |

## 实证合规（基线，不是 finding）

- ✅ `swiftlint force_unwrapping: error` 真实
- ✅ 全仓 .swift < 600 行（file_length 限制合规）
- ✅ 业务代码无裸 `print()`（仅 DataSeeder 题干字符串）
- ✅ 业务代码 `nonisolated(unsafe)` 严格 4 处（DataExecutor / DataConcurrencyTests / CameraSessionManager / PDFPagePickerView），与 coding.md §nonisolated(unsafe)「当前 4 处」声明一致——**这是少有的精确实证合规**
- ✅ `settings.json` 11 个活跃 hook 与 permission-model §3 一致
- ✅ `audit-rubric` EXTERNAL_GAP/VALID_WITH_GAP 在 ledger 命中 31 次
- ✅ `testing.md` 禁止 swift test → CI 用 xcodebuild
- ✅ `docaudit all --strict --baseline` exit 0（机械门禁整体健康）

## Gemini 3.5 over-endorse 持续监控（维度 5 数据点）

| 指标 | 维度 1 | 维度 2 | 维度 3 | 维度 4 | 维度 5 |
|---|---|---|---|---|---|
| HIGH 占比 | 33% | 17% | 17% | 40% | 17% (1/6) |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 独家深度 finding | ✅ Dynamic Type | ✅ CSV vs Image | ✅ H2 vs SM-2 | ✅ 通知 ID 物理覆盖 | ✅ testing @Suite 描述漂移 |
| 误判数 | 2 | 0 | 0 | 0 | 0 |
| 工作流违规 | — | — | ⚠️ 抢跑 | ✅ 守规矩 | ✅ 守规矩 |

**累计结论**：Gemini 3.5 五轮实测**未复现 over-endorse 病灶**。维度 4-5 连续两轮工作流守规矩，证明改进提示词模板（「严禁操作」段）封堵成功。

## 单家排名（维度 5）

| 排名 | 单家 | 角色 |
|---|---|---|
| 1 | **Codex** | 大爆发——12 项里 5 项独家（skill 计数 / any existentials / F-004 dead / accessibility / harness-recall ## Risks）。维度 4+5 连续两轮最强 |
| 2 | Antigravity | 守规矩，1 项独家（testing.md @Suite 描述漂移）|
| 3 | Claude CLI | 元层级独家 1 项（C5.5 制定者不遵守自己规则），覆盖广度不足 |

## Claude CLI 维度 5 局限标注

Claude CLI 这一轮**两次跑维度 5**：第一次只扫 5/17 文件偷懒，被用户纠正后重跑完整 17 文件。但即使完整扫，**机械实证广度仍不如 Codex**——Codex 抓的 skill 计数 / allowed-tools 矩阵 / any existentials / F-004 dead rule / accessibility 死规则 / execution-gates 影子规则 / harness-recall ## Risks 都是大范围 grep + 跨文件实证才能发现的，Claude 在这类任务上有上下文/时间约束。

**控制变量法暴露的模型差异**：
- Claude CLI 在大范围机械实证类任务上不如 Codex 系统
- 但 Claude CLI 元层级自指能力强（C5.5 是 Codex/Antigravity 都漏的元层级独家）
- 互补性强：Codex 广度 + Antigravity 代码层 grep + Claude 元层级 = 三家配齐才能覆盖维度 5 全貌

## 下一步

1. **本会话**：commit + push（ledger + dim5-consensus + ADR-005 维度 5 行 + STATUS/handoff）
2. **下一会话**：维度 6「skill description ↔ body 一致性」，**Claude CLI 完整跑 52 个 skill** → 起草提示词 → Codex/Antigravity 跑
3. **累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) + 维度 4 (11) + 维度 5 (15) = **69 项**
