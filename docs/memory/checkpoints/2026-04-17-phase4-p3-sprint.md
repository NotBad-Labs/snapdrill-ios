---
last_verified: 2026-04-17
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-17 Phase 4 P3 Sprint

## Goal

执行 `~/.claude/plans/doc-audit-summary.md` + `~/.claude/plans/warm-sleeping-peach.md` P3 高优先级条目：文档 frontmatter 标准化、大文件分层拆分、运行时门（hooks）、端上 AI PoC（#626）。

## Done

| PR | 主题 | 关键改动 |
|---|---|---|
| #656 | ADR-003 YAML 5-layer schema | `docs/decisions/ADR-003-yaml-frontmatter-schema.md`：`last_verified` + `layer` + `freshness` + `status` + `reason` 的正式决策 |
| #657 | Step 2+3 YAML 迁移 | `docs/` 全 40 md 文件 HTML frontmatter → YAML frontmatter 一次性迁移 |
| #658 | Step 4 Scripts + CI 校验门 | `Scripts/migrate_to_yaml_frontmatter.py` + `Scripts/validate_frontmatter.py` + `.github/workflows/ci.yml` 校验 step（含 PyYAML 自动安装修复） |
| #659 | PR-I-W1 备份铁律拆分 | `product-cases.md` 备份铁律按 vision / req / cases 三层拆分（Codex 方案），cases 加 `[Boundary]` 验收条 |
| #660 | PR-I-W2 隐私五层拆分 | 隐私原则按 vision / req / compl / business / design 五层拆（混合：vision/req/compl 用 Codex 方案，business/design 用 Claude 方案） |
| #661 | PR-I-I1 冲突裁决唯一源 | `product-design.md` 改指针引用 `product-vision.md` 的冲突裁决章节，消除双源 |
| #662 | #540 Claude Code hooks | 4 个运行时门：`swift-autolint.sh` / `block-dangerous-bash.sh` / `premerge-checklist.sh` / `prepush-lint.sh` + `.claude/settings.json` 注册 |
| #663 | #626 QuestionSplittingService PoC | `Packages/SnapDrillCore`：Service + Protocol + Mock + FoundationModels `@Generable` schema + 单测；`nonisolated struct` 在 Swift 6.3 + defaultIsolation(MainActor) 下合法验证 |

## Open

- #626 PoC 真机准确率验证（≥ 80% 边界识别 Go 条件）—— 需 iOS 26 真机 + Apple Intelligence
- Issue #666 swift-autolint 文件级 vs 行级方案 B（拆 LocalizationKeys 1503 行）待排期

## Decisions

- YAML frontmatter 作为全仓 SSOT（HTML 注释方式淘汰），校验由 CI + 可选 pre-commit 双层
- 备份铁律按"主张放 vision、要求放 req、场景边界放 cases"三层分；T-09 对抗起草三方共识支持
- 隐私五层拆分采混合方案：部分 Codex 方案更精准（vision/req/compl），部分 Claude 方案更贴合产品语境（business/design）
- `post-merge-checkpoint` hook 选择"提示运行 skill"而非"自动生成 checkpoint"——保留人在回路，避免 AI 写无价值 checkpoint
- `long-session-guard` hook 每会话只提一次，`.claude/.long-session-warned` 标志文件；跨日负差加 24h
- QuestionSplittingService 做 PoC 不做消费方接入，Go/No-Go 基于真机准确率独立判断

## Risks

- Gemini 幻觉事件：T-07/08/09 对抗起草中 Gemini 输出 OLD 原文全为虚构（编造章节号、Use Case 名称）—— 已补到 `feedback_gemini_adversarial.md`，结构性建议可参考，引用原文做 diff 不可信
- `SystemLanguageModel.default.isAvailable` 在 Simulator 上检查耗时 ~150s，测试代码强制 Mock，不调用生产 API
- LocalizationKeys.swift 1503 行存量违规（SwiftLint file_length 500 限），swift-autolint hook 过滤了文件级规则避免假阳性
- CI YAML 校验 step 依赖 PyYAML，首次运行需要 pip install；已在脚本里自动安装

## Next

- tech-debt sprint（#637 / #638 / #666）—— 见 `checkpoints/2026-04-17-phase4-tech-debt.md`
- 用户排期：#626 真机验证 → Go 后接入消费方（ScanPagePicker / PDFPagePicker 等）
- Issue #666 方案 B LocalizationKeys 拆分（独立 PR，非紧急）
