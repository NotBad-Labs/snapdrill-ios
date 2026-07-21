---
id: feat-profile
title: 单一本地资料库（Multi-Profile 退场）
status: in-progress # 实证链：develop 仍是 Multi-Profile；#868 已关闭，需从最新 develop 分片收敛
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-16
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - positioning-and-audience
release_refs:
  - release-1:DATA-1
  - release-1:DATA-1-E
  - release-1:DATA-1-R
release_outcomes:
  - M1
  - M8
  - M10
---

# Feature: 单一本地资料库（Multi-Profile 退场）

> **产品重基线（2026-07-14）**：Product Constitution v1 的 B5-A 已批准用户只看到一个资料库，并在无外部证据前不规划 Workspace / Profile。frontmatter `status: in-progress` 表示当前 `develop` 仍有 Multi-Profile 实现；已关闭的 #868 只保留为历史实现与风险证据，不是恢复、重开或合并路径。
>
> Release 1 Contract DATA-1 已固定过渡边界：仅 PO 的 epoch 前开发数据 / v1-v2 备份无需迁移；任何非 PO 下载资格触发兼容 epoch；对外 wire 必须 Profile-free。[Local Library Data Contract](../../reference/local-library-data-contract.md) 固定路径、inventory、恢复 journal 与 Profile-free runtime 边界；外部 DDL 仍由 Backup Wire Contract 单独获批。合同生效不自动授权任何代码实现或合并。

## 1. 为什么做 (Why)

- 当前没有外部用户证据证明同一设备需要多个独立资料库；Multi-Profile 增加了首启、导航、设置、偏好、备份、恢复和测试复杂度。
- 一个本地资料库足以支持用户通过搜索、基础分类和标签整理不同主题，同时保持采集 -> 整理 / 找回 -> 导出 / 打印的主路径清晰；动态字段只是可选增强，不是移除 Multi-Profile 的成立前提。
- 这是中等置信度、可重新裁决的产品假设，不是对未来内部架构的永久禁令。只有外部证据、PO 新裁决和新的 effective 权威才能让 Workspace / Profile 回归。

## 2. 产品规则 (What)

- **一个可见资料库**：用户无需创建、命名、选择、切换或删除 Profile；所有用户可见资料属于同一个本地资料库。
- **不规划 Workspace / Profile**：在新证据出现前，不新增资料库切换、独立工作区、家庭成员账户或相关设置入口。
- **内容靠基础整理能力组织**：多个主题通过资料库内的搜索、基础分类和标签表达，不通过顶层容器分割；动态字段只有在冻结 manifest 纳入时才可见。
- **无 SnapDrill 账户**：单资料库不引入注册、身份、权限或儿童账户模型。
- **数据权利不退化**：B4-A 的手动备份 / 恢复、导出、删除与数据可携带承诺保持有效，不能因移除 Profile 而削弱。
- **迁移边界**：仅 PO 的 epoch 前开发数据、偏好及 v1 / v2 备份可以重置或明确拒绝；一旦非 PO 获得 build 下载资格，本机升级与正式备份兼容承诺立即生效。对外 wire 必须 Profile-free；本地生命周期与恢复安全边界以 [Local Library Data Contract](../../reference/local-library-data-contract.md) 为准，wire / golden fixture 以 Backup Wire Contract 为准。
- **实现中立**：是否保留内部 scope 类型、如何简化目录或 UserDefaults、是否迁移备份 schema，均属于工程设计，不能改变上述用户可见行为。

## 3. 当前实现与候选 (How)

- 当前 `develop` 仍由 `ProfileManager` 管理多个 SwiftData container、图片目录和 per-profile preferences；Profile 创建 / 切换 / 删除入口仍存在。这些是实证事实，也是待移除的复杂度，不是产品依据。
- #868 已关闭且与当前基线冲突，只保留为影响分析和测试思路的历史证据。生产收敛必须从最新 `develop` 出发，按当前 Product / Release / Data Contract 拆成可验证的小切片。
- 在精确 Backup Wire Contract 与对应实现授权前，不应从 #868 搬运 backup schema、golden fixtures、MigrationPlan 或恢复策略。

## 4. 验证标准 (Verify)

Release 1 的产品验收如下；备份 / 恢复技术 oracle 由 DATA-1 下游 Data Contract 补足：

- 用户从首启到日常使用都不会看到 Profile / Workspace 的创建、切换、删除或命名流程。
- 采集、资料库、搜索、整理、导出、打印、设置和手动备份均直接作用于同一个本地资料库；被 manifest 纳入的 Review / SmartPaper 实验也只能读取该资料库。
- 不存在“至少保留一个 Profile”、当前 Profile 头像、跨 Profile 切换阻塞等用户可见文案或交互。
- 不同主题仍可在一个资料库内通过字段与搜索区分；移除 Profile 不得删除核心分类 / 标签能力。
- 手动备份 / 恢复继续可用；恢复失败保持原数据不变。路径、generation 与 D3-B oracle 由 Local Library Data Contract 验证；wire 兼容范围由 Backup Wire Contract 验证，不在本 spec 复制。
- 代码、UI 测试和 AX 审计不得把内部遗留标识符误当成用户可见产品概念；是否保留程序标识符由实现 slice 决定。

## 5. Contracts（退场边界）

### A. 产品行为

- Release 1 只呈现一个资料库，不保留隐藏的 Profile 管理入口或“稍后推出多个资料库”提示。
- 未来 Workspace / Profile 只能通过新的产品证据、PO 裁决和 effective 上游权威重新进入。

### B. 数据安全

- “无生产 / 内测用户需要迁移”只免除用户数据迁移需求，不免除备份恢复、路径安全、原子性和失败回滚验证。
- backup wire、schemaVersion、golden fixtures 和 MigrationPlan 的任何变化必须由 owning Data Contract 明确授权；单资料库实现不得绕过 `local-library-data-contract.md` 的 generation / incident 状态。

### C. Enforcement

| 契约项 | Enforcement |
|---|---|
| 单一用户可见资料库 | L10n / SwiftUI grep + UI dogfood + UI tests |
| 无 Profile 管理入口 | 导航审计 + AX 审计 |
| 字段整理能力保留 | Library targeted tests + dogfood |
| 备份安全不退化 | Backup contract tests + golden fixtures + restore rollback tests |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Product Constitution | `../../explanations/vision.md`（B4-A / B5-A；P2 / P4 / P5） | 一个可见资料库、无账户、数据权利不退化、无证据前不规划 Workspace / Profile |
| 定位 | `../../explanations/positioning-and-audience.md` | 通用成人效率工具，不建立儿童 / 家庭成员账户体系 |
| 待验证假设 | `../../explanations/assumptions.md` H12 | 单资料库能否覆盖首个切口；以 TestFlight / dogfood 证据重新评估 |
| Release 1 Contract | `../../reference/release-1-contract.md` DATA-1 / DATA-1-E / DATA-1-R | epoch、Profile-free 外部 wire、完整备份与恢复材料保留边界 |
| Data Contract | `../../reference/local-library-data-contract.md` | 单一 runtime、路径 / inventory、generation / journal、incident 与 D3-B oracle |
| 验收证据 | §4 产品验收 + owning Data Contracts | 不把当前代码或 Draft PR 当成产品 oracle |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联

- Product Constitution：`../../explanations/vision.md`
- 当前实现状态：`../../reference/feature-status.md`
- 代表旅程：`../../explanations/user-journeys.md`（旅程 4：单资料库管理多个主题）
- 历史实现证据：已关闭 PR #868（不得重开、rebase 或合并）
- 数据出口：`feat-backup.md`、`feat-export.md`
- 本地数据契约：`../../reference/local-library-data-contract.md`
