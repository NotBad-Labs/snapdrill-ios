# SnapDrill 项目状态看板

> 最后更新：2026-03-30
> 编译状态：✅ 0 errors · 0 lint violations
> Open PR：0 · Open Issue：3（全部外部阻塞）

---

## 当前焦点

全量文档审计完成（37 个自有 markdown 文件分类审查），产出三项产品决策：
1. **Multi-Profile 提升到 v1.0** — 旅程 5 证明多孩家庭必需
2. **COPPA 定位加固** — 明确效率工具定位，补充合规分析
3. **DocC 策略确认** — v1.0 需要，现有 9 个 DocC 文件覆盖所有 Package

CI 修复分支 `fix/ci-swift-test` 进行中（测试步骤改用 xcodebuild test）。

## 下一步

| 优先级 | 事项 |
|---|---|
| P1 | TestFlight Build 6（DocC 策略已确认，仅剩构建验证） |
| P1 | #440 维度 3+4（SwiftUI 架构最佳实践 + 竞品技术差距） |
| P2 | Multi-Profile 功能设计与实现（v1.0 新增，参考 Obsidian Vault 切换） |

## 产品决策记录

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-03-30 | Multi-Profile 从 v1.5 提���到 v1.0 | Journey 5：无 Profile = 多孩家庭产品不可用 |
| 2026-03-30 | DocC 策略：v1.0 需要 | 项目规范化，现有 9 个 DocC 文件即满足 |
| 2026-03-30 | COPPA：效率工具定位，当前 Analytics 方案合理 | 不提供教育内容，非 "directed to children" |

## 外部阻塞

| Issue | 内容 | 解除条件 |
|---|---|---|
| #161 | TestFlight Build 6 | ~~DocC 策略确定~~ ✅ 已确认（2026-03-30） |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
