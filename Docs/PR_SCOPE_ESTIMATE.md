# SnapDrill · 大概需要多少个 PR？（非权威粗估）

> **结论**：整段 greenfield **不必、也不应该**演变成「几百个失控 PR」。按 [`ROADMAP.md`](ROADMAP.md) 唯一 `Slice 1–8` 一 PR 一边界推进，合理 MVP 总量预计在 **40–70 个** PR（中间值 **~55 个**）；若逼近 **150+**，说明切分过碎或需求/架构出现返工，应及时收口。

---

## 按唯一 `Slice 1–8` 的粗算分解

> 所有需求依据见 [`PRD.md`](PRD.md) 文内当前版；本估算仅作节奏参考，不构成工程硬指标（[`GOVERNANCE.md`](GOVERNANCE.md) §1 L5）。

| 阶段 / 唯一 Slice | PRD / AC 范围 | 粗算 PR 数 | 说明 |
|---|---|---:|---|
| 文档、治理与架构闭环 | [`PRD.md`](PRD.md)、[`GOVERNANCE.md`](GOVERNANCE.md)、[`ARCHITECTURE.md`](ARCHITECTURE.md) 等 | **5–8** | 已完成多轮盲审闭环 |
| 阶段 0（轨道 B） | 样本工具、Hold-out 评估、Core ML 模型与接入准备 | **3–6** | 含模型量化、趋势门与冻结门裁决 |
| **Slice 1** · 工程壳与科目 | AC-01 | **2–4** | 原生三 Tab、地区 `presetKey`、单库 UUID 模型与 **Slice 1 前 `CKSyncEngine` Spike** |
| **Slice 2** · 2 步流畅采集 | AC-02、AC-03、AC-09(草稿) | **7–12** | 唯一 `AVFoundation`+Vision/`PHPicker`、多框 ≤30、随时建科、**`LibraryServing` 入库/预检子集**、≤300 ms 编码 1 秒提交、`Application Support` 草稿与 UX 冻结 |
| **Slice 3** · 端侧去手写 | AC-04 / `AC-04-B` | **3–6** | 懒加载模型、`MistakeItem.backfillState`+`beginBackgroundTask`、6 秒硬超时降级（若 B/C 档含 `F-12` 则取高值） |
| **Slice 4–5** · 图库与复习 | AC-05、AC-06 | **6–10** | `LibraryServing` 完整扩展、筛选、重跑/单题微调重裁、精确三态 5 秒撤销墓碑、`ReviewServing` |
| **Slice 6–7** · PDF 与商业同步 | AC-07、AC-08 | **7–11** | `PDFExportService`（B5/公式留白/双超页缩放/水印一致）、StoreKit 2 状态机、`ProEntitlementStore` + `CloudKitSyncEngine` 启停 |
| **Slice 8** · 边界、五语与 a11y | AC-09、AC-10 | **4–7** | 库损坏自救导出、`F-66` 清理、5 语动态切换、6 组调色板 WCAG AA / 5 界面 VoiceOver / Reduce Motion |
| 上架合规与商店素材 | §6.3、§7.5、§9.1 | **3–6** | W1–W2 提前启动 ICP 备案、官网/5 语隐私托管、`PrivacyInfo.xcprivacy`、iOS 26 图标三变体 |
| **合计（MVP 上架）** | **§13 全部十条 AC** | **40–70** | **下界精确相加 = 40，上界精确相加 = 70，中间值 ~55** |

---

## 规模健康度对比

| 情况 | PR 数量级 | 含义 |
|---|---|---|
| **健康** | **40–70** | 一 PR 一边界，8–10 周稳健完成 MVP |
| **偏多但可控** | 71–110 | 粒度偏细或含阶段 0 多轮模型与合规修补 |
| **需复盘收敛** | 111–149 | 拆 PR 偏碎或边界出现小规模返工，应合并清理杂项并检查 `Slice 1–8` 合同 |
| **警惕** | **150+** | 出现架构撞墙返工、Scope 蔓延或反复推倒重画 |

greenfield 严格执行 **唯一 PR 模板门禁** 与 **合并后删远端分支**，避免旧仓库多分支长期漂移的历史重演。

---

## 不建议单独开 PR 的杂项

- 纯单字 typo、`.xcuserdata`（应直接在 `.gitignore` 忽略）
- 与当前分配 Slice 无关的「顺手全库格式化/重构」
- 未先更新 [`PRD.md`](PRD.md) 且未过 PO 确认的行为变更

---

## 修订记录

| 日期 | 说明 |
|---|---|
| 2026-11-16 | 首版 PO 粗估 |
| 2026-11-27 | 盲审闭环：算术精确对齐 **40–70**；按唯一 `Slice 1–8` 重分项；清除硬编码 PRD 版本号 |
| 2026-11-27 | 冻结前复审与终审定案：补全 `111–149` 区间；Slice 1/7 同步为 `CKSyncEngine` Spike 与启停同步；Slice 2 对齐 `LibraryServing` 入库子集 |
