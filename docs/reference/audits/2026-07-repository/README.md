# 2026-07 Repository Audit

## Charter

- **PO 授权日期**：2026-07-10
- **审计 base**：`develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- **协调者**：Codex C1
- **工作状态**：C2 / C3 / C4 暂挂；本审计的外部 CLI 是只读 reviewer，不是新的 write lane
- **write WIP**：1 个审计分支；不在本分支修产品代码
- **目标**：区分必要投入、可解释返工、真实浪费和当前发布风险，形成可验证的 keep / repair / replace / retire / delete / defer 与 release 输入

本 charter 只约束本次审计，不改写 steady-state lane 归属。产品方向、风险接受、修复优先级、合并和发布仍由 PO 裁决。

本轮以 [`rebaseline-contract.md`](rebaseline-contract.md) 定义“无死角清理”的边界、分类、删除/替换门和完成条件。审计与修复分离：本分支只记录事实，已授权修复在最新 `develop` 的独立分支落地，并在合并后回填 finding ledger。

## 已确认基线

2026-07-10 使用 GitHub Search API 与 Actions API 得到：

| 指标 | 数量 | 解释边界 |
|---|---:|---|
| Issues | 347 | 其中 4 个 open；不含 PR |
| Pull requests | 517 | 与 issue 共用编号空间 |
| Issues + PRs | 864 | 可解释“编号接近 1000”，不等于近 1000 个真实 issue |
| Actions runs | 1,881 | 1,305 success / 506 failure / 70 cancelled |
| Failure share | 26.9% | 只表示 run 结论；需按根因、重跑和当时目标分类后才能判断浪费 |

工具和真实模型握手：

| Lane | CLI | 已验证模型 |
|---|---|---|
| Codex | `0.144.0-alpha.4`，随 ChatGPT App 管理 | 当前 C1 |
| Claude | `2.1.206` | `claude-fable-5[1m]` |
| Antigravity | `1.1.1` | `Gemini 3.5 Flash (High)` |
| Grok | `0.2.93` | `grok-4.5` |

Gemini CLI 已移除；Google 订阅入口统一为 Antigravity。Gemini API 是单独的显式付费 fallback，不在本审计默认调用。

## Phase Map

每个 phase 由四方独立覆盖；若 60 分钟或 50 个主要文件不足，则按表内 slice 拆分，仍使用同一 base 与报告 schema。

| Phase | 范围 | 预定 slices | 状态 |
|---|---|---|---|
| 00 Control plane | T0、工具链、模型、报告协议、恢复演练 | `00a` 基线；`00b` 小范围盲审 | complete |
| 01 History | issue/PR 生命周期、CI 失败分类、返工热点 | `01a` lifecycle；`01b` CI；`01c` churn；`01d-f` 证伪 | complete |
| 02 Truth | 意图链、状态 SSOT、生成物、流程与脚本漂移 | `02a` docs；`02b` guardrails；`02c` stale claims | complete |
| 03 Architecture | package 依赖、DI、并发、共享接缝、废弃代码 | `03a` graph；`03b` runtime flow；`03c` debt | complete |
| 04 Data safety | SwiftData、repository、profile、迁移、备份、图片 | `04a` models；`04b` profile；`04c` backup；`04d` images | pending |
| 05 Capture | camera、scanner、album/PDF、crop、OCR、save | `05a` input；`05b` processing；`05c` persistence | pending |
| 06 Library/export | library、search、taxonomy、SmartPaper、export/share | `06a` library；`06b` SmartPaper；`06c` export | pending |
| 07 Other features | review、dashboard、settings、onboarding | `07a` review；`07b` dashboard；`07c` settings/onboarding | pending |
| 08 UI quality | shell、布局、AX、Dynamic Type、本地化、dogfood | `08a` shell；`08b` AX；`08c` l10n；`08d` visual | pending |
| 09 Test/CI | test plan、oracle、flakiness、覆盖、缓存与耗时 | `09a` topology；`09b` oracle；`09c` run taxonomy | pending |
| 10 Security/privacy | secret、路径、归档、依赖、manifest、数据流 | `10a` appsec；`10b` privacy；`10c` supply chain | pending |
| 11 Release | signing、capability、metadata、support、性能与诊断 | `11a` build/sign；`11b` listing/legal；`11c` runtime | pending |
| 12 Synthesis | 去重、风险排序、投入解释、发布差距与 PO 队列 | `12a` cluster；`12b` decision packet；`12c` go/no-go | pending |

## Recovery

- **worktree**：`/private/tmp/snapdrill-repository-audit`
- **branch**：`codex/repository-audit-program`
- **方法**：`docs/how-to/repository-audit.md`
- **报告模板**：`report-template.md`
- **外部 agent 调用协议**：`agent-invocation-protocol.md`
- **再基线契约**：`rebaseline-contract.md`
- **finding ledger**：`findings.md`
- **当前 checkpoint**：`checkpoints/phase-03.md`
- **00b 结果**：`phases/00b-results.md`
- **Phase 01 结果**：`phases/01-results.md`
- **Phase 02 结果**：`phases/02-results.md`
- **Phase 03 结果**：`phases/03-results.md`
- **下一步**：Phase 04 Data safety；先冻结 models/profile/backup/image contract 与 fixtures；RA-03-001 以独立测试隔离修复跟踪
