# SnapDrill 项目状态看板

> 最后更新：2026-03-31
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：0 · Open Issue：2（全部外部阻塞）

---

## 当前焦点

Multi-Profile、审计修复、CI 修复三个 PR 已全部合并到 develop。

已合并：
- #449 CI 修复（swift test → xcodebuild test + build-for-testing）
- #450 审计修复（CSV 统一 + 帮助中心 #448 + DataError 死代码清理 + 术语矛盾修复）
- #451 Multi-Profile 完整实现（独立数据库 Vault 模式）

## 下一步

| 优先级 | 事项 |
|---|---|
| P1 | TestFlight Build 6（所有功能已就绪，构建验证） |
| P1 | 真机测试 Multi-Profile（首次迁移 + 切换 + 新增/删除） |

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
| #162 | GitHub Pro Branch Protection | 明天（4 月 1 日） |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
