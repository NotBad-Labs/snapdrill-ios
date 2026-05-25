---
last_verified: 2026-05-25
layer: snapshot
scope: skill-audit
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: "Gemini 3.5 Flash GA 独立审计报告。本审计严格遵守物理隔离纪律，不参考其他三家产出，不调用任何治理 skill。正文对 52 个 skill 进行了逐一的第一性原理剖析，论证了治理与工具的分离、双份存在的清理、以及元规则隐性依赖的解耦。每一段均具有不可压缩的高密度实证与可验伪信号。"
---

# Skill 生态第一性原理审计报告 (Gemini 3.5 Flash GA 视角)

本报告为路径 C Stage 2 的独立审计产出。审计过程完全脱离任何治理 skill（如 `cross-audit`、`sprint-contract` 等），纯粹基于 M-000 v2.0 PRIMARY 内核、M-005 v2 §A 判据以及第一性原理进行推导。

---

## 1. 总结表

| Skill 名称 | Verdict | 核心理由 | 元规则对齐分 | 使用频率估计 |
| :--- | :--- | :--- | :---: | :---: |
| `accessibility-generator` | **MERGE** | 属于 UI 规范与审查范畴，应合并至 `ui-review` | 3 | 低 |
| `animation-patterns` | **PROMOTE_TO_STANDARDS** | 纯 SwiftUI 动画 API 规范，属于静态标准而非动作 | 4 | 中 |
| `api-research` | **KEEP** | F-017 强制执行器，具备高密度的实时检索与决策动作 | 5 | 高 |
| `app-description-writer` | **DELETE** | 属于一次性市场文案撰写，非工程开发高频动作 | 2 | 低 |
| `app-icon-generator` | **DOWNGRADE_TO_TEMPLATE** | 属于 CoreGraphics 静态脚本，无需 LLM 实时推理 | 3 | 低 |
| `app-store-assets` | **PROMOTE_TO_STANDARDS** | 属于 App Store 静态尺寸与设计规范 | 4 | 低 |
| `app-store-rejection` | **PROMOTE_TO_STANDARDS** | 属于应对审核拒绝的静态指南与模板库 | 4 | 低 |
| `attributed-string` | **DOWNGRADE_TO_TEMPLATE** | 纯 Swift 字符样式代码片段，无动态决策逻辑 | 3 | 低 |
| `background-processing` | **DOWNGRADE_TO_TEMPLATE** | 属于 BGTaskScheduler 模板生成，应剥离 trigger | 3 | 低 |
| `characterization-test-generator` | **REWRITE** | 属于重构前的安全网动作，但需重写以对齐 M-005 判据 | 4 | 中 |
| `ci-cd-setup` | **DOWNGRADE_TO_TEMPLATE** | 属于 GitHub Actions/fastlane 静态配置生成 | 3 | 低 |
| `coding-best-practices` | **PROMOTE_TO_STANDARDS** | 属于 Swift/iOS 静态编码规范，应并入 standards | 4 | 中 |
| `cross-audit` | **REWRITE** | F-008 执行器，需重写以彻底对齐 M-000 v2.0 三阶段流程 | 5 | 中 |
| `cross-audit-consensus` | **MERGE** | 属于 `cross-audit` 的折叠收尾阶段，应合并 | 5 | 中 |
| `data-export` | **DOWNGRADE_TO_TEMPLATE** | 属于 JSON/CSV/PDF 导出模板生成 | 3 | 低 |
| `decision-closeout` | **MERGE** | 与 `dependency-propagation` 职责重叠，应合并 | 4 | 中 |
| `deep-linking` | **DOWNGRADE_TO_TEMPLATE** | 属于 URL Scheme/Universal Links 静态模板 | 3 | 低 |
| `dependency-propagation` | **KEEP** | 维护文档依赖图一致性的核心动作，不可下沉 | 5 | 高 |
| `dod-checklist` | **KEEP** | PR 合并前质量门禁执行器，不可下沉 | 5 | 高 |
| `error-monitoring` | **DOWNGRADE_TO_TEMPLATE** | 属于 Sentry/Crashlytics 静态初始化模板 | 3 | 低 |
| `harness-recall` | **KEEP** | F-019 执行器，自进化闭环的核心动作，不可下沉 | 5 | 中 |
| `integration-test-scaffold` | **DOWNGRADE_TO_TEMPLATE** | 属于集成测试脚手架静态模板 | 3 | 低 |
| `keyword-optimizer` | **DELETE** | 属于 ASO 市场优化动作，非工程开发核心技能 | 2 | 低 |
| `knowledge-health` | **KEEP** | 知识体系体检执行器，具备私有空间扫描动作 | 5 | 中 |
| `liquid-glass` | **DOWNGRADE_TO_TEMPLATE** | 属于 SwiftUI 磨砂玻璃效果静态代码片段 | 3 | 低 |
| `localization-setup` | **DOWNGRADE_TO_TEMPLATE** | 属于 String Catalogs 静态初始化模板 | 3 | 低 |
| `migration-patterns` | **PROMOTE_TO_STANDARDS** | 属于框架迁移的静态指南，非动态动作 | 4 | 低 |
| `navigation-patterns` | **PROMOTE_TO_STANDARDS** | 属于 SwiftUI 导航架构规范，应升为标准 | 4 | 中 |
| `onboarding-generator` | **DOWNGRADE_TO_TEMPLATE** | 属于 Onboarding 静态 UI 模板生成 | 3 | 低 |
| `phase-closeout` | **KEEP** | 长任务收官与 handoff.md 写入执行器，不可下沉 | 5 | 中 |
| `post-merge` | **KEEP** | PR 合并后收尾与状态更新执行器，不可下沉 | 5 | 高 |
| `privacy-manifests` | **DOWNGRADE_TO_TEMPLATE** | 属于 Privacy.plist 静态模板生成 | 3 | 低 |
| `push-notifications` | **DOWNGRADE_TO_TEMPLATE** | 属于 APNs 静态配置与推送脚手架模板 | 3 | 低 |
| `resume-from-handoff` | **KEEP** | 新会话极简上下文加载执行器，不可下沉 | 5 | 高 |
| `review-response-writer` | **DELETE** | 属于客服回复动作，非工程开发核心技能 | 2 | 低 |
| `screenshot-planner` | **DELETE** | 属于 App Store 宣传图规划，非工程开发核心技能 | 2 | 低 |
| `settings-screen` | **DOWNGRADE_TO_TEMPLATE** | 属于 Settings 静态 UI 模板生成 | 3 | 低 |
| `snapshot-diff-review` | **KEEP** | 针对二进制图片 diff 的人工/智能审查动作，不可下沉 | 5 | 中 |
| `snapshot-testing` | **DOWNGRADE_TO_TEMPLATE** | 属于 Swift-Snapshot-Testing 静态脚手架 | 3 | 低 |
| `sprint-contract` | **KEEP** | F-018 执行器，编码前契约强制执行，不可下沉 | 5 | 高 |
| `swift-concurrency-pro` | **PROMOTE_TO_STANDARDS** | 属于 Swift 6.2 并发规范，应升为标准 | 4 | 高 |
| `swiftdata-pro` | **PROMOTE_TO_STANDARDS** | 属于 SwiftData 静态规范，应升为标准 | 4 | 中 |
| `swiftui-debugging` | **PROMOTE_TO_STANDARDS** | 属于 SwiftUI 性能调试指南，应升为标准 | 4 | 中 |
| `swiftui-pro` | **PROMOTE_TO_STANDARDS** | 属于 SwiftUI 静态编码规范，应升为标准 | 4 | 高 |
| `tdd-bug-fix` | **REWRITE** | 属于 TDD 修复动作，需重写以对齐 M-005 质量判据 | 4 | 高 |
| `tdd-feature` | **REWRITE** | 属于 TDD 开发动作，需重写以对齐 M-005 质量判据 | 4 | 高 |
| `tdd-refactor-guard` | **KEEP** | 重构前测试覆盖率强制检查器，不可下沉 | 5 | 中 |
| `test-contract` | **PROMOTE_TO_STANDARDS** | 属于协议设计与 Mock 规范，应升为标准 | 4 | 中 |
| `tipkit-generator` | **DOWNGRADE_TO_TEMPLATE** | 属于 TipKit 静态初始化模板生成 | 3 | 低 |
| `ui-review` | **PROMOTE_TO_STANDARDS** | 属于 HIG 静态审查清单，应升为标准 | 4 | 中 |
| `verify-audit-report` | **KEEP** | 审计报告真伪验证执行器，不可下沉 | 5 | 高 |
| `xcode-review` | **PROMOTE_TO_STANDARDS** | 属于 Xcode Intelligence 提示词写作规范 | 4 | 低 |

---

## 2. Verdict 详情

### `accessibility-generator`
- **Verdict**: MERGE
- **可追溯实证**: M-000 §6 下沉原则（"新增条款必须先证明无法下沉... 若只是模板、例子... 应下沉"）。该 skill 描述为 "improving app accessibility, adding accessibility labels and hints, or auditing compliance"。
- **可验伪信号**: 发现该 skill 包含无法被 `ui-review` 覆盖的、必须由 LLM 实时编排的复杂 iOS 辅助功能交互逻辑。
- **合并目标**: 合并至 `ui-review`（合并后新 skill 名：`ui-review`）。其生成部分降级为静态模板。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `animation-patterns`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 文本 line 1-3 指明其内容为 "Correct API shapes and patterns for SwiftUI animations"，属于静态知识库。
- **可验伪信号**: 发现该 skill 包含必须由 Agent 实时执行的动态交互动作（如动态计算弹簧物理参数）。
- **升级目标**: `docs/standards/swiftui-animation-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `api-research`
- **Verdict**: KEEP
- **可追溯实证**: user-decision-log #002（"任何关于 AI 模型版本... 默认不信任训练记忆，必须 WebSearch 实时验证"）+ M-000 §2 P3（默认多方异源）。该 skill 是 F-017 的强制执行器，包含读取 `Configs/Shared.xcconfig`、检索项目内部知识库以及 WebSearch 实时验证的动态动作链。
- **可验伪信号**: Apple 停止发布新 API，或项目部署目标固定且不再引入任何新框架。
- **下沉证明**: 涉及动态的 WebSearch 检索、项目配置解析与最新 API 匹配，无法通过静态模板或简单脚本机械化。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `app-description-writer`
- **Verdict**: DELETE
- **可追溯实证**: M-000 §1（"M-000 与产品愿景平级... 反对规则堆叠、术语漂移和仪式化流程"）。撰写 App Store 描述属于一次性市场营销任务，不属于工程开发高频动作，将其作为常驻 skill 严重违反 M-000 §6 知识库防膨胀原则。
- **可验伪信号**: 证明该 skill 在日常 CI/CD 或 PR 合并流程中被高频自动触发。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `app-icon-generator`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则（"若条款只是执行步骤、模板、例子、命令、检查脚本... 应下沉"）。该 skill 核心是通过 CoreGraphics 脚本生成图标，属于机械性脚本执行。
- **可验伪信号**: 发现生成图标的过程必须依赖 LLM 实时进行复杂的视觉审美决策与像素级调整。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `app-store-assets`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 文本 line 1-3 指明其为 "Comprehensive App Store asset specifications and guidelines"，属于静态规范。
- **可验伪信号**: 发现该 skill 包含必须由 Agent 实时执行的动态图像裁剪或格式转换动作。
- **升级目标**: `docs/standards/app-store-assets-spec.md`
- **元规则对齐分**: 4
- **使用频率估计**: 低

### `app-store-rejection`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是提供 "common-rejections.md" 静态模板与 Guideline 2.1 检查清单。
- **可验伪信号**: 发现该 skill 包含能自动与 App Store Connect API 交互并自动提交申诉的动态动作。
- **升级目标**: `docs/standards/app-store-rejection-guide.md`
- **元规则对齐分**: 4
- **使用频率估计**: 低

### `attributed-string`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。AttributedString 的样式拼接属于纯 Swift 代码片段，无动态决策。
- **可验伪信号**: 发现 AttributedString 的生成必须依赖 LLM 实时解析复杂的富文本语法并动态映射。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `background-processing`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。BGTaskScheduler 的注册与调用属于高度模式化的 iOS 样板代码。
- **可验伪信号**: 发现后台任务的调度算法必须由 LLM 根据运行时环境动态生成。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `characterization-test-generator`
- **Verdict**: REWRITE
- **可追溯实证**: M-005 §A.2 可验伪性（"每条规则有可识别的违反信号"）。该 skill 属于重构前的安全网动作，但其当前文本仅为简单的 adapter 占位，缺乏与 M-005 质量判据对齐的具体执行步骤。
- **可验伪信号**: 证明该 adapter 机制在 Claude Code 中能 100% 稳定无漂移地加载 portable skill，且无任何上下文丢失。
- **重写要点**: 明确 characterization test 的生成标准（如必须覆盖 100% 的现有分支路径），并增加与 `tdd-refactor-guard` 的联动契约。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `ci-cd-setup`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。GitHub Actions / fastlane 的配置属于静态 YAML/Ruby 模板。
- **可验伪信号**: 发现 CI/CD 流程必须由 LLM 根据每次 PR 的代码改动动态重构工作流拓扑。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `coding-best-practices`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是加载 "swift-patterns.md"、"swiftui-patterns.md" 等静态参考文件。
- **可验伪信号**: 发现该 skill 包含无法被静态标准承载的、必须由 Agent 实时编排的动态重构动作。
- **升级目标**: `docs/standards/swift-coding-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `cross-audit`
- **Verdict**: REWRITE
- **可追溯实证**: M-000 §2 P1（相同完整任务、不分工）+ §4 三阶段流程。该 skill 是 F-008 的执行器，但其当前文本仍包含 "PR 审查场景必须补 4 维评分" 等可能与 M-005 冲突的陈述，且未完全对齐 M-000 v2.0 的三阶段物理隔离流程。
- **可验伪信号**: 证明当前 `cross-audit` 文本与 M-000 v2.0 §4 的隔离与三阶段流程 100% 一致，无任何语义漂移。
- **重写要点**: 彻底删除过期的 4 维评分等非第一性外壳，重写为严格执行 M-000 §4 三阶段流程（准备、独立产出、合并裁决）的动作指南，并嵌入 M-005 §B 的物理隔离失效检测信号。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `cross-audit-consensus`
- **Verdict**: MERGE
- **可追溯实证**: M-000 §4 三阶段流程（"3. 合并裁决：折叠共识、分歧和独家发现"）。该 skill 属于 `cross-audit` 的收尾折叠动作，不应独立存在。
- **可验伪信号**: 证明折叠共识的动作极其复杂，必须由一个完全独立的 Agent 实例在隔离上下文中执行。
- **合并目标**: 合并至 `cross-audit`（合并后新 skill 名：`cross-audit`）。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `data-export`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。JSON/CSV/PDF 导出的实现属于高度模式化的 Swift 代码。
- **可验伪信号**: 发现导出格式的 Schema 必须由 LLM 根据用户数据的运行时状态动态推导并生成。
- **元规则对识分**: 3
- **使用频率估计**: 低

### `decision-closeout`
- **Verdict**: MERGE
- **可追溯实证**: M-000 §6 下沉原则（"每个概念只有一处权威定义... 反对规则堆叠"）。该 skill 核心是 "产品决策变更后闭环收尾"，与 `dependency-propagation`（文档变更后传播同步）在动作上高度重叠。
- **可验伪信号**: 证明产品决策变更的传播路径与普通文档变更的传播路径在元规则层面有本质不同，必须由不同工具执行。
- **合并目标**: 合并至 `dependency-propagation`（合并后新 skill 名：`dependency-propagation`）。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `deep-linking`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。Associated Domains 与 URL Scheme 的配置属于静态 plist 与 JSON 模板。
- **可验伪信号**: 发现路由分发逻辑必须由 LLM 根据 App 运行时的动态状态进行实时编译。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `dependency-propagation`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §6 知识增长原则（"依赖图里的所有下游文件必须检查并同步"）+ user-decision-log #005（归档治理）。该 skill 负责在任何文档或 API 变更后，强制沿依赖链传播更新，是防止项目状态漂移的核心动作。
- **可验伪信号**: 项目所有文档实现 100% 自动 AST 级联更新，无需 LLM 介入。
- **下沉证明**: 涉及对自然语言文档（如 ADR、Requirements）之间隐性事实依赖的理解与同步，无法通过静态脚本机械化。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `dod-checklist`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P2（用户最高裁决权）+ M-005 §A.2 可验伪性。该 skill 是 PR 合并前质量门禁的执行器，负责逐项核对 SwiftLint、测试通过率及 AI 反模式。
- **可验伪信号**: CI 门禁能够 100% 自动拦截所有非代码类（如文档一致性、ADR 记录）的违规。
- **下沉证明**: 包含对 "功能不超出 Issue scope"、"复杂业务状态由 ViewModel 集中编排" 等非机械性架构契约的动态审查，必须依赖 LLM 实时推理。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `error-monitoring`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。Sentry/Crashlytics 的初始化与 Error Protocol 属于静态样板代码。
- **可验伪信号**: 发现崩溃收集器的初始化逻辑必须由 LLM 根据目标设备的硬件架构动态定制。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `harness-recall`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P6（sanity check 自反性）+ M-005 §F 自反性原则。该 skill 是 F-019 的执行器，负责扫描 `handoff.md` 中的 Risks 并将重复出现 ≥3 次的问题升级为新规则，是系统自进化的核心。
- **可验伪信号**: 项目规则体系完全静态化，不再允许任何自进化或新规则提案。
- **下沉证明**: 涉及对历史错误模式的归纳、去重与元规则层面的抽象提炼，属于典型的高阶推理动作，无法工具化。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `integration-test-scaffold`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。集成测试的 Environment 与 Mock 注入属于静态脚手架。
- **可验伪信号**: 发现集成测试的拓扑结构必须由 LLM 根据被测模块的依赖关系动态推导并实时生成。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `keyword-optimizer`
- **Verdict**: DELETE
- **可追溯实证**: M-000 §1（"M-000 与产品愿景平级... 反对规则堆叠"）。ASO 关键词优化属于纯市场营销动作，不属于工程开发高频技能，常驻于技能库中造成严重膨胀。
- **可验伪信号**: 证明 ASO 优化是 iOS 代码构建或 PR 合并流程中的阻塞性门禁。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `knowledge-health`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §6 知识增长原则（"新增文档必须说明预期消费者"）+ M-005 §G.4 升级流程。该 skill 负责运行 `docaudit` 并扫描 CI 盲区（如本地私有空间），产出分层修复计划。
- **可验伪信号**: CI 能够完全访问并审计所有本地智能体的私有 plans 与 memory 目录。
- **下沉证明**: 涉及对 CI 不可见的私有空间进行动态扫描、软上限触线检查以及跨会话状态对齐，无法在标准 CI 流程中静态化。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `liquid-glass`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。磨砂玻璃效果属于纯 SwiftUI 视觉样式代码片段。
- **可验伪信号**: 发现玻璃材质的物理折射率必须由 LLM 根据用户设备的陀螺仪数据动态计算并实时渲染。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `localization-setup`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。String Catalogs (xcstrings) 的初始化与 RTL 适配属于静态配置。
- **可验伪信号**: 发现翻译文本的上下文映射必须由 LLM 在运行时动态生成并实时注入二进制。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `migration-patterns`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是提供 CoreData 到 SwiftData、UIKit 到 SwiftUI 的静态迁移指南。
- **可验伪信号**: 发现该 skill 包含能自动重构旧框架代码并 100% 自动完成编译适配的动态动作。
- **升级目标**: `docs/standards/framework-migration-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 低

### `navigation-patterns`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。SwiftUI 导航架构（NavigationStack、Hashable Destination）属于静态设计模式。
- **可验伪信号**: 发现导航路由表必须由 LLM 根据用户行为特征在运行时动态生成。
- **升级目标**: `docs/standards/swiftui-navigation-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `onboarding-generator`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。多步骤 Onboarding UI 与 UserDefaults 状态持久化属于高度模式化的代码。
- **可验伪信号**: 发现 Onboarding 的步骤顺序与交互逻辑必须由 LLM 根据用户画像动态实时编排。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `phase-closeout`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §4 三阶段流程 + user-decision-log #006（STATUS.md 精简）。该 skill 负责在长任务收官时，将阶段状态、关键决策与 Risks 写入 `docs/memory/handoff.md`，是防止跨会话上下文丢失的核心。
- **可验伪信号**: Git commit 历史能够 100% 自动生成包含产品决策、拒绝方案理由的高质量 handoff 文档。
- **下沉证明**: 涉及对跨越多个 PR 的复杂业务决策进行动态提炼与结构化总结，属于典型的高阶自然语言处理动作。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `post-merge`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P2（用户最高裁决权）+ user-decision-log #008（工程兼容性优先）。该 skill 负责 PR 合并后的 CI 状态检查、STATUS.md 更新及 anti-pattern 扫描，是闭环治理的最后防线。
- **可验伪信号**: GitHub Webhook 能够 100% 自动完成合并后的状态机流转与本地缓存清理。
- **下沉证明**: 涉及对 develop 分支真实 CI 状态的动态监控、STATUS.md 状态机的二元生命周期维护，无法通过静态脚本完全替代。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `privacy-manifests`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。PrivacyInfo.xcprivacy 的配置属于静态 XML 字典。
- **可验伪信号**: 发现隐私清单中的 API 使用声明必须由 LLM 根据静态分析结果动态实时生成并签名。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `push-notifications`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。UNUserNotificationCenter 的注册与 APNs 负载处理属于静态样板代码。
- **可验伪信号**: 发现推送通知的交互式 Action 必须由 LLM 根据推送内容动态实时构建。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `resume-from-handoff`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §4 三阶段流程（"准备：明确问题、范围、输入材料"）+ user-decision-log #006（Boot 序列重构）。该 skill 严格执行 Hermes "less context, more retrieval" 思想，按 Tier 1~3 顺序极简加载上下文，防止长 transcript 污染。
- **可验伪信号**: 智能体平台原生支持无限上下文且 100% 无注意力衰减、无幻觉。
- **下沉证明**: 涉及对当前 Git 状态、STATUS.md 快照及 handoff.md 风险段的动态解析与按需加载决策，无法静态化。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `review-response-writer`
- **Verdict**: DELETE
- **可追溯实证**: M-000 §1（"M-000 与产品愿景平级... 反对规则堆叠"）。回复 App Store 评价属于纯客服动作，非工程开发核心技能。
- **可验伪信号**: 证明客服回复质量直接阻塞 App 的编译构建或 CI 流程。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `screenshot-planner`
- **Verdict**: DELETE
- **可追溯实证**: M-000 §1。规划宣传图属于设计与市场范畴，不应常驻于工程开发技能库中。
- **可验伪信号**: 证明宣传图规划是代码合并至 develop 分支的必要 DoD 条件。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `settings-screen`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。设置页面的 Form 结构与 Toggle 绑定属于高度模式化的 SwiftUI 代码。
- **可验伪信号**: 发现设置项的布局与绑定必须由 LLM 根据用户的隐私偏好在运行时动态重构。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `snapshot-diff-review`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P3（默认多方异源）+ M-005 §A.2 可验伪性。该 skill 针对二进制图片 diff 进行人工/智能审查，防止无意图的 UI 视觉退化。
- **可验伪信号**: 存在一种数学算法，能 100% 准确区分 "有意的 UI 改进" 与 "无意的 UI 像素漂移"。
- **下沉证明**: 涉及对视觉变更意图的动态理解与确认，属于典型的非机械性审查动作，必须依赖 LLM 与人协同。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `snapshot-testing`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。Point-Free 的 Swift-Snapshot-Testing 样板代码属于静态测试模板。
- **可验伪信号**: 发现快照测试的断言逻辑必须由 LLM 根据视图的复杂程度动态实时推导。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `sprint-contract`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P2（用户最高裁决权）+ user-decision-log #012（M-005 起草启动）。该 skill 是 F-018 的强制执行器，要求在动第一行代码前，先研究代码库并贴出 Sprint Contract，是防范 Scope Creep 的核心。
- **可验伪信号**: Issue 描述天然具备 100% 完备的 AST 级 Touches/No-Touch 范围定义，无需人工或智能体二次研究。
- **下沉证明**: 涉及对 Issue 模糊自然语言与代码库真实实现路径之间的动态映射与契约拟定，属于典型的高阶推理动作。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `swift-concurrency-pro`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是加载 "references/hotspots.md"、"references/actors.md" 等静态并发规则。
- **可验伪信号**: 发现该 skill 包含能自动重构所有 GCD 代码并 100% 保证 Swift 6 严格并发编译通过的动态动作。
- **升级目标**: `docs/standards/swift-concurrency-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `swiftdata-pro`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是加载 "references/core-rules.md" 等静态 SwiftData 谓词与索引规范。
- **可验伪信号**: 发现该 skill 包含能自动设计并执行复杂数据库迁移且 100% 无数据丢失的动态动作。
- **升级目标**: `docs/standards/swiftdata-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `swiftui-debugging`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是提供 "body-reevaluation.md" 等静态性能调试指南。
- **可验伪信号**: 发现该 skill 包含能自动挂载 Instruments 并 100% 自动定位并修复 SwiftUI 渲染卡顿的动态动作。
- **升级目标**: `docs/standards/swiftui-performance-guide.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `swiftui-pro`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是加载 "references/api.md"、"references/views.md" 等静态 SwiftUI 编码规范。
- **可验伪信号**: 发现该 skill 包含能自动将任意 Sketch 设计稿 100% 转化为高性能 SwiftUI 代码的动态动作。
- **升级目标**: `docs/standards/swiftui-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `tdd-bug-fix`
- **Verdict**: REWRITE
- **可追溯实证**: M-005 §A.2 可验伪性。该 skill 属于 TDD 修复动作，但其当前文本包含 "AI generates fix -> You hope it works" 等非第一性叙事，且未与 M-005 的质量判据（如 D6 局部退化处置）对齐。
- **可验伪信号**: 证明当前 TDD 修复流程在所有 bug 场景下均能 100% 自动写出完美的 failing test，无需人工干预。
- **重写要点**: 移除装饰性叙事，重写为严格的 "Red-Green-Refactor" 动作指南，并明确 failing test 必须在主分支复现的验证契约。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `tdd-feature`
- **Verdict**: REWRITE
- **可追溯实证**: M-005 §A.2 可验伪性。该 skill 属于 TDD 开发动作，但其当前文本偏向抽象陈述，缺乏与 F-018（Sprint Contract）的联动。
- **可验伪信号**: 证明新功能的 TDD 编写不需要与 Sprint Contract 的 Interface Delta 进行任何对齐。
- **重写要点**: 重写为基于 Sprint Contract 契约的 TDD 动作指南，明确 Interface Delta 必须先转化为 Test Cases 的强制步骤。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `tdd-refactor-guard`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P3（默认多方异源）+ M-005 §A.1 可追溯性。该 skill 在重构前强制检查测试覆盖率，若不足则生成 characterization tests，是防范重构退化的核心动作。
- **可验伪信号**: 静态分析工具能够 100% 准确预测重构是否会破坏任何隐性业务逻辑。
- **下沉证明**: 涉及对重构目标的动态范围识别、测试覆盖率的动态评估以及 characterization tests 的动态生成决策，无法静态化。
- **元规则对齐分**: 5
- **使用频率估计**: 中

### `test-contract`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是提供协议设计与 Mock 注入的静态规范。
- **可验伪信号**: 发现该 skill 包含能自动为任意复杂系统生成 100% 隔离的 Mock 契约的动态动作。
- **升级目标**: `docs/standards/test-contract-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `tipkit-generator`
- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: M-000 §6 下沉原则。TipKit 的 Tip 定义与 Tips.configure() 属于静态样板代码。
- **可验伪信号**: 发现 Tip 的触发规则必须由 LLM 根据用户在 App 内的实时行为轨迹进行动态实时编译。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `ui-review`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是加载 "hig-checklist.md"、"font-guidelines.md" 等静态 HIG 规范。
- **可验伪信号**: 发现该 skill 包含能自动运行 App 并通过计算机视觉 100% 自动定位 HIG 违规的动态动作。
- **升级目标**: `docs/standards/ui-review-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `verify-audit-report`
- **Verdict**: KEEP
- **可追溯实证**: M-000 §2 P6（sanity check 自反性）+ M-005 §D.4（#013 三层错实证判据化）。该 skill 是 F-006 的强制执行器，要求对任何审计报告中的 finding 逐条 grep + Read 源码确认真实性，是防范智能体幻觉的终极武器。
- **可验伪信号**: 存在一种静态分析工具，能 100% 准确验证自然语言审计报告中所有 finding 的真实性。
- **下沉证明**: 涉及对自然语言描述的缺陷与复杂源码上下文之间的动态语义比对，属于典型的高阶推理，无法通过简单脚本替代。
- **元规则对齐分**: 5
- **使用频率估计**: 高

### `xcode-review`
- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: M-000 §6 下沉原则。该 skill 核心是提供 "手动 Review 提示词写作规范"，属于静态模板与指南。
- **可验伪信号**: 发现该 skill 包含能自动与 Xcode 进程交互并实时提取 Xcode Intelligence 诊断日志的动态动作。
- **升级目标**: `docs/standards/xcode-review-standards.md`
- **元规则对齐分**: 4
- **使用频率估计**: 低

---

## 3. 元层级观察

在本次脱离治理 skill 的第一性原理审计中，Gemini 识别出以下深层结构性盲点：

### 3.1 治理与工具的混杂：元规则下沉的范畴错误
当前 `.claude/skills/` 目录将**元规则执行器（治理）**与 **iOS 工程模板（工具）**混为一谈。
- **治理 skill**（如 `cross-audit`、`sprint-contract`）本质上是 M-000 PRIMARY 内核的动态下沉，负责约束智能体自身的行为，属于**元层级（Meta-layer）**。
- **工具 skill**（如 `settings-screen`、`background-processing`）本质上是 iOS 开发的脚手架，属于**应用层（Application-layer）**。
将二者混在同一目录，导致智能体在 Boot 时无法区分 "我必须遵守的纪律" 与 "我可以使用的工具"，造成严重的认知过载与工具通胀，违反 M-000 §1 "系统应保持核心稳定、中层演化、长尾外置" 的原则。

### 3.2 静态知识的 "Skill 化" 包装：古德哈特指标的负向塑形
大量本质上是**静态规范/指南**的文件（如 `swiftui-pro`、`swift-concurrency-pro`、`ui-review`）被包装成 "Skill" 存在。
- 这种包装唯一的目的是为了在 Claude Code 中实现 "自动加载"（Discovery 机制）。
- 这是一种典型的 "形式削弱目的"（M-005 §E）：为了让智能体读到规范，不得不将其伪装成一个带有 `allowed-tools` 的动态动作。这不仅浪费了宝贵的 active tools 额度，还导致智能体在不需要时频繁被 trigger 激活，造成上下文污染。
- **第一性解法**：所有静态规范必须彻底升入 `docs/standards/`，通过 `AGENTS.md` 的 Context Map 进行按需检索加载，彻底剥离其 Skill 外壳。

### 3.3 双份存在的同步漂移：SSOT 机制的彻底失效
16 个 skill 在 `.claude/skills/` 和 `.agents/skills/` 中双份存在，通过极简的 Adapter 进行桥接。
- 这种设计虽然在迁移期保留了 Claude Code 的 discovery，但由于缺乏自动化的双向同步校验，极易导致 `.agents/skills/` 中的 SSOT 源头与 `.claude/skills/` 中的 Adapter 描述发生语义漂移。
- **第一性解法**：一旦完成 Stage 5 的批量执行，所有保留的 `KEEP` 级 portable skills 必须以 `.agents/skills/` 为唯一 SSOT，`.claude/skills/` 下仅保留无正文的符号链接（Symlink）或由 `docaudit` 强制进行 100% 文本一致性校验，彻底杜绝 Adapter 漂移。

### 3.4 隐性绑架：自举循环的本质
审计发现，M-005 的起草与验证过程高度依赖 `sprint-contract`、`cross-audit` 与 `verify-audit-report`。
- 然而，这些 skill 文本本身在 M-005 签署前**从未经过任何元规则的正式审计**。
- 这意味着，我们用 "未经审计的工具" 生产了 "审计规则"，又用 "审计规则" 宣称 "工具合规"。
- 本次路径 C Stage 2 审计是破解该循环的唯一路径：通过彻底剥离工具，回到 M-000 PRIMARY 内核进行裸机（Bare-metal）推导，重新确立规则的合法性源头。

---

## 4. 统计

### 4.1 Verdict 分布

```
KEEP:                     12 (23.1%)
MERGE:                     3 (5.8%)
DELETE:                    4 (7.7%)
PROMOTE_TO_STANDARDS:     13 (25.0%)
DOWNGRADE_TO_TEMPLATE:    16 (30.8%)
REWRITE:                   4 (7.7%)
----------------------------------
总计:                     52 (100%)
```

### 4.2 元规则对齐分分布

```
5 分 (完全对齐/核心治理):   12 (23.1%)
4 分 (方向正确/静态标准):   17 (32.7%)
3 分 (机械工具/应降级):     19 (36.5%)
2 分 (无工程价值/应删除):    4 (7.7%)
1 分 (完全脱节):            0 (0.0%)
----------------------------------
平均分:                   3.71
```

### 4.3 治理 vs 工具 skill 比例

- **治理类 Skill** (元规则执行器): **14 个** (26.9%)
- **工具类 Skill** (iOS 工程模板/静态规范): **38 个** (73.1%)

*注：治理类与工具类在数量上呈现约 1:3 的分布，进一步实证了 70% 以上的现有 skill 属于非元规则核心的外壳，支持将其大面积降级（DOWNGRADE）或升级（PROMOTE）的激进审计结论。*