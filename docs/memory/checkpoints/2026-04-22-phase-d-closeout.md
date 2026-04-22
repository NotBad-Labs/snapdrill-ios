---
last_verified: 2026-04-22
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-22 — 自主迭代系统 Phase D 独立仓抽出 + 消费试点

## Goal

按 Phase D/E scope consensus（三方 cross-audit 裁决），把自主迭代系统从 snapdrill-ios 内部抽到独立仓库 [NotBad-Labs/agent-harness](https://github.com/NotBad-Labs/agent-harness)。snapdrill-ios 保持"孵化器 + 消费者"dual-role，首次以 consumer 身份接入（非破坏性试点）。

## Done（5 PR，一天全链路）

| PR | 仓库 | commit | 内容 |
|---|---|---|---|
| PR-D1 | agent-harness #1 | 98e4430 | 骨架 + **any-agent 定位** + 4 层契约（core / adapter- / preset- / examples）+ denylist CI |
| PR-D2 | agent-harness #2 | fc927cf | docaudit 引擎迁入 + 8 点硬编码参数化 + 34 tests |
| PR-D3 | agent-harness #3 | 6b2408b | CLI `init --minimal/--pragmatic` / `doctor` / `sync --check` + 21 tests |
| PR-D4 | agent-harness #4 | 5affca7 | adapter-claude 8 hooks + 7 skills + settings.example + policy.starter |
| PR-D5 | snapdrill-ios #724 | 798b640f | snapdrill-ios 消费试点（.agent-harness/project.yaml + lock.json + D-003 决策） |

## Phase D 战略锚（用户 2026-04-22 两轮拍板）

1. **工具链加固**：自主迭代系统应普遍通用，能被不同项目复用，随项目演进
2. **独立仓库 + 初始空白骨架**："理想化的自主迭代系统一开始其实是空白的，随项目实战演进自迭代"
3. **any-agent 定位**（override Claude 原主张"Claude Code 原生"）：不自限单一生态
4. **直接开空仓 + 双仓并行**：private / MIT / main + feature PR 流程

## 三方 cross-audit consensus 结果

| 方 | 自评 | 角色 | 状态 |
|---|---:|---|---|
| Codex gpt-5.4 high | **8.75** | 主锚 | ✅ |
| Gemini 3.1-pro | 8.5 | 次锚（守纪律） | ✅ v2 内联 prompt |
| Claude 主线程 | 7.75 | 参考 | ✅ |

方差 1.0 < 2.5，共识度高，立即推进。

### 共识 ≥ 2/3（12 条核心裁决）

- 独立仓库优于单仓分层（3/3 ✅）
- **CLI 工具 + 模板仓库**形态（2/3，Claude submodule 落败）
- B 档务实骨架（3/3 ✅）
- **Phase D 非破坏性**消费试点（2/3，Claude "删本地副本"被 override）
- Phase D = 5 PR（Codex 切法，Claude 9 PR 与 Gemini 3 PR 折中）
- 反哺硬门槛：Codex **two-consumer rule** + Gemini **3 迭代周期** + Claude **去项目化 grep** 三家互补
- D/E 严格依赖（D1-D3 先于 E，D4/E1 可局部并行）
- CI denylist 防污染（3/3 ✅）
- 核心风险：过度抽象 / YAGNI 违反（3/3 ✅）
- 核心风险：双仓版本漂移（3/3 ✅）
- 核心风险：反哺门槛过高 → 腐烂（3/3 ✅）

## Decisions

1. **D-003（snapdrill-ios/docs/memory/decisions.md）**：抽出 agent-harness 独立仓库
2. **命名** `agent-harness`（Codex 主推荐；Claude `meta-dev-loop` 和 Gemini `gemini-agent-core` 落败）
3. **仓库形态**：CLI + 模板（`bin/agent-harness` Python entry + `core/cli/` 模块 + `templates/base/`）
4. **消费契约**：`.agent-harness/project.yaml` + `lock.json`（锁 upstream commit）
5. **preset 分层**：core / adapter-claude / preset-ios（空，反哺积累）/ examples
6. **反哺双轨**：
   - 轻量轨：SnapDrill 改完 → meta PR（6 硬门槛 + 3 迭代周期 + 去项目化 grep）
   - 半自动轨：`extract-candidate` CLI 扫描 drift，Phase E 实现
7. **防污染四件套**：PR 模板 "Project-specific residue removed" + CI denylist + preset 分层 + two-consumer rule
8. **14 个 `AGENT_HARNESS_*` env var**：hooks/skills 全部参数化，不依赖外部 config 文件

## Decisions 过程中 Claude 主张被 override 的两项

1. **定位**：Claude 原主张 "Claude Code 原生 meta-dev-loop"（防假通用），被用户 override 为 "any-agent harness"（更开放）。工程上通过 preset 分层 + `core/` denylist 禁硬编码 agent CLI 来保持架构诚实
2. **Phase D 动作**：Claude 原主张 PR-D9 "删 snapdrill-ios 本地副本"，被 Codex + Gemini 2/3 consensus 改为"非破坏性消费试点"（保留本地，只加 `.agent-harness/` 契约）

## Risks

| 严重度 | 风险 | 缓解 |
|---|---|---|
| 高 | 假通用（单项目证据不足） | Phase E 必须做第二 consumer 实证 |
| 高 | 双仓版本漂移 | `lock.json` + 未来 CI bump 检测 |
| 高 | 过度抽象 / YAGNI 违反 | B 档迁入三门槛；`sync --check` 不 `--apply` |
| 中 | 反哺门槛过高 → 腐烂 | 轻量轨道（不强制 RFC）；`extract-candidate` 降摩擦 |
| 中 | agent-harness 被消费项目污染 | CI denylist 强制；自反修复 snapdrill 术语已验证 |
| 中 | 双仓 cognitive overhead | KNOWLEDGE_MAP 更新 / `/resume-from-handoff` 处理 |
| 低 | 机制崇拜（Codex 独有警示） | 每机制有触发 / 退出 / 成本预算 |

## 方法论实证

### denylist 自反守门真修（而非放水）

PR-D1 合并前 CI 第一轮挂 denylist：`core/README.md` 写了"从 snapdrill-ios 参数化迁入"被 `snapdrill` 关键字扫中。**选择真修** README 措辞（"从孵化项目迁入"），不改 CI 规则。PHILOSOPHY 第 3 反模式"被消费项目污染核心"第一次就自证有效。

### Commit message 撞自己 hook

PR-D4 commit 失败：message 里写 "rm -rf / / git push -f" 作 hook 功能描述，被 snapdrill-ios 本地 `block-dangerous-bash.sh` 拦住。**讽刺地证明 hook 工作正常**，重写 message 去掉 pattern。

### Gemini 第一次卡死 + 内联 prompt 成功

三方起草时 Gemini v1 读 `/tmp/` 外部文件 10 min 只出 280 字节；kill + 内联 prompt 重启后 v2 正常产出 8KB（159 行）守纪律评分 8.5。**Gemini 复杂任务工具调用脆弱，简单任务 OK**。

### Commit message 里写 markdownlint 改规则 vs 改内容

PR-D1 合并前 CI 第一轮 markdownlint 挂 55 errors（大头 MD013 行长 80，中文极不友好）。**决策**：`.markdownlint-cli2.yaml` 禁 MD013 / MD060 / MD033 / MD041（工具层不适配中文）；但保留 MD022 / MD031 / MD032 / MD040（真格式问题修内容）。**不是放水**。

## Metrics

| 维度 | 数值 |
|---|---|
| Phase 持续 | 2026-04-22 一天（Phase C 收官后立即） |
| PR 总数 | 5（4 agent-harness + 1 snapdrill-ios） |
| 新仓库文件 | agent-harness 55 files |
| 测试覆盖 | 34 docaudit + 21 CLI = 55 tests（agent-harness CI），0 tests 新增 on snapdrill-ios |
| 代码行数 | agent-harness ~3500 lines（含 tests / config / docs） |
| 本地验证 | denylist clean + markdownlint 0 err + 55 tests OK + bin/agent-harness --version OK |
| CI 事故 | 2 次（denylist 自反 + markdownlint 中文不适配），均当场修复 |

## Next

### Phase E（反哺机制，候选）

按 consensus §5.5：

- **PR-E1** (agent-harness)：`CONTRIBUTING.md` 反哺协议展开（6 硬门槛 + 3 迭代周期 + 安全级定义）
- **PR-E2** (agent-harness)：`extract-candidate` + `propose-upstream` CLI
- **PR-E3** (agent-harness)：`harness-introspection` skill（自省，只产 plan）
- **PR-E4** (snapdrill-ios)：**首次反哺实战** — 选一个低风险候选（如 docaudit 墓碑识别鲁棒性、或 `/knowledge-health` 首次实测产出的 finding）走完整 `extract-candidate → propose-upstream → agent-harness PR`

### 立即可做

- `/knowledge-health` skill 首次实测（Phase C 就应该做，延期到这里）
- snapdrill-ios 可以在某个 tech-debt 机会选择 Claude adapter 的 symlink 实验（非强制）

### 阻塞外

- Apple 账号 $99 延迟到 2026-05（用户控制）
- #626 真机验证（等用户到 iOS 26 真机）
- Phase 2 #699 Issue epic（#6/#7/#8 暂停）

---

**签名**：Claude Opus 4.7（1M context）主线程。Phase D 5 PR 全链路 2026-04-22 一天收官。按 cross-audit-consensus §2.5 主线程裁决员，非评分锚点。
