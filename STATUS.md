# SnapDrill 项目状态看板

> 最后更新：2026-03-25（PR #424 合并 — Diátaxis 重构 + Milestone 1 关闭 + Tag v1.0-doc-baseline）
>
> 每次新对话必读此文件恢复上下文。

---

## 当前状态

**Milestone 1「v1.0 架构与文档基线」已关闭。** 代码审计（3 轮）+ 文档审计（4 轮）+ Diátaxis 重构全部完成。Git tag `v1.0-doc-baseline` 标记当前基线。

DocC 覆盖率摸底完成：整体 75%（Core 55%、Infrastructure 21% 为薄弱点）。

### 优先级

1. 与 Xcode Intelligence 探讨 DocC 覆盖率策略
2. TestFlight Build 6

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | DocC 策略确定 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
