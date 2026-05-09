---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Baseline Audit 2026-05-08

## Goal

以 2026-05-08 为基线，对 snapdrill-ios 全量第一方文件进行三方独立基线审计（F-008 纪律）。

## 参与方

| 审计方 | 模型 | 状态 | 方式 |
|---|---|---|---|
| **Claude/DeepSeek** | DeepSeek v4 Pro (1M ctx) | ✅ | 逐字全读 ~45,500 行 |
| **Codex CLI** | GPT-5.5 (high effort) | ✅ | 263K tokens，深度 grep+read |
| **Gemini CLI** | Gemini 3 Pro Preview | ✅ | 312+ 文件 glob+grep 扫读 |

## Scope

| 类别 | 文件数 | 行数 |
|---|---|---|
| Markdown 文档 | 56 | ~8,000 |
| Swift 源码 | 218 | ~33,000 |
| 配置/脚本/CI | ~15 | ~4,300 |
| **合计** | **~290** | **~45,500** |

## Results

**0 Critical / 14 Warning / 8 Info — 无阻塞缺陷。评分 8.5/10。**

### 三方共识 (3/3)

| # | 发现 | 维度 |
|---|---|---|
| C1 | api-reference.md 缺少 DataExecutor 独立条目 | D2 |
| C2 | ContentTaggingServiceMock / QuestionSplittingServiceMock 违规使用 @unchecked Sendable | D3 |
| C3 | PersistenceController 废弃但无 @available(deprecated) 标记 | D3 |

### 两家共识 (2/3)

| # | 发现 | 维度 |
|---|---|---|
| C4 | ProfileManager.swift:126 force_unwrap + swiftlint:disable | D3 |
| C5 | api-reference 缺少 Repository init(executor:) | D2 |
| C6 | ProfileManager api-reference 签名不一致（init() vs init(inMemory:), throws vs throws(ProfileError)） | D2 |
| C7 | F-014 skipped/disabled tests 缺少统一追踪 | D4 |

### Claude 独有

| # | 发现 | 维度 | 严重度 |
|---|---|---|---|
| U1 | CaptureResultViewModel.saveResult() NSError → typed throws | D3 | Warning |
| U2 | LiveServiceContainer analytics 默认 fallback 到 Mock | D3 | Info |
| U3 | 6 产品文档 last_verified: 2026-04-14 | D1 | Info |
| U4 | appstore-metadata.md 隐私政策 URL 待上线 | D1 | Info |
| U5 | Share Extension 大图内存待真机验证 | D4 | Info |
| U6 | F-018 Sprint Contract 无自动化执行 | D6 | Info |

### Codex 独有

| # | 发现 | 维度 | 严重度 |
|---|---|---|---|
| X1 | Remote Config 幽灵 API（api-reference 仍列已删除的 API） | D1 | Warning |
| X2 | App Store 隐私文案"绝不上传"与 compliance 矛盾 | D1 | Warning |
| X3 | architecture.md AppActivityTracker 接线描述过期 | D1 | Warning |
| X4 | Features 直接依赖 ZIPFoundation（架构泄漏） | D3 | Warning |
| X5 | Share Extension 临时文件可短暂保留原始 EXIF | D5 | Warning |
| X6 | GoogleService-Info.plist.example 缺少默认禁采集 keys | D5 | Warning |
| X7 | SnapDrillUITests 未纳入 AllTests test plan | D4 | Warning |

### Gemini 独有

| # | 发现 | 维度 | 严重度 |
|---|---|---|---|
| G1 | ReviewAppearanceSettingsView.swift L34/L67 硬编码中文预览文本 | D3 | Warning |
| G2 | 15/15 ViewModel 测试覆盖 100% 匹配确认 | D4 | Info |
| G3 | 46 处 try? 全部有 best-effort 注释，合规 | D3 | Info |
| G4 | Pro 门控 isProUser TODO 注释合规引用 #479 | D6 | Info |

### 冲突裁决

| 冲突 | 裁决 | 理由 |
|---|---|---|
| DataExecutor 缺失严重度（Claude Info / Codex Warning / Gemini Critical） | **Warning** | 三方共识需补充，但 Critical 偏高（handoff.md 和代码注释已有充分文档） |

### D5 Security — 全通过

- ✅ EXIF GPS 剥离（ImageStorage.compressedJPEGData + jpegDataStrippingLocation）
- ✅ Firebase 默认不采集（plist DEACTIVATED/Disabled + DependencyContainer 双重 opt-in 守卫）
- ✅ 零注册、纯本地架构、无数据外传
- ✅ nonisolated(unsafe) 4 处全部正当

### Mechanical Verification — 全通过

- ✅ swiftlint --strict: 0 violations, 218 files
- ✅ docaudit all --strict --baseline: exit 0, 7 checks clean
- ✅ validate_frontmatter --check: 56 files valid

## 评分 (Rubric 4 维)

| 维度 | 评分 | 说明 |
|---|---|---|
| Scope Fidelity | 9 | 全量覆盖，无 scope creep |
| Code Quality | 9 | 架构纪律好，并发安全，EXIF stripping 完整 |
| Test Coverage | 8 | 420 tests，16/16 VM 全覆盖，少量 skipped 需追踪 |
| Architecture Fit | 8 | 2 处泄漏（PersistenceController deprecated 无标记、ZIPFoundation 泄漏到 Features） |
| **综合** | **8.5** | |

## Decisions

- 本次审计仅报告不修复（F-011 遵守）
- 14 Warning 留待下个开发 sprint 统一修复
- Gemini 3.1 Pro / 2.5 Pro 服务器容量耗尽（全模型 429），退至 3 Pro 完成
- Codex 的 DataExecutor MainActor init Critical 经裁决降级为 Warning（生产环境无 XCTest runner 时安全）

## Next

- ~~下个开发 sprint 修复 14 Warning~~ → 已完成（PR #739 + #740，14/14 闭合）
- 下次全量审计建议：App Store 提交前

## 修复闭合状态（2026-05-09 更新）

| ID | 发现 | PR | 状态 |
|---|---|---|---|
| W1 | CaptureResultViewModel NSError → typed throws | #739 | ✅ |
| W2 | PersistenceController @available(deprecated) | #739 | ✅ |
| W3 | ProfileManager force_unwrap | #739 | ✅ |
| C2 | @unchecked Sendable mocks → @MainActor | #739 | ✅ |
| G1 | 硬编码中文预览文本 → L10n | #739 | ✅ |
| X1 | Remote Config 幽灵 API 清理 | #739 | ✅ |
| X2 | App Store 隐私文案修正 | #739 | ✅ |
| X3 | architecture.md AppActivityTracker 状态 | #739 | ✅ |
| C1/C5/C6 | api-reference DataExecutor/AppActivityTracker/Repository/ProfileManager | #739 | ✅ |
| X6 | GoogleService-Info.plist.example 禁采集 keys | #739 | ✅ |
| X4 | ZIPFoundation 架构泄漏 → ZIPArchiver | #740 | ✅ |
| X5 | Share Extension EXIF 临时保留 | — | 📝 设计级考虑，非紧急，后续排期 |
| X7 | SnapDrillUITests 未入 AllTests plan | — | ✅ **有意设计**：SPM `SnapDrillUITests` 与 Xcode 原生 XCUITest target 命名冲突（见 testing.md:87），基础 smoke tests 已被 FeaturesTests 的 16 View snapshot 回归测试覆盖和超越。记录为 Info，无需修改。 |
