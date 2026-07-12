---
id: feat-icloud-sync
title: Apple 私有同步（候选，商业分层未定）
status: backlog
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
intent_refs:
  - vision:P4
  - vision:P6
---

# Feature: Apple 私有同步（候选，商业分层未定）

> 人读摘要：📋 候选 backlog，产品范围与商业分层未定；旧 #485 不能自行授权重入。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> `mode: lightweight`（backlog）：仅 Why + What 必填；How / Verify 只记录当前已确认约束，未实现部分标注，不编造假设计。
> 本 spec 于 2026-05-30 从 vision / requirements / design / business / journeys / tech 聚合（docs 重组 B）。
>
> **商业规范偏差（2026-07-12）**：B4-A 只把 Apple 私有同步保留为独立假设，B6-A 已取代旧 Pro 分层，B7-A 也不包含 iPad；frontmatter 已改为 `tier: undecided`。新的 Product / Data / Privacy / Commercial contract 与 Release Contract 生效前不得实现或公开承诺。

## 1. 候选价值假设 (Why)

- Apple 私有同步可能减少用户在多设备或换机时的手动搬运，但当前没有外部需求或付费证据。
- B4-A 只允许把它保留为独立假设；它不能替代永久手动备份，也不能改变 local-first、无 SnapDrill 账户和一个资料库的定位。
- 若未来回归，必须重新通过产品、数据、隐私、CloudKit 可行性和商业 contract；B7-A 的 Release 1 不包含 iPad 或中国专项路线。

## 2. 候选范围与重入条件 (What)

- 候选只考虑 Apple 私有 CloudKit，不建立开发者可访问的内容后端，也不引入 SnapDrill 账户。
- 同步范围必须是一个资料库；冲突、删除、离线、空间不足、备份共存和退出后的数据权利均需新的 Data / Privacy Contract 明确。
- 手动备份 / 恢复始终保留为独立出口；同步异常不得锁定、隐藏或损坏本地资料。
- 当前无 Pro、StoreKit、价格或订阅取消规则；ADR-001 的商业分层和 iPad 闭环只作历史证据。
- 前置包括外部价值证据、PO 新裁决、CloudKit PoC、容器与签名配置、隐私复核、Release Contract 和完整同步测试；#485 只是技术 issue，不能自行授权实现。

## 3. 技术设计 (How)
> backlog：以下只记录当前关闭状态与候选技术边界；同步引擎细节等待新的 Product / Data / Privacy / Release Contract，**不在此编造假实现**。
- **当前实现状态**：所有 `@Model` 默认 `cloudKitDatabase: .none`（显式关闭）；旧 `ProEntitlementProvider` / Profile 相关路径仅是遗留代码背景。
- **启用路径**：未裁决。不得从旧 StoreKit、Profile 或 CloudKit issue 链推导未来架构。
- **State & Concurrency**（Swift 6 strict）：同步落库走 SwiftData `ModelContainer`（由 `DataExecutor` actor 拥有），重活不阻塞主线程；其余 actor/State 归属待解锁实现时定（PoC 阶段填）。
- **平台边界**：SwiftData 仅支持相关私有数据库能力；`#Unique` 与 CloudKit 的兼容约束仍需 PoC。中国专项路线不在 B7-A 当前范围。

## 4. 验证标准 (Verify)

> 当前不在 Release 1 范围，且生产配置显式关闭。新的 Product / Data / Privacy / Commercial / Release Contract 生效后再定义多设备 GWT、冲突策略、离线降级、延迟 SLO、退出行为和恢复演练；在此之前不得显示同步或升级入口。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P4 用户拥有数据·隐私 / P6 Apple 原生优先） | 同步基于系统级 CloudKit、Apple 加密、SnapDrill 不接触；不引入第三方同步层 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A）；`../../decisions/ADR-003-dual-region-release.md`（挂起历史） | 当前无有效 Pro 或区域同步承诺；手动备份永久免费 |
| 待验证假设 | `../../explanations/business-model.md` H7 | 先验证多设备价值，不预设付费理由 |
| 验收证据 | 新 contract 生效后补；当前 `cloudKitDatabase: .none` | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户 / P6 原生优先）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 商业假设：`../../explanations/business-model.md`
- 历史决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`、`../../decisions/ADR-003-dual-region-release.md`（均非当前实现授权）
- 免费迁移出口（互补）：`../active/feat-backup.md`（`.zip` 手动备份/恢复）
- 产品边界：`../active/feat-profile.md`（一个可见资料库）
