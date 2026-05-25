---
last_verified: 2026-05-25
layer: snapshot
scope: skill-audit
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: "DeepSeek reasoner 独立审计52个skill，依据M-000 P1-P8 + M-005 §A判据 + 第一性原理，物理隔离，不参考其他家产出。本审计密度证明：每个Verdict必须含可追溯实证、可验伪信号、元规则对齐分，不可省略任何字段；52个skill逐一展开，不可抽样；元层级观察总结生态结构问题；Verdict统计提供治理/工具比例。任一段缺失将导致审计不可追溯或不可验伪。"
---

# DeepSeek Skill 审计报告

## 1. 总结表

| # | Skill | Verdict |
|---|-------|---------|
| 1 | accessibility-generator | DELETE |
| 2 | animation-patterns | PROMOTE_TO_STANDARDS |
| 3 | api-research | KEEP |
| 4 | app-description-writer | DELETE |
| 5 | app-icon-generator | KEEP |
| 6 | app-store-assets | KEEP |
| 7 | app-store-rejection | KEEP |
| 8 | attributed-string | DELETE |
| 9 | background-processing | KEEP |
| 10 | characterization-test-generator | DELETE |
| 11 | ci-cd-setup | KEEP |
| 12 | coding-best-practices | KEEP |
| 13 | cross-audit | REWRITE |
| 14 | cross-audit-consensus | REWRITE |
| 15 | data-export | KEEP |
| 16 | decision-closeout | REWRITE |
| 17 | deep-linking | DELETE |
| 18 | dependency-propagation | KEEP |
| 19 | dod-checklist | REWRITE |
| 20 | error-monitoring | KEEP |
| 21 | harness-recall | REWRITE |
| 22 | integration-test-scaffold | DELETE |
| 23 | keyword-optimizer | KEEP |
| 24 | knowledge-health | REWRITE |
| 25 | liquid-glass | DELETE |
| 26 | localization-setup | KEEP |
| 27 | migration-patterns | PROMOTE_TO_STANDARDS |
| 28 | navigation-patterns | DELETE |
| 29 | onboarding-generator | KEEP |
| 30 | phase-closeout | KEEP |
| 31 | post-merge | REWRITE |
| 32 | privacy-manifests | DELETE |
| 33 | push-notifications | DELETE |
| 34 | resume-from-handoff | REWRITE |
| 35 | review-response-writer | DELETE |
| 36 | screenshot-planner | DELETE |
| 37 | settings-screen | KEEP |
| 38 | snapshot-diff-review | KEEP |
| 39 | snapshot-testing | KEEP |
| 40 | sprint-contract | REWRITE |
| 41 | swift-concurrency-pro | KEEP |
| 42 | swiftdata-pro | KEEP |
| 43 | swiftui-debugging | PROMOTE_TO_STANDARDS |
| 44 | swiftui-pro | KEEP |
| 45 | tdd-bug-fix | KEEP |
| 46 | tdd-feature | KEEP |
| 47 | tdd-refactor-guard | KEEP |
| 48 | test-contract | DELETE |
| 49 | tipkit-generator | KEEP |
| 50 | ui-review | KEEP |
| 51 | verify-audit-report | REWRITE |
| 52 | xcode-review | PROMOTE_TO_STANDARDS |

## 2. Verdict 详情

### 1. accessibility-generator (adapter)

- **Verdict**: DELETE
- **可追溯实证**: 该skill仅为 `.agents/skills/accessibility-generator/SKILL.md` 的adapter，正文仅含“Claude Code adapter”和路径引用。依据M-000 §6「每个概念只有一处权威定义」——双份adapter违反SSOT原则。路径 `#016` 启动路径C审计时已识别双份存在的16个skill，当前adapter无独立治理价值。
- **可验伪信号**: 如果能证明 `.claude/skills/accessibility-generator/` 被Claude Code的discovery机制必须依赖此adapter才能触发共享skill，且删除后共享skill不可达，则可推翻DELETE。但实际Claude Code可配置直接搜索 `.agents/skills/`。
- **元规则对齐分**: 1（完全脱节，无实质内容）
- **使用频率估计**: 低

### 2. animation-patterns

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 内容为SwiftUI动画模式的技术参考，含决策树、API形状、常见错误预防。属于规则性知识（“正确API形状”“常见错误”），不是动作模板或元规则执行器。依据M-000 §6「规则、模式、准则应下沉到standards」；M-005 §A.3下沉证明要求：若内容可被静态文档替代则不应为skill。本skill的决策树和参考文件完全可移动至 `docs/standards/animation-patterns.md`。
- **可验伪信号**: 若能证明该skill的触发机制（如用户说“弹簧动画”时自动加载参考）对效率提升超过静态standards，则可能推翻PROMOTE。但静态standards也可被LLM检索。
- **升级目标**: `docs/standards/animation-patterns.md`
- **元规则对齐分**: 3（内容有价值但形式错误，不应为skill）
- **使用频率估计**: 中

### 3. api-research

- **Verdict**: KEEP
- **可追溯实证**: 强制执行F-017规则（新增UI组件或引入新SDK API前查Apple最新文档）。该规则源于 `#002`（AI模型/工具版本信息需WebSearch验证），并扩展至Apple API。skill工作流包含确认iOS版本、搜项目内部知识库、WebSearch，可动态适应当前项目。依据M-000 P1「相同完整任务不分工」——每个调用需求都是一个完整研究任务。M-005 §D外部事实验证纪律要求WebSearch验证，本skill直接执行该纪律。
- **可验伪信号**: 若查实该skill从未实际触发或所有研究均可由手动WebSearch完成，则可推翻KEEP。但当前iOS 26+频繁更新API，自动化研究价值明确。
- **下沉证明**: 不能下沉到standards，因为需要动态检测部署目标、grep项目内已有知识、WebSearch最新文档；静态规则无法覆盖实时版本变化。
- **元规则对齐分**: 5（完全对齐M-005 §D和M-000 P7净化提示词？其trigger描述不会泄露其他方结论）
- **使用频率估计**: 高

### 4. app-description-writer (adapter)

- **Verdict**: DELETE
- **可追溯实证**: 与accessibility-generator相同，纯adapter，内容指向 `.agents/skills/`。违反M-000 §6 SSOT。`#016` 路径C已识别双份问题。
- **可验伪信号**: 同1。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 5. app-icon-generator

- **Verdict**: KEEP
- **可追溯实证**: 工具skill，生成app图标代码。含Pre-Generation Checks（检测项目上下文、现有图标），生成CoreGraphics脚本，安装到asset catalog。这是iOS工程实用工具，与元规则无直接冲突。依据M-000 §3默认多方异源不适用于低风险机械操作（图标生成可逆、视觉属性），本skill可单方执行。M-001尚未起草，但按第一性原理，工具skill应保留。
- **可验伪信号**: 若证明LLM直接写脚本比用skill更高效无错误，可考虑DELETE。但当前skill封装了check和格式约束，减少错误。
- **下沉证明**: 需要动态识别项目平台（iOS/macOS/universal）和现有图标，不是纯静态模板；不能下沉到standards或模板。
- **元规则对齐分**: 4（内容对齐工程实践，无元规则违规）
- **使用频率估计**: 低

### 6. app-store-assets

- **Verdict**: KEEP
- **可追溯实证**: 生成App Store资产规格和清单，含交互式配置（询问平台和资产类型）。提供综合资产清单，防止遗漏。依据M-000 §9目的优先——本skill服务于App Store提交目的，减少出错。无元规则冲突。
- **可验伪信号**: 若App Store Connect工具未来提供自动化资产检测，则可能降低价值。
- **下沉证明**: 需要根据用户选择的平台动态生成清单，且可集成AskUserQuestion交互，静态清单无法适应多样性。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 7. app-store-rejection

- **Verdict**: KEEP
- **可追溯实证**: 处理App Store拒绝指南，含Pre-Submission Audit Checklist。该Checklist基于Apple官方Guidelines，可帮助避免常见拒绝原因。属于工具skill，是项目质量门的一部分。引用M-005 §G docaudit check设计原则——check必须有真实事故来源，本skill的checklist映射到具体Guideline条款。
- **可验伪信号**: 若Apple改变Guideline结构使checklist失效，则需REWRITE。
- **下沉证明**: 需要根据具体拒绝原因动态生成响应模板和引用，不是纯静态。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 8. attributed-string (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 9. background-processing

- **Verdict**: KEEP
- **可追溯实证**: 生成后台处理基础设施，含BGTaskScheduler/URLSession/静默推送。含Pre-Generation Checks（检测部署目标、现有代码），生成可编译代码。工具skill。与元规则无冲突。
- **可验伪信号**: 若iOS版本更新使BGTaskScheduler行为变化，skill可能过时。
- **下沉证明**: 需要检测项目现有代码和部署目标，动态生成。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 10. characterization-test-generator (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 11. ci-cd-setup

- **Verdict**: KEEP
- **可追溯实证**: 生成CI/CD配置，含GitHub Actions/Xcode Cloud/fastlane。工具skill。含Pre-Generation Checks检测现有CI文件和项目结构。与元规则无冲突。
- **可验伪信号**: 若项目CI已是成熟流水线，可能不需要。
- **下沉证明**: 动态检测项目结构，生成匹配的yaml。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 12. coding-best-practices

- **Verdict**: KEEP
- **可追溯实证**: 代码审查skill，加载参考模式（swift-patterns等）进行review。工具skill，帮助保持代码质量。其Review Process与M-005 §A判据可追溯性精神一致（要求引用具体模式）。无元规则冲突。
- **可验伪信号**: 若review过程导致大量误报，则可能需REWRITE。
- **下沉证明**: 需要根据代码上下文动态应用参考模式，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### 13. cross-audit

- **Verdict**: REWRITE
- **可追溯实证**: 三方对抗性审查工作流。当前版本引用旧F-008/F-011/F-012规则，而这些规则已被M-000 P1/P3/P5/P7吸收。skill启动模板假设Claude为主线程，违反P1「不分工」精神（应各家独立完成）。`#013` 揭示了subagent调度未强制注入SSOT。`#014 D5` 要求技能内容与元规则对齐。本skill当前文本与M-000 §3默认多方异源、M-005 §B伪共识识别、§F自反性sanity check不一致。
- **可验伪信号**: 若能证明该skill的所有功能已完全被M-000/M-005覆盖且无需skill，则更应DELETE而不是REWRITE。但cross-audit的具体执行模板（如启动命令、fork上下文）仍有价值。
- **重写要点**: (1) 删除对所有F-规则的引用，替换为M-000 P1/P3/P5/P7和M-005 §B/§F；(2) 启动模板改为中性（不预设Claude为主线程），去除“给Claude（主线程）”固定措辞；(3) 增加SSOT强制注入步骤（#013 D.4.1）；(4) trigger净化：检查是否泄露其他方结论；(5) 参考M-005 §G docaudit check设计原则。
- **元规则对齐分**: 2（当前版本与元规则部分冲突）
- **使用频率估计**: 高

### 14. cross-audit-consensus

- **Verdict**: REWRITE
- **可追溯实证**: 汇总三方结果的skill。输出格式固定，引用旧cross-audit-consensus §2.5。但M-005 §B已定义伪共识识别和否决权重（如#014 D8 thinking mode折扣），本skill未体现。且trigger“用户说汇总三方”可能绕过净化提示词。依据#015 M-005 ratify时已确认需重写治理skill。
- **可验伪信号**: 若元规则完全接管共识流程，此skill可DELETE。
- **重写要点**: (1) 输出格式引用M-005 §B触发信号清单和§F自反性；(2) 增加Gemini特殊处置（#013）；(3) 去除对旧consensus文档的引用；(4) 增加否决阈值检查（#014 D1）。
- **元规则对齐分**: 2
- **使用频率估计**: 高

### 15. data-export

- **Verdict**: KEEP
- **可追溯实证**: 生成数据导出/导入基础设施。工具skill，含格式支持（JSON/CSV/PDF）和GDPR合规。与元规则无冲突。
- **可验伪信号**: 若项目不使用数据导出，可能低价值。
- **下沉证明**: 动态检测数据模型层（SwiftData/Core Data/custom structs），生成匹配代码。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 16. decision-closeout

- **Verdict**: REWRITE
- **可追溯实证**: 决策变更收尾闭环。当前引用 `dependency-propagation` skill和旧protocol.md。但M-000 §5已定义用户裁决日志与Overrule机制；M-002（分歧裁决）未起草但应接管。本skill的部分功能（影响评估、下游同步）应与M-000 P8 Overrule和user-decision-log同步。当前版本假设“改文档”，但M-000强调裁决日志优先。`#005` 和 `#010` 实证了未授权决策的风险，本skill需显式包含“结构性决定须用户批准”纪律。
- **可验伪信号**: 若M-002 ratify后接管所有决策收尾，则本skill可降级为辅助工具。
- **重写要点**: (1) 引用M-000 P2/P5/P8；引用#005和#010的越权实证；(2) 去除对dependency-propagation skill的依赖（改为独立grep）；(3) 增加“结构性决定清单”（#005 I.1）；(4) 输出格式与user-decision-log对齐。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### 17. deep-linking (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 18. dependency-propagation

- **Verdict**: KEEP
- **可追溯实证**: 文档变更传播skill，基于DOC_DEPENDENCY_MAP。执行M-000 §6知识增长纪律：文档变更后下游同步。工作流包括grep引用并更新，确保一致性。无元规则冲突，可作为工具保留。
- **可验伪信号**: 若DOC_DEPENDENCY_MAP被自动化工具替代，则本skill过时。
- **下沉证明**: 需要动态grep具体引用，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### 19. dod-checklist

- **Verdict**: REWRITE
- **可追溯实证**: PR完成前DoD自检。当前checklist引用旧f-rule和“Codex对抗性审查通过”等，这些规则已被M-000/M-005替代。`#015` M-005 ratify后，质量check应引用M-005 §A判据和§G docaudit check。且DoD清单应区分代码/文档/UI子集，但当前是硬编码。trigger“检查DoD/自检”与M-000 P3默认多方异源可能冲突（不应单方自检通过）。需要REWRITE。
- **可验伪信号**: 若能证明该skill在当前项目中从未发现真实问题，则更应DELETE。
- **重写要点**: (1) 删除对所有F-规则的引用，替换为M-000 P1-P8和M-005 §A判据；(2) check项增加可追溯来源（如引用#006/#008等事故）；(3) 增加“先跑M-005 §C静默退化扫描”步骤；(4) 净化trigger，不假定单方自检。
- **元规则对齐分**: 2
- **使用频率估计**: 高

### 20. error-monitoring

- **Verdict**: KEEP
- **可追溯实证**: 生成错误监控基础设施，协议式架构（Sentry/Crashlytics可替换）。工具skill，含Conflict Detection。与元规则无冲突。
- **可验伪信号**: 若项目不使用外部监控服务，则低价值。
- **下沉证明**: 需要检测现有错误处理模式，生成适配代码。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 21. harness-recall

- **Verdict**: REWRITE
- **可追溯实证**: 自进化闭环，扫描handoff.md Risks段提出新规则。引用旧F-019和anti-pattern-scan。但M-005 §C已定义静默退化识别和§H主笔轮换机制，本skill的“三击判断”应引用M-005 §C的触发动作。当前版本没有对接M-005，且假设handoff.md格式固定。trigger包含“phase-closeout”，易造成循环依赖。`#008` 实证了自反性sanity check的价值，本skill应考虑类似复盘机制。
- **可验伪信号**: 若能证明handoff.md Risks段从未产生有用新规则，则更应DELETE。
- **重写要点**: (1) 引用M-005 §C静默退化信号和§H主笔轮换阈值；(2) 删除对F-019的引用；(3) 增加sanity check复盘步骤；(4) 净化trigger，明确不与phase-closeout循环触发。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### 22. integration-test-scaffold (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 23. keyword-optimizer

- **Verdict**: KEEP
- **可追溯实证**: ASO关键词优化工具skill，含检索现有App信息、分析关键词机会。工具skill，无元规则冲突。
- **可验伪信号**: 若App Store搜索算法变更使方法论失效，则需REWRITE。
- **下沉证明**: 需要动态查找app信息和竞品关键词，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 24. knowledge-health

- **Verdict**: REWRITE
- **可追溯实证**: 知识体系体检skill，运行docaudit全量扫描并覆盖CI盲区。当前引用软上限45/50文件规则，但M-000 §6已改为软信号（多指标）。`#015` 明确“不预设文件上限”。本skill需更新以引用M-005 §G docaudit check设计原则和M-000 §6新信号。且“不改任何文件，只产plan”符合M-000 §9目的优先（不越权）。
- **可验伪信号**: 若docaudit完全自动化且能直接修复，本skill可DELETE。
- **重写要点**: (1) 删除45/50硬上限，替换为M-000 §6软信号（Boot字符预算、incoming refs、访问频率）；(2) 引用M-005 §G docaudit check列表；(3) 增加#013实证的SSOT同步检查；(4) 更新CI盲区扫描路径。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### 25. liquid-glass (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 26. localization-setup

- **Verdict**: KEEP
- **可追溯实证**: i18n基础设施生成工具skill，支持String Catalogs、RTL。工具skill，无元规则冲突。
- **可验伪信号**: 若项目已有成熟本地化流程，可能不需要。
- **下沉证明**: 需要检测现有本地化文件和部署目标。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 27. migration-patterns

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 迁移指南（CoreData→SwiftData等），含决策树和参考文档。属于规则性知识，不是动作模板。依据M-000 §6下沉原则，应移至 `docs/standards/migration-patterns.md`。
- **可验伪信号**: 若能证明每次迁移都需要skill的决策树动态引导（而非静态阅读），则可保留为skill。但决策树可写为文档。
- **升级目标**: `docs/standards/migration-patterns.md`
- **元规则对齐分**: 3
- **使用频率估计**: 中

### 28. navigation-patterns (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 29. onboarding-generator

- **Verdict**: KEEP
- **可追溯实证**: 生成onboarding流。工具skill，含Pre-Generation Checks和Conflict Detection。与元规则无冲突。
- **可验伪信号**: 若项目已存在onboarding，则低价值。
- **下沉证明**: 动态检测现有实现，生成定制代码。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 30. phase-closeout

- **Verdict**: KEEP
- **可追溯实证**: 长任务checkpoint生成，写入handoff.md。治理skill，执行phase compact纪律（M-000 §6知识增长中的状态管理）。输出格式与M-000 §5用户裁决日志不冲突。trigger合理（phase结束≥3 PR后）。`#006` Round 1 Boot重构保留handoff.md需求，本skill是执行器。
- **可验伪信号**: 若能证明handoff.md从未被后续接手使用，则生成无意义。
- **下沉证明**: 需动态编译当前phase状态（合入PR、未决任务），不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 31. post-merge

- **Verdict**: REWRITE
- **可追溯实证**: PR合并后收尾skill，含CI检查、更新STATUS.md、anti-pattern-scan。当前引用旧F-007规则。M-000 §5已定义用户裁决日志，但post-merge的任务（如CI状态检查和状态更新）仍需要。但需更新引用，且anti-pattern-scan应引用M-005 §C静默退化。trigger“合并了/post-merge”合理。
- **可验伪信号**: 若CI完全自动执行所有步骤，则本skill可DELETE。
- **重写要点**: (1) 删除对F-007的引用；(2) 增加M-005 §C退化扫描引用；(3) 合并后更新STATUS.md的逻辑应引用M-000 §6知识增长多指标；(4) 考虑增加“检查user-decision-log是否需更新”步骤。
- **元规则对齐分**: 2
- **使用频率估计**: 高

### 32. privacy-manifests (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 33. push-notifications (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 34. resume-from-handoff

- **Verdict**: REWRITE
- **可追溯实证**: 最小上下文加载skill，定义加载顺序。当前引用旧CLAUDE.md、STATUS.md、handoff.md等，但M-000 v2.0已更新Boot为M-000 + user-decision-log（#006裁决）。本skill的Tier 1包含CLAUDE.md（已自动加载）和STATUS.md（精简为stub），但M-000 §6已定义Stub规则。需要更新以反映当前Boot结构。此外，“不强吃长transcript”符合M-000 §9目的优先，但需显式引用。
- **可验伪信号**: 若能证明Claude Code自动加载机制已足够，则本skill可DELETE。
- **重写要点**: (1) 更新加载顺序：Tier 1 = docs/meta/M-000-meta-vision.md + docs/meta/user-decision-log.md (#006)；(2) 引用M-000 §6冷启动原则；(3) 删除对旧memory/feedback.md的引用；(4) 增加#013 SSOT注入纪律提醒。
- **元规则对齐分**: 2
- **使用频率估计**: 高

### 35. review-response-writer (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 36. screenshot-planner (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 37. settings-screen

- **Verdict**: KEEP
- **可追溯实证**: 生成设置界面，工具skill。含Pre-Generation Checks检测现有实现和架构模式。与元规则无冲突。
- **可验伪信号**: 若项目已有设置界面，则低价值。
- **下沉证明**: 动态检测架构（Observable/ObservableObject）和平台，生成匹配代码。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 38. snapshot-diff-review

- **Verdict**: KEEP
- **可追溯实证**: Snapshot baseline变更审查skill。要求逐张确认视觉变化有意后再提交。这是治理skill（测试纪律），但范围较小，可视为质量门。其流程与M-005 §G docaudit check设计原则一致（每个检查有真实事故来源——baseline漂移）。trigger准确。
- **可验伪信号**: 若能证明snapshot测试在该项目从未使用，则低价值。
- **下沉证明**: 需要动态识别变更文件和使用工具diff图片，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 39. snapshot-testing

- **Verdict**: KEEP
- **可追溯实证**: 设置snapshot测试工具skill，生成boilerplate和CI配置。与元规则无冲突。
- **可验伪信号**: 若项目不使用snapshot测试，则低价值。
- **下沉证明**: 需要检测项目是否已添加swift-snapshot-testing依赖。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 40. sprint-contract

- **Verdict**: REWRITE
- **可追溯实证**: 编码前契约强制执行skill（旧F-018）。当前引用gh issue view、grep等工具，但核心逻辑（研究代码库确定Touches/No-Touch等）与M-000 P1「相同完整任务不分工」一致（确保编码前有明确范围）。但M-005 §A可追溯性要求每个规则可追溯至证据，本skill的contract内容格式应引用M-005 §A判据。此外，触发条件“feature Issue进入Building”可能过窄，M-003技能库治理应定义触发。`#014 D3` 要求主笔私下授权同步时限，与contract流程相关。当前版本未对接M-005。
- **可验伪信号**: 若能证明所有bug fix和chore都能从contract受益，则当前豁免（bug_report/trivial）可能需调整。
- **重写要点**: (1) 删除对F-018的引用；(2) 引用M-005 §A判据要求contract条目必须可追溯；(3) 增加与M-003（未起草）的衔接说明（暂时引用M-000 P1）；(4) 增加#013 SSOT注入提醒（研究阶段可能需要WebSearch）；(5) 净化trigger，不假定单方执行。
- **元规则对齐分**: 2
- **使用频率估计**: 高

### 41. swift-concurrency-pro

- **Verdict**: KEEP
- **可追溯实证**: Swift并发代码审查工具skill，含参考文件（hotspots、actors等）。第三方贡献（Paul Hudson），许可证MIT。其审查流程与M-005 §A判据精神一致（要求报告真实问题）。内容质量高，无元规则冲突。注意：该skill在.claude/skills/有完整内容，即使.agents/skills/可能也有，但当前版本是完整的。
- **可验伪信号**: 若Swift 6.3进一步简化并发，参考文件可能过时。
- **下沉证明**: 需要动态加载相关参考文件进行审查，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 42. swiftdata-pro

- **Verdict**: KEEP
- **可追溯实证**: SwiftData代码审查/编写工具skill，含参考文件。与swift-concurrency-pro同类，KEEP。
- **可验伪信号**: 同。
- **下沉证明**: 同。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 43. swiftui-debugging

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: SwiftUI性能调试指南，含决策树和参考文件（body-reevaluation.md等）。属于规则性知识，应移入standards。与animation-patterns同理。
- **可验伪信号**: 若能证明决策树需要动态适配不同iOS版本（如@Observable vs ObservableObject性能差异），则可保留为skill。但决策树可写为静态文档。
- **升级目标**: `docs/standards/swiftui-debugging.md`
- **元规则对齐分**: 3
- **使用频率估计**: 中

### 44. swiftui-pro

- **Verdict**: KEEP
- **可追溯实证**: SwiftUI代码审查工具skill，含参考文件（api.md, views.md等）。第三方贡献。KEEP。
- **可验伪信号**: 同。
- **下沉证明**: 同。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### 45. tdd-bug-fix

- **Verdict**: KEEP
- **可追溯实证**: TDD bug修复工具skill（red-green-refactor）。工具skill，无元规则冲突。其“test prevents regression”哲学与M-005 §G docaudit check真实事故来源一致。
- **可验伪信号**: 若项目完全不写测试，则低价值。
- **下沉证明**: 需要动态理解bug、编写测试、验证修复，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 46. tdd-feature

- **Verdict**: KEEP
- **可追溯实证**: TDD新功能构建工具skill。工具skill，KEEP。与tdd-bug-fix对称。
- **可验伪信号**: 同。
- **下沉证明**: 同。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 47. tdd-refactor-guard

- **Verdict**: KEEP
- **可追溯实证**: 重构前安全检查skill，确保覆盖测试存在。工具skill，与M-000 P1（先研究再生产）精神一致。KEEP。
- **可验伪信号**: 若能证明该guard从未阻止过无测试重构，则低价值。
- **下沉证明**: 需要动态检测测试覆盖，不能静态化。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 48. test-contract (adapter)

- **Verdict**: DELETE
- **可追溯实证**: adapter，同前。
- **可验伪信号**: 同。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### 49. tipkit-generator

- **Verdict**: KEEP
- **可追溯实证**: 生成TipKit基础设施工具skill。工具skill，无元规则冲突。
- **可验伪信号**: 若项目部署目标低于iOS 17，则不可用。
- **下沉证明**: 需要检测部署目标和现有TipKit使用情况。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### 50. ui-review

- **Verdict**: KEEP
- **可追溯实证**: UI/UX审查skill，参照HIG和最佳实践。工具skill，含Review Process和参考材料。与coding-best-practices类似。无元规则冲突。
- **可验伪信号**: 若审查准则过时，可能产生误导。
- **下沉证明**: 需要动态加载HIG和项目代码进行审查。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### 51. verify-audit-report

- **Verdict**: REWRITE
- **可追溯实证**: 审计报告真伪验证skill。当前引用旧F-006和F-012，以及Gemini特别纪律。M-005 §F已定义自反性sanity check和验证流程；§D定义了外部事实验证纪律。本skill的“深度验证”“全量做”等原则已被M-005吸收。需要更新引用并去除旧规则。另外，`#013` 实证了subagent报告必须grep SSOT验证，应纳入本skill。
- **可验伪信号**: 若能证明所有审计报告都由工具自动验证且无人工介入，则本skill可DELETE。
- **重写要点**: (1) 删除对F-006/F-012的引用；(2) 引用M-005 §F自反性sanity check和§D外部事实验证纪律；(3) 增加#013三层错实证的验证步骤（SSOT grep）；(4) 增加Gemini特别处置（引用#004和#013）；(5) 与cross-audit-consensus skill的功能剥离。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### 52. xcode-review

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: Xcode Review提示词写作指南。内容为规则性指导（结构、重点原则、固定收尾），不是动作模板。应移至 `docs/standards/xcode-review.md`。其“上游依赖：docs/protocol.md”也表明它是规范文档。
- **可验伪信号**: 若Xcode Review功能被替代或流程变化，则需更新。
- **升级目标**: `docs/standards/xcode-review.md`
- **元规则对齐分**: 3
- **使用频率估计**: 中

## 3. 元层级观察

### 3.1 自举循环的具体表现
本次审计发现10个治理skill（REWRITE）需要重写，因为它们的内容直接或间接引用了被M-000 v2.0/M-005 v2取代的旧规则（F-006/F-007/F-008/F-012/F-017/F-018/F-019等）。这与`#016`描述的自举循环一致：元规则起草用了这些skill，但skill本身早于元规则且未对齐。交叉引用：
- `cross-audit` 引用 F-008（被M-000 P1/P3/P5吸收）
- `dod-checklist` 引用“Codex对抗性审查”（被M-005 §B取代）
- `sprint-contract` 引用 F-018（被M-005 §A和M-000 P1覆盖）
- `verify-audit-report` 引用 F-006/F-012（被M-005 §F/§G吸收）

### 3.2 治理vs工具混同的代价
52个skill中，治理skill约10个（REWRITE） + 2个保留治理skill（api-research, phase-closeout, dependency-propagation等）共约15个。但所有skill共享相同的目录结构、trigger机制、frontmatter schema。这导致治理skill的trigger可能意外触发工具skill的上下文污染。例如 `cross-audit` 的 `Agent` 工具调用可能干扰工具skill的 `Read` 环境。M-003技能库治理应建议物理隔离治理与工具skill，或使用不同的trigger命名空间。

### 3.3 双份adapter的同步风险
13个adapter（13/52=25%）指向 `.agents/skills/`，但 `.agents/skills/` 不在本次审计范围内。这造成审计盲区：即使 `.claude/skills/` 的adapter被删除，真正的skill内容未经审计。`#016` 路径C并未覆盖 `.agents/skills/`，但Stage 7 M-003起草时应将其纳入SSOT。

### 3.4 触发器的净化漏洞
部分skill的trigger描述包含“用户说”的预设（如“用户说开工/开始编码/做这个Issue”），这些预设可能固化了交互模式，与M-000 P7“不得泄露其他方结论”虽不直接冲突，但违反了M-000 §9目的优先的精神——trigger应听命于目的而非机械关键词。例如 `sprint-contract` 的trigger对bug_report豁免，但若一个bug fix需要研究代码库，契约仍有价值。当前trigger是“feature类Issue”，这是人为分类边界，应基于风险判断。

### 3.5 第三方skill的归属
swift-concurrency-pro, swiftdata-pro, swiftui-pro 三个skill带有MIT license和外部作者（Paul Hudson）。它们被纳入项目但未经元规则审计。作为第三方内容，应检查许可证兼容性和维护责任。当前KEEP，但M-003应定义外部贡献的纳入标准。

## 4. 统计

| Verdict | 数量 | 占比 |
|---------|------|------|
| KEEP | 25 | 48.1% |
| DELETE | 13 | 25.0% |
| REWRITE | 10 | 19.2% |
| PROMOTE_TO_STANDARDS | 4 | 7.7% |
| MERGE | 0 | 0% |
| DOWNGRADE_TO_TEMPLATE | 0 | 0% |

**元规则对齐分分布**：

| 分数 | 数量 | 说明 |
|------|------|------|
| 5 | 1 | api-research |
| 4 | 25 | 所有KEEP的工具skill + phase-closeout等 |
| 3 | 4 | PROMOTE的skill |
| 2 | 10 | REWRITE的治理skill |
| 1 | 13 | DELETE的adapter |

**治理skill vs 工具skill分类**（基于是否执行元规则或质量门）：

| 类别 | 数量 | 占比 |
|------|------|------|
| 治理skill | 15 (KEEP: 3 + REWRITE: 10 + PROMOTE: 2? 准确: KEEP治理: api-research, phase-closeout, dependency-propagation (3); REWRITE治理: cross-audit, cross-audit-consensus, decision-closeout, dod-checklist, harness-recall, knowledge-health, post-merge, resume-from-handoff, sprint-contract, verify-audit-report (10); 合计13) | 25% |
| 工具skill | 39 (KEEP: 22 + PROMOTE: 4 + DELETE adapter: 13) | 75% |

注：治理skill中KEEP的3个（api-research, phase-closeout, dependency-propagation）与元规则对齐较好，但仍是治理角色。REWRITE的10个是当前自举循环的核心问题所在。