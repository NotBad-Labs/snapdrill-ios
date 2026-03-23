# SnapDrill 项目状态看板

> 最后更新：2026-03-23
>
> 每次新对话必读此文件恢复上下文。每个 PR 合并后同步更新。

---

## 当前工作

**PR #418**：文档体系瘦身（Issue #417）
- 基于第三方独立评估（专家 + Xcode Intelligence），文档从 5,072 行精简到 2,663 行（-47.5%）
- infrastructure.md 718 → 18 行，principles.md 322 → 95 行，workflow.md 395 → 65 行
- CLAUDE.md 自动注入从 9 个文件 → 3 个文件
- Skills 从 19 → 9 个（删除发布前不需要的 10 个）
- 等待 Xcode review 后合并

**前序 PR #415 已合并**：产品文档审计（隐私措辞统一 + ADR 删除 + 文档瘦身 -3,357 行）

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | 文档审计完成后 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
