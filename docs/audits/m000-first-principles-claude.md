---
last_verified: 2026-05-24
layer: snapshot
scope: audit-product
freshness:
  max_age_days: 90
  decay_trigger: [m000_revision]
---

# M-000 第一性原理审计 — Claude (Opus 4.7)

## 污染声明

本审计在当前对话上下文中产出,对话前期已 brainstorm 出 29 项嫌疑清单。本产物的客观性受此锚定偏见影响。为减轻污染:
- 每项重新用 5 问独立审计(不沿用嫌疑标签)
- 允许新增/删除/合并/改 verdict
- 最终 verdict 以 5 问结论为准

## 总评

扫了 24 项。verdict 分布:**PRIMARY 6 / INHERITED 7 / ANALOGY 8 / UNDETERMINED 3**。核心结论:M-000 体系**少数核心动机站得住第一性**(异源多家、物理隔离、用户终审),但大量配套机制是模仿其他治理体系(宪法/RFC/ADR/经济学)的产物,真目的与机制之间存在断裂。最大风险是「概念借用过多」导致体系自重过大,反而违反 M-005 §E 古德哈特防御的精神。

---

## 待审项明细

### [C001] M-000 「协作宪法」定位

- 范围: Layer 1, §1
- 路径: `docs/meta/M-000-meta-vision.md`
- **目的**: 给整个项目协作体系一个最高优先级文件,所有规则冲突时仲裁回这里
- **机制**: 命名为「宪法」,要求所有派生 M-001~M-006 显式 reference,Overrule 走 user-decision-log
- **替代**: 直接命名「项目协作根规则」或「Root Rule」,不借用「宪法」概念
- **来源**: ANALOGY — 类比国家治理「宪法 + 法律」。「宪法」自带「神圣不可侵犯」「修订需重型流程」的隐含语义,但项目协作不需要这些
- **破坏测试**: 删除「宪法」叙事,改称「Root Rule」,系统功能不变。说明「宪法」是修辞包装而非功能必需
- **Verdict**: ANALOGY
- **改造建议**: 重写为朴素描述「项目最高优先级协作规则」,删除「宪法」修辞。理由:类比隐含的「神圣性」反而妨碍后续 Overrule 实操

### [C002] 8 项议题清单 (M-000 §2)

- 范围: Layer 1
- **目的**: 给 M-000 一个穷尽性的内容骨架
- **机制**: 8 项议题各对应一个 M-001~M-006 派生(部分议题合并)
- **替代**: 不预设议题数,让议题数随实际需要浮现
- **来源**: INHERITED — 8 项是 M-000 起草时用户口述的初稿议题数,没有底层证据证明「正好 8 项」是必要且充分的
- **破坏测试**: 减到 5 项 / 加到 12 项,M-000 仍能履行最高规则职能。8 这个数没有事实基础
- **Verdict**: INHERITED
- **改造建议**: 暂缓改造。8 项是凝固快照,改动 ripple 大;但应承认「8 项不是第一性,是历史落点」

### [C003] 默认多方异源 (M-000 §3)

- 范围: Layer 1
- **目的**: 防同源 LLM 主笔的盲点污染(实证:user-decision-log #006/#008)
- **机制**: 关键议题默认要求 ≥ 2 家异源 LLM 独立产出,折叠后才落地
- **替代**: 没有更朴素的方式 — 「让另一个独立视角看一遍」是认知防御的最底层手段
- **来源**: PRIMARY — 从「单家 LLM 必有训练偏好盲点」的底层事实直接推出
- **破坏测试**: 删除后,#006 (workflow.md 路径决策同源)、#008 (sanity check 自反性) 这类问题会无法识别,系统会持续在同源盲点上栽跟头
- **Verdict**: PRIMARY
- **改造建议**: 保留

### [C004] user-decision-log 格式(append-only,8 字段)

- 范围: Layer 1+5
- **目的**: 让用户终审决定不被后续 LLM 改写覆盖
- **机制**: append-only + 编号 + Overrule 字段 + 时间戳
- **替代**: git commit 历史本身就是 append-only,直接用 commit msg 标 `[DECISION]` 前缀也能达成
- **来源**: ANALOGY — 模仿 ADR 格式 (Architecture Decision Record)
- **破坏测试**: 删除后,用户决定散落在 commit msg / chat 历史里,检索困难,但append-only 不变
- **Verdict**: ANALOGY (但 ANALOGY 借得有道理,功能上确实有增益)
- **改造建议**: 保留,但承认「8 字段」是 ADR 模板借用,不是第一性

### [C005] 字数 B+ 方案 (2500 nwc + 400 代码块 + 4000 英译)

- 范围: Layer 1, §5
- **目的**: 防止元规则文档无限膨胀,保持「可一次性读完」
- **机制**: 三档预算 (中文正文 / 代码块 / 英译) 各自上限
- **替代**: 设「单次阅读时长上限 5 分钟」更直接 — 这才是真目的(可读性)
- **来源**: ANALOGY — 借用「字数限制」是从论文/PR/Twitter 来的惯性,但「字数 ≠ 可读性」(密度高的 500 字比稀薄的 2000 字更难读)
- **破坏测试**: 用「阅读时长」替代,体验上等价。当前 M-005 起草已经实证 2500 上限违反真目的(古德哈特,被 user-decision-log #009 突破)
- **Verdict**: ANALOGY
- **改造建议**: 重写为「软上限 + override_rationale 机制 + 真目的(可读性)优先」,删除「2500 nwc」硬数字

### [C006] Overrule 机制 (M-000 §6)

- 范围: Layer 1, §6
- **目的**: 用户能否决/修改任何 LLM 落地的决定
- **机制**: user-decision-log 新增 Overrule 字段,显式标注被覆盖的前序决定
- **替代**: 直接 `git revert` 或新增决定覆盖旧决定,不需要专门 Overrule 概念
- **来源**: ANALOGY — 「Overrule」来自法律语境(上级法院覆盖下级判决)。LLM 协作里所有决定本来就是用户终审,不需要专门动词
- **破坏测试**: 删除 Overrule 字段,改为「新决定 supersedes 旧决定 #N」,语义等价但更朴素
- **Verdict**: ANALOGY
- **改造建议**: 重写为 `supersedes: #N`,删除 Overrule 法律修辞

### [C007] 风险接受机制 (M-000 §7.1)

- 范围: Layer 1
- **目的**: 用户明确接受某个已识别风险,后续不再重复警告
- **机制**: 用户在 user-decision-log 声明 `risk_accepted: <risk_id>`
- **替代**: 一个 `known_risks.md` 标 `accepted` 状态即可,不需要进 user-decision-log
- **来源**: INHERITED — 模仿安全审计「risk acceptance」流程
- **破坏测试**: 删除后,LLM 可能重复警告已知风险。但 LLM 提示词加「不要重复警告同一风险」也能解决
- **Verdict**: INHERITED
- **改造建议**: 暂缓,边际成本低

### [C008] 结构性同源警告 (M-000 §7.2)

- 范围: Layer 1+4
- **目的**: 提醒 4 家中 Claude 桌面端 + CLI 是同源(都是 Claude 4.7),不算异源
- **机制**: 标注模型版本,警告同模型族不算异源
- **替代**: 直接要求异源 = 不同公司/不同模型族,不需要单独「同源警告」概念
- **来源**: PRIMARY — 从「同模型同训练数据 → 同盲点」的事实推出
- **破坏测试**: 删除后,容易把 Claude 桌面端 + CLI 当成 2 家异源,污染异源纪律
- **Verdict**: PRIMARY
- **改造建议**: 保留,但条款表述可简化

### [C009] 4 家 LLM 选型 (Claude / Codex / DS / GM)

- 范围: Layer 2
- **目的**: 在「不同公司 + 不同训练数据」前提下,凑齐够多的异源视角
- **机制**: Anthropic Claude + OpenAI Codex + DeepSeek + Google Gemini = 4 家
- **替代**: 3 家(Claude+DS+GM)够不够? 5 家(加 Mistral/Qwen)够不够?
- **来源**: INHERITED — 4 家是当前帅哥手头有 API/CLI 可调用的家,不是「4 是最优数」推出来的
- **破坏测试**: 3 家场景下 (DS 故障时) 实证可用 (M-005 plan 审就只有 DS+GM 2 家也得出强收敛)。4 不是必需
- **Verdict**: INHERITED
- **改造建议**: 重写为「≥ 2 家不同公司异源」,不绑定 4 这个具体数

### [C010] worktree 物理隔离工作流

- 范围: Layer 2+3
- **目的**: 防止外审 LLM 看到 Claude 已有产出导致分工/抄袭
- **机制**: `git worktree add ../snapdrill-ios-codex -b audit/codex-*` 物理分支独立目录
- **替代**: 没有更直接的方式 — 文字提示词封堵「不要看 Claude 产出」在 Phase 10 实战已被证实失败
- **来源**: PRIMARY — 从 Phase 10 实证(文字封堵失败,LLM 解读「Claude 已抓 X」为分工)直接推出
- **破坏测试**: 退回到文字封堵,Phase 10 污染必复现
- **Verdict**: PRIMARY
- **改造建议**: 保留,核心机制

### [C011] 5 phases 起草流程

- 范围: Layer 2
- **目的**: 给元规则起草一个可重复的流程模板
- **机制**: P1 议题对齐 / P2 4 家独立 / P3 折叠 / P4 主笔 / P5 sign-off
- **替代**: M-005 plan 审实证 3 phases (sketch / 异源对决 / 用户裁决) 也够
- **来源**: ANALOGY — 5 phases 是软件工程「瀑布模型」的模仿,不是从底层需求推
- **破坏测试**: M-005 plan 审实证 3 步够用,5 步反而带来 P3+P5 双重用户干预,产生认知摩擦(DS+GM 共识)
- **Verdict**: ANALOGY
- **改造建议**: 重写为「最少 3 phases:sketch / 异源 / 终审」,phases 数随议题复杂度浮动

### [C012] sanity check 自反性 (跨 Round 复盘)

- 范围: Layer 2+4
- **目的**: 防 sanity check 本身陷入应声虫
- **机制**: Round N 的 prompt 要求 reviewer 复盘 Round N-1 的反馈是否仍然站得住
- **替代**: 没有更朴素的方式 — 这是元层级反思的最底层手段
- **来源**: PRIMARY — 从 #008 实证(GM Round 2 自我撤回 R1)直接推出
- **破坏测试**: 删除后,sanity check 退化为「另一个 LLM 看一遍点头」,失去自纠错能力
- **Verdict**: PRIMARY
- **改造建议**: 保留

### [C013] 净化提示词概念

- 范围: Layer 2
- **目的**: 让外审 LLM 在零先验下独立判断
- **机制**: 提示词不出现「Claude 已抓 X」「请覆盖 Y」「参考 consensus」等分工/锚定句式
- **替代**: 没有更朴素的方式 — 与 worktree 物理隔离配套
- **来源**: PRIMARY — 从 Phase 10 污染实证推出
- **破坏测试**: 删除后,worktree 物理隔离的价值被泄漏的 prompt 销蚀
- **Verdict**: PRIMARY
- **改造建议**: 保留,但「净化」的具体规则需明确定义(M-005 §F 应承载)

### [C014] docaudit 11 check

- 范围: Layer 3
- **目的**: 机械化执行文档治理纪律,不依赖 LLM 自觉
- **机制**: Python 脚本扫 frontmatter / 引用 / freshness 等 11 个维度
- **替代**: 11 个 check 每个都是独立功能,本身不是一个统一概念
- **来源**: UNDETERMINED — 11 个 check 中,有些是底层需要(frontmatter 解析、broken link),有些可能是堆出来的(verdict-sync 这种)
- **破坏测试**: 需逐个 check 单独评估,无法整体评判
- **Verdict**: UNDETERMINED
- **改造建议**: 暂缓,需要拆开逐个 check 做 5 问

### [C015] frontmatter layer 6 枚举 (principle/pattern/snapshot/archive/decision/contract)

- 范围: Layer 3+4
- **目的**: 文档分类,方便检索与生命周期管理
- **机制**: 6 类枚举值,每个文档必须 declare
- **替代**: 标签系统 (tag list) 更灵活,允许多标签;6 类硬枚举强迫单选造成 边界模糊文档归类困难
- **来源**: INHERITED — 6 类是 ADR-004 起草时摸索的分类,不是从「文档生命周期事实」推出
- **破坏测试**: 把 6 类改为 tag 系统,文档检索体验类似,但避免「pattern vs principle 怎么分」这种 bikeshedding
- **Verdict**: INHERITED
- **改造建议**: 重写为多标签,删除单选枚举

### [C016] frontmatter status 3 枚举 (active/archived/deprecated)

- 范围: Layer 3+4
- **目的**: 标识文档生命周期状态
- **机制**: 3 类枚举
- **替代**: 2 类够 (active / inactive),deprecated vs archived 区分模糊(#008 side-channel 实证 — `partially_superseded` 都得走 supersession_status 字段)
- **来源**: ANALOGY — 模仿 npm package status (active/deprecated)
- **破坏测试**: 简化为 2 类 (active/inactive) + supersession_status 描述细节,信息不丢
- **Verdict**: ANALOGY
- **改造建议**: 重写为 2 类 + 细节字段

### [C017] ADR-004 5 Phase 方法论

- 范围: Layer 3
- **目的**: 给文档结构清洁一套可复用流程
- **机制**: Phase 0-9 (起步 → 体检 → 裁决 → 修复 → 治理升级 → ...)
- **替代**: 没必要预设 Phase 数,清洁就清洁,该几步几步
- **来源**: INHERITED — Phase 编号是实际执行时落出来的历史记录,不是预先设计的方法论
- **破坏测试**: 后续清洁不强制走 5 Phase,效果应等价
- **Verdict**: INHERITED
- **改造建议**: 重写 ADR-004 为「核心步骤(接管/体检/裁决/修复)+ 可选治理升级」,删除 Phase 编号

### [C018] ADR-005 7 维度切分

- 范围: Layer 3
- **目的**: 把语义层审计拆成 7 个维度独立扫描
- **机制**: D1 declared/actual / D2 incoming/outgoing / D3 evidence / D4 verdict / D5 risk / D6 lifecycle / D7 governance
- **替代**: 7 维度是审计员主观切分,没有底层证据证明「正好 7 维度」
- **来源**: INHERITED — 7 是 ADR-005 起草时落出的数,可能 5 维度 / 9 维度也行
- **破坏测试**: 5 维度合并 (incoming+outgoing 合 / risk+lifecycle 合) 系统不退化
- **Verdict**: INHERITED
- **改造建议**: 暂缓,7 维度已凝固于 Phase 10 历史快照,改动 ripple 大

### [C019] audit-ledger TSV 格式 (24 字段)

- 范围: Layer 3
- **目的**: 文件级 verdict 表格化,可被脚本/grep 处理
- **机制**: TSV + 24 字段(Path/Verdict/Confidence/三家裁决/...)
- **替代**: 24 字段中有冗余(Codex_Verdict/Gemini_Verdict 列大部分为空,Phase 5+ 单家裁决);可压缩
- **来源**: ANALOGY — 模仿 spreadsheet 治理 + 24 字段是「ADR-004 起草时凑出的全集」
- **破坏测试**: 砍到 10-12 字段(核心 Path/Verdict/Confidence/Reason/Final_Decision),功能等价
- **Verdict**: ANALOGY
- **改造建议**: 重写 schema,瘦身字段

### [C020] KNOWLEDGE_MAP / DOC_DEPENDENCY_MAP 两张图

- 范围: Layer 3
- **目的**: 文档总览 + 变更影响传播
- **机制**: 手工维护的 markdown 表格
- **替代**: 自动化(脚本扫 frontmatter + 引用图)生成 — 手工维护必漂移
- **来源**: INHERITED — 模仿 architecture diagram 文化
- **破坏测试**: 删除两张图,新成员靠 grep + frontmatter 直接读 docs/ 也能上手,但需更多时间
- **Verdict**: INHERITED
- **改造建议**: 暂缓,有边际价值但应转自动生成

### [C021] F 规则索引 (F-001~F-021)

- 范围: Layer 3
- **目的**: 沉淀历史 feedback,防同样的错重犯
- **机制**: 21 条规则带编号,在 feedback.md 列出
- **替代**: 编号是不是必要?直接按主题分组(测试纪律/PR 纪律/...)更直接
- **来源**: ANALOGY — 模仿 CWE/CVE 编号体系
- **破坏测试**: 删除编号,按主题分组,可读性不降反升
- **Verdict**: ANALOGY
- **改造建议**: 重写为主题分组,允许保留编号作为引用锚点(but 不强制递增)

### [C022] 同源 vs 异源二元对立

- 范围: Layer 4
- **目的**: 给「需要多视角」决策一个判据
- **机制**: 同公司同模型 = 同源,跨公司跨模型 = 异源
- **替代**: 二元划分简化了真实情况(Claude 4.7 vs 4.6 算同源?Codex (GPT-5) vs ChatGPT (GPT-5) 算同源?) — 实际是连续光谱
- **来源**: ANALOGY — 借用统计学「独立样本」概念,二元化是简化
- **破坏测试**: 改为「异源度评分 (0-1)」,Claude vs Codex 评 0.8,Claude vs Claude 评 0.1,操作更精确
- **Verdict**: ANALOGY
- **改造建议**: 重写为光谱,但 v1.0 二元已够用,暂缓

### [C023] 古德哈特防御 (Form over Substance)

- 范围: Layer 4
- **目的**: 防「指标变成目标后被优化游戏化」
- **机制**: 命名为「古德哈特定律」+ Form over Substance 双标签
- **替代**: 直接说「不要让规则字面优先于规则目的」,不借用经济学术语
- **来源**: ANALOGY — Goodhart's Law 来自经济政策(Charles Goodhart 1975),迁移到 LLM 协作上下文需要重新论证
- **破坏测试**: 改名「目的优先于字面」,语义等价,但少了一个学术词汇的「装饰性权威」
- **Verdict**: ANALOGY (但概念本身在 LLM 上下文真实成立 — 帅哥说「2500 nwc 不能挤压表达力」就是实证)
- **改造建议**: 保留概念,可考虑简化命名

### [C024] side-channel frontmatter (`status: active` + `supersession_status: partially_superseded`)

- 范围: Layer 3+4+5
- **目的**: 表达「部分被替代」状态而不破坏现有 validator
- **机制**: 双字段:`status` 兼容 validator,`supersession_status` 携带真实语义
- **替代**: 直接扩展 status 枚举到 `{active, partially_superseded, fully_superseded, archived}`,但会触发下游 consumer 脚本断裂
- **来源**: UNDETERMINED — workaround,本身就是承认了 status 枚举设计不够。是底层需要还是 schema 设计缺陷的折中?
- **破坏测试**: 重新设计 status 枚举,迁移 consumer 脚本,side-channel 可删
- **Verdict**: UNDETERMINED — 暴露了 [C016] status 3 枚举的不足
- **改造建议**: 与 [C016] 一起重审

---

## 跨项观察 (Meta)

### 集中 ANALOGY 簇 1: 法律/政治隐喻

[C001 宪法] [C006 Overrule] [C022 同源/异源] — 都借用法律/政治词汇。**风险**:法律隐喻带来「修订成本高」「上下级关系」等隐含语义,可能阻碍 M-000 体系自身的迭代速度。

### 集中 ANALOGY 簇 2: 软件工程模板

[C004 ADR 格式] [C005 字数预算] [C011 5 phases] [C015 layer 枚举] [C016 status 枚举] [C019 TSV 字段] [C021 F 编号] — 大量来自 ADR/RFC/CWE/PR 模板。**风险**:模板是别人解决别人的问题,搬过来不一定 fit。

### 集中 PRIMARY 簇: 异源对抗实证

[C003 多方异源] [C008 同源警告] [C010 worktree] [C012 sanity check 自反性] [C013 净化提示词] — 全部来自实战污染教训(#006/#008 + Phase 10)。**信号**:这是 M-000 真正第一性的部分。

### 元结论

**M-000 体系的真正第一性内核可能只有 ~5 条**(异源对抗 + 物理隔离 + 自反性),其余 ~70% 是模板借用。如果重写 M-000 v2.0,可以瘦身到 ~600-800 nwc 而非当前 ~2400 nwc。

但是 — **此结论本身需要异源 sanity check**(我可能高估了「精简化」的价值,这正是 Claude 训练偏好之一:倾向极简主义美学)。
