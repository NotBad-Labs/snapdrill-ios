---
last_verified: 2026-04-22
layer: snapshot
status: archived
archived_on: 2026-04-22
---
# Phase E PR-E4 — 首次反哺实战记录（2026-04-22）

> snapdrill-ios 作为 agent-harness 第一个 consumer 的**首次反哺实战演练**。本 PR 不真正反哺代码，而是**吃自己的狗粮**跑完 `extract-candidate → propose-upstream` 全流程，暴露并修复工具链问题，产出 sample proposal draft 作为方法论实证。

## Context

- **Phase**：Phase D/E consensus §5.5 PR-E4
- **目标**：用 PR-E2 实现的 CLI 工具（`extract-candidate` + `propose-upstream`）在第一个真实 consumer（snapdrill-ios）上跑一遍，验证工具链可用 + 暴露实战问题
- **依赖**：
  - agent-harness PR-D5（snapdrill-ios `.agent-harness/project.yaml` 契约已落地）
  - agent-harness PR-E1（contribution-rubric + PR template）
  - agent-harness PR-E2（extract-candidate + propose-upstream CLI）
  - agent-harness PR-E3（harness-introspection skill）

## Execution trace

### Step 1 — 首次跑 `extract-candidate`

```bash
$ python3 ~/Developer/agent-harness/bin/agent-harness \
    extract-candidate ~/Developer/snapdrill-ios
```

输出：29 个候选全部被建议 `preset-ios (needs adapt)`，包括明显通用的 `cross-audit` / `phase-closeout` / `update-status` / `post-merge-checkpoint` 等 skill/hook。

### Step 2 — 识别 bug #1（path-matching）

**根因**：`_score_and_suggest()` 用 `str(file_path).lower()` 判断层建议。`file_path` 是绝对路径 `/Users/yiming/Developer/snapdrill-ios/...`，含子串 `ios`，误触发 "preset-ios" 分支。

**影响**：所有候选被误判为 iOS 特定，掩盖了真正 adapter-claude / core/ 候选。

**修复**：agent-harness PR #9（`fix/extract-candidate-path-matching`）
- `_score_and_suggest` 新增 `rel_path` 参数（相对 consumer root），启发式改用 `rel_path`
- 收紧 `ios` 匹配：不再裸子串，改为明确路径段（`ios/` 开头 / `/ios/` 夹层 / `.swift` 扩展名）
- 加 3 个回归测试（`LayerSuggestionRegressionTest`）
- CI 全绿后合并 commit `02775c5`

**按 contribution-rubric §0**：这是 **bug fix 不是反哺**，直接修不走反哺 rubric。

### Step 3 — 重跑 `extract-candidate`（hotfix 后）

29 候选重新评分。前 10：

| 候选 | Score | Commits | 建议层 |
|---|---:|---:|---|
| `.claude/skills/phase-closeout/SKILL.md` | 100% | 4 | adapter-claude/ |
| `.claude/skills/update-status/SKILL.md` | 100% | 6 | adapter-claude/ |
| `.claude/skills/cross-audit/SKILL.md` | 100% | 4 | adapter-claude/ |
| `.claude/hooks/post-merge-checkpoint.sh` | 100% | 3 | adapter-claude/ |
| `docs/standards/apple-native.md` | 100% | 9 | core/principles/（**误判 - finding #2**） |
| `docs/standards/memory-routing.md` | 100% | 3 | core/principles/ |
| `.claude/skills/cross-audit-consensus/SKILL.md` | 90% | 5 | adapter-claude/ |
| `docs/standards/apple-extension.md` | 90% | 4 | core/principles/（**误判 - finding #2**） |
| `docs/standards/ux-design.md` | 90% | 4 | core/principles/ |
| `.claude/hooks/docaudit-on-doc-edit.sh` | 80% | 3 | adapter-claude/ |

### Step 4 — 识别 bug #2（apple-* 启发式缺口，follow-up）

**观察**：`apple-native.md` / `apple-extension.md` 明显是 iOS 特定文档（讨论 Apple HIG / Xcode Review 等），应建议 `STAY`（consumer 特定），但工具建议 `core/principles/ (high confidence)`。

**根因**：默认 denylist 包含 `swift / swiftui / swiftdata / xcode`，但**不含 `apple`**。如果 apple-*.md 内容不提 swift 具体类型，denylist count 就是 0 → 被认为"通用"。

**处置（follow-up，不在 PR-E4 修复）**：
- 可选方案 A：扩展默认 denylist 加入 `apple|hig`
- 可选方案 B：在 `_score_and_suggest` 加入文件名前缀启发式（`apple-*.md` / `ios-*.md` → preset-ios）
- 可选方案 C：consumer 在 project.yaml 显式声明 `consumer_terms: [apple, HIG, ...]`

推荐：**B + C 组合**（扩展启发式 + consumer 可 override），不硬扩默认 denylist（`apple` 是过于通用的词，对非 iOS consumer 可能误命中）。

**记录到**：agent-harness repo 未来 issue（待用户创建）。

### Step 5 — 识别 finding #3（无新反哺候选）

**观察**：所有 high-score + ≥3 commits 的候选：

- `.claude/skills/*` 的通用 skills：**已在 agent-harness PR-D4 迁移完毕**（adapter-claude/skills/）
- `.claude/hooks/*` 的通用 hooks：**已在 PR-D4 迁移完毕**（adapter-claude/hooks/）
- `docs/standards/*` 通用原则：**已在 PR-D4 部分迁移**（adapter-claude/ 下部分，其余作为 STAY 保留）
- 剩余未迁移的：apple-*（iOS 特定，STAY）/ coding.md / testing.md / ux-design.md（大部分 iOS 特定，STAY）

**结论**：snapdrill-ios 当前**没有真正的新反哺候选**。这是**积极信号**（不是失败信号）—— 说明 Phase D PR-D4 已经把通用 skill/hook/原则完整迁到 agent-harness 了，现在等第二 consumer 出现或 snapdrill-ios 孵化新模式。

### Step 6 — 生成 sample proposal draft

为演示 `propose-upstream` 工具可跑通，对一个已迁移的候选（`.claude/skills/phase-closeout/SKILL.md`）生成 draft：

```bash
$ python3 ~/Developer/agent-harness/bin/agent-harness \
    propose-upstream .claude/skills/phase-closeout/SKILL.md \
    --target ~/Developer/snapdrill-ios
```

产出：`.agent-harness/proposals/_claude__skills__phase-closeout__SKILL_md__<timestamp>.md`（136 行，含自动填入的 consumer name / commit 数 / 时间窗 / P1 六门槛 checklist / P2 3 迭代状态 / 层建议）。

**注**：该 skill **已**在 agent-harness adapter-claude/skills/phase-closeout 里（PR-D4 迁移），所以本 draft 不实际开反哺 PR —— 仅作**工具链 validation**（证明 propose-upstream 能正确填充数据）。

## Findings 汇总

| # | Finding | 严重度 | 处置 |
|---|---|---|---|
| 1 | extract-candidate path-matching bug（绝对路径含 `ios` 误触发 preset-ios） | S-normal | ✅ 修复（agent-harness #9 合并）+ 3 回归测试 |
| 2 | apple-* 文件启发式缺口（无 `apple` 关键词导致 iOS 文档被建议 core/principles） | S-experimental | 📝 Follow-up（未来加启发式 + consumer override）|
| 3 | snapdrill-ios 当前无新反哺候选（PR-D4 已完整迁移通用内容） | N/A（积极信号） | 等第二 consumer 或 snapdrill-ios 孵化新模式 |

## 工具链验证结论

- ✅ `extract-candidate` 可跑通，返回 ranked 候选清单
- ✅ `propose-upstream` 可跑通，生成 136 行模板化 draft
- ✅ PR-E1 rubric 6 硬门槛 + P2 3 迭代数据被 CLI 正确填入 draft
- ✅ Bug #1 首次吃狗粮即暴露 + 修复 + 回归测试 — 证明 Phase E 机制设计有效
- ✅ Finding #3 证明 Phase D PR-D4 完整性（通用内容全部已迁）

## 方法论实证

Phase E 的核心假设是**"工具通过 consumer 使用自证"**。本次 PR-E4 dry-run 实证：

1. **首次吃狗粮暴露 bug** — Phase D 内部 self-test 34 tests + CI denylist 都通过了 path-matching bug，但一接触真实 consumer 路径（含 `ios` 子串）就暴露。说明**sandbox tests 不能替代真实 consumer 实战**。
2. **hotfix 当场解决** — 从发现 bug 到 hotfix PR #9 合并约 20 min，加 3 个回归测试防回归。工具链自身的可维护性通过。
3. **启发式 follow-up 诚实记录**（Finding #2）— 不急于 hotfix 所有问题，记录为 backlog，体现"空白 + 演进"原则。

## 产出清单

- `.agent-harness/proposals/_claude__skills__phase-closeout__SKILL_md__2026-04-22T12-47-28+00-00.md` — sample proposal draft（snapdrill-ios 本地）
- 本文件 `docs/archive/phase-e-pr-e4-reflow-20260422.md` — 完整实战记录
- agent-harness PR #9 hotfix — `fix(cli): extract-candidate layer suggestion 必须用相对路径不是绝对路径`

## Next（PR-E4 之后）

### Phase E 收官（snapdrill-ios 侧）

- ✅ 本 PR：PR-E4 实战记录归档
- 后续 sync PR：STATUS / handoff 更新反映 Phase E 全收官（5 PR：E1/E2/E3/hotfix/E4）

### agent-harness 侧 follow-up（用户拍板）

- 可选 issue：apple-* heuristic 缺口（Finding #2）
- 可选 issue：consumer project.yaml 支持 `consumer_terms` 配置（部分已支持，但文档不全）

### Phase F 候选

按 consensus §5.6 D/E 关系：
- 第二 consumer（玩具级）验证通用性
- 版本发布机制（semver / CHANGELOG）
- preset 成熟化（等 ≥ 2 consumer 反哺 iOS 共性后再填充 `preset-ios/`）

## 与 PHILOSOPHY 对齐

- 三原则 #1 空白+演进：Finding #3 证明 core/ 不预抽象、反哺驱动的策略正确
- 三原则 #2 共生：snapdrill-ios 既是孵化器（贡献 Phase D 全部通用内容）又是消费者（PR-E4 dry-run 暴露 bug 促成 hotfix）
- 三原则 #3 可被复用：Finding #3 + 34 tests 证明工具链在 consumer 侧可工作
- 反模式 #3 假通用：Finding #3 主动标注"无新候选 ≠ 不通用，是因为通用的已迁完"，避免 PR 作者虚报"通用性"

---

**签名**：Claude Opus 4.7（1M context）主线程。Phase E PR-E4 dry-run 一次完成（含一次 hotfix）。归档于 snapdrill-ios `docs/archive/` 作为 Phase E 方法论实证案例。
