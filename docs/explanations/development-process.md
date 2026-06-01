---
last_verified: 2026-06-01
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
| ①愿景/需求 | docs/explanations 结构重组完成（**非"封板冻结"**，见 §4） | 8 个 explanation 文件存在，frontmatter last_verified 多为 2026-05-25 | 🟢 结构 / 🟡 "完成"程度 |
| ②功能规格 | 8 个 active feat-*.md；2 处 doc≠code（见下）；Dashboard 无 spec(=gap) | `find docs/features/active -name 'feat-*.md'`=8；feature-status.md SSOT 自动生成 | 🟢 |
| ③架构/设计 | 分层铁律 **0 反向依赖**；SRP 最大文件 ProfileManager 499<600 | 4 方各自 grep `^import SnapDrill(UI\|Data\|Features\|Infra)` 于 Core/Data/UI 均 0 命中 | 🟢（4 方复核一致） |
| ④代码 | 核心闭环 ~90% implemented；**P2 真 bug：activityTracker 实例隔离**（见 §5 KI-01） | 8/8 active spec frontmatter status=implemented；P2 见 ProfileManager.swift:226 等 | 📄(90%) / 🟢(P2，5 源印证) |
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

- **KI-01【已 5 源印证 🔴】activityTracker 实例隔离**：`ProfileManager.swift:226` 查 `AppActivityTracker.shared`，但 `LiveServiceContainer.swift:63` 注入 `AppActivityTracker()` 新实例、`DependencyContainer.swift:53` 未传入 → 导出/采集 begin/end 在新实例，Profile 切换保护读 .shared 看不到 → **切换保护形同虚设**。修：DependencyContainer 注入 `.shared`（1 行）+ 集成测试。
- **KI-02【doc≠code，deepseek 抓、已核】SmartPaper**：`SmartPaperView/ViewModel/Tests` 代码已存在，但 `feat-smartpaper.md` = `status: blocked / tier: pro / blocked_by:[479]`。须裁决：spec 改 implemented，还是代码本不该在 free 闭环。
- **KI-03【gap≠contradiction，v0 归错类已改】Dashboard**：`SnapDrillFeatureDashboard`(8 文件) 无 `feat-dashboard.md`——是**孤儿代码(无 spec)**，非"矛盾"。修：建 active feat-dashboard.md 或在 feat-review 声明归属。
- **KI-04【待 Batch 2 列具体条目】**：58-agent 报的 4 处 SSOT 矛盾（CSV 字段数/CSV 引号/空集导出/复习目标范围）+ 隐私铁律零 oracle（EXIF/CSV 注入/去答案 PDF）+ 数据丢失级 audit#1（迁移非原子/Profile 还原失同步等）。

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
| **0.5** | 基线冻结 + P2 热修复准入 | 冻结 SSOT 清单/统计口径/快照 commit；先修 KI-01（P2 1 行 + 测试）再深审（codex/agy） |
| **1a** | 封板实证 + 文档结构完整性 | 确认①②③ 无孤儿/死链/frontmatter 合规；grep 可证 |
| **1b** | 上游内容正确性（逐 spec） | 8 active spec 内容 vs 现实逐条核（4 方异源）；交付=每 spec 通过/缺陷 |
| **1c** | spec↔spec 一致性 + 交叉引用 | 术语/字段口径/交叉链一致 |
| **2** | ②↔④↔⑤ doc↔code↔test 对账 | 以 §5 KI 登记册为输入做**增量复核**（非重复发现）；裁 4 处 SSOT；4 方异源 |
| **3** | ⑥⑦ 构建/发布就绪 + 横切 gate | CI 实跑绿、供应链(C6)、双区域 Firebase 剥离(C4)、隐私 manifest 对账(C1)；朝 TestFlight |

## 8. Provenance

- 2026-06-01：v0（Claude 单方）→ 4 方异源评审（codex/deepseek/agy/grok）→ 本 v1。原始 4 份评审见 `/tmp/sd-panorama/out/`（会话外可重跑）。
- 关联：[[project_audit_fix_progress]]（58-agent 审计 45 条）、AGENTS.md（活契约）、docs/decisions/ADR-003·004（双区域/Firebase-Free）。
- **下一步**：Batch 0.5——冻结基线 + 修 KI-01（P2）。本 v1 入库后即受 docs/ SSOT 与 pre-commit 约束。
