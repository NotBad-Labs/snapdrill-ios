# SnapDrill 项目状态看板

> 最后更新：2026-03-31
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：2 · Open Issue：3（全部外部阻塞）

---

## 当前焦点

全量审计修复已完成，Multi-Profile 设计方案已确定（独立数据库 / Vault 方式）。

| PR | 内容 | 状态 |
|---|---|---|
| #449 | CI 修复（swift test → xcodebuild test） | Open，CI pending |
| #450 | 审计修复（CSV 统一 + 帮助中心 #448 + 死代码清理） | Open，待 review |

## 下一步

| 优先级 | 事项 |
|---|---|
| P0 | Multi-Profile 实现（v1.0 必须，设计已完成，见 plan 文件） |
| P1 | PR #449 + #450 合并 |
| P1 | TestFlight Build 6（DocC 已确认，仅剩构建验证） |

## 产品决策记录

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-03-31 | Multi-Profile 采用独立数据库方案（Vault 方式） | 零查询改动、数据隔离彻底、备份天然 per-profile |
| 2026-03-30 | Multi-Profile 从 v1.5 提升到 v1.0 | Journey 5：无 Profile = 多孩家庭产品不可用 |
| 2026-03-30 | DocC 策略：v1.0 需要 | 项目规范化，现有 9 个 DocC 文件即满足 |
| 2026-03-30 | COPPA：效率工具定位，当前 Analytics 方案合理 | 不提供教育内容，非 "directed to children" |

## 外部阻塞

| Issue | 内容 | 解除条件 |
|---|---|---|
| #161 | TestFlight Build 6 | ~~DocC 策略确定~~ ✅ 已确认（2026-03-30） |
| #162 | GitHub Pro Branch Protection | 明天（4 月 1 日） |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
