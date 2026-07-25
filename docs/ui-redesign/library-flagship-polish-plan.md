# Library 旗舰屏发布级打磨清单（PO 已确认）

> **文档状态：已取代的历史 UI 证据。** 本文保留旧实现、截图和当时裁决，不再是当前 UI 合同或 release checklist；当前要求以 `docs/product/vision.md` -> `docs/product/release-1-prd.md` -> owning feature spec 为准。

> 状态：PO 已批准默认建议（2026-06-15）。本文收敛 Library 第一屏打磨范围，并作为本轮实现合同。

## 0. PO 决策区

以下是执行合同。PO 可回复“批准默认建议”，或逐项改写 `PO 结论`；未确认前不进入实现。

| 决策项 | Codex 默认建议 | PO 结论 |
| --- | --- | --- |
| L1 详情页答案行为 | 默认隐藏；点击展开；同一容器内切换，避免文字/图标刷新跳动。 | 批准默认建议 |
| L2 详情页阅读层级 | 题干为主视觉层级；答案与元信息次级；只做 UI 可读性，不做 OCR/公式解释层改造。 | 批准默认建议 |
| L3 列表状态 | 保留已合入的筛选防抖；只补加载/空/错误/分页与行内布局稳定性。 | 批准默认建议 |
| L4 导出/分享/打印反馈 | 对 Library 入口补进行中、禁用、失败反馈；不改 Core/Data 契约。 | 批准默认建议 |
| 分享卡标题 | `SnapDrill 摘录卡`。备选：`SnapDrill 资料卡` / `SnapDrill 条目卡`。 | 批准 `SnapDrill 摘录卡` |
| 导出 PDF 标题 | `SnapDrill 资料集`。备选：`SnapDrill 回顾资料` / `SnapDrill 归档`。 | 批准 `SnapDrill 资料集` |
| 导出默认 subject | `资料集`。备选：`未分类资料` / `归档资料`。 | 批准 `资料集` |
| 答案区标题 | `答案与备注`。低风险备选：保留 `参考答案`。 | 批准 `答案与备注` |
| SmartPaper 入口 | 首版隐藏 Library toolbar 入口；后续如保留，必须先由 PO 决定免费/Pro 与通用文案。 | 批准隐藏入口 |
| 打印体验证明 | Simulator 只证明编译与基本入口；最终 UX 需 iPhone 17 真机 dogfood。 | 批准此验证边界 |

## 1. 范围与红线

**范围**：Library 列表、题目详情、批量导出、分享卡、打印入口，以及这些入口直接露出的 Library 文案。

**不做**：其它屏、Bundle 名、`developmentRegion`、TestFlight、ASO、Pro 实现、`#816` DIRTY 分支、Core/Data/ViewModel 逻辑重写。

**裁决顺序**：PO 最新明确决策 > 当前代码/构建实证 > `AGENTS.md`/README > feature spec/ADR > 私有记忆。

## 2. 当前代码事实

- 详情页答案目前默认展示：`LibraryDetailView.swift:138-178` 只要有答案文本或答案图片就直接渲染。
- 答案图片目前进入详情页即加载：`LibraryDetailView.swift:191-195`。
- 详情页分享按钮渲染分享卡，失败只写 log，无用户反馈：`LibraryDetailView.swift:254-270`。
- 详情页打印已接 `printPresenter`，有 `isPrinting` 禁用与错误 alert：`LibraryDetailView.swift:275-308`。
- 列表已有空库空态、搜索/过滤无结果空态：`LibraryListView.swift:117-131`。
- 列表行题干只显示 2 行：`LibraryListView.swift:138-141`，这会让详情页答案默认展示更容易打断“先看完整题目再决定是否看答案”的心流。
- 批量导出解析有 loading/failed/loaded 三态：`ResolvedExportSheet.swift:21-39`。
- 导出选项已有 PDF/CSV/ZIP 三入口，ZIP 有处理中状态：`ExportOptionsSheet.swift:41-111`。
- 导出预览已有生成/失败态，打印按钮有 `isPrinting` 禁用：`ExportPreviewView.swift:37-83`。
- Library 直接暴露的儿童/错题语义文案仍存在：`Localizable.strings:167`、`:672`、`:679`、`:794`、`:813-824`。

## 3. 打磨清单

### L1 详情页答案默认隐藏

**目标**：题目详情默认只展示完整题干、图片和元信息；答案区域默认折叠，用户显式点击后展开。

**完成线**：

- 有答案时默认显示一个稳定的答案入口行，不直接暴露答案文本或答案图片。
- 展开/收起使用同一容器与固定标题结构，避免“显示答案/隐藏答案”文字和灯泡图标刷新跳动。
- 展开后再展示答案文本和答案图片；答案图片加载占位只在展开后出现。
- VoiceOver label/hint/trait 保留，使用现有 `accessibility.show_answer` / `accessibility.hide_answer` 或 PO 批准的新文案。
- 不改 Review 复习页逻辑，不改 Data/Core。

### L2 详情页题干识别度与长文本阅读

**目标**：进入详情页后，用户能立即识别哪些文字是“题目正文”，且长题目/数学区间不被布局压得像普通说明文字。

**完成线**：

- 题干区域有明确视觉层级：标题/正文/图片关系清楚，但不做儿童化卡通或游戏化。
- 正文行宽、行距、段落间距适合长文本浏览；不使用会导致中文或数学表达异常拥挤的固定小容器。
- 数学公式/换行只做 UI 可读性改善；OCR 结构化、公式语义、断句算法属于内容解释层，若需要改写则记录为跨层待办。

### L3 列表状态与筛选后的稳定感

**目标**：列表在加载、空库、无结果、刷新、分页时不给用户“数据闪烁或布局突然左移”的感觉。

**完成线**：

- 初次加载不是裸 `ProgressView`，使用与 Library 风格一致的加载态。
- 空库和无搜索结果文案保持通用受众，不出现“孩子/作业/错题”低龄或单一教育信号。
- 行内标签/日期/难度等元信息使用稳定布局；缺少主分类时不让后续元素突兀左移。
- 分页加载有轻量底部状态；分页失败不吞掉已有列表，但需有可感知反馈或重试路径。

### L4 分享、导出、打印交互反馈

**目标**：分享/打印/导出都是一等入口，有进行中、失败、重复点击防护，不让用户误以为按钮无反应。

**完成线**：

- 详情页分享卡渲染失败时给用户反馈，不只写 log。
- 详情页打印生成 PDF 与系统打印呈现期间，有明确进行中反馈，重复点击被禁用。
- 批量导出 PDF/CSV/ZIP 的入口状态一致；ZIP 已有 spinner，但 PDF/CSV 需要检查是否存在“点了没反应”的瞬间。
- 导出预览打印期间按钮状态明确；打印失败 alert 不复用“PDF 生成失败”这类误导文案。
- 真机 `UIPrintInteractionController` 结果仍需 iPhone 17 dogfood；Simulator 只能验证入口和基本 build，不作为最终打印体验证明。

### L5 Library 对外文案合规清单（PO-gated）

以下只列候选，不在 PO 签字前落代码：

| 现有 key / 文案 | 风险 | 候选方向 |
| --- | --- | --- |
| `library.share_card_title` = `SnapDrill 错题卡` | “错题”把产品强绑定教育/儿童语境 | `SnapDrill 摘录卡` / `SnapDrill 资料卡` / `SnapDrill 条目卡` |
| `export.pdf_title` = `SnapDrill 错题本` | 导出成品像儿童错题本 | `SnapDrill 资料集` / `SnapDrill 回顾资料` / `SnapDrill 归档` |
| `export.default_subject` = `错题本` | 无分类页眉回退到旧定位 | `资料集` / `未分类资料` / `归档资料` |
| `library.answer_section` = `参考答案` | 可保留，但偏学习场景 | 保留 / 改为 `答案与备注` / `参考内容` |
| `smart_paper.title` = `智能组卷` | “组卷/练习卷/复习卷/Pro”均不符合首版纯免费通用效率工具信号 | 首版隐藏入口 / 改为 `整理成资料` / `生成资料包`，需 PO 决策 |
| `smart_paper.pro_required` = `Pro 功能，敬请期待` | Pro 已移出 MVP，首版纯免费 | 若入口保留，不能出现 Pro gate；建议首版隐藏或降级为本地免费能力 |

## 4. 跨层发现与待裁决

- 数学题换行质量不是纯 UI 能完全解决。UI 可改善行宽、行距、标题层级；公式结构、OCR 断句、MathML/LaTeX 属内容解释层或未来第三方能力。
- SmartPaper 位于 Library toolbar，且文案/行为涉及 Pro 与“组卷”。这是 Library 屏内暴露项，但是否隐藏、改名、降级为免费能力属于产品决策。
- 打印真机行为需要设备 dogfood；代码与测试只能证明 adapter 路径和基本状态，不能证明真实打印面板的最终手感。

## 5. 实现完成线

实现阶段只有在 PO 确认本清单后启动。完成必须满足：

- L1-L4 全部完成，L5 按 PO 明确授权的文案范围执行。
- 不触碰 #816，不改受保护分支，不静默改外部文案。
- 更新 `docs/ui-redesign/REDESIGN-LOG.md`，记录范围、设计决策、改动文件、跨层发现、DoD 状态。
- `swiftlint --strict` 通过。
- `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` 通过。
- 创建指向 `develop` 的 Ready PR，不 merge。
