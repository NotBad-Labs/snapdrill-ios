# SnapDrill 项目状态看板

> 最后更新：2026-03-25（文档体系 Diátaxis 重构，PR 待 review）
>
> 每次新对话必读此文件恢复上下文。

---

## 当前状态

文档体系 Diátaxis 重构进行中。基于横向研究（Diátaxis、Arc42、PRD vs Design Doc），从 product-requirements.md 拆出 product-design.md，分离 Explanation（设计决策）和 Reference（功能规格）。PR 待三方 review。

DocC 覆盖率摸底完成：整体 75%（Core 55%、Infrastructure 21% 为薄弱点）。

### 优先级

1. 文档体系重构 PR review + 合并
2. 与 Xcode Intelligence 探讨 DocC 覆盖率策略
3. TestFlight Build 6

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | DocC 策略确定 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
