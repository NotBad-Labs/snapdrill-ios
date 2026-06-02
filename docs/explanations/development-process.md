---
last_verified: 2026-06-02
layer: process
freshness:
  max_age_days: 90
  decay_trigger: [arch_change, doc_restructure, batch_completion]
---
# SnapDrill 开发流程全景图 v1（分批审计基线）

> **用途**：定义"开发流水线各层 + 横切关注点 + 当前状态 + 分批审计路线"的 success-criteria 地图，作为后续分阶段全量审计的基线（AGENTS.md 第 4 条：可验证 success criteria + 双向可追溯无孤儿）。
> **可证伪性**：本文每条状态断言带**证据等级**列，区分「实测grep可证 / 文档自述 / 作者声称 / 外部未核验」——不混为一谈。
> **v1 来历**：v0 由 Claude 单方起草；经 4 方异源评审（codex / deepseek / agy / grok 各自 git worktree 独立批判）后修订。4 方证伪的 v0 错误已在 §6 列明并改正。**v1 本身仍是待用基线、非定论**。

## 1. 产品与目标

SnapDrill：家庭教育拍照存档 iOS app（SwiftUI / iOS 26+ / Swift 6.3）。价值链 `采集 > 管理 > 导出/打印`，复习为附加值。**近期唯一战略目标：国内 TestFlight 内测 → 验证 PMF**（注意：PMF/反馈闭环此前不在流程模型内，见 §3 横切层）。核心免费闭环 ~90% build-complete。

## 2. 流水线七层 + 横切关注点

**纵向七层**（上游真相 → 下游实现 → 交付）：

```
①愿景/需求(Why)   ②功能规格(What)   ③架构/设计(How)
        │ 向下追溯（每条需求 → 实现代码 → 验真相的测试）
        ▼
④代码实现         ⑤测试(oracle 来自用例真相)
        │
        ▼
⑥构建/CI         ⑦发布(TestFlight/上架)
```

**横切关注点（cross-cutting，贯穿多层，须在每个 Batch 作为 gate 显式追踪——4 方一致补充）**：

| 横切项 | 锚点证据 | 提出方 |
|---|---|---|
| **C1 隐私/合规** | ImageStorage EXIF/GPS 剥离、PrivacyInfo.xcprivacy、ADR-002(移除ATT)、ADR-004(国内 Firebase-Free) | 4/4 |
| **C2 数据迁移/Schema 演进** | ProfileManager.ProfileMigration、SnapDrillData/MigrationPlan、backup S0 向后兼容 | 4/4 |
| **C3 一致性维持机制** | Scripts/generate_feature_status.py(B方案SSOT)、pre-commit、swift-autolint、AGENTS.md 活契约 | grok |
| **C4 双区域发布治理** | ADR-003(不可逆资源:Bundle/iCloud/AppGroup)、双账号、C 路径 xcconfig 拆分 | codex/agy/grok |
| **C5 PMF/反馈闭环** | 战略 #1 目标；内测数据收集/指标定义/pivot 触发条件（当前**未建模**） | grok |
| **C6 三方供应链** | Mantis(UI裁剪)、ZIPFoundation(Data备份)；Zip-Slip/路径遍历风险 | agy |

## 3. 各层当前状态（带证据等级）

证据等级：🟢实测grep可证 / 📄文档自述 / 🟡作者声称(未独立核验) / ⚪外部系统未在worktree内核验

| 层 | 状态断言 | 证据 | 等级 |
|---|---|---|---|
| ①愿景/需求 | docs/explanations 结构重组完成（**非"封板冻结"**，见 §4） | 9 个 explanation 文件存在（含本 development-process.md），frontmatter last_verified 多为 2026-05-25 | 🟢 结构 / 🟡 "完成"程度 |
| ②功能规格 | 9 个 active feat-*.md（Batch 2 补建 feat-dashboard，KI-03）；6 处 doc≠code 已标 GAP-R1~R6（见 §5）；Dashboard gap 已补 spec | `find docs/features/active -name 'feat-*.md'`=9；feature-status.md SSOT 自动生成 | 🟢 |
| ③架构/设计 | 分层铁律 **0 反向依赖**；SRP 最大文件 ProfileManager 499<600 | 4 方各自 grep `^import SnapDrill(UI\|Data\|Features\|Infra)` 于 Core/Data/UI 均 0 命中 | 🟢（4 方复核一致） |
| ④代码 | 核心闭环 ~90% implemented；**P2 真 bug：activityTracker 实例隔离**（见 §5 KI-01） | 9/9 active spec frontmatter status=implemented；P2 见 ProfileManager.swift:226 等 | 📄(90%) / 🟢(P2，5 源印证) |
| ⑤测试 | 测试函数 ≈ **483**；隐私/安全铁律零 oracle | Packages/\*/Tests：`@Test`=443 + `func test`=40 = 483，50 文件（含 app 层 SnapDrillTests/UITests/ShareTests 约 499/52，口径以命令为准）；ImageStorageTests 无 EXIF/GPS 断言 | 🟢 |
| ⑥构建/CI | CI workflow **配置存在**；当前运行是否全绿**未在 worktree 内核验** | .github/workflows/ci.yml 含 lint/build-for-testing/test | ⚪（外部状态） |
| ⑦发布 | 未启动（fastlane/upload_testflight.sh 存在但未执行；占位脚本已知坏） | 无 TestFlight 构建/元数据提交证据 | 🟢 |

> **基线快照**：develop @ `69c6bee8`（commit 确认；审计 worktree 为 detached HEAD，不等于"在 develop 分支上"——codex 指正）。

## 4. 「封板」定位的修正（4 方证伪后）

- **概念成立**（agy/grok/codex 认同）：封板 = 锁定 WHAT/WHY/HOW 的"真相定义权"、终结需求 churn、给下游稳定靶子；一致性是审计的独立度量，不是封板的保证。「要求 100% 一致才许封板」= 要求子弹正中红心才许画靶子（agy）。
- **但 v0 的"已封板冻结"是事实错误**（deepseek git 证伪）：
  - 无任何 in-file `SEALED` 物理标记（4/4 grep 证伪）；"封板"只是 commit message（`e402de1a`）。
  - **封板 commit 之后 docs 又被全量改**：`05879c47`(2026-06-01 feature-spec 一元化 B 重组) + `202ff1d4`(dangling 清理)——"冻结/不再 churn"不成立。
- **准确表述**：**「docs 结构重组完成（B 方案 / PR #773），内容待异源验证」**，而非"封板冻结"。封板若要成立，应有可 grep 的签名/hash/范围清单工件 + 之后冻结。

## 5. 已知问题登记册（Known-Issues Registry，供 Batch 2 增量复核而非重复发现）

> 来源：Claude 58-agent 审计（单源 v0，待 Batch 2 异源复核）。**完整 45 条带 file:line 在 `[[project_audit_fix_progress]]` + workflow 输出**；此处登记可追溯锚点。

- **KI-01【已 9 源印证 🔴】activityTracker 实例隔离**：`ProfileManager.swift:226` 查 `AppActivityTracker.shared`，但 `DependencyContainer.swift:53` 未给 `LiveServiceContainer` 传 activityTracker → `services.activityTracker` 是 `LiveServiceContainer.swift:63` 新建的 `AppActivityTracker()`、与 `.shared` 不同实例。
  - **范围（4 方咨询纠正，deepseek 实证）**：**仅 `ExportPreviewView` 导出流受影响**（它用 `services.activityTracker`）；采集/设置/编辑 VM 在调用点未传参、走默认 `?? .shared`，与 ProfileManager 同实例、保护未失效。v0/早期"导出+采集都失效"**过度估计**。
  - **修法（recon 纠正）：非 1 行**——App target `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`（零容忍），在 App 层新引用 deprecated `.shared` 会编译报错；正解=多文件注入单一实例到 ProfileManager（弃用 .shared，根治 grok 指出的 S-D4-001 迁移未完成）。**作为紧邻独立 PR（KI-01b），不阻塞 Batch 1 只读审计**。
- **KI-02【doc≠code，deepseek 抓、已核】SmartPaper**：`SmartPaperView/ViewModel/Tests` 代码已存在，但 `feat-smartpaper.md` = `status: blocked / tier: pro / blocked_by:[479]`。须裁决：spec 改 implemented，还是代码本不该在 free 闭环。
- **KI-03【gap≠contradiction，v0 归错类已改】Dashboard**：`SnapDrillFeatureDashboard`(8 文件) 无 `feat-dashboard.md`——是**孤儿代码(无 spec)**，非"矛盾"。修：建 active feat-dashboard.md 或在 feat-review 声明归属。
- **KI-04【待 Batch 2 列具体条目】**：58-agent 报的 4 处 SSOT 矛盾（CSV 字段数/CSV 引号/空集导出/复习目标范围）+ 隐私铁律零 oracle（EXIF/CSV 注入/去答案 PDF）+ 数据丢失级 audit#1（迁移非原子/Profile 还原失同步等）。

### Batch 2 代码债登记（GAP-R1~R6，2026-06-02 · 4 方 Batch 1b 审计 ≥2/4 互证 + PO 裁决）

> 裁决原则（PO 定，AGENTS 第4条 oracle=用例非代码）：**spec 守需求为上游真相 + 标 `⚠ 实现现状`，代码是债（独立 PR 后排）**。各 active spec 已就地标注对应 GAP。这些是 Batch 2 doc↔code 对账产出，待独立 code PR 修复（非本轮 doc 改范围）。

- **GAP-R1【复习软删除】**（feat-review）：`ReviewViewModel` 在 `.reviewing` 期忽略 `reviewDataDidChange` + `ReviewRepository.fetchDue` 未过滤 `DeletionScheduler.pendingDeletionIDs` → 5s 窗口内软删除到期题仍在复习流。修：复习队列过滤 pendingDeletion。
- **GAP-R2【Draft 跨 Profile 污染·真 bug】**（feat-capture/profile）：`CaptureDraftService` 草稿图片全局路径 `Caches/draft_capture.jpg`，未按 Profile 隔离。修：draft 图片路径含 Profile ID。
- **GAP-R3【OCR 语言】**（feat-capture）：`OCRService.recognitionLanguages` 硬编码 `zh-Hans`/`en-US`，无 `zh-Hant`、非 Profile 感知。修（PO 要繁体）：加 zh-Hant + 按 Profile 优先语言。
- **GAP-R4【ActivityTracker 非全程】**（feat-export）：快速打印无 tracker、`.printing` 生产零调用、编辑误用 `.capturing`。修：快速打印/编辑路径补 tracker。
- **GAP-R5【快速打印过渡实现】**（feat-export）：实为 PDF→系统分享表（grep 实证全仓零 `UIPrint*`），非 `UIPrintInteractionController`。PO 保留真 AirPrint 为目标 → 修：补真 AirPrint + 每页题数直排。
- **GAP-R6【CSV 字段数】**（feat-backup）：`CSVParser` 按表头列尽力映射，未严格校验字段数。PO 要数据完整性优先 → 修：字段数不匹配整行拒绝 + 提示。

### Batch 2 已处置（doc 改，本轮完成）

- **KI-02【SmartPaper】已处置**：实证发现 spec 已区分 免费基础组卷(已实现#566)/Pro精准选题(阻塞#479)。PO 裁 `status: blocked→implemented`（指免费基线+门控脚手架已落地，**Pro 精准算法权重/多版式仍未实现**，待 #479；`blocked_by:[479]` 保留 Pro 不可达性质）。
- **KI-03【Dashboard 孤儿代码】已处置**：补建 `../features/active/feat-dashboard.md`（免费基础首页：题库总数/今日新增/今日待复习/今日已复习/复习Hero/空状态/草稿恢复）；高级统计(Pro)仍归 `feat-advanced-stats.md`。

## 6. v0→v1 修正清单（4 方证伪的错误）

1. 「5/29 SEALED 标记」→ 删除（不存在；4/4 证伪）。
2. 「封板冻结」→ 「结构重组完成、内容待异源验证」（deepseek git 证伪）。
3. 测试数「483/52」→ 标明命令口径（Packages 483/50；含 app 层 ~499/52）。
4. 「CI 全绿」→ 「配置存在，运行状态未在 worktree 核验」。
5. Dashboard 从"4 处矛盾"→ 改为 **gap(无 spec)**（KI-03）。
6. **新增** SmartPaper doc≠code 矛盾（v0 漏，deepseek 抓，KI-02）。
7. 新增横切关注点 C1–C6（4 方一致）。
8. 新增证据等级列 + 基线快照 commit/detached 标注（codex）。

## 7. 分批审计路线（修订）

| Batch | 任务 | 完成标准 / 方法 / 交付物 |
|---|---|---|
| **0 ✅** | 异源验证全景图 → v1 | 4 方 worktree 独立评审完成（本文 §6 即产出）；交付=本 v1 文档 |
| **0.5 ✅** | 基线冻结 + P2 热修复准入 | 冻结锚点 `develop@27514750`·源 186·测试 483·spec 8 active/5 backlog（2026-06-02）；KI-01 改判**多文件 S-D4-001**（非 1 行，App target 零容忍 + `.shared` deprecated）→ 独立 PR（PO 定后排） |
| **1a ✅** | 封板实证 + 文档结构完整性 | 死链 0（35 链全检）·孤儿 0·frontmatter 合规（剥 2 backlog 残留注释）·SSOT `[ok]` |
| **1b ✅** | 上游内容正确性（逐 spec） | 4 方异源审 8 active spec，6 条 ≥2/4 互证 doc≠code（见 §5 GAP-R1~R6） |
| **1c ✅** | spec↔spec 一致性 + 交叉引用 | 死链 0=交叉链完整 + 4 方确认术语/口径一致；缺口 KI-02/03 已处置 |
| **2 🔄** | ②↔④↔⑤ doc↔code↔test 对账 | doc 改完成（GAP-R1~R6 就地标注 + KI-02/03 处置，PO 8 项裁决）；code 债待独立 PR；4 方异源 verify 进行中 |
| **3** | ⑥⑦ 构建/发布就绪 + 横切 gate | CI 实跑绿、供应链(C6)、双区域 Firebase 剥离(C4)、隐私 manifest 对账(C1)；朝 TestFlight |

## 8. Provenance

- 2026-06-01：v0（Claude 单方）→ 4 方异源评审（codex/deepseek/agy/grok）→ 本 v1。原始 4 份评审见 `/tmp/sd-panorama/out/`（会话外可重跑）。
- 关联：[[project_audit_fix_progress]]（58-agent 审计 45 条）、AGENTS.md（活契约）、docs/decisions/ADR-003·004（双区域/Firebase-Free）。
- 2026-06-02：Batch 1a/1b/1c/0.5 完成 + Batch 2 doc 改（PO 8 项裁决，GAP-R1~R6 标注 + KI-02/03 处置）。
- **下一步**：Batch 2 收尾——4 方异源 verify 本轮 doc 改 → 起 GAP-R1~R6 + KI-01 的独立 code PR → Batch 3 发布就绪（CI 实跑/Firebase 剥离/供应链/隐私 manifest）+ C5 PMF 建模（PO 侧）。
