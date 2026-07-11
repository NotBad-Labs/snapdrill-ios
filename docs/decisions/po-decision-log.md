# PO 决策台账

> **性质**：PO 决策的时间序索引。本文采用 thin-pointer：每条决策只保留一行，指向其权威归属文档；归属仍只存在于对话 / 外部报告中的，本文件即其归属。
>
> **维护规则**：后续新决策由 Claude 起草条目，PO 确认，Codex 落盘；路由方式与根 `AGENTS.md` / `CLAUDE.md` 的裁决路由规则一致。更早的奠基性决策（2026-06-09 美国全球版 pivot、零后端、iPhone-only 等）已在 ADR / positioning 固化，不重复收录。
>
> **范围**：2026-06-27 至 2026-07-11。初始草案由 Claude 起草，后续裁决由 PO 直接确认、Codex 固化入仓。

## A. 产品意图与功能语义

| 日期 | 决策 | 归属 |
|---|---|---|
| 06-30 | 工作序：先合并 → Slice3 → 方向 C（繁体 OCR）→ 方向 D（SmartPaper 免费层）；**跳过方向 A（发布）** | 对话；已由执行结果固化 |
| 07-01 | SmartPaper 免费配额 = **3 次 / 自然月** | `docs/features/backlog/feat-smartpaper.md` §3 |
| 07-01 | 扣费语义 = **导出完成才扣**（预览不扣、同生成多次导出只扣 1） | `docs/features/backlog/feat-smartpaper.md` §3 + 测试契约 |
| 07-01 | SmartPaper 入口：正常浏览态可见、**非 Pro 门**、轻量工具栏动作、保留名称 | `docs/features/backlog/feat-smartpaper.md` §3 |
| 07-02 | 损坏库恢复 UX = **完整恢复流程**（从备份恢复 / 以空资料库继续），否决静默清空与维持现状 | `docs/features/active/feat-backup.md` 恢复安全规范 + `docs/features/active/feat-profile.md` 降级 / Profile 隔离边界 |
| 07-03 | B2 恢复页文案 5 条定稿（含“复制副本路径”等） | L10n 实现 + PR #848 |
| 07-05 | **术语标准 = 资料系**（资料 / 资料库 / 资料空间），SmartPaper 域内保留 题 / 试卷 / 组卷 | `docs/reference/glossary.md`（已固化，含边界表） |
| 07-06 | “每页题数”→“每页资料数”（通用导出面归资料系） | `docs/reference/glossary.md` 边界的应用；PR 描述 |
| 07-06 | 配额 Toast 混域句维持现状（组卷 = 域内词，资料 = 通用词） | PR 描述 |
| 07-06 | 隐私政策文案校正批准（“学习助手”→“资料整理应用”，清除 pre-pivot 残留） | L10n + Policy 实现；与 `docs/explanations/positioning-and-audience.md` 一致 |
| 07-11 | **退休 Multi-Profile，重基线为单一本地资料库**；项目无内测用户，开发期 Profile 数据、偏好和旧多 Profile 备份无需迁移或兼容 | `docs/reference/audits/2026-07-repository/phases/04b-single-library-brief.md`；实施时回填 `docs/features/active/feat-profile.md` 的替代归属 |

## B. 质量门槛

| 日期 | 决策 | 归属 |
|---|---|---|
| 07-04 | TestFlight 前做**有界质量基线**：HIG 普适条款 + 可检验，不追求完美重设计 | 本台账（质量基线原则） |
| 07-05 | **零 AX 警告再发版**（选了最严选项；审计翻强制门禁） | `docs/reference/appstore-metadata.md` 发版检查清单 |
| 07-05 | 双盲 P1 清单确认（XXXL 遮挡 / 恢复页清理 / VoiceOver / 文案成品） | Q2 缺陷池 §六 + Q3-A 实现 |
| 07-06 | Q3-A 文案 5 条批准（含“搜索”占位符）；`uploadSymbols=true` | PR #852 / #854 描述 |
| 07-07 | **四方独立零信任审计（Claude / grok / agy / Codex）= 一致 GO**；放行进入真机 dogfood；零 P0 / P1 / blocker | 本台账 + `~/Developer/snapdrill-agent-reports/2026-07-07-four-way-zero-trust-scorecard.md` |
| 07-07 | 审计浮现 **6 类 P2 加固全部延后**至 TestFlight 后队列（含 Tier-A #1 Share GPS），不阻 dogfood | 本台账 + §F 队列 |

## C. 路线与优先级

| 日期 | 决策 | 归属 |
|---|---|---|
| 07-02 | CI 信号健康刀先行（pre-push + concurrency），方向 B 随后 | 已执行（PR #846） |
| 07-04 | 现在做规划 Slice 2（TestFlight 阻塞清单） | Slice2 报告（已交付） |
| 07-04 | **质量基线优先于 TestFlight 执行序**（§E 顺延） | 本台账；执行入口见 `docs/how-to/release-and-ci.md` |

## D. 协作与流程

| 日期 | 决策 | 归属 |
|---|---|---|
| 06-27 | **记忆最小化、真相入仓**：agent 私有记忆只是可丢弃缓存 | `AGENTS.md` + `docs/how-to/parallel-lanes.md` |
| 06-30 | 协作模型：Claude shape → Codex 执行（可挑战）→ Claude 只读复核 → PO 合并 | `docs/how-to/parallel-lanes.md` §3 |
| 07-01~04 | 三次纠正“不可能 / 必须人工”论 → Codex 可 dogfood、可绕系统面板、坐标点击破墙 | Claude 记忆（no-premature-impossibility）；过程记录在 checkpoint |
| 07-02 | **规划 freshness 对账成为习惯**并固化入仓 | `docs/how-to/parallel-lanes.md` §3（PR #849） |
| 07-06 | **多窗口并行模式采用**（主刀 / 副刀 / 运维 / QA；write ≤ 2；合并串行） | `docs/how-to/parallel-lanes.md` 多窗口小节（PR #855） |
| 07-06 | 老窗口退役；PO 转发降级为提醒信号（Claude 自查仓库为准） | 本台账 |

## E. 处置类

| 日期 | 决策 | 归属 |
|---|---|---|
| 06-27 | 23 个历史分支与旧 worktree **不备份直接删除**；Codex 记忆硬抹除 | 已执行 |
| 07-06 | 10 + 1 个旧分支（含 6 个含独有工作的）全部删除 | 已执行；C3 报告 |
| 07-06 | pbxproj 584 行 Firebase 死引用：先丢弃、后专刀正式清理 | PR（pbxproj-firebase-deadrefs） |

## F. 已挂号、尚未拍板

- **N2：Mac mini 网络**（固化直连 vs 还原修 OpenClash）——最急，443 已成每日税
- 定价 / iPad 通用 / 公开上架合规时点（legal）/ China 续费（约 2027-01）
- GAP-R1（复习中删除）/ hard-easy 评分 / printed 事件 / ADR-005 Layer A / `reviewItems` 永久 wire key
- **P2 加固队列（四方审计浮现，6 类，TestFlight 后按 Tier 开刀）**：Tier-A ① Share Extension GPS 剥离 / 测试 ② DataExecutor / ProfileManager fatalError → 错误弹窗 ③ 日志 Profile 名 PII；Tier-B ④ CSV 导入大文件 OOM ⑤ 含图备份恢复 round-trip 测试缺口 ⑥ LiveServiceContainer 默认 mock → NoOp
- TestFlight 执行：~~ASC 建记录（07-07 已完成，Apple ID 6788202421）~~ → 真机 P1-P6 → Organizer 首传（§E，约 1-2 小时）

## 统计

约 **27 项已拍 + 9 项在队**。分布：产品语义 10、质量门槛 6、路线 3、制度 6、处置 3。

草案中标记“待路由”的 5 项已随本文件入仓路由：

| 草案待路由项 | 入仓归属 |
|---|---|
| SmartPaper 入口非 Pro 门 | `docs/features/backlog/feat-smartpaper.md` §3 |
| 损坏库恢复 UX 裁决 | `docs/features/active/feat-backup.md` + `docs/features/active/feat-profile.md` |
| 质量基线原则 | 本台账 |
| TestFlight 顺延 | 本台账 + `docs/how-to/release-and-ci.md` |
| 四方审计 GO + 6 P2 延后 | 本台账 + §F 队列 |
