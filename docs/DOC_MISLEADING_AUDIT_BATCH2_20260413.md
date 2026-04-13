# 误导性文档审计（Batch 2）

> 日期：2026-04-13  
> 基线：`#583`（Codex Baseline v1）  
> 范围：`PRD.md` / `product-requirements.md` / `product-cases.md`  
> 方法：Codex 最终裁决 + Claude / Gemini 对抗性只读评审

## 结论

Batch 2 已完成两轮：第一轮回写 5 项直接一致性修复；第二轮完成 3 项裁决并回写，当前无挂起裁决项。

## 已修复（已回写）

1. PRD 采集入口补齐 `Document Scan`。  
2. PRD 管理范围补齐“删除撤销（5 秒窗口）”。  
3. UC1 补齐 `Share Extension` 入口与 Variant。  
4. requirements“草稿恢复”补齐“按 Profile 隔离”。  
5. UC5 明确快速打印规格：详情页固定 1 题/页，批量打印支持 1/2/4。

## 第二轮裁决与回写（已完成）

1. `product-requirements.md`：保留“已实现 = ✅”，新增 `MoSCoW` 列，明确“状态”和“承诺优先级”是不同维度；并补齐 `CSV 导入` 行（`Could`）。  
2. `product-cases.md`：保留 UC8/UC9 完整验收用例，不降级为删除或整体 Deferred；增加状态说明，明确“免费层可验收、Pro 层因 StoreKit 订阅态接线阻塞”。  
3. `PRD.md`：将“高级导出”精确化为“PDF 增强免费；Word 导出与 iCloud 多设备流转属于增值体验”，消除与免费 PDF 增强能力的混淆。

## 输出物

- 文档回写：`PRD.md`、`product-requirements.md`、`product-cases.md`
- 跟踪 issue：`#586`
