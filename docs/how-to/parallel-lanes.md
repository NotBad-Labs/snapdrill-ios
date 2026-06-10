# 三路并行 lane 协调（共享 SSOT）

> 三个 agent 可独立并行开发 SnapDrill：**Codex**（UI 叶子）/ **Antigravity**（合规+官网）/ **Claude**（Core·Data·CI·集成闸）。
> 本文是三 lane 的**单一真相源**——边界/接口/合并顺序/完成信号。各 lane 开工前读一遍。
> **唯一可靠的强制门禁是 CI（`.github/workflows/ci.yml`）**；本地 hook / 日志 / 口头转达只是早期提醒，不是唯一防线。
> 背景：三路协调协议异源研究（2026-06-10）。**刻意轻量**——单人 + 3 个 GUI/终端 agent，不套大团队重流程。

## 0. lane 拓扑 + 路径白名单（谁可碰哪些文件）

| lane | agent | 可触碰路径（白名单） | 拥有的"写区"（改它须该 lane） |
|---|---|---|---|
| **Core·Data·CI·集成闸** | Claude（终端） | `Packages/SnapDrillCore/` `Packages/SnapDrillData/` `SnapDrill/App/`（composition root）`.github/` `docs/decisions/` `docs/how-to/` | @Model / ServiceContainer 协议 / MigrationPlan / 对外 DTO / Notification name |
| **UI 叶子** | Codex（GUI worktree `feat/ui-redesign`） | `Packages/SnapDrillFeatures/` `Packages/SnapDrillUI/` `docs/ui-redesign/` | View body/布局/视觉、Router 内部 case |
| **合规·官网** | Antigravity（GUI，2 worktree：snapdrill-ios + notbad-website） | `docs/*.md`、Swift **注释行**、官网仓草案文件 | 仅文档 + 注释，**零业务 Swift** |

越界（碰白名单外文件）= 停手回报 PO，不自行决断。

**集成文件（无叶子 lane 可独占，高冲突，改动一律走 Claude 串行）**：`SnapDrill.xcodeproj/project.pbxproj`（target / 文件引用）、5 个 `Package.resolved` lockfile（`Packages/SnapDrill{Data,UI,Infrastructure,Features}/` + workspace `SnapDrill.xcodeproj/project.xcworkspace/.../swiftpm/Package.resolved`）。任一 lane 要加/改 SPM 依赖或 target 成员 = **知会 Claude 串行改**，别在各自 worktree 各改各的 lockfile / pbxproj（必撞 merge 地狱）。这两类未列入上面任何 lane 白名单 = 默认归 Claude（集成闸）。

## 1. 冻结集（共享上游契约，改前须 Claude 串行 + 广播）

**🔒 铁律：成员与数字一律 `grep` 当前 develop，不凭记忆。**（曾因凭记忆把属性数 13 误写 14、并编造了 3 个不存在的 View 类型——这是真事故。）

- **Core ServiceContainer 协议属性**：以 `grep -cE '^\s+var \w+:' Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift` 为准 —— **当前 develop = 13（异源对抗审 2026-06-10 grep 实证）**。⚠️ #799（MetricKit）**尚未合 develop**，合并后将增第 14 个 `metricService`；**它合并前冻结集就是 13，别照"14/metricService"写**（曾把拟态当现态写进本文档，已纠）。增属性 = 破坏 `LiveServiceContainer`/`MockServiceContainer` 两 conformer，编译期强制同步。
- **Data @Model（3 个）**：`ReviewItemModel` / `CategoryDimensionModel` / `CategoryValueModel`。改字段 = 零用户期原地改 V1、不写迁移（no-legacy-baggage）。
- **Library 跨 feature 导出 View（public，被 Settings/Dashboard 消费）**：`CategoryManagerView` / `LibraryEditView` / `LibraryView` / **`SFSymbolPickerView`**（异源审补：`SFSymbolPickerView.swift:19` public，被 `FeatureSettings/EditProfileView.swift:221` 跨 lane 消费——Codex 动它 init 会断 Settings）。grep `public struct .*View` 于 `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/` 复核。**`SubjectManager/SourceManager/GradeManagerView` 类型已不存在**（被 `CategoryManagerView` 取代），但**源 `.docc`/README/`Package.swift` 注释仍误称它们 public**（`SnapDrillFeatureLibrary.docc:19-21` 等 stale）——同源漂移陷阱，**信 grep 不信 docc**。改 public init 签名 = 跨接缝契约，Codex 改前知会 Claude。
- **对外 DTO（比 @Model 更需冻结，消费方更多）**：`ReviewExportSnapshot`（CSV+PDF 消费，**已在 develop**）。⚠️ `MetricPayloadSnapshot` **当前源树 0 命中**——随 #799 才落地，**未合前不是真 DTO，别冻结/别消费**。

仅 **Claude** 增删冻结集成员。

## 2. 接口变更协议

1. 动 Core/Data 公共契约 / DTO / Notification name = **Claude 单边串行**，改完在 PR + memory 广播（含 `file:line`）。
2. UI 改 public init 签名 / `@Environment` 消费键 = 跨接缝，**改前知会 Claude**。
3. 合规改 `.swift` = **只允许注释行**；任何非注释 diff 走 Claude review 闸。

## 3. 合并顺序 + rebase-then-verify（核心规则）

**按依赖层从下往上合：Core → UI → Features；docs 随时。** 让上层 lane 最后合、rebase 到含新下层的 develop 做最终 `build-for-testing`，拿真正的 post-merge 集成信号。

- 每 lane PR merge 前：`git fetch && git merge-base --is-ancestor origin/develop HEAD` 不成立则 **rebase 到 `origin/develop` HEAD（非分支点）重跑 AllTests**。
- 每合一个 lane → 下游未合 lane 强制 rebase + 重验才能续合。
- ⚠️ **已知坑**：本地 `develop` 易落后 `origin/develop`（曾落后 11 个 commit）。**永远以 `origin/develop` 为合并基线**，别在 stale 本地 develop 上验"集成绿"——那是假绿。
- 回滚：develop CI 红 = 立即 `revert` 最近一次 merge（LIFO）拉回已知绿，再在 lane 分支查根因；优先 **squash merge**（每 lane = 一个可独立 revert 的 commit）。
- ⚠️ **revert 后连锁**：`revert` 改写了 `origin/develop` HEAD → **所有未合 lane 必须先 rebase 到 revert 后的 HEAD 再续**（与合并后 rebase 同源风险，别在已被撤掉的基线上继续累积）。

## 4. 完成信号（废口头转达）

GUI agent（Codex/Antigravity）是黑盒，完成靠 PO 口头转达零留痕 → 改为**文件系统产物**：
- 完成 = **推分支 + 开 draft PR + CI 绿 + PR 描述三段式**（## 完成信号 / ## 覆盖目标哪部分 / ## 未覆盖现状 / ## 跨层发现 / ## 触碰边界自查）。
- Claude 工程闸 review 触发 = PO 给 PR 打 `needs-eng-gate` label，Claude `gh pr list --label needs-eng-gate` 轮询。
- **GUI lane 信任 = 读真 diff，非读自述**（实证 ground-truth 封顶）。

## 5. 验收门（CI 共享强制）

**现有（保持）**：`swiftlint --strict` + AllTests `build-for-testing` + `test` + develop-only XCUITest E2E + 反向依赖门禁（`ci.yml` Check Package Dependencies）。每路 PR 过此 = 验收。

**裁决后（异源对抗审 2026-06-10 grep 实证；判据 = 只加"确定性 + 低成本 + 拦得住现有 CI 拦不住的真并行故障"的门）**：

| 拟加门禁 | 裁决 | 理由（实证） |
|---|---|---|
| **lane fencing**（`git diff --name-only` 比白名单、越界 exit 1） | ✅ **加（最高杠杆）** | 现有 CI 查编译/lint/测试/import 方向，**唯独不查"错 lane 碰错文件"**（`ci.yml` 0 命中）；GUI agent 彼此盲（§7），这门直接焊死核心协调风险。 |
| **feature-status SSOT 校验** | ✅ **加（小检查）** | `Scripts/generate_feature_status.py` 已带 `--check`、pre-commit 已跑，但 **CI 未接**——确定性防漂移、非 ceremony。 |
| 完成声明 grep（校验 PR 三段式文本） | ❌ **不加（纯 ceremony）** | 本文档自己就说"信 diff 不信自报"（§4）；grep 只能证明 agent 写了小标题、证不了真完成。 |
| CODEOWNERS | ❌ **暂不加** | 单 PO 场景且未开强制 review 时基本只是 GitHub UI 元数据；同批 PO-owned 路径由 lane fencing 保护更强。分支保护现靠本地 `pre-push`。 |

> 加这两门 = Claude（CI 域）的工程活，待 PO 点火后做；属 CI 共享强制层，落地即对三路生效。

## 6. 无主 straddling 工件（归属待 PO 定）

- **faq URL**（`SettingsView.swift:220` 硬链接 `notbadhq.com/snapdrill/faq`，线上已 404）：slug SSOT = **Antigravity（官网信息架构）**，app 侧 = 消费方；任一方改 slug 必广播对侧。
- **本地账本**（PMF pitch A，未实现）：数据契约 = **Claude 先冻结**，再交 Codex 渲染只读 snapshot。
- **analytics seam**：隐私文案以 `DependencyContainer.swift` 实际注入（`NoOpAnalyticsService` 零采集）为 ground-truth、引行号，不凭假设。

## 7. GUI agent 协作现实（orchestrator blindness）

Claude（终端）**看不到、碰不到** Codex/Antigravity 的 UI；只能读它们留在文件系统的产物（commit/分支/worktree/日志/draft PR），且**仅终端开着、Claude 在运行时**。**PO 是 Claude 与 GUI agent 之间唯一的人肉桥**。这就是 §4 完成信号必须是文件系统产物的根本原因。

**本地构建缓存互踩（异源审补）**：3 个 agent 在不同 worktree 跑本地 `xcodebuild`（`AGENTS.md` 的命令未钉 `-derivedDataPath`/`-clonedSourcePackagesDirPath`）会共享全局 DerivedData/SPM 缓存 → 可能互相污染增量编译。各 worktree 本地构建建议各钉独立 `-derivedDataPath`；但**唯一权威验收始终是 CI**（CI 已 per-workspace 隔离 DerivedData），本地绿不算数。
