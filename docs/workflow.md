---
last_verified: 2026-04-21
layer: principle
---
# SnapDrill 协作流程

> 开发闭环、Git 工作流、Code Review、优先级。工程哲学见 `docs/principles/engineering.md`，协作模式见 `docs/principles/collaboration.md`。

---

## 开发闭环（Personal Kanban）

```
Shaped → Building (WIP≤2) → Reviewing → Done
```

无固定周期。做完一个拉下一个。

### Issue 模板（Shape 阶段）

SSOT：`.github/ISSUE_TEMPLATE/feature_request.md`（GitHub 创建 Issue 时自动加载）。bug 报告用 `.github/ISSUE_TEMPLATE/bug_report.md`，杂项治理用 `.github/ISSUE_TEMPLATE/chore.md`。

核心字段：问题/用户场景 · MoSCoW · Severity · Appetite · Scope/No-Go · 风险与不确定性 · 影响范围（涉及文件） · 验收标准（Given-When-Then）。

### Scope 控制

1. **Appetite 预算**：超预算砍 scope，不加时间
2. **No-Go 清单**：Issue 明确不做什么
3. **发现即建 Issue**：Build 中范围外的新发现不在当前 PR 处理

### 编码前契约（Sprint Contract）

feature / chore 类 Issue 且 Appetite >= Small 时，动第一行代码前必须在 Issue 回复一条 Sprint Contract comment，覆盖 Issue 模板 Sprint Contract 段的全部字段（Touches / No-Touch / Interface Delta / Test Additions / DoD 最小集 / 预期不确定点；chore 简化为三条）。

**触发**：Issue 从 Shaped 进入 Building 状态时。bug_report 类不强制（修复 scope 天然小）。

**变更纪律**：编码过程中若发现预期与实际不符，先改 Issue comment 里的 contract，再改代码。禁止"代码和 contract 自然漂移"。

**Review 挂钩**：Codex 对抗性审查、Xcode Review、三方 cross-audit 在开工时与合并前都有义务对照 contract 检查 scope fidelity；有偏离必须在 review 意见中点名。

详见 `docs/memory/feedback.md` F-018。

---

## Git 工作流

```
main ← App Store，只接受 develop 的 PR
develop ← TestFlight，只接受 feature/fix/chore 分支的 PR
```

**铁律**：禁止直推 develop/main。每个任务：Issue → 分支 → PR（`Closes #N`）→ Review → 合并。

**例外**：STATUS.md 允许直推 develop。

---

## Definition of Done（PR 合并前检查清单）

> 基于 `docs/principles/engineering.md` 工程哲学。重点：奥卡姆剃刀（新增抽象是否必要）、编译期拦截（warnings 0）、YAGNI（不超出 Issue scope）。

### 代码质量
- [ ] `swiftlint --strict` 0 violations
- [ ] `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` 0 errors
- [ ] `xcodebuild test-without-building -xctestrun ... -only-test-configuration CI` 通过（已有测试不得回归，详见《本地复现 CI Test》）
- [ ] 改接口签名后 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- [ ] Codex 对抗性审查通过（每个 PR 必须）
- [ ] Xcode Review 核实通过（UI 改动必须）
- [ ] AI 反模式检查通过（见 `collaboration.md` 检查表），附证据
- [ ] 实现满足 Issue 的 Scope 和 No-Go 约束（intent review）
- [ ] 此 PR 影响已文档化的约束？如是，已更新对应文件

### 功能完整性
- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步
- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] `api-reference.md` 已更新（新增/变更 public 接口）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 术语与 `product-glossary.md` 一致（新增或修改产品概念时）
- [ ] 合并后立即更新 `STATUS.md`

### Review
- [ ] Review 结论已留痕（PR comment 或 PR 描述）

---

## Code Review

**所有 PR 必须完成 review 后，由用户确认再合并。Review 结论必须留痕。**

1. **Xcode Review**：Claude Code 写提示词，用户在 Xcode 触发
2. **Claude Code 核实**：每条 finding 读源文件确认真实性
3. **留痕**：Review 结论必须记录在 PR comment 或 PR 描述中

**纪律**：
- PR 未合并前禁止推进下一任务
- 禁止自审自批
- 范围外发现立即建 Issue
- PR 合并后立即更新 STATUS.md
- Review 无留痕的 PR 不得合并

---

## CI 与本地一致性

Mac mini self-hosted runner 与本地 Xcode 版本锁定一致（Xcode 26.4 / iPhone 17 Simulator）。
`AllTests` scheme 覆盖 Core/Data/Features 三个测试 target，含 `SnapshotRegressionTests`。

### Snapshot 测试失败时的产物

CI `Test` step 用 `-resultBundlePath TestResults.xcresult` 固定产物路径。
失败时 `Upload xcresult on failure` step 把整个 `TestResults.xcresult` 目录
打包为 artifact（保留 7 天），含：

- 每个失败 snapshot 的 reference / failure / difference 三张 PNG
- 测试日志、失败断言信息

### 下载与查看 artifact

```bash
# GitHub CLI（推荐）
gh run download <run_id> --name xcresult-<run_id>-<attempt> -D ./ci-artifacts
# 提取附件 JSON 索引
xcrun xcresulttool get --path ci-artifacts/TestResults.xcresult --format json > result.json
# 用 xcode 打开可视化审查
open ci-artifacts/TestResults.xcresult
```

Agent 可直接读图判断是否是有意变更；若需更自动化可后续 PR 封装 MCP，当前人工审已够用。

### 本地复现 CI Test

```bash
rm -rf TestResults.xcresult DerivedData
# 1) build-for-testing 产出 xctestrun
xcodebuild build-for-testing -scheme AllTests -testPlan AllTests \
  -derivedDataPath ./DerivedData \
  -destination 'platform=iOS Simulator,name=iPhone 17'
# 2) test-without-building 复用产物，-only-test-configuration CI 对齐 CI 行为
XCTESTRUN=$(find ./DerivedData/Build/Products -name 'AllTests_*.xctestrun' | head -1)
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN" \
  -only-test-configuration CI \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO \
  -resultBundlePath TestResults.xcresult
```

`TestResults.xcresult` 在 `.gitignore`，本地产物不入 git。

### 本地重录 snapshot baseline

有意修改 View 后基线需更新，切 `SnapshotRecord` configuration（`SNAPSHOT_TESTING_RECORD=all`）重录：

```bash
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN" \
  -only-test-configuration SnapshotRecord \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO
# 然后 git diff 确认 __Snapshots__/*.png 改动符合预期后提交
```

禁止盲目 record 掉所有 baseline（F-014 test evasion 反模式）；Review 见到一次性 >3 张 baseline 改动必须质询。

---

## 决策变更收尾

产品决策变更时，同一回复中 Grep 影响范围 → 创建执行 Issue。Issue 未关闭 = 收尾未完成。

---

## 工作优先级（S0-S3）

按「用户失去了什么」排序：

| 级别 | 含义 | 典型场景 |
|---|---|---|
| **S0** | 数据不可逆丢失 | 保存静默失败、备份损坏 |
| **S1** | 流程完全阻断 | 崩溃、功能不可用、OOM |
| **S2** | 能完成但有摩擦 | OCR 不准、搜索不准、卡顿 |
| **S3** | 更好但不紧急 | UI 打磨、测试补充、重构 |

**同级排序**（按模块重要性）：采集 > 管理 > 导出 > 复习 > 设置。
**执行**：S0 → S1 → S2 → S3，严格按序。

---

## 交叉审计（Cross-Audit）

三方审计的组合、流程、工具链见 `docs/principles/collaboration.md`；核心纪律见 `docs/memory/feedback.md` F-008。

---

## 审计命中处置协议（docaudit）

> 适用范围：`Scripts/audit/docaudit.py` 的 6 子命令 + `frontmatter`（via validate_frontmatter.py）发现的命中。
> 依据：Phase B 三方共识（Codex 主锚独有「组件 E 处置协议」洞见），避免"发现但不闭环"的治理风险。

### 三档处置

| 命中级别 | CI 行为（`all --strict --baseline`） | 必须动作 | 允许豁免路径 |
|---|---|---|---|
| **error** | 阻断（exit 1） | 必须修复或升级到 Phase C 清理 PR | **唯一豁免路径**：`Scripts/audit/policy.yaml` `legacy_whitelist` + 明确 `reason` + 硬 `expires_on`；豁免 PR 必须同步含白名单条目的添加。**禁止**仅在 PR 描述里写理由就过 error |
| **warning** | `--strict` 升级为阻断 | 合并前二选一：修 / 登记 `legacy_whitelist`（同 error 路径） | 与 error 相同；不允许仅靠 PR 描述；不允许降级为 info 规避 |
| **info** | 不阻断（summary 可见） | 可忽略，建议周期性跑 `/knowledge-health` 捞 dead rule 候选 | 无需留痕 |

**关键**：CI 默认跑 `--strict --baseline`，warning 会被升级为阻断。因此"warning 仅 PR 描述留痕"不是合法豁免 —— 它会在 CI 层直接被红 check 挡掉。唯一合法豁免仍是 `legacy_whitelist`。

### 留痕要求

- **PR 描述**（`.github/PULL_REQUEST_TEMPLATE.md` 《审计豁免留痕》段）：声明本 PR 是否触发 docaudit 新命中 + 是否更新 legacy_whitelist + 豁免 `expires_on`
- **commit message**：涉及 `policy.yaml legacy_whitelist` 改动的 commit 必须含 `docaudit:` 前缀或段落
- **Phase C 清理 PR**：必须同步从 `legacy_whitelist.paths` 移除对应条目，不能只改代码不改策略

### 禁止项

- ❌ 通过 `--strict` 或 `--baseline` 的组合绕过 error 级命中（这是防回归设计，不是豁免通道）
- ❌ **严禁为使当前 PR 过审而对 `policy.yaml` 中的规则做任何降级**（error→warning、error→info、warning→info 一律禁止）。规则设定本身不合理时，必须提交单独的 `chore: adjust docaudit policy` PR 独立讨论（不能伴随代码改动）；本 PR 的特殊情况必须走 `legacy_whitelist` 豁免。留痕降级不是合法后门
- ❌ 把 `legacy_whitelist` 条目的 `expires_on` 无限期延后（每次延后必须伴随具体 Phase C sub-PR 的进度说明）
- ❌ 在 PR 描述里"解释合理性"就试图过 error/warning 命中 —— 豁免必须通过 `legacy_whitelist` 机制，PR 描述是**留痕辅助**而非豁免通道

### 与 `/knowledge-health` 的分工

- **docaudit**（CI + hook）是执行门禁：强制阻断级
- **`/knowledge-health`** 是诊断报告：产出分层修复 plan，不阻断，不改文件
- 处置协议的**决策层**由人读完 plan 后触发（写 Phase C 清理 PR 或更新 legacy_whitelist）

---

## 长任务 Phase Compaction

> 借鉴 Hermes agent 研究（2026-04-18，`docs/archive/research/hermes-agent-study-20260418.md`）。

跨多 PR、多天、多 reviewer 的长任务（如本仓 Phase 4 收官 19 PR）容易产生：
- 旧工具输出/讨论噪声稀释相关性
- 接手成本高（必须重读全部 transcript）
- prefix cache 失效（系统 prompt 频繁变化）

**规则**：每合并 3-5 个相关 PR 后，必须产出一次 **Phase Checkpoint**：

```markdown
# Phase Checkpoint <YYYY-MM-DD> <主题>

## Goal
本 phase 想解决的问题（一句话）

## Done
- PR #N 主题（关键改动 + 影响范围）
- ...

## Open
- 待合并 PR
- 待解决子任务

## Decisions
- 关键技术/产品决策（指针到 ADR/discussion）

## Risks
- 已知风险 / 待真机验证 / 阻塞链

## Next
- 下一组工作清单
```

**位置**：`docs/memory/checkpoints/<YYYY-MM-DD>-<topic>.md`（layer: snapshot, max_age_days: 30）

**触发**：
- 每 3-5 PR 合并自动（hook：`post-merge-checkpoint`，已实现；见 `docs/principles/permission-model.md` §3 Hook 生命周期门禁）
- Phase 结束手动（`phase-closeout` skill 协助）

**接手时**：新 Claude 会话只读 `STATUS.md` + `docs/memory/handoff.md` + 最近 Checkpoint，**不强吃长 transcript**（`resume-from-handoff` skill）
