# SnapDrill 项目状态看板

> 最后更新：2026-04-12
> 编译状态：✅ 0 errors · 0 lint violations · CI 全绿
> Open PR：1（#582）· Open Issue：8

---

## 当前焦点

PR #582 待 Review：Share Extension 后台读图 + AppActivityTracker 全链路接线 + DeletionScheduler 测试。
Codex 在 develop 上并行进行代码审计和静默失败治理（#574、#581），尚未提交。
测试覆盖：135 tests passed（原 125 + 新增 DeletionScheduler 10 cases）。

### 今日已完成（2026-04-12，worktree claude/serene-elion）

- #579 perf: Share Extension 图片读取迁移到后台线程（`Task.detached`）
- #580 refactor: AppActivityTracker begin/end 全链路接线（采集/导出/打印/备份恢复 4 类，10 begin + 18 end）
  - `switchBlockReason` 改中文描述，移除 TODO
  - SettingsViewModel 提取 `beginBackupActivity()/endBackupActivity()` helper
- #574 test: DeletionScheduler 状态机专属测试 10 cases（scheduleDeletion、undo、commitImmediately、连续调度、5 秒倒计时）
- fix: BackupService 旧备份清理改为显式日志（try? → do/catch）
- fix: SmartCameraView DispatchQueue.main.async → Task（结构化并发）
- 质量评估：Codex 在 develop 上的 40+ 文件未提交改动（代码审计 + 文档治理 + 静默失败治理）

### 待处理

| 严重度 | 事项 | 状态 |
|---|---|---|
| S2 | #574 DeletionScheduler 状态机完整性 | Codex 本地修复已落地，待测试闭环和 PR |
| S2 | #579 Share Extension 主线程阻塞 | ✅ PR #582 |
| S2 | #580 AppActivityTracker 接线 | ✅ PR #582 |
| S2 | #581 Data 层静默失败治理 | Codex 进行中 |
| S2 | #540 Hooks 扩展（需深入研究协议） | 待排期 |

### 历史已完成（详见 git log）

累计合并 60+ PR，覆盖：基础架构（Multi-Profile、CI）、功能扩展（12 个 feat PR）、文档审计（4 轮，含三方交叉审计）、S0 数据安全修复、产品文档深度审计、Claude Code 配置改进、知识演进体系。完整记录见 `git log --oneline`。

### 待做（依赖公司 Apple 开发者账号）

| Issue | 内容 | 解除条件 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | Enrollment 已提交（ID: 83VZW7VJKK），等 Apple 审核 1-3 天 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 |
| #485 | iCloud 同步 | 需 CloudKit Container + StoreKit |
| #486 | Word 导出 | 需 StoreKit |
| #490 | App Store 提交准备 | 需公司账号 + 真机验证 |
| #161 | TestFlight Build 6 | 需真机验证 |

### 暂缓（Phase 4，探索性）

| 事项 | 定位 |
|---|---|
| 手写体识别增强 | 需 PoC 验证识别率 |
| AI 辅助拆题 | 需 Foundation Models PoC |
| 端上 AI 集成 | 等 iOS 26 正式发布 |
| 数理化公式识别 | 无 Apple 原生 API |
| 去手写/去批改痕迹/试卷还原 | Pro 付费（免费限次体验），需第三方端上方案 PoC |
| 探索性 PoC（Foundation Models / App Intents） | 技术预研 |

## 产品决策记录

> 基线重置后的决策通过 ADR 管理（`docs/decisions/`），此表为索引。基线前的历史决策保留原格式。

| 日期 | 决策 | ADR / 依据 |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | [ADR-002](docs/decisions/ADR-002-remove-att-authorization.md)（三方一致） |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | [ADR-001](docs/decisions/ADR-001-smart-paper-analytics-pricing.md)（三方研究） |
| 2026-04-07 | 图片处理增强纳入 Pro 层 | 横向研究 7 款 App |
| 2026-04-07 | 价值链定稿：采集→管理→导出/打印 | 复习是独立附加值 |
| 2026-04-01 | 定价：¥8/月，$1.99/月，Lifetime ¥298/$49.99 | 横向研究 Infuse/Bear/Craft |
| 2026-04-01 | Grandfather 涨价策略 | Bear 模式 |
| 2026-04-01 | 全免费发布 | 先积累口碑 |
| 2026-04-01 | Multi-Profile/导出/打印免费 | 基础可用性不应付费 |
| 2026-03-31 | SM-2 → 智能选题打印（Pro） | 进阶能力 |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- 写 Xcode Review 提示词前，确认 STATUS.md 当前焦点段是最新的（两边共享状态）；"已完成"记录只在 PR 合并后写入
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
