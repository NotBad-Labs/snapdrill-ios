OpenAI GPT-5 / Codex CLI（异源 reviewer）执行本次 M-001 sign-off。

# Verdict

BLOCK

# 摘要

M-001 v1 draft 的主体方向正确：多方启动、模型 ID 验证、Boot/Action Gate/Context Map、主笔轮换、单方执行窗口、sync-status、私下授权同步等主题都落在 M-000 §4 / §11.1 的派生范围内。字数实测为 11641 nwc，与 frontmatter 自报一致，override_rationale 也按 M-005 §J.2 给出章节级与段级证明。

但本轮不能 ratify。第一处 BLOCK 是 §11 标题和 M-006 §6.4 都要求“CLI/API 调用前”脱敏，M-001 §11.1 却把主路径写成 PostToolUse；这无法在命令执行前阻断 L0/L1 泄露，且与 §11.3 的“阻塞命令”动作不自洽。第二处 BLOCK 是 §5 / §13 对 M-000 §3 独立性四层的“真 grep 对照”声明不成立：M-001 §5 四节实际只覆盖 L-ii / L-iii 的不同形态，缺 L-i 训练谱系验证和清晰的 L-iv 任务输入未泄露中间结论映射，复现了 [../meta/user-decision-log.md#025](../meta/user-decision-log.md#025) / [../meta/user-decision-log.md#026](../meta/user-decision-log.md#026) 所警示的数字/列项视觉对齐盲点。

# 逐章评估（D1-D7）

| ID | Verdict | 依据 |
|---|---|---|
| D1 可追溯性 | CONDITIONAL | 大多数章节有来源锚：M-001 frontmatter derived_from 指向 M-000 §4 / §11.1 / MC-2，§4.2 指 MC-2 + M-005 §D.1，§8 指 M-002 §4.4 + M-005 §I.1，§10 指 M-002 §11 + MC-11。但 §13 对 §5 的“原文镜像”声明与 M-000 §3 原文不一致，削弱追溯可信度。 |
| D2 可验伪性 | BLOCK | §11.1 使用 PostToolUse 时，§11.3 的“检测到 L0 特征 -> 阻塞命令”不可在事前成立；这是可验伪执行矛盾。其他章节多数有违反信号，例如 §4.1、§4.2、§5.5、§8.4、§9.4、§12.2。 |
| D3 下沉证明 | PASS | frontmatter override_rationale 对 13 章逐章说明不可下沉、不可省略，并对 §5 / §8 给段级压缩分析；结构上满足 M-005 §J.2 v2。 |
| D4 目的关联 | CONDITIONAL | §2 明确映射 P1/P3/P4/P5/P6/P7/P8，核心目的链成立；但 §13 的接口表自述写成“P1/P3/P4/P5/P6/P7 已选 6 项，P8 由 §9 承载”，而 §2 表实际已经列 P8，属自反性列项不一致。 |
| D5 边界一致 | BLOCK | M-006 §6.4 要求 CLI/API 调用前执行脱敏检查，M-001 §11.1 的主路径是 PostToolUse；这把 M-006 的事前边界降成事后告警，交叉接口不一致。 |
| D6 字数密度 | PASS | 按 task def 指定命令实测 `11641` nwc，等于 frontmatter `word_count_actual: 11641`；超参考篇幅后已提供章节级证明和 §5 / §8 段级证明，满足 M-005 §J.2 / §J.7。 |
| D7 backlog 覆盖 | PASS | MC-2 在 §4.2 落为启动多家任务前验证模型 ID 与 SSOT 刷新；Antigravity 独家发现 1 在 §9 落为私下授权 / 私有 plan 派生链同步。未参考 AGY sign-off 原文，仅按 task definition 指定项核查 M-001 正文吸收情况。 |

# BLOCK finding

## B1: §11 的 PostToolUse 设计无法实现“调用前脱敏”和 L0 阻断

**具体事实错误**：M-006 §6.4 明确规定“CLI / API 调用前的脱敏 hook”，并列出写 docs/audits、调用外部 CLI、Bash stdin、上传到外部服务前必须执行脱敏检查（`docs/meta/M-006-data-governance.md` lines 218-227）。M-001 §11 标题同样写“CLI 调用前的脱敏 hook 实现”，但 §11.1 把触发器主路径写成 `PostToolUse` matcher `Bash`，仅补一句“也可以是 PreToolUse”（`docs/meta/M-001-collaboration-workflow.md` lines 371-380）。随后 §11.3 又要求“检测到 L0 特征 -> 阻塞命令（exit 1）”（lines 396-400），这与 PostToolUse 的事后时机冲突。

**可证伪反假设**：如果 M-001 §11.1 把强制路径改为 PreToolUse 或外部 CLI wrapper 的事前检查，并把 PostToolUse 降为日志/复核兜底，那么 §11.3 的“阻塞命令”才可执行；当前文本以 PostToolUse 为主路径时，命令已经执行，无法证明阻断成立。

**明确风险路径**：若 ratify 当前 §11，智能体可能把含 L0 凭据或 L1 本机路径的 prompt / stdin 发给 `agy`、`codex`、`gemini` 等外部 CLI 后，PostToolUse 才告警；M-006 §5.2 的 L0 硬约束和 §6.4 的事前脱敏边界会被虚假满足，造成泄露后才“阻塞”的治理假象。

## B2: §5 / §13 的“独立性四层原文镜像”声明不成立

**具体事实错误**：M-000 §3 原文四层是“模型权重或训练谱系不同、运行实例不同、上下文互不可见、任务输入未泄露其他方中间结论”（`docs/meta/M-000-meta-vision.md` line 46）。M-001 §5 四节分别是 worktree 隔离、分支隔离、context 隔离、.claude.md / memory 隔离；其中 §5.1 / §5.2 都标为 L-ii 运行实例，§5.3 / §5.4 都标为 L-iii 上下文形态（`docs/meta/M-001-collaboration-workflow.md` lines 151-178）。§13 却声明“§5 物理隔离 4 节”已与 M-000 §3 独立性四层原文 4 项 grep 对照（lines 448-454）。

**可证伪反假设**：如果 §5 明确补出四层映射，例如 L-i 模型权重/训练谱系验证（可引用 §4.2 / M-005 §D.2）、L-ii worktree/分支/实例隔离、L-iii context/.claude.md/memory 互不可见、L-iv 任务定义书不泄露其他方中间结论，并在 §13 按这四项逐项声明，那么“4 层原文镜像 + 派生展开”才成立。

**明确风险路径**：按当前文本 ratify，会让“worktree / 分支 / context / memory”这四个操作项被误认为覆盖了 M-000 的四层独立性；同 vendor 多端点、未验证训练谱系、或任务定义书泄露其他方中间结论时，仍可能被错误标为“已满足四层隔离”。这正是 [../meta/user-decision-log.md#025](../meta/user-decision-log.md#025) / [../meta/user-decision-log.md#026](../meta/user-decision-log.md#026) 所记录的列项视觉对齐盲点。

# CONDITIONAL finding

## C1: §13 PRIMARY 接口表自述与 §2 实际表不一致

§2 实际列出 P1/P3/P4/P5/P6/P7/P8，排除 P2（`docs/meta/M-001-collaboration-workflow.md` lines 71-79）。§13 左列却写“P1/P3/P4/P5/P6/P7”，右列又说“P8 Overrule 由 §9 局部承载”（lines 450-453）。这不是独立 BLOCK，因为 P8 在正文 §2 / §9 确有承载，P2 由 M-002 全局承载也可成立；但自反性标注本身是 task def 要求真 grep 的列项，应修成“§2 PRIMARY 接口表 P1/P3/P4/P5/P6/P7/P8；P2 由 M-002 全局承载”。

## C2: §6 对 #006 A-F 的吸收说明应拆清“本章承载”与“跨章承载”

#006 A-F 原文包含 Boot 两项、STATUS minimal stub、workflow -> protocol 迁移、feedback 移出 Boot、AGENTS 三段架构、protocol.md ≤200 nwc（[../meta/user-decision-log.md#006](../meta/user-decision-log.md#006)）。M-001 §6 直接承载 A / E 的核心结构，C / F 由 `docs/protocol.md` 与 §6.2 间接承载，B 的 sync-status 主要在 §10 承载，D 仅以 Context Map 索引位间接承载。§13 把 §6 Boot 三段架构标成“原文镜像”时，应说明这是“跨 §6 + §10 + protocol.md 的吸收”，否则容易被误读为 §6 单章逐项覆盖 A-F。

# 自反性标注

**身份**：OpenAI GPT-5 / Codex CLI（异源 reviewer）。

**禁止材料执行情况**：未参考 AGY / DeepSeek sign-off，未读取 M-002 / M-006 历次 sign-off 报告，未读取 Claude commit message 详情，未读取 M-001 起草讨论。工作区中存在未跟踪 `docs/audits/signoff-agy-cli-m001.md`，但本报告未打开该文件。

**列项原文真 grep 执行情况**：

| 对照项 | grep 结果 | 结论 |
|---|---|---|
| M-000 §2 P1-P8 | `rg '\| P[1-8] \|' docs/meta/M-000-meta-vision.md docs/meta/M-001-collaboration-workflow.md`：M-000 lines 31-38 给出 P1-P8；M-001 §2 lines 71-79 覆盖 P1/P3/P4/P5/P6/P7/P8，排除 P2。 | 正文承载基本成立；§13 列项自述需修 C1。 |
| M-000 §3 独立性四层 | `rg '独立性至少包含四层|模型权重|运行实例|上下文互不可见|任务输入未泄露|worktree 隔离|分支隔离|context 隔离|\\.claude\\.md / memory' ...`：M-000 line 46 给四层；M-001 §5 lines 151-178 只显式映射 L-ii / L-iii。 | 不通过，构成 B2。 |
| #006 A-F | ``rg 'A\\. Boot\|B\\. `STATUS\\.md`\|C\\. `docs/workflow\\.md`\|D\\. `docs/memory/feedback\\.md`\|E\\. `AGENTS\\.md`\|F\\. `protocol\\.md`\|Boot 必读\|Action Gate\|Context Map\|protocol\\.md 主体' ...``：#006 line 96 给 A-F；M-001 §6 lines 195-214 覆盖 Boot / Action Gate / Context Map。 | 部分通过；需按 C2 说明跨章承载。 |
| 字数实测 | `awk 'BEGIN{c=0} /^---$/{c++;next} c>=2 {print}' docs/meta/M-001-collaboration-workflow.md \| tr -d ' \\t\\n' \| wc -m` 输出 `11641`。 | 与 frontmatter 一致，D6 PASS。 |

**复盘**：本轮故意不按“4 节 vs 4 层”的视觉对齐放行，而是逐项 grep 原文并核对语义映射。两个 BLOCK 都来自“文字表面合规但执行语义不成立”：PostToolUse 不能事前阻断，四个操作节不能自动等同四层独立性。
