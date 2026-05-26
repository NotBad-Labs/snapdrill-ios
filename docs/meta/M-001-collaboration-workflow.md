---
last_verified: 2026-05-26
layer: principle
scope: meta
status: active
ratification: ratified
ratified_at: 2026-05-26
ratified_by: ["user-decision-log #027"]
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, workflow_change, new_vendor_added, isolation_incident]
word_count_actual: 15165  # 正文 Unicode nwc（不含 frontmatter）；M-005 §J.7 标准 `awk + tr + wc -m` 实测 2026-05-26（P4.Fix² Codex Round 2 BLOCK 修复后）
override_rationale: |
  正文 15165 nwc（M-005 §J.7 标准实测，P4.Fix² 后），参考篇幅 2500 nwc，本文超 ~506%。按 M-005 §J.2 v2「分层 + 触发」证明（[#021](user-decision-log.md#021) D-J2=C 裁决：超参考篇幅时 override_rationale 应至少示例 1-2 段最长或最可能冗余的段落）。

  **章节级证明（mandatory）**：以下 13 章不可下沉、不可省略：
  (1) §1 定位 — M-001 在 M-000 §4 + §11.1 派生位置的合法性声明
  (2) §2 与 M-000 PRIMARY 接口 — P1/P3/P4/P5/P6/P7/P8 共 7 项映射（P2 由 M-002 全局承载，M-001 不重复定义），定义本规则对宪法层的承载
  (3) §3 与 M-002/M-003/M-004/M-005/M-006 边界 — 防 5 个派生规则交叉重定义
  (4) §4 多方启动流程 — 任务定义书生成 + 模型 ID 验证 (MC-2) + 异源矩阵核对
  (5) §5 物理隔离操作规程 (M-000 §4 落地) — worktree / 分支 / context / .claude.md 隔离 4 步
  (6) §6 上下文加载顺序 — Boot 必读 + Action Gate + Context Map 三段架构（承接 #006）
  (7) §7 主笔轮换提议流程 (M-005 §H 落地) — 同源连续 ≥3 版触发轮换的提议机制
  (8) §8 单方执行窗口清单 (M-002 §4.4 落地) — 可逆/低副作用动作的具体清单
  (9) §9 私下授权同步流程 (M-005 §I.2 落地 + Antigravity 独家发现 1) — 私有 plan 派生链
  (10) §10 sync-status skill 具体实现 (M-002 §11 接口) — session start/end 机制
  (11) §11 CLI 调用前的脱敏 hook 实现 (M-006 §6.4 接口) — PreToolUse hook
  (12) §12 修订与复审
  (13) §13 自反性标注 — 起草工具 + 列项原文真 grep 验证（[[feedback-numeric-alignment-blindspot]] 应用）

  **段级证明（按 §J.2 v2 触发：作者主张）**：以下 2 段为最可能冗余段落，已分析压缩路径：

  - **§5 物理隔离操作规程（4 节，仅覆盖独立性四层 L-ii + L-iii）**：§5.1 worktree + §5.2 分支 + §5.3 context + §5.4 .claude.md / memory。
    *压缩分析*：4 节**直接覆盖** M-000 §3 独立性四层中的 L-ii（运行实例不同：§5.1+§5.2）+ L-iii（上下文互不可见：§5.3+§5.4）；**L-i 模型权重 / L-iv 任务输入未泄露**由其他章节跨章承载（§5 章首已加四层映射表显式说明：L-i → §4.2 + M-005 §D.2；L-iv → §4.1 + §11）。删除本节任一小节 → L-ii / L-iii 操作步骤断链 → 数据流转层独立性失锚。P4.Fix² 已修正本段从「4 节对应四项」（v1 虚假对照）改为「4 节直接覆盖 L-ii + L-iii」（诚实陈述）。
  - **§8 单方执行窗口清单（4 节）**：§8.1 可逆原则 + §8.2 具体清单 + §8.3 不可逆动作排除 + §8.4 违反信号。
    *压缩分析*：§8.2 具体清单是 M-002 §4.4 的可执行展开（lint / 排序 / 改名 / 等），§8.3 排除来自 M-005 §I.1 结构性决定 + M-006 §8.1 硬边界，删除任一 → 单方窗口边界不清触发越权风险。

  **不接受的简化路径**：
  - 把多方启动流程下沉 standards/（→ 失去 M-000 §4 派生合法性，且模型 ID 验证是元规则层约束）
  - 把物理隔离操作下沉 templates/（→ 失去元规则层「P5 + §3 独立性」执行强约束）
  - 把单方执行窗口下沉 skill/（→ 这是约束清单，不是 LLM 动态判断）
  - 章节合并 §4+§5（→ 启动 vs 隔离是两个序贯阶段）

derived_from: [M-000 §4, M-000 §11.1, MC-2]
---
# M-001 协作工作流规约

> M-001 定义「多方启动、独立工作、物理隔离、上下文加载、主笔轮换提议、单方执行窗口、私下授权同步、sync-status 实现、CLI 脱敏 hook」的可操作流程。承接 M-000 §4（隔离与三阶段流程）+ M-000 §11.1 派生职能 + MC-2（多家任务启动前主笔验证模型 ID）+ Antigravity 独家发现 1（私有 plan 派生链）。
> **前置依赖**：M-000 v2.0、M-002（§4.4 单方窗口 / §11 sync-status 接口）、M-005（§H 主笔轮换 / §I.1 结构性决定 / §I.2 私下授权）、M-006（§5.4 数据流转 / §6.4 CLI hook 接口）。

---

## §1 定位

M-001 是协作工作流层的元规则。M-000 §4 给出原则（隔离 + 三阶段），M-005 给出主笔轮换 + 越权防线，M-002 给出裁决触发条件 + sync-status 元规则层职责，M-006 给出数据流转层约束，**M-001 给出可执行的操作步骤**：

1. 多方启动前如何验证模型 ID（§4）
2. worktree / 分支 / context / .claude.md 如何隔离（§5）
3. Boot 必读 + Action Gate + Context Map 三段架构如何加载（§6）
4. 主笔轮换如何提议（§7）
5. 单方执行窗口的具体动作清单（§8）
6. 私下授权如何同步主分支（§9）
7. sync-status skill 如何实现（§10）
8. CLI 调用前的脱敏 hook 如何配置（§11）

M-001 不取代任何下游的具体 hook 脚本、worktree 命令、CLI wrapper——M-001 定义这些工具应做什么、按什么顺序、违反信号是什么。

适用范围：所有受 M-000 §3 默认多方异源约束的协作场景（元规则起草、ADR、cross-audit、sign-off、subagent 调度、主笔轮换）。

## §2 与 M-000 PRIMARY 接口

M-000 v2.0 §2 的 8 条 PRIMARY 内核中，与 M-001 直接挂钩如下：

| PRIMARY | M-001 相关章节 | 关联说明 |
|---|---|---|
| P1（相同完整任务） | §4 多方启动 | 任务定义书生成保证各方收到同一完整任务 |
| P3（默认多方异源） | §4 / §7 | 启动验证 + 主笔轮换防同源 |
| P4（同源警告） | §7 主笔轮换 | 连续同源主笔 ≥3 版触发轮换 |
| P5（物理隔离） | §5 物理隔离 | 4 步隔离对应 M-000 §3 独立性四层 |
| P6（sanity check 自反性） | §6 上下文加载 | Boot 序列重构（#006）+ 自反性 sanity 入口 |
| P7（净化提示词） | §4 任务定义书 + §11 CLI hook | 任务定义和 CLI 调用前脱敏 |
| P8（Overrule） | §9 私下授权同步 | 私下 Overrule 必须同步主分支 |

## §3 与 M-002/M-003/M-004/M-005/M-006 的分工边界

| 规则 | M-001 给出的 | 由对方给出 |
|---|---|---|
| M-002（分歧裁决） | sync-status skill 具体实现（§10）+ 单方执行窗口清单（§8）+ 主笔轮换具体流程（§7） | 裁决触发条件 §4 + Overrule 写法 §7 + sync-status 元规则层职责 §11.2 |
| M-003（skill 治理） | sync-status / docaudit-on-doc-edit / agent-cli-models-refresh 等 skill 的入库流程（§10 内嵌 §2.4 三条门槛） | skill 入库门槛、命名空间、生命周期状态机、Verdict 体系 |
| M-004（降级操作） | 多方启动时若某 vendor 不可用的降级路径（§4.3）+ CLI hook 失败时的降级（§11.4） | 不可逆动作具体清单、用户不可达等待判据、降级幅度 |
| M-005（质量判据） | 主笔轮换提议流程（§7）+ 越权防线的操作（§9 + §10） | 主笔轮换原则 §H + 越权识别 §I 三分 + 自反性 §F 复盘 prompt |
| M-006（数据治理） | CLI 调用前的脱敏 hook 实现（§11）+ 跨厂商共享的批次记录（§4.4 + §10） | 脱敏策略默认值 §6 + 跨厂商共享默认行为 §5 + 数据分类 §4 |

**多余交集**：M-001 不重复定义 M-005 §H 主笔轮换原则（直接引用），不重复 M-002 §4.4 单方窗口判据（直接引用），不重复 M-006 §6.1 脱敏规则（hook 调用 §6 默认值）。但 M-001 给出「**操作步骤 + 违反信号 + 工具配置**」的执行细节。

---

## §4 多方启动流程

### §4.1 任务定义书生成（承接 M-000 §4 准备阶段）

多方启动前主笔必须生成**净化版任务定义书**，路径：`docs/audits/signoff-task-definition-<元规则>.md` 或对应任务子目录。任务定义书最小必填字段：

1. **任务**：一句话目标（如「审计 M-006 v1 draft 是否可 ratify」）
2. **必读输入**：按读取顺序列出文件路径（≥3 个，含待审产物 + 宪法层 + backlog）
3. **禁止材料**：其他方 sign-off 报告 + 主笔内部推理 + 引导性语言
4. **评估维度**：判据 ID + 说明（如 M-005 §A D1-D7）
5. **输出格式**：markdown 结构 + 字段强约束（self-id / verdict / 逐章评估 / BLOCK 三要素 / 自反性）
6. **Verdict 判定规则**：PASS / CONDITIONAL / BLOCK 三选一边界
7. **主笔身份强约束**：自报 vendor + model（M-005 §C.4 身份误识别防御）

**违反信号**：任务定义书缺任一字段 → 异源方报告可能无法对齐，主笔需补全后重发。

### §4.2 模型 ID 验证（承接 MC-2 + M-005 §D.1）

启动多家任务前主笔**必须**验证当前各家模型 ID 与可用性：

1. **对照 SSOT**：`docs/tech/reference/agent-cli-models.md`（max_age_days: 30，需先确认未过期）
2. **若 SSOT 过期**（last_verified > 30 天）：先 WebSearch 验证当前各家 vendor 主力模型 ID + 同 PR 刷新 SSOT 文档
3. **若新 vendor 接入**：必须先在 SSOT 注册（添加新行）+ 跑最小 ping 测试确认调用方式
4. **若 vendor 通道故障**（如 #025/#026 实证的 DeepSeek wrapper）：按 §4.3 降级，并在 user-decision-log 留痕

**违反信号**：未对照 SSOT 直接 spawn 异源方 → 模型 ID 误用风险（[#013](user-decision-log.md#013) 实证）；主笔强行声称「某 model 已可用」未 grep SSOT → 按 M-005 §C 静默退化处理。

### §4.3 异源矩阵核对

主笔启动前必须确认**当前可用异源矩阵**：

| 来源 | 当前状态（2026-05-26 实测） | 触发判据 |
|---|---|---|
| AGY CLI（Gemini 3.5 Flash GA）| ✅ 可用 | `/opt/homebrew/bin/agy --print-timeout 30m -p` |
| Codex CLI（GPT-5）| ✅ 可用 | 通过 `codex:codex-rescue` subagent 或直接 codex exec |
| DeepSeek V4 Pro CLI | ⛔ 通道故障（#025/#026 实证）| 跳过，按 #017/#021/#025/#026 共识 2 家 + 用户裁决有效 |
| Claude 主线 | 主笔不下场（M-005 §H.2 + M-003 §7）| 仅做任务定义 + 修复 finding，不参与 sign-off 评估 |

**异源数量底线**：≥2 家不同 vendor PASS 视为共识有效（#017/#021/#025/#026 实证扩展）。若仅 1 家可用 → 自动触发用户裁决（M-002 §4.2）。

### §4.4 跨厂商共享的批次记录（M-006 §5.5 接口）

多方启动涉及任务定义书 + 待审产物分发到各 vendor，这构成跨厂商共享 L2/L3 数据。**M-002 §4.3 + §6.2 + M-006 §5.3 明确：跨厂商共享不属于双核默认通过，必须有用户显式授权。**每次分发必须按 M-006 §5.5 留痕 + 满足 M-006 §5.3 八字段用户授权：

- 时间戳 + 任务定义书路径 + 各 vendor 接收的具体文件路径列表
- 接收方：vendor 名 + 端点 + model ID（来自 §4.2 SSOT）
- **授权依据**：必须引用具体 user-decision-log 编号（如 [#025](user-decision-log.md#025) / [#026](user-decision-log.md#026) ratify 同 PR 默示授权 sign-off 工作流的跨厂商共享 L3 内部决策；或专门的 sign-off 工作流授权条目）。**禁止**写「M-002 §6 默认通过」——M-002 §6.2 已明示跨厂商共享是双核同意无效事项
- **本批 sign-off 工作流的授权来源**：[#025](user-decision-log.md#025) / [#026](user-decision-log.md#026) ratify 时帅哥已默示授权「sign-off 工作流跨厂商共享 L3 元规则起草过程文档（M-001~M-006 草案 + 任务定义书 + sign-off 报告）」用于异源 reviewer 评估；该默示授权范围限定为 L3 起草过程文档，不延伸到 L1 用户隐私 / L0 凭据 / 项目核心代码（L2 限制）

留痕位置：sign-off 任务定义书 + ratify commit message + sign-off 报告归档同 PR（参 M-006 §5.5）。M-001 ratify 后建议追加专门的 sign-off 工作流跨厂商共享授权条目到 user-decision-log（消除「默示授权」依赖）。

---

## §5 物理隔离操作规程（M-000 §3 独立性四层的运行实例 + 上下文层落地）

承接 M-006 §5.4「独立性四层数据流转层」+ M-000 P5。本节给出**操作步骤**，但**仅覆盖 M-000 §3 独立性四层中的 L-ii（运行实例不同）+ L-iii（上下文互不可见）两层**——其余两层的操作步骤承接到本元规则其他章节：

| 独立性层 | 落地章节 | 承接说明 |
|---|---|---|
| **L-i 模型权重或训练谱系不同** | §4.2 模型 ID 验证 + M-005 §D.2 异源训练谱系判断 | M-001 §4.2 强制启动前对照 SSOT + WebSearch 验证训练谱系（不依赖智能体自我宣称）|
| **L-ii 运行实例不同** | **§5.1 worktree + §5.2 分支** | 本节直接覆盖 |
| **L-iii 上下文互不可见** | **§5.3 context + §5.4 .claude.md / memory** | 本节直接覆盖 |
| **L-iv 任务输入未泄露其他方中间结论** | §4.1 任务定义书净化（P7 + 禁止材料清单）+ §11 CLI 调用前脱敏 hook | M-001 §4.1 任务定义书生成强制「禁止材料」字段排除其他方 sign-off 报告 / 主笔推理 / 引导性语言；§11 PreToolUse hook 拦截含 L1/L2 数据的外部 CLI 调用 |

本节以下 4 小节是 L-ii + L-iii 的操作步骤：

### §5.1 worktree 隔离（对应 L-ii 运行实例不同）

- **场景**：复杂多方任务（如元规则起草、cross-audit）
- **操作**：`git worktree add ../snapdrill-<task-name> <branch>` 创建独立 worktree
- **要求**：每个 vendor 的执行环境 cd 到独立 worktree（不复用主分支）
- **本会话简化**：M-002 / M-006 sign-off 因主笔不下场 + 各 vendor CLI 自身有 sandboxing，未启用 worktree 隔离（共享主分支）。后续高风险任务（如新 vendor 接入 / 元规则争议大）应启用 worktree

### §5.2 分支隔离（对应 L-ii 运行实例不同的扩展）

- **场景**：长任务 + 频繁 commit
- **操作**：每个 vendor 在独立分支 (`feature/<task>-<vendor>`)，最后折叠 merge
- **本会话简化**：M-002 / M-006 全部 commit 在 develop（元规则搭建期纪律 + 主笔不下场），sign-off 报告归档同 PR

### §5.3 context 隔离（对应 L-iii 上下文互不可见）

- **场景**：所有多方任务（强约束）
- **操作**：
  - 各 vendor CLI 使用独立 conversation（AGY 用 `--add-dir` + 新 prompt；Codex 通过 subagent 起新 session；DeepSeek wrapper 独立 spawn `claude -p`）
  - 不通过 shell 历史 / paste 等带入其他方上下文
  - 不在任务定义书提及其他方编号 / 分工锚点（P7 净化）

### §5.4 .claude.md / memory 隔离（对应 L-iii 持久化形态）

- **场景**：长会话 + 跨 vendor sign-off
- **操作**：
  - Claude 主线私有 memory 不写入其他 vendor 的具体产物 / 编号（仅记元规则类 feedback）
  - .claude.md / AGENTS.md 不嵌入 sign-off 中间结论
  - 跨 vendor sign-off 任务执行前显式断言「本任务 memory 上下文不含其他参与方中间产物」（M-006 §10.3）

### §5.5 隔离失效检测（M-005 §B.2 5 条信号联动）

任何一条触发 → 视为隔离失败，按 M-005 §B 处理：
1. 提示词污染（任务定义含「参考其他方」）
2. git 历史横向引用（commit message 提其他 vendor 编号）
3. .claude.md / memory 横向扩散（M-006 §10.3 联动）
4. agent 内部推理链泄漏（#010 Codex 实证）
5. 产物相似性（结构 / 例子 / 比喻高度相似）

---

## §6 上下文加载顺序（承接 [#006](user-decision-log.md#006) Boot 重构）

直接引用 #006 裁决 + AGENTS.md 三段架构：

### §6.1 Boot 必读（≤500 nwc）

- `docs/meta/M-000-meta-vision.md` — 宪法层
- `docs/meta/user-decision-log.md` — 已生效裁决与 Overrule

不在 Boot 加载：STATUS.md / docs/workflow.md / docs/memory/feedback.md / standards/

### §6.2 Action Gate（按需触发）

触发改代码 / 改文档 / 提 PR / merge / push / 跑 lint/test 前，读 `docs/protocol.md`，按阶段进入对应 skill 或文档。

### §6.3 Context Map（索引位）

按场景查表读取（AGENTS.md 已有完整表）。

### §6.4 启动新会话的自审 prompt

新会话启动后主笔应自审：
1. 是否已读 M-000 + user-decision-log？（Boot 必读）
2. 当前任务是否触发 Action Gate？（改代码 / 文档 / merge 等）
3. 是否需要按 §4 启动多方流程？（涉及元规则修订 / ADR / cross-audit）

---

## §7 主笔轮换提议流程（承接 M-005 §H）

### §7.1 触发条件

- 同一 vendor 连续担任主笔 ≥ 3 版（按 M-005 §H.1）
- 或任意一次 sign-off 中出现「主笔自身盲点」实证（如 #025 数字凑数巧合）→ 主笔自动建议下一版轮换

### §7.2 提议格式

提议作为 user-decision-log 新条目，字段（M-002 §10.1 八字段 + 轮换 payload）：

```yaml
编号: #NNN
时间: YYYY-MM-DD
冲突描述: <当前主笔 vendor> 已连续主笔 <版本列表>，触发 M-005 §H 轮换阈值；或 sign-off 中暴露 <具体盲点>
裁决: 下一版主笔提议轮换至 <候选 vendor> （或 user 裁决）
理由: 防同源偏向累积 / sign-off 盲点修复
是否触发元规则修订: ❌（轮换不修元规则正文）
Overrule 关系: 无
元层级注记: 第 N 次主笔轮换 / 实证锚定 <sign-off 报告路径>
# 轮换 payload：
候选vendor: [Claude / Codex / AGY / DeepSeek / ...]
评估依据: <候选方此前 sign-off 表现 / 训练谱系异源 / 通道可用性>
物理隔离要求: <见 §5>
```

### §7.3 轮换执行（M-005 §H.2 物理隔离）

- 主笔候选确定后，旧主笔不参与新版 sign-off 初审（仅事后 reviewer 角色）
- 新主笔在独立 worktree 起草（§5.1）
- 旧主笔可作为辅助 reviewer，但 BLOCK 权限受限（M-005 §H.3）

---

## §8 单方执行窗口清单（承接 M-002 §4.4 + M-005 §I.1）

### §8.1 可逆原则

「这件事如果做错，是否需要用户介入恢复？」若答案是「否」（可一键回滚 / 无外部副作用 / 不破坏裁决链）→ 单方执行；否则上交用户。

### §8.2 具体可单方执行清单

| 类别 | 具体动作 | 判据 |
|---|---|---|
| 代码质量 | swiftlint --fix / import 排序 / 空白整理 | 可一键回滚 + 无逻辑变化 |
| 文件操作 | 非结构性可逆本地文件改名（不含归档 / 移动 / 删除）| §4.4 + §I.1 排除清单 |
| 测试与构建 | swiftlint --strict / xcodebuild build-for-testing | 只读式验证 |
| 文档微调 | typo 修复 / 格式化 / Markdown 渲染优化（不改语义）| 不破坏裁决链 |
| frontmatter 修改 | last_verified 日期刷新 / word_count_actual 实测填入 | 元数据维护 |
| commit | 本地 commit（不 push）| 可 reset --soft 撤销 |

### §8.3 排除清单（不属于单方窗口）

引 M-005 §I.1 + M-006 §8.1：

- 归档路径决定 / 目录重命名 / 跨目录文件移动 / 删除文件
- 批量 frontmatter 修改（如全部文档 layer 字段迁移）
- 修改验证脚本枚举（如 `validate_frontmatter.py` STATUS_ENUM）
- git push / fastlane match / TestFlight 发布 / 数据库迁移
- 跨厂商共享 L1/L2/L3 数据（M-006 §5.3）
- 任何触发 git pre-commit hook 失败的本地动作（hook 拒绝 = 系统告诉你需要更高授权）

### §8.4 违反信号

智能体在 §8.3 排除清单中任一项执行单方动作 → 按 M-005 §I.3 「真违纪」处理 + user-decision-log 留痕。

---

## §9 私下授权同步流程（承接 M-005 §I.2 + Antigravity 独家发现 1）

### §9.1 私下授权的来源

主笔（特别独立 worktree 中的 Codex / AGY / DeepSeek 主笔）可能在与用户私聊中收到 Overrule 或临时授权（如 [#010](user-decision-log.md#010) Codex 收到字数原则升级 Overrule）。这些授权**必须**同步主分支。

### §9.2 私下授权同步格式

私下授权同步到 user-decision-log 必须包含：

- **授权内容**：用户原话引用 + 授权范围（全局 / 仅当前任务）
- **授权时间**：私下对话时间戳
- **授权途径**：哪个对话（Codex desktop / AGY GUI / DeepSeek chat / etc.）
- **主笔身份**：vendor + 当时角色（主笔 / reviewer / sub-agent）
- **同步延迟**：私下授权时间 → 主分支同步时间的间隔（原则上越快越好，硬时限由 M-001 后续精化提议）

### §9.3 私有 plan 派生链（Antigravity 独家发现 1 落地）

按 Antigravity sign-off 独家发现 1 + M-006 §10：

- 私下授权产生的 plan / 临时规约 / 工作链文档**不应**仅留在私有 memory 或 worktree
- 若该 plan 影响主分支治理（如「下一版 M-XXX 主笔轮换给 vendor Y」），必须按 §9.2 同步格式入 user-decision-log
- **派生链断裂检测**：每周 / 每月扫描私有 memory 中含「plan」「decision」「override」关键字的条目，对照 user-decision-log 是否有同步条目；缺失 → 提示主笔补同步

### §9.4 检测违反

其他参与方 sanity check 时若发现：
- 主笔产物含「按 user 之前私下确认」类语句，但 user-decision-log 无对应同步条目 → 触发 M-005 §C 静默退化扫描 + 私下授权同步要求

---

## §10 sync-status skill 具体实现（承接 M-002 §11 接口）

承接 M-002 §11 元规则层职责（session start 读 / session end 写 / 冲突优先级 / 缺口记录）+ MC-11。本节给出 skill 实现规约。

### §10.1 skill 入库门槛（按 M-003 §2.4 三条）

- ✅ 重复触发 ≥3 次：每个 session start + session end 均触发，远超阈值
- ✅ ≥2 个独立场景验证：元规则起草 session + 常规开发 session 两类
- ✅ 无法机械化：判断哪些 user-decision-log 条目是「当前焦点」需要 LLM 推理，不能纯脚本

入库门槛满足，sync-status 是 skill。

### §10.2 命名 + 路径

- 名称：`sync-status`
- 路径：`.agents/skills/sync-status/SKILL.md`（portable SSOT，按 M-003 §3 公私分治）
- `.claude/skills/sync-status` symlink 到 SSOT
- frontmatter `derived_from: [M-002 §11, MC-11]`

### §10.3 skill SKILL.md 必填字段

```yaml
---
name: sync-status
description: Session start 读取 user-decision-log + backlog + git 状态生成当前焦点视图；session end 写回 STATUS.md 极简手动条目。
derived_from: [M-002 §11, MC-11]
---
```

### §10.4 session start 流程

1. 读 user-decision-log 最近 5 条（按编号倒序）
2. 读 M-001-to-M-006-followup-backlog.md（识别 active MC）
3. 跑 `git log --oneline -10` + `gh issue list --state open` + `gh pr list --state open`
4. 跑 `git rev-list --count HEAD ^origin/develop`（本地领先 commit 数）
5. 生成「当前焦点」视图（不写文件，仅输出到对话）

### §10.5 session end 流程

1. 收集本 session 完成的任务（task list completed）+ 新 commit（git log -<count>）+ 触发的 user-decision-log 新条目
2. 写回 STATUS.md「当前焦点」段（极简 3-5 行）
3. 写本 session 的 ratify / 修订到「权威状态源」列表

### §10.6 冲突优先级（M-002 §11.2 引用）

直接引用，不重复定义：user-decision-log > backlog > git/GitHub live state > STATUS stub。

### §10.7 缺口记录

无法自动判定的状态 → 不擅自把推论写成事实，记入 STATUS.md `gap_due` 字段 + 提示用户复核。

---

## §11 CLI 调用前的脱敏 hook 实现（承接 M-006 §6.4 接口）

承接 M-006 §6.4 + M-006 §6.2 自动脱敏检测。本节给出 PreToolUse hook 实现规约。

### §11.1 hook 路径与触发器（**强制 PreToolUse**）

- 路径：`.claude/hooks/cli-call-desensitize.sh`
- **主路径触发器：`PreToolUse` matcher `Bash`**——必须在命令执行**前**拦截，这是 M-006 §6.4 「调用前的脱敏 hook」边界的硬要求
- 兜底 / 复核：`PostToolUse` matcher `Bash` 可同时配置一份事后日志 hook（仅记录，不阻断；用于审计 + 误报率分析）
- **不允许把主路径设为 PostToolUse**——事后 hook 无法阻断已发出的 CLI 调用，会让 L0 凭据 / L1 用户隐私在 `agy` / `codex` / `deepseek` / `gemini` 等外部 CLI 接收后才告警，违反 M-006 §5.2 L0 硬约束与 §6.4 事前边界

### §11.2 检测规则（机械可执行）

**输入契约**（Claude Code PreToolUse hook 强约束）：

- PreToolUse hook 接收 JSON via **stdin**，结构：`{"tool_name": "Bash", "tool_input": {"command": "<bash 命令字符串>", ...}, ...}`
- 必须用 `jq` 从 stdin 提取 `tool_input.command` 字段为字符串变量 `$COMMAND_TEXT`
- 检测对象是 `$COMMAND_TEXT`（命令字符串）+ 可选的 stdin 内容（若主命令含 heredoc / pipe）
- 检测方式：`printf '%s\n' "$COMMAND_TEXT" | grep -E '<pattern>'`（管道传字符串，不把变量当文件路径）

按 M-006 §6.2 grep 特征：

```bash
#!/usr/bin/env bash
# .claude/hooks/cli-call-desensitize.sh
# PreToolUse Bash matcher hook

set -euo pipefail

# 从 stdin JSON 提取命令字符串
INPUT=$(cat)
COMMAND_TEXT=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 非 Bash 调用 / 解析失败 → 不阻断（让其他 hook / 框架自决）
[ -z "$COMMAND_TEXT" ] && exit 0

# L0 凭据特征（命中即 exit 2 阻断，PreToolUse exit 2 = block tool call）
if printf '%s\n' "$COMMAND_TEXT" | grep -qE '(ANTHROPIC_API_KEY|DEEPSEEK_API_KEY|GH_TOKEN|GITHUB_TOKEN|AWS_SECRET|FIREBASE_ADMIN|GEMINI_API_KEY)'; then
  echo "L0 凭据特征检测到，命令已拦截（M-006 §5.2 硬约束）" >&2
  exit 2
fi

# 文件路径含敏感（同 L0 阻断）
if printf '%s\n' "$COMMAND_TEXT" | grep -qE '\.env(rc)?|/\.ssh/|/id_rsa|\.pem|\.key($|[^=])'; then
  echo "敏感文件路径检测到，命令已拦截（M-006 §5.2 / §8.1 硬约束）" >&2
  exit 2
fi

# L1 用户隐私（warning 但不阻塞，exit 0 + stderr 提示）
if printf '%s\n' "$COMMAND_TEXT" | grep -qE '/Users/yiming/|chramboliao@'; then
  echo "[warning] L1 用户隐私特征检测到（M-006 §6.2），建议脱敏后再调用外部 CLI" >&2
fi

exit 0
```

**输入契约违反信号**：hook 内若直接写 `grep '...' "$CMD"`（变量不接管道而作 grep 文件参数）→ grep 把变量当文件路径，文件不存在则 fail-open（按 §11.4 不阻塞），破坏 M-006 §6.4 「调用前阻断」边界。

### §11.3 触发动作

- 检测到 L0 特征 → 阻塞命令（exit 1）+ 输出「L0 凭据特征检测到，命令已拦截」
- 检测到 L1 特征 → warning 但不阻塞（exit 0 + stderr 提示）
- 检测到外部 CLI 调用（agy / deepseek / codex / gemini）含 L2 项目代码 → warning + 提示主笔确认

### §11.4 hook 失败的降级（M-004 接口）

- hook 脚本本身报错 → 不阻塞主命令（exit 0），但记录到 `.claude/hooks/desensitize-errors.log`
- M-004 后续定义 hook 故障的等待 / 修复路径

### §11.5 实施时序

本节是规约设计，**未实施**于 `.claude/hooks/`。按 M-005 §G.4 升级路径：
- 第一阶段（本 M-001 ratify）：M-001 §11 设计入档
- 第二阶段：实现 `.claude/hooks/cli-call-desensitize.sh` + 加入 settings.json hooks 链
- 第三阶段：30 天观测 + ≥3 次触发 + 误报率 <20% 后升 core

---

## §12 修订与复审

### §12.1 复审周期

`freshness.max_age_days: 180`。提前复审触发条件：

1. 新 vendor 接入（§4.2 异源矩阵扩展）
2. 物理隔离失败事故 ≥3 次 / 季度
3. M-005 §H 主笔轮换原则修订 → M-001 §7 同步
4. M-006 §6 脱敏规则修订 → M-001 §11 hook 同步
5. 用户主动要求复审

### §12.2 修订要求

修订 M-001 必须满足 M-000 §12 自我修订 4 点 + 额外要求：

1. 在 §4 增加新 vendor 时，必须先在 `agent-cli-models.md` SSOT 注册
2. 在 §8 调整单方执行窗口清单时，必须对照 M-005 §I.1 + M-006 §8.1 排除清单
3. 在 §10 / §11 修订 skill / hook 规约时，必须按 M-003 §5 升降级流程或 M-005 §G.4 升级路径

### §12.3 自反性约束

M-001 自身适用 M-005 §J 字数原则 + §F 自反性 sanity check + M-006 §10 私有 memory 治理。

---

## §13 自反性标注

**起草工具**：Claude Opus 4.7 主笔（直接 API，本会话主分支），未使用 .claude/skills/ 下任何 governance skill（M-003 §7 主笔体系隔离）。

**WebSearch 验证**：本文未引用需 WebSearch 验证的**结论性**外部事实（多方启动 / 物理隔离 / 主笔轮换均基于内部 #006/#010/#013/#017/#020/#021/#025/#026 实证 + M-000~M-006 已 ratify 文本派生）。

**列项原文真 grep 验证**（[[feedback-numeric-alignment-blindspot]] 应用，区分「原文镜像」vs「派生扩展」，v1 → P4.Fix 诚实修正）：

| M-001 列项 | 来源性质 | 宪法层原文对照 |
|---|---|---|
| §2 PRIMARY 接口表 P1/P3/P4/P5/P6/P7/P8（共 7 项）| **原文镜像** | M-000 §2 P1-P8 原文共 **8 项**，本表覆盖 **7 项**（P1/P3/P4/P5/P6/P7/P8）；**P2 用户裁决权由 M-002 全局承载，M-001 不重复定义**。v1 自反性表错写「P1/P3/P4/P5/P6/P7」+「7 项已选 6 项」（漏 P8 + 算术错），P4.Fix B1+C2 已修正本表。|
| §5 物理隔离 4 节（worktree / 分支 / context / .claude.md / memory）| **派生扩展（仅覆盖 L-ii + L-iii 两层）** | M-000 §3 「独立性至少包含四层」原文 4 项（L-i 模型权重 / L-ii 运行实例 / L-iii 上下文 / L-iv 任务输入未泄露）。本节 4 小节**仅直接覆盖 L-ii + L-iii**；L-i 由 §4.2 模型 ID 验证 + M-005 §D.2 承载，L-iv 由 §4.1 任务定义书净化 + §11 PreToolUse CLI hook 承载。§5 章首已加四层映射表显式说明。v1 自反性表错称「四层 grep 对照」（实际仅 2 层），P4.Fix B2 已修正本表 + §5 章首映射表。|
| §6 Boot 三段架构（必读 / Action Gate / Context Map）| **跨章承载（非单章镜像）** | user-decision-log [#006](user-decision-log.md#006) 裁决 A-F 原文 6 项分布承载：A Boot 必读 → §6.1；B STATUS minimal stub → §10.5 sync-status session end；C workflow→protocol.md 迁移 → §6.2 Action Gate（具体路径由 protocol.md 自身承载）；D feedback 移出 Boot → §6.3 Context Map 索引位；E AGENTS 三段架构 → §6 整章；F protocol.md ≤200 nwc → 由 protocol.md 自身承载，M-001 后续精化。v1 自反性表错称「§6 原文镜像」+ 错称「A-F 中 A-E 直接相关」（漏 B 的 §10 + F 的 protocol.md 边界），P4.Fix C3 已修正为跨章承载说明。|
| §8 单方执行窗口清单 | **派生扩展** | M-002 §4.4 给原则（可逆 + 局部 + 低副作用）+ M-005 §I.1 给排除项 + M-006 §8.1 给硬边界，M-001 §8.2 是把三者交集落地为具体动作清单（非原文镜像）|
| §11 CLI 脱敏 hook 实现（PreToolUse 强制） | **派生扩展** | M-006 §6.2 给 grep 特征 + §6.4 给「调用前」hook 时机，M-001 §11 是把两者落地为 bash + PreToolUse hook 实现（非原文镜像）。v1 §11.1 错把主路径写成 PostToolUse（事后无法阻断），P4.Fix B3 已改为 PreToolUse 强制 + PostToolUse 仅做兜底日志。|

**下沉边界注记（C1 修复，按 M-005 §A.3「标准写法」）**：

- §4 多方启动流程**不下沉**到 standards/——模型 ID 验证 + 任务定义书生成的强制性是元规则层约束，standards/ 可被绕过
- §5 物理隔离操作**不下沉**到 templates/——L-ii / L-iii 操作步骤涉及 git worktree / context 切换的强制性约束，模板可被绕过
- §6 Boot 三段架构**已是元规则层入口约束**——AGENTS.md 已落地，但「读哪些 / 不读哪些」的边界判断属 M-001
- §7 主笔轮换**不下沉**到 templates/——轮换提议的 8 字段 schema 是 M-002 §10 派生 + M-005 §H 元规则约束
- §8 单方执行窗口**不下沉**到 standards/——清单 / 排除清单的边界判断需 LLM 推理 + 与 §4.1/§I.1/§8.1 三处宪法层联动
- §9 私下授权同步**不下沉**到 skill/——私下授权检测是元规则层约束，不是 LLM 动态判断的任务模式
- §10 sync-status skill 实现**是 skill 入库提案**（按 §10.1 三条门槛满足）——本节是 skill 设计规约，由 M-001 元规则层承载；具体 SKILL.md 实现下沉 `.agents/skills/sync-status/`
- §11 CLI hook 实现**是 hook 入库提案**——PreToolUse 强制性属 M-006 §6.4 派生 + M-001 §11 实现规约；具体 bash 脚本下沉 `.claude/hooks/cli-call-desensitize.sh`

**异源 sign-off 待补**：本 draft 待 AGY CLI（Gemini 3.5 Flash GA）+ Codex CLI（GPT-5）异源 sign-off。DeepSeek 通道仍故障（[#025](user-decision-log.md#025)/[#026](user-decision-log.md#026)），跳过；按 [#017](user-decision-log.md#017)/[#021](user-decision-log.md#021)/[#025](user-decision-log.md#025)/[#026](user-decision-log.md#026) 实证 2 家异源 + 用户裁决追认即共识有效。

*本草案由 Claude Opus 4.7 (1M context) 基于 M-000 §4/§11.1 派生职能 + MC-2 backlog + Antigravity 独家发现 1 + M-002 §11/§4.4 接口 + M-005 §H/§I 引用 + M-006 §5.4/§6 引用 + [#006](user-decision-log.md#006)/[#010](user-decision-log.md#010)/[#013](user-decision-log.md#013)/[#025](user-decision-log.md#025)/[#026](user-decision-log.md#026) 实证起草。*
