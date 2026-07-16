# 阶段 02e 候选：PO 产品宪章（Product Constitution）与 Release 1 工作坊

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

> **非规范性塑形输入（NON-NORMATIVE SHAPING INPUT）** — 本文件只列证据、选项、推荐与影响。
> 它不是 Product Constitution、Release Contract、路线图（roadmap）或 PO 决策。
> 任何选项只有经过 02d Gate A 生命周期、PO 明确批准并合入权威文档后才生效。
> **“推荐”不等于默认选中**；工作坊开始时所有产品选项均为空，推荐只表示当前判断及其置信度。

## 目的

把“产品应该是什么”从散落的聊天、功能现状和历史 ADR 中抽离出来，让 PO 用有限选择稳定 Product Constitution v1 与 Release 1。目标不是保留现有实现，也不是为了整洁删除功能；每个推荐都必须同时说明用户价值、当前证据、可逆性和下游成本。

## PO 裁决进度

- Gate A 已由 PR #869 合入 `develop@5c31eff7`，决策生命周期、旧规范显式 supersede 与 contract-first 规则已经 effective。
- Gate B 已由 PO 于 2026-07-12 逐项批准 B1-A 至 B7-A；这些裁决只有在归属权威 `docs/explanations/vision.md` 及直接产品政策合入 `develop` 后才 effective。
- Gate C 尚未开始裁决。本文后半的 C1-C6 仍是非规范性 shaping 选项。
- Multi-Profile 的用户可见产品行为由 B5-A 承接；开发期数据、偏好和旧备份不兼容的过渡边界仍等待 Release 1 / Data Contract。

## 工作坊启动时证据矩阵（冻结快照）

| 问题 | 当前规范主张 | 当前实证状态 | 尚未决定 |
|---|---|---|---|
| 对外定位 | 面向通用受众的成人生产力工具；仍可深耕考试 / 题目 / 培训工作流 | UI/L10n 已大体转向“资料 / 资料库”，旧 ASO / 部分文档仍以教育为先 | 对外定位可以保持宽泛，但首个产品切口尚未命名 |
| 核心价值 | 采集 -> 管理 -> 导出/打印；Review 是可选能力 | App 有五个同级标签页：Dashboard、Library、Capture、Review、Settings | 可选的 Review/Dashboard 是否应占据主导航，以及是否属于 Release 1 范围 |
| 采集 | 摩擦最低；图片是内容真相，OCR 只起辅助作用 | 已有相机、Photos、文档扫描、PDF、手动、剪贴板 / Share 等路径 | 哪些结果是 Must，哪些只是已经实现的渠道 |
| 管理 | 可搜索、可编辑的个人资料库 | 已有搜索、过滤、taxonomy、编辑、批量操作和撤销 | 动态 taxonomy 的复杂度属于核心还是可选能力 |
| 输出 | 导出 / 打印是一等终点 | 已有 PDF / 打印 / 分享、JSON/CSV 和备份 | 哪些格式是用户价值 Must，哪些只是数据可携带性支持 |
| 数据 | local-first、无账户、数据属于用户 | SwiftData / 文件均在本地；无 CloudKit/Firebase；已有备份 / 恢复 | 永久 local-first，还是未来可选的 Apple 私有同步 |
| 资料库身份 | `develop@56e9d27e` 仍把 Multi-Profile 视为 Must；PO 已明确裁决退休，该裁决为 ratified candidate，尚未按 Gate A 成为 effective baseline | Draft PR #868 在 126 个文件中替换该实现；尚未合并（数量复核见 `02d-product-constitution-results.md`） | 先把已批准裁决路由到归属权威，再区分耐久产品行为与实现策略 |
| 商业 | 核心能力免费；未来 Pro 可增加同步 / 智能 / 输出 | StoreKit/CloudKit/Word 不可用；SmartPaper 免费配额仍在推广未来 Pro | 隐藏不可用 Pro、展示占位，还是上架前完成商业化 |
| 平台 / 区域 | 美国公司全球发行；当前目标设备为 iPhone-only | `com.snapdrill.global`、iPhone device family、英文 + 简体中文资源 | Release 1 语言范围；iPad / 中国路线的重新进入政策 |
| 质量 / 成功 | 无崩溃与数据丢失、隐私与 AX、低采集摩擦 | 本地门禁强；无外部用户，也无后端事件流 | 结果级验收，以及 TestFlight 后的学习信号 |

## Gate A — 治理

**PO 状态（2026-07-12 更新）：第 1-3 项已通过 PR #869 成为 effective。第 0 项的产品行为已由 B5-A 承接，过渡兼容边界等待 Release 1 / Data Contract。本裁决不隐含任何后续合并授权。**

已批准事项：

0. 退休 Multi-Profile 的产品目标已由 B5-A ratify；#868 仍只是实现证据，不迁移 / 不兼容边界尚未获得 Release 1 / Data Contract 的 effective 承接。
1. `exploration -> shaped candidate -> ratified -> effective -> superseded`。
2. 当前 tracked 规范持续有效，直到被明确 supersede。
3. 跨 feature、数据 wire、公开承诺、商业或平台边界的变更，合并前必须先有上游 contract；Draft 探索可以更早开始。

替代方案：聊天内容立即具有约束力。审计否决该方案，因为 fresh clone 无法重建聊天内容，而且并行 lane 可以在不违反任何 tracked 规则的情况下发生分歧。

## Gate B — Product Constitution 选项

**PO 结果（2026-07-12）：B1-A、B2-A、B3-A、B4-A、B5-A、B6-A、B7-A 均已逐项批准，等待归属权威合并后 effective。下列未选选项保留为 shaping 历史，不得继续驱动工作。**

### B1. 首个工作流切口与待完成任务（job-to-be-done）

| 选项 | 定义 | 影响 |
|---|---|---|
| **B1-A（推荐的塑形假设，中等置信度）** | 处理结构化纸张 / PDF 材料的成年人，需要完成采集、整理、稍后找回和打印；考试、职业认证、培训以及成年人管理的家庭资料都是示例 | 在不声称某个未经验证的人群的前提下，让工作流具备清晰形状；现有结构化采集 / 打印优势仍然相关 |
| B1-B | 准备考试、职业认证或结构化培训的成年人 | 与历史产品最贴合，但尚无外部需求证据；可能过度拟合现有答案 / SM-2 代码 |
| B1-C | 整理任何个人纸张或文档的所有成年人 | 可触达范围宽，但会直接与 Notes / Files / 扫描工具竞争，也难以形成有力的默认设置与 ASO 方向 |
| B1-D | 整理家庭学习资料的成年人 | 是合理的成年人主导工作流，但不应重新引入多孩账户 / Profile 架构，也不应采用低龄受众导向营销 |

推荐理由：“通用受众”是一种受众 / 合规定位，不是有效的首个工作流。B1-A 是 TestFlight 学习假设，不是已经证实的市场细分或永久宪法人群。目前没有外部获客或付费意愿证据。只要耐久价值承诺保持内容中立，就可以低成本调整元数据（metadata）、引导页（onboarding）和示例层。

### B2. 耐久价值承诺

| 选项 | 承诺 |
|---|---|
| **B2-A（推荐）** | 以最低摩擦，把纸张、照片和 PDF 变成可搜索、可整理、可打印的个人资料库 |
| B2-B | 扫描、归档并整理任何题目或文档 | 当前表述；耐久但较宽泛，结果导向较弱 |
| B2-C | 建立个人题库与回顾系统 | 强烈偏向教育，并把 Review 变成核心，与当前定位冲突 |

### B3. 核心价值链

| 选项 | 价值链 | Review / SmartPaper 的处理 |
|---|---|---|
| **B3-A（推荐）** | 采集 -> 整理 / 找回 -> 导出 / 打印 | 可选的复用工具；不得占据或复杂化主路径 |
| B3-B | 采集 -> 整理 -> 回顾 -> 提升 | Review 成为核心，需要同等验收与投入 |
| B3-C | 扫描 -> 归档 | 更简单的扫描工具；放弃有差异化的打印 / 结构化工作流 |

### B4. 数据与身份定位

| 选项 | 定义 | 影响 |
|---|---|---|
| **B4-A（推荐）** | local-first、无 SnapDrill 账户、一个资料库；永久提供手动可携带备份；未来可选的 Apple 私有同步仍是独立假设 | 在当前不承诺 CloudKit 或 Pro 架构的前提下，保留隐私与差异化 |
| B4-B | 永久严格 local-only | 隐私定位最简单；永久放弃多设备价值 |
| B4-C | 以同步为先，账户 / 云最终成为核心 | 改变隐私、商业、架构和发布定位；需要新的产品证据 |

### B5. 单资料库产品行为

| 选项 | 定义 | 影响 |
|---|---|---|
| **B5-A（推荐的塑形假设，中等置信度）** | 用户只看到一个资料库；除非外部证据支持新的产品决策，否则不规划工作区（workspace）/ Profile 模型 | 移除未经验证的用户可见复杂度；但不声称多个工作区永远不能回归 |
| B5-B | Release 1 中用户只看到一个资料库，但未来工作区 / Profile 模型仍是明确路线图项 | 保留一个没有需求证据的产品承诺，并让下游架构持续不确定 |
| B5-C | 现在保留可见的 Multi-Profile | 保留当前 `develop` 行为，但与已批准且尚未生效的 PO 裁决冲突，并增加跨 UI / 数据负担 |
| B5-D | 发布一个可见资料库，同时隐藏 / 禁用现有 Multi-Profile 代码路径 | 短期技术可逆性最高，但保留推测性状态、备份和失败复杂度 |

PO 应决定产品行为，而不是某个 `ProfileManager` 抽象是否保留。B5 获得批准后，工程侧负责选择符合所选可逆性与数据 contract 的最简单实现。#868 的现有工作是影响证据，不是产品理由。未来由证据支持的 PDR 可以通过 Gate A supersede B5。

### B6. 商业定位

| 选项 | 定义 | 影响 |
|---|---|---|
| **B6-A（推荐）** | Release 1 免费、无广告 / IAP；未来 Pro/CloudKit/Word/定价仍是候选假设；隐藏不可用的购买界面 | 产品不承诺当前无法兑现的能力，并先收集核心价值证据 |
| B6-B | Release 1 免费，但明显宣传即将推出的 Pro 能力 | 可以较弱地测试兴趣，但会增加半成品信号和公开承诺 |
| B6-C | Release 1 前完成 StoreKit/CloudKit | 在没有用户的情况下延迟核心验证，并扩大隐私与发布范围 |

B6 必须分类的当前 Pro 界面清单：SmartPaper 配额与 Pro toast；Dashboard“稍后提供更多洞察”占位；App Store 元数据中的价格 / IAP 主张；Settings / Library 的未来功能文案；Pro 层 backlog 行。隐藏 Pro 是有界产品政策，但不是单字符串修改。

### B7. 平台与区域

| 选项 | 定义 | 影响 |
|---|---|---|
| **B7-A（推荐）** | Release 1：iPhone-only，由 NotBad Labs 美国公司发布全球版；产品 UI 为英文和简体中文；iPad 与中国特定发行必须经过明确的重新进入决策 | 符合当前生产事实与现有本地化投入 |
| B7-B | Release 1 前增加 iPad | 核心验证前需要 UI dogfood、截图、NFR 和发布工作 |
| B7-C | Release 1 前恢复中国特定构建 | 重新打开账户、元数据、隐私、签名和区域维护范围 |

## Gate C — Release 1 选项

### C1. 目标产物

| 选项 | 定义 | 推荐意见 |
|---|---|---|
| **C1-A** | 先发布供 PO 内部试用（dogfood）的 TestFlight 构建，再单独进行公开发布 go/no-go | **推荐**：形成真实发布产物，但不提前声称已具备市场发布条件 |
| C1-B | rebaseline 后立即公开发布到 App Store | 现在就需要元数据、法律文本、截图、支持渠道和完整的外部用户兼容性 |
| C1-C | 不发布；只做仓库 rebaseline | 内部更整洁，但不会产生产品证据；应设定时间边界 |

### C2. Must 结果，而非实现清单

推荐的 Release 1 Must 结果：

1. 新用户无需注册或设置身份即可开始使用。
2. 用户能采集 / 导入真实资料，保留原始图片真相；即使 OCR 失败或不准确也能保存。
3. 用户能在一个资料库中找到、查看、编辑和删除 / 撤销删除已保存资料。
4. 用户能把选定资料生成可用 PDF，并打印 / 分享 / 保存。
5. 取消采集 / 导入 / 导出不会产生部分数据；被中断且尚未保存的采集可恢复或明确丢弃。
6. 权限被拒绝时提供可用的替代输入路径，而不是进入死路。
7. 用户能创建并恢复完整的可携带备份，不发生静默覆盖 / 丢失或路径穿越 / 解压攻击；失败后原资料库仍可恢复且可见。
8. 产品清楚说明本地存储 / 卸载丢失风险，且不会意外上传用户内容。
9. 再次打开 App 的用户遇到本地 store 无法打开时，会看到可理解的恢复选择；可以恢复备份，或在明确知情下以空资料库继续，而不是进入空白页 / 死路。
10. 所有 Must 旅程在 VoiceOver 与受支持 Dynamic Type 下均可使用；公开隐私声明与实际构建一致。

剪贴板、Share Extension、JSON/CSV、每个 taxonomy 字段和每项设置等渠道可以随版本交付，但不能仅因已经实现就自动成为 Must。

### C3. Dashboard

| 选项 | 处理方式 | 影响 |
|---|---|---|
| C3-A（最低改动实验） | 保留为当前首页，但只按导航 / 方向指引价值判断；不把统计作为核心承诺 | 允许内部试用测试它是帮助用户还是延迟采集，但存在意外形成首要产品承诺的风险 |
| C3-B | Library 成为首页；移除或降级 Dashboard | 核心路径更清晰，但证据出现前就需要导航 / UI 重做 |
| C3-C | Dashboard / analytics 成为核心 | 需要可衡量的洞察价值和持续投入 |
| C3-D | 保留 Dashboard 模块，但内部试用默认启动到 Capture 或 Library | 在保留证据收集能力的同时，测试用户是否会主动寻找 Dashboard |

C3-A/D 仅适用于内部 C1-A 产物。收到第一份结构化 TestFlight 反馈包后，PO 根据激活（activation）/ 核心效用（core utility）证据重新决定 Dashboard；公开的 C1-B 发布会让所选首页 / 导航成为软性外部承诺。

### C4. Review

| 选项 | 处理方式 | 影响 |
|---|---|---|
| C4-A（最低改动实验） | 把现有 Review 作为可选能力交付，但暂停新增投入；明确测试同级顶层标签页是否夸大了它的重要性 | 在收集证据时保留已有价值，但同级界面层级（chrome）存在意外形成核心产品承诺的风险 |
| C4-B | Release 1 前把 Review 从主导航降级 | 更符合核心价值链，但会改变用户流程和截图 |
| C4-C | 从 Release 1 移除 Review | 最大程度简化，但在没有使用证据时删除一个规模可观且可用的既有功能 |
| C4-D | 内部试用中保留 Review 模块，但通过 Library / Dashboard 的次级入口进入 | 把可选价值测试与同级主标签页承诺分离 |

内部试用构建中的同级主标签页是实验，不是 Product Constitution 承诺。收到第一份结构化反馈包后，PO 根据可选价值证据重新决定 Review。若公开 Release 1 保留该 IA，需要有主动使用证据。

### C5. SmartPaper 与不可用 Pro

| 选项 | 处理方式 | 影响 |
|---|---|---|
| C5-A | Release 1 把现有基础生成器作为不限次数的免费次级工具；在可购买层级存在前移除配额 / Pro 升级引导（upsell） | 不产生人为死路，但会形成强烈的免费使用先例，并要求明确 suspend 或 supersede ADR-001 |
| **C5-B（推荐的塑形假设，中等置信度）** | Release 1 隐藏并暂停 SmartPaper | 形成最简单的一致版本，并最大程度保留未来定价主动权；但失去差异化打印的 dogfood 证据 |
| C5-C | 保留每月 3 次配额和“Pro 即将推出” | 保留 07-10 前决策，但会在没有升级路径时阻断用户；不推荐 |
| C5-D | 现在实现 StoreKit/Pro | 把发布范围问题转换为大型商业 / 隐私项目 |
| C5-E | 仅在内部试用构建中开放不限次数的基础 SmartPaper，不显示 Pro 文案；根据证据决定公开版本处理方式 | 保留内部试用学习机会，但不会悄然做出公开免费层承诺；仍需明确 ADR-001 状态 |

任何不限次数的免费选项都必须说明 ADR-001 Hybrid 是 suspend 还是 supersede。只有 PO 确认领域专用工作流语言仍符合 Release 1 对外定位后，SmartPaper 域内术语（`题 / 试卷 / 组卷`）才能保留。

对于 C5-A/E，PO 还必须选择开放哪种已实现选择器（selector）：仅基础随机选择，还是当前放在 Pro entitlement 后的 SM-2 紧迫度精准选择器。这与配额是两个独立问题，不能从“免费 SmartPaper”推导出来。C5-A/E 需要通过 Gate A supersede 或 suspend tracked 的 07-01 配额、导出完成才扣费和入口不受 Pro 门槛限制的决策。

### C6. Release 1 验收

推荐的结果证据：

- 一次全新安装（clean install）真机试用，以及一次已有本地资料的再次启动真机试用；
- 保存（包括存储失败）、删除 / 撤销、导出和备份 / 恢复失败路径的确定性自动化覆盖；
- 明确试用权限拒绝、OCR 失败、取消流程、草稿恢复，以及恢复失败但既有数据不丢失；
- 未解决 P0/P1 为零，剩余 P2 均由 PO 明确接受；
- 所有可到达 Release 1 屏幕的 Accessibility Audit issue 为零；
- 在受支持 Dynamic Type 和发行 iPhone viewport 集合中无截断 / 阻断 UI；
- 针对同一候选构建的 release archive / install / launch 与 TestFlight upload / install 证据，包括主 App -> App Group -> Share Extension 往返；
- 公开文案、Privacy Manifest、entitlements 与观察到的网络 / 数据流一致；
- 所选测试者群体拥有可用的隐私政策、支持和反馈路径；
- 不可用 Pro / coming-soon 界面为零，或每一项都由 PO 明确接受为 Release 1 债务；
- 首个外部用户构建声明兼容性边界；此后 backup wire / 数据变更必须明确选择迁移或不兼容。

构建成功和 feature-status 行只是辅助证据，不等于结果验收。

## 首次 TestFlight 后的成功信号

不需要后端事件流。Apple 聚合信号无法证明任务级激活、找回或可选功能意图。产品 / 研究 DRI 必须通过有脚本的主持式内部试用、TestFlight 反馈表和简短跟进访谈收集这些信息；参与者必须知道自己在提供什么反馈。

1. **Activation（激活）**：不熟悉产品的成年人能否在无人帮助下完成首次采集 / 保存，停在哪里？
2. **Core utility（核心效用）**：用户稍后能否找回已保存资料并生成可用 PDF / 打印产物？
3. **Repeat value（重复价值）**：用户是否会在一周内再次回来采集 / 管理另一份真实资料？
4. **Trust（信任）**：备份 / 恢复是否有效，用户是否理解本地数据所有权与卸载风险？
5. **Optional value（可选价值）**：完成核心价值链后，用户是否主动使用 Review 或 SmartPaper？
6. **Quality（质量）**：崩溃 / 卡死 / 启动和 accessibility 证据是否保持在 Release Contract 阈值内？

这些信号用于检验 H1/H2/H3/H9。在后续 PO 决策前，它们不会把假设提升为产品承诺。外部试用前，PO 必须在无遥测（telemetry）定位下接受证据收集方法和负责人（owner）。

## 下游影响图

| 决策 | 首批需要更新的权威 | 主要下游表面 |
|---|---|---|
| B1/B2/B3 | Vision + positioning | onboarding、user journeys、metadata、导航重点、feature intent refs |
| B4/B5 | Vision / product policy + `feat-profile` / local-library PDR | #868、backup wire、settings、CloudKit backlog、architecture/NFR |
| B6/C5 | business model + ADR-001 + Release Contract | SmartPaper 配额 / 字符串 / 测试、Settings Pro 界面、metadata |
| B7 | production / platform policy + Release Contract | NFR、orientations / device family、release guide、截图、本地化 |
| C2-C5 | Release Contract + 受影响的 feature specs | 顶层导航、UI tests、AX route matrix、dogfood scripts、截图 |
| C6 / 成功信号 | Release Contract + assumptions / success-signal owner | test plan、审计门禁、TestFlight 反馈包、go/no-go |

## 推荐决策顺序

1. Gate A 治理（已 effective）。
2. B1/B2/B3：用户、承诺与价值链（已 ratified）。
3. B4/B5：数据定位与单资料库持久性（已 ratified）。
4. B6/B7：商业 / 平台定位（已 ratified）。
5. C1/C2：目标与 Must 结果。
6. C3/C4/C5：可选功能处理。
7. C6：验收与成功信号。

这个顺序避免功能级决策反向定义上游产品。
