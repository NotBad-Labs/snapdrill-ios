---
last_verified: 2026-04-17
layer: snapshot
freshness:
  max_age_days: 3
  decay_trigger: [pr_merge, branch_change]
---
# Handoff

## 当前接手状态

- 主力智能体：Claude Code（Opus 4.7，1M context）
- 主分支：`develop`
- 当前工作分支：`chore/handoff-sync-phase4-complete`
- 仓库分支：本地清理 / 远程 develop + main 纯净

## 待合并 PR

| PR | 内容 | 状态 |
|---|---|---|
| #665 | fix: EditProfileView PhotosPicker 失败 UX 反馈 + 同图重选 (#637) | CI 绿，**等 Xcode Review**（UI 改动必经 F-017） |
| #668 | chore: api-reference 补 QuestionSplittingService 条目（#626） | CI 中 |
| 本 PR | chore: handoff.md 同步 Phase 4 完整收官 | 本次接手产物 |

## 重要产出（新会话必读）

- `~/.claude/plans/doc-audit-summary.md` — 文档体系三方独立审计综合报告（2026-04-17）
- `~/.claude/plans/warm-sleeping-peach.md` — Phase 4 P3 执行蓝图
- `~/.claude/plans/phase4-p1-adversarial-summary.md` — 9 任务 × 3 方对抗起草汇总 + 6 项拍板决策
- `~/.claude/plans/adversarial-{t05-06,t07-08-09,t14,t15}-claude.md` — Claude 4 份独立方案（F-008 三方对抗纪录）

## 关键事实（当前快照）

### 项目状态
- **Must Have + Should Have 全部完成** · 免费版功能齐全
- 测试基线：~360+ tests（Core 103+QSplit / Data 95 / Features 158+VM），ViewModel 覆盖 16/16
- CI：Mac mini 自托管 runner，全绿（含 YAML frontmatter 校验 step）
- SwiftLint：0 violations（199 files）
- iOS 26.0+ / Xcode 26.4.1 / Swift 6.3 / defaultIsolation(MainActor)
- YAML frontmatter：全仓 40 md 统一，pre-commit + CI 双层校验

### 本会话完成的工作（2026-04-17 晚 → 深夜，19 PR + 1 Issue 关闭）

#### Phase 4 P1+Step1（4 PR，之前已合并）
- #642 SSOT 校准 / #644 cross-audit skill / #646 api-reference / #648 .claude/rules YAML

#### Phase 4 P2 sprint（6 PR，2026-04-17 晚间）
- #650 PR-D F-008 去重 / #651 PR-G archive / #652 PR-F + T-01 追补 / #653 PR-H / #654 PR-K Issue 模板 / #655 PR-E KNOWLEDGE_MAP

#### Phase 4 P3 sprint（8 PR，2026-04-17 晚间对抗起草 + 合并）
- #656 ADR-003 YAML 5-layer schema
- #657 Step 2+3 — 40 文件 YAML 迁移
- #658 Step 4 — Scripts/migrate + validate + CI 校验门
- #659 PR-I-W1 备份铁律 / #660 PR-I-W2 隐私五层 / #661 PR-I-I1 冲突裁决
- #662 #540 hooks 4 个运行时门
- #663 #626 QuestionSplittingService PoC（draft → ready 合并）

#### Tech-debt 清理（3 PR，2026-04-17 深夜）
- #664 #638 ProfileListView 抽 VM + 8 单测
- #665 #637 EditProfileView UX（**待 Xcode Review**）
- #667 #666 swift-autolint hook 过滤文件级违规

#### Issue 动态
- 新建 Issue #666（swift-autolint hook bug） → PR #667 修复（方案 A）
- #626 加 comment 总结 PoC 工作 + 保持 open 等真机验证
- #637 #638 将随 PR 合并自动关闭

### Mac mini runner 事件（已解决）
- 2026-04-17 晚 CoreSimulator 1051.49→1051.50 过时 → #651/#652/#653 首轮 CI FAILURE
- 用户系统更新 + 重启 Mac mini（macOS 26.4.1 / Xcode 26.4.1）后恢复

### Gemini 幻觉事件（已记录）
- T-07/08/09 对抗起草中 Gemini 输出 OLD 原文全为虚构（编造章节号、Use Case 名称）
- 已补充到 `feedback_gemini_adversarial.md`：Gemini 引用仓库原文做 diff 不可信

## 后续待做（按可执行性排序）

| 优先级 | 工作项 | 说明 | 阻塞 |
|---|---|---|---|
| P1 | PR #665 EditProfileView UX 合并 | 等 Xcode Review（F-017 UI 改动必经） | 用户在 Xcode 触发 |
| P2 | #626 QuestionSplittingService 真机准确率验证 | 10 份试卷样本，Go 条件 ≥ 80% 边界准确率 | 需 iOS 26 真机 + Apple Intelligence |
| P3 | LocalizationKeys.swift 拆分 | 1503 行 → 按 enum 拆多文件（Issue #666 方案 B） | 无（待排期） |
| P3 | CSV 导入功能 | Could Have，现有 CSV 导出的逆向操作 | 无 |
| P3 | Share Extension 集成验证 | App Group 已配置，需端到端验证 | 真机 |

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

## 技术提醒

### 新增基础设施（本会话）
1. **Scripts/migrate_to_yaml_frontmatter.py** — 一次性迁移脚本（已用完）
2. **Scripts/validate_frontmatter.py** — 校验脚本（CI + 可选 pre-commit）
3. **.claude/hooks/** 4 个新 hook（H1-H4）：
   - `swift-autolint.sh` — PostToolUse Edit\|Write `*.swift`，行级违规 exit 2（文件级已过滤）
   - `block-dangerous-bash.sh` — PreToolUse Bash，拦截 rm -rf/force push/hard reset 等
   - `premerge-checklist.sh` — PreToolUse `gh pr merge`，近 24h 无 STATUS.md 更新 → 阻塞
   - `prepush-lint.sh` — PreToolUse `git push`，全仓 swiftlint 违规 → 阻塞

### 已验证的 iOS 26 新 API
1. **RecognizeDocumentsRequest**（Vision）— OCRService.recognizeDocument
2. **FoundationModels** — ContentTaggingService（生产）+ QuestionSplittingService（PoC，待真机）
   - `SystemLanguageModel.default.isAvailable` 在 Simulator 上检查耗时 ~150s → 测试不调用生产
   - `nonisolated struct` 在 Swift 6.3 + defaultIsolation(MainActor) 下合法

### 已踩坑记录
- `defaultIsolation(MainActor)` + async + PersistenceController.init = 死锁（#599 / PR #628 修）
- `modelContext.delete(model:)` 批量删除不影响 context 未保存对象
- `fetchOrCreateModel` 只 insert 不 save → deleteAll 前需先 saveContext
- SwiftLint file_length 500 行限制（LocalizationKeys.swift 1503 行存量违规，Issue #666 方案 B 待拆）
- swift-autolint hook 单文件 lint 与全仓不一致（PR #667 已过滤文件级规则）

### 对抗起草纪律（Phase 4 实证）
- Codex GPT-5.4（--effort high）对仓库 diff 任务可信，OLD/NEW 原文精准
- Gemini 对文档**结构性建议**可信，但**引用仓库原文做 diff 不可信**（会幻觉编造章节号）
- 每次三方对抗必须 Claude 亲自汇总比对（Claude 充当主 reviewer）
