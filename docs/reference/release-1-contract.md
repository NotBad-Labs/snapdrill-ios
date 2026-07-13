---
last_verified: 2026-07-14
layer: release-contract
release: 1
ratified_at:
  C3: 2026-07-13
  remaining_12: 2026-07-14
activation: effective_when_merged_to_develop
ratified_decisions: ["C1-A", "C2-Core", "C2-Image", "C2-Optional", "C2-Personalization", "C3", "C4-D", "C5-E", "C5-S1", "C6-A", "DATA-1", "DATA-1-E", "DATA-1-R"]
pending_decisions: []
upstream:
  - ../explanations/vision.md
  - ../explanations/positioning-and-audience.md
  - ../explanations/business-model.md
  - ../explanations/design-principles.md
---
# Release 1 Product Contract

> PO 于 2026-07-13 ratify C3，并于 2026-07-14 ratify 其余 12 个精确决策 ID；至此下表全部 13 项均已批准。本文在分支或 PR 中只是已批准候选，合入 `develop` 后才成为 effective Release 1 权威。`RATIFIED` 不授权代码实现、构建上传、开放 TestFlight、发布或合并；每次合并和发布动作仍需 PO 单独明确授权。

## 1. 合同职责

本文承接 [Product Constitution v1](../explanations/vision.md)，只定义 Release 1 的目标产物、Must outcomes、可见能力、明确非目标、数据兼容边界与结果级验收。它不冻结具体卡片、像素布局、类型名、package 边界或当前实现，也不允许通过“代码已经存在”反向扩大范围。

发生冲突时：Product Constitution 决定耐久产品方向；本文决定 Release 1；feature spec 细化单功能；代码、测试和发布实证只证明当前实现。

### 决策摘要

| ID | 状态 | 推荐 / 已批准结论 |
|---|---|---|
| C1-A | RATIFIED | PO-only TestFlight 与公开候选分阶段；公开候选可以是修复后的新 build |
| C2-Core | RATIFIED | 批准 §3.1 的十项用户结果；具体时长、编码和 test ID 由下游 DRI 维护 |
| C2-Image | RATIFIED | 内容真相是用户确认裁剪 / 方向后的 App-managed 可读图片；不承诺来源原始字节 / 完整分辨率 |
| C2-Optional | RATIFIED | 除 Must 和单独批准实验外，optional 默认隐藏；逐 build manifest 只能缩小范围 |
| C2-Personalization | RATIFIED | Release 1 隐藏昵称、头像和座右铭；Review 目标、排序与提醒随 C4 |
| C3 | RATIFIED | Release 1 普通启动默认 Dashboard；任务枢纽，不批准当前卡片 / 五 Tab |
| C4-D | RATIFIED | Review 仅在非公开实验 build 由 Library 单一静态次级入口开放；证据只触发重新裁决 |
| C5-E | RATIFIED | SmartPaper 仅在非公开实验 build 可见；只要可见就不限次、无 Pro |
| C5-S1 | RATIFIED | SmartPaper 基础选择器是无权重、不重复随机抽取 |
| C6-A | RATIFIED | PO 批准公开风险政策与最终 go / no-go；具体证据计划由 QA / Release DRI 维护 |
| DATA-1 | RATIFIED | 明确外部兼容 epoch、本机升级与完整备份承诺；wire / journal 技术方案下沉 Data Contract |
| DATA-1-E | RATIFIED | Release 1 手动备份允许未加密，但分享前明确提示可能包含私人内容 |
| DATA-1-R | RATIFIED | 损坏 store 或恢复双失败后选择空库继续，事件材料不自动删；仅显式删除或成功“导出并删除”可清理 |

## 2. 目标产物

**RATIFIED C1-A**：采用三个必经证据阶段，并允许一个条件式 research 分支；不把首次 dogfood build 误当最终公开 build：

1. **PO-only 提名 / 上传**：每个 build 先冻结 `audience: po-only` 的 Capability Manifest，并取得独立上传授权；达到工程证据计划的内部基线后才上传。发现问题可以产生新 build，新 commit / build / manifest 即是新候选。
2. **PO-only 安装后 dogfood**：用真实 TestFlight 安装包验证核心价值链、数据安全、发布链路与 optional 是否值得继续；只形成产品和技术证据，不证明市场需求。
3. **公开候选**：另行提名最终 `audience: public-candidate` build。完整 C6 约束本地 archive、上传回执、ASC build、TestFlight 安装变体与 App Store submission 属于同一 build lineage，不要求 Apple 分发变体与本地 archive 字节相同；PO 再分别授权 go / no-go、上传、non-PO availability 和发布。PO-only build 的证据不能自动替代不同 ASC build 的结果证据。

**条件式 research 分支**：若在公开候选前向任何非 PO 自然人开放 build，先冻结 `audience: research` 候选并执行 research evidence plan，同时触发 DATA-1 定义的外部兼容 epoch。没有非 PO 研究者时可以跳过该分支。

任何让非 PO 自然人获得 build 下载资格的动作都必须事先取得 PO 明确的 **non-PO availability 授权**，并在对应 manifest 记录授权与实际开放时间。若流程违规但下载资格事实上已经开放，DATA-1 epoch 仍按事实触发，不能用缺少授权撤销已产生的数据权利。

## 3. Release 1 用户结果

Release 1 服务处理结构化纸张、照片或 PDF 材料的成年人。考试、职业认证、培训和成年人管理的家庭资料都是允许场景，但产品不把用户定义为学生、儿童、家长或教师，也不提供题目内容平台。

耐久承诺在本次发布中落实为：以最低摩擦，把真实材料变成一个可搜索、可整理、可打印且可手动备份的本地资料库。

### 3.1 Must outcomes

**RATIFIED C2-Core**：批准下列 M1-M10 用户结果。具体撤销时长、图片编码参数、命令、test ID、fault-injection 点和设备集合由 owning feature / Data / QA / Release DRI 维护，不随本项一并锁定。

**RATIFIED C2-Image**：保存内容真相是用户确认裁剪和方向后的 App-managed 可读图片；OCR 是辅助表达。Release 1 不承诺保留来源照片 / PDF 渲染页的原始字节或完整分辨率。工程可以选择编码与质量参数，但必须满足可读性、隐私和所有受支持资料库可完整备份的结果边界。

**RATIFIED C2-Optional**：§3.2 / §3.3 中除 Must 与单独批准实验外的能力默认隐藏；每个 audience/build 的 Capability Manifest 只能在合同允许范围内逐项 include，不能从现有代码反推范围。

**RATIFIED C2-Personalization**：Release 1 隐藏昵称、头像和座右铭等身份装饰。语言与外观是真实通用设置，不由本项移除；当前每日回顾目标、按回顾状态排序和 Review 提醒全部随 C4-D 隐藏，不由 C2 单独裁决。

1. 新用户无需注册、创建身份或选择资料空间即可开始使用。
2. 用户可以从相机 / 文档扫描、相册和 PDF 导入真实资料；内容真相与来源保留政策见 C2-Image。OCR 失败、不准确或不可用时仍可保存和人工修正。
3. 权限被拒绝、输入取消或 OCR 失败不会形成死路；至少存在一条仍可完成录入的替代路径。
4. 用户可以在唯一资料库中搜索、查看、编辑、分类和删除资料；不可逆删除前提供清楚、可测试的撤销机会，具体时长由 Library feature spec 维护。
5. 用户可以选择资料生成 PDF，并独立完成系统预览与打印；分享或保存是并列出口，不能替代打印验收。每条选定资料恰好出现一次，页数符合所选每页资料数，每条资料的主要图片或文字至少有一种可读内容，不得出现空白、遗漏或重复资料。取消或失败不得留下损坏或部分的 App-owned 输出；用户已明确保存到 App 外部的副本不承诺回滚。
6. 未保存采集被中断时，用户可以恢复或明确丢弃草稿；任何取消路径都不会留下不可理解的半成品。
7. 用户可以创建并恢复完整的手动可携带备份；损坏、超限或恶意备份失败时不崩溃、不穿越文件边界、不静默覆盖现有资料。
8. 本地 store 无法打开时，用户会看到可理解的恢复选择，可以从备份恢复，或在明确知情后以空资料库继续，而不是进入白屏或假空库。
9. 产品清楚说明本地存储、卸载丢失和手动备份责任；实际构建不会意外上传用户内容，公开隐私声明与数据流一致。
10. 所有 Must 旅程在 VoiceOver、受支持 Dynamic Type 和 Release 1 iPhone viewport 上可完成，不存在阻断性截断、遮挡或不可达操作。

### 3.2 输入与输出边界

| 能力 | Release 1 分类 | 结果边界 |
|---|---|---|
| 相机 / 文档扫描 | Must | 能形成可保存资料；设备或权限不支持时有替代路径 |
| 相册导入 | Must | 支持成年人整理既有扫描件、截图和家庭资料 |
| PDF 导入 | Must | 支持结构化纸张 / PDF 的首个工作流切口 |
| OCR | Must 的辅助能力 | 不得成为保存前置条件；C2-Core 明确支持印刷体简体中文与英文，识别结果可见、可编辑；不承诺手写、公式或题目答案准确率 |
| 手动录入、剪贴板、Share Extension | Candidate optional | 默认不从当前实现推导为可见；只有冻结清单明确纳入且通过数据、隐私、AX 和 S0/S1 门禁时才随候选交付 |
| PDF 导出、系统打印 / 分享 / 保存 | Must | 输出可用、失败可理解、取消无副作用 |
| JSON / CSV 导出 | Candidate optional | 作为可携带性辅助，不替代完整备份或 PDF 用户终点；只有冻结清单明确纳入才可见 |
| CSV 导入 | Candidate optional；当前 manifest 必须 hidden | GAP-R6 字段数量严格性修复及对应门禁完成前不可 include；是否修复属于实现排期，不由 C2 批准自动启动 |
| Word 导出、图片增强 | Hidden / out of scope | 不显示占位、锁态、价格或发布时间承诺 |

### 3.3 可见能力处置规则

当前实现不自动产生 Release 1 范围。除 Must 和本合同单独批准的实验外，其余表面默认隐藏，只有按 [Release 1 Capability Manifest](release-1-capability-manifest.md) 的版本化路径与 schema 生成的不可变冻结件逐项列为 `included`、满足对应门禁并随该 build 获得 PO 授权后才可见。

每个 manifest 必须声明 `audience: po-only | research | public-candidate`。`hidden` 表示该 build 对该能力**零入口、零激活、零副作用**：没有 Tab、Dashboard / Library / Onboarding / Settings 入口、通知 / 徽标、任何可由用户或系统触发的 deep link / App Intent / Shortcut / Spotlight / widget、状态恢复路径、可达 AX 元素或公开元数据；启动、后台、升级和遗留调度也不得执行该能力、写入其状态或产生网络 / 文件 / 数据副作用。不可达且不执行的代码可以保留。不同 commit、build、audience 或 capability set 都是新候选，旧 build 的证据不能无说明继承。

| 能力簇 | 默认处置 |
|---|---|
| 基础分类 / 标签的选择、搜索和过滤 | Must；支持一个资料库内的通用整理，不预设教育领域字段或孩子身份 |
| 自定义字段 / 动态维度管理 | Candidate optional；不得让首次采集依赖配置 |
| 批量打标签、批量删除 | Candidate optional；若纳入，部分失败必须给出结果摘要 |
| ShareCard | Hidden by default；不属于 PDF / 打印 Must |
| 去答案、留白、页眉页码、单条快速打印 | Candidate optional；基础多选 PDF / 系统打印不得依赖这些增强项 |
| 昵称、头像、座右铭 | Hidden；C2-Personalization 已批准隐藏，不把本地实现当保留理由 |
| 每日回顾目标、按回顾状态排序、Review 提醒 | Hidden；C4-D 的实验范围不包含这些表面，未来只有新裁决才可 include |
| Dashboard analytics、高级统计 | Hidden / out of scope |

Capability Manifest 是一次候选构建的实证附件，只能缩小本合同允许的范围，不能新增产品权威；`pre-freeze`、未列入或未经 PO build 授权均视为隐藏。Candidate optional 的缺陷不得破坏 Must 路径，任何 S0 / S1、隐私或 AX 阻断都会使该能力从候选移除或先修复，不能用“可选”豁免质量。

## 4. 启动与 Dashboard

**RATIFIED C3 — Dashboard 默认首屏。** 完成 onboarding 后的普通启动默认进入 Dashboard；显式 deep link 和阻塞性 store 恢复流程可以覆盖默认目的地。该 PO 裁决已锁定本候选中的 Dashboard-default；当本文成为 effective 时，它将成为 Release 1 正式契约，并 supersede 工作坊中“仅限内部 C1-A 实验、公开版本另行重选首页”的限制。生效后的 dogfood 仍可调整内容和布局，但不能静默改掉默认目的地。

Dashboard 是单一本地资料库的任务入口和可执行状态概览：

- 从 Dashboard 一次操作即可进入 Capture 和 Library；空资料库必须提供一次操作即可开始的 Capture 入口。
- 可以呈现未完成草稿、最近资料，以及能直接进入对应内容的本地事实；纯趋势、比较、完成率或行为统计不进入 Dashboard。
- Dashboard 不得暴露 Profile / Workspace、孩子账号、课程推荐、连续记录、积分、排名、Pro / IAP、锁定或 coming-soon 界面。
- Capture 与 Library 入口在视觉和 accessibility 内容顺序中必须先于任何 Review 入口；analytics 模块不得出现。Review 不得使用 hero、进度环、连续记录或完成庆祝占据核心入口层级。

本裁决不批准当前卡片、指标、排序、问候语、头像、五 Tab 结构或 Review 的导航等级。Dashboard 是否合格由上述可证伪行为判断，而不是由模块名称或截图相似度判断。

## 5. 可选复用能力

### 5.1 Review

**RATIFIED C4-D**：Review 只在 `po-only` 或 `research` 实验 build 通过 **Library 内一个静态次级入口**开放；无主 Tab、Dashboard cue / 计数、Onboarding 介绍、Settings 提醒 / 目标、通知 / 徽标或恢复到 Review 的隐式路径。暂停新增能力。公开候选默认完全不可达，保留不可达代码不等于 include。

Review 不得占据 Dashboard hero，不得把“今日完成”、连续记录或待办压力变成产品主叙事。形成性证据采用预登记完整 cohort：所有合格参与者在任务前登记，不得事后排除；`n >= 3`，每人完成三次核心闭环后，至少 `2/3` 在无提示下主动进入 Review，并能说明它解决了不同于查找 / 打印的任务。达到门槛只触发新的 PO shaping / ratification，不自动公开、不自动写入 public manifest，也不证明市场需求。

### 5.2 SmartPaper

**RATIFIED C5-E**：SmartPaper 只在 `po-only` 或 `research` 实验 build 通过 Library 内一个静态次级工具入口开放。Release 1 内只要可见，就不限次数，且无配额状态、entitlement、Pro、升级或 coming-soon 文案；这不承诺 Release 1 之后永久免费。公开候选默认完全不可达。

这项推荐不同于工作坊最初的 C5-B（完全隐藏）：[02g 非规范市场证据](audits/2026-07-repository/phases/02g-dashboard-market-evidence.md)和 Dashboard 任务枢纽裁决提高了“选择多份资料 -> 编排 -> 打印”作为成年人管理家庭资料场景的可用性验证价值，但不构成需求或教育定位证据。

**RATIFIED C5-S1**：基础 selector 只接受数量和可选的基础分类范围，从未删除的合格资料中无权重、不重复随机抽取 `min(N, eligible)`；禁止使用 Review / SM-2、难度、时间、内容或其他衍生排序。去答案、留白、页眉页码等 PDF 增强仍是独立 Candidate optional，不能由 SmartPaper include 顺带授权。

SmartPaper 域内“题 / 试卷 / 组卷”沿用 PO 2026-07-05 已批准的术语边界，不属于 C5 新裁决；通用 Dashboard、Library 与导出表面继续使用“资料 / 资料库”。ADR-001 Hybrid 已被 B6-A supersede，旧 3 次配额不再是当前商业权威。任何未来配额、定价或付费分层都必须重新经过 Gate A 商业裁决。

SmartPaper 的形成性证据同样使用预登记完整 cohort：`n >= 3`，不得事后排除；每位参与者先完成三次核心闭环，再观察无提示路径；至少 `2/3` 主动进入并完成真实多资料编排任务，且能说明它比 Library 多选 PDF 解决了不同问题。达到门槛只触发新的 PO 裁决，不自动公开。C4 与 C5 可使用同一预登记 cohort，但两个结果分别计算、分别裁决。

## 6. 数据与兼容边界

Release 1 只有一个用户可见的本地资料库，没有 SnapDrill 账户、Profile 或 Workspace。手动完整备份是永久用户权利；Apple 私有同步只是未来候选。

**RATIFIED DATA-1**：

1. **epoch 前**：只向 PO 本人开放的开发、真机或 TestFlight build，其本机数据、偏好及 v1 / v2 开发期备份可以被重置或明确拒绝，不承诺迁移。
2. **epoch 触发**：任何渠道首次让非 PO 自然人获得下载资格时触发，包括 research / external TestFlight、Ad Hoc 或交付给非 PO 的开发签名包；仅上传但尚未开放下载不触发。开放动作须先取得 C1 规定的 PO non-PO availability 授权；即使流程违规，实际开放仍触发 epoch。Capability Manifest 固定记录 source commit、渠道 artifact / ASC build identity、渠道、audience、授权、开放时间、Marketing Version、Build 和 Backup Schema。
3. **epoch 后本机升级**：App 更新必须保留用户已保存资料、主图 / 答案图、用户分类与关联、Review 状态，以及当前版本承诺支持的用户偏好；需要变形时提供内置迁移，不得假装空库或静默丢弃。
4. **epoch 后备份兼容**：每个正式分发 writer 生成、且符合其当时 effective wire contract 的完整备份，必须能由当前 App 直接恢复；格式转换可以作为 App 内恢复流程的实现细节，不能把 CLI、桌面工具或人工迁移作为普通用户唯一恢复路径。损坏、篡改或超出原格式合同的文件不在兼容承诺内。安全边界若需收紧，必须在 App 内保留旧 reader 或安全转换，不能让旧合法备份失效。
5. **外部分发前**：外部 backup wire 必须 Profile-free，并由 [backup-wire-format.md](backup-wire-format.md) 在独立 Data Contract 中冻结；旧 Profile v1 / v2 仅属 epoch 前开发格式，可被明确拒绝并给出可理解提示。

“完整备份”包含：已保存资料、主图 / 答案图、用户创建的分类 / 字段及关联、Review 状态，以及解释这些内容所必需的配置。它不包含未保存草稿、缓存、内部损坏-store / restore-journal 材料，也不要求携带设备本地的语言、外观、通知时间或诊断偏好；这些偏好在同设备 App 升级时仍受 DATA-1 第 3 项保护。

外部完整备份采用严格 all-or-nothing：任何必需图片或 metadata 缺失、损坏、非法或不一致，整包拒绝且现有资料库不变；不得把路径改成 `nil` 后声称完整恢复。损坏 store 的 salvage 是单独、明确标识的恢复路径，可以提取部分可恢复材料，但不得伪装成完整备份恢复。

**RATIFIED DATA-1-E（未加密备份）**：Release 1 的用户导出备份可以不设密码，以保持跨设备可恢复和避免密钥丢失；分享前必须明确提示文件可能包含私人文字与图片，由用户通过系统 share sheet / 文件选择器决定保存位置。未来加密格式需新的 privacy / Data Contract，并保留旧正式备份可恢复性。

**RATIFIED DATA-1-R（恢复材料保留）**：用户在损坏 store，或恢复的确定性前滚与回滚均无法完成（双失败）时选择“以空资料库继续”后，原始损坏材料、恢复前安全快照和解释失败所需的只读状态默认保留，直到用户在可见管理入口显式删除。用户可以先导出；只有明确选择“导出并删除”且导出成功，才同时终止本机保留。该选择不等于授权后台自动淘汰。未解决事件永不自动删除，正常 UI 也不得把这些材料伪装成可用资料库。

Release 1 必须让产品所支持创建的任意资料库都能生成一个同版可恢复的正式备份；writer 不得报告成功后再被同版 reader 拒绝。若单文件格式无法覆盖受支持规模，Data DRI 必须选择流式、分卷或其他可恢复方案，不能用未公开容量上限撤销永久备份权。

恶意 / 损坏输入、磁盘不足、进程中断、数据库与图片提交不同步或 store 打不开，均不得造成崩溃、越界读写、静默覆盖、假空库或不可理解的半恢复。用户看到的是可崩溃恢复的 all-or-nothing 结果或明确阻塞恢复态；具体 archive grammar、schema / key、资源 / 像素边界、validator / dependency、staging、journal phase、marker、启动协调与 fault injection 属于 Data / Security DRI，在 DATA-1 effective 后写入独立 Data Contract 与 DoR，不能从本节直接获得实现授权。

## 7. 明确非目标与隐藏能力

Release 1 不包含：

- SnapDrill 账户、多 Profile / Workspace、班级或亲子身份模型；
- 广告、IAP、StoreKit、Pro 配额、付费墙或未来能力预告；
- CloudKit / Apple 私有同步、开发者可访问的内容后端或第三方行为分析；
- Word 导出、高级统计、自动解题、答案搜索、课程 / 内容推荐；
- iPad 发行或中国大陆专项构建、账号、合规和元数据路线。

简体中文 UI 和成年人管理家庭资料属于全球 iPhone 版支持范围；它们不等于启动中国专项发行，也不授权把产品重新定义为儿童教育 App。

## 8. 结果级验收

**RATIFIED C6-A（发布风险政策）**：

1. 最终公开候选必须对 M1-M10 建立双向追溯：每个 Must 至少一个结果 oracle，每个纳入的测试 / dogfood 项都能指回 Must、effective policy 或 manifest capability；没有孤儿勾选项。
2. 最终公开候选的本地 archive、上传回执、App Store Connect build record、TestFlight 安装变体和 App Store 提交必须映射到同一 source commit、Marketing Version、Build 与 ASC build ID。Apple 重新签名、thinning 或 DRM 产生的安装变体不要求与本地 archive 共用 hash；Release DRI 分别记录本地 archive hash、上传回执和安装变体身份。PO-only / research build 可以更早且不同，但它们的绿色结果不能自动替代另一 ASC build 的完整证据。
3. 打印是 B3 的独立正式终点，必须通过真实系统预览与打印路径验证；分享或保存不能替代打印结果。
4. 按 [design-principles.md](../explanations/design-principles.md) 的 S0-S3：公开 go / no-go 时未解决 S0 / S1 为零；每个剩余 S2 都记录用户影响与缓解，并由 PO 明确接受。GitHub P0 / P1 标签只作排期信号。
5. 可达能力、公开文案、隐私声明、数据 / 网络行为、entitlements、Accessibility 与当前 binary 一致；hidden 能力满足 §3.3 的完全不可达定义。
6. 最终公开 go / no-go、上传、non-PO availability 和发布均由 PO 明确授权。构建成功、feature-status、代理输出或单一测试绿色都不能单独替代产品结果。

具体命令、设备 / 语言 / Dynamic Type 矩阵、test ID、fault-injection 点、隐私验证方法和附件路径属于 QA / Data / Security / Release DRI，维护在 [release-and-ci.md](../how-to/release-and-ci.md) 的可演进 evidence plan。该计划覆盖三个必经阶段和条件式 research 分支；工具链变化时记录实际环境。单一代理观察、单一测试或静态声明不能独立证明隐私 / 数据结果。

## 9. Dogfood 学习信号

内部试用采用主持式脚本和反馈记录，不新增后端遥测。证据至少回答：

- **Activation**：首次用户能否无人提示完成采集与保存，停在哪里？
- **Core utility**：稍后能否找回资料并得到可用 PDF / 打印结果？
- **Repeat value**：一周内是否会再次处理另一份真实材料？
- **Trust**：是否理解本地数据所有权、卸载风险和备份恢复？
- **Optional value**：完成核心链后是否主动寻找 Review 或 SmartPaper？
- **Quality**：是否出现崩溃、卡死、恢复失败或 accessibility 阻断？

内部 dogfood 证据可以改变后续 feature 与公开发布决策，但不能静默改写 Product Constitution；任何变更继续走五态生命周期。

## 10. 合同生效与退出条件

1. PO 已于 2026-07-13 批准 C3，并于 2026-07-14 批准其余 12 个精确决策 ID，摘要表全部 13 项均为 ratified。
2. 本文及必要 thin pointers 通过文档门禁和独立语义复核。
3. PR 合并获得 PO 单独授权并进入 `develop`；合并前仍是 ratified candidate。
4. 本合同同一 docs-only PR 同步对齐受 13 项裁决直接影响的产品说明、feature spec、结果 oracle、发布 evidence plan、术语与导航索引；这些改动用于移除旧规范冲突并建立追溯，不授权或包含代码、导航、schema / wire 实现。
5. Draft PR #868 只有在 DATA-1 effective、独立 Backup Wire / 单资料库可崩溃恢复 Data Contract 与对应 fixtures 纳入其 diff 或前置 PR 后，才具备重新申请合并的 DoR。
6. 本合同一经 effective，在新 Release Contract 或明确 supersession 合入前持续有效。
