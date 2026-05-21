---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-21（**Phase 0-9 结构层收官 + Phase 10 语义层七维度全部完成 + Phase 11 worktree 首战 S-D7-001 收尾**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）

## 当前状态（2026-05-20）

**文档体系深度清洁 Phase 0-9 结构层收官**（2026-05-20，共识基线 commit `4883d6b6`，Gemini 全周期 FULL PASS）。方法论沉淀在 `docs/decisions/ADR-004-doc-system-deep-clean.md`。

**🎉 Phase 10 语义层审计全部收官**（2026-05-21 七维度完成，共识基线 commit 待 push；ADR-005 状态「提议」→「已决策」，ADR-004 backlog 第一条勾 ✅✅）。共识报告 [dim1](docs/audits/semantic-audit-dim1-consensus.md) + [dim2](docs/audits/semantic-audit-dim2-consensus.md) + [dim3](docs/audits/semantic-audit-dim3-consensus.md) + [dim4](docs/audits/semantic-audit-dim4-consensus.md) + [dim5](docs/audits/semantic-audit-dim5-consensus.md) + [dim6](docs/audits/semantic-audit-dim6-consensus.md) + [dim7](docs/audits/semantic-audit-dim7-consensus.md) + 语义 ledger [audit-ledger-semantic-2026-05.tsv](docs/audits/audit-ledger-semantic-2026-05.tsv) 含 **86 OPEN finding**。

⚠️ **语义层审计终态**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) + 维度 4 (11) + 维度 5 (15) + 维度 6 (7) + 维度 7 (10) = **86 OPEN finding**（HIGH×13 MEDIUM×26 LOW×35 INFO×12）。**进入「集中入 PR 修复」阶段**。维度 7 Antigravity 抓到 Phase 10 致命独家 S-D7-001（docaudit.py:593 rule-usage check 工具底层 bug，13 active F-rule 漏审）。Phase 10 五大方法论实战教训沉淀到 ADR-005 §Phase 10 全局收官段；Phase 11+ 启用 git worktree 物理隔离 + 净化提示词为标准。

**🛠️ Phase 11 worktree 首战 S-D7-001 收尾**（2026-05-21）：三家物理隔离独立产出 + Claude CLI 主笔 cross-fix-consensus 融合 + apply。`Scripts/audit/docaudit.py` 修复后 declared 集合 n=1 → n=14（14 个 active F-rule 全部识别），test_docaudit 76 tests OK，实测 F-004 = 31 refs（**S-D5-013 翻 REJECTED**，S-D7-010 元悖论闭环 RESOLVED）。

**🛠️ S-D4-003 badge 三层背离 RESOLVED**（2026-05-21 单家机械修复）：删除 .badge 权限 + 10 文件清理对齐 product-requirements:178「不使用角标」。

**🛠️ Phase 11 worktree 第二战 S-D4-002 收尾**（2026-05-21 真生产 bug 三方对抗）：通知 ID Multi-Profile 隔离修复。融合 Codex 4 层 namespace `com.snapdrill.notification.daily-review.profile.<uuid>` + `UserNotificationScheduling` facade（FakeCenter 测试真实 Live 服务行为）+ `ProfileScope` 类型注入 + 级联升级清理 legacy ID + `cancelAllSnapDrillNotifications` 用 managed prefix（不触碰第三方 app pending request）。测试 13 Core + 8 Features OK。详见 [S-D4-002-fix-consensus.md](docs/audits/S-D4-002-fix-consensus.md)。

**🛠️ S-D1-001/002/003 维度 1 三大 HIGH RESOLVED**（2026-05-21 单家批量文档对齐）：Requirements 新增 §字段配置规格段（4 层 + 过滤排序闭环 + 5 入口分层）+ Architecture 补 CSV 模块归属 + NFR 修正 Dynamic Type vs 自定义字号概念混淆 + 补 CSV 导入吞吐/内存/解析合规。

**🛠️ 第二批纯文档 HIGH 5 条 RESOLVED**（2026-05-21）：S-D2-001（vision §1 加图片主路径边界声明 + CSV 定位为可携带权场景）+ S-D3-001（vision H2-SM2 假设补 SM-2 协作流程）+ S-D5-001（permission-model §2/§5 改为 Python classifier 实现表 + 审计命令更新）+ S-D5-007（collaboration.md GPT-5.4 → GPT-5.5）+ S-D5-008（Antigravity 定位升级为三方对抗 worktree 主审之一）。

**🛠️ 维度 1 100% 关闭**（22 条文档对齐）。

**🛠️ 第三批纯文档批量 51 条 RESOLVED**（2026-05-21）：vision / design / business 承接 + standards 实现层对齐 + skill description 语义边界 + F-rule 触发方式声明边界 + 防焦虑硬约束 + 订阅取消硬性承诺 + 推荐算法语义澄清 + 原生优先 Firebase 边界 + Apple Pencil 价值定位 + a11y 价值主张 + 角色/模板边界 + Dashboard 文案防焦虑 + execution-gates 补 hook + permission-model 计数动态化 + frontmatter 漂移检测 + a11y 标签例外 + Word 导出定位 + Codex 三形态。

**⚠️ 仅剩 3 条 OPEN finding**：全部为待 worktree 三方对抗的高复杂度任务。
- `S-D4-001` ServiceContainer DI 系统性退化（架构大改）
- `S-D7-002` F-005 PR review 留痕 hook 强化（流程治理设计）
- `S-D7-003` F-018 Sprint Contract 机械拦截（流程治理设计）

**🛠️ Phase 11 第三战 S-D4-001 收尾**（2026-05-21）：ServiceContainer DI 系统性退化重构。三家对抗 Antigravity 46 分胜出（临时 apply 实证暴露 2 个真生产 bug：`LiveNotificationService.current()` 静态初始化崩溃 + `PrivacySettingsViewModel` 测试 `AppActivityTracker.shared` 串扰）。融合 Codex ReviewScheduler + 「Core service 规则」段。协议从 5 属性扩展到 13；4 个 View/ViewModel 已迁移；旧 `.shared` 加 `@deprecated` 标注引导渐进迁移。详见 [S-D4-001-fix-consensus.md](docs/audits/S-D4-001-fix-consensus.md)。

**🛠️ Phase 11 第二战 S-D7-002 收尾**（2026-05-21）：F-005 PR review 留痕机械化。三家对抗 Codex 51 分胜出（字段化 schema 严格 key:value 解析）+ Antigravity 占位符防御融合 + Claude 7 触发器盲区。新增 review-trace policy YAML + Python 校验器 + 14 unittest + CI 两 job（PR 阻断 + push trailer 兜底）+ PR template 字段化 + cross-audit/sprint-contract skill F-005 输出。详见 [S-D7-002-fix-consensus.md](docs/audits/S-D7-002-fix-consensus.md)。

**🎉 Phase 11 收官战 S-D7-003 完成**（2026-05-21）：F-018 Sprint Contract 机械拦截。三家对抗 Codex 48 分（完整 12 字段 schema + 多行 bullet 解析）+ Antigravity 45 分（**Scope Creep 实时防御** check_file_scope 比对 Edit 文件 vs Touches/No-Touch globs）+ Claude 7 触发器盲区。新增 sprint-contract policy YAML + Python gate（含 Scope Creep）+ 24 unittest + PreToolUse Edit hook 硬阻断 + premerge 串接 F-005+F-007+F-018 + CI sprint-contract-trace job + issue template 字段化 + skill Step 0/7 引导。详见 [S-D7-003-fix-consensus.md](docs/audits/S-D7-003-fix-consensus.md)。

**🏆 Phase 11 整体收官**（OPEN finding 累计净减 **86 → 0，100% 关闭率**）：
- Phase 10 86 finding 全部 RESOLVED 或 WAIVED
- Phase 11 五战全部完成：S-D7-001 工具 bug / S-D4-002 Multi-Profile / S-D4-001 DI / S-D7-002 F-005 review / S-D7-003 F-018 contract
- worktree 三方对抗工作流 5 次实战验证（物理隔离 + 净化提示词 + Codex/Antigravity/Claude 三家差异化能力清晰）
- 流程治理基础设施落地：`Scripts/audit/{pr_review_trace,sprint_contract_gate}.py` + `.github/{review-trace,sprint-contract}-policy.yml` + `.claude/hooks/{premerge-checklist,pre-edit-sprint-contract}.sh` + CI {review-trace,direct-push-review-trace,sprint-contract-trace} 三 job

- **Phase 0-2**：52-doc 审计接管 + SSOT 自洽 + 三方 verdict 裁决 + NEEDS_REVISION 修订
- **Phase 3**：跨文档 contradiction / ghost ref / orphan 横向扫描 + Codex 二意见
- **Phase 4**：治理升级 — docaudit 扩展到 11 check + ADR-004
- **Phase 5/7**：剩余 132+ 文件全量补审 + 10 处修复
- **Phase 8**：73 文件真全文 Read 补审 4 latent finding
- **Phase 9**：snapshot-testing 拆出嵌入第二 frontmatter 为独立 `snapshot-diff-review` skill

audit-ledger 现状（`docs/audits/audit-ledger-2026-05.tsv`，元信息见 `docs/audits/README.md`）：**224 行**（Round 9 全集覆盖补审 + Codex 反馈矫正后，含 14 governance + 11 构建/CI/meta + 7 Codex 盲区补审 + 2 真 bug 修复 + 2 dead duplicate 标 stale）；Final_Decision: VALID 184 / VALID_WITH_GAP 29 / STALE_OR_INVALID 11；Confidence 全部 RESOLVED；Codex 已 Round 1-9 独立验证（Round 9 矫正 4 verdict + 补 7 盲区）；Gemini 全周期最终复核待用户触发。

**Skill 体系**：52 个 distinct 一层 skill（15 项目治理、21 Claude-only 领域 skill、16 共享 skill）。SSOT：`docs/standards/skill-architecture.md`。

| 外部阻塞项 | 说明 | 状态 |
|---|---|---|
| Apple 开发者账号 (#163 链) | $99 年费待缴 | 用户控制 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 待真机验证 |

### Apple 账号阻塞链

| Issue | 内容 |
|---|---|
| #163 | 公司 Apple 开发者账号 |
| #479 | StoreKit 付费墙 |
| #485 | iCloud CloudKit 同步 |
| #161 | TestFlight Build 6 |

## 产品决策索引

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | ADR-002 |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | ADR-001 |
| 2026-04-17 | 文档 frontmatter 从 HTML 注释迁移到 YAML | ADR-003 |
| 2026-05-19 | 文档体系深度清洁方法论 + 防漂移机制 | ADR-004 |
| 2026-05-20 | 文档体系语义层审计方法论（Phase 10 立项，状态：提议） | ADR-005 |
