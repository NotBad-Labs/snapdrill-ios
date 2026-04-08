# SnapDrill 项目状态看板

> 最后更新：2026-04-08
> 编译状态：✅ 0 errors · 0 lint violations · CI 绿色
> Open PR：0 · Open Issue：11（#532 TipKit 隔离、#540 Hooks 扩展、#162 #163 外部阻塞、#161 TestFlight Build 6 等）

---

## 当前焦点

全量文档审计（56 份）+ CI 修复完成。下一优先级：#532 TipKit 决策（2026-04-15 前）。

### 待处理

| 优先级 | 事项 | 状态 |
|---|---|---|
| P2 | Issue #532 TipKit 状态按 Profile 隔离 | 待决策，2026-04-15 前（Gemini 独有发现） |
| P2 | Issue #540 Hooks 扩展（需深入研究协议） | 待排期 |

### 已完成（CI 修复）

- #562 fix: CI 连续 4 天全红修复 — restoreFromBackup repos 对称性（三方一致诊断：备份/恢复 repos 不一致）
- #558 fix: Profile 切换 S0 保护 — 草稿拦截 + .strings 本地化（Xcode Review 通过）

### 已完成（产品文档审计修复）

- #560 docs: 三方全量文档审计修复（非产品文档 49 份）— 16+5 个发现修复（Codex 发现 BackupService 签名/Schema V4→V1/Tests 路径；Coze 补审 README 定位/DocC 补全）
- #557 docs: 三方对抗性审计修复 — Claude+Codex+Coze 35 个发现全量修复（首次三方独立审计+独立 Review 闭环；Coze 脚本升级：完整文件模式+项目基线注入+网络搜索验证）
- Issue 清理：三方独立审查后关闭 #452（产品战略复核，已被审计覆盖）、#477（Share Extension，代码已完整实现）；更新 #540/#162/#161 描述
- #554 docs: 文档体系架构重构 — Glossary 定位修正 + 信息去重 + 未实现标注（首次三方审查：Claude+Codex+Coze，Coze 独有发现 2 项已修正）
- #551 docs: 竞品分析补全 — 新增隐形竞品分析（Apple 备忘录/Notion/GoodNotes，Codex 事实性核验修正通过）
- #552 docs: 成功指标量化 — 6 条成功信号改为可度量表格（Codex 审查 + journeys 口径同步）
- #548 docs: Pro 层增强 — 图片处理增强纳入 Pro 规划（横向研究 7 款 App，Codex 对抗性审查通过）
- #546 docs: 统一价值链定义 — 采集→管理→导出/打印，复习移出价值链（9 文件统一，Codex 对抗性审查通过）
- #544 docs: 产品文档审计修复 — #531 状态过期清理、元规则矛盾修正、日期噪音移除、情绪化措辞客观化、数据来源标注（Codex 两轮对抗性审查通过）

### 已完成（S0 数据安全修复）

- #542 fix: 恢复原子性 — 图片失败回滚 + 自动备份条件清理（Codex Review 6/6 通过）
- #531 feat: 全 Profile 备份 — 备份覆盖所有 Profile 数据和图片（Codex Review 6/6 通过）

### 已完成（Claude Code 配置改进）

- #541 chore: CLAUDE.md 收敛 104→75 行（协作模式迁到 rules、执行铁律精简、按需上下文压缩，Codex 两轮验收通过）
- #539 chore: Skills frontmatter 升级（pr-review-workflow + update-status 加 context:fork + disable-model-invocation）+ 项目级 settings.json + log-file-change.sh 路径修复
- #538 fix: compact-reminder.md 恢复（2026-03-23 文档瘦身误删，hook 失效修复）
- #537 chore: apple-native.md 吸收 MiniMax iOS Skill（Anti-Patterns + 布局基线 + Dynamic Type + 语义色 + Accessibility + 权限请求）

### 已完成（产品文档深度审计，#534）

- #536 chore: Batch 3+4（Onboarding/失败/换机旅程、免费层定义、商业模型框架、空状态/错误/可访问性设计、数据可携带权矩阵、B26 Profile 删除，Antigravity 三轮验收通过）
- #535 chore: Batch 1+2（术语表新建、备份/恢复注记、SM-2 分层、Dashboard 修正、旅程 parent-first 重排，Antigravity 二次验收通过）

### 已完成（三方全量文档交叉审计，#530）

- #533 chore: 全量文档交叉审计修复（compliance COPPA/GDPR-K 分析、ATT 修正、幽灵 API 清理、architecture 4 处修正等 34 个问题）
- #529 chore: AI 文档审计（rules 7 + skills 10 = 17 个文档对齐代码）
- 新建 #531（全 Profile 备份）+ #532（TipKit Profile 隔离）

### 已完成（文档审计第二轮，#527）

- #528 chore: 项目文档第二轮审计 — 18 个文档（Claude + Codex 交叉审计 + 外部专家 3 方）
  - Batch 1: workflow.md + GitHub 模板对齐（Issue 模板补全 Shape 字段、PR Checklist 4→13 项、Review 留痕、S0-S3 label）
  - Batch 2: README + 5 Package README + Scripts（修复 17 个问题，含 5 个幽灵类型）
  - Batch 3: 8 个 DocC 文档（修复 21 个问题，internal 类型改单反引号 + 散文描述）
  - 架构决策：DocC internal 类型策略（四方一致选 A：不改 public，用单反引号）

### 已完成（文档审计第一轮，15 个 PR）

- #523 docs: api-reference.md 基于代码完整重写（368→717 行）
- #522 docs: tech 文档全量审计 + coding.md typed throws 规则
- #519 docs: Gemini 外部审计（缓存误删 B23、Profile 删除 B24、iCloud 旅程 8）
- #518 docs: GLM4.7 外部审计采纳（合规预案、评估框架、竞品更新策略、风险评估）
- #517 docs: 第二轮全量实质内容审计（6 个文档合并）
- #510 docs: business 审计修复 — 价值链对齐 + Pro 表分离 + 数据安全承诺
- #508 docs: requirements 审计修复 + design 金字塔拆分
- #506 docs: design 外部专家评审微调（iCloud fallback、备份向后兼容、无感创建、B22）
- #505 docs: design 文档结构性审计修复（重写 216→345 行，新增 5 章节）
- #503 fix: vision 产品价值链修正 — iCloud 同步是付费核心引擎
- #502 docs: vision 外部专家评审微调（物理环境鲁棒性、不贩卖焦虑、多 Profile 业务指标）
- #501 docs: vision 根文档审计修复 + 旅程 6/7 补全（Claude + Codex 交叉审计，8 项 PO 决策）
- #497 docs: 产品文档体系审计修复 + 用例/边界规格（Claude + Codex 交叉审计）
- #499 chore: Codex 子 agent 委派规范

### 已完成（功能扩展批次，12 个 PR）

- #476 feat: 删除撤销 — 软删除 + Toast 5 秒撤销
- #474 feat: 单题快速打印 + 每页题数可选 + 存储管理
- #472 feat: App 内语言切换 — 中文/英文直选
- #470 feat: 批量打标签
- #468 feat: 难度过滤
- #466 feat: OCR 结果复制到剪贴板
- #464 feat: 纯文本草稿保存
- #462 fix: 采集管线体验改进 — OCR 重试 + 稳定性提示 + 参数微调
- #460 fix: 相机权限缺失处理
- #458 feat: PDF 导出增强 — 去答案打印 + 留白答题区 + 页眉页码
- #456 chore: 清理 Schema V2/V3/V4 过期注释
- #454 fix: 移除 #Unique 宏解决 CloudKit 真机崩溃
- 商业化策略 + 免费/付费分层文档

### 已完成（基础架构批次）

- #451 Multi-Profile 完整实现
- #450 审计修复
- #449 CI 修复

## 下一步

### 已完成（功能 PR 批次，5 个 PR — Review + 修复后合并）

- #494 feat: iPad 分屏/大屏优化 — sidebarAdaptable + 动态 grid 列数
- #493 chore: TipKit 迁移 — 替代自定义 FeatureTooltip（+Tips.resetDatastore 修复）
- #491 feat: 题目分享卡片 — ImageRenderer 生成分享图片（+UIScreen.main 废弃修复）
- #492 feat: 批量导出原图 ZIP（+ImageStorage DI 注入 + 失败反馈 + deflate 压缩）
- #495 feat: CSV 数据导入（+RFC 4180 合规 + difficulty 范围 + Task.yield）

### 已确认无需开发（代码已有）

- #481 批量删除 — 选择模式 + softDeleteItems 已支持批量
- #478 一图连续裁剪 — CaptureRouter.shouldContinuousCrop 已完整实现

### 待做（依赖公司 Apple 开发者账号）

| Issue | 内容 | 解除条件 |
|---|---|---|
| #163 | 公司 Apple 开发者账号 | Enrollment 已提交（ID: 83VZW7VJKK），等 Apple 审核 1-3 天 |
| #479 | StoreKit 付费墙 | 需 App Store Connect 配置产品 |
| #485 | iCloud 同步 | 需 CloudKit Container + StoreKit |
| #486 | Word 导出 | 需 StoreKit |
| #487 | 组卷排版打印 | 需 StoreKit |
| #488 | 高级统计 + 趋势图 | 需 StoreKit |
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
- STATUS.md 先更新再写 Xcode Review 提示词（两边共享状态）
- Xcode 提出问题 → 修复后让 Xcode 复核，不自审自批

## 里程碑

- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`
