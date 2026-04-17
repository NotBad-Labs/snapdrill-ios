<!-- last_verified: 2026-04-17 -->
<!-- layer: snapshot -->
<!-- freshness: max_age_days=7, decay_trigger=[pr_merge] -->
# SnapDrill 项目状态看板

> 最后更新：2026-04-17（晚间 P2 sprint 启动中）
> 编译状态：✅ 0 lint violations（本地）· ⚠️ CI 阻塞：Mac mini runner CoreSimulator 过时（1051.49.0 vs 1051.50.0）
> Open PR：3（#651/#652/#653 等 runner 修复重跑）· Open Issue：~10（Apple 阻塞 6 + #540/#626/#637/#638）
> 测试：158 tests（Features）+ 103 tests（Core）+ 95 tests（Data）= 356 total · ViewModel 覆盖 15/15 = 100%

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

**Phase 4 P2 sprint 进行中（2026-04-17 晚）**：
- ✅ **PR #650** PR-D F-008 去重（合并）— workflow.md:146 改纯指针
- 🟡 **PR #651** PR-G archive 标废弃（CI 阻塞）— audit-report-20260409.md 元信息 + memory/README 注记
- 🟡 **PR #652** PR-F 时效性修正（CI 阻塞）— collaboration Opus 4.6→4.7 + requirements 端上 AI 毕业
- 🟡 **PR #653** PR-H ux-design 失效 skill 修正（CI 阻塞）— 删除 ux-design.md:5 死引用
- 🔴 **PR-E 待启动**：KNOWLEDGE_MAP 文件数 25→39 + feedback 条数 12→17 + memory/README 同步（依赖 PR-G 先合并避免冲突）

**CI 阻塞根因**：Mac mini runner CoreSimulator 1051.49.0 < Xcode build 1051.50.0。需用户到家后重启 Mac mini 或 SSH 升级 CoreSimulator。修复后重跑 #651/#652/#653 即可。

**PR-F 漏洞待补**：requirements.md:250 MoSCoW Could Have 段仍列"端上 AI 集成（探索性）"，需在 PR-F 追加 commit 或 PR-E 捎带修正。

**下一候选**：
- **P3 sprint = PR-I 大 PR**：W1 备份铁律收敛 requirements + W2 隐私三层拆分 + I1 vision 唯一 + I2 全文档 YAML frontmatter + Step 3 产品文档 YAML 化（用户最终拍板决策已记忆）
- **P2 Step 2/4**：docs/principles + memory 14+4 文件 YAML 化 + Scripts/validate_frontmatter.py

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
| #642 | **Phase 4 P1**：SSOT 校准 — codex/gemini-delegation 迁移到 docs/principles/ |
| #644 | **Phase 4 P1**：新建 cross-audit skill 强制 F-008 三方审计纪律 |
| #646 | **Phase 4 P1**：api-reference 同步 — recognizeDocument + ContentTaggingService |
| #648 | **Phase 4 Step 1**：.claude/rules/ux-design.md 补 YAML frontmatter（12/12 全 YAML） |
| #650 | **Phase 4 P2 PR-D**：workflow.md F-008 改纯指针（collaboration + feedback 两处持） |
| — | #626 FoundationModels 可行性研究完成（结论已发到 Issue） |
| — | 历史分支全量清理（113→0，本地+远程纯净） |
| — | Gemini 对抗性审查：草稿恢复/删除撤销误判已验证，try? 残余已识别 |
| — | **2026-04-17 中期审计**：目标/约束/验收三维，发现 8 项脱轨点 + Scope 精化 |
| — | **2026-04-17 文档体系三方独立审计**：56 文件五维度审计，三方独立报告（Claude + Codex exec + Gemini）→ 综合报告 `~/.claude/plans/doc-audit-summary.md` |

### 当前开发焦点（待做）

| 优先级 | 工作项 | 说明 |
|---|---|---|
| P1 | **文档体系三方审计** | 中期审计发现：docs/rules/skills 从未独立 review，疑有重复/抽象缺失/知识未固化。计划按"目标-约束-验收"三维 Gemini+Codex+Xcode 三方审计 |
| P2 | CSV 导入功能 | Could Have，现有 CSV 导出的逆向操作 |
| P3 | Share Extension 集成验证 | App Group 已配置，需端到端验证 |
| P3 | #626 FoundationModels 题目分割 | 整页扫描自动分割题目（需 PoC） |
| P3 | #540 Claude Code hooks 扩展 | 待排期 |
| P3 | #637 EditProfileView PhotosPicker UX | 加载失败无反馈 + 同张照片无法重试（合并 Xcode Y-1） |
| P3 | #638 ProfileListView 测试覆盖 | deleteProfile 错误路径缺自动化保护 |

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
- CI 失败是致命信号，不能继续推进（F-015）
- UI/SDK 改动必须先查阅 Apple 最新文档（F-017）

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
