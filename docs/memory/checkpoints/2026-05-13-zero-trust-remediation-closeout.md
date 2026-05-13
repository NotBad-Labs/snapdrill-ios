---
last_verified: 2026-05-13
layer: snapshot
freshness:
  max_age_days: 365
  decay_trigger: [next_zero_trust_audit]
---
# 零信任审计 + 全量修复 — 监督记录

> 本记录由 Claude（监督方）撰写，客观记录 2026-05-11 → 2026-05-13 的零信任审计与全量修复过程。
> Codex（执行方）负责审计发现和代码修复，Claude 负责方向引导、进度监督、质量审查和最终验收。

## 参与方

| 角色 | 模型/工具 | 职责 |
|---|---|---|
| **Codex CLI** | GPT-5.5 (high effort) | 独立审计执行、修复实施 |
| **Claude/DeepSeek** | DeepSeek v4 Pro | 方向引导、进度监督、质量审查、验收 |
| **人类操作者** | — | 战略决策、最终审批 |

## 方法论

### 审计阶段

1. **入口引导**：给 Codex 项目入口（CLAUDE.md + STATUS.md + 目录结构），不告知审计方法论，让 Codex 独立探索并制定自己的审计计划。
2. **逐文件全量阅读**：357 个文件（73 文档 + 231 Swift + 52 治理 + STATUS.md），每个文件用 `nl -ba` 逐行读取，禁止 grep 抽样、禁止首尾 50 行、禁止代表性文件。
3. **声称驱动验证**：从 STATUS.md 逐行提取 57 条事实性声称，每条映射到验证路径。覆盖产品/代码/测试/CI/PR 历史/外部状态/私有路径/元信息 8 个类别。
4. **贪吃蛇追踪**：每读一个文件更新 File Coverage Ledger，UNREAD → READ_VERIFIED。只有蛇身覆盖的才算已验证。

### 交叉审查纪律（F-008）

修复阶段严格执行"实施方不自审"原则：
- Codex 审计发现问题 → Claude 实施部分修复 → **Codex 独立审查 Claude 的修复** → Codex 发现 5 个 FAIL → Codex 修复 FAIL → Claude 审查验收
- 后续修复：Codex 实施 → Claude 审查

### 分批次控制

Codex 单次任务上限约 5-8 个文件，超过会超时（504 Gateway Timeout）。全部工作拆分为 ~40 个批次执行。卡住时立即拆分重试，不等超时。

## 时间线

| 日期 | 阶段 | 关键事件 |
|---|---|---|
| 2026-05-11 上午 | 审计启动 | Claude 给 Codex 入口，Codex 独立制定 6 维度安全审计框架 |
| 2026-05-11 上午 | 方法论纠正 | Claude 引导 Codex 从"安全边界驱动"转为"声称驱动"——重新审视 STATUS.md 自我声称 |
| 2026-05-11 上午 | 方法论深化 | Codex 发现自己的 6 维度框架覆盖不全——大量 STATUS 声称（PR 历史、外部状态、私有路径）无验证入口 |
| 2026-05-11 下午 | 审计计划 v2 | Codex 制定 349 文件全量审计计划，8 步吞食顺序 |
| 2026-05-11 下午→深夜 | Step 0-4 文档审计 | 全部文档（产品/技术/记忆/原则/治理/路由指针）逐行阅读完成 |
| 2026-05-12 凌晨 | Step 5 源码审计 | Data 层 41 文件完成，发现 S0 原子性缺口 |
| 2026-05-12 凌晨→上午 | Step 5 继续 | Core 60 文件、Features 97 文件、Infra/UI/App/Share 完成 |
| 2026-05-12 上午 | Step 6-8 | Agent 治理层（hooks/skills/settings）、CI/Harness、机械验证完成 |
| 2026-05-12 下午 | 修复 J 组 | 治理 fail-closed：token 移除、hook 解析式拦截、fail-closed 模式 |
| 2026-05-12 下午 | 修复 A 组 | ProfileScope 编译期隔离：新建类型、RepositoryContainer/ImageStorage 强制 scope |
| 2026-05-12 下午 | 交叉审查 | Codex 审查 Claude 的 J+A 修复，发现 5 个 FAIL（RepositoryContainer 未注入 imageStorageFactory、View 未传 activeImageStorage、bash -lc 绕过等） |
| 2026-05-12 下午 | 修复 FAIL | Codex 修复审查发现的 5 个问题，Claude 验收 |
| 2026-05-12 下午 | 修复 B 组 | ZIPArchiver 原子写、restoreImages staging、SettingsViewModel profileId 匹配 + 活跃 Profile 还原、原子性测试补齐 |
| 2026-05-12 晚上 | 修复 C 组 | 并发测试 timeout、FirebaseBootstrap 锁保护、ProfileManager 异步工厂 |
| 2026-05-12 晚上 | 修复 D 组 | TelemetryGate 统一门控：默认 denied、遗留 key 保守迁移 |
| 2026-05-12 晚上 | 修复 E 组 | MainActor 统一：FeatureRouter 修正、全局隔离对齐 |
| 2026-05-12 深夜 | 修复 F 组 | Mutation Transaction：ReviewViewModel save 失败回滚、SwipeCard hasFired 修复、Manager rollback |
| 2026-05-12 深夜 | Codex 用量归零 | UTC 00:53 前不可用。Claude 处理 2 个 lint 违规（ReviewViewModel 方法拆分、测试文件拆分） |
| 2026-05-13 上午 | Codex 恢复 | 修复 G 组（相机 stopSession、Share URL 校验、降采样统一）、H 组（hasMore 守卫、PDF 临时文件名、itemsPerPage 校验）、I 组（ProEntitlementProvider）、K 组（L10n 补齐、隐私口径收敛、ADR 清理、许可证） |
| 2026-05-13 上午 | 提交 | 110 文件、4667 行新增、524 行删除。swiftlint 0 · docaudit exit 0 · xcodebuild 0 errors |

## 关键决策

1. **Codex 作为执行方而非辅助工具**：Codex 独立制定审计计划、独立发现问题、独立实施修复。Claude 不越俎代庖——只引导方向、检查质量。

2. **声称驱动而非风险驱动**：零信任审计的核心不是"找高风险区域"，而是"验证项目对自身的每一个声称"。这要求 100% 覆盖，不允许抽样。

3. **架构修复而非局部补丁**：每个修复都从架构层面解决根因。ProfileScope 让 Profile 隔离从"约定"变为"编译期强制"。TelemetryGate 让隐私同意从"散落各处的默认 true"变为"单一来源的默认 denied"。恢复事务从"逐个 Profile 独立操作"变为"staging → 原子切换"。

4. **交叉审查不可省略**：Codex 审查 Claude 的代码时发现了 5 个真实 FAIL——如果自审自批，这些问题会漏过。

## 产出物

| 文件 | 说明 |
|---|---|
| `docs/memory/checkpoints/2026-05-11-zero-trust-audit-trail.md` | 357 文件审计追踪（File Coverage Ledger + 57 条 Claim Ledger + Deep Dive Queue） |
| `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md` | Codex 独立撰写的审计收官报告 |
| `docs/memory/checkpoints/2026-05-13-zero-trust-remediation-closeout.md` | 本文件（监督记录） |
| Commit `49172637` | 全量修复提交：110 文件，11 组架构修复 |

## 发现统计

| 严重度 | 审计发现 | 修复状态 |
|---|---|---|
| CRITICAL | 1（明文 GitHub token） | ✅ 已修复 |
| S0 | 4（多 Profile 恢复非原子、图片恢复无原子性等） | ✅ 已修复 |
| S1 | 11（Analytics 默认值矛盾、hook 漏检等） | ✅ 已修复 |
| S2 | 30+（L10n 缺失、MainActor、hook 静默失败等） | ✅ 已修复 |
| S3 | 20+（测试弱断言、硬编码 Pro、死代码等） | ✅ 已修复 |

## 已知局限

以下在本次审计范围内但未完成或依赖外部条件：

| 项目 | 状态 | 原因 |
|---|---|---|
| 420 tests 逐条执行与断言质量审计 | 仅抽样 | 需真机/模拟器运行 |
| 性能/负载测试 | 未覆盖 | 需 Instruments |
| Share Extension 端到端测试 | 未覆盖 | 需真机 + 外部 App |
| Apple 开发者账号阻塞链 | 未解决 | 用户控制缴费时机 |
| QuestionSplittingService 真机验证 | 待验证 | 需 iOS 26 真机 + Apple Intelligence |
| 第三方依赖 CVE 扫描 | 未覆盖 | 需专门工具 |

## 后续建议

1. 在真机上运行 420 tests 全量，验证无回归
2. 下次 App Store 提交前重新运行归零审计（特别是 B 组恢复事务和 D 组 TelemetryGate）
3. Apple 账号缴费开闸后接入 StoreKit 到 ProEntitlementProvider
4. 定期（季度）运行 docaudit + swiftlint 作为基础门禁
