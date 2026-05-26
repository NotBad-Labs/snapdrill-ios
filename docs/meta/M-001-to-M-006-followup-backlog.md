---
last_verified: 2026-05-25
layer: pattern
scope: meta
freshness:
  max_age_days: 90
  decay_trigger: [m_001_to_m_006_drafted]
derived_from: [M-000 §11.1]
---
# M-001~M-006 起草 Follow-up Backlog

> 4-way sign-off ([user-decision-log #004](user-decision-log.md)) 收到的 10 条 Minor Concerns，按下游派生归类。
> 起草 M-001~M-006 时必须查阅本 backlog 对应章节。

## MC-1: §4.3 双核「不可用」定义需含静默退化 + 适用范围限定

- **提出方**: Gemini G2 + Codex C2 + DeepSeek 隐含
- **问题**: M-000 §4.3「当任一方不可用」未区分:
  - 物理不可用(API 报错/超时)
  - 静默退化(prompt injection / 上下文污染 / 微调漂移 → 胡言乱语但物理"可用")
- **归宿**: **M-002 分歧裁决** + **M-005 质量判据**
- **具体落实**:
  - M-002 在「双核默认通过」适用范围明确:**只覆盖普通、可逆、低外部副作用事项**;非普通事项升级用户
  - M-005 定义「静默退化」识别信号(格式崩溃 / 自相矛盾 / 偏离任务 / 身份误识别),触发"逻辑不可用"判定 → 同物理不可用回退用户

## MC-2: §7.2 异源判断与 user-decision-log #002 的宪法层映射

- **提出方**: Codex C3 + Gemini G1
- **问题**: §7.2「异源 = 独立模型权重 + 独立训练谱系」需要外部事实核验,但 #002 WebSearch 验证纪律未在宪法层有原则锚
- **归宿**: **M-005 质量判据** + **M-001 协作工作流**
- **具体落实**:
  - M-005 明文:「AI 模型/工具版本事实必须 WebSearch / 官方来源验证,不信训练记忆。检测异源时同样适用——训练谱系判断须基于厂商公开声明,不依赖智能体自我宣称(实证: §7.2 sign-off 中 DeepSeek/Gemini 互换身份)」
  - M-001 工作流要求:启动多家任务前,主笔须验证当前各家模型 ID 与可用性(对接 `agent-cli-models.md` 30 天刷新机制)

## MC-3: §5 字数定义两处表述潜在重复

- **提出方**: DeepSeek D1 独家
- **问题**: M-000 文档头摘要「正文≤2500 non-whitespace chars」+ §5 主体「主体 ≤2500 non-whitespace chars」表述重复
- **归宿**: **M-000 v1.3 候选(轻微修订,不阻塞 sign off)** 或忽略
- **建议**: 不立即触发 v1.3——文档头摘要是导览句,§5 是完整规则,两处目的不同。但如未来有 v1.3 修订机会(任何主要修订时),合并表述
- **状态**: ⏸️ 暂不修订,等待 v1.3 触发条件

## MC-4: §3 数据治理「用户未定义」空档

- **提出方**: Codex C4
- **问题**: §3「跨厂商共享须经用户明确批准;敏感信息脱敏策略由用户定义」——用户未定义时产生空档
- **归宿**: **M-006 数据治理**
- **具体落实**:
  - M-006 默认值:**用户未定义脱敏策略时,默认最小披露 + 默认不跨厂商共享 + 默认记录缺口**
  - 缺口纳入 M-002 裁决日志,触发用户后续补充

## MC-5: §4.3 裁决清单变更的边界

- **提出方**: DeepSeek D2
- **问题**: 「裁决智能体清单变更记录于裁决日志」未明确变更类型:
  - 新增/移除模型 → 显然算变更
  - 模型版本升级(v2→v3 同厂商) → 算不算?
- **归宿**: **M-002 分歧裁决**
- **具体落实**:
  - M-002 明文:**同一服务商内的版本升级(如 Gemini 2.5 → 3.5)不视为清单变更**,但须在 `agent-cli-models.md` 更新 last_verified;能力跃迁导致裁决资格变化时,在裁决日志补一行说明
  - 跨服务商替换(如 GPT 替换 Gemini)算正式变更,走完整流程

## MC-6: §5 译本乘数 1.6 系数来源缺注

- **提出方**: DeepSeek D3
- **问题**: 「未来英文译本使用独立乘数,约 4000 non-whitespace chars」未注明 1.6 系数采自 user-decision-log #003 DeepSeek 提议
- **归宿**: **user-decision-log #003 注记补充**(已在本批次同步落实)
- **状态**: 不修 M-000 正文(避免膨胀);在 #003 加 4000 = 2500 × 1.6 的脚注,实际产生英文译本时再验证系数

## MC-7: §7.3「自动触发」实际为手动

- **提出方**: DeepSeek D4
- **问题**: 「服务发生重大或持续性变化时,自动触发 M-000 review」当前无自动监控基础设施
- **归宿**: **M-004 降级操作手册** + **措辞修订**(可选 v1.3)
- **具体落实**:
  - M-004 明确「触发"由感知方发起(任一智能体或用户),不依赖自动监控」
  - M-000 措辞:可选在 v1.3 修订为「应触发」替换「自动触发」,但不阻塞
- **状态**: 暂不修 M-000;M-004 起草时含

## MC-8: frontmatter `status: active + ratification: ratified` 语义

- **提出方**: Codex C1
- **问题**: `ratification: ratified` 在文档已 ratify 后是稳定状态,但措辞略有「预批准」感
- **归宿**: 已 sign-off,**状态正确**,可忽略
- **状态**: ✅ 无需动作

## MC-9: iOS 工程特有「不可逆」灰色地带

- **提出方**: Gemini 盲点
- **问题**: M-000 §4.3「不可逆 = 跨越本地工作区边界 + 外部副作用 + 对外承诺」对 iOS 项目过于抽象:
  - `git push` 算不算?(算,跨越本地工作区)
  - `fastlane match` 证书同步算不算?(算)
  - 修改 `project.pbxproj` 算不算?(灰色,影响构建但本地可逆)
- **归宿**: **M-004 降级操作手册** + iOS-specific skill 文档
- **具体落实**: M-004 明确 iOS 特有不可逆动作清单(git push / fastlane match / TestFlight 发布 / Apple ID 改动 / 数据库迁移 / 证书操作 / ...);灰色区动作(pbxproj)默认按"需双核同意"处理

## MC-10: 异源否决权滥用 → 注意力通胀

- **提出方**: Gemini 盲点
- **问题**: §7.2 异源辅助方"强烈、具体、可证伪反对"会触发双核失效。如辅助方频繁就非关键技术细节"强反对",触发用户裁决的频率会过高,违背 §3「承认注意力成本」初衷
- **归宿**: **M-002 分歧裁决** 否决阈值机制
- **具体落实**: M-002 定义"强烈反对"的客观判据:
  - 引用具体事实错误
  - 提出可证伪的反假设
  - 指出明确风险路径
  仅"我感觉不对"不构成强烈反对。同时设连续触发率阈值(如 24 小时内辅助方触发 ≥ 5 次升级,需用户介入审视辅助方是否退化或滥用否决权)

## MC-11: sync-status skill 双向维护 STATUS.md

- **来源**: user-decision-log #006
- **问题**: Round 1 Boot 重构后，`STATUS.md` 保留为 minimal stub；长期权威状态不能依赖手动复制，也不能在 Boot 阶段加载旧的大型状态快照
- **归宿**: **M-002 分歧裁决与裁决日志**
- **理由**: `sync-status` 的核心职责是把裁决日志、Overrule、进行中工作与状态快照做双向同步，属于「裁决事实如何被记录、读取、更新」的问题；它依赖质量判据，但主归宿不是 M-005
- **具体落实**:
  - 设计 `sync-status` skill：session start 读取 `user-decision-log.md`、backlog、git/GitHub 状态，生成当前状态视图
  - session end 写回 `STATUS.md` 极简手动条目，避免软状态漂移
  - 明确冲突优先级：user-decision-log > backlog > git/GitHub live state > STATUS stub
  - 记录无法自动判定的缺口，不擅自把推论写成事实

## MC-12: M-005 §G.7 加 audit 流程 counter-verify 纪律

- **来源**: Goal H7 P0 verify 实证（[docs/audits/h7-p0-verify-20260526.md](../audits/h7-p0-verify-20260526.md)）
- **问题**: 主笔自审 derived_from 修复建议**准确率 0%**（6 个建议全部被异源 REJECT/REFINE），其中 2 处事实错误（引用不存在的章节/概念）+ 1 处术语混淆 + 3 处方向偏差。当前 M-005 §G 只规定 docaudit check 设计，没有规定「audit 报告产出后必须 counter-verify」流程。
- **归宿**: **M-005 §G.7 新增**「audit 流程 counter-verify 纪律」
- **理由**: feedback_numeric_alignment_blindspot 第 6 条「跨 vendor 异源不能完全消除盲信但能补主笔单点盲区」已升级为强制流程必需。本会话双家异源（agy + DeepSeek）+ 主笔 grep counter-verify 防止了所有 6 处错误。这是治理流程级问题，应固化到 M-005 元规则。
- **具体落实**:
  - M-005 §G.7（新增）：audit 报告 P0 修复建议必须经 ≥2/3 异源 agreement + 主笔 grep counter-verify 才能落地
  - audit 报告若 finding 误报率 >20% 需驳回重做
  - 主笔自审单独不足以作为 derived_from 修改依据
  - 触发：所有 audit 报告含「修复建议」「修改建议」「重新标注建议」类内容
- **配套机制**（已部分实施）:
  - `.claude/hooks/pre-edit-derived-from.sh`（已 deb6f0a8 commit）：detect derived_from 字段修改时 stderr 提示 counter-verify
  - `.claude/hooks/pre-edit-numeric-alignment.sh`（已 0fc3ac88 commit）：detect §N 对照声明
- **关联**: H7 audit 系列 + audit agent 自身污染 55% 实证

## MC-13: M-000 §11.10 v2.2 schema 扩展（同级派生 + ADR 引用）

- **来源**: Goal H7 P0 verify 暴露的 schema 表达力 gap
- **问题**: M-000 §11.10 v2.1 schema 仅允许 `M-NNN` / `M-NNN §N` / `user-decision-log #NNN`，**不允许 ADR-NNN 引用**，且不允许同级 standards-to-standards 派生（如 shared-constraints 实际是多 standards + product docs 汇总）
- **归宿**: **M-000 §11.10 v2.2 升级**
- **理由**: H7 P0 修复揭出 knowledge-health-workflow 派生 `[ADR-004, M-005 §G]` 但 ADR-004 不在 schema 允许范围；同样 cross-audit-workflow 派生关系复杂涉及 M-001 + M-003 + 自身 F-008 定义
- **具体落实**:
  - schema 扩展允许 `ADR-NNN` / `ADR-NNN §N` 元素
  - 考虑允许 `standards/<file>.md` / `templates/<file>.md` 文件路径形式表达同级派生
  - 或新增 `related_to: [...]` 字段表达「非派生但相关」关系
- **当前 workaround**: ADR-NNN 在 derived_from 字段中实际有用（docaudit `derived_from_required` proposed 未实施），但需 v2.2 正式允许

---

## 起草顺序建议

依赖关系分析(MC 归属):
- **M-005**(质量判据): MC-1 静默退化 + MC-2 WebSearch 验证 ← 多家依赖,**优先起草**
- **M-002**(分歧裁决): MC-1 + MC-5 + MC-10 + MC-11
- **M-006**(数据治理): MC-4
- **M-001**(协作工作流): MC-2 部分
- **M-004**(降级手册): MC-7 + MC-9
- **M-003**(技能库治理): 无 MC 直接依赖

主笔建议顺序:**M-005 → M-002 → M-006 → M-001 → M-004 → M-003**(底层判据先定,治理流程后定,长尾外置最后)

---

## 关联文档

- [docs/meta/M-000-meta-vision.md](M-000-meta-vision.md) v1.2 ratified
- [docs/meta/user-decision-log.md](user-decision-log.md) #001/#002/#003/#004/#005/#006
- [docs/meta/M-000-signoff-{codex,deepseek,gemini}.md](.) 三家 sign-off 原文
- [docs/tech/reference/agent-cli-models.md](../tech/reference/agent-cli-models.md) 工具/模型快照(30 天刷新)
