---
id: feat-profile
title: 单一本地资料库（Multi-Profile 退场）
status: in-progress # 实证链：develop 仍是 Multi-Profile，Draft PR #868 尚未获合并授权
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-12
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - positioning-and-audience
---

# Feature: 单一本地资料库（Multi-Profile 退场）

> **产品重基线（2026-07-12）**：Product Constitution v1 的 B5-A 已批准用户只看到一个资料库，并在无外部证据前不规划 Workspace / Profile。frontmatter `status: in-progress` 表示当前 `develop` 仍有 Multi-Profile 实现、Draft PR #868 是待重审候选；它不代表该 PR 已获合并授权。
>
> 本 spec 只固化 B5-A 可直接推导的产品行为与退场约束。数据 / backup wire 的过渡细节、最终实现方式和 Release 1 验收仍须由 Gate C / Release 1 Product Contract 承接。

## 1. 为什么做 (Why)

- 当前没有外部用户证据证明同一设备需要多个独立资料库；Multi-Profile 增加了首启、导航、设置、偏好、备份、恢复和测试复杂度。
- 一个本地资料库足以支持用户通过分类、来源、级别、标签和自定义字段整理不同主题，同时保持采集 -> 整理 / 找回 -> 导出 / 打印的主路径清晰。
- 这是中等置信度、可重新裁决的产品假设，不是对未来内部架构的永久禁令。只有外部证据、PO 新裁决和新的 effective 权威才能让 Workspace / Profile 回归。

## 2. 产品规则 (What)

- **一个可见资料库**：用户无需创建、命名、选择、切换或删除 Profile；所有用户可见资料属于同一个本地资料库。
- **不规划 Workspace / Profile**：在新证据出现前，不新增资料库切换、独立工作区、家庭成员账户或相关设置入口。
- **内容靠字段整理**：多个主题通过资料库内的搜索、分类、来源、级别、标签和自定义字段表达，不通过顶层容器分割。
- **无 SnapDrill 账户**：单资料库不引入注册、身份、权限或儿童账户模型。
- **数据权利不退化**：B4-A 的手动备份 / 恢复、导出、删除与数据可携带承诺保持有效，不能因移除 Profile 而削弱。
- **迁移边界**：PO 已确认项目没有需要保留的生产 / 内测 Multi-Profile 用户数据，因此旧开发数据迁移不是产品要求；但现有 backup wire、golden fixture 与恢复安全边界必须先由独立 Data / Release Contract 明确，不能从“无用户”推导为可任意破坏恢复逻辑。
- **实现中立**：是否保留内部 scope 类型、如何简化目录或 UserDefaults、是否迁移备份 schema，均属于工程设计，不能改变上述用户可见行为。

## 3. 当前实现与候选 (How)

- 当前 `develop` 仍由 `ProfileManager` 管理多个 SwiftData container、图片目录和 per-profile preferences；Profile 创建 / 切换 / 删除入口仍存在。这些是实证事实，也是待移除的复杂度，不是产品依据。
- Draft PR #868 是单资料库实现候选。Product Constitution 合入后仍须依据 Release 1 Product Contract 和 Data Contract 重新审查其 scope、wire 兼容、安全测试与 UI 清理，运维窗口只有在 PO 单独授权后才能合并。
- 在新 contract 生效前，不应为了提前迎合 #868 而修改 backup schema、golden fixtures、MigrationPlan 或恢复安全保证。

## 4. 验证标准 (Verify)

Release 1 的完整 GWT 等待 Gate C。B5-A 已确定的最低产品验收如下：

- 用户从首启到日常使用都不会看到 Profile / Workspace 的创建、切换、删除或命名流程。
- 采集、资料库、搜索、整理、回顾、导出、打印、设置和手动备份均直接作用于同一个本地资料库。
- 不存在“至少保留一个 Profile”、当前 Profile 头像、跨 Profile 切换阻塞等用户可见文案或交互。
- 不同主题仍可在一个资料库内通过字段与搜索区分；移除 Profile 不得删除核心分类 / 标签能力。
- 手动备份 / 恢复继续可用；恢复失败保持原数据不变。wire 兼容范围按后续 Data Contract 验证，不在本 spec 猜测。
- 代码、UI 测试和 AX 审计不得把内部遗留标识符误当成用户可见产品概念；是否保留程序标识符由实现 slice 决定。

## 5. Contracts（退场边界）

### A. 产品行为

- Release 1 只呈现一个资料库，不保留隐藏的 Profile 管理入口或“稍后推出多个资料库”提示。
- 未来 Workspace / Profile 只能通过新的产品证据、PO 裁决和 effective 上游权威重新进入。

### B. 数据安全

- “无生产 / 内测用户需要迁移”只免除用户数据迁移需求，不免除备份恢复、路径安全、原子性和失败回滚验证。
- backup wire、schemaVersion、golden fixtures 和 MigrationPlan 的任何变化必须由独立 Data Contract 明确授权。

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
| 验收证据 | §4 最低产品验收；完整 GWT 等待 Release 1 Product Contract | 不把当前代码或 Draft PR 当成产品 oracle |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联

- Product Constitution：`../../explanations/vision.md`
- 当前实现状态：`../../reference/feature-status.md`
- 代表旅程：`../../explanations/user-journeys.md`（旅程 4：单资料库管理多个主题）
- 候选实现：Draft PR #868（等待 contract 重审与 PO 单独合并授权）
- 数据出口：`feat-backup.md`、`feat-export.md`
