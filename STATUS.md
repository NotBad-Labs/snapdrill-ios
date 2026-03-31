# SnapDrill 项目状态看板

> 最后更新：2026-04-01
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：0 · Open Issue：2（全部外部阻塞）

---

## 当前焦点

v1.0 功能开发 + 采集管线改进全部完成，等待 TestFlight Build 6 + 真机测试。

已合并：
- #462 fix: 采集管线体验改进 — OCR 重试 + 稳定性提示 + 参数微调
- #460 fix: 相机权限缺失处理 — 拒绝/受限时引导用户开启
- #458 feat: PDF 导出增强 — 去答案打印 + 留白答题区 + 页眉页码
- #456 chore: 清理 Schema V2/V3/V4 过期注释
- #454 fix: 移除 #Unique 宏解决 CloudKit 真机崩溃 + Schema V1 简化
- #451 Multi-Profile 完整实现（独立数据库 Vault 模式）
- #450 审计修复（CSV 统一 + 帮助中心 + 死代码清理）
- #449 CI 修复（swift test → xcodebuild test + build-for-testing）

## 下一步

| 优先级 | 事项 |
|---|---|
| P1 | TestFlight Build 6（所有功能已就绪，构建验证） |
| P1 | 真机测试：Multi-Profile + PDF 导出增强 + 相机权限 + OCR 重试 |
| P2 | 纯文本草稿保存（已有 TODO，CaptureDraftService 扩展）— 见 #452 |
| P3 | SM-2 驱动「生成复习卷」功能设计 — 见 #452 |

## 产品决策记录

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-03-31 | PDF 导出默认隐藏答案 + 显示答题留白区 | 家长打印给孩子重做，带答案废了 |
| 2026-03-31 | SM-2 重新定位：从卡片复习 → 智能选题打印 | 家长打印 A4 纸给孩子练习，不让孩子用手机复习 |
| 2026-03-31 | 三基石修正：采集 + 存储 + 导出/打印（非 SM-2 复习） | 产品价值链终点是纸质练习卷 |
| 2026-03-31 | #Unique + CloudKit = fatalError | Simulator 不触发，真机必崩 |
| 2026-03-31 | Multi-Profile 采用独立数据库方案（Vault 方式） | 零查询改动、数据隔离彻底、备份天然 per-profile |

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
