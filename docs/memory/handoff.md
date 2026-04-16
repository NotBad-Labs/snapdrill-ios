<!-- last_verified: 2026-04-17 -->
<!-- layer: snapshot -->
<!-- freshness: max_age_days=3, decay_trigger=[pr_merge,branch_change] -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code（Opus 4.6 → 即将交接给 Opus 4.7）
- 主分支：`develop`
- 当前工作分支：无（develop 上，纯净状态）
- 仓库分支：本地 1（develop） + 远程 2（develop + main）

## 待合并 PR

无。

## 关键事实（当前快照）

### 项目状态
- **Must Have + Should Have 全部完成**，免费版功能齐全
- 测试基线：356 tests（Core 103 + Data 95 + Features 158），ViewModel 覆盖 15/15 = 100%
- CI：Mac mini 自托管 runner，全绿，~1.5min
- SwiftLint：0 violations（195 files）
- iOS 26.0+ / Xcode 26.4 / Swift 6.3 / defaultIsolation(MainActor)

### 本会话完成的工作（2026-04-16~17，7 个 PR）
- **#628** Data 测试死锁修复（根因：PersistenceController + async + MainActor 死锁 → 对齐 Features 测试模式）
- **#629** NSLocalizedString → L10n 统一（LiveNotificationService）
- **#630** RecognizeDocumentsRequest 结构化文档识别（OCRServiceProtocol + OCRService）
- **#631** ScanPagePicker/PDFPagePicker 迁移到 recognizeDocument
- **#632** FoundationModels 端侧 AI 自动标注学科/难度（ContentTaggingService）
- **#633** App Store 元数据预备（docs/product/appstore-metadata.md）
- **#634** ContentTaggingService 测试补齐

### Gap 分析结论（Gemini 对抗审查已校准）
- Gemini 提出 2 个 Critical（草稿恢复/删除撤销缺失）→ 经代码验证均为**误判**，两者完整实现
- Gemini 有效发现：try? 残余 31 处需审计

### Codex 状态
- 额度已用完（2026-04-16），每日刷新
- 本会话全部用 Gemini CLI 替代（5 次审计调用）

### 纪律规则
- F-001~F-017（含治理元数据：permanent/timeboxed 分类）
- 详见 `docs/memory/feedback.md`

## 后续待做（非 Apple 账号阻塞）

| 优先级 | 工作项 | 说明 | 预估 |
|---|---|---|---|
| P2 | try? 第三批治理 | 31 处残余（21 个文件），数据路径改 do/catch + 日志，清理路径保留 | ~1h |
| P2 | CSV 导入功能 | Could Have，现有 CSV 导出的逆向操作（CSVImportService + UI） | ~2h |
| P3 | Share Extension 集成验证 | App Group 已配置（group.com.snapdrill.app），需端到端验证 | ~30min |
| P3 | #626 FoundationModels 题目分割 | 基础设施已就绪（RecognizeDocumentsRequest），需 PoC + UI | ~3h |
| P3 | #540 Claude Code hooks 扩展 | 需深入研究 hook 协议后实现，3-5 天 | 3-5d |

## Apple 账号阻塞链（2026-05-01 后处理）

| Issue | 内容 | 依赖 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | Enrollment 已提交（ID: 83VZW7VJKK） |
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
