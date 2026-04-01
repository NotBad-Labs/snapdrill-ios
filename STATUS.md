# SnapDrill 项目状态看板

> 最后更新：2026-04-01
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：0 · Open Issue：4（#162 #163 外部阻塞，#161 等真机，#452 讨论存档）

---

## 当前焦点

v1.5 功能批量实现中，12 个 PR 已合并。仅剩 Share Extension。

### 已完成（v1.5 批次，12 个 PR）

- #476 feat: 删除撤销 — 软删除 + Toast 5 秒撤销
- #474 feat: 单题快速打印 + 每页题数可选 + 存储管理
- #472 feat: App 内语言切换 — 中文/英文直选
- #470 feat: 批量打标签
- #468 feat: 难度过滤
- #466 feat: OCR 结果复制到剪贴板
- #464 feat: 纯文本草稿保存
- #462 fix: 采集管线体验改进 — OCR 重试 + 稳定性提示 + 参数微调
- #460 fix: 相机权限缺失处理
- #458 feat: PDF 导出增强 — 去答案打印 + 留白答题区 + 页眉页码
- #456 chore: 清理 Schema V2/V3/V4 过期注释
- #454 fix: 移除 #Unique 宏解决 CloudKit 真机崩溃
- 商业化策略 + 免费/付费分层文档

### 已完成（v1.0 批次）

- #451 Multi-Profile 完整实现
- #450 审计修复
- #449 CI 修复

## 下一步

### 待做（不依赖外部，1 项）

| 优先级 | 事项 | 备注 |
|---|---|---|
| P1 | Share Extension | 需用户在 Xcode 创建 target 后写代码 |

### 待做（依赖外部条件，3 项）

| Issue | 内容 | 解除条件 |
|---|---|---|
| #161 | TestFlight Build 6 | 需真机验证 |
| #162 | GitHub Pro Branch Protection | 等 GitHub Pro 今天生效 |
| #163 | 公司 Apple 开发者账号 | 等 DUNS 就绪 |

### 暂缓（产品策略已定，等用户验证后实施）

| 事项 | 定位 |
|---|---|
| StoreKit / 付费墙 | v1.0 全免费，验证后实施 |
| iCloud 同步 | Pro 付费功能 |
| Word 导出 | Pro 付费功能 |
| SM-2 智能组卷 | Pro 付费功能 |
| 探索性 PoC（Foundation Models / App Intents） | 技术预研 |

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

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
