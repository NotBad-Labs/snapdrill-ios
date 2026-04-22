---
last_verified: 2026-04-22
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-22 — 自主迭代系统 Phase E 反哺机制 + 工具链公开

## Goal

按 Phase D/E consensus §5.5 Phase E，给 agent-harness 加完整反哺机制 —
从"可用骨架"过渡到"可演进框架"。同期按用户决策把 agent-harness 切为
**public 开源**（"应该造福人类"）。

## Done（5 PR，一天全链路）

| PR | 仓库 | commit | 内容 |
|---|---|---|---|
| PR-E1 | agent-harness #6 | 494866f | 反哺详细 rubric（400 行）+ PR 模板 + CONTRIBUTING 升级 |
| PR-E2 | agent-harness #7 | 856861c | extract-candidate + propose-upstream CLI（10 新 tests → 31） |
| PR-E3 | agent-harness #8 | 29d910c | harness-introspection skill（元审查 agent-harness 自身健康） |
| hotfix | agent-harness #9 | 02775c5 | extract-candidate path-matching bug（首次吃狗粮暴露 + 3 回归测试） |
| PR-E4 | snapdrill-ios #726 | ad431be7 | 首次反哺实战 dry-run 记录 + sample proposal draft |

## 同期大动作：agent-harness 切 public

- PR #5 prepare-for-public（3690fff）: README 双语增强 + SECURITY + Issue 模板 + 去 snapdrill-ios URL 硬链接
- `gh repo edit --visibility public`: 成功切换
- 新面貌：<https://github.com/NotBad-Labs/agent-harness>
- 定位：**any-agent harness** — meta-dev-loop kit for autonomous iteration

## Phase E 三原则设计

按 consensus §5.5:

1. **反哺有硬门槛**（防污染）：
   - Codex 主锚 P1 六门槛（two-consumer rule + 去项目化 grep + 可配置 + 可测试 + 低污染 + 生命周期）
   - Gemini 次锚 P2 3 迭代周期量化门槛
2. **工具辅助不替代判断**：CLI 只扫描 + 产 draft，不自动开 PR
3. **只产 plan 不改文件**：harness-introspection / knowledge-health 一致设计

## 首次吃狗粮的 3 项实证（PR-E4）

| # | Finding | 价值 |
|---|---|---|
| 1 | path-matching bug（绝对路径含 `ios` 误判 preset-ios） | ✅ hotfix + 回归测试。**实证 sandbox tests 不能替代真实 consumer 实战** |
| 2 | apple-\* 启发式缺口（无 `apple` 关键词导致 iOS 文档被建议 core/principles） | 📝 Follow-up（S-experimental，未来加启发式 + consumer override） |
| 3 | snapdrill-ios 当前无新反哺候选（PR-D4 通用内容已完整迁完） | 积极信号：**snapdrill-ios 已从"孵化器"过渡为"消费者+稳定 consumer"** |

## Decisions

1. **Phase E 反哺机制采用轻量 + 半自动双轨**：
   - 轻量轨：consumer 改完直接开 meta PR（不要求 RFC）
   - 半自动轨：`extract-candidate` 定期扫描产出候选清单；`propose-upstream` 模板化 PR body
2. **反哺流程（6 step）**：
   - 改 overlay（consumer 本地积累）→ extract-candidate → propose-upstream → 填 TODO → 开 PR → 合并后 bump lock.json
3. **agent-harness 公开定位**：any-agent harness（不自限 Claude Code），当前实现 Claude Code + Codex CLI + Gemini CLI 三方 adapter
4. **harness-introspection vs knowledge-health 角色分工**：前者审 agent-harness 仓库本身，后者审 consumer 项目
5. **2 个 follow-up bug 不在 Phase E 修复**：
   - apple-\* 启发式（Finding #2）
   - consumer project.yaml `consumer_terms` 支持文档完整化

## Risks

| 严重度 | 风险 | 当前缓解 | 长期策略 |
|---|---|---|---|
| 高 | 假通用 / 单 consumer 风险（Finding #3 也验证了） | harness-introspection skill 的 step 7 硬 check | Phase F 做第二 consumer 实证 |
| 高 | 过度抽象 / YAGNI 违反 | contribution-rubric P1.3 + 启发式评分 | Reviewer 独立思考 + `sync --apply` 未实现 |
| 中 | 反哺门槛过高腐烂 | 轻量轨 + CLI 辅助降摩擦 | Phase F 观察实际反哺频率 |
| 中 | Public repo 后 issue 轰炸 | SECURITY.md + ISSUE 模板 | 按维护能力调整 triage 节奏 |
| 低 | agent-harness 代码的 CLI bug 再次暴露 | harness-introspection 定期跑 | 每个 phase 收官前必跑 |

## Metrics

| 维度 | 数值 |
|---|---|
| Phase 持续 | 2026-04-22 一天（同 Phase D 同日） |
| PR 总数 | 5（4 agent-harness + 1 snapdrill-ios + 1 hotfix） |
| 新文件 | agent-harness: 5（rubric + PR template + 2 CLI cmd + introspection skill） / snapdrill: 2（dry-run 归档 + proposal draft） |
| 测试增量 | agent-harness CLI tests 21 → 34（+13 新增反哺 + 回归测试） |
| Sandbox tests 总 | agent-harness: 68（34 docaudit + 34 CLI） |
| 代码行数（agent-harness 新增） | ~1800 行（400 rubric + 600 CLI + 240 skill + 150 PR template + 其他） |
| 首次吃狗粮发现 bug | 1 fixed + 1 follow-up + 1 positive signal |

## 方法论实证（本 phase 的关键收获）

1. **首次吃狗粮暴露 bug** — PR-D 阶段 sandbox tests 34 + CI denylist 全绿，但一接触真实 consumer 路径（含 `ios` 子串）就暴露。**没有任何 sandbox 能完整模拟真实 consumer 路径**。
2. **"无新反哺候选" = 积极信号** — 消费者角色成熟度的指标，不是失败。
3. **harness-introspection skill 的"单 consumer 风险硬 check"** 直接呼应了 Finding #3 的 positive signal —— 本 phase 同时设计了 check 和验证了 check 的必要性。
4. **public repo 决策伴随的"去私有 URL 硬链接"清理** 是 Phase E 的隐藏工作 —— 不在 consensus 的 scope 里，但用户的战略升级（"造福人类"）立即触发。
5. **agent-harness 的 CI denylist 自反守门**在 Phase E 再次证实（PR-E2 的 `cmd_extract_candidate.py` 豁免 + main.py 的 `.claude/` 硬链接 hotfix），**机制本身在实战中锤炼**。

## Next

### Phase D→E 全链路收官后（下一步候选）

1. **Phase F（反哺成熟化 + 第二 consumer）候选**：
   - 第二 consumer（玩具级）接入实证（消除"假通用陷阱"风险）
   - agent-harness semver / CHANGELOG / release 流程
   - `sync --apply` 真实现（Phase E 显式 reserved）
   - apple-\* heuristic follow-up（Finding #2）修复
2. **snapdrill-ios 回归产品工作**：
   - #626 QuestionSplittingService 真机验证
   - Apple 账号 $99 缴费开闸（用户控制）
   - Phase 2 剩余 PR #6/#7/#8（typed throws / staged migration / ModelExecutor）
3. **agent-harness 社区建设**（低优）：
   - 启用 GitHub Discussions
   - 写几个 hello-world 集成例子
   - 观察是否有外部 star / issue / PR

### 不启动新 Phase，而选"稳定期"（推荐）

Phase D→E 一天跑完两个 phase 共 10 PR + 2 sync PR。**信息量已经很大**，建议进入稳定期：
- 观察 agent-harness public 后是否有 external 反馈
- snapdrill-ios 回到产品迭代节奏
- 等 Phase F 有明确触发（第二 consumer 出现 / 反哺需求积累 / bug 积累）再启动

---

**签名**：Claude Opus 4.7（1M context）主线程。Phase E 5 PR 全链路 2026-04-22 下午收官（继 Phase D 同日上午收官）。agent-harness 公开上线同期完成。
