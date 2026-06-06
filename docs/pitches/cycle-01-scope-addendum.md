# Cycle 1 Scope Addendum — 意图对齐落地边界

> 状态：**草案 · 待 PO 批准** · 2026-06-06 · 修订对象：`cycle-01-quality-floor.md`（pitch 的 no-go / scope）
> 缘由：意图对齐（`cycle-01-intent-tradeoffs.md` 22 答案）与 pitch no-go「不碰复习 / 不加新功能」冲突。**4 方异源一致**：问卷答案 ≠ backlog，需一个「进本 cycle / 只观察 / Parked」闸门。本文件 = 那个闸门。
> **不变的 bet**：守住 采集→管理→导出/打印→TF 的质量地板；最高价值 = PO 自己 dogfood + 通 TF，不是更多文档。
> 顺序（仍按 pitch Ch.11）：**S5 先通 TF 管线 → S1 dogfood → 小修在 S2/S3 内做**。

## 一、进本 cycle（小修 = 让代码对齐已定意图 / 修正确性债，非新功能）

| # | 改动 | 为什么算质量地板·非新功能 | 代码锚（codex grep，实现时核行号） |
|---|---|---|---|
| 1 | ExportPreview：临时文件没存好就**不进预览**（B=b） | S3 最后一项；修「能看却谎称自己坏」的不连贯 | `ExportPreviewView.swift:107-117` |
| 2 | AI **不再自动填难度** | 删行为；对齐「AI 不碰主观 / 信任 even over 省事」 | `CaptureResultViewModel.swift:185` |
| 3 | 采集**默认只展示学科**（其余可选披露） | 改默认值；对齐 Q16 极简 + #1 录入原则 | `CaptureResultViewModel.swift:198`（`?? true`）|
| 4 | GAP-R1：软删题**不在复习 session 出现** | 正确性债，pitch 允许修 blocker | `feat-review.md` §Verify |

\+ S1 dogfood 暴露的 **S0/S2**：崩溃 / 数据丢失 / 假成功 / 隐私 / 主路径严重误导（pitch 原范围）。

## 二、只 dogfood 观察（不实现 · 测信号喂 Cycle 2）

意图答案**大多在此**——它们是「观察透镜」不是待办。dogfood 时按下表记，**不边用边改功能**：

| 答案 | 观察什么 |
|---|---|
| Q5 采集单元 | 一张卷裁几次？（反复 5+ → AI 拆题拉力变真）|
| **Q6 复习入列**（A=Cycle 2）| 存 50+ 题后「N 道待复习」是有用提示还是焦虑？⚠️ **这 backlog 是占位模型（`.distantPast`）产物、非真实形态，别误读成产品信号** |
| Q8 OCR 失败 | 空/乱码比例？纯图片项后来搜不到的频率？|
| Q9 复习定位 | 你自己会主动回来开复习吗？|
| Q11 打印 | 打印步多 tap / 排版痛？（强痛才进 Cycle 2 专属流）|
| Q16/18/19 采集轻·检索富 | 采集字段烦不烦？找题用搜还是筛？|
| Q17 AI 学科 | 静默填学科错不错？错了改起来烦不烦？（决定 Cycle 2 要不要做 confidence-gate + 可见确认）|
| Q2 操作者 / Q15 Multi-Profile | population——dogfood 答不了，需 TF 信号（见四）|

**问卷盲区（deepseek 捕捉，dogfood 重点补看）**：**Onboarding 首次体验（H1 = 最重要假设却零题）** / 错误恢复（网络·存储满·权限·iCloud 不可用）/ 无障碍 VoiceOver（vision §5 基线）/ iPad·Pencil。

## 三、Parked · Cycle 2+（已定方向，本 cycle 冻结）

复习入列 reshape（Q6-B）+ 复习整体 shape（Q10-B）= **Cycle 2** ｜ SmartPaper 组卷（Q7-C）/ AI 拆题（Q5-A）/ 高级统计 = **冻结** ｜ Pro 捆绑 · iCloud · Word · StoreKit（Q13 Bear 式方向已记）= **阻塞/RC** ｜ 分区域匿名埋点（Q14）= **RC** ｜ 打印一等专属流（Q11-A）= **Cycle 2**，除非 dogfood 强 flip ｜ OCR 补救新流（Q8-B）= **Cycle 2**（先观察）｜ 假设台账参数 Q20/21/22 = **dogfood 定**。

> 注：R14「复习 2 按钮」= 现有代码本就如此，**无需改动**（PO 已确认保留）。

## 四、闸门规则（什么能破例进本 cycle）

默认：二、三筐**一律不碰**。只有这些发现可破例（**且须砍等量 scope 换**）：数据丢失 / 崩溃 / 假成功 / 隐私泄露 / 主路径严重误导。

- **复习 backlog 特例**：默认当占位**忽略**；只有 dogfood 证明它**主动有害**（不是「看着多」，而是「挡住主路径 / 误导操作」）才允许一个**最小** `.distantPast` 止血（**非**完整 reshape）。

## 五、population 题最小验证计划（防「待真实用户」= 无限期拖延）

Q2 操作者身份 / Q15 Multi-Profile：TF 内测时**收一个最小信号**——例：内测引导问「你家几个孩子在用」+ 观察是否有 12-15 岁自己操作。**多少样本算「有信号」由 PO 定阈值。**

## 六、不动

- **vision.md 仍不动**：6 条耐久 tenet（见 `cycle-01-intent-tradeoffs.md` §H）已 PO 逐条确认、**待一次性签字**才写入；**Q9 已排除**（它是 H9 假设、非原则——4 方一致）。这是独立的 30 分钟小动作，不属本 cycle 的 dogfood 工作。
- 不重写 / 不删能跑代码 / 不优化架构（pitch 原 no-go 保留）。
