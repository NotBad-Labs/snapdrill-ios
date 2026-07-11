---
id: feat-icloud-sync
title: iCloud 多设备同步
status: blocked
tier: pro
blocked_by: [485]
mode: lightweight
last_updated: 2026-05-30
intent_refs:
  - vision:P4
  - vision:P6
  - ADR-001
---

# Feature: iCloud 多设备同步

> 人读摘要：⛔ 阻塞（Pro）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> `mode: lightweight`（backlog）：仅 Why + What 必填；How / Verify 只记录当前已确认约束，未实现部分标注，不编造假设计。
> 本 spec 于 2026-05-30 从 vision / requirements / design / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：多设备场景下，纯本地存储无法跨设备流转——免费用户换机或卸载即数据永久丢失，只能靠手动 `.zip` 备份迁移。iCloud 同步打通「手机随时拍 + iPad 随时整理/复习 + 打印机随时印」的多设备闭环，让数据自动跨设备到位、换机后自动回来，无需手动操作。
- **定位**：iCloud 多设备实时同步是 **Pro 付费的核心引擎 / 核心卖点**——免费层是完整单设备闭环（采集→管理→导出/打印），付费层叠加跨设备流转。同步功能不单独售卖，与图片处理增强、高级导出等打包进 Pro 订阅，避免 App Store 审核指引 3.2.2 风险。
- **隐私边界**：同步完全基于系统级 CloudKit，数据由 Apple 加密存储在用户个人 iCloud 账户；SnapDrill 不接触、不存储、不可访问用户的 Apple ID 或 iCloud 数据。零注册 + 纯本地 + iCloud 的隐私架构在 Apple 生态内有系统级支撑。
- **原则归属**：P4 数据属于用户（隐私是核心差异化）+ P6 原生优先（同步必须用 Apple 原生 CloudKit，不引入第三方同步层）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **核心能力**：iCloud CloudKit 多设备同步（Pro）。同步范围为唯一资料库，基于 Apple CloudKit 与设备 Apple ID，无需单独注册。
- **冲突策略**：同一题在两设备同时编辑时，采用 last-write-wins + 冲突记录保留（CloudKit 默认行为），实现时细化。
- **iCloud 空间提示**：2000 题约 400MB，可能占满 5GB 免费 iCloud 空间；需在设置页提供空间占用与风险提示，保留手动备份/恢复作为降级出口。
- **边界 / 不做**：
  - 不做自建服务器同步（违反 P6 原生优先 + P4 隐私）。
  - 不单独售卖同步（打包进 Pro，规避审核 3.2.2）。
  - SwiftData 不原生支持 CloudKit 公共数据库，仅做私有数据库同步（无共享/公共数据）。
  - 配额计数等本地状态不跨设备同步。
- **前置依赖**：
  - StoreKit 闸门（#479）——Pro 解锁判断（`ProEntitlementProvider`）；
  - CloudKit Container（#485，需 Apple 开发者账号）；
  - `feat-local-library`（同步范围与 `.zip` 备份同为唯一资料库）。
- **商业分层**：iCloud 自动同步 = Pro；免费层不含自动同步，但必须可迁移（`.zip` 手动备份/恢复，见 `../active/feat-backup.md`）。订阅取消后数据完整保留可编辑，仅停止新数据跨设备 push（本机数据仍在），不锁定/不隐藏/不阻断手动备份。定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How)
> backlog / blocked：以下为当前已确认的设计意图；同步引擎细节（SLO、离线降级）解锁 #485 后补，**不在此编造假实现**。
- **当前实现状态**：所有 `@Model` 默认 `cloudKitDatabase: .none`（显式关闭）；StoreKit 未接（`ProEntitlementProvider.isProUser` 硬编码 false），首版纯免费、无法购买或测试。
- **模块归属**：同步随 SwiftData `@Model`（`SnapDrillData`）启用；Pro gating 经 `ProEntitlementProvider`；与 `BackupService` 同为唯一资料库边界。
- **启用路径**：StoreKit 落地（#479）→ 创建 CloudKit Container（#485）→ `ProEntitlementProvider` 判断 → 单一资料库同步。
- **State & Concurrency**（Swift 6 strict）：同步落库走 SwiftData `ModelContainer`（由 `DataExecutor` actor 拥有），重活不阻塞主线程；其余 actor/State 归属待解锁实现时定（PoC 阶段填）。
- **平台边界**：SwiftData 仅私有数据库同步；`#Unique` 与 CloudKit 不兼容（PR #454 已全量移除）。中国区 iCloud 由云上贵州运营、数据存境内，同步实现时做中国区专项性能测试。

## 4. 验证标准 (Verify)
> backlog / blocked：解锁 #485 后补完整 GWT 与 NFR（同步延迟 SLO、冲突策略、离线降级）。以下为多设备协作的目标主流程，非已实现验证。
- **Success path (GWT，目标态)**：Given 用户已订阅 Pro 且多设备登录同一 Apple ID，When 在 iPhone 录入资料，Then 资料通过 CloudKit 同步到其他设备的同一资料库。
- **边界 / 异常**：网络/CloudKit 暂时异常给重试或手动备份路径，不静默吞错；iCloud 空间不足时提示风险。
- **数据保证**：冲突策略与记录方式须在 PoC 后明确，不能直接把 CloudKit 默认行为写成产品保证。
- **NFR**：待实现补——同步延迟 SLO / 冲突策略细化 / 离线降级 依赖 #485 解锁后在 `../../reference/non-functional-requirements.md`§同步与网络 补齐（当前为占位）。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P4 用户拥有数据·隐私 / P6 Apple 原生优先） | 同步基于系统级 CloudKit、Apple 加密、SnapDrill 不接触；不引入第三方同步层 |
| 产品政策 / ADR | `../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层）；`../../decisions/ADR-003-dual-region-release.md`（区域 iCloud 差异，挂起的区域路线历史参考） | 同步打包进 Pro（规避审核 3.2.2）；免费层靠 `.zip` 迁移 |
| 待验证假设 | `../../explanations/business-model.md` H7（iCloud 同步是否足以成为 Pro 核心付费理由） | 解锁后验证 H7 |
| 验收证据 | 解锁 #485 后补；当前 `cloudKitDatabase: .none` | 见本 spec Verify 节（目标态） |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户 / P6 原生优先）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（多设备协作；本版本未单列该 Pro 旅程，参 旅程 4 资料库隔离 + 旅程 6 打印）
- 商业分层 / 定价：`../../explanations/business-model.md`
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层 Hybrid）、`../../decisions/ADR-003-dual-region-release.md`（双地区，中国区 iCloud 差异）
- 免费迁移出口（互补）：`../active/feat-backup.md`（`.zip` 手动备份/恢复）
- 同步范围依赖：`../active/feat-local-library.md`（唯一资料库）
