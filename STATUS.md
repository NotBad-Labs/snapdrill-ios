# SnapDrill 项目状态看板

> 最后更新：2026-04-13
> 编译状态：✅ 0 errors · 0 lint violations · CI 全绿
> Open PR：0 · Open Issue：7

---

## 当前状态

项目主权重组完成（2026-04-13）。文档体系精简（80→68 文件），工程哲学扩展到 7 条原则，skills 精简到 6 个。
三方基线审计 Layer 0-3 全部完成，ADR 系统已建立（ADR-001 Hybrid 定价 + ADR-002 删除 ATT）。

**功能开发被 Apple 开发者账号阻塞。**

### 阻塞链

| Issue | 内容 | 阻塞原因 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | Enrollment 已提交（ID: 83VZW7VJKK），等 Apple 审核 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 ← #163 |
| #485 | iCloud CloudKit 同步 | 需 CloudKit Container + StoreKit ← #163 |
| #486 | Word 导出 | 需 StoreKit ← #163 |
| #490 | App Store 提交准备 | 需公司账号 + 真机验证 ← #163 |
| #161 | TestFlight Build 6 | 需真机验证 ← #163 |

### 其他 Open Issue

| Issue | 内容 |
|---|---|
| #540 | Claude Code hooks 扩展（S2，待排期） |

### 待清理

- 113 个历史分支待清理（基线重置后无意义）

## 产品决策记录

> 决策通过 ADR 管理（`docs/decisions/`），此表为索引。

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | [ADR-002](docs/decisions/ADR-002-remove-att-authorization.md) |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | [ADR-001](docs/decisions/ADR-001-smart-paper-analytics-pricing.md) |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- 写 Xcode Review 提示词前，确认 STATUS.md 当前焦点段是最新的
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
