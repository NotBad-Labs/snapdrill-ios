# Pull Request 模板指引（指针页）

> **单一真源原则**：为彻底避免两份 PR 模板内容漂移，全仓唯一 PR 模板正文已收口至 **[`.github/pull_request_template.md`](../.github/pull_request_template.md)**（GitHub 新建 PR 时自动加载）。  
> 凡手动开 PR 或使用命令行提交时，请**直接复制或引用该唯一真源模板**，不要在本文件维护第二份副本。

---

## 开工与提审速查清单

开出任何代码或文档 PR 前，确保满足以下核心约定：

1. **一 PR 一边界**：只对应 [`ROADMAP.md`](ROADMAP.md) 唯一 `Slice 1–8` 中的单个子边界或单个文档修复任务，不夹带无关全盘重构。
2. **权威顺序**：[`PRD.md`](PRD.md)（文内当前版）→ [`GOVERNANCE.md`](GOVERNANCE.md) / [`ARCHITECTURE.md`](ARCHITECTURE.md) → [`DEVELOPMENT_PRINCIPLES.md`](DEVELOPMENT_PRINCIPLES.md) → [`ENGINEERING.md`](ENGINEERING.md)。
3. **模板强制门禁**（完整勾选框见 [`.github/pull_request_template.md`](../.github/pull_request_template.md)）：
   - **PO UX 收权**：未擅自将演示草稿扩为正式产品交互；
   - **文档红线**：未私建 `Docs/*.md`、未篡改冻结文档或 `Samples/`；
   - **Legacy 闸门**：仅允许按 [`LEGACY_PARTS_INVENTORY.md`](LEGACY_PARTS_INVENTORY.md) 已标 `[x] 要` 的 L10/L12（或 PO 本 PR 特批）迁入；
   - **隐私与保密**：绝不提交 `Samples/stage0/raw/`、密钥或 `.xcuserdata`；
   - **合同与本地化**：变动 `*Serving` 必同步测试，变动 UI 文案必同步 5 语 String Catalog；
   - **实测留痕**：写明真实运行设备/模拟器与实测结果，而非只贴空步骤。

---

## 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-27 | 盲审闭环（D7）：将本文收敛为指向 `.github/pull_request_template.md` 唯一真源的指针页，消除双份模板维护漂移 |
