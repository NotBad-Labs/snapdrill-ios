---
last_verified: 2026-05-24
layer: snapshot
scope: audit-archive
freshness:
  max_age_days: 365
  decay_trigger: [historical_record]
source_adr: docs/decisions/ADR-004-doc-system-deep-clean.md
phase_period: 2026-05-19 to 2026-05-20
---
# 结构层清洁实施历史记录

> 本文件从 ADR-004 物理切出（user-decision-log #007 激进拆分裁决）。记录 Phase 0-9 结构层清洁实施、当时三方工具观察与旧工具选型立场。方法论活性骨架仍见 [ADR-004 主文档](../../decisions/ADR-004-doc-system-deep-clean.md)；当前模型版本事实见 [docs/tech/reference/agent-cli-models.md](../../tech/reference/agent-cli-models.md)。

## 三方对抗参与（历史记录）

- **Claude Opus 4.7**（主线程）：执行所有 Phase 工作
- **Codex GPT-5.5**：5/18 完成 52 文档 verdict 提案；5/19 second-opinion review 发现 1 处当前 bug（verdict artifact drift）+ 9 类未扫盲区候选 + 6 个 docaudit check 推荐
- **Gemini 3 Pro Preview**：5/19 完成 52 文档独立 verdict（5 batches），但 100% VALID 显示 over-endorse 模式，按 cross-audit-consensus 权重规则降为参考
- **DeepSeek V4 Pro**：5/19 尝试 second-opinion review，26 分钟无输出后 kill；与之前会话开头 tool_uses=36 提前收尾是同类问题

## 工具稳定性观察

| 工具 | 用途 | 本次稳定性 | 后续选型建议 |
|---|---|---|---|
| Claude Opus 4.7 (主线程) | 全程执行 | 稳定 | 主线程主力 |
| Codex GPT-5.5 | verdict + second-opinion | 稳定（5 batches + 1 review 全成功） | second-opinion 首选 |
| Gemini 3 Pro Preview | verdict | 稳定但 over-endorse | verdict 类对抗任务慎用；适合差异化任务（代码 review） |
| DeepSeek V4 Pro | second-opinion | **卡死 26 min** | 暂不再作为对抗 reviewer；适合定向小任务 |

## Phase 0-3 实施总结

| Phase | 时长 | Commit | 关键产出 |
|---|---|---|---|
| Phase 0 | 30 min | （报告） | 接管 52-doc 审计成果，三方提案汇总 |
| Phase 1 | 1.5 h | f40fcdcf | SSOT 自洽体检（KM §1 §4 跳号 + Dep Map §1 缺号 + 漏列文件补全 + 软上限触线机制）|
| Phase 2 | 3 h | bdb7cbc6 + fcb288a0 + 5d8b904e | 52 文档 verdict 终态 47/4/1/0 |
| Phase 3 | 1 h | 18d59a7f + fdcbf92b | 跨文档 contradiction / orphan / ghost ref（1 修复）+ Codex 二意见 |
| Phase 4 | 1.5 h | 36353525 | docaudit 2 个新 check 实现 + 4 文件结构化 gap 字段 + KM 治理规则 + ADR-004 |

## 工具选型决策（2026-05-19 旧立场）

> 本节是 2026-05-19 时点旧立场，已由 M-000 §3/§7.2、user-decision-log #002/#006 和 agent-cli-models.md 接管。

- **DeepSeek**：暂停作为对抗 reviewer（稳定性问题）；适合定向小任务（如代码片段 review）
- **Gemini**：verdict 类对抗任务慎用（over-endorse 模式）；适合代码 review / 差异化视角任务；按 cross-audit-consensus 评分权重段处理
- **Codex**：second-opinion 首选；本次实测最稳定

## 已落地（本会话 commits）

主线 Phase 0-4：

- `f40fcdcf` Phase 1 SSOT 自洽
- `bdb7cbc6` Phase 2.1-2.5 partial（verdict + 批量刷 + 归档 A019）
- `fcb288a0` Phase 2.4 A+B 13 文档闭环
- `5d8b904e` Phase 2.4 C 5 文档闭环
- `18d59a7f` Phase 3.3 ghost ref 修
- `fdcbf92b` Phase 3.4 Codex 二意见 + verdict drift 修
- `36353525` Phase 4 治理升级 — docaudit 11 check + ADR-004 收官

延伸 Phase 5-9（用户在主线收官后追加的「全量补审 + 真全文阅读 + 嵌入 frontmatter 拆分」三段，未列入复用模板因为属于本会话覆盖率追平动作，不是方法论的固定阶段）：

- `6a98bbf7` Phase 5 全量审计 — 剩余 132 文件无死角覆盖 + 10 处修复
- `7a3d2854` Phase 5 副线 — 退役 3 个 stub skill（biometric-auth / network-security / secure-storage）
- `1c71fb01` Phase 7 全量补审 132 文件 — 治理执行层 + Scripts + 配置 + DocC + 散落
- `cafaf4e8` Phase 8 真全文 Read 73 文件 — 修 4 个 latent finding
- `1992453f` Phase 9 — snapshot-testing 拆出嵌入第二 frontmatter 为独立 `snapshot-diff-review` skill

Codex GUI 多轮验证修复（Phase 0-9 收官后由 Codex 独立审计触发）：

- `dbe4547c` Codex Round 1 — 3 Major + 3 Minor
- `c96bb644` Codex Round 2 — 1 Major + 3 Minor
- `2fe2b8b0` Codex Round 3 — 2 FAIL + 2 NEW_FINDING
- `735cc3a7` Codex Round 4 — 1 FAIL + 4 NEW_FINDING（含元数据 stale 数字 + Phase 5-9 归属补全）
- `130f1553` Codex Round 5 — 仅余 3 Minor（含 `.agent-harness` overlay 对齐 15 governance skill）
- `20356a71` audit-ledger 从 Claude 私有空间迁入 `docs/audits/`（与 ADR 同级，对齐 SOC2 / 学术 audit log 行业惯例）
- `1135ef00` Codex Round 6 — 1 FAIL + 3 NEW_FINDING（KM TSV 路径 + auditor/reviewer 字段 + 删除私有副本 + Retention/Lifecycle 表）

> Codex Round 6 总判断「审计边界 + 外审独立性已实质闭环，可停止 Codex 验证循环」。后续若仍有零星 commit 推到本 ADR 主题，**以 `git log` 为准，不再追加 SHA 行**（避免列表无限尾随）。

## 元数据（历史记录）

- 本 ADR 决策者：用户（PO）批准本方法论；Claude 起草 + 实施；Codex second-opinion 提供 9 类盲区候选 + 6 个 check 推荐
- 累计 commit 数与文件触动数：以本 ADR 上方「已落地」段 git SHA 列表 + `git log --oneline 97e266b4..HEAD` + `git diff --stat 97e266b4..HEAD` 为准；本 ADR 内不再硬编码数字（避免后续修复继续推高数字时漂移）
- 审计 LLM 调用：主线 Phase 2 三方对抗（Gemini 5 batch + Codex 5 batch + Phase 3 Codex second-opinion + DeepSeek 卡死 1 次），加 Phase 0-9 收官后 Codex GUI 多轮独立验证（共 6 轮 Round，Codex Round 6 判定收敛后停止）
- 实际耗时：plan 预估 6-11 小时；实际跨多个 session（本 ADR 不再硬编码总时长，原因同 commit 计数）
- Phase 5-9 在 STATUS / handoff / git log 也都有持久化记录；本 ADR 仅作方法论 SSOT，不重复 phase 内事实细节
