# PO 决策台账

> **文档角色：当前证据索引，不是规范权威。** 本文按时间记录 PO 回执并尽量用 thin-pointer
> 指向 owning authority。只有归属权威合入 `develop` 后，裁决才对其他 lane effective。
> 仍只存在于对话、私有报告或“本台账”中的条目属于未路由历史证据，不能驱动新实现。
>
> **维护规则**：当前 orchestrator 起草 thin-pointer，PO 确认，owning lane 落盘；路由方式与根
> `AGENTS.md` 的裁决规则一致。更早的奠基性决策（2026-06-09 美国全球版 pivot、零后端、
> iPhone-only 等）已在 ADR / positioning 固化，不重复收录。
>
> **范围**：2026-06-27 至 2026-07-19 的历史回执，加上此后具名 authority pointer；模型品牌
> 不拥有决策或文件。

## 决策状态

本文使用 `exploration -> shaped candidate -> ratified -> effective -> superseded`。PO 批准候选只使其成为 `ratified`，不同时授权合并；归属权威合入 `develop` 后才成为 `effective`。旧 tracked 规范在被明确 supersede 前持续有效。

## A. 产品意图与功能语义

| 日期 | 决策 | 归属 |
|---|---|---|
| 06-30 | 工作序：先合并 → Slice3 → 方向 C（繁体 OCR）→ 方向 D（SmartPaper 免费层）；**跳过方向 A（发布）** | 对话；已由执行结果固化 |
| 07-01 | SmartPaper 免费配额 = **3 次 / 自然月**；随 07-14 C5-E 所属权威合入 `develop` 后 superseded，之后只作实现 / 历史裁决 | `docs/features/backlog/feat-smartpaper.md` §3 |
| 07-01 | 扣费语义 = **导出完成才扣**（预览不扣、同生成多次导出只扣 1）；随 C5-E 的 Release 1 无配额边界合入 `develop` 后 superseded | `docs/features/backlog/feat-smartpaper.md` §3 + 测试契约 |
| 07-01 | SmartPaper 入口：正常浏览态可见、**非 Pro 门**、轻量工具栏动作、保留名称；公开可见性随 07-14 C5-E 合入 `develop` 后 superseded | `docs/features/backlog/feat-smartpaper.md` §3 |
| 07-02 | 损坏库恢复 UX = **完整恢复流程**（从备份恢复 / 以空资料库继续），否决静默清空与维持现状 | `docs/features/active/feat-backup.md` 恢复安全规范 + `docs/features/active/feat-profile.md` 降级 / Profile 隔离边界 |
| 07-03 | B2 恢复页文案 5 条定稿（含“复制副本路径”等） | L10n 实现 + PR #848 |
| 07-05 | **术语标准 = 资料系**（资料 / 资料库；当时包含资料空间），SmartPaper 域内保留 题 / 试卷 / 组卷；“资料空间”已随 07-12 B5-A 单资料库裁决停用 | `docs/reference/glossary.md`（已固化，含边界表） |
| 07-06 | “每页题数”→“每页资料数”（通用导出面归资料系） | `docs/reference/glossary.md` 边界的应用；PR 描述 |
| 07-06 | 配额 Toast 混域句维持现状（组卷 = 域内词，资料 = 通用词） | PR 描述 |
| 07-06 | 隐私政策文案校正批准（“学习助手”→“资料整理应用”，清除 pre-pivot 残留） | L10n + Policy 实现；与 `docs/explanations/positioning-and-audience.md` 一致 |
| 07-11 | **退休 Multi-Profile，重基线为单一本地资料库**；产品行为已由 07-12 B5-A 承接。项目无内测用户，开发期 Profile 数据、偏好和旧多 Profile 备份无需迁移或兼容；该过渡边界仍须由 Release 1 / Data Contract 承接后才能合并实现 | `docs/product/vision.md` §数据与身份定位；`docs/reference/audits/2026-07-repository/phases/04b-single-library-brief.md` |
| 07-12 | **Gate B / Product Vision & Principles：B1-A 至 B7-A 全部逐项批准**。首个切口 = 结构化纸张 / PDF 成人工作流；价值承诺 = 可搜索、可整理、可打印资料库；核心链 = 采集 → 整理 / 找回 → 导出 / 打印；local-first / 无 SnapDrill 账户 / 单资料库 / 永久手动备份；Release 1 免费无广告无 IAP；iPhone-only 美国主体全球版、英文 + 简体中文 | `docs/product/vision.md`（Product Vision & Principles；本权威合入 `develop` 后 effective） |
| 07-13 | **Gate C / C3 ratified：Release 1 普通启动默认进入 Dashboard**。Dashboard 只承担任务入口与可执行状态概览；不批准当前卡片 / 五 Tab，不允许 Profile / Pro / analytics / Review hero 主导首屏 | `docs/product/release-1-prd.md` §4 |
| 07-14 | **Gate C 四包全部批准**：C1-A；C2-Core / Image / Optional / Personalization；C4-D；C5-E / C5-S1；C6-A；DATA-1 / DATA-1-E / DATA-1-R。加上 07-13 的 C3，Release 1 PRD 全部 13 个精确 ID 已 ratified；本权威合入 `develop` 后 effective，且不自动授权实现、上传、开放 TestFlight 或发布 | `docs/product/release-1-prd.md` |
| 07-19 | **Release safety 四项 ratified**：S1-A 固定内容 / taxonomy / normalized JPEG 接受边界；M1-A 固定 taxonomy cardinality 转换的失败原子性；D4S-A 固定 complete / partial operation 与 shared prestate / barrier；ORI-A 固定 iPhone shell 与媒体内容方向边界。它们合入 owning authority 后才 effective，不批准 Backup v3 DDL / package、实现、合并、上传或发布 | `docs/product/release-1-prd.md` + `docs/reference/local-library-data-contract.md`；来源 #918 / #884 / #950 |

## B. 质量门槛

| 日期 | 决策 | 归属 |
|---|---|---|
| 07-04 | TestFlight 前做**有界质量基线**：HIG 普适条款 + 可检验，不追求完美重设计 | 本台账（质量基线原则） |
| 07-05 | **零 AX 警告再发版**（选了最严选项；审计翻强制门禁） | `docs/reference/appstore-metadata.md` 发版检查清单 |
| 07-05 | 双盲 P1 清单确认（XXXL 遮挡 / 恢复页清理 / VoiceOver / 文案成品） | Q2 缺陷池 §六 + Q3-A 实现 |
| 07-06 | Q3-A 文案 5 条批准（含“搜索”占位符）；`uploadSymbols=true` | PR #852 / #854 描述 |
| 07-07 | **四方独立零信任审计（Claude / grok / agy / Codex）= 一致 GO**；放行进入真机 dogfood；零 P0 / P1 / blocker | 本台账 §B.1 的最小历史回执；不再依赖仓库外 scorecard |
| 07-07 | 审计浮现 **6 类 P2 加固全部延后**至 TestFlight 后队列（含 Tier-A #1 Share GPS），不阻 dogfood | 本台账 + §F 队列 |

### B.1 2026-07-07 四方审计最小历史回执

- 2026-07-24 从当时本机 scorecard 复核并转录；原文件 SHA-256：
  `da72a572e21fb419968c601a83bc6766f9bbe853899fef5af1ccfcad026c22ab`。仓库外文件不再是
  本裁决的唯一持有者。
- 原报告只记录 base 为当时 `develop`，未记录精确 commit；因此该结论只能解释当时允许 PO
  进入真机 dogfood，不能证明当前代码或发布候选绿色。
- 四路均给出 GO / conditional GO，报告零 P0、零 P1、零 dogfood blocker，并归并出 6 类 P2；
  Claude 路称逐文件覆盖 297 个文件，其他三路为轴向或高流量抽样。
- 已知证据边界：四路都未运行 `xcodebuild test`；真机、打印、OCR、并发和 OOM 仍需 dogfood。
  §F 的 6 类 P2 是历史快照，只有重新通过 Current Admission 才能恢复执行。

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
| 06-30 | 协作模型：Claude shape → Codex 执行（可挑战）→ Claude 只读复核 → PO 合并；已被 07-16 的角色制协作模型 supersede | 历史记录；当前权威见 `docs/how-to/parallel-lanes.md` |
| 07-01~04 | 三次纠正“不可能 / 必须人工”论；当前耐久规则是先核对 live 工具、API 与可复现实证，再报告真实边界 | `AGENTS.md` §2 + `docs/how-to/parallel-lanes.md` §3；私有记忆不再是 owner |
| 07-02 | **规划 freshness 对账成为习惯**并固化入仓 | `docs/how-to/parallel-lanes.md` §3（PR #849） |
| 07-06 | **多窗口并行模式采用**（主刀 / 副刀 / 运维 / QA；write ≤ 2；合并串行） | `docs/how-to/parallel-lanes.md` 多窗口小节（PR #855） |
| 07-06 | 老窗口退役；PO 转发降级为提醒信号（Claude 自查仓库为准） | 本台账 |
| 07-11 | **产品决策五态 + 旧规范显式 supersede + contract-first**（effective）；Draft 实验可先存在，但跨 feature / 数据 wire / 公开 / 商业 / 平台变更必须先有上游契约，每次合并仍需 PO 单独授权 | `AGENTS.md` §1 + `docs/how-to/definition-of-ready.md` |
| 07-16 | **Agent 控制面改为角色制**：Codex C1 默认统筹；模型不永久拥有文件；Claude / Gemini / Grok 默认只读复核，只有 PO / shaping 显式分配时进入独立 write lane；active write WIP ≤ 2，合并串行且逐次授权 | `AGENTS.md` + `docs/how-to/parallel-lanes.md` |
| 07-16 | **Write WIP v2**：active write ≤ 2；满足精确 head 冻结、必需门禁全绿、PR / handoff 完整且无 blocker 的 slice 可进入 frozen merge queue（≤ 2）并退出 active 计数；任何新 commit、冲突、门禁失败或未解决 finding 使其退回 active；串行合并与精确 head 授权不变 | `AGENTS.md` + `docs/how-to/parallel-lanes.md` + PR 模板 |

## E. 处置类

| 日期 | 决策 | 归属 |
|---|---|---|
| 06-27 | 23 个历史分支与旧 worktree **不备份直接删除**；Codex 本地会话缓存清除 | 已执行 |
| 07-06 | 10 + 1 个旧分支（含 6 个含独有工作的）全部删除 | 已执行；C3 报告 |
| 07-06 | pbxproj 584 行 Firebase 死引用：先丢弃、后专刀正式清理 | PR（pbxproj-firebase-deadrefs） |

## F. 2026-07-07 历史队列快照（不得据此排期）

以下列表只解释当时尚未处理的事项。当前优先级、issue 状态与 Release 1 disposition 必须从
live GitHub、Release PRD、owning feature spec 和当前审计入口重新核对。

- **N2：Mac mini 网络**（固化直连 vs 还原修 OpenClash）——最急，443 已成每日税
- 公开上架合规时点（legal）/ China 挂起资源续费处置（约 2027-01）
- GAP-R1（复习中删除）/ hard-easy 评分 / printed 事件 / ADR-005 Layer A / `reviewItems` 永久 wire key
- **P2 加固队列（四方审计浮现，6 类，TestFlight 后按 Tier 开刀）**：Tier-A ① Share Extension GPS 剥离 / 测试 ② DataExecutor / ProfileManager fatalError → 错误弹窗 ③ 日志 Profile 名 PII；Tier-B ④ CSV 导入大文件 OOM ⑤ 含图备份恢复 round-trip 测试缺口 ⑥ LiveServiceContainer 默认 mock → NoOp
- TestFlight 执行：~~ASC 建记录（07-07 已完成，Apple ID 6788202421）~~ → 真机 P1-P6 → Organizer 首传（§E，约 1-2 小时）

## 历史统计

截至 2026-07-16 的历史估算约 **33 组已拍 + 7 项在队**。该旧统计不包含 07-19 的四项 Release safety 裁决，也不得用于当前排期；live 状态以 owning authority 与 GitHub 为准。

草案中标记“待路由”的 5 项已随本文件入仓路由：

| 草案待路由项 | 入仓归属 |
|---|---|
| SmartPaper 入口非 Pro 门 | `docs/features/backlog/feat-smartpaper.md` §3 |
| 损坏库恢复 UX 裁决 | `docs/features/active/feat-backup.md` + `docs/features/active/feat-profile.md` |
| 质量基线原则 | 本台账 |
| TestFlight 顺延 | 本台账 + `docs/how-to/release-and-ci.md` |
| 四方审计 GO + 6 P2 延后 | 本台账 + §F 队列 |
