---
last_verified: 2026-05-14
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-14（**工程治理收尾 — 6 skill + 依赖传播链全量复核 + 源文件头防腐**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）
> 领先 origin/develop：**0 commits**（已同步）
> **新增 6 个 Skill**：verify-audit-report / dependency-propagation / sprint-contract / post-merge / api-research / snapshot-diff-review
> **源文件防腐**：237 文件删除创建日期，git blame 为唯一真相源
> **工具链**：Claude Opus 4.7 + Codex CLI + Gemini CLI · skill-creator@claude-plugins-official
> **下次接手**：读 `docs/memory/handoff.md` Boot 序列

## 本轮完成（2026-05-14，工程治理收尾）

| 类别 | 内容 |
|---|---|
| 6 个新 Skill | verify-audit-report / dependency-propagation / sprint-contract / post-merge / api-research / snapshot-diff-review — F 规则全部有 skill 执行器 |
| 依赖传播链全量复核 | engineering → product-vision → ADR-001/002 → NFR → architecture — 6 个根文档 ~20 个下游一致性验证 |
| architecture.md 补齐 | DataExecutor actor（Phase 2 核心架构变更）DI 图/数据流/模块表/设计决策 4 处更新 |
| 源文件头防腐 | 237 文件 `Created by NotBad Labs on DATE.` → `Created by NotBad Labs.` — Codex + Claude 零分歧 |
| 文档日期修复 | 8 个 last_verified 过期修复（04-14 → 05-14）|
| auto-commit 记忆 | 改动完成后主动提交推送，不让用户提醒 |

**零内部阻塞。全部 handoff 待办清空。**

## 历史完成（2026-04-18→19，Harness Engineering Stage A+B 7 PR）

| PR | 内容 |
|---|---|
| #673 | Phase 4 历史 checkpoint 补齐（P2/P3/tech-debt 3 个 checkpoint + checkpoints/ 目录）|
| #674 | Harness Engineering 三方研究归档（Anthropic 2026-03-24 蓝本 + Hashimoto 命名源 + 中文译法） |
| #675 | Sprint Contract 内嵌 Issue 模板 + F-018 编码前契约纪律 |
| #676 | post-merge 反模式启发式（anti-pattern-scan.sh）+ F-019 人工回流 |
| #677 | Permission Model SSOT（T1/T2/T3 tier + 9 hook 表 + 10 skill 矩阵） |
| #678 | session-metrics hook（全 tool matcher）+ phase-closeout Metrics 段 |
| #679 | cross-audit-consensus 量化 rubric 4 维（0-10 整数分 + Retry 阈值） |

**本轮机制首次实战**：cross-audit rubric 一次性挡下 2 个 PR 合并（#677 Codex 6.8 / #678 Codex 5.5），Codex 两轮复核后通过。详见 `~/.claude/plans/harness-prs-cross-audit-20260418.md`。

**方法论反思修复（PR #682 #681）**：checkpoint Risks 段 3 项未落地全部合并：
- **F-020**（新 feedback → 2026-04-21 Phase C PR-α1 合并入 F-005 Auto mode 强化段）：Auto mode 不豁免 F-005 对抗审查
- **§2.5 评分方权重 SSOT**：Codex 始终主锚点 / Gemini 守纪律次锚点 / Claude 实施方自审为参考（不进入裁决）
- **Gemini 评分纪律**：8.0 起评 + plan 锚点 + 10.0 硬门槛 + 方差自检，运行侧 prompt 完整承接

**第二轮吃狗粮验证**：PR #682 首次 cross-audit 出现 Gemini 9.8 vs Codex 6.0（方差 3.8），按新 §2.5 硬阈值 retry；retry 后 Codex 8.5 通过。规则再次挡住自身的自审 bias，证明设计有效。

**文档体系 v2 三方审计 + 收口 PR #685**（2026-04-19 晚）：Hermes + Harness 密集引入后用户担忧文档膨胀失真，三方全景审 49 md / 370KB。Codex 主锚点 8.0 / Claude Agent 次锚点 8.5 / Gemini 次锚点 8.75（方差 0.75）。归档 `~/.claude/plans/doc-audit-v2-20260419.md`。PR #685 落地 H 高 5 项 + 3 处 last_verified + M 中 6 项（共 14 文件 small diff，Closes #684）。首次三方审 Codex 6.8 发现阈值语义反转（方差 3.2 vs Gemini 10.0），retry 后 Codex 9.1 通过。**第三轮 rubric 吃狗粮成功：SSOT 闭环。**

**Stage C 暂缓**：PR-6 SnapshotTesting + PR-7 CI 集成（~2-3 天）用户将另开单独会话推进。

---

## 当前状态

**文档已冻结，功能开发 + 测试补齐 + 工程治理阶段**（2026-04-14 冻结，2026-04-15-16 密集开发）。

**本周已完成（4 个 sprint）**：
1. B1 try? 第三批治理（PR #636 合并）
2. 中期审计校准（PR #640 合并）
3. **文档体系三方独立审计**（Phase 1-3 完成，综合报告 `~/.claude/plans/doc-audit-summary.md` 含三方比对 + 误判归档 + Phase 4 PR 清单）
4. **Phase 4 P1 完成**：PR #642 SSOT 校准 + #644 cross-audit skill + #646 api-reference 同步 — 全合并

**Phase 4 Step 1 完成**：
- PR #648 .claude/rules/ux-design.md 补 YAML frontmatter（已合并，.claude/rules/ 12/12 全 YAML）

**Phase 4 P2 sprint 完成（2026-04-17 晚，6 PR 全合并）**：
- ✅ **PR #650** PR-D F-008 去重 — workflow.md:146 改纯指针
- ✅ **PR #651** PR-G archive 标废弃 — audit-report-20260409.md 元信息 + memory/README 注记
- ✅ **PR #652** PR-F 时效性修正 + 追补 — collaboration Opus 4.6→4.7 + requirements 端上 AI 毕业（含 MoSCoW Could Have 删除）
- ✅ **PR #653** PR-H ux-design 失效 skill 修正 — 删除 ux-design.md:5 死引用
- ✅ **PR #654** PR-K Issue 模板去重 — workflow.md:17-48 改 SSOT 指针 + feature_request.md 合并独有字段
- ✅ **PR #655** PR-E KNOWLEDGE_MAP 校准 — 12→17 条 + ~25→~40 文件 + memory/README 同步

**Mac mini runner 事件**：CoreSimulator 1051.49→1051.50 过时导致 #651/#652/#653 首轮 CI FAILURE。用户系统更新 + 重启 Mac mini（macOS 26.4.1 / Xcode 26.4.1）后恢复，全部 CI 绿。

**Phase 4 P3 sprint 完成（2026-04-17 晚，8 PR 全合并）**：
- ✅ **PR #656** ADR-003：文档 frontmatter 5-layer YAML schema 决策
- ✅ **PR #657** Step 2+3：docs/ 全 40 文件 frontmatter HTML→YAML 迁移
- ✅ **PR #658** Step 4：Scripts/migrate + validate 脚本 + CI 校验门（含 PyYAML 自动安装修复）
- ✅ **PR #659** PR-I-W1：备份铁律三层拆分（Codex 方案 + cases.md `[Boundary]` 验收条）
- ✅ **PR #660** PR-I-W2：隐私五层拆分（混合方案：vision/req/compl Codex + business/design Claude）
- ✅ **PR #661** PR-I-I1：冲突裁决唯一源（design.md 改指针引用 vision）
- ✅ **PR #662** #540 Claude Code hooks 4 个：swift-autolint / block-dangerous-bash / premerge-checklist / prepush-lint
- ✅ **PR #663** #626 QuestionSplittingService PoC：Service + Protocol + Mock + @Generable schema + 单测（draft → ready 合并，待真机准确率验证）

**对抗起草纪录**：9 个对抗任务（T-05/06/07/08/09/14a/14b/15a/15b）三方独立产出 27 份方案，汇总比对见 `~/.claude/plans/phase4-p1-adversarial-summary.md` + Claude 4 份独立方案 `~/.claude/plans/adversarial-*-claude.md`。

**Gemini 幻觉事件**：T-07/08/09 Gemini 输出 OLD 原文全为虚构（编造章节号、Use Case 名称），已补充 `feedback_gemini_adversarial.md`：Gemini 引用仓库原文做 diff 不可信，仅作结构性建议参考。

**遗留待真机验证**：
- #626 PoC `QuestionSplittingService` Go/No-Go：边界准确率 >= 80%（10 份真实试卷），需 iOS 26 真机 + Apple Intelligence

**Phase 4 收官后的 tech-debt 清理（2026-04-17→19，3 PR）**：
- ✅ **PR #664** #638 ProfileListView 抽 ViewModel + 8 单测（删除错误路径无覆盖问题）
- ✅ **PR #665** #637 EditProfileView PhotosPicker 失败 UX 反馈 + 同图重选（2026-04-19 合并，Xcode Review 2 轮：R-1🔴+Y-1/2/3🟡 修复后验收通过）
- ✅ **PR #667** #666 swift-autolint hook 过滤文件级违规（修 hook bug）

**本轮发现的 tech-debt（已记录）**：
- Issue #666 swift-autolint 文件级 vs 行级 — 方案 A 修 hook 已合并；方案 B 拆 LocalizationKeys（1503 行）待独立 PR 排期

**下一候选**（用户排期）：
- #626 PoC 真机验证（QuestionSplittingService Go 后接入消费方）
- Apple 账号缴费开闸 → #163/#479/#485/#486/#490/#161 六个解锁

**本轮新增完成**（2026-04-19 晚）：
- **PR #688** Issue #666 方案 B：LocalizationKeys.swift 1503 行按 enum 拆 12 文件（L10n/ 子目录 + LocalizationHelper 独立），消除 SwiftLint file_length 豁免，清理 PR #665 留下的 TODO。三方对抗规划（Claude+Codex+Gemini），Codex 独家发现 LocalizationHelper 独立 enum。Xcode Review 2 轮（0🔴+1🟡 Y-1 顺手修复）验收通过。
- **PR #690** Harness Stage C/PR-6：引入 pointfreeco/swift-snapshot-testing，首批 7 个 SnapDrillUI public View 的 snapshot 测试 + 217 KB baseline 入 git。为解决 Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM 命名冲突，测试放 SnapDrillFeaturesTests。顺手修 Issue #666 hook 残留 bug（swift-autolint.sh 对 Package.swift 假阳性阻塞）。Xcode Review 2 轮（0🔴+1🟡 Y-1 hook/swiftlint 双向注释锚定）验收通过。
- **PR #691** Harness Stage C/PR-7（收官）：CI 集成 xcresult artifact upload（`if: failure()` + `actions/upload-artifact@v4`，保留 7 天），新增 `docs/workflow.md` 《CI 与本地一致性》章节。Xcode Review 首轮直接 **0🔴+0🟡+8🟢** 通过。Harness 三阶段 9 PR 收官。
- **PR #694/#695/#696** Codex 3 PR 方案（Harness 后首次真实 feature-adjacent sprint）：
  - 三方对抗规划 Codex 独家发现"CSV 导入已实现 + 0 测试 + 文档状态矛盾 + parser RFC 4180 偏差"，Gemini 与 Claude 初判错误（以为 Could Have 未做）
  - PR #694 CSV 行为锁定 19 tests（含 `__currentBehavior_` 锁 bug）
  - PR #695 parser 单字符状态机重写（字段内嵌换行 + CRLF/CR 归一化）+ CSVParser 独立文件解除 SettingsViewModel file_length 526 超门 + product-requirements.md 去矛盾。Codex 三方审 8.0 发现 🔴 BOM 未处理 → 追加 BOM 剥离 + 4 条边界测试（含未闭合引号宽松吞入锁定），Codex 验收 9.4 通过合并
  - PR #696 Features 层 internal View snapshot 扩展（`@testable import` 访问 Dashboard/Capture/Settings internal View）9 tests，Stage C snapshot 覆盖 7 → 16
- **发现的实战价值**：Codex rubric 4 维 + F-016 质疑方批准 + `__currentBehavior_` bug lock-in 模式在真实 sprint 吃狗粮成功。Codex 独家发现 3 个真实 risk（BOM / 文档矛盾 / 测试 0 覆盖）验证主锚点地位

### 本轮完成（2026-04-15~16，24 个 PR）

| PR | 内容 |
|---|---|
| #594 | 文档冻结 + 角标定案 |
| #595 | 文档扫描入口（3x2 网格） |
| #596 | AppActivityTracker 接线（7 个方法 defer） |
| #597 | CI 测试扩展（Core + Features，Data 跳过 #599） |
| #598 | E2E UI 测试（手动录入闭环） |
| #600 | 补救：TODO 注释 + F-013/14/15 纪律 |
| #601 | 多页文档扫描 + F-016 纪律 |
| #602 | Pro 门控关闭 + 连续录入修正 |
| #603 | 工程哲学迭代（4 条原则 + CI 陷阱 + XCUITest） |
| #604 | PrivacySettingsViewModel 测试（8 用例） |
| #605 | SmartPaperViewModel 测试（13 用例） |
| #606 | try? 第一批治理（4/12 处 do/catch + 日志） |
| #607 | 工程质量治理升级（纪律元数据 + AI 反模式检查 + CI 依赖守卫） |
| #609 | try? 第二批治理（ProfileMigration + ProfileManager 关键路径） |
| #611 | DashboardAnalyticsViewModel 测试（12 用例） |
| #613 | coding.md 补充 Swift 6.3 并发特性文档 |
| #614 | ProfileManager inMemory 写盘守卫 |
| #616 | CaptureView Liquid Glass 适配 |
| #617 | exportData Task.isCancelled 修复 CI flaky |
| #619 | 单文件多类型治理（6 文件拆分 + SwiftLint + coding.md） |
| #621 | 事后审计修复（5 个 Codex/Gemini Warning） |
| #623 | iOS 26 现代化（F-017 纪律 + DashboardAnalyticsView Liquid Glass） |
| #624 | 剩余 .regularMaterial 治理（BentoCard + ReviewHeroCard + PDFPagePicker + LibraryList） |

### 2026-04-16~17 晚间完成（13 个 PR + 1 研究 + 分支清理 + Gap 分析 + 中期审计 + 文档体系审计 + P2 sprint 启动）

| PR | 内容 |
|---|---|
| #628 | Data 测试死锁修复 — 对齐 Features 测试模式，318→351 tests |
| #629 | NSLocalizedString → L10n 统一（LiveNotificationService） |
| #630 | RecognizeDocumentsRequest 结构化文档识别（Protocol + 实现 + 测试） |
| #631 | ScanPagePicker/PDFPagePicker 迁移到 recognizeDocument（消费方） |
| #632 | FoundationModels 端侧 AI 自动标注学科/难度（contentTagging） |
| #633 | App Store 元数据预备（ASO 文案 + 隐私审查） |
| #634 | ContentTaggingService + NotificationService 测试补齐 |
| #636 | try? 第三批治理 + 三方对抗审查（Gemini+Codex+Xcode）+ 风格统一 |
| #640 | 中期审计校准（handoff Apple 表述 + codex-delegation effort high） |
| #642 | **Phase 4 P1**：SSOT 校准 — codex/gemini-delegation 迁移到 docs/standards/ |
| #644 | **Phase 4 P1**：新建 cross-audit skill 强制 F-008 三方审计纪律 |
| #646 | **Phase 4 P1**：api-reference 同步 — recognizeDocument + ContentTaggingService |
| #648 | **Phase 4 Step 1**：.claude/rules/ux-design.md 补 YAML frontmatter（12/12 全 YAML） |
| #650 | **Phase 4 P2 PR-D**：workflow.md F-008 改纯指针（collaboration + feedback 两处持） |
| #651 | **Phase 4 P2 PR-G**：archive/audit-report-20260409.md 加元信息 + memory/README 注记不可信 |
| #652 | **Phase 4 P2 PR-F + T-01**：collaboration Opus 4.7 + requirements 端上 AI 已实现毕业（含 MoSCoW 追补） |
| #653 | **Phase 4 P2 PR-H**：ux-design.md 移除失效 skill 引用（ux-designer/user-advocate） |
| #654 | **Phase 4 P2 PR-K**：Issue 模板去重 — workflow.md SSOT 指针 + feature_request.md 合并独有字段 |
| #655 | **Phase 4 P2 PR-E**：KNOWLEDGE_MAP + memory/README 校准（12→17 条，~25→~40 文件） |
| #656 | **Phase 4 P3 ADR-003**：YAML frontmatter 5-layer schema 决策 |
| #657 | **Phase 4 P3 Step 2+3**：docs/ 40 文件 HTML→YAML frontmatter 迁移 |
| #658 | **Phase 4 P3 Step 4**：Scripts/migrate + validate + CI 校验门 |
| #659 | **Phase 4 P3 PR-I-W1**：备份铁律三层拆分 |
| #660 | **Phase 4 P3 PR-I-W2**：隐私五层拆分（混合方案） |
| #661 | **Phase 4 P3 PR-I-I1**：冲突裁决唯一源 |
| #662 | **Phase 4 P3 #540**：Claude Code hooks 4 个运行时门（swift-autolint / block-dangerous-bash / premerge-checklist / prepush-lint） |
| #663 | **Phase 4 P3 #626**：QuestionSplittingService PoC（draft→ready 合并，待真机验证） |
| #664 | **tech-debt #638**：ProfileListView 抽 ViewModel + 8 单测（deleteProfile 错误路径覆盖） |
| #667 | **tech-debt #666**：swift-autolint hook 过滤文件级违规（修单文件 lint 假阳性） |
| — | #626 FoundationModels 可行性研究完成（结论已发到 Issue） |
| — | 历史分支全量清理（113→0，本地+远程纯净） |
| — | Gemini 对抗性审查：草稿恢复/删除撤销误判已验证，try? 残余已识别 |
| — | **2026-04-17 中期审计**：目标/约束/验收三维，发现 8 项脱轨点 + Scope 精化 |
| — | **2026-04-17 文档体系三方独立审计**：56 文件五维度审计，三方独立报告（Claude + Codex exec + Gemini）→ 综合报告 `~/.claude/plans/doc-audit-summary.md` |

### 当前开发焦点（2026-05-10）

**Phase 2 + Phase 2.N 收尾完成**。软件内部零阻塞问题。

**基线审计（2026-05-08→09）**：DeepSeek v4 Pro 全量逐字审计 ~45,500 行，Codex GPT-5.5 + Gemini 3 Pro 三方交叉验证。结果：**0 Critical / 14 Warning / 8 Info**，评分 8.5/10。详细报告 `docs/memory/checkpoints/2026-05-08-baseline-audit.md`。

**14 Warning 全部闭合**（PR #739 + #740）：13 修复 + 1 记录为有意设计（SnapDrillUITests 命名冲突）。X5 Share Extension EXIF 临时保留记录为设计级考虑，后续排期。

| 外部阻塞项 | 说明 | 状态 |
|---|---|---|
| Apple 开发者账号 (#163 链) | $99 年费待缴 | 用户控制 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 待真机验证 |
| TestFlight Build 6 (#161) | 需 Apple 账号 | 用户控制 |

### Apple 账号阻塞链（用户主动延迟至 5 月缴费）

Enrollment ID 83VZW7VJKK **已通过 Apple 审核**，$99 年费用户主动延迟到 2026-05。不是"等 Apple 审批"，而是"等用户决定何时缴费开闸"。所有下游功能随时可启动，节奏由用户控制。

| Issue | 内容 | 阻塞原因 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | 已通过审核，等用户缴费 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 ← #163 |
| #485 | iCloud CloudKit 同步 | 需 CloudKit Container + StoreKit ← #163 |
| #486 | Word 导出 | 需 StoreKit ← #163 |
| #490 | App Store 提交准备 | 需公司账号 + 真机验证 ← #163 |
| #161 | TestFlight Build 6 | 需真机验证 ← #163 |

### 待清理

- ~~113 个历史分支待清理~~ 已全部清理（本地 1 + 远程 2 = 纯净状态）

## 产品决策记录

> 决策通过 ADR 管理（`docs/decisions/`），此表为索引。

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | [ADR-002](docs/decisions/ADR-002-remove-att-authorization.md) |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | [ADR-001](docs/decisions/ADR-001-smart-paper-analytics-pricing.md) |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- 写 Xcode Review 提示词前，确认 STATUS.md 当前焦点段是最新的
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批
- Codex/Gemini 审查发现的问题，必须提交回原质疑方复核才能合并（F-016）
- CI 失败是致命信号，不能继续推进（F-007 时点 1）
- UI/SDK 改动必须先查阅 Apple 最新文档（F-017）

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
