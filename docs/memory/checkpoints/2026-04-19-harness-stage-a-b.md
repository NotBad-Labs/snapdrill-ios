---
last_verified: 2026-05-13
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-19 Harness Engineering Stage A+B

## Goal

把 SnapDrill 现有的 80% harness 基础设施（F-008 三方对抗 / skills / hooks / rules）按 Anthropic 2026-03-24 *Harness design for long-running apps* 蓝本补齐 5 个断点：编码前契约、量化 rubric、反模式启发式、权限 SSOT、session metrics。源自 `docs/archive/research/harness-engineering-study-20260418.md` + plan `~/.claude/plans/resilient-floating-quasar.md`（7 PR 分 3 阶段，本轮 Stage A+B 共 5 PR，另 2 补漏 PR）。

## Done（7 PR 全合并）

| PR | 主题 | 关键改动 | 受影响 layer |
|---|---|---|---|
| **#673** | 补齐 Phase 4 历史 checkpoint | `docs/memory/checkpoints/` 新建目录 + P2/P3/tech-debt 3 个 checkpoint + `memory/README` 条目 + `STATUS.md` 日期 | snapshot |
| **#674** | Harness Engineering 三方研究归档 | `docs/archive/research/harness-engineering-study-20260418.md`（3000+ 字，三方共识 + URL 表 + P1~P3 可行动条目） | archive |
| **#675** | Sprint Contract + F-018 | `.github/ISSUE_TEMPLATE/feature_request.md` + `chore.md` 加 Sprint Contract 段；`workflow.md` 加《编码前契约》；`feedback.md` F-018 | pattern + snapshot |
| **#676** | 反模式启发式 + F-019 | `Scripts/anti-pattern-scan.sh` + `.claude/hooks/post-merge-checkpoint.sh` 扩展；`feedback.md` F-019 | pattern + snapshot |
| **#677** | Permission Model SSOT | `docs/standards/permission-model.md`（126 行 5 节）+ `.claude/rules/permission-model.md` + `CLAUDE.md` + `KNOWLEDGE_MAP` + `principles/README` 同步 | pattern |
| **#678** | session-metrics hook | `.claude/hooks/session-metrics.sh` + `settings.json` PostToolUse `.*` matcher + `phase-closeout` skill Metrics 段 + `.gitignore` | pattern |
| **#679** | cross-audit 量化 rubric | `.claude/skills/cross-audit-consensus/SKILL.md` §2.5 四维 rubric；`cross-audit/SKILL.md` 委派模板；`principles/collaboration.md` 量化评分门 | pattern |

## Open

- **Stage C**（未启动，暂缓）：
  - PR-6 SnapshotTesting + 15 核心 View baseline（1.5-2 天）
  - PR-7 CI snapshot diff + xcresult artifact（1 天）
- **tech-debt 遗留**：
  - #665 EditProfileView PhotosPicker UX（等 Xcode Review）
  - #626 QuestionSplittingService PoC 真机准确率验证
  - LocalizationKeys 1503 行拆分（Issue #666 方案 B）

## Decisions

- **中文译名**：沿用「驾驭工程」（已成既定事实），项目内文档保留英文 `Harness Engineering / Harness`（三方共识，见 `docs/archive/research/harness-engineering-study-20260418.md` §9）
- **术语策略**：只落机制**不引术语**进 `docs/standards/`（避免术语通胀，用户决策）
- **Sprint Contract 位置**：Issue 模板内嵌字段（最轻量，与现有 workflow 无缝衔接），不独立 `docs/sprints/` 文件
- **评分 vs 裁决分离**：rubric 量化分数决定"是否 retry"（硬阈值），共识/冲突采纳仍走 2/3 原则；避免 "高分即合并" 的绕过风险
- **反模式启发式不自动改规则**：启发式命中只 stderr 警报（F-019），出现 3 次后人工升级（Claude 提议 + 用户批准），避免 AI 自写纪律循环
- **Permission Model 先立 SSOT 不加 CI 校验**：plan 明确 "等稳定再加门禁"，避免一开始就给配置加硬约束
- **session-metrics 不记 token**：Claude Code 当前不通过 hook 暴露 input/output token，自建 HTTPS 代理 ROI 不匹配
- **拒绝独立 Planner/Generator/Evaluator 进程**：Anthropic 蓝本 20× 成本对单人项目不值
- **Stage C 暂缓**：Stage A+B 机制需要先用几天验证真实效用，再判断 Stage C 是否调整（避免"急着盖楼"）

## Risks

- **F-005 漏执行**（严重）：本轮 Claude 连续推 5 个 PR 没做 Codex/Gemini 对抗性审查，用户发现后补救（Auto mode 下 Claude 把 "提 PR" 当 "完成"，漏 DoD 最后一关）。补救方案：下一次 plan 里给 F-005 加 Auto mode 豁免说明，或加 pre-push-adversarial-review hook。**本次未落地此修复**，遗留为下轮 plan 起点
- **主线程 Claude 自审 bias**：本轮 Claude 自审给 5 PR 平均 9.3 分，Codex 给 7.5 分，方差 > 2.5 触发必须 retry。根因是 Claude 既是实施方又是评分方，看"完成度"而非"吻合度"。补救：cross-audit-consensus skill §2.5 可加一条 "Claude 作为实施方时自审分作参考不作裁决锚点"（未落地）
- **Gemini 评分偏高**：本轮 Gemini 给 3/5 PR 打 10.0，比 Codex 高 1-4 分。Gemini 对定性维度敏感，但对 scope 漂移弱。补救：Gemini 委派 prompt 里强制要求 "逐条对照 plan 条目评分"（未落地）
- **PR 间合并冲突连环**：本轮 7 PR 合并时解了 3 处冲突（STATUS.md / feedback.md F-018vs F-019 / permission-model §3 hook 8vs9）。这是 sprint 内多 PR 同区改动的常态，不是设计问题
- **Sprint Contract 未经真实功能 PR 检验**：F-018 刚立，本轮 Harness PR 开工时未填 Contract（属 bootstrap 例外）。首个按 F-018 流程走的 feature PR 会暴露字段设计是否合理
- **rubric 4 维阈值无数据校准**：Retry 阈值 7.0/5.0/8.5/2.5 是抄 Anthropic 蓝本的设计假设，需若干 PR 实战后校准
- **反模式启发式假阳性**：PR #657（40 文件 YAML 迁移）已证明会误报 scope 膨胀。F-019 机制（人工判断 3 次才升级）是对冲

## Next

按 ROI 排序：

1. **[最高 ROI，零成本]** 下次 feature / chore Issue 实际走 F-018 Sprint Contract 流程，验证字段设计 → 调整模板（如有需要）
2. **[高 ROI，半天]** 下次 PR 合并触发 cross-audit，实际用 rubric 4 维打分 → 校准阈值
3. **[中 ROI，半天]** 解决本 Checkpoint Risks 里的 3 个未落地项（F-005 Auto mode 豁免 / Claude 自审 bias / Gemini 评分偏高）—— 可合成 1 个 PR
4. **[中 ROI，1-3 天]** Stage C PR-6 SnapshotTesting + baseline（需用户在活跃监督下做，不适合 auto mode 连做）
5. **[低 ROI，观望]** Meta-harness 方向（Stanford arXiv 2603.28052，Claude 单家引用未验证）—— 看社区是否真起来再跟

**阻塞链不变**：Apple 账号 $99 缴费（用户延迟至 2026-05），释放后解锁 #163/#479/#485/#486/#490/#161 六个下游 Issue。

## Metrics

> 数据来源：`.claude/session-metrics.tsv`（PR-5 session-metrics hook 记录）。注：hook 在 PR-5 分支开发期间即生效（settings.json 本地路径生效），故实际记录 window 是 **2026-04-18 15:23 UTC → 2026-04-19 01:02 UTC**，覆盖从 Harness 研究归档开始到 7 PR 全合并 ~9.6 小时的工作。数据不全（PR-5 合并之前的工作未记）。

- 记录窗口 tool call 总数：**47**（样本，非全量）
- Top tool（窗口内）：Bash × 30 · Edit × 8 · Read × 4 · Write × 2 · TaskUpdate × 2
- Session 起止（UTC）：2026-04-18T15:23:11Z → 2026-04-19T01:02:02Z
- Session 时长：**~9.6 小时**（含研究 + 7 PR 实现 + 2 轮三方审 + 冲突解决 + 合并）
- 三方审查耗时：Claude 自审 + Codex `gpt-5.4 --effort high` 两轮 + Gemini 一轮，总 ~40 分钟 wall-clock

**读数提示**：Token 成本未记录（Claude Code hook 不暴露）；Read/Grep 等只读 tool call 在 PR-5 合并前未采集（matcher 那时还是 Edit|Write + Bash）；这些限制已在 `phase-closeout` skill Metrics 段文档化。

## 吃自己狗粮的反馈（本轮机制首次实战）

| 新机制 | 本轮实际使用情况 |
|---|---|
| Sprint Contract (F-018) | **未使用**（Harness PR 开工时 F-018 还未合并，属 bootstrap 例外） |
| cross-audit rubric 4 维 | **使用成功**：一次性挡下 2 个 PR（#677 Codex 6.8 / #678 Codex 5.5），方差 2.56/2.65 > 2.5 触发必须列冲突原因，Codex 反馈促成 7 处修复（C-1~C-8） |
| 反模式启发式 (F-019) | **未触发**（本轮 PR 都小且干净，无 scope 膨胀 / over-generation / test evasion） |
| Permission Model SSOT | **已用一次**：PR-5 新增 session-metrics hook 时触发 §3 Hook 表同步（C-6），验证 SSOT 纪律有效 |
| session-metrics hook | **部分生效**：记录了 PR-5 分支开始后的 tool call，但本 checkpoint 是首次消费数据 |
| Permission Model 覆盖自身 (C-1) | **已生效**：`.claude/rules/permission-model.md` paths 包含 SSOT 本体，改 `permission-model.md` 触发规则加载 |

**核心教训**：**rubric 4 维 + F-016 质疑方批准**是本轮最有价值的组合 —— 在 Claude 自审打出虚高分时（9.3 vs Codex 7.5），rubric 数学硬阈值（方差 > 2.5、综合 < 7.0）强制阻断合并，push Claude 回去修 Codex 的 8 条具体发现。这正是 Anthropic 蓝本 "Evaluator 用硬标准对抗 Generator self-praise" 的本地化验证。
