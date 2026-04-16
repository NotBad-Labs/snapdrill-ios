<!-- last_verified: 2026-04-16 -->
<!-- layer: snapshot -->
<!-- freshness: max_age_days=3, decay_trigger=[pr_merge,branch_change] -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code
- 主分支：`develop`
- 当前工作分支：无（develop 上）

## 待合并 PR

无。

## 关键事实（当前快照）

- **文档冻结 + 功能开发 + 工程治理阶段**（2026-04-14 冻结，2026-04-15-16 密集开发 24 个 PR）
- 测试基线：223 tests（Core 65 + Features 158），ViewModel 覆盖 15/15 = 100%
- 纪律规则：F-001~F-017（含治理元数据：permanent/timeboxed 分类）
- 工程治理升级：AI 反模式检查表 + cross-audit 回灌闭环 + agent 冲突裁决模板
- CI 新增 Check Package Dependencies step（5 条依赖方向检查）
- SwiftLint file_length error 收紧到 600
- 6 个文件拆分完成（CaptureMethodCard、ReviewCardBack、CameraSessionManager、AppError、EditSubjectView、EditSourceView、DataExporter）
- 全项目 .regularMaterial → Liquid Glass / 语义色完成（0 处残留）
- coding.md 新增：Swift 6.3 特性 + 文件组织规则
- try? 治理：两批完成，关键路径全部 do/catch + 日志
- ProfileManager inMemory 写盘守卫完成
- exportData Task.isCancelled 修复（CI flaky 根因）
- 事后审计修复：configureSession defer + AppError 逃生舱 + createProfile 返回值 + 空 profiles 恢复
- Pro 功能门控已关闭（isProUser=false），等 #479 StoreKit
- #599 Data Repository CI 死锁：需 Mac mini 现场排查（PR #612 验证 simctl erase 无效）
- iOS 26 / Xcode 26.4 / Swift 6.3

## 后续 Issue

| Issue | 内容 | 优先级 |
|---|---|---|
| #599 | Data Repository CI 死锁 | P1（需 Mac mini） |
| #625 | RecognizeDocumentsRequest 升级 | P2 |
| #627 | NSLocalizedString → L10n | P2 |
| #626 | FoundationModels 端侧 AI 调研 | P3 |
| #540 | Claude Code hooks 扩展 | P3 |
