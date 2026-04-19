---
last_verified: 2026-04-19
layer: snapshot
freshness:
  max_age_days: 3
  decay_trigger: [pr_merge, branch_change]
---
# Handoff

## 当前接手状态

- 主力智能体：Claude Code（Opus 4.7，1M context）
- 主分支：`develop`
- 仓库分支：本地 + 远程 develop/main 纯净（所有 feature 分支本轮随 PR 合并自动删除）

## 待合并 PR

（本轮 Harness Stage A+B 7 PR #673/#674/#675/#676/#677/#678/#679 已全部合并）
（PR #665 EditProfileView PhotosPicker UX 已于 2026-04-19 04:02 合并，Closes #637）

## 重要产出（新会话必读）

### 本轮新增（2026-04-18→19）
- `docs/research/harness-engineering-study-20260418.md` — Harness Engineering 三方研究归档（Anthropic + Hashimoto + Böckeler + Willison 命名时间线 + 中文译法 + SnapDrill 映射）
- `docs/memory/checkpoints/2026-04-19-harness-stage-a-b.md` — 本轮 7 PR checkpoint（Goal/Done/Decisions/Risks/Next/Metrics）
- `~/.claude/plans/resilient-floating-quasar.md` — Harness 3 阶段 7 PR 落地计划
- `~/.claude/plans/harness-prs-cross-audit-20260418.md` — 本轮 5 PR 三方 cross-audit 汇总（含冲突裁决 + 方法论反思）

### Phase 4 遗留
- `~/.claude/plans/doc-audit-summary.md` — 文档体系三方独立审计综合报告（2026-04-17）
- `~/.claude/plans/warm-sleeping-peach.md` — Phase 4 P3 执行蓝图
- `~/.claude/plans/phase4-p1-adversarial-summary.md` — 9 任务 × 3 方对抗起草汇总 + 6 项拍板决策

## 关键事实（当前快照）

### 项目状态
- **Must Have + Should Have 全部完成** · 免费版功能齐全
- 测试基线：~360+ tests（Core 103+QSplit / Data 95 / Features 158+VM），ViewModel 覆盖 16/16
- CI：Mac mini 自托管 runner，全绿（含 YAML frontmatter 校验 step）
- SwiftLint：0 violations（199 files）
- iOS 26.0+ / Xcode 26.4.1 / Swift 6.3 / defaultIsolation(MainActor)
- YAML frontmatter：全仓 47 md 统一，pre-commit + CI 双层校验

### 2026-04-18→19 Harness Engineering Stage A+B（7 PR 全合并）

**研究 + 计划**：
- Anthropic 2026-03-24 《Harness design for long-running apps》 触发 → 三方独立研究（Claude 27KB + Codex 24KB + Gemini 12KB）→ 综合报告归档 `docs/research/harness-engineering-study-20260418.md`
- 用户进 plan mode 深度研究 SnapDrill 落地 → 7 PR 3 阶段计划 `~/.claude/plans/resilient-floating-quasar.md`
- 用户 3 个决策：Issue 模板内嵌 Sprint Contract / 中成本 snapshot diff / 不引术语

**Stage A 流程骨架（3 PR）+ Stage B 治理强化（2 PR）+ 闭环 2 PR**：
- #673 Phase 4 历史 checkpoint 补齐（补 Hermes skill 里列但未生成的 3 个 checkpoint）
- #674 Harness 研究归档
- #675 Sprint Contract（feature/chore Issue 开工前必填 Touches/No-Touch/Interface Delta/Test Additions/DoD 最小集/不确定点）+ F-018
- #676 post-merge 反模式启发式（Scripts/anti-pattern-scan.sh 4 项检测 + F-019 人工升级纪律）
- #677 Permission Model SSOT（T1/T2/T3 tier + 9 hook 表 + 10 skill 矩阵 + 审计方法）
- #678 session-metrics hook（PostToolUse matcher `.*` 全 tool 记录 + phase-closeout Metrics 段）
- #679 cross-audit-consensus 量化 rubric 4 维（Scope Fidelity / Code Quality / Test Coverage / Architecture Fit，0-10 整数 + Retry 阈值 7.0/5.0/8.5/方差 2.5）

**F-005 漏执行事件**：Claude 推完 5 PR 没做 Codex/Gemini 对抗性审查（Auto mode 把 "提 PR" 当 "完成"），用户发现后补救：
- 三方 cross-audit 5 PR + 吃自己狗粮用新 rubric 打分
- Codex 独家抓到 8 处硬伤（Claude 9.3 vs Codex 7.5，方差触发硬 retry）
- retry 后 Codex 复核 #676/#677 通过；#678 首次 retry 剩 1 处文档矛盾，二次复核后通过
- 闭环：5 PR 全部按 F-016 质疑方批准流程合并
- **方法论教训**：主线程 Claude 自审有 bias（看"完成度"而非"吻合度"），下轮应把 Claude 自审分作参考不作裁决锚点

**合并冲突**：3 处（STATUS.md 日期 / feedback.md F-018 vs F-019 同位置 / permission-model §3 hook 表 8 vs 9）全部解决。

### Phase 4 收官（2026-04-17，19 PR，已合并）
见 `docs/memory/checkpoints/2026-04-17-phase4-p2-sprint.md` / `phase4-p3-sprint.md` / `phase4-tech-debt.md`。

## 后续待做（按可执行性排序）

| 优先级 | 工作项 | 说明 | 阻塞 |
|---|---|---|---|
| P1 | **Harness Stage C**（PR-6 SnapshotTesting + PR-7 CI 集成） | ~2-3 天，首次 baseline 易 flaky 需监督 | 用户将另开单独会话推进 |
| P2 | #626 QuestionSplittingService 真机准确率验证 | 10 份试卷样本，Go 条件 ≥ 80% 边界准确率 | 需 iOS 26 真机 + Apple Intelligence |
| P3 | LocalizationKeys.swift 拆分 | 1503 行 → 按 enum 拆多文件（Issue #666 方案 B） | 无（待排期） |
| P3 | CSV 导入功能 | Could Have | 无 |
| P3 | Share Extension 集成验证 | App Group 已配置，需端到端验证 | 真机 |

**Stage A+B 3 项 Risks 已落地**（PR #682 / Issue #681 闭环 2026-04-19）：F-020 Auto mode 不豁免 F-005 / §2.5 评分方权重 SSOT 表 / Gemini 评分纪律（6 条运行侧 prompt 承接）。首个 F-018 Sprint Contract PR 吃自己狗粮成功：首审 Gemini 9.8 vs Codex 6.0 方差 3.8 触发 retry，复核 Codex 8.5 通过。

**文档体系 v2 审计 + 收口 PR #685 已落地**（Closes #684，2026-04-19 晚）：Hermes + Harness 密集引入后三方全景审 49 md / 370KB。Codex 主锚点 8.0 / Claude Agent 次锚点 8.5 / Gemini 次锚点 8.75（方差 0.75）。修复 H 高 5 项 + M 中 6 项 + 3 处 last_verified（共 14 文件）：ADR-003 已决策 / 规则数指针化 / rubric 阈值收到 §2.5 SSOT / STATUS.md YAML 迁移 / feedback decisions frontmatter layer → pattern / review-prompt-guide 路径+水印 / workflow Phase Compaction 已实现 / principles/README 平权 vs 权重 / collaboration 合并状态措辞 / checkpoint ADR 路径 / appstore freshness。首次三方审 Codex 6.8 发现阈值语义反转（vs Gemini 10.0 方差 3.2），retry 后 Codex 9.1 通过。归档 `~/.claude/plans/doc-audit-v2-20260419.md`。

## Apple 账号阻塞链（用户主动延迟至 2026-05 缴费）

Enrollment ID 83VZW7VJKK **已通过 Apple 审核**，$99 年费用户主动延迟。下游所有功能随时可启动，节奏由用户控制。

| Issue | 内容 | 依赖 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | 已通过审核，等用户缴费 |
| #479 | StoreKit 付费墙 | ← #163 |
| #485 | iCloud CloudKit 同步 | ← #163 + #479 |
| #486 | Word 导出 | ← #479 |
| #490 | App Store 提交 | ← #163（ASO 文案已预备 #633） |
| #161 | TestFlight Build 6 | ← #163 |

## 新增基础设施（本轮 Harness 落地）

### Hooks（9 个活跃，见 `docs/principles/permission-model.md` §3）
- **Stage A+B 新增**：
  - `anti-pattern-scan.sh`（Scripts/，post-merge-checkpoint 调用）— 反模式启发式 4 项（scope / over-gen / test evasion × 2）
  - `session-metrics.sh`（.claude/hooks/，PostToolUse `.*`）— 全 tool call 时间戳记录到 `.claude/session-metrics.tsv`（不入 git）
- **此前已有**：swift-autolint / block-dangerous-bash / premerge-checklist / prepush-lint / post-merge-checkpoint / long-session-guard / log-file-change / SessionStart compact

### Rules（14 条）
- **Stage A+B 新增**：`.claude/rules/permission-model.md`（指向 `docs/principles/permission-model.md` SSOT）
- **此前已有**：engineering / collaboration / codex-delegation / gemini-delegation / shared-constraints / ...

### Skills（扩展）
- **Stage A+B 扩展**：
  - `cross-audit-consensus` §2.5 量化评分 + Retry 阈值
  - `cross-audit` 委派模板加 rubric 要求
  - `phase-closeout` 模板加 Metrics 段 + session 时长计算命令
- **此前已有**：cross-audit / cross-audit-consensus / phase-closeout / resume-from-handoff / update-status / pr-review-workflow / developer / qa-engineer / devops / security-engineer

### Feedback 纪律（20 条 F-001~F-020）
- **Stage A+B 新增**：F-018 编码前契约 / F-019 反模式启发式回流 / F-020 Auto mode 不豁免 F-005（PR #682）

### Issue 模板
- **Stage A+B 扩展**：`feature_request.md` + `chore.md` 加 Sprint Contract 段；`bug_report.md` 不加（scope 天然小）

## 已验证的 iOS 26 新 API（Phase 4 遗留）
1. **RecognizeDocumentsRequest**（Vision）— OCRService.recognizeDocument
2. **FoundationModels** — ContentTaggingService（生产）+ QuestionSplittingService（PoC，待真机）
   - `SystemLanguageModel.default.isAvailable` 在 Simulator 上检查耗时 ~150s → 测试不调用生产
   - `nonisolated struct` 在 Swift 6.3 + defaultIsolation(MainActor) 下合法

## 已踩坑记录（Phase 4 + Harness）
- `defaultIsolation(MainActor)` + async + PersistenceController.init = 死锁（#599 / PR #628 修）
- `modelContext.delete(model:)` 批量删除不影响 context 未保存对象
- `fetchOrCreateModel` 只 insert 不 save → deleteAll 前需先 saveContext
- SwiftLint file_length 500 行限制（LocalizationKeys.swift 1503 行存量违规，Issue #666 方案 B 待拆）
- swift-autolint hook 单文件 lint 与全仓不一致（PR #667 已过滤文件级规则）
- **新增**：git add -A 在 local-only 文件未入 .gitignore 时容易误提交（session-metrics.tsv 在 PR-5 合并前）
- **新增**：PR 间改同一文件尾部追加（如 feedback.md）合并必冲突，需按语义顺序解决

## 对抗起草纪律（本轮实证更新）
- Codex GPT-5.4（--effort high）：对抗审查最严格，独家发现 Claude/Gemini 都漏的硬伤（#677 3 处 + #678 3 处），plan 逐条对照能力最强
- Gemini 3 Auto：本轮未现幻觉（diff 直接贴 prompt 而非引用仓库原文），但**评分整体偏高**（3/5 PR 打 10.0），不宜作裁决锚点
- Claude 主线程自审：存在 confirmation bias（看"完成度"而非"吻合度"），实施方同时评分时应降权
- 裁决锚点优先级：详见 `.claude/skills/cross-audit-consensus/SKILL.md` §2.5 评分方权重 SSOT 表（主锚点 Codex / 次锚点 Gemini-守纪律 & Claude-Agent / 参考 Claude-主线程自审）
