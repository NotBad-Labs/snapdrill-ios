# SnapDrill 项目状态看板

> 最后更新：2026-03-31
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：1（#456 注释清理，待 Review） · Open Issue：3

---

## 当前焦点

PR #454 已合并：移除 #Unique 宏解决 CloudKit 真机崩溃 + 预发布 Schema 清理。

已合并：
- #454 fix: 移除 #Unique 宏解决 CloudKit 真机崩溃 + Schema V1 简化
- #451 Multi-Profile 完整实现（独立数据库 Vault 模式）
- #450 审计修复（CSV 统一 + 帮助中心 + 死代码清理）
- #449 CI 修复（swift test → xcodebuild test + build-for-testing）

待 Review：
- #456 chore: 清理 Schema V2/V3/V4 过期注释（纯注释变更）

## 下一步

| 优先级 | 事项 |
|---|---|
| P1 | TestFlight Build 6（所有功能已就绪，构建验证） |
| P1 | 真机测试 Multi-Profile（首次迁移 + 切换 + 新增/删除） |
| P2 | 导出/打印增强（去答案打印、留白答题区、页码页眉）— 见 #452 |
| P2 | 采集管线改进（OCR 失败重试、纯文本草稿保存）— 见 #452 |

## 产品决策记录

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-03-31 | SM-2 重新定位：从卡片复习 → 智能选题打印 | 家长打印 A4 纸给孩子练习，不让孩子用手机复习 |
| 2026-03-31 | 三基石修正：采集 + 存储 + 导出/打印（非 SM-2 复习） | 产品价值链终点是纸质练习卷 |
| 2026-03-31 | #Unique + CloudKit = fatalError | Simulator 不触发，真机必崩 |
| 2026-03-31 | Multi-Profile 采用独立数据库方案（Vault 方式） | 零查询改动、数据隔离彻底、备份天然 per-profile |
| 2026-03-30 | Multi-Profile 从 v1.5 提升到 v1.0 | Journey 5：无 Profile = 多孩家庭产品不可用 |

## 外部阻塞

| Issue | 内容 | 解除条件 |
|---|---|---|
| #162 | GitHub Pro Branch Protection | 明天（4 月 1 日） |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
