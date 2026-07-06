# 三路协作边界与交接协议

> 当前版本：2026-06-26。适用于 Codex Desktop、Claude Code 与 Antigravity 并行协作。
> 目标是减少文件冲突与认知摩擦，不建立额外管理层。PO 对产品意图和争议拥有最终裁决权。

## 1. 共同真相源

不同问题使用不同裁决链：

- **产品意图**：PO 最新明确意图 > `vision.md` > 产品政策 / ADR > feature spec > 实现。
- **实现事实**：代码、测试、构建与运行实证 > 自动生成状态 > 当前说明文档 > 私有记忆和历史材料。

代码不能覆盖产品意图；它只能证明当前实现。两条链冲突时，由对应 lane 记录偏差，产品语义交 PO，技术实现由 Claude 收口，UI 表现由 Codex 收口。

私有记忆只是可丢弃缓存。任何会影响其他 lane 的结论必须进入 git-tracked SSOT、代码、测试或 commit，不能只留在某个 agent 会话中。

## 2. Lane 所有权

### Codex Desktop：UI 设计与 UI 实现

拥有：

- `Packages/SnapDrillUI/`
- `Packages/SnapDrillFeatures/**/**View.swift`
- UI snapshot / XCUITest 中与视觉和交互表现直接相关的文件
- `SnapDrill/App/AppRootView.swift`、`SnapDrill/App/AppRouter.swift` 的导航外观与视觉壳
- `docs/ui-redesign/`

不拥有：

- 任何 `*ViewModel.swift`
- Core/Data、Repository、DataExecutor、`@Model`
- CI、签名、pbxproj、Package lockfile
- 保存编排、错误恢复、通知监听、筛选/分页算法等非视觉业务逻辑

Codex 可以从实际交互中审计跨层问题，但只记录契约、复现与建议；实现交给对应 lane。UI 设计决策由 Codex 与 PO 决定，Claude 不代理设计。

### Claude Code：工程与集成

拥有：

- `Packages/SnapDrillCore/`
- `Packages/SnapDrillData/`
- `Packages/SnapDrillFeatures/**/*ViewModel.swift`
- Feature 内非视觉服务、解析、导出编排与状态机
- `SnapDrill/App/` 的 composition root、依赖装配与生命周期逻辑
- `.github/`、`Scripts/`、签名/构建配置、`project.pbxproj`、`Package.resolved`
- Core/Data/ViewModel 测试与最终集成闸

Claude 是工程集成与发布就绪协调 DRI：负责跨层技术归属、构建可行性、依赖顺序和发布工程闭环。该职责不构成对 Codex 的设计管理权；Claude 不修改 Codex 与 PO 已确定的 UI 视觉方案。跨层修复需要新增 UI 接口时，先定义最小契约并在共享文档记录，再由 Codex 接入 View。

### Antigravity：官网、运营与合规文案

拥有：

- 官网仓库内容与页面
- App Store 元数据、ASO、运营材料、合规文案草案
- 本仓库中明确分配的文档与追溯日志

Antigravity 不修改 Swift 业务逻辑。法律结论必须标注来源与是否需律师确认；产品定位文案必须服从 PO 已决策的 general-audience 效率工具定位。发布后由 Antigravity 汇总支持渠道、TestFlight 和 App Store 的用户反馈，先做事实分类，不代替 PO 判断产品优先级。

## 3. 结果责任（唯一 DRI）

文件所有权用于避免冲突，DRI 用于确保结果有人收口。多人可以参与，每项结果只有一个最终 DRI：

| 结果领域 | 最终 DRI | 参与与边界 |
|---|---|---|
| 产品意图、优先级、商业与法律风险 | PO | Agent 提供证据与方案，不替 PO 决策 |
| UI、交互、设计系统、无障碍、本地化最终呈现 | Codex | Antigravity 提供措辞，Claude 集成资源；截断、布局和交互体验由 Codex 收口 |
| 工程集成、架构可行性、依赖、CI、发布就绪 | Claude | Claude 可裁决技术归属与集成顺序，但不能覆盖 Codex 的视觉决定 |
| 公开文案、ASO、官网与反馈初筛 | Antigravity | 产品优先级仍由 PO 决定 |
| 真机产品验收与正式发布授权 | PO | Claude 汇总发布就绪状态，PO 作最终 go/no-go |
| 技术监控、性能与线上技术事故分诊 | Claude | 使用 MetricKit、Xcode Organizer 与 App Store Connect，不恢复第三方遥测 |
| 安全/隐私事件的对外处置与风险取舍 | PO | Claude 提供技术事实，Antigravity 提供公开措辞，必要时律师给法律意见 |

跨层 Feature 默认由 Claude 承担工程集成 DRI，确保各层能共同构建和通过测试；Codex 仍对其最终 UI 体验负责。涉及产品语义的分歧必须交 PO。

### 总规划 / 本地实证模型

在 PO 明确授权的复杂阶段，Claude 可以承担总规划 / 架构规划 DRI，Codex 承担本地实现、验证与整合 DRI。该模型是 §3 与 §5 的细化，不改变共同真相源：

- PO 仍是产品方向、体验取舍、默认行为、命名语义、发布授权和风险取舍的最终裁决者。
- Claude 的规划职责是划分阶段、边界、依赖顺序、合同、风险和 PO 决策点；规划必须给 scope / no-go、owner、验证方式和 path:line 证据，并区分 `FACT` / `JUDGMENT` / `PENDING-PO`。
- Codex 的本地职责是用 live repo 审查规划，执行 bounded slice，跑验证并提交；Codex 不因 Claude 规划而跳过 DoR、T0-T4 或本地证据。
- 在“当前实现是什么”的问题上，live code、测试、构建、真机/模拟器证据高于任何规划文本或 agent 记忆。
- Claude 不是 code-truth arbiter，不是 merge / execution authority，也不代理 PO 的产品裁决或 Codex + PO 已定的 UI 视觉判断。
- Codex 可以挑战 Claude，但挑战必须绑定证据；纯偏好或空泛反驳不改变规划。
- 执行任何跨 agent 规划或合并前，先做 T0 对账：确认目标分支 / HEAD / dirty files、已合并与未合并工作、规划引用的 live path:line 是否仍成立；对账结果写入任务 brief、PR 描述或对应 report，不新增并行状态 SSOT。

Codex 挑战 Claude 的有效触发包括：

- Claude 描述与 live code、测试、构建或真机证据不一致。
- Claude 使用过期上下文、旧分支、旧报告或未验证的 agent 记忆。
- Claude 把合法历史、guardrail、negation 或 legal/fact-gated 内容当成腐烂内容。
- Claude 规划越过 lane 边界，例如直接裁决 UI/产品体验或要求无授权实现。
- Claude 计划缺少 scope、no-go、owner、验证方式、证据或 PO 决策点。
- Claude 计划过重、过宽、不可验证，或引入 speculative abstraction。
- 规划存在明显 feasibility gap，无法在当前工具链、签名、CI、设备或时间 appetite 内完成。

全局架构 / 生命周期规划只能作为 shaping input：它应产出候选阶段、依赖、风险和 bounded slices，随后仍需 Codex 本地实证审查与 PO 拍板，不能自动成为固定 roadmap 或当前 bet。

规划文档还必须周期性对账保鲜：每当一条工作链闭合（相关 slices 合并进 `develop`）、选择下一个 bounded slice 之前，Claude 对现行全局规划做一次有界 freshness 对账，内容限于：已落地项标记（挂 PR / commit）、load-bearing 锚点对 live `develop` 的漂移核查、风险清单重排、候选 slices 刷新、PO 决策队列变化。产出为日期化 checkpoint 报告，按 §5 报告字段要求写入仓库外规划产物目录；不修改原规划文件，不新增并行状态 SSOT，feature 级状态权威仍是生成的 `feature-status.md`。

## 4. 共享接缝

以下改动不是某个 lane 可静默完成的局部改动：

| 接缝 | 主责 | 协作要求 |
|---|---|---|
| Core service / DTO / Notification name | Claude | 改前记录消费者；改后提供签名、迁移说明与验证结果 |
| Feature public View init / Environment key | Codex | 改前 grep 所有调用点并通知 Claude；由拥有调用文件的 lane 接入 |
| View 与 ViewModel 状态契约 | Claude（工程收口） | Codex 表达 UI 所需状态/动作并验交互；Claude 负责并发、时序和副作用；产品语义分歧交 PO |
| 打印/分享系统呈现 | Core 产物由 Claude，UIKit/SwiftUI presentation adapter 由 Codex | 当前契约见 `docs/ui-redesign/flagship-cross-layer-contracts.md` |
| 本地化文案 | Codex（最终呈现） | 产品含义由 PO，公开/合规措辞由 Antigravity，资源集成由 Claude；截断、Dynamic Type 和布局由 Codex 验收 |
| 隐私声明与代码行为一致性 | Claude（技术事实） | Claude 核对依赖、数据流与 Privacy Manifest；Antigravity据此维护公开政策；法律充分性与风险取舍归 PO/律师 |
| 用户反馈闭环 | Antigravity（收集初筛） | Antigravity 汇总事实，PO 定优先级，Claude/Codex 分别完成工程与体验分析和实现 |
| `project.pbxproj` / lockfile / target membership | Claude | 其他 lane 只提交需求，不并行编辑这些高冲突文件 |

冻结集的成员与数量必须从 live code grep，不凭记忆。2026-06-11 实证锚点：

- `ServiceContainer`：14 个属性，含 `metricService`
- SwiftData `@Model`：`ArchiveItemModel` / `CategoryDimensionModel` / `CategoryValueModel`
- Library public View：`CategoryManagerView` / `LibraryEditView` / `LibraryView` / `SFSymbolPickerView`
- SPM package：Core / Data / Features / UI，共 4 个；Features 内含 5 个 feature target

## 5. 交接方式

Agents 不会自动读取彼此的私有会话。默认交接通过共享仓库中的文档、commit hash、测试结果和 GitHub 事实完成；只有 PO 明确授权时，Codex 才可以编排 Claude / Gemini / Grok / Antigravity 等外部 agent 做候选实现或交叉审查。

当前规则：

- Claude 不主动调用 Codex CLI、ChatGPT 或 Codex 插件；Claude 负责自己 lane 的工程实现与验证。
- Codex 可以在 PO 授权下向外部 agent 发出明确 prompt，但外部 agent 的结论只是候选证据，不是项目真相。
- 外部 agent 产物必须回落到 git-tracked 文档、代码、测试、PR 评论或可复现命令输出，不能只留在某个 agent 会话中。
- PO 不需要人工复制完整上下文；只需在需要启动另一 lane、授权 GitHub 写操作或作产品裁决时通知。
- 跨层发现写入拥有明确路径的文档，例如 `docs/ui-redesign/REDESIGN-LOG.md` 或专项 contract。
- handoff 至少包含：问题、复现、责任层、所需契约、不可触碰边界、验证方式。
- 发现者不负责替所属层修复，但 Claude 作为工程集成 DRI 负责追踪跨层技术问题直到关闭或明确升级给 PO。

外部 agent 调用前必须先判断是否值得：

- **Claude Code**：用于长时间工程实现、测试补齐、跨层集成和发布就绪工作；必须在独立 worktree / 分支内执行。
- **Gemini / Antigravity**：用于快速交叉审查、文案/运营/合规素材初筛、文档一致性校验；不得直接修改 Swift 业务逻辑，除非 PO 单独授权。
- **Grok**：仅作为非阻塞参考；若 headless 输出不稳定、响应过慢或需要人工复制大量上下文，则不进入关键路径。
- **Claude Design / Figma / 原型工具**：只用于 UI 候选稿和对照参考，不能覆盖 Codex + PO 的 UI 决策权。

外部 agent 审查报告必须标注：只读/写入范围、base commit、使用的命令或工具、发现项、未验证项、是否需要 PO 裁决。没有这些字段的报告只能作为聊天意见，不能作为合并或产品决策依据。

### UI 设计辅助工具

Claude Design、Figma、截图批注、HTML/CSS/React 原型和其它设计工具可以作为 Codex UI lane 的对照参考，但不构成 SnapDrill 的设计真相源。设计工具的产物必须回落到以下证据之一才算进入项目：

- `docs/ui-redesign/REDESIGN-LOG.md` 中的设计决策、取舍和 PO 结论
- SwiftUI 代码、Snapshot / XCUITest 或可复现的真机/模拟器观察
- 与 Apple HIG、无障碍、Dynamic Type、本地化和当前产品定位一致的验证记录

Claude Design 的推荐用法是先产出 wireframe / high fidelity 候选稿，用于比较布局、信息密度、视觉 token 和组件结构；Codex 与 PO 决定是否吸收。不得把网页原型、Claude Design 输出或第三方博主工作流直接当成 SwiftUI 架构结论，也不得让 Claude Design 覆盖 Codex+PO 已定的 UI 视觉方向。

## 6. Worktree 与提交

- 每个活跃 lane 使用独立 worktree 和独立分支
- 开工前记录 base commit；集成前 rebase 到最新 `origin/develop`
- 不改、不清理其他 lane 的 worktree、stash 或未提交文件
- 依赖顺序：Core/Data 契约先落地，UI/Feature 消费方后 rebase 接入
- PO 要求本地交付时，完成信号是：clean diff + 本地 commit + commit hash + 验证结果
- push、PR、merge、部署只有在 PO 明确授权时执行

### 多窗口并行运行模式

多窗口并行只用于 PO 或 shaping 已明确授权的阶段。每个窗口仍是一个独立 lane，协作只经 repo 产物流转：commit、PR、report、tracked docs；窗口之间不靠聊天口头同步状态。

窗口角色：

- **主刀**：当前主 write slice 的执行窗口；负责该 slice 的本地实现、验证、commit 和回报。
- **副刀**：仅当规划方声明两刀文件集不相交时激活；负责第二个独立 write slice，不能触碰主刀文件集。
- **运维**：负责合并、PR、CI、rerun 与 worktree 卫生；永不写代码。
- **QA**：只读 dogfood、审计、盲审与报告；不直接改代码或文档。

写并行准入：

- shaping 必须先声明主刀 / 副刀的文件集不相交，且每刀都有独立验收与验证方式。
- 若两刀都需要修改共享接缝，先拆出契约小 PR 冻结接口；两边基于该契约并行，不能各自猜接口。

硬约束：

- 同时进行的 write WIP 不超过 2 个窗口。
- 合并永远串行，由运维执行；合并顺序由 shaping 标注，每次合并都需要 PO 明确授权。
- 每个窗口开工先按 §3 的 T0 对账要求确认目标分支 / HEAD / dirty files / 已合并与未合并工作 / live path:line 仍成立，并把结果写入任务 brief、PR 描述或对应 report。

### PO 暂时不在线

- 各 Agent 可以继续在自己的 worktree 中实现已明确的任务、补测试、核实事实并创建本地 commit
- 可以记录新发现和准备 handoff，但不能自行改变产品语义、法律立场或免费/付费边界
- 不得自行 push、merge、上传 TestFlight、提交审核或发布 App Store 版本
- S0/S1 问题可由 Claude 立即完成技术分诊和 hotfix 准备；涉及发布、下架、账号或对外通知时仍等待 PO 授权
- PO 恢复在线后只需审阅决策点与可验证产物，不要求 Agent 停止所有低风险工作

建议每个 worktree 使用独立 DerivedData，避免并行构建互相清缓存：

```bash
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests \
  -derivedDataPath /tmp/snapdrill-derived-<lane>
```

## 7. 验证与完成信号

验证重量按改动风险分级，而不是每个补丁都默认跑最高规格。分级只能降低低风险改动的仪式成本，不能降低真实代码、产品语义、跨层契约和发布相关改动的验证强度。

### 验证分级表

| 等级 | 适用改动 | 本地验证 | PR / CI 策略 |
|---|---|---|---|
| T0 | 纯文档、注释、Markdown 索引指针、不会进入编译产物的说明性文本 | `git diff --check`；涉及 docs 结构时跑 `python3 Scripts/validate_docs.py --check`；涉及自动生成索引时跑对应 generator `--check` | 可创建 Ready PR；不必等待全量 iOS build；CI 可异步观察 |
| T1 | 开发者可见但不影响编译结果的 Swift 注释、`#Preview` 名称等 | `swiftlint --strict` 或 scoped SwiftLint；必要时 `git diff --check` | 可不等待全量 CI；报告说明未跑 build 的理由 |
| T2 | 任意进入编译产物的代码改动，包括常量值、L10n 取值、View 结构、资源引用、测试文件 | `swiftlint --strict` + `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` | PR 可先开，但合并前必须有本地 build 或 CI build 绿 |
| T3 | 用户可见交互、状态分支、手势、导航、导出/打印、权限、错误态、ViewModel 接口消费 | T2 + 针对性测试或手动实测；必要时截图/录屏/真机 dogfood | 等 CI 绿；报告已验证路径与未验证路径 |
| T4 | Core/Data/ViewModel/SM-2/存储/隐私声明/发布签名/跨层契约/迁移/批量导出等高风险改动 | T3 + 相关契约测试、回归测试或发布前专项检查；必要时外部复审 | 等 CI 绿；必要时 PO/legal/外部 reviewer 复核；不得靠自述跳过 |

`swiftlint` 是 linter，不是编译器：它不做类型检查，也不保证代码能编译。因此 T0/T1 严格限定为“不可能改变编译结果”的内容。任何进入编译产物的代码，即使只是常量、字符串值或资源 key，也从 T2 起步，必须通过 build。

### 升级触发

遇到以下任一情况，至少升到 T2；不确定时升一级：

- 用户可见文案或 L10n **值**变化
- View 结构、布局、导航、手势或无障碍行为变化
- 逻辑分支、状态机、错误处理、异步时序或 ViewModel 交互变化
- Core/Data/Repository/SM-2/存储、导出、打印、OCR、权限或隐私路径变化
- 测试文件、Package 配置、pbxproj、资源 membership 或 build setting 变化
- 对外文案、法律/合规、发布、签名、TestFlight 或 App Store Connect 相关改动

### 不可简化的护栏

- PO 对产品意图、默认行为、免费/付费边界、对外文案和发布授权拥有最终裁决权。
- Agent 不自行 merge；push、PR、merge、删分支均按 §6 授权执行。
- 对外文案 PO-gated；未授权不得静默改写定位、合规或营销语义。
- 跨层问题不得用 UI 层静默绕过；需记录契约、owner、验证方式和 blocker。
- ViewModel/Core/Data/SM-2/存储/导出打印/隐私声明等高风险路径必须真验证，不能用“看起来正确”替代。
- 屏级打磨的完成线不取消；契约 seed 不取消，只是不被每个微补丁自动触发。

完成报告必须区分：验证等级、已验证、未运行、外部阻塞与降级理由。若降级验证，报告必须说明为什么该改动不可能影响编译或运行行为。

## 8. 产品决策闸

只有以下情况必须停下问 PO：

- 改变产品定位、默认行为、免费/付费边界或用户可见语义
- 多个合理交互方案会形成不同产品体验
- 法律/合规 guardrail 与现有功能冲突
- 需要删除或不可逆迁移用户数据、账号、签名或发布资源

纯工程实现、事实校准、测试补齐、已决策方案的落地由对应 lane 自主完成。

## 9. 分支生命周期

最小分支策略，保证仓库分支与活跃工作一一对应。本节只描述策略，不授权 agent 改 GitHub 设置或删分支。

- **一 lane/任务一活跃分支**：每个 lane 或任务同时只保留一个活跃分支，避免并行分支堆积与漂移。
- **合并即删**：分支合并进 `develop`/`main` 后删除该分支（其历史已在目标分支与 Git 历史中保全）。
- **关闭未合并需校验 + 授权**：关闭但未合并的分支，删除前必须确认它已被取代（supersession）或确认其上没有未在别处保全的独有 commit（unique-commit 校验），并取得 PO 明确授权。
- **不靠过期固定 hash 复活**：永不用私有记忆 / 旧任务清单里的固定旧 commit hash 去 recover 或 rebase；恢复工作前先 `git fetch`、检查 live checkout、查 GitHub 实证。
- **agent 不直推 develop/main**：agent 一律在独立分支工作，不在 `develop`/`main` 上直接提交；push、PR、merge、删分支均需 PO 明确授权（与 §6 一致）。
