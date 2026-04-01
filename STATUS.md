# SnapDrill 项目状态看板

> 最后更新：2026-04-01
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：0 · Open Issue：4（#162 #163 外部阻塞，#161 等真机，#452 讨论存档）

---

## 当前焦点

v1.5 功能批量实现中，9/10 项已合并。仅剩 Share Extension。

已合并（v1.5 批次）：
- #476 feat: 删除撤销 — 软删除 + Toast 5 秒撤销
- #474 feat: 单题快速打印 + 每页题数可选 + 存储管理
- #472 feat: App 内语言切换 — 中文/英文直选
- #470 feat: 批量打标签
- #468 feat: 难度过滤
- #466 feat: OCR 结果复制到剪贴板
- #464 feat: 纯文本草稿保存

已合并（v1.0 批次）：
- #462 fix: 采集管线体验改进 — OCR 重试 + 稳定性提示 + 参数微调
- #460 fix: 相机权限缺失处理
- #458 feat: PDF 导出增强 — 去答案打印 + 留白答题区 + 页眉页码
- #456 chore: 清理 Schema V2/V3/V4 过期注释
- #454 fix: 移除 #Unique 宏解决 CloudKit 真机崩溃
- #451 Multi-Profile 完整实现
- #450 审计修复
- #449 CI 修复

## 下一步

| 优先级 | 事项 |
|---|---|
| P1 | Share Extension（v1.5 最后一项） |
| P1 | TestFlight Build 6 + 真机测试 |
| P2 | StoreKit / 付费墙（产品策略已确立，等用户验证） |
| P2 | iCloud 同步（Pro 付费功能） |

## 产品决策记录

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-04-01 | 定价：中国区 ¥8/月，美区 $1.99/月，Lifetime ¥298/$49.99 | 横向研究 Infuse/Bear/Craft 后确立 |
| 2026-04-01 | Grandfather 涨价策略 | Bear 模式：老用户保原价，涨价只影响新用户 |
| 2026-04-01 | v1.0 全免费发布 | 先积累口碑和用户基数 |
| 2026-04-01 | Multi-Profile 免费、导出/打印免费 | 基础可用性不应付费 |
| 2026-03-31 | SM-2 重新定位：智能选题打印（Pro 付费） | 进阶能力，需用户先完成练习闭环 |
| 2026-03-31 | 三基石修正：采集 + 存储 + 导出/打印 | 产品价值链终点是纸质练习卷 |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- STATUS.md 先更新再写 Xcode Review 提示词（两边共享状态）
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批

## 外部阻塞

| Issue | 内容 | 解除条件 |
|---|---|---|
| #162 | GitHub Pro Branch Protection | 今天（4 月 1 日） |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
