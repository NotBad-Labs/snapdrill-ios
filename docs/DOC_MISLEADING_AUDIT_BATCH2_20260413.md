# 误导性文档审计（Batch 2 / 第一轮）

> 日期：2026-04-13  
> 基线：`#583`（Codex Baseline v1）  
> 范围：`PRD.md` / `product-requirements.md` / `product-cases.md`  
> 方法：Codex 人工复核 + Claude（Sonnet 与 Opus）只读交叉粗筛

## 结论

本轮确认 5 项可直接修复的一致性问题，均已回写；另有 3 项需产品裁决后再改写。

## 已修复（已回写）

1. PRD 采集入口补齐 `Document Scan`。  
2. PRD 管理范围补齐“删除撤销（5 秒窗口）”。  
3. UC1 补齐 `Share Extension` 入口与 Variant。  
4. requirements“草稿恢复”补齐“按 Profile 隔离”。  
5. UC5 明确快速打印规格：详情页固定 1 题/页，批量打印支持 1/2/4。

## 待裁决（需产品口径）

1. `product-requirements.md` 中“原图 ZIP / 分享卡片 / CSV 导入”在能力矩阵为 ✅，但 MoSCoW 在 Could Have；需确认“已实现但非当前承诺”还是“应上调到当前承诺层”。  
2. `product-cases.md` 中 UC8/UC9（Smart Paper / Advanced Analytics）是否保留完整验收用例，或改为 Deferred 标记。  
3. `PRD.md` 中“高级导出和多设备流转可属于增值体验”表述需更精确（避免与免费 PDF 增强混淆）。

## 输出物

- 文档回写：`PRD.md`、`product-requirements.md`、`product-cases.md`
- 跟踪 issue：`#586`
