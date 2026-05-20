---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 1 — 三方对抗共识报告

> **日期**：2026-05-20 | **维度**：1 跨文档语义链条 (V→D→R→T) | **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 High)
>
> **方法**：F-008「相同完整任务、不分工」纪律，三家独立审完整范围，[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (8 findings)
> - Codex 桌面端：用户粘贴 (15 findings)
> - Antigravity：[`semantic-audit-dim1-findings.md`](semantic-audit-dim1-findings.md) (12 findings)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) (22 OPEN + 1 WAIVED + 1 REJECTED)

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **3/3 全共识** | 3 | HIGH×1 MEDIUM×1 (注：含 1 同域不同角度 LOW→HIGH 升级) |
| **2/3 共识** | 3 | MEDIUM×2 LOW×1 |
| **1/3 单家可采纳** | 16 | HIGH×1 MEDIUM×4 LOW×10 INFO×1 |
| **1/3 拒绝/豁免** | 2 | REJECTED×1 WAIVED×1 |
| **合计可采纳** | 22 | HIGH×3 MEDIUM×6 LOW×12 INFO×1 |

## 3/3 全共识 finding（最高置信度，最优先修复）

### S-D1-001 [HIGH, D→R] — 字段配置/系统字段管理规格断链

Design §字段可配置系统四层分层表 + §系统字段选项管理 (删除保护/级联/无感创建)，但 Requirements 只在 v2.0 全景一句话带过。**Antigravity 抓到最尖锐表现**：来源/年级开了字段，但题库过滤/排序都没承接（只支持时间/学科/难度/复习状态），用户高成本录入的字段沦为「死元数据」。

- Claude F1.3 (LOW): 字段分层表 R 没承接
- Codex #6 (LOW): 选项管理（删除保护/级联/无感创建）R 没承接
- Antigravity F-D1-005 (HIGH): 来源/年级被废线化

**修复路径**：Requirements 新增 §字段配置规格段，承接 Design 全部三个维度 + 题库过滤/排序闭环。

### S-D1-004 [MEDIUM, D→R] — 多 Profile 关键生命周期规格漏损

Design §多 Profile 写了全部生命周期（切换中断/最后 Profile 保护/创建/删除/TipKit Per-Profile/Onboarding 全局），Requirements 只一行 bullet「多 Profile 本地切换（参考 Obsidian）」。

- Claude F1.4 / Codex #4 / Antigravity F-D1-007 (全 MEDIUM)

**修复路径**：Requirements 新增 §多 Profile 规格段。

## 2/3 共识 finding

### S-D1-002 [HIGH, R→T] — CSV 数据导入技术架构断链

Codex #10 (MEDIUM) + Antigravity F-D1-011 (HIGH)。Requirements 承诺「CSV 数据导入 (RFC 4180 合规)」，Architecture/NFR 完全无技术支撑。`CSVParser.swift` 代码已存在但架构图缺失。

### S-D1-005 [MEDIUM, D→R] — 错误分级 L1/L2/L3 在 Requirements 完全缺失

Claude F1.5 + Codex #3 (均 MEDIUM)。Design 详细写了三级标准（可忽略/可恢复/数据风险），Requirements 没有任何错误处理段。

### S-D1-006 [MEDIUM, R→T] — Foundation Models / ContentTaggingService 已实现但架构图缺失

Claude F1.7 (MEDIUM) + Codex #9 (HIGH)。Requirements v2.0 全景声明「端上 AI 自动标注（Apple Foundation Models）」，且 `ContentTaggingService.swift` + `QuestionSplittingService.swift` 代码已存在并测试覆盖，但 Architecture §SnapDrillCore Service 未列。

### S-D1-007 [LOW, V→D] — Vision §成功信号未在 Design 闭环

Codex #1 + Antigravity F-D1-004。Vision 8 项可度量信号没映射到 Design 校准入口/埋点框架。

## 1/3 单家独有但可采纳（部分摘录）

### S-D1-003 [HIGH, R→T] — Dynamic Type 概念混淆（Antigravity 独家）

NFR §无障碍写「Dynamic Type | 复习卡片字号 12-24pt 可调」，Requirements 写「字号正反面独立设置」。Dynamic Type 是 iOS 系统级无障碍机制，**不可能**在同一页面对正反面独立缩放。文档存在实际错误，会误导架构实现。

**grep 验证**：
- `non-functional-requirements.md:73`: `| **Dynamic Type** | 复习卡片字号 12-24pt 可调 |`
- `product-requirements.md:169`: `字号：正面和背面独立设置`

**修复路径**：NFR 拆为「Dynamic Type 系统级支持」+「复习卡片 App 自定义字号」两条独立条款。

### 其他 1/3 单家详见 [`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv)

包含：版权边界承接（Codex C1）、Dashboard 字段规格（Codex C2）、采集方式技术归属（Codex C3）、Smart Paper 架构（Codex C4）、分享卡片架构（Codex C5）、高级统计架构（Codex C6）、备份恢复差异化（Codex C7）、双语 OCR 设计（Antigravity A2）、软删除强退收敛（Antigravity A3）、安全网自动备份设计（Antigravity A4）、PrintService 架构（Antigravity A5）、OCR 不强迫校对规格（Claude L2）、EXIF 剥离组件归属（Claude L3）、iCloud Architecture 占位（Claude L4）、P3 标注稀疏（Claude L1 → INFO/WAIVED）。

## 拒绝 / 豁免

### S-D1-R01 [REJECTED, V→D] — 物理鲁棒性 vs Pro 图片增强边界（Antigravity F-D1-001）

Antigravity 把 Vision P1「物理环境鲁棒性」与 Pro 图片增强强行关联为同一边界。实际两个不同场景：
- Vision P1 物理鲁棒性 → OCR 拍摄期对比度/对焦/稳定性指示器
- Pro 图片增强 → 已保存图片去手写/去批改痕迹

Design §OCR 定位 + §图片处理增强已分别承接。**误判**。

### S-D1-R02 [WAIVED, V→D] — 复习独立 Tab 与 Vision 张力（Antigravity F-D1-002）

Design §导航结构已显式豁免：「复习是可选留存层（非核心价值链），但因其使用频率足以支撑独立 Tab」+「复习入口在信息架构中不得压过采集和题库」。已知 architecture tradeoff，不是漂移。**WAIVED**。

## Gemini 3.5 over-endorse 病灶评估（ADR-005 关键观察）

ADR-005 §决策段定的关键观察点：Gemini 3.5 通过 Antigravity 是否仍呈 over-endorse 模式（Gemini 3 Pro Preview 在结构层 52 文档 verdict 100% VALID 即 over-endorse 表现）。

**维度 1 实测结果**：

| 指标 | Antigravity (Gemini 3.5) 表现 |
|---|---|
| 总输出 finding | 12（Claude 8 / Codex 15） |
| HIGH 严重度占比 | 4/12 = 33% |
| MEDIUM | 2/12 |
| LOW | 6/12 |
| 100% VALID 倾向 | ❌ 未出现 |
| 抓到致命独家 finding | ✅ F-D1-010 Dynamic Type 混淆（Claude/Codex 均漏） |
| 误判数 | 2 (F-D1-001 / F-D1-002) — 偏严而非偏松 |

**结论**：Gemini 3.5 经 Antigravity 在语义层任务**未复现 over-endorse 病灶**。偏严风格反而抓到 Claude/Codex 漏掉的真问题。**维持三方对抗角色**，不需要按 ADR-005 §后续 phase backlog 走「降权重 fallback」分支。

> ⚠️ 单维度结论，需在后续 6 个维度持续观察。如果维度 2-7 中出现 over-endorse 反复，再触发降权重。

## 下一步

1. **本会话**：commit ledger + consensus 报告；ADR-005 §决策段或新增 §维度 1 收官观察 段回填 Gemini 3.5 实测结论
2. **下一会话**：维度 2「反向溯源」启动（按 STATUS.md / handoff.md 已更新的指向）
3. **22 项 OPEN finding 何时修**：可在维度 2-7 全部完成后集中入 PR（避免边审边改导致基线漂移），或抽 HIGH 3 项立即修。**待用户决策**。
