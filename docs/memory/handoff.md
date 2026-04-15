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

- **文档冻结 + 功能开发阶段**（2026-04-14 冻结，2026-04-15-16 开发 12 个 PR）
- 测试基线：211 tests（Core 65 + Features 146），ViewModel 覆盖 14/14 = 100%
- Pro 功能门控已关闭（isProUser=false），等 #479 StoreKit
- 文档扫描：入口接入 + 多页支持 + 连续录入修正 完成
- AppActivityTracker：7 个方法 defer 保护 + switchBlockReason 本地化 完成
- E2E UI 测试：手动录入闭环，--uitesting in-memory 隔离 完成
- 工程哲学：4 条新原则 + CI 陷阱 + XCUITest 策略 + 4 条新纪律（F-013~F-016）
- try? 治理：第一批 4/12 处完成（CaptureDraft + Backup），剩余 8 处待做
- #599 Data Repository CI 死锁：AllTests 中 skipped，待 Mac mini 现场排查
- iOS 26 / Xcode 26.4 / Swift 6.3
