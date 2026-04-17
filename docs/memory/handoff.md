<!-- last_verified: 2026-04-17 -->
<!-- layer: snapshot -->
<!-- freshness: max_age_days=3, decay_trigger=[pr_merge,branch_change] -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code（Opus 4.7，已升级）
- 主分支：`develop`
- 当前工作分支：无（develop 上，纯净状态）
- 仓库分支：本地 1（develop） + 远程 2（develop + main）

## 待合并 PR

无。本会话所有 PR 已合并：#640/#642/#644/#646/#648。

## 重要审计产出（新会话必读）

`~/.claude/plans/doc-audit-summary.md` — 文档体系三方独立审计综合报告
- 三方独立审计：Claude（核心治理）+ Codex `exec --full-auto`（全量）+ Gemini（产品文档）
- 五维度发现：DRY / YAGNI / Skill 化 / 一致性 / 时效性
- 误判归档：Gemini 关于 ASO 虚假宣传的 Critical 已实证反驳
- Phase 4 PR 候选清单 P1-P3
- 用户 PR-I 决策已拍板（W1 Codex 方案 / W2 三层拆分 / I1 vision 唯一 / I2 YAML frontmatter）

## 关键事实（当前快照）

### 项目状态
- **Must Have + Should Have 全部完成**，免费版功能齐全
- 测试基线：356 tests（Core 103 + Data 95 + Features 158），ViewModel 覆盖 15/15 = 100%
- CI：Mac mini 自托管 runner，全绿，~1.5min
- SwiftLint：0 violations（195 files）
- iOS 26.0+ / Xcode 26.4 / Swift 6.3 / defaultIsolation(MainActor)

### 本会话完成的工作（2026-04-16~17，12 个 PR + 中期审计 + 文档体系三方独立审计）
- **#628** Data 测试死锁修复（根因：PersistenceController + async + MainActor 死锁 → 对齐 Features 测试模式）
- **#629** NSLocalizedString → L10n 统一（LiveNotificationService）
- **#630** RecognizeDocumentsRequest 结构化文档识别（OCRServiceProtocol + OCRService）
- **#631** ScanPagePicker/PDFPagePicker 迁移到 recognizeDocument
- **#632** FoundationModels 端侧 AI 自动标注学科/难度（ContentTaggingService）
- **#633** App Store 元数据预备（docs/product/appstore-metadata.md）
- **#634** ContentTaggingService 测试补齐
- **#636** try? 第三批治理（#635 闭合）：1 关键路径 + 7 日志 + 11 注释 + 3 对抗补救 + 2 风格统一。三方审计（Gemini + Codex + Xcode Intelligence）
- **中期审计 2026-04-17 早**：按目标/约束/验收三维，识别 8 项脱轨点，STATUS + handoff + codex-delegation 校准（PR #640 闭合）
- **#642** Phase 4 P1 SSOT 校准：codex/gemini-delegation 迁移 .claude/rules/ → docs/principles/
- **#644** Phase 4 P1 cross-audit skill：强制 F-008 三方审计纪律
- **#646** Phase 4 P1 api-reference 同步：recognizeDocument + ContentTaggingService（Codex 独有发现）
- **#648** Phase 4 Step 1：.claude/rules/ux-design.md 补 YAML frontmatter（12/12 全 YAML）
- **文档体系三方独立审计 2026-04-17 晚**：56 文件五维度，三方独立报告 → 综合报告 `~/.claude/plans/doc-audit-summary.md`

### Gap 分析结论（2026-04-17 已闭合）
- Gemini 提出 2 个 Critical（草稿恢复/删除撤销缺失）→ 经代码验证均为**误判**，两者完整实现
- Gemini 有效发现 try? 残余 → PR #636 已全量盘点（50 处 / 28 文件）并按 F-006 治理完毕

### Codex + Gemini 状态（2026-04-17 升级）
- Codex CLI v0.120.0 → v0.121.0，额度刷新
- Gemini CLI v0.37.0 → v0.38.1
- 规范升级：审计类任务默认 effort medium → **high**（Codex v0.121.0 + GPT-5.4 改善搜索循环）

### 纪律规则
- F-001~F-017（含治理元数据：permanent/timeboxed 分类）
- 详见 `docs/memory/feedback.md`

## 后续待做（非 Apple 账号阻塞）

| 优先级 | 工作项 | 说明 | 预估 |
|---|---|---|---|
| P1 | **文档体系审计 P2 sprint** | 原 PR-D F-008 去重 / PR-E KNOWLEDGE_MAP 校准 / PR-F Opus 4.7+requirements AI / PR-G archive 标废弃 / PR-H ux-design 失效 skill + Step 2 (docs/principles+memory 18 文件 YAML 化) + Step 4 (Scripts/validate_frontmatter.py) | ~3-4h |
| P1 | **文档体系审计 P3 sprint = PR-I 大 PR** | W1 Codex 方案 (requirements 持铁律) + W2 三层拆分 (vision/requirements/compliance) + I1 vision 唯一 + I2 全文档 YAML frontmatter + Step 3 产品文档 YAML 化（用户拍板决策已记忆） | ~3-5h |
| P2 | CSV 导入功能 | Could Have，现有 CSV 导出的逆向操作（CSVImportService + UI） | ~2h |
| P3 | Share Extension 集成验证 | App Group 已配置（group.com.snapdrill.app），需端到端验证 | ~30min |
| P3 | #626 FoundationModels 题目分割 | 基础设施已就绪（RecognizeDocumentsRequest），需 PoC + UI | ~3h |
| P3 | #540 Claude Code hooks 扩展 | 需深入研究 hook 协议后实现，3-5 天 | 3-5d |
| P3 | #637 EditProfileView PhotosPicker UX | 加载失败无反馈 + 同张照片无法重试 | ~30min |
| P3 | #638 ProfileListView 测试覆盖 | deleteProfile 错误路径 | ~1-2h |

## Apple 账号阻塞链（用户主动延迟至 2026-05 缴费）

Enrollment ID 83VZW7VJKK **已通过 Apple 审核**，\$99 年费用户主动延迟到 2026-05。不是"等 Apple 审批"，而是"等用户决定何时缴费开闸"。下游所有功能随时可启动，节奏由用户控制。

| Issue | 内容 | 依赖 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | 已通过审核，等用户缴费 |
| #479 | StoreKit 付费墙 | ← #163 |
| #485 | iCloud CloudKit 同步 | ← #163 + #479 |
| #486 | Word 导出 | ← #479 |
| #490 | App Store 提交 | ← #163（ASO 文案已预备 PR #633） |
| #161 | TestFlight Build 6 | ← #163 |

## 技术提醒

### 已验证的 iOS 26 新 API
1. **RecognizeDocumentsRequest**（Vision）— OCRService.recognizeDocument，ScanPagePicker/PDFPagePicker 已接入
2. **FoundationModels**（contentTagging）— ContentTaggingService，CaptureResultViewModel 已集成
   - `SystemLanguageModel.default.isAvailable` 在 Simulator 上检查耗时 ~150s → 测试中不调用生产实现
   - `nonisolated struct` 在 Swift 6.3 + defaultIsolation(MainActor) 下合法

### 已踩坑记录
- `defaultIsolation(MainActor)` + `async` + `PersistenceController.init` = 死锁（#599，PR #628 修复）
- `modelContext.delete(model:)` 批量删除不影响 context 中未保存的对象（TagRepository 测试修复）
- `fetchOrCreateModel` 只 insert 不 save → deleteAll 前需先 saveContext
- SwiftLint file_length 500 行限制 → CaptureResultViewModel 492 行（临近）
- Profile JSON round-trip：iso8601 截断亚秒精度 → 用固定时间戳测试

### Gemini CLI 使用要点
- 不加 `--sandbox`（性能 2x 损失）
- prompt 必须内联 `docs/principles/shared-constraints.md`
- 每批 2-3 个文件（防超时）
- Gemini 不知道 iOS 26 API → prompt 需内联项目约束
- Gemini 审计结论需 Claude 交叉验证（本次有 2 个 Critical 误判）
