---
id: feat-onboarding
title: Onboarding 新手引导
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-19
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - ADR-002
  - positioning-and-audience
---

# Feature: Onboarding 新手引导

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / journeys / onboarding 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户第一次打开 App 最容易被"先注册、先配置字段"挡在门外。Onboarding 只用几页讲清"这是一个采集、归档、整理任何题目与文档的工具"的价值，让不熟悉专业扫描 / 归档工具的成年用户零学习成本就敢开始录第一项。
- **定位**：Onboarding 是**价值解释层**，不是配置层——快进不配置，只解释"是什么 / 怎么用 / 能做什么 / 隐私如何保护"，把字段选择等设置延后到用户使用过程中按需触发。同时承担 ASO 之外的预期管理：明确"归档工具"定位，避免用户误以为 App 提供题库 / 解题等内容。
- **原则归属**：P5 成人生产力工具（中性成熟语气、零学习曲线、不假设用户懂"SM-2"等概念）+ P4 数据属于用户（零注册、纯本地，作为信任建立的开场）+ P2 简洁（不强制首次配置）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **首次启动多页引导**：~3-4 页，每页一个核心概念，滑动翻页，介绍核心功能与定位（是什么 / 怎么录题 / 存下来能做什么 / 隐私保护）。
- **快进不配置**：Onboarding **不要求配置任何字段**，不要求填昵称 / 头像 / 学校 / 年级，不要求选学科（Apple HIG: "Avoid asking for setup information up front"）。
- **可跳过**：提供"开始使用"跳过按钮；语气成熟、面向成年用户，不幼稚不卡通。
- **首个 Profile 自动创建**：首次启动时系统自动创建默认 Profile，用户无感（见 `feat-profile.md`）。
- **只展示一次**：完成后不再显示；**完成状态为全局**，不因切换 Profile 重新触发。
- **结束动作**：直接进入主界面（Dashboard）——一个已创建好的默认 Profile + 空 Dashboard（展示空状态引导）+ 底部 Tab（首页 / 题库 / 采集 / 复习 / 设置）。
- **字段配置延后**：首次录入保存后，才通过引导提示「要不要开启更多字段（难度 / 来源等）？」触发；非首次启动。后续 TipKit 提示（首次进采集 / 首次进过滤 / 首次进复习）也在使用过程中触发，按 Profile 隔离。
- **边界 / 不做**：不弹通知权限请求（仅在用户主动开启提醒开关时才触发系统弹窗）；不在 Onboarding 中索取相机 / 相册权限（point-of-use 请求，进采集时才请求）；不播放视频教程；不做动画过渡特效；角色预设套件等模板入口不进 Onboarding。
- **前置依赖**：无（首个 Profile 由 `feat-profile.md` 在 Onboarding 期间自动创建，属同生命周期协作而非阻塞依赖）。
- **商业分层**：免费。Onboarding 全程不嵌广告、不做 Pro 引导。

## 3. 技术设计 (How)
- **模块归属**：`OnboardingView`（引导页）+ `OnboardingManager`（完成状态）位于 `SnapDrillUI`。`OnboardingManager` 在架构上是**显式豁免清单**成员（不挂 DI 容器，全局静态状态）。
- **关键机制 / 数据流**：多页滑动引导 → "开始使用"或翻完末页 → `OnboardingManager` 标记完成 → 进入 Dashboard。Onboarding 完成状态是**全局**状态（与 VoiceOver / 辅助功能同类），不随 `ProfileManager` 切换 Profile 而重置；与之相对，TipKit tooltip 状态按 Profile 隔离（每个资料库各自看一次新功能引导，由 `ProfileTipState` 管理）。后续字段引导用 Alert（首次保存后），功能 tooltip 用 TipKit。
- **State & Concurrency**（Swift 6 strict）：Onboarding 是纯展示流，无重活、无落库——完成标记走 `OnboardingManager` 全局状态，不经 `DataExecutor`；首个默认 Profile 的创建由 `ProfileManager` 负责（详见 `feat-profile.md`，其 ModelContainer 重建在该模块内处理），Onboarding 本身不直接持有 `ModelContext`。
- **设计裁决**：`OnboardingManager` 列入静态 facade 豁免清单（全局静态状态，非 Profile-scoped），与 `TelemetryGate` / `ImageStorage` / `DependencyContainer.shared` 同属架构层显式豁免，不视为违反 DI 注入约定。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 用户首次启动 App（设备无任何 Profile），When 系统自动创建默认 Profile 并展示 ~3-4 页引导、用户翻完或点"开始使用"，Then `OnboardingManager` 标记完成并进入 Dashboard（已有默认 Profile + 空状态引导 + 底部 Tab），全程不要求注册 / 不要求配置字段 / 不索取权限。
- **边界 / 异常**：
  - 完成 Onboarding 后切换 Profile → 不重新触发首次引导（完成状态全局）。
  - 进入采集页才触发相机权限请求；用户拒绝 → 不阻断主流程、不弹空白页，展示降级引导（相册导入 / 文档扫描 / 手动编辑）+「去设置开启」入口（Boundary B14/B16）。
  - 用户主动开启提醒开关后系统已拒绝通知权限 → 提示权限已被拒绝并引导跳转系统设置（Boundary B21）。
  - 空题库（Onboarding 后无数据）→ Dashboard 显示空状态 + 采集入口引导，不显示脏数据（Boundary B17）。
- **数据保证**：Onboarding 完成状态只写一次且全局，不随 Profile 切换被清除；首个默认 Profile 创建后不复制任何其他数据；Onboarding 流程不写入任何题目 / 图片记录。
- **NFR**：无（纯展示流，无大图加载 / 无落库 / 无中断恢复要求）。


## 5. Contracts（首启 / 权限预期 / 文案定位）

### A. 首启流程

- Onboarding 只解释产品价值和本地隐私边界，不在首屏直接请求相机、相册或通知权限。
- 用户完成或跳过 Onboarding 后，状态必须持久化；后续再次进入不得重复打断，除非用户显式重置。
- 完成、跳过、返回每个动作都应有清晰可达路径，不把用户困在单页引导中。

### B. 权限预期

- 相机、相册、文件导入等权限请求应在 Capture 等 point-of-use 场景触发；Onboarding 只能做预期说明。
- 权限预说明必须与系统权限用途串一致，不能承诺未实现的云同步、账号、自动备份或 AI 解题能力。

### C. 文案定位与 L10n 归属

- Onboarding 对外文案必须面向通用效率工具，避免“错题/作业/儿童/年级/同学”等儿童教育信号。
- 已知共享 key：`L10n.Onboarding.fieldConfigTitle` / `fieldConfigDescription` 被 Capture 结果页和提示视图复用。后续应迁入 Common/Shared 或显式登记共享，不应长期挂在 Onboarding 命名空间。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| 首启不提前请求权限 | 模拟器实测 / UI test |
| 完成/跳过持久化 | 现有 Onboarding 状态测试或手动复验 |
| 文案通用受众 | Onboarding L10n grep gate + PO review |
| 权限预说明一致 | PR review + InfoPlist/L10n 对照 |
| 共享 L10n 归属 | 批量 L10n 归属整理 PR |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P4 用户拥有数据 / P5 成人生产力工具） | 快进不配置、零注册纯本地、中性成熟不挡门外 |
| 产品政策 / ADR | `../../decisions/ADR-002-remove-att-authorization.md`（ATT 已移除）；`../../explanations/positioning-and-audience.md`（通用受众预期管理） | Onboarding 不索取追踪授权 / 不预期儿童；明确"归档工具"定位 |
| 待验证假设 | `../../explanations/assumptions.md` H1（首次能完成采集与保存） | Onboarding 不阻挡首次达成 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P4 数据属于用户 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 1：首次采集与保存）
- 决策：`../../decisions/ADR-002-remove-att-authorization.md`（ATT 已移除，Onboarding 不索取追踪授权）
- 相关 feature：`feat-profile.md`（首个默认 Profile 自动创建 + Onboarding 完成状态全局不随切换重置）、`feat-capture.md`（point-of-use 相机 / 相册权限请求 + 拒绝后降级路径）、`feat-settings.md`（字段配置延后入口 + 通知权限开关）
