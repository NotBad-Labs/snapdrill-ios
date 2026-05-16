---
last_verified: 2026-05-15
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-15（**Phase 5 零信任审计修复完工 — 11 PR 全合，24 真问题清零**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）
> 领先 origin/develop：**0 commits**（Phase 5 #751–#761 11 PR 全部已合）
> **新增 6 个 Skill**：verify-audit-report / dependency-propagation / sprint-contract / post-merge / api-research / snapshot-diff-review
> **源文件防腐**：237 文件删除创建日期，git blame 为唯一真相源
> **新增双统帅架构**：Claude Opus 4.7 + Codex GPT-5.5 high effort = 双统帅 / DeepSeek V4-Pro = 单文件贪吃蛇执行者
> **零信任审计在跑**：Codex 16 finding + DeepSeek 贪吃蛇 50 文件 ~235 finding = 251 finding，Phase 2 Claude 核验待启
> **CI 盲区治理闭环**：ci.yml push trigger + pre-push hook + PR #749 五轮 fix 解锁 develop 三天累积 build/runtime fatal
> **工具链**：Codex CLI 0.130.0 + Gemini CLI + DeepSeek V4-Pro · skill-creator@claude-plugins-official
> **下次接手**：读 `docs/memory/handoff.md` Boot 序列

## 本轮完成（2026-05-15，零信任审计 Phase 5 完工）

### Phase 5 修复 PR 全景（11 PR 全合）

| PR | 内容 | 类别 |
|---|---|---|
| #751 | PR-A1 cases.md 多 Profile 恢复 (S0) | A 验收口径 |
| #752 | PR-A2 engineering.md F-XXX 规则 (S1) | A 验收口径 |
| #753 | PR-B1 vision SSOT 指针 + analytics 事件名 | B 引用一致性 |
| #754 | PR-B2 README/CLAUDE/CODEX/Infra RemoteConfig + scheme | B 引用一致性 |
| #755 | PR-B5 ASO 类别 + shared-constraints SSOT | B 引用一致性 |
| #757 | PR-B3 用户旅程引用批量改 + review 示例虚构注 | B 引用一致性 |
| #758 | PR-B4 KNOWLEDGE_MAP + standards/README + ADR-001 | B 引用一致性 |
| #756 | PR-D1 STATUS.md 归档历史 sprint -145 行 | D 归档 |
| #759 | handoff sync 插件升级前 | D 归档 |
| #760 | PR-C2 杂项 5 项（deployment/NFR/UC 8-9/permission-model/ADR-003） | C 时效性/杂项 |
| #761 | PR-C1 时效性批量 + decisions D-001 4:2 不一致 + handoff Skill 表重复 | C 时效性/杂项 |

24 真问题清零（Codex 16 finding 100% verified + DeepSeek 235 finding D2/D4 真问题）。

NFR iCloud 同步段写「待 #485 解锁」占位（按方案 A，避免过早设计）。

## 上一轮完成（2026-05-14，零信任审计 + CI 治理 emergency）

### 双统帅架构 + 零信任审计 Phase A

| 类别 | 内容 |
|---|---|
| 双统帅协作 | Claude Opus 4.7 + Codex GPT-5.5 high effort = 双统帅，DeepSeek V4-Pro = 单文件贪吃蛇执行者；7 次 Codex 协商决策 |
| DeepSeek wrapper 修 | `~/.local/bin/deepseek` 加 `--allowedTools Read Write Edit Bash Glob Grep --add-dir` 永久投资 |
| 发现 wrapper 致命 bug | spawn `claude -p` agent loop 跑长任务挂死（CPU 0% 20+ 分钟），改 curl 直调 API 单文件粒度 |
| Codex 第 1 轮全量审 | 16 finding (1C/6H/8M/1L)，13 文件覆盖 |
| DeepSeek 贪吃蛇 50 文件 | curl + code-evidence packet + 反向引用 + 上游事实摘要，~235 finding (9C/53H/117M/72L) |
| 总 finding | 251 个，aggregate `~/.claude/plans/audit-findings-20260514/master-findings.tsv` |
| 自动预筛 | evidence-verification.tsv：17 HIT / 7 MISS / 92 NO_CMD / 120 NOT_GREP |
| Memory 新增 | feedback_quality_over_speed / feedback_leaked_key_policy |

### CI 盲区治理（紧急发现 + 修复）

| 阶段 | 内容 |
|---|---|
| 发现 | CI 三天没跑，根因：ci.yml 缺 push trigger（注释明确"只 PR 触发减少排队"，与最近 16 commits 直推 develop 模式冲突） |
| 第 1 修 | ci.yml 加 push trigger（commit 51b3c035 已合 develop） |
| 第 2 修 | pre-push hook 软治 develop 直推（**PR #748 CI 跑中**） |
| 第 3 修 | PR #749 emergency unblock 5 commits 修 3 天累积 5 层洋葱（test import × 3 + ProfileManager environment runtime detection + cherry-pick docaudit fixture） |
| 安全决策 | server secrets 全干净，决定不公开 repo（保留商业策略），Free GitHub 无 branch protection 改用 pre-push hook 软治 |

**当前阻塞**：PR #748 CI 跑完即合并；Phase 2-5 audit 收口工作（~92 个高优先 finding 待 Claude 核验）。

## 本轮上午完成（2026-05-14，工程治理收尾）

| 类别 | 内容 |
|---|---|
| 6 个新 Skill | verify-audit-report / dependency-propagation / sprint-contract / post-merge / api-research / snapshot-diff-review — F 规则全部有 skill 执行器 |
| 依赖传播链全量复核 | engineering → product-vision → ADR-001/002 → NFR → architecture — 6 个根文档 ~20 个下游一致性验证 |
| architecture.md 补齐 | DataExecutor actor（Phase 2 核心架构变更）DI 图/数据流/模块表/设计决策 4 处更新 |
| 源文件头防腐 | 237 文件 `Created by NotBad Labs on DATE.` → `Created by NotBad Labs.` — Codex + Claude 零分歧 |
| 文档日期修复 | 8 个 last_verified 过期修复（04-14 → 05-14）|
| auto-commit 记忆 | 改动完成后主动提交推送，不让用户提醒 |


## 历史归档

历史 sprint（2026-04-15 至 2026-05-09）已归档到 [`docs/memory/checkpoints/2026-05-15-status-archive.md`](docs/memory/checkpoints/2026-05-15-status-archive.md)，含：

- 2026-04-18→19 Harness Engineering Stage A+B 7 PR (#673-#679)
- 2026-04-15~16 密集开发 24 PR (#594-#624)
- 2026-04-16~17 Sprint 13 PR + Phase 4 P1-P3 (#628-#667)
- 2026-04-19 晚 Stage C/PR-6/7 + Codex 3 PR sprint (#688-#696)
- 2026-04-21 现代化 Sprint Phase 1-2 (#700-#706) + #15 CloudKit (#704)
- 2026-05-08→09 基线审计 ~45,500 行 + 14 Warning 闭合 (#739-#740)

---

## 当前状态（2026-05-15）

**Phase 2 + Phase 2.N + 零信任审计 Phase 5 全部收尾完成**。软件内部零阻塞问题。下一步仅余 Apple 账号阻塞链 + #626 真机待验 + #699 backlog Could Have 项。

**基线审计（2026-05-08→09）**：DeepSeek v4 Pro 全量逐字审计 ~45,500 行，Codex GPT-5.5 + Gemini 3 Pro 三方交叉验证。结果：**0 Critical / 14 Warning / 8 Info**，评分 8.5/10。详细报告 `docs/memory/checkpoints/2026-05-08-baseline-audit.md`。

**14 Warning 全部闭合**（PR #739 + #740）：13 修复 + 1 记录为有意设计（SnapDrillUITests 命名冲突）。X5 Share Extension EXIF 临时保留记录为设计级考虑，后续排期。

| 外部阻塞项 | 说明 | 状态 |
|---|---|---|
| Apple 开发者账号 (#163 链) | $99 年费待缴 | 用户控制 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 待真机验证 |
| TestFlight Build 6 (#161) | 需 Apple 账号 | 用户控制 |

### Apple 账号阻塞链（用户主动延迟至 5 月缴费）

Enrollment ID 83VZW7VJKK **已通过 Apple 审核**，$99 年费用户主动延迟到 2026-05。不是"等 Apple 审批"，而是"等用户决定何时缴费开闸"。所有下游功能随时可启动，节奏由用户控制。

| Issue | 内容 | 阻塞原因 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | 已通过审核，等用户缴费 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 ← #163 |
| #485 | iCloud CloudKit 同步 | 需 CloudKit Container + StoreKit ← #163 |
| #486 | Word 导出 | 需 StoreKit ← #163 |
| #490 | App Store 提交准备 | 需公司账号 + 真机验证 ← #163 |
| #161 | TestFlight Build 6 | 需真机验证 ← #163 |

### 待清理

- ~~113 个历史分支待清理~~ 已全部清理（本地 1 + 远程 2 = 纯净状态）

## 产品决策记录

> 决策通过 ADR 管理（`docs/decisions/`），此表为索引。

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | [ADR-002](docs/decisions/ADR-002-remove-att-authorization.md) |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | [ADR-001](docs/decisions/ADR-001-smart-paper-analytics-pricing.md) |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- 写 Xcode Review 提示词前，确认 STATUS.md 当前焦点段是最新的
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批
- Codex/Gemini 审查发现的问题，必须提交回原质疑方复核才能合并（F-016）
- CI 失败是致命信号，不能继续推进（F-007 时点 1）
- UI/SDK 改动必须先查阅 Apple 最新文档（F-017）

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
