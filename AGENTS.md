# AGENTS.md

> 给 AI 编码智能体（Claude Code / Codex / Cursor / Gemini）的最小上下文。
> 视为一份资深工程师交接笔记 — 改动外科手术化，自证后再宣告完成。
>
> CLAUDE.md → 软链接到本文件（`ln -s AGENTS.md CLAUDE.md`）。

## 行为铁律（Karpathy 四原则）

每次写代码前先过一遍这四条。这是最高优先级，覆盖下面所有具体准则。

1. **Think before coding** — 假设要显式说出口；多种解释要并列；不清楚就停下问，别静默选一个；改既有体系/约定前先搜现有怎么做 + 参考社区高 star 实践 + 验证一致再动手，别盲目发明
2. **Simplicity first** — 最小代码解决问题；不要 speculative 抽象；不要未要求的 flexibility 或 configurability；200 行能写成 50 行就重写（"最简"指解决问题的最简，非"省力 / 够用就行"；地基级工作目标是最优且可持续，该重构就重构）。AI 时代补充：追求最优解耦非极致——多显式契约（类型/文档/package 边界）、少形式抽象层（单实现 protocol/pass-through）；agent 度量痛点、不主动提议抽象；缝要么做完（详见 `docs/explanations/architecture.md` §解耦准则）
3. **Surgical changes** — 只动该动的；不要顺手"改进"无关代码 / 注释 / 格式；每行改动追溯到 user 请求
4. **Goal-driven execution** — 把模糊任务转成可验证 success criteria，跑测试自验证后再宣告完成；零信任对齐时验"是否满足上游真相（需求/用例）"而非"自洽"——测试 oracle 来自用例非代码，双向可追溯无孤儿

**本文件运转良好的信号**：diff 中无关改动减少；过度抽象引发的重写减少；澄清问题在实现前提出而非犯错后。

## 项目概览

SnapDrill：一款 SwiftUI 单平台 iOS 通用效率工具。首个切口是帮助处理结构化纸张 / PDF 的成年人，以最低摩擦形成可搜索、可整理、可打印的个人资料库；产品可继续优化试卷 / 题目工作流，但不对外呈现为儿童教育 App。

- **平台**：iOS 26.0+，当前 shipping target 为 iPhone-only（`TARGETED_DEVICE_FAMILY = 1`）；iPad / 通用发行需 PO 决策与 UI dogfood 后再开启；原生 SwiftUI，Swift 6.3 strict concurrency
- **价值链**：采集 > 整理 / 找回 > 导出 / 打印（Review / SmartPaper 是可选附加值）
- **生产基线**：美国 NotBad Labs L.L.C. Team `J58U72W335` + Bundle `com.snapdrill.global`；Release Archive + Development signing 已验证，开发签名真机 Release build/install/launch 已验证，真机功能 dogfood 与 TestFlight / App Store distribution signing 待验。国内路线暂时挂起，相关资源保留可复活
- **状态**：零上架零用户；Release 1 免费、无广告、无 IAP。Pro / StoreKit、CloudKit、Word 与定价只是未来候选，不属于当前发布承诺
- **架构铁律**：单向依赖向下，Core 层零外部依赖

### 意图与事实的裁决规则

SnapDrill 不使用一条混合优先级同时裁决“应该做什么”和“现在实现了什么”。两类问题分别沿不同链路判断：

- **规范链（产品应该是什么）**：`develop` 中当前有效的 Product Constitution（`docs/explanations/vision.md`）> 当前 Release Product Contract > 产品政策 / typed decision > feature spec > 验收标准 > 代码与测试。
- **实证链（产品现在是什么）**：当前代码、测试、构建、真机与发布实证 > 自动生成状态 > 当前说明文档 > agent 私有记忆与历史材料。

代码可以证明当前实现，但不能覆盖产品规范。两条链不一致时，应记录为待修复偏差或待裁决问题，不能用现状反向改写产品目标。PO 的最新明确意图启动 shaping，但在归属权威文档合入 `develop` 前，不替换其他 lane 正在执行的有效基线。

产品决策采用统一生命周期：

```text
exploration -> shaped candidate -> ratified -> effective -> superseded
```

- 对话中的想法、偏好和类比属于 **exploration**，没有跨 lane 规范效力。
- agent 写清选项、影响、可逆性、归属和验证后成为 **shaped candidate**。
- PO 明确批准候选及范围后成为 **ratified**；批准不等于授权合并。
- 归属权威文档合入 `develop` 后才成为 **effective**，并可替换旧基线。
- 旧决定被新有效权威取代后成为 **superseded**，保留历史指针但不得驱动新工作。

现有 tracked 规范在被明确 supersede 前持续有效。跨 feature、数据 / wire、公开承诺、商业或平台边界的变更，合并前必须先有上游产品或 release contract；Draft 实验可提前存在，但不得凭实现反向生成产品事实。每次合并仍需 PO 单独明确授权。

当前 Release 1 Product Contract 尚未建立。现有 feature spec / architecture 中的 Multi-Profile、Pro、CloudKit、Word、iPad 和五 Tab 描述属于下游漂移或实现刻画，只能作为下一阶段影响证据；不得据此新增范围、修改公开承诺或合并 #868。

私有记忆只是可丢弃缓存，不能覆盖仓库事实或产品意图。Product Constitution 固定入口为 `docs/explanations/vision.md`，当前定位见 `docs/explanations/positioning-and-audience.md`；多 agent 协作边界、Claude planning DRI 与 Codex 本地实证挑战权见 `docs/how-to/parallel-lanes.md`。

## 构建命令

```bash
# Test build（编译 app/test bundles；CI 随后运行 test-without-building）
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests

# Linting（CI 门禁；0 violations）
swiftlint --strict
```

**重要**：
- `swift test` 不可用（SPM 仅声明 iOS 平台，macOS 跑会 SIGTRAP）
- `SnapDrill` scheme 不含 SPM 包测试；必须用 `AllTests` scheme + `AllTests` testPlan
- Xcode 26.5，真机 iPhone 17
- 版本号单一来源：`Configs/Shared.xcconfig`（`MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`）

## 架构

### 模块拓扑

```
SnapDrill.app（薄壳，Composition Root）
    │
    ├── SnapDrillFeatures（5 个 Feature target，UI + ViewModel）
    │   ├── FeatureCapture       拍照 / 文档扫描 / PDF 导入 / 手动 / 剪贴板
    │   ├── FeatureLibrary       题库 + SmartPaper（智能组卷）+ ShareCard
    │   ├── FeatureReview        SM-2 复习
    │   ├── FeatureDashboard     首页 + 高级统计（Pro 门控，当前实现遗留）
    │   └── FeatureSettings      设置 + CSV 导入/导出 + 备份
    │
    ├── SnapDrillUI              公共 UI + 路由协议（依赖 Mantis 图片裁剪）
    ├── SnapDrillData            SwiftData @Model + Repository + Backup（依赖 ZIPFoundation）
    └── SnapDrillCore            Service Protocol + DI + SM-2 引擎 + MetricKit（零第三方依赖）

SnapDrillShare（Share Extension）  通过 App Groups 与主 App 共享容器
```

**依赖方向**：Features → UI → Data → Core。**严禁反向引用**。`SnapDrillInfrastructure` 与 Firebase SDK 已在 #803 删除。

### DI 与数据流

```
View (@Environment 注入) → ViewModel (@Observable) → Repository → DataExecutor (actor) → SwiftData @Model
```

- `DependencyContainer.shared` App 启动时初始化
- Core service 全部经 `ServiceContainer` 注入（14 属性：analytics / pdfExport / appConfig / privacyConsent / notification / ocr / captureDraft / contentTagging / questionSplitting / deletionScheduler / proEntitlement / activityTracker / reviewScheduler / metricService）
- 当前代码的 Profile-scoped 服务走 `ProfileManager` / `RepositoryContainer`（典型例外：`ImageStorage`）；这是待重基线的实现事实，不是继续扩展 Multi-Profile 的产品依据
- `DataExecutor` 是 actor 拥有 `ModelContainer`，`createOffMainActor()` 消除 MainActor + XPC 死锁（#599）
- 静态 facade 显式豁免清单：`TelemetryGate` / `ZIPArchiver` / `ImageStorage` / `OnboardingManager` / `DependencyContainer.shared`

### 关键决策

| 决策 | 理由 |
|---|---|
| 4 个 SPM Package（Features 含 5 个 feature target） | 编译隔离 + 依赖方向强制 + 模块独立测试 |
| SwiftData 而非 Core Data | iOS 26+ 原生 Swift 集成 |
| `defaultIsolation(MainActor)` | xcconfig 全局 + `-default-isolation MainActor`，减少并发标注噪音 |
| Multi-Profile Vault（当前实现偏差） | 当前代码仍为每 Profile 独立容器；Product Constitution 已选单一资料库，候选替换 #868 待 contract 后重审 |
| Soft Delete + Undo | `DeletionScheduler` 管理 5 秒撤销窗口 |
| 零后端行为采集 | Firebase 已删除；生产注入 NoOp analytics，设备诊断使用端侧 MetricKit |

## SwiftUI 实战准则

### State 管理

- `@State` — 本地短生命周期视图状态
- `@Binding` — 视图间双向流
- `@Observable` — 共享状态（新代码首选；遗留 `@StateObject` / `@ObservedObject` 仅限 iOS 17 之前模式）
- `@Environment` — 全局依赖注入入口

### 异步

- `async/await` 是默认范式，**不**用 Combine 做简单异步
- `.task` 修饰符做生命周期感知异步
- 错误显式处理 `do/try/catch`，**禁止 silent `try?` 吞错**

### View 组合

- 小组件 + 视图修饰符 + 组合优于继承
- View 按业务拆分，不按文件大小（SwiftLint `file_length` 600 硬限）
- **新代码避免 ViewModel**：用 `@State` + `@Observable` 服务直接驱动视图
- **例外**：业务流程复杂的写操作（保存编排、错误恢复、通知监听）仍放 ViewModel

## DO / DON'T

### DO

- 改代码前用 `Grep` / `Read` 确认 API 真实存在
- 采集 / 导出 / 备份流必须 `AppActivityTracker.begin(...)` → ... → `end(...)`，否则 Profile 切换不被阻塞
- 图片加载用 `loadImageAsync()` / `loadDownsampledImage()`
- Repository 保存用 `insertAndSave()`；或 `insert()` + `saveContext()`，失败必须 `rollbackContext()`
- 跨模块刷新发 `Notification.Name.reviewDataDidChange`
- 图片入库前经 `ImageStorage` 剥离 EXIF GPS/位置信息（隐私铁律）
- PDF 批量渲染包 `autoreleasepool` 防 OOM
- 日志用子系统化 API：`SnapDrillLogger.generic.error("...")`
- 改接口签名后 `grep -rn "TypeName(" Packages/*/Tests/` 同步测试
- nonisolated DTO / Snapshot / L10n / Logger 显式标 `nonisolated`

### DON'T

- `repository.save(model)` — 没有此方法
- `@Model.save()` — `@Model` 没有 save()
- `SnapDrillLogger.log("...")` — 没有 .log()，用子系统（`.generic` / `.repository` / ...）
- `#Unique<Model>([\.field])` — 与 CloudKit 不兼容，真机 fatalError（PR #454 已全量移除）
- `#Predicate` 中写 many-to-many 过滤 — 编译通过运行 SIGTRAP，必须 fetch 全量后内存过滤
- `ImageStorage.loadImage()` 同步调用 — 阻塞主线程
- `ModelContainer` 作局部变量 — 必须实例属性保活
- View 直接持有 `ModelContext` — 经 Repository 走 DataExecutor
- 强解包 `!` — SwiftLint `force_unwrapping: error` 阻断合并
- 嵌套 `@Observable` within `@Observable` — 破坏 SwiftUI 观察系统
- Combine 做简单异步 — 用 `async/await`
- `Thread.sleep` 在 `UIGraphicsPDFRenderer.pdfData()` 闭包做时序测试 — CI 调度不确定

## Apple 平台边界

- **Vision OCR**：擅长印刷体；**无独立中文手写识别模型**；`RecognizeDocumentsRequest` 适合整页文档，不适合裁剪后单题
- **Foundation Models**（iOS 26+）：擅长分类 / 摘要；**不擅长数学推理**；`contentTagging` 自动标签可用，**解题不可**
- **CloudKit**：当前 `cloudKitDatabase: .none`，Release 1 不含同步。未来 Apple 私有同步须重新通过 Product / Data / Privacy contract；技术上 SwiftData 不原生支持公共数据库
- **StoreKit**：Release 1 无 IAP，#479 / #486 不属于当前发布范围。未来重入仍需 Apple Developer、ASC 产品、购买 / 恢复 / 取消与隐私验证
- **不存在的 API**：Math Notes（Calculator 私有）/ Smart Script（屏幕手写非照片 OCR）/ 原生公式识别 LaTeX/MathML（需第三方）

## 隐私与合规

- 零注册，全本地（SwiftData + Files），无姓名 / 手机 / 学校等直接身份标识
- App Tracking Transparency **已移除**（ADR-002）
- Privacy Manifest 文件 `SnapDrill/PrivacyInfo.xcprivacy` 已就位；改变收集类目需同步 App Store Connect 数据问卷
- 图片 EXIF GPS/位置信息必须经 `ImageStorage` 剥离
- CSV 导出含 `=+-@` 前缀防注入；JSON 含 schema 版本

## 区域资源约束（双区域路线已挂起，资源勿误删）

SnapDrill 曾规划“一个产品 + 两区域发行版”；该路线已挂起，历史与可逆资源见 `docs/decisions/ADR-003-dual-region-release.md`。

> **当前产品政策（B7-A，2026-07-12）**：Release 1 由美国 NotBad Labs L.L.C. 发布一个 iPhone-only 全球版，产品语言为英文与简体中文。iPad 与中国大陆专项发行已退出当前范围，只有新的明确立项才能重入；下方资源保留仅代表可逆资产，不是发布承诺。

- **当前生产签名**：Team `J58U72W335`（美国 NotBad Labs L.L.C.）+ Bundle `com.snapdrill.global` + App Group `group.com.snapdrill.global`；Automatic Signing；已删未用的 iCloud/CloudKit entitlement。Release archive 与真机安装使用 Apple Development identity 与 `iOS Team Provisioning Profile: com.snapdrill.global` 成功；本机 keychain 尚无 Apple Distribution identity；App Store Connect 本地 export 当前缺 `com.snapdrill.global` / `com.snapdrill.global.share` distribution profiles。
- **挂起的国内资源**（保留勿删、可复活）：Bundle `com.snapdrill.app` / iCloud `iCloud.com.snapdrill.app` / App Group `group.com.snapdrill.app` / 个人 Team `W5A8THDKW8`。
- **官网**：`notbadhq.com/snapdrill`（子目录非子域名）

## 开工前 DoR 与改代码后的 DoD

开工前先过 [`docs/how-to/definition-of-ready.md`](docs/how-to/definition-of-ready.md)：目标、scope、红线、验收标准、验证等级和 PO/legal/fact gate 必须清楚；不清楚就先 shape 或问 PO。

每次 commit / PR 前至少跑这两个本地门禁；0 errors 才能继续。失败立刻修，不留 TODO。

```bash
swiftlint --strict     # SwiftLint 规则见 .swiftlint.yml；force_unwrapping=error / file_length=600
xcodebuild build-for-testing -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests
```

`build-for-testing` 只证明 app 与测试 bundle 能编译，不等于测试已运行。凡是 T2+ 代码行为、用户可见交互、Core/Data/ViewModel/SM-2/存储/导出/隐私或跨层契约改动，完成声明必须包含相关 targeted test / contract test 的本地运行结果，或明确等待 CI 的 `test-without-building` 运行测试结果；不能把绿色编译说成绿色测试。

低风险文档/流程与开发者可见小修的验证重量按 `docs/how-to/parallel-lanes.md` §7 的 T0–T4 分级执行；涉及代码行为、用户可见文案或跨层契约时不得降级。

PO 裁决采用 thin pointer：裁决写入其权威文档（vision / positioning / ADR / feature spec / PO 指定范围文档），`intent-traceability.md` 负责索引。若新裁决暂时没有清晰归属，先在任务 brief 中标明；第二个同类未路由裁决出现时，再建立正式 tracked decision file，避免新增第二真相源。

**本地 hooks**（自动触发）：

- `swift-autolint.sh` — PostToolUse Edit/Write `.swift` 文件后即时 lint
- `block-dangerous-bash.sh` — PreToolUse 拦 `rm -rf /` / `git push --force` / `git reset --hard`
- `Scripts/pre-commit` — 本仓库 tracked pre-commit；用 `Scripts/setup.sh` 安装 / 刷新到当前 checkout 的 git hook，避免本地 `.git/hooks/pre-commit` 滞后
- `pre-push` — push develop/main 前阻断直推，除非 `ALLOW_DIRECT_PUSH=1`

## 文档体系（重组 B · feature-spec 一元化 + Diátaxis）

完整文档见 `docs/`（导航 `docs/README.md`）。功能规格已**一元化**——单功能的 Why/What/How/Verify 在一个 feature spec：

| 目录 | 内容 |
|---|---|
| `docs/features/active\|backlog/feat-*.md` | 功能规格（一元化，每功能一文件）；backlog 为 `mode: lightweight` |
| `docs/features/template.md` | 新建 feature spec 模板 |
| `docs/explanations/` | 为什么：vision = Product Constitution / design-principles 设计原则 / business-model 商业政策 / architecture 架构 / assumptions 待验证假设 / competitive-analysis 竞品 / user-journeys 旅程 / privacy-compliance 隐私合规 |
| `docs/reference/` | 查阅：feature-status 功能状态(SSOT·自动生成) / intent-traceability 意图追溯索引(自动生成) / glossary 术语 / analytics-events 埋点 / apple-platform-limits 平台边界 / non-functional-requirements NFR / scope-and-roadmap 范围路线 / api-pitfalls / appstore-metadata ASO |
| `docs/how-to/` | 操作：definition-of-ready 开工入口 / shape-up 工作方式 / parallel-lanes 协作边界 / release-and-ci 发布与 CI |
| `docs/decisions/` | 架构决策 ADR-001~005 |

**功能状态单一真理源（B 方案）**：状态写在各 feature spec frontmatter（`status`/`tier`/`blocked_by`/`mode`），`docs/reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成（**勿手改**，pre-commit 校验）。

**意图追溯索引**：意图引用写在各 feature spec frontmatter（`intent_refs`），`docs/reference/intent-traceability.md` 由 `Scripts/generate_intent_traceability.py` 自动生成（**勿手改**，pre-commit 校验）。索引只证明“已声明上游依据”，不替代人工语义 review。

## References（按需查阅，需显式调用才会读，不要假设 AI 已读）

- Swift 6 strict concurrency 官方：https://developer.apple.com/documentation/swift/adoptingswift6
- Swift 6 实战坑（ConcurrencyRecipes）：https://github.com/mattmassicotte/ConcurrencyRecipes
- SwiftUI 官方文档：https://developer.apple.com/documentation/swiftui
- SwiftUI 架构参考（Clean Architecture for SwiftUI）：https://nalexn.github.io/clean-architecture-swiftui/
- Swift Testing 官方：https://github.com/swiftlang/swift-testing
- Testing playbook for AI agents：https://gist.github.com/steipete/84a5952c22e1ff9b6fe274ab079e3a95
- Privacy Manifest 自动扫描器：https://github.com/stelabouras/privacy-manifest
- Apple Privacy Manifest 官方：https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Apple Human Interface Guidelines：https://developer.apple.com/design/human-interface-guidelines/
