# SnapDrill 项目状态看板

> 最后更新：2026-04-09
> 编译状态：✅ 0 errors · 0 lint violations · CI 全绿
> Open PR：0 · Open Issue：8

---

## 当前焦点

智能体架构精简已合并（#573），CI 全绿。Layer 0 引导层三方审计已完成并提交。
下一步：#486 Word 导出（依赖 StoreKit，被 Apple 开发者账号阻塞）。
当前可做：引导层/流程层/产品层/技术层文档审计（不依赖外部阻塞）。

### 今日已完成

- #573 chore: #572 智能体协作架构精简 — 移除 Coze/OpenClaw，重建稳定工具链 + 修复 softDeleteItems 测试 crash（DeletionScheduler 单例遗留 Task，Claude/Codex 交叉诊断一致）
- #571 fix: #570 审计修复 — COPPA 合规（plist 预禁用 + opt-in 激活）+ Profile 切换保护（AppActivityTracker 中心状态机）+ Soft Delete 下沉（DeletionScheduler App 级）+ 隐私文案修正 + Analytics 纵深防御 + 性能基准测试 + GDPR 跨境方案
  - 三方审计：Claude 代码验证 → Codex 独立验证 → Antigravity 方案审阅
  - Codex Review 4 blocker 修复 + Xcode Review 2 RED 修复 + 二轮验收通过
- #569 fix: #568 三方深度审计修复 — 异步头像加载 + ZIPFoundation 依赖声明（Xcode Review 二轮验收）
- #567 feat: #488 高级统计 — 学科趋势图 + 难度分布 + 薄弱排行（Swift Charts，三方设计 + 三方审查 + Xcode Review）
- #566 feat: #487 智能组卷 — SM-2 选题 + 配置页 + PDF 预览（三方设计 + 三方审查 + Xcode Review 二轮验收）
- #565 fix: #564 ExportPreviewView actor isolation 警告
- #563 fix: #532 TipKit 状态按 Profile 隔离
- 三方深度审计 Track 1（产品完整性 98.8%）+ Track 2（架构健康 0 Critical）+ Track 3（代码质量 1 Critical 已修复）
- `.claude/rules/coding.md` + `api-pitfalls.md` 新增 Task 闭包 actor isolation 规则
- ExportPreviewView 去掉嵌套 NavigationStack（Xcode Review R1，既有问题一并修复）
- 记忆系统优化：新增 Xcode Review feedback + 知识路由表

### 待处理

| 严重度 | 事项 | 状态 |
|---|---|---|
| S3 | Issue #540 Hooks 扩展（需深入研究协议） | 待排期 |

### 历史已完成（详见 git log）

累计合并 60+ PR，覆盖：基础架构（Multi-Profile、CI）、功能扩展（12 个 feat PR）、文档审计（4 轮，含三方交叉审计）、S0 数据安全修复、产品文档深度审计、Claude Code 配置改进、知识演进体系。完整记录见 `git log --oneline`。

### 待做（依赖公司 Apple 开发者账号）

| Issue | 内容 | 解除条件 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | Enrollment 已提交（ID: 83VZW7VJKK），等 Apple 审核 1-3 天 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 |
| #485 | iCloud 同步 | 需 CloudKit Container + StoreKit |
| #486 | Word 导出 | 需 StoreKit |
| #487 | 组卷排版打印 | 功能代码已完成（#566），付费开关需 StoreKit |
| #488 | 高级统计 + 趋势图 | 功能代码已完成（#567），付费开关需 StoreKit |
| #490 | App Store 提交准备 | 需公司账号 + 真机验证 |
| #161 | TestFlight Build 6 | 需真机验证 |
| #162 | GitHub Pro Branch Protection | 等 GitHub Pro 生效 |

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

| 日期 | 决策 | 依据 |
|---|---|---|
| 2026-04-07 | 图片处理增强（去手写/去批改痕迹/试卷还原）纳入 Pro 层 | 横向研究 7 款 App，"免费限次体验 + Pro 无限"行业验证模式 |
| 2026-04-07 | 价值链定稿：采集→管理→导出/打印，复习移出价值链 | "存储"是技术实现非用户行为；复习是独立附加值可砍 |
| 2026-04-01 | 定价：中国区 ¥8/月，美区 $1.99/月，Lifetime ¥298/$49.99 | 横向研究 Infuse/Bear/Craft 后确立 |
| 2026-04-01 | Grandfather 涨价策略 | Bear 模式：老用户保原价，涨价只影响新用户 |
| 2026-04-01 | 全免费发布 | 先积累口碑和用户基数 |
| 2026-04-01 | Multi-Profile 免费、导出/打印免费 | 基础可用性不应付费 |
| 2026-03-31 | SM-2 重新定位：智能选题打印（Pro 付费） | 进阶能力，需用户先完成练习闭环 |
| 2026-03-31 | 三基石修正：采集 + 存储 + 导出/打印 | 产品价值链终点是纸质练习卷 |

## 协作纪律备忘

- 涉及 UI/外观的改动，优先让 Xcode Review（Xcode 能观测 UI）
- 写 Xcode Review 提示词前，确认 STATUS.md 当前焦点段是最新的（两边共享状态）；"已完成"记录只在 PR 合并后写入
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
