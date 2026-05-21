---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-002 三方修复方案 — Cross-Fix-Consensus

> Phase 11 B 方案串行第二战收尾（**F-005 PR review 留痕机械化**）。
> Claude CLI 主笔，融合 **Codex 字段化 schema** + Antigravity 占位符防御 + Claude 盲区清单。
>
> 单家产出：[claude](S-D7-002-claude.md) · [codex](S-D7-002-codex.md) · [antigravity](S-D7-002-antigravity.md)
> 任务定义书：[S-D7-002-fix-task-definition.md](S-D7-002-fix-task-definition.md)

## 1. 三家共识（3/3 命中）

| 共识点 | 内容 |
|---|---|
| 强化路径 | CI step + 本地 hook 双层（不依赖 GitHub Branch Protection，Free repo 限制）|
| 检测时机 | `gh pr merge` 前阻断为主，CI 阻断为兜底 |
| 历史 PR 处理 | 不追溯，新 PR 起机械化 |
| 直推 develop | 不豁免；现有 ALLOW_DIRECT_PUSH 需附加额外 trace 校验路径 |
| docs-only 豁免 | 可豁免外部 review，但必须有路径白名单 + 黑名单双层校验 |
| 联动 S-D7-003 | 共享 Python 检查器框架命名约定 |

## 2. 三家差异点对比

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| **PR body 格式** | 段头匹配（`## Codex Review` 等，1 个 marker 即过）| **字段化 schema**（`Review Required: yes` 严格 key:value）| HTML 注释包裹 + checkbox `[x]` 符号 |
| **豁免精度** | yaml 三层（paths_only/labels/paths_not_exempt）| **字段化 `Review Exemption: docs-only\|trivial` + denied/allowed globs** | 正则黑白名单 + `[skip review] 理由:` 紧急逃逸 |
| **占位符防御** | 未触及 | Evidence 非空 + 接受 verdicts 集合 | **`placeholder_pattern` 防 `[填写`/`tbd`/`...`**（独家）|
| **UI 改动联动** | 未触及 | **`ui_review.path_globs` 触发 Xcode Review 必填** | 自动检测 `View.swift\|Assets.xcassets` 强制 Xcode Review |
| **直推 develop** | SKIP_REVIEW_TRACE + ALLOW_DIRECT_PUSH 双 override | **ALLOW_DIRECT_PUSH + commit msg trailer `F-005-Review-Trace:` + CI push event 兜底** | pre-push 扫 `[review-by: codex & gemini]` |
| **实现规范度** | 段头 marker 自由文本 | **完整 policy YAML + 字段化 Python + CI + template + skill** | HTML 注释 + 完整 workflow |
| **测试规范度** | 5 场景描述 | **4 个 unittest + mock + monkeypatch**（最规范）| 4 场景描述 |
| **联动 S-D7-003** | 共享 hook 框架命名约定 | 预留 `pr_governance_check.py` 框架但保持单职责 | 直接展望 `contract_and_review_gate.py` 统一引擎 |
| **盲区诚实度** | **7 触发器最全** | 8 条 | 3 条但深度 |

## 3. 综合裁决

### 评分矩阵（1-5 分）

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| 正确性 | 4 | 5 | 5 |
| PR body 格式严谨度 | 3（自由格式段头）| **5**（字段化 schema）| 4（HTML 注释 + checkbox）|
| 豁免精度 | 4 | **5** | 4 |
| 占位符防御 | 2 | 4 | **5**（placeholder_pattern 独家）|
| UI 改动联动 | 2 | **5** | 4 |
| 直推 develop 处理 | 4 | **5**（CI push trailer 兜底）| 4 |
| 实现完整度 | 4 | **5** | 4 |
| 测试规范度 | 3 | **5**（unittest + mock）| 4 |
| 与 S-D7-003 联动 | 4 | 4 | 4 |
| 盲区诚实度 | **5**（7 触发器最全）| 4 | 4 |
| 实证强度 | 2 | 3 | 2 |
| **总分** | **37** | **51** | **45** |

### 最强方案：**Codex 字段化 schema 基础 + Antigravity 占位符防御 + Claude 盲区清单**

**Codex 显著胜出**理由：
1. **字段化 schema**（`Review Required: yes / Review Scope: full-pr / Codex Review: PASS / Codex Evidence: <URL> / ...`）远比段头匹配或 checkbox 严格——每个字段都可机器解析、可验证
2. **完整 unittest + mock 测试**（其他两家只描述场景）
3. **UI 改动 `ui_review.path_globs` 联动 Xcode Review 必填** 最完整
4. **CI push 事件 trailer `F-005-Review-Trace:`** 兜底直推
5. **policy YAML 设计** 最规范（required_fields / accepted_verdicts / exemptions）
6. **audit mode** 历史 PR 抽样能力预留

### 采纳 Antigravity 增强

- **占位符防御正则**（`placeholder_pattern` 防 `[填写`/`tbd`/`...` 等模板占位符）—— 独家创新，融合到 Codex 字段化 schema 的 Evidence 字段校验中
- **`[skip review] 理由:` 紧急逃逸**作为额外路径（与 Codex Review Exemption 互补——后者是机器可读豁免，前者是人工签字）

### 采纳 Claude 增强

- **7 条 future-proof 盲区清单** 最细致——融入 §6

### 共识舍弃

- **Claude 段头格式**（`## Codex Review`）：自由度高但难以字段化校验
- **Antigravity HTML 注释边界**：与 Codex 字段化 schema 重叠，选 Codex 更易解析

## 4. 融合方案（最终 apply）

### 4.1 文件清单

| 文件 | 操作 |
|---|---|
| `.github/review-trace-policy.yml` | **新增**（Codex schema + Antigravity 占位符）|
| `Scripts/audit/pr_review_trace.py` | **新增**（Codex 字段化 + Antigravity placeholder 防御）|
| `Scripts/audit/tests/test_pr_review_trace.py` | **新增**（Codex unittest 模式）|
| `.claude/hooks/premerge-checklist.sh` | **扩展**（Codex diff）|
| `.github/workflows/ci.yml` | **扩展**（review-trace + direct-push-review-trace jobs）|
| `.github/PULL_REQUEST_TEMPLATE.md` | **重写 Review 段**（Codex 字段化模板）|
| `.claude/skills/cross-audit/SKILL.md` | **扩展**（F-005 输出步骤）|
| `.claude/skills/sprint-contract/SKILL.md` | **扩展**（PR body Review Trace 占位）|
| `docs/workflow.md` | **不改**（F-005 段保持纪律强度，不能因落地难度松绑）|

### 4.2 关键技术要素融合

```yaml
# .github/review-trace-policy.yml
version: 1
required_section: "## F-005 Review Trace"

required_fields:
  - Review Required
  - Review Scope
  - Human Merge Approval

normal_review:
  review_required: "yes"
  required_fields: [Codex Review, Codex Evidence, Findings Resolved]
  accepted_verdicts: [PASS, PASS_WITH_FINDINGS]
  optional_review_fields: [Gemini Review, Xcode Review]
  # Antigravity 增强：占位符防御
  placeholder_patterns:
    - "\\[填[写入]"
    - "\\[填入"
    - "tbd"
    - "TBD"
    - "TODO"
    - "placeholder"
    - "^\\.\\.\\.$"
    - "^x$"
    - "^xxx+$"

ui_review:
  path_globs:
    - "Packages/SnapDrillFeatures/Sources/**/*.swift"
    - "Packages/SnapDrillUI/Sources/**/*.swift"
    - "SnapDrill/**/*.swift"
  required_fields: [Xcode Review, Xcode Evidence]

exemptions:
  docs-only:
    allowed_globs: ["docs/**/*.md", "*.md"]
    denied_globs:
      - "docs/workflow.md"
      - "docs/standards/**"
      - "docs/audits/**consensus*.md"
      - "docs/decisions/ADR-*.md"
  trivial:
    max_files: 1
    allowed_globs: ["docs/**/*.md", "*.md"]
    denied_globs:
      - "Packages/**"
      - "SnapDrill/**"
      - ".github/**"
      - ".claude/**"
      - "Scripts/**"
      - "*.xcodeproj/**"
      - "*.xcconfig"
      - ".swiftlint.yml"
      - "Package.swift"
      - "fastlane/**"
```

## 5. Apply 计划

1. ✅ 写本 consensus 文件
2. apply policy YAML + Python 校验器 (Codex + Antigravity 占位符融合)
3. apply unittest 测试套件
4. apply premerge-checklist.sh 扩展
5. apply ci.yml review-trace + direct-push job
6. apply PR template 字段化
7. apply cross-audit / sprint-contract skill F-005 输出步骤
8. 跑 unittest + docaudit
9. ledger 翻面 S-D7-002 OPEN → RESOLVED
10. commit + push + 清 worktree

## 6. 已知盲区（融合三家 + 实战补充，7 条 future-proof）

| 盲区 | 处理 |
|---|---|
| GitHub Web UI 合并绕过本地 hook | 远端 CI required check 配合（Free repo 限制需用户每次手动 enforce）|
| `ALLOW_DIRECT_PUSH=1` 绕过本地 pre-push | 远端 push event CI 补救（失败但已 push）+ 双 override 设计 |
| 格式不规范的合规 review 被拒 | 假阳性可接受成本，换机械可审计 |
| 高质量 Evidence URL 形式合规但内容空 | 字段非空 + 占位符防御只能检语法；语义质量仍需 cross-audit/human review 抽检 |
| docs-only path globs 重命名/generated docs 误判 | policy YAML 维护 |
| gh CLI / API 字段变化 | CI fix `gh` version 或 REST API fallback |
| S-D7-003 共享框架时 schema 冲突风险 | 本任务保持 `pr_review_trace.py` 单职责，S-D7-003 引入 `pr_governance_check.py` orchestrator |

## 7. Phase 11 串行第二战工作流观察

| 项 | 评价 |
|---|---|
| 物理隔离效果 | ✅ 三家产出 7 项设计决策真实分歧（格式 / 占位符 / 直推处理）|
| 用户决策调整为串行 | ✅ S-D4-001 落地后再启 S-D7-002，避免共享 hook 框架空想式协同 |
| 模型差异化能力 | ✅ Codex 严谨工程化 / Antigravity 防御性正则 / Claude 盲区清单——三种风格清晰互补 |
| 共享框架启动时机 | ✅ 本任务保留 pr_review_trace.py 单职责，S-D7-003 启动时按需引入 orchestrator |

## 8. 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- [S-D4-001-fix-consensus](S-D4-001-fix-consensus.md) Phase 11 第三战参考
- `docs/memory/feedback.md` F-005
- `docs/workflow.md` §对抗性审查（**不改**，保持纪律强度）
- 联动：[S-D7-003 任务定义书](S-D7-003-fix-task-definition.md) — 下一战
