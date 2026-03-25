# 文档→代码可追溯性审计方案

> **状态**：定稿（三方审查完成，采纳 Xcode Intelligence 方案为主，Antigravity 依赖蔓延建议纳入）
>
> **目标**：验证文档体系与代码实现之间的双向映射完整性，发现"凭空捏造的代码"和"想当然的接口"
>
> **前置条件**：Milestone 1「v1.0 架构与文档基线」已关闭，文档体系 Diátaxis 重构完成

---

## 为什么需要这次审计

过去完成的审计：
- **文档审计**（4 轮）：文档之间的一致性（引用、交叉指针、措辞精确性）
- **代码审计**（3 轮）：代码本身的质量（lint、并发安全、HIG、性能）

**从未验证的缺口**：文档和代码之间的映射。具体风险：

| 风险 | 含义 | 举例 |
|---|---|---|
| 幽灵代码 | 代码存在但文档中无对应需求 | 某个 Protocol 是"觉得以后会用"而写的 |
| 需求悬空 | 文档有需求但代码未实现或实现偏离 | requirements 说"草稿恢复"，但实现有遗漏 |
| 决策违背 | architecture.md 说"不做 X"，代码里偷偷做了 | 禁止 Domain 层，但有 struct 在扮演领域对象 |
| 接口想当然 | Protocol/API 的设计没有文档依据 | 某个协议的方法签名是"感觉应该这样"而非基于需求推导 |

---

## 审计范围

### 文档侧（5 份输入文档，全部有对应审计维度）

| 文档 | 对应维度 |
|---|---|
| `product-requirements.md` | 维度 1 正向追溯 |
| `product-design.md` | 维度 3 设计决策合规 |
| `architecture.md` | 维度 4 架构+编码约束合规 |
| `conventions.md` | 维度 4 架构+编码约束合规 |
| `infrastructure.md` | 维度 4 架构+编码约束合规 |

### 代码侧（混合粒度：核心骨干逐个，View 按模块）

| 类别 | 数量 | 审计粒度 | 审计重点 |
|---|---|---|---|
| public protocol | 8 个 | 逐个 | 是否有文档依据？是否违反"无协议"约束？ |
| @Model 类 | 5 个 | 逐个 | 字段是否与 requirements 中的字段定义一致？ |
| ViewModel | 11 个 | 逐个 | 是否对应 requirements 中的功能？ |
| View | ~37 个 | 按模块（6 组） | 模块整体是否对应需求？（不逐个追溯 UI 子组件） |
| Service/工具（public 接口） | 逐个确认 | 逐个 | 是否有需求支撑？ |
| Service/工具（纯内部） | — | 跳过 | 如 `Color+Hex`、`Date+Extensions` 等工具类不审计 |

> View 按 6 个功能模块审查：Capture、Dashboard、Review、Library、Settings、Onboarding。
> 子组件（如 `CornerBracketShape`、`BentoCard`）的存在依据是 UI 实现细节而非产品需求，逐个追溯会产生大量无意义标记。

---

## 审计维度（5 个）

### 维度 1：正向追溯（需求 → 代码）

**方法**：逐条检查 `product-requirements.md` v1.0 功能清单，确认每条需求有对应的代码实现。

**输出格式**：

| 需求 | 对应模块/文件 | 测试覆盖 | 状态 |
|---|---|---|---|
| 智能相机拍照 | CaptureView, SmartCameraView | CaptureViewModelTests: 正常流+异常流 | 已实现 |
| 草稿恢复 | CaptureDraftService | CaptureDraftServiceTests: 待验证行为链 | 需验证完整性 |

**关注点**：
- 状态为"已实现"但实际代码不完整
- 需求细节（如"保存后自动返回摄像头"）是否真的在代码中体现
- **测试行为覆盖**：对应测试是否覆盖需求的关键行为路径（正常流 + 至少一条异常流），而非仅检查测试文件是否存在

### 维度 2：反向追溯（代码 → 需求）

**方法**：遍历每个 public protocol、@Model、ViewModel、有 public 接口的 Service，追问"为什么存在？文档中的依据是什么？"

**输出格式**：

| 代码构件 | 文档依据 | 判定 |
|---|---|---|
| `OCRServiceProtocol` | design§OCR 定位 + requirements§OCR 演进 | 有据 |
| `SubscriptionServiceProtocol` | business§付费模式 | 有据（但 v1.0 未实现付费） |
| `RemoteConfigurable` | ??? | 待确认 |

**关注点**：
- 找不到文档依据的构件 = 幽灵代码嫌疑
- 为未来需求提前写的代码（gold plating）
- **合理技术兜底**：错误处理、日志、空状态等防御性代码如果符合 conventions.md 规范，标记为"合理兜底"而非"幽灵代码"

### 维度 3：设计决策合规（design → 代码）

**方法**：逐条检查 `product-design.md` 的 8 条设计决策，验证代码是否遵循。

| 设计决策 | 验证方式 | 预期 |
|---|---|---|
| 用户价值金字塔（录入 > 管理 > 复习） | 检查 Tab 顺序、导航层级、功能入口权重 | Tab 栏排列反映优先级 |
| 采集入口 = 标准 Tab | 检查 TabItem 枚举和 TabView 实现 | 无 FAB、无自定义突出按钮 |
| OCR 是辅助不是主角 | 检查 CaptureResultView 的 UI 权重 | 原图优先展示，OCR 文字可选编辑 |
| 原图必须保存 | 检查 ImageStorage 保存链路 | 裁剪后原图持久化，非仅 OCR 文字 |
| 字段可配置 | 检查录入界面是否动态渲染字段 | 设置关闭的字段不出现 |
| 连续录入 | 检查保存后导航行为 | 保存→回到摄像头，非 Dashboard |
| 一图多题 v1.0 = 手动裁剪 | 检查是否有 AI 拆题代码提前存在 | v1.0 无 AI 拆题 |
| 复习克制 | 检查是否有打卡/连续天数/成就系统 | 无此类代码 |

### 维度 4：架构+编码约束合规（architecture + conventions + infrastructure → 代码）

**方法**：逐条检查三份约束文档，验证代码合规性。部分可自动化（Grep 扫描）。

**architecture.md 约束**：

| 约束 | 验证方式 |
|---|---|
| 无 Domain 层 | grep struct 类型，确认无独立领域对象 |
| 无 UseCase 层 | 确认 ViewModel 直接调 Repository |
| 无 Repository 协议 | 确认 Repository 是具体类，非 protocol |
| DI = DependencyContainer 单例 | 确认唯一 DI 入口 |
| Infrastructure 仅 App 可 import | 确认 Features/UI/Data/Core 不 import Infrastructure |
| 复习算法 = SM-2 | 确认 ReviewScheduler 实现 SM-2 |
| TD-1: tags 内存端过滤 | 确认 #Predicate 未用于 many-to-many |
| TD-2: 8 个 .shared 单例 | 确认数量和清单准确 |

**conventions.md 约束**（SwiftLint 管不到的部分）：

| 约束 | 验证方式 | 自动化 |
|---|---|---|
| ViewModel = `@Observable @MainActor final class` | grep 全部 ViewModel 声明 | 可自动化 |
| Task 句柄 = `@ObservationIgnored private var xxxTask` | grep Task 声明模式 | 可自动化 |
| 关键路径禁止 `try?` | grep `try?`，逐条判断是否在关键路径 | 半自动化 |
| 禁止 `@unchecked Sendable` / `force unwrap !` / `print()` | grep 扫描 | 可自动化 |
| NotificationCenter 用 `for await` 替代 `addObserver` | grep `addObserver` | 可自动化 |

**infrastructure.md 约束**（10 条常见错误 + 4 条 SwiftData 陷阱）：

| 约束 | 验证方式 | 自动化 |
|---|---|---|
| 无 `repository.save(model)` | grep `\.save(` | 可自动化 |
| 无 `SnapDrillLogger.log(` | grep `Logger.log(` | 可自动化 |
| `saveContext()` 失败后有 `rollbackContext()` | grep `saveContext`，检查 catch 分支 | 半自动化 |
| 无 `ImageStorage.loadImage()` 在 View 中 | grep `loadImage()` 在 View 文件中 | 可自动化 |
| PDF 批量渲染有 autoreleasepool | grep PDF 渲染循环 | 半自动化 |
| ModelContainer 非局部变量 | grep `ModelContainer(` 确认作为属性 | 半自动化 |

**第三方依赖备案检查**（来自 Antigravity 建议）：

| 检查项 | 验证方式 |
|---|---|
| Package.swift 中的所有第三方依赖是否在 architecture.md 或 README 中有备案 | 比对 dependencies 列表与文档 |
| 是否有未声明的隐式第三方依赖 | 检查 import 语句 |

### 维度 5：接口设计合理性（protocol → 需求推导）

**方法**：对每个 public protocol 的每个方法，追问"这个方法由哪条需求驱动？"

以 `OCRServiceProtocol` 为例：
- `recognizeText(from:)` → 需求：OCR 印刷体识别 → 有据
- 如果有 `recognizeHandwriting(from:)` → 需求：v1.5 手写体（v1.0 不应存在）→ gold plating

---

## 执行策略

### 三方分工

| 审计方 | 负责维度 | 理由 |
|---|---|---|
| **Claude Code** | 维度 2（反向追溯）+ 维度 4（架构+编码约束合规） | 有 Grep/Read 能力，适合逐文件审查 + 自动化扫描 |
| **Xcode Intelligence** | 维度 1（正向追溯）+ 维度 5（接口合理性） | 有项目内全量上下文，适合需求→代码映射 + 接口推敲 |
| **Antigravity** | 维度 3（设计决策合规）+ 交叉验证 | 独立视角（非 Claude 系模型），适合检验设计意图是否落地 |

### 执行顺序

1. ~~**方案审查**~~（已完成）
2. **独立审计**：各方按分工独立执行，完成后立即输出报告（不等三方同步）
3. **交叉比对**：汇总三方报告，识别共识和分歧
4. **修复**：根据审计发现创建 Issue，按严重度优先级修复

### 严重度定义（复用 workflow.md S0-S3 框架）

| 严重度 | 定义（审计语境） | 举例 |
|---|---|---|
| S0 | 决策违背：代码违反了 architecture.md "不得擅自推翻"的决策 | 存在 Domain struct 层 |
| S1 | 需求悬空：v1.0 标记为 ✅ 的需求未实现或实现不完整 | 草稿恢复缺少"仅保留最近一份"逻辑 |
| S2 | 幽灵代码/接口想当然：代码无文档依据但不影响正确性 | 提前写了 v1.5 功能的 Protocol 方法 |
| S3 | 需求漂移：实现与文档描述有差异但功能可用 | 字段默认值与文档不一致 |

### 输出物

每方输出一份审计报告，统一格式：

```markdown
## 审计报告 — [维度名]

### 审计覆盖
- 检查了 X 个构件/需求

### 发现

| # | 严重度 | 类别 | 描述 | 文档位置 | 代码位置 | 建议 |
|---|---|---|---|---|---|---|

类别：
- 幽灵代码（代码无文档依据）
- 需求悬空（需求无代码实现）
- 决策违背（代码违反文档约束）
- 接口想当然（API 设计无需求推导）
- 需求漂移（代码和文档描述不一致）
- 合理兜底（无文档但属于必要技术防御，不算问题）

### 统计
- 有据：X 个
- 合理兜底：X 个
- 幽灵代码：X 个
- 需求悬空：X 个
- 决策违背：X 个
```

---

## 三方审查采纳记录

| 来源 | 建议 | 采纳情况 |
|---|---|---|
| Xcode | 维度 4 扩展纳入 conventions + infrastructure | 采纳 |
| Xcode | View 审计按功能模块，不逐个 | 采纳 |
| Xcode | Service 按 public 接口划分 | 采纳 |
| Xcode | 严重度复用 S0-S3 | 采纳 |
| Xcode | 测试覆盖从"文件存在"升级到"行为覆盖" | 采纳 |
| Xcode | View 数量修正（37 而非 49） | 采纳 |
| Antigravity | 第三方依赖备案检查 | 纳入维度 4 |
| Antigravity | 新增维度 6（隐式需求） | 不采纳 — 由维度 4 扩展覆盖 |
| Antigravity | 分层递进+阻断卡点 | 不采纳 — 小团队四阶段更简洁 |
| Antigravity | 重新分配三方分工 | 不采纳 — 原分工已合理 |
