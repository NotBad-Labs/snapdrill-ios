---
last_verified: 2026-04-16
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [feedback_event]
---
# 项目反馈与纪律规则

> 从项目执行中积累的教训。所有智能体必须遵守。
> 人类拥有最高裁决权，这些规则反映人类的明确指令。

## F-001: Git 工作流纪律
<!-- added: 2026-03-31 | owner: human | type: permanent -->
<!-- trigger: Claude 在 develop 直接写了 5 个改进项 -->

「自主执行」偏好的范围是：不需要 yes/no 确认每个代码改动，直接做并汇报。

**不包括**跳过 Git 工作流闭环。任何代码改动都必须：Issue → feature 分支 → PR（Closes #N） → Review → 合并。

**Why:** 2026-03-31 对话中直接在 develop 分支写了 5 个改进项的代码，违反了 workflow.md 的铁律「禁止直推 develop/main」。

**How to apply:** 即使用户要求「一口气全部做完」，也要先建 Issue，切 feature 分支，在分支上开发，完成后开 PR 等用户 review。唯一例外是 STATUS.md 允许直推 develop。

---

## F-002: 产品文档优先于一切
<!-- added: 2026-04-01 | owner: human | type: permanent -->
<!-- trigger: 工具服务于目的的核心原则确立 -->

产品文档是项目的源头，优先级高于根级文档、技术文档、规则文件。

**Why:** 产品文档定义「做什么、为谁做」，错了全盘皆错。工具服务于目的，不是反过来。

**How to apply:** 文档审计、任务排序、优先级判断时，始终从产品价值出发。产品 > 技术 > 流程/规则 > Agent 配置。

---

## F-003: 依赖图区分主链 vs 交叉引用
<!-- added: 2026-04-03 | owner: human | type: timeboxed | review_after: 2026-07-03 -->
<!-- trigger: 混淆主链和交叉引用导致依赖层级失真 -->
<!-- sunset: 文档体系稳定后（无新增根文档 6 个月）可降级为参考 -->

1. **主链 vs 交叉引用**：依赖图中不能把所有引用当同等权重。主链依赖（vision→design→requirements）是内容生成方向，交叉引用（cases 引用 workflow 的 S0-S3）是辅助参考。
2. **文档→代码锚点**：文档审计不能只验证「文档间自洽」，必须验证「文档声明是否有代码兑现」。

**Why:** 混淆主链和交叉引用会导致依赖层级失真；纯文档间审计容易产生"文档自洽但脱离代码"的幻觉。

**How to apply:** 画依赖图时先识别内容生成的单向主链，再标注横向交叉引用。技术文档审计时对每个事实性声明 grep 代码验证。

---

## F-004: 内测阶段不做 Schema 迁移
<!-- added: 2026-04-01 | owner: human | type: timeboxed | review_after: 2026-07-01 -->
<!-- trigger: 设计了复杂的向后兼容方案，属于战术勤奋 -->
<!-- sunset: App Store 正式上架后废止，改为标准 Schema 迁移流程 -->

内测阶段（TestFlight Internal，0 外部用户）不需要 Schema 向后兼容迁移。

**Why:** 没有任何用户数据需要保护。设计复杂的向后兼容方案属于「战术勤奋掩盖战略懒惰」。

**How to apply:** 数据结构变更直接覆盖（新结构 replace 旧结构）。等正式发布后有真实用户数据时再考虑迁移。判断标准：App Store 上架前 = 不需要迁移。

---

## F-005: 完成前必须对抗性审查
<!-- added: 2026-04-02 | owner: human | type: permanent -->
<!-- trigger: Claude 首次提交漏了 5+1 处问题，全靠 Codex 抓出 -->

改完代码或文档后，不要直接跟用户说"搞定了"。必须先让 Codex 做对抗性审查，审查通过后才能声明完成。

**Why:** "自审自批"违反 workflow.md 的纪律。Claude 首次提交时漏了 5+1 处问题，自己没发现，全靠 Codex 抓出来。

**How to apply:** 每次完成修改后，先派 Codex 审查 diff，Codex 说"可以合并"后才汇报完成。

---

## F-006: 审计必须深度读源码
<!-- added: 2026-04-04 | owner: human | type: permanent -->
<!-- trigger: Codex 用 450+ 条深度命令发现 5 个严重问题，Claude 零发现 -->

审计和审查时必须做到深度代码验证：不只验证"类型名/方法名存在"（浅层），还要读源码确认"行为与文档描述一致"（深层）。

**Why:** Codex 通过 450+ 条深度命令发现了 5 个严重问题，Claude 一个都没发现。把自己定位为"协调者"而偷懒只做浅层验证，浪费了三方对抗性审查中的一个独立视角。

**How to apply:** 每个事实性声明不仅 grep 存在性，还要 Read 源码 10-20 行上下文确认行为。验证深度标准：能回答"代码具体怎么做的"而不只是"代码里有没有这个名字"。

---

## F-007: PR 合并后必须检查 CI
<!-- added: 2026-04-06 | owner: human | type: permanent -->
<!-- trigger: CI 连续 4 天全红（15+ 次失败）未被发现 -->

PR 合并后必须立即运行 `gh run list --limit 3` 检查 CI 状态。

**Why:** CI 从 2026-04-06 起连续 4 天全红（15+ 次失败），未被发现。本地通过不等于 CI 通过。

**How to apply:** 每次 `gh pr merge` 后等 30 秒再检查。如果最近 3 个 run 都是 failure，立即排查。

---

## F-008: 三方交叉审计必须相同完整任务
<!-- added: 2026-04-06 | owner: human | type: permanent -->
<!-- trigger: 用户多次提醒（至少 3 次），错误模式是分配不同子任务 -->

三方交叉审计的核心是"冗余"：各方独立完成完全相同的完整任务，然后交叉比对发现盲区。

**Why:** 用户多次提醒（至少 3 次）。错误模式是把其他 Agent 当成"补充角色"分配不同子任务。

**How to apply:** 委派时 prompt 的核心任务描述必须与自己做的完全一致，可以调整格式但任务范围不能缩减。

---

## F-009: Xcode Review 必须先读模板
<!-- added: 2026-04-07 | owner: human | type: timeboxed | review_after: 2026-07-07 -->
<!-- trigger: 连续两次凭记忆写错提示词 -->
<!-- sunset: Claude 稳定遵循 3 个月无违反后可降级为参考 -->

写 Xcode Review 提示词前必须先读取 skill 模板文件，严格按模板结构输出。

**Why:** 连续两次写错提示词 — 模板文件一直存在但未被读取，导致每次凭记忆拼凑，每次都有不同的错误。

**How to apply:** PR 创建后第一步读模板，不凭记忆写。提示词必须包含：开头一句话 + 变更概要 + 审查重点 + 固定收尾（项目约束 + 输出格式 + 水印要求）。

---

## F-010: 审计按依赖关系拆分阶段
<!-- added: 2026-04-08 | owner: human | type: timeboxed | review_after: 2026-07-08 -->
<!-- trigger: 全量审计丢失上下文焦点 -->
<!-- sunset: 文档体系稳定后（审计频率降低）可降级为参考 -->

大型审计按依赖关系拆分阶段，步步为营，不全量一把梭。

**Why:** 帅哥原话——"就好像写代码遵守高内聚低耦合一样，文档之间也存在类似的联系"。全量审计会丢失上下文焦点。

**How to apply:** 分析文档依赖图 → 按拓扑序拆分阶段 → 先审根文档再审下游 → 每阶段修复后再进入下一阶段。

---

## F-011: 审计期间三方只读
<!-- added: 2026-04-08 | owner: human | type: permanent -->
<!-- trigger: Claude 审计期间提前修改 api-reference.md 导致 Codex 暂停 -->

审计流程中三方必须同时只读审计 → 汇总比对 → 统一修复。审计期间不得提前修改被审文件。

**Why:** api-reference.md 审计中 Claude 提前修改文件（731→779 行），导致 Codex 检测到文件变更后暂停。

**How to apply:** 三方并行启动后审计结果只记录在回复中不触碰文件，等全部完成后汇总比对再统一修复。另外：抽查 ≠ 审计。

---

## F-012: 不偷懒，全量做
<!-- added: 2026-04-08 | owner: human | type: permanent -->
<!-- trigger: Claude 抽查 10 个签名说"全部匹配"，Codex 全量验证发现 13 处不匹配 -->

审计、验证、代码检查等任务必须全量执行，禁止抽查后声称"基本准确"。

**Why:** api-reference 审计中 Claude 抽查 10 个签名说"全部匹配"，但 Codex 全量验证 358 条后发现 2 个幽灵 API + 11 个签名不匹配。帅哥原话："codex 工作比你认真多了，你总会偷懒"。

**How to apply:** 代码验证逐文件逐方法 grep 不跳过；文档审计逐段落检查。规模太大需分批时明确告知覆盖范围。学习 Codex 的做法：遇到大量数据时写脚本自动化验证。

---

## F-013: PR scope 膨胀时必须拆分
<!-- added: 2026-04-15 | owner: human | type: timeboxed | review_after: 2026-07-15 -->
<!-- trigger: PR #597 从 CI 全量测试膨胀到 8 次 CI 尝试 -->
<!-- sunset: 团队形成稳定的 PR scope 习惯后可降级为参考 -->

当 PR 实际工作偏离原始目标（如从「配置修改」滚雪球成「修复 4 个编译错误 + 7 次 CI 重试」）时，必须停下来拆分为独立 PR。

**Why:** PR #597 从「CI 全量测试」膨胀到修复编译、修复环境问题、调试死锁，最终 8 次 CI 尝试。稳定通过的部分（Core 测试集成）被死锁问题（Data 测试）拖延合并。Codex 和 Gemini 一致建议拆分。

**How to apply:** 当 PR 发现的附带问题超过 2 个、或 CI 失败超过 3 次且原因不同时，拆分为独立 PR。稳定通过的部分先合并，有问题的部分保持 open 或另开 PR。

---

## F-014: 跳过测试的合并门禁
<!-- added: 2026-04-15 | owner: human | type: timeboxed | review_after: 2026-07-15 -->
<!-- trigger: PR #597 跳过 Data 测试，tracking issue 和注释事后补的 -->
<!-- sunset: 所有 skipped 测试恢复后可降级为参考 -->

标记测试为 `skipped` 是降级决策，合并前必须完成检查清单：(a) 创建 tracking issue，(b) 在代码中添加 `// TODO: #issue` 注释，(c) 在 PR description 中声明跳过原因，(d) PR 标题反映实际交付而非初始意图。

**Why:** PR #597 跳过 Data 测试后合并，但 tracking issue 和代码注释都是事后补的。Codex 指出 `skipped="YES"` 的测试容易被遗忘，Gemini 建议增加过期提醒机制。

**How to apply:** 任何将测试标记为 skipped/disabled 的 PR，合并前检查四项清单全部完成。

---

## F-015: CI 失败是致命信号
<!-- added: 2026-04-15 | owner: human | type: permanent -->
<!-- trigger: PR #597 CI 失败后 Claude 不等结果就开始 PR #598 -->

CI 失败必须立即阻塞后续工作。不能在未确认 CI 通过的情况下推进新 PR 或新任务。

**Why:** PR #597 第一次 CI 失败后，Claude 没有监控结果就开始了 PR #598 的开发。本地通过 ≠ CI 通过——CI 环境差异（UserDefaults 残留、资源限制、SwiftData XPC）暴露了本地无法覆盖的问题。

**How to apply:** 每个 PR push 后必须 `gh pr checks --watch` 等待结果。CI 失败时立即修复，不开新分支。与 F-007 互补：F-007 是合并后检查，F-015 是合并前等待。

---

## F-016: 质疑方批准，禁止自审自批
<!-- added: 2026-04-15 | owner: human | type: permanent -->
<!-- trigger: Claude 修复 Gemini Critical 发现后直接说"准备合并"，跳过复核 -->

修复审查发现的问题后，必须提交回原质疑方（Codex/Gemini/Xcode）复核。只有提出问题的 reviewer 确认修复有效，才能声称"问题已解决"。Claude 自己不允许批准合并。

**Why:** 这是不可改变的原则。Claude 修复 Gemini Critical 发现（内存风险）后直接说"准备合并"，跳过了 Gemini 复核。自审自批违反对抗性审查的根本目的——独立视角验证。

**How to apply:** 修复后必须重新提交给原 reviewer：Gemini 提的问题回 Gemini 验收，Codex 提的问题回 Codex 验收，Xcode 提的问题回 Xcode 验收。只有 reviewer 说"通过"才能声明修复完成。

---

## F-017: UI/SDK 改动必须查阅 Apple 最新文档
<!-- added: 2026-04-16 | owner: human | type: permanent -->
<!-- trigger: CaptureView 使用旧的 .regularMaterial 而非 iOS 26 Liquid Glass，Xcode Review 发现 -->

新增或修改 UI 组件、引入新 SDK API 时，必须先查阅 Apple 最新文档确认是否有更合适的原生方案。

**Why:** Claude 的训练数据不覆盖 iOS 26 新 API。CaptureMethodCard 用旧方案手动模拟玻璃效果，Xcode 指出应使用 .glassEffect()。engineering.md 的"决策前研究铁律"已要求此步骤，但未被执行。

**How to apply:** 每次涉及以下场景时，在编码前通过 WebSearch 或 WebFetch 查阅 developer.apple.com：
- 新增 SwiftUI View 组件
- 修改视觉样式（材质、动画、布局）
- 引入新框架 API（Vision、AVFoundation、Charts 等）
- 不确定 API 是否为最新版本

检查清单：Apple 文档 → WWDC session → 项目 apple-native.md / api-pitfalls.md。

---

## F-018: 编码前契约（Sprint Contract）
<!-- added: 2026-04-18 | owner: human | type: permanent -->
<!-- trigger: 长任务研究（docs/research/harness-engineering-study-20260418.md）发现开工时 Claude 自己也不清楚要碰什么，是 PR scope 偏离与 over-generation 的主要源头 -->

feature / chore 类 Issue 且 Appetite >= Small 时，Claude 在动第一行代码前必须在 Issue 回复一条 Sprint Contract comment（字段见 `.github/ISSUE_TEMPLATE/feature_request.md` Sprint Contract 段）。编码过程中 contract 变更须先改 comment 再改代码。

**Why:** 历史上 PR scope 偏离（F-013）、over-generation（F-005）、test evasion（F-014）多源自开工时没有显式锚点。Issue 的 Given-When-Then 是"结果态"，Sprint Contract 是"手段态"——要动/不动哪些文件、哪些接口变、哪些测试补、哪些 DoD 条目硬要求。把手段态显式写下来，Reviewer 与 Evaluator（Codex / Gemini / Xcode Review）才能做 scope fidelity 比对，不必靠 diff 反推意图。

**How to apply:**
- Issue 进入 Building 状态时第一个 action 是贴 Sprint Contract comment
- bug_report 类不强制（scope 天然小）
- Small Appetite 可简化填 Touches / No-Touch / DoD 最小集三条
- 若 contract 未贴直接 push，任一 reviewer 可要求补 contract 再继续
- 编码中发现 contract 需要改动：先改 Issue comment 解释变更理由，再改代码。禁止"代码和 contract 漂移"（比照 F-013 scope 膨胀处理）

---

## F-019: 反模式启发式回流（人工确认升级）
<!-- added: 2026-04-18 | owner: human | type: permanent -->
<!-- trigger: Harness Engineering 研究（docs/research/harness-engineering-study-20260418.md）建议 Hashimoto 式"错误即永久修复"要闭环，但不能让启发式自动改纪律 -->

`post-merge-checkpoint.sh` 通过 `Scripts/anti-pattern-scan.sh` 对刚合并 PR 做反模式启发式扫描（scope 膨胀 / over-generation / test evasion 等），命中时 stderr 警报。**启发式命中不是规则变更的自动触发器。**

**Why:** Hashimoto 的 "engineer the harness" 原则是把每次错误沉淀成永久纪律，但启发式会有假阳性（大型文档 PR 天然改动多文件、genuinely 新增功能的大 PR 天然 additions 高）。若让启发式直接写 feedback.md 或变更 CI 门禁，会产生噪声污染纪律体系，反而让真正的纪律失去权威性。

**How to apply:**
- Claude 下次开工读到 stderr 警报时，在 `docs/memory/handoff.md` 或 phase-closeout 的 Risks 段记录该警报
- 三次判断分档：
  - **单次偶然**（单个 PR 的特殊情况，如大型文档治理）→ 忽略，在 phase-closeout 显式注明忽略理由
  - **出现 2 次**（同类警报在 2 个 PR 中出现）→ 仍观察，不升级
  - **出现 3 次**（同类警报重复 3 次）→ phase-closeout 时升级，选择以下之一：
    - 新增 feedback 规则（F-0NN）
    - 扩展 `anti-pattern-scan.sh` 阈值或新增检测项
    - 追加 CI / hook 强制门禁
- 升级决策必须人类拍板（Claude 提议，用户批准），避免 AI 自写纪律循环

---

## F-020: Auto mode 不豁免 F-005 对抗性审查
<!-- added: 2026-04-19 | owner: human | type: permanent -->
<!-- trigger: Harness Stage A+B 7 PR 实现期间，Claude 连续推 5 个 PR 未做 Codex/Gemini 对抗审查，用户发现后补救（cross-audit 五 PR + 两轮 Codex retry，挡下 2 PR 合并） -->

F-001 "自主执行" 偏好的范围是免除 yes/no 确认每个代码改动。**不包括**免除 F-005（完成前必须对抗性审查）。在 Auto mode 下，Claude 把 "提 PR" 当成 "完成"、跳过 Codex 对抗审查直接推下一个 PR，**违反** F-005/F-008/F-016。

**Why:** 2026-04-19 Harness Engineering Stage A+B 实施中，Claude 在 Auto mode 下连续推 5 PR（#675/#676/#677/#678/#679）没做对抗审查。用户发现后补救，三方 cross-audit 暴露 Codex 独家 8 处硬伤，其中 #677/#678 触发 rubric 硬阈值必须 retry。这证明对抗审查不是仪式——是真能挡质量问题的工程门禁。

**How to apply:**
- Auto mode 只豁免"逐步确认"节奏，不豁免任何工程纪律门禁（F-005 / F-008 / F-014 / F-015 / F-016 / F-017 全部生效）
- PR push 后的**第一个** action 必须是启动 Codex 对抗性审查（或系列 PR 合并前统一做一次三方 cross-audit），不是"开下一个 PR"
- 即使 PR 看似 trivial（纯文档、单行 fix），也必须过 F-005——trivial 的 PR 复核成本极低，跳过没有正当理由
- 违反 F-020 的修复路径：停下当前工作 → 对已推但未审的 PR 补三方 cross-audit → 按 rubric 打分 → retry 或合并；不得 "合了再说"
- 对照检查：每次 Claude 准备说"搞定了 / 已 push / 等你合并"之前，自问 "Codex 审过这个 diff 了吗？"，没审就先审
