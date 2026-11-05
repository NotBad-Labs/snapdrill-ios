# Docs 审计：一般性 iOS 要求与内部一致性

> 审计对象：`greenfield/rebuild-from-zero` @ `f992aaa5`
> 范围：`Docs/PRODUCT.md`、`ENGINEERING.md`、`ACCEPTANCE.md`、`CUTOVER.md`、`README.md`、`REVIEW.md`（现行章节）、`Docs/STAGE0-REVIEW-RESPONSE.md`
> 方法：逐条给 `path:line`；严格区分「阶段 0 按设计尚未写」与「现在就自相矛盾」
> 状态：**已随本分支提交（11-05 18:27）**，供 PO 与 Cursor（`chbearxiong`）共同研究。第 4 节草拟内容**未落地**；所有涉及产品语义的改动仍需 PO 裁决

---

## 0. 结论

| 视角 | 判定 |
| --- | --- |
| 作为**阶段 0 产品契约** | 合格偏上。11 条结果可证伪、非目标明确、设备/受众/发版顺序清晰，旧文档包袱确实卸掉了；`§6.2` 按设备族而非机型定矩阵、§2 拒绝编造 ROI，都是第一性原理的好例子 |
| 作为**完整 iOS 项目文档体系** | 远不完整，但**大部分缺口按设计属于阶段 2+，不算阶段 0 缺陷** |
| 真正该现在处理的 | **1 个硬缺口（工具链未定义）+ 6 处内部矛盾 + 4 类追溯缺口** |

最值得警惕的不是「缺文档」，而是**状态陈述互相矛盾**：同一分支里 runner 既 online 又 offline、提交身份既有新约定又有旧正文、灰度既被禁止又被列为阶段 5 产物。这恰好违背你要求的「越上游越要清晰稳定」——下游两台机器会各自挑一句当依据。

---

## 1. 一般性 iOS 开发要求对照

图例：✅ 已有 ／ ⚠️ 部分 ／ ⬜ 阶段 2+ 按设计未写（可接受） ／ ❗ 现在就该补或澄清

| 要求项 | 状态 | 位置 / 说明 |
| --- | --- | --- |
| 产品定位、目标用户、范围、非目标、结果级验收 | ✅ | `PRODUCT.md` §1/§3/§4/§5/§7 |
| 最低 OS、设备族、屏幕方向 | ✅ | §6.1 `iOS 26.0+`；§6.2 设备矩阵 |
| 构建受众与发版顺序、同 build lineage | ✅ | §6.3；L129 明确 version/build/ASC 同源 |
| **Xcode / Swift / lint 工具链版本** | ❗ | `ENGINEERING.md` L52 明确「旧仓库 develop 的快照 Xcode 26.6 **不是本分支的产品决定**」，但**没有给出本分支自己的针**；L50 只说 Mac 工作机「可见 Xcode 27.1」。没有工具链针，T0/T1 的具体命令、`build-for-testing` 的可复现性都无从定义 |
| 架构分层与依赖方向 | ⚠️ | 仅 `ENGINEERING.md` L14 一句「依赖朝 Core 收敛，Core 零第三方依赖」；无模块职责、无 DAG、无 owner 文档 ⬜ 阶段 2 |
| 数据模型 / 持久化 / 迁移 / 备份格式 | ⬜ | `PRODUCT.md` §6.4 明确归阶段 2，`ENGINEERING.md` L14 把「备份格式已冻结」设为阶段 2 准出 —— 设计自洽 |
| 第三方依赖清单与许可 | ⬜ | 阶段 2；Core 零三方依赖是约束而非清单 |
| **Info.plist 权限用途说明** | ❗ | 结果 2 已定相机 / 文档扫描 / 相册 / PDF 输入，结果 9 涉及隐私，但**全文没有列出所需权限键与用途文案**（`NSCameraUsageDescription` 等）。这是 App Store 审核硬项，至少应在阶段 0 列清单 |
| `PrivacyInfo.xcprivacy`、App Privacy 营养标签、数据流声明 | ⬜ | 阶段 2 / 发布前；但需指定 owner（`ENGINEERING.md` L14 只泛称「隐私契约」） |
| 加密出口合规（`ITSAppUsesNonExemptEncryption`）、年龄分级 | ⬜ | 发布前；当前无任何占位 |
| 签名主体 / Bundle ID / Team / entitlements / Provisioning | ⬜ | §6.1 说「一个全球构建，不分区域包」，但没说主体与 Bundle；§5 排除 Share Extension 等，未说明 entitlements 范围 |
| 无障碍：VoiceOver / Dynamic Type / AX 顺序 | ✅ | 结果 10、A10 |
| 无障碍：对比度、触控目标、Reduce Motion、**深色模式** | ❗ | 结果 10 **未提深色模式**；旧 effective PRD 的 `PRD-12` 是包含深色模式的。若是有意收窄，应写明；若是遗漏，属于产品语义漂移 |
| 本地化：语言、兜底、术语表、文案 owner | ⚠️ | §6.2 L111 只有「英文 + 简体中文，英文兜底」；无术语表、无文案 owner、无日期/数字格式约定 |
| 性能 / NFR：库容量、内存、大图、OCR 耗时、备份体积上限 | ⬜ | 阶段 2；但对「本地图片资料库」是关键 NFR，建议至少列为阶段 2 必答项 |
| 测试策略：类型、覆盖率、设备/OS 矩阵 | ⚠️ | `ENGINEERING.md` §2 有 T0–T4 分层，但无具体设备与 iOS 版本矩阵、无覆盖率口径 |
| 崩溃监控 / 诊断 | ❗ | `ENGINEERING.md` L17 写「崩溃监控」，与 `PRODUCT.md` L35/L81「不做第三方行为分析」、L68「没有用户未发起的上传」**可能冲突**，未说明用 MetricKit 还是第三方 SDK |
| CI 配置、签名、TestFlight、ASC 提交证据包 | ⚠️ | `ENGINEERING.md` L16 只说「每个 build 独立证据包」；⬜ 无代码阶段可不做 |
| App Store Connect 元数据（截图/描述/关键词/审核说明/隐私政策 URL） | ⬜ | 全文只在 §6.3 L129 提「公开元数据」作为隐藏能力检查面，**没有正面的元数据契约** |
| 发布后：崩溃监控、迁移与恢复 | ⚠️ | `ENGINEERING.md` L17 提到，但表述与 §6.3 冲突（见矛盾 3） |

**判断**：缺的大部分是「按设计还没到阶段」，不构成阶段 0 缺陷。真正该现在补的只有三项——工具链针、权限用途说明清单、深色模式这一处可能是无意的产品语义收窄。

---

## 2. 内部逻辑矛盾（逐条，按严重度）

| # | 矛盾 | 证据 A | 证据 B | 严重度 | 建议 |
| --- | --- | --- | --- | --- | --- |
| M1 | **runner 状态互斥** | `CUTOVER.md` L25「当前 runner offline，本机无 Apple 工具链」 | `ENGINEERING.md` L51「2026-11-05 核查为 online，busy=false」；`ACCEPTANCE.md` L31「已于 2026-11-05 上线」 | 高 | 改 CUTOVER L25 为「runner 已 online，但本分支无代码与 CI，尚无可安装构建」 |
| M2 | **崩溃监控 vs 隐私边界** | `ENGINEERING.md` L17「崩溃监控」 | `PRODUCT.md` L35/L81「不做第三方行为分析」、L68 结果 9「没有用户未发起的上传」 | 高（隐私） | 明确「仅本机 MetricKit 诊断、不上传」或「需 PO 单独裁决」；否则会被实现方当成允许第三方 SDK |
| M3 | **提交身份约定冲突** | `REVIEW.md` L3「第 7 节『一律用 greenfield-draft』被本条代替」、`README.md` L17「Windows 用 chramboliao 提交推送」 | `REVIEW.md` L82（§7）、L170（§11）正文仍写「一律使用中性占位 greenfield-draft」 | 中 | §7/§11 正文加「本段为 11-04 约定，已被顶部 11-05 协作条代替；误用记录仍有效」 |
| M4 | **灰度被禁又被列为产物** | `PRODUCT.md` L115「没有远程开关，也没有按百分比放开的灰度」 | `ENGINEERING.md` L17 阶段 5「分阶段放量」 | 中 | 区分 Apple 侧 phased release 与运行时远端开关；或把 L17 改为「按构建推进的发布与监控」 |
| M5 | **README 自称草稿 vs 产品权威** | `README.md` L1「（本地草稿）」、L4「**不是产品决策**」、L52「本地草稿已推送」 | `PRODUCT.md` L5「本文件是这条重构的**唯一产品权威**」 | 中 | README 改为「本分支是候选工作面，产品权威是 Docs/PRODUCT.md；未 effective」；「不是产品决策」应限定为「未合入 develop、不替代 develop」 |
| M6 | **Docs 目录清单与实际不符** | `ENGINEERING.md` L65 `Docs/ # PRODUCT、ACCEPTANCE、ENGINEERING、CUTOVER`（4 个） | 实际 5 个；`README.md` L29 列了 `STAGE0-REVIEW-RESPONSE.md` | 低 | L65 补齐或改为「见 README 内容表」 |
| M7 | **阶段 0 产出枚举不一致** | `PRODUCT.md` L8「三份产出：愿景与原则、立项结论、Release 1 目标与结果」 | `ENGINEERING.md` L12「愿景、立项、Release 1 结果、设备矩阵、受众和发版顺序」（6 项） | 低 | 统一为「三份产出，其中第三份含第 4/6 节」或改两处措辞 |
| M8 | **orphan 与路径 B 的可执行性缺口** | `PRODUCT.md` L156「与 develop 没有共同祖先，不能直接开对比 PR」；`REVIEW.md` §10 | `CUTOVER.md` L21 仍问「替换 develop 还是新建 repo」 | 中 | 补一句：替换需 `--allow-unrelated-histories` 或内容镜像分支，且属不可逆动作需 PO 单独确认 |

> 注：本文件加入后 `Docs/` 实为 6 个文件，`ENGINEERING.md` L65 的清单差距进一步扩大（M6）。**本提交刻意不修改任何被审计对象**（`PRODUCT.md` / `ENGINEERING.md` / `ACCEPTANCE.md` / `CUTOVER.md` 均保持 `f992aaa5` 原样），以便 PO 与 Cursor 看到矛盾发生时的原始状态；仅在 `README.md` 内容表补一行收录本文件。

**另有一处我方遗留错误（非对方引入）**：`Docs/STAGE0-REVIEW-RESPONSE.md` §3 把 `PRODUCT.md` §7 的 5 条「结果级验收」全当成阶段 0 准出、并判 3–5 条 ❌，是**用错尺子**（阶段 0 准出在 §2）。该文件被 `README.md` L29 列为现行内容，应标注为历史快照或修正，否则会被后来者沿用错误判据。

---

## 3. 文档质量与追溯缺口

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| Q1 | **书面确认未定义载体** | `PRODUCT.md` §2 L47/L48、§8 L147 | 关卡本身没有格式：载体、签署人、版本锚点、改动后是否重签、两次确认（阶段 0 / 阶段 1）的关系都未定义。这是最后一个上游歧义，详见 §4.1 |
| Q2 | **§6.3 lineage 约束无 oracle** | `PRODUCT.md` L129 | 「签名/隐私/归档/上传/TestFlight/ASC 指向同一 commit、version、build、ASC build」是产品级约束，但 `ACCEPTANCE.md` 11 条用例无一条验证它；A11 只查隐藏能力 |
| Q3 | **§6.2 与 §5 缺系统性负面用例** | `PRODUCT.md` L111、§5 | 英文兜底、免费/无广告/无 IAP、全球版、以及「账号/Pro/CloudKit/题库/Word/Share Extension」等非目标，除 A1 查账户墙外没有负面检查用例 |
| Q4 | **用例对 §6 的指回不完整** | `ACCEPTANCE.md` L18/L19 vs `PRODUCT.md` §7 L138 | A10 可观察结果含「旋转不换横屏、图片保持自身方向」(§6.2)、A11 含「仅本人构建记录不带入」(§6.3)，但「结果」列只写 10/11，未显式指回 §6 |
| Q5 | **T 层映射与验证手段不匹配** | `ACCEPTANCE.md` L26–29 | A4 的「切后台、杀进程再打开窗口仍在」(L12)、A8 的「崩溃/被杀后草稿还在」(L16) 明显需要运行时/真机，却只列在 T1「逻辑」；T1 定义为 `build-for-testing + test-without-building`，覆盖不了 |
| Q6 | **「可观察结果」缺验证手段** | `ACCEPTANCE.md` L17/L19 | A9「没有用户未发起的上传」需抓包、A11「后台任务不运行」需运行时检查，表里没给工具/环境，L31 只笼统说跑不了 |
| Q7 | **状态/生命周期混用** | 多文件 | `未 effective`、`未 ratify`、`未书面确认`、`候选`、`未执行` 五个词散落各处，没有一张状态表说明各自含义与转换条件 |

---

## 4. 草拟（可直接 apply，未落地）

### 4.1 书面确认机制（建议新增 `Docs/CONFIRMATION.md`，并在 `PRODUCT.md` §8 引用）

```markdown
# 书面确认（Confirmation）

> 本文件定义 `PRODUCT.md` §2「书面确认」与 §2 L47「进入阶段 1 需要另一次书面确认」的执行格式。
> 未写入本文件的确认不成立。聊天、PR 描述、commit message 里的附带语句、issue 评论都只作证据。

## 载体
确认以 `Docs/PRODUCT.md` frontmatter 的字段为准，并由一个独立的确认 commit 承载；两者必须同时存在。

## 字段
confirmed_at: <ISO 8601 UTC>
confirmed_by: PO
confirmed_sha: <承载该版 PRODUCT.md 的 commit sha>
confirmed_scope: §1 / §2 / §3 / §4 / §5 / §6 / §7 / §8 全文
confirmation_type: stage0_baseline | stage1_admission
supersedes: <前一次确认的 sha，首次为空>

## 规则
1. PO 以本人账号签署；不接受代理或自动确认。
2. `confirmed_sha` 是版本锚点：PRODUCT.md 发生任何改动后，该确认自动失效，须重新确认并写入 `supersedes`。
3. 两次确认分开：stage0_baseline 冻结需求基线；stage1_admission 才授权进入阶段 1。前者不隐含后者。
4. 确认后冻结 ≠ effective；effective 仍须合入选定主干（§2 L48）。
5. 确认不授权 merge、上传 TestFlight、发布、go/no-go；这些仍按 ENGINEERING §3 逐次单独确认。
6. 确认可被新的书面确认 supersede，旧确认记录保留在 git 历史中，不删除。
```

同时在 `PRODUCT.md` §8 末尾补一句：「书面确认的载体、字段与失效规则见 `Docs/CONFIRMATION.md`。」

### 4.2 两处不一致的替换文本

**`Docs/CUTOVER.md` L25**（M1）：

```
旧：| 5 | 验证：`mac-mini` 上线且工具链对齐后再切换 | 当前 runner offline，本机无 Apple 工具链 |
新：| 5 | 验证：`mac-mini` 工具链对齐后再切换 | runner 已于 2026-11-05 上线；本分支尚无代码与 CI，没有可安装构建，验收用例未执行 |
```

**`REVIEW.md` §7 L82 与 §11 L170 段首**（M3）：加一句

```
> 本段的「一律用 greenfield-draft」为 2026-11-04 约定，已被文件顶部 2026-11-05 协作条代替；
> 后续 Windows 侧按该条用 chramboliao 提交推送。本段及第 11 节的身份误用记录仍然有效，仅作历史证据。
```

### 4.3 建议同批补的三项（非阻塞）

1. `ENGINEERING.md` §5 增一行「本分支工具链针：Xcode __ / Swift __ / SwiftLint __（待 PO 定；Mac 工作机可见 27.1 仅为环境事实）」——解决硬缺口。
2. `ACCEPTANCE.md` 增一条 A12 覆盖 §6.3 L129 的 lineage 一致性，并在 A10/A11 的「结果」列写成 `10 + §6.2` / `11 + §6.3`。
3. `ACCEPTANCE.md` T 层表把 A4、A8 的运行时部分从 T1 移到 T2，并给 A9/A11 标注所需手段（抓包 / 运行时检查）。

---

## 5. 需 PO 裁决（不是起草方能定的）

1. **深色模式**：结果 10 未包含，是有意收窄还是遗漏？（相对旧 PRD 属产品语义变化）
2. **崩溃监控**：仅本机 MetricKit、不上传？还是允许第三方 SDK（那会与结果 9 冲突，需改产品语义）？
3. **分阶段放量**：指 Apple 侧 phased release 还是运行时灰度？§6.3 L115 禁止后者。
4. **工具链针**：本分支用哪个 Xcode / Swift / SwiftLint 版本？
5. **§4.1 的确认机制**是否采纳，以及 `confirmed_by` 的账号名。

---

*已随 `greenfield/rebuild-from-zero` 分支推送供审查；草拟内容未落地、未 effective；被审计的四份 Docs 保持 `f992aaa5` 原样，`develop` 未改动。*
