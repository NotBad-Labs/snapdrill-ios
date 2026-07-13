---
id: feat-onboarding
title: Onboarding 新手引导
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-14
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - ADR-002
  - positioning-and-audience
---

# Feature: Onboarding 新手引导

> **产品重基线（2026-07-14）**：Onboarding 必须服从 B1-A / B2-A 的首个切口与使命；不出现 Profile、Review、SmartPaper、Pro 或其他 optional 功能清单。C3 规定完成或跳过引导后普通启动进入 Dashboard；deep link 与阻塞恢复除外。当前四页流程仍是实现事实，具体页面与视觉调整需要独立授权。

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / journeys / onboarding 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户第一次打开 App 最容易被"先注册、先配置字段"挡在门外。Onboarding 应以最少页面讲清“把纸张、照片和 PDF 变成可搜索、可整理、可打印的个人资料库”，让处理结构化材料的成年人零学习成本开始采集第一项。
- **定位**：Onboarding 是**价值解释层**，不是配置层——快进不配置，只解释"是什么 / 怎么用 / 能做什么 / 隐私如何保护"，把字段选择等设置延后到用户使用过程中按需触发。同时承担 ASO 之外的预期管理：明确"归档工具"定位，避免用户误以为 App 提供题库 / 解题等内容。
- **原则归属**：P5 成人生产力工具（中性成熟语气、零学习曲线、不假设用户懂"SM-2"等概念）+ P4 数据属于用户（零注册、纯本地，作为信任建立的开场）+ P2 简洁（不强制首次配置）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **首次启动引导**：页数、顺序和具体文案由 owning UI slice 在合同边界内维护；内容必须解释使命、最低摩擦采集、整理 / 找回、导出 / 打印和 local-first，不得扩张为功能清单。
- **快进不配置**：Onboarding **不要求配置任何字段**，不要求填昵称 / 头像 / 学校 / 年级，不要求选学科（Apple HIG: "Avoid asking for setup information up front"）。
- **可跳过**：提供"开始使用"跳过按钮；语气成熟、面向成年用户，不幼稚不卡通。
- **单资料库无感就绪**：引导不创建、命名或选择 Profile；唯一资料库由系统内部准备，用户无需理解容器概念。
- **只展示一次**：完成后不再显示；完成状态为 App 全局状态。
- **结束动作**：进入 C3 规定的 Dashboard；deep link / 阻塞恢复例外及 Dashboard 行为见 Release 1 Contract。五栏 Tab 仍只是当前实现，不是本 spec 的产品要求。
- **字段配置延后**：只有冻结 manifest 纳入动态字段管理时，首次保存后才可按需提示；未纳入时不显示字段 TipKit。提示不按 Profile 建立用户可见语义。
- **边界 / 不做**：不请求通知权限，也不介绍 Review / SmartPaper；不在 Onboarding 中索取相机 / 相册权限（point-of-use 请求，进采集时才请求）；不播放视频教程；不做动画过渡特效；角色预设套件等模板入口不进 Onboarding。
- **前置依赖**：无。唯一资料库的内部初始化归数据 / composition root，不由 Onboarding 建立用户可见 Profile 生命周期。
- **商业政策**：B6-A 下 Onboarding 不嵌广告、IAP、Pro 引导或“即将推出”承诺。

## 3. 技术设计 (How)
- **模块归属**：`OnboardingView`（引导页）+ `OnboardingManager`（完成状态）位于 `SnapDrillUI`。`OnboardingManager` 在架构上是**显式豁免清单**成员（不挂 DI 容器，全局静态状态）。
- **关键机制 / 数据流**：当前实现为多页滑动引导 → "开始使用"或翻完末页 → `OnboardingManager` 标记完成 → 进入 Dashboard，与 C3 目的地一致。完成状态是 App 全局状态。现有 Profile / TipKit 隔离属于 B5-A 待退场实现。
- **State & Concurrency**（Swift 6 strict）：Onboarding 是纯展示流，无重活、无落库；完成标记走 `OnboardingManager` 全局状态，不经 `DataExecutor`，且不直接持有 `ModelContext`。
- **设计裁决**：`OnboardingManager` 列入静态 facade 豁免清单（全局静态状态，非 Profile-scoped），与 `TelemetryGate` / `ImageStorage` / `DependencyContainer.shared` 同属架构层显式豁免，不视为违反 DI 注入约定。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 用户首次启动 App，When 完成或跳过 Release 1 引导，Then `OnboardingManager` 标记完成并进入 Dashboard；全程不要求注册、Profile 选择、字段配置或提前索取权限。
- **边界 / 异常**：
  - 完成 Onboarding 后再次启动 → 不重新触发首次引导（完成状态全局）。
  - 进入采集页才触发相机权限请求；用户拒绝 → 不阻断主流程、不弹空白页，展示仍可用的相册 / PDF 路径 +「去设置开启」入口；文档扫描同样依赖相机权限，不得伪装成替代路径，手动入口仅在 manifest 纳入时出现（Boundary B14/B16）。
  - 空资料库（Onboarding 后无数据）→ Release 1 首屏显示明确空状态与采集入口，不显示脏数据（Boundary B17）。
- **数据保证**：Onboarding 完成状态只写一次且全局；流程不创建用户可见 Profile，不写入任何资料 / 图片记录。
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
- 相关 feature：`feat-profile.md`（单一本地资料库）、`feat-capture.md`（point-of-use 相机 / 相册权限请求 + 拒绝后降级路径）、`feat-settings.md`（字段配置延后入口 + 通知权限开关）
