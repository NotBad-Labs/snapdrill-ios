# Capture 采集屏发布级打磨清单（待 PO 确认）

> 状态：待 PO 确认。本文收敛 Capture 第二屏打磨范围，并作为后续实现合同；未确认前不进入实现。

## 0. PO 决策区

以下是 Codex 默认建议。PO 可回复“批准默认建议”，或逐项改写 `PO 结论`；未确认前不改代码、不改对外文案。

| 决策项 | Codex 默认建议 | PO 结论 |
| --- | --- | --- |
| C1 采集入口布局 | 沿用 #820 Library 的冷静生产力风格；保留 6 个入口，但改为更稳定、可扫读的入口组，不做儿童化/游戏化视觉。 | 待确认 |
| C2 入口反馈 | 每个入口点击后有局部 busy/disabled 反馈；全局处理 overlay 保留但不作为唯一反馈。 | 待确认 |
| C3 权限与无相机 | 权限拒绝/受限给明确引导；无相机/模拟器路径有用户可见降级说明。若 camera session 无法把错误暴露给 UI，则记录跨层契约。 | 待确认 |
| C4 OCR 成功/失败/空结果 | 成功进入结果页；失败给重试/返回路径；空结果进入可编辑空态但明确说明“未识别到文字”，不让用户误以为空白是正常结果。 | 待确认 |
| C5 导入反馈 | 相册/PDF/剪贴板/文档扫描均有加载、失败、空输入或不可读反馈；已有逻辑只做 UI 补齐，不重写导入/OCR 引擎。 | 待确认 |
| C6 存入题库反馈 | 保存时有明确进行中状态；成功有短确认；失败保留 alert 并优化文案。只使用现有 `isSaving`/`isSaved`/`showErrorAlert` 等 View 状态。 | 待确认 |
| C7 对外文案策略 | Capture 本屏可见文案先列候选；PO 签字后才落代码。InfoPlist 权限用途串列为发布硬化候选，可由 PO 决定是否本轮一起改。 | 待确认 |
| C8 a11y / XCUITest | 保留现有 VoiceOver 与 identifier；为 6 个入口补稳定 identifier，但不删除现有 `capture.manual` / `capture.saveButton` / `capture.contentEditor`。 | 待确认 |
| C9 跨层边界 | 不改 `*ViewModel.swift`、Core/Data/OCR 算法。若 UI 需要新状态或错误类型，写入 blocker/risk 交 PO 决策。 | 待确认 |

## 1. 范围与红线

**范围**：Capture 采集屏族，包括相机/扫描采集、OCR 处理、相册/PDF/剪贴板导入、手动录入、采集结果编辑、存入题库衔接，以及这些入口直接露出的 Capture 文案。

**不做**：其它屏、Bundle 名、`developmentRegion`、TestFlight、ASO、Pro 实现、`#816` DIRTY 分支、Core/Data/ViewModel 逻辑重写、OCR/Vision 引擎算法改写。

**硬边界**：

- 默认不改任何 `*ViewModel.swift`。本轮 UI 只能消费现有状态；如果现有状态不足，记录为跨层契约待办。
- 不移动 Core/Data 中现有 UI 概念，包括 `SnapDrillCore` 的 `L10n+Capture.swift`。
- 不删除无障碍标签、选中 trait、`accessibilityIdentifier`，不破坏 XCUITest 入口。
- PO 最新明确决策 > 当前代码/构建实证 > `AGENTS.md` / git-tracked SSOT > feature spec / ADR > 私有记忆。

## 2. 当前代码事实

- Capture 首页有 6 个入口：拍照、相册、手动、剪贴板、文档扫描、PDF 导入。
- Capture 首页已有全局 `isProcessing` overlay，但入口卡片本身没有进行中或禁用态。
- 相机权限拒绝/受限已有 alert 与“打开设置”动作；相机 session 内部无后置摄像头/配置失败目前主要写 log，UI 侧没有明确状态。
- 相册导入失败有用户 alert；图片导入成功后进入 OCR 处理。
- 主图片 OCR 失败有重试 alert；OCR 识别为空时目前仍进入结果页，用户只看到空内容，缺少“未识别到文字”的解释。
- 文档扫描和 PDF 页 OCR 失败路径存在日志或空内容进入结果页的情况，缺少一致的用户可见失败/空态。
- PDF 导入已有大文件警告、读取失败、空 PDF 等错误反馈；PDF 页渲染和 OCR 有 loading overlay。
- 剪贴板为空已有错误反馈；手动录入会直接进入空编辑页。
- 结果页保存按钮会在识别/保存时禁用；保存失败有 alert；保存成功有触觉反馈并延迟返回，但缺少足够明确的视觉确认。
- 结果页有图片 OCR overlay、文本编辑禁用态、复制反馈；答案图片识别失败已有 alert。
- `CaptureMethodCard` 只有手动入口传入稳定 identifier，其他入口当前没有稳定 `accessibilityIdentifier`。

## 3. 打磨清单

### C1 入口层级与视觉统一

**目标**：Capture 首页成为 Library 之后的第二个稳定生产力入口，不再像“功能菜单拼贴”，而是像清晰的采集工作台。

**完成线**：

- 6 个入口保留，但视觉层级统一：主入口、导入入口、手动/剪贴板入口关系清楚。
- 卡片或行内元素尺寸稳定，图标颜色轻快，避免过深圆底和儿童化插画。
- 文案只表达“拍摄/导入/输入资料”，不强化“作业/儿童/错题本”信号。
- 入口按钮有 pressed/busy/disabled 的可见反馈，且不会因为 overlay 出现造成“点了没反应”的瞬间。

### C2 相机、扫描与权限状态

**目标**：用户从点击拍摄到看到相机/扫描器期间，每个失败或等待状态都有解释和下一步。

**完成线**：

- 相机权限拒绝/受限：保留系统设置引导，文案改为通用资料采集语境。
- 文档扫描在模拟器或不支持环境下有清楚空态，不只显示技术限制。
- 相机启动/扫描进行中有轻量状态提示；快门按钮在捕获进行中有 disabled/busy 反馈。
- 如果无相机或 session 配置失败只能由 `CameraSessionManager` 记录 log，计划中标记为跨层契约 blocker，不在 UI 层伪造状态。

### C3 OCR 处理、失败与空结果

**目标**：OCR 不是黑箱。用户能区分“正在处理”、“识别失败”、“未识别到文字但可手动编辑”。

**完成线**：

- 主图片、文档扫描页、PDF 页 OCR processing 的 loading 表达一致。
- 主图片 OCR 失败保留重试；PDF/扫描 OCR 失败不再静默进入空编辑页，至少在结果页给出明确的空态解释或错误提示。
- OCR 为空时，结果页文本区显示“未识别到文字，可手动输入或重试采集”的空态，不把空白当正常内容。
- 低质量图片、超时、置信度等未由现有状态暴露的场景列为 OCR/Core 契约风险，不在 UI 层编造判断。

### C4 导入路径反馈

**目标**：相册、PDF、剪贴板和手动录入都像一等入口，错误可理解，重试路径清楚。

**完成线**：

- 相册导入：读取/解码/处理期间入口有反馈；失败 alert 说明下一步。
- PDF 导入：大文件、不可读、空 PDF、页面渲染中、OCR 中都有明确状态；分页选择后 OCR 失败/空结果有可见解释。
- 剪贴板：空剪贴板反馈保留；成功进入编辑页后文案不使用“题目”作为唯一语境。
- 手动录入：空编辑页是 intentional，不和 OCR 空结果混淆；标题和占位文案表达“内容/资料”。

### C5 采集结果编辑与保存

**目标**：结果页是用户确认和修正的地方，保存链路要明确、低焦虑、不中断。

**完成线**：

- 文本区、图片区、元信息区和答案/备注区沿用 Library 的阅读层级，题目/资料正文更突出。
- `isRecognizing`、`isSaving`、`isSaved`、`showErrorAlert` 都有可见 UI 对应；保存期间按钮禁用并显示正在保存。
- 保存成功有短确认，不只靠触觉反馈；保存失败继续用 alert，但文案指向重试或保留编辑内容。
- 复制、裁剪、重识别按钮保留并优化反馈；不删除现有 a11y。

### C6 本屏对外文案合规清单（PO-gated）

以下只列候选，不在 PO 签字前落代码：

| 现有 key / 文案 | 风险 | 候选方向 |
| --- | --- | --- |
| `capture.camera_title` = `拍照录题` | 强绑定题目/教育场景 | `拍摄资料` / `拍摄内容` / `拍摄并识别` |
| `capture.manual_subtitle` = `直接输入题目` | 只服务题目场景 | `直接输入文本` / `手动补充内容` |
| `capture.question_content` = `题目内容` | 结果页把资料固定为题目 | `内容` / `资料内容` / `识别内容` |
| `capture.question_details` = `题目详情` | 旧教育语境 | `详情` / `资料详情` |
| `capture.grade` = `年级/程度` | 年级有儿童/学校信号 | `阶段/级别` / `级别` / `分类阶段` |
| `capture.new_grade` 等新增年级文案 | 年级语义延续 | `新建阶段` / `新建级别` |
| `capture.camera_scanning_hint` = `寻找题目区域...` | 拍摄时只寻找题目 | `寻找文字区域...` / `对齐资料区域...` |
| `capture.default_source` = `试卷` | 单一教育材料 | `资料` / `导入资料` / `未分类资料` |
| `NSCameraUsageDescription` = `小本本需要使用相机来扫描和采集题目。` | 旧品牌 + 题目语境；属于二进制权限用途串 | `SnapDrill 需要使用相机拍摄并识别你选择的资料内容。` |
| `NSPhotoLibraryUsageDescription` = `小本本需要访问相册来导入学习资料。` | 旧品牌 + 学习资料语境 | `SnapDrill 需要访问相册以导入你选择的图片资料。` |

## 4. 状态验证矩阵

| 状态 | 当前证据 | 本轮目标 | 验证方式 |
| --- | --- | --- | --- |
| 相机权限拒绝/受限 | 已有 alert + Open Settings | 文案与样式统一 | Simulator / code path |
| 无相机/模拟器 | 文档扫描有模拟器空态；SmartCamera 无后置相机仅 log | 文档扫描 UI 优化；SmartCamera 列为跨层风险 | Simulator + code path |
| 相机扫描中 | SmartCamera 有 ready/scanning hint | 快门 busy/disabled，提示稳定 | Simulator limited；最终真机 |
| 相册导入中 | 全局 `isProcessing` | 入口级反馈 + 全局 overlay | Simulator |
| PDF 导入中 | 大文件 alert、PDF picker loading | 反馈一致，失败不静默 | Simulator |
| 剪贴板为空 | 已有错误反馈 | 保留并统一样式 | Simulator |
| OCR 处理中 | 主流程、PDF/扫描 picker 有 loading | 文案和视觉统一 | Simulator / mock data |
| OCR 失败 | 主图片有 retry；PDF/scan 多数只 log 或空结果 | 有用户可见失败/空态 | Code path + targeted manual test |
| OCR 空结果 | 当前进入空编辑页 | 明确“未识别到文字，可手动编辑” | Fixture / manual |
| 手动录入 | 直接进入空编辑页 | 与 OCR 空结果区分 | Simulator |
| 保存中 | `isSaving` 禁用按钮 | 明确保存中反馈 | Simulator / code path |
| 保存成功 | 触觉反馈 + 延迟返回 | 短确认 + 返回稳定 | Simulator |
| 保存失败 | alert | 文案和重试路径清楚 | Unit/UI mock or code path |

## 5. 跨层发现与待裁决

- `SnapDrillCore` 中的 `L10n+Capture.swift` 仍承载 UI 文案常量。这是已知跨层 UI 概念，本轮只在 PO 批准后改必要字符串，不移动层级。
- `CameraSessionManager` 在无后置相机、配置失败等路径主要记录日志。若需要 UI 精确展示“相机不可用”，需要 Feature/Core 暴露状态或错误契约。
- OCR 空结果、低质量图片、超时、置信度目前不是完整 UI 状态机。UI 可以处理空字符串和错误回调，但不能判断 OCR 质量原因。
- PDF/扫描页 OCR 失败后进入空结果页的路径若要区分失败和空结果，可能需要页面选择器或 ViewModel 暴露失败原因；本轮先以结果页空态兜底，深层契约另列。
- 权限用途串属于二进制发布硬化范围。它直接影响 Capture 入口体验，但是否本轮修改需 PO 明确授权。

## 6. 实现完成线

实现阶段只有在 PO 确认本清单后启动。完成必须满足：

- C1-C5 逐项完成，C6 只执行 PO 明确批准的文案范围。
- 不触碰 #816，不改受保护分支，不静默改外部文案。
- 不改 `*ViewModel.swift`；如确需新状态，先停下记录 blocker/risk。
- 更新 `docs/ui-redesign/REDESIGN-LOG.md`，记录范围、设计决策、改动文件、跨层发现、DoD 状态。
- `swiftlint --strict` 通过。
- `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` 通过。
- 创建指向 `develop` 的 Ready PR，不 merge。
