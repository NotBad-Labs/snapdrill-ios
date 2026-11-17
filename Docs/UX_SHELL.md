# SnapDrill · MVP UI 壳（方案 A）

> PO 2026-11-17 选用 **方案 A**：先全屏可点 + 假数据，再按屏替换为真逻辑。  
> **冻结范围**：布局与主路径；**不冻结**：采集细手势、性能、错误边界。

## 如何体验

1. 设置 → **Load UI demo mistakes**（约 6 条彩色占位题图 + 答案/错因）。
2. 走通：**Notebook** 列表/网格 → **Filter** → **详情编辑** → **Review** → **Export PDF** 壳 → **Pro** 壳。
3. 不需要真机；Simulator 即可。
4. 清除：**Remove demo mistakes**（仅删 `isDemoSample` 题，不动你实拍数据）。

## 屏幕清单（P0 壳）

| 屏 | 状态 | 真逻辑 Slice |
|---|---|---|
| Tab 首页 / 科目 | ✅ 已有 | Slice 1 |
| 采集三步 | ✅ 相册/相机 + pipeline | Slice 2 |
| 错题列表 + 筛选 | 壳 + 本地筛选 | Slice 4 |
| 错题详情编辑 | 壳 + SwiftData 存 | Slice 4 |
| 复习 | 壳 + 缩略图 | Slice 5 |
| PDF 导出 | 壳 | Slice 6 |
| Pro 订阅 | 壳 | Slice 7 |
| 科目管理 | 壳（只读列表） | Slice 4 |

## PO 签「UX 冻住」前建议看

- 纸与笔主题、Tab 结构、复习「先题干后答案」是否 OK。
- Pro 卖点排序、PDF 选项是否对齐 PRD §8.5 / §6。
- 不满意：**只改文案/布局 PR**，不要同时接 StoreKit。

## 修订

| 日期 | 说明 |
|---|---|
| 2026-11-17 | 首版；`UIDemoDataService` + `UX_SHELL` |