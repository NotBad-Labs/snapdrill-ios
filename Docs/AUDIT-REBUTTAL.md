# 对 `Docs/DOCS-AUDIT.md`（`01f38513`）的复核

> 复核对象：`01f38513` 的 `Docs/DOCS-AUDIT.md`
> 复核方：Mac / `chbearxiong`
> 被审计的 `PRODUCT.md`、`ENGINEERING.md`、`ACCEPTANCE.md`、`CUTOVER.md` 保持 `f992aaa5` 正文，本文件不改它们
> `DOCS-AUDIT.md` §4 的 `CONFIRMATION.md`、两处替换文本、三项补项均未落地
> 总评「合格偏上 / 1 个硬缺口」不采纳。下面逐条独立判定

编号规则：`S` 总评，`R` 对照表，`M` 矛盾，`Q` 追溯，`X` 审计自己的方法。

| 编号 | 审计条目 | 判定 | 依据 | 建议动作 |
| --- | --- | --- | --- | --- |
| S0 | §0：阶段 0 契约「合格偏上」；现在该处理的是 1 个硬缺口 + 6 处矛盾 + 4 类追溯缺口 | 拒收 | 硬缺口、深色模式、崩溃监控、灰度、lineage 用例、确认格式的判定分别在 R4、R10、M2、M4、Q2、Q1 被拒。总评的计数没有独立证据 | 不以 §0 的计数作为确认前的待办 |
| R1 | 定位、范围、非目标、结果级验收已有 | 接受 | `Docs/PRODUCT.md:15-18`、`:53-54`、`:57-70`、`:75-89`、`:135-142` | 无 |
| R2 | 最低 OS、设备族、方向已有 | 接受 | `Docs/PRODUCT.md:97`、`:103-109` | 无 |
| R3 | 受众、发版顺序、lineage 已有 | 接受 | `Docs/PRODUCT.md:115-129` | 无 |
| R4 | 工具链针未定义，是现在就要补的硬缺口 | 拒收 | `Docs/ENGINEERING.md:52` 只否定旧针：「该针不是本分支的产品决定」。阶段 0 产出清单在 `Docs/ENGINEERING.md:12`，平台冻结范围在 `Docs/PRODUCT.md:91-93`，两者都没有工具链版本。`Docs/ENGINEERING.md:50` 把 Xcode 27.1 写成 2026-11-04 的环境观察。阶段 2 准出在 `Docs/ENGINEERING.md:14`，写的是数据契约、隐私契约、发布证据和备份格式，**也没有**工具链针。因此「阶段 0 硬缺口」不成立；「文本已经把它指定给阶段 2」同样不成立 | 不在阶段 0 补 Xcode / Swift / SwiftLint 版本。不落地 `DOCS-AUDIT.md:136`。版本号等到有工程文件时再定，不提前写成产品句子 |
| R5 | 架构 DAG、数据模型、第三方清单、PrivacyInfo、加密出口、签名与 Bundle、性能 NFR、CI、ASC 元数据属于阶段 2 或更后 | 接受其「现在不是阶段 0 缺陷」 | `Docs/PRODUCT.md:6`、`:131-133`；`Docs/ENGINEERING.md:12-16`。这些行没有把上述条目列为阶段 0 产出 | 不在本阶段补这些文档 |
| R6 | Info.plist 权限用途说明必须在阶段 0 列清单 | 拒收 | 阶段 0 定死的平台项是 `Docs/PRODUCT.md:91-93`。相机等输入的用户结果在 `:61`，权限被拒绝时的结果在 `:66`。用途字符串不在这两处。`Docs/PRODUCT.md:6` 规定本阶段不写代码 | 不列 `NSCameraUsageDescription` 等键。用途文案留给后续功能说明 |
| R7 | 无障碍结果 10 已覆盖 VoiceOver / Dynamic Type / AX 顺序 | 接受 | `Docs/PRODUCT.md:69`；`Docs/ACCEPTANCE.md:18` | 无 |
| R8 | 深色模式未写，且相对旧 PRD 的 `PRD-12` 可能是语义漂移，现在就要澄清 | 拒收 | `Docs/PRODUCT.md:5`：「旧仓库文档不是输入」。`README.md:11` 同样禁止把旧文档当输入。`rg -n "深色\|PRD-12" Docs/PRODUCT.md Docs/ENGINEERING.md Docs/ACCEPTANCE.md Docs/CUTOVER.md` 无匹配。审计引用的 `PRD-12` 只出现在 `Docs/DOCS-AUDIT.md:40`。结果 10 的范围以 `Docs/PRODUCT.md:69` 的肯定句和「不承诺」列为准 | 整条撤回。不得把「相对旧 PRD 是否收窄」列为确认前的 PO 问题。若以后要把深色模式写进结果 10，那是一条新的产品建议，不能靠旧编号成立 |
| R9 | 语言只有兜底，缺术语表和文案 owner，算部分缺口 | 拒收 | `Docs/PRODUCT.md:111` 已写英文、简体中文和英文兜底。术语表不在 `Docs/ENGINEERING.md:12` 的阶段 0 产出里 | 不补术语表 |
| R10 | 「崩溃监控」与「不做第三方行为分析 / 不上传」可能冲突，严重度为高 | 拒收 | `Docs/ENGINEERING.md:17` 只有「崩溃监控」四个字，没有 SDK，也没有上传。`Docs/PRODUCT.md:35`、`:81` 禁止的是第三方行为分析；`:68` 禁止的是用户未发起的上传。这三句与「本机诊断、不上传」可以同时为真。冲突只在把 L17 读成第三方上传时出现，正文没有这种读法 | 不把 MetricKit 或第三方 SDK 写进产品契约。审计 `DOCS-AUDIT.md:145` 的二选一问题撤回。若以后要消歧，只在工程约定里复述产品禁令，不新增监控产品 |
| R11 | 测试策略缺具体机型与覆盖率 | 拒收 | `Docs/PRODUCT.md:101`：「矩阵按设备族，不按具体机型」。`Docs/ENGINEERING.md:23-27` 只定义 T0–T4 各层不能证明什么 | 不补机型清单和覆盖率百分比 |
| R12 | 阶段 5「分阶段放量、崩溃监控」与 §6.3 冲突 | 需澄清 | 见 M4。这里不单独升成 ❗ | 见 M4 |
| M1 | runner 既 offline 又 online，严重度高 | 接受「两句状态冲突」；拒收「严重度为高，因而挡住阶段 0」 | `Docs/CUTOVER.md:25` 写「当前 runner offline」。`Docs/ENGINEERING.md:51` 写 2026-11-05 online。`Docs/ACCEPTANCE.md:31` 写同日已上线。同一份 `Docs/CUTOVER.md:42` 写「runner 上线只影响以后的验证，不影响现在写产品定义」 | 不落地 `DOCS-AUDIT.md:120-124` 的替换文本。过期的是 L25 的状态从句。它不改变 `Docs/PRODUCT.md` 的准出 |
| M2 | 崩溃监控 vs 隐私，高 | 拒收 | 同 R10。`Docs/ENGINEERING.md:17` 与 `Docs/PRODUCT.md:35`、`:68`、`:81` | 不同时成立的读法没有写在正文里。不要求 PO 在确认前选择 SDK |
| M3 | 11-05 身份约定与 §7/§11「一律 greenfield-draft」并存 | 接受 | `REVIEW.md:3` 写明第 7 节的 greenfield-draft 约定被 11-05 协作条代替。`README.md:17` 规定 Windows 用 `chramboliao`、Mac 用 `chbearxiong`。`REVIEW.md:82` 与 `REVIEW.md:170` 仍写「一律使用中性占位 greenfield-draft」 | 不落地 `DOCS-AUDIT.md:127-131` 的插入句。§7 与 §11 的误用记录仍然有效；过时的是「此后一律占位」这半句。以后只在 `REVIEW.md` 正文加历史标记，不改产品文件 |
| M4 | L115 禁止灰度，L17 又把分阶段放量列为阶段 5 产物 | 拒收「已经不能同时为真」 | `Docs/PRODUCT.md:115` 禁止的是远程开关，以及会变成隐藏通道的运行时灰度；同一段 `:125-127` 规定按构建推进、三次确认分开。`Docs/ENGINEERING.md:17` 的「分阶段放量」没有写执行者。把它读成 App Store 对同一已发布构建的投放，与 `:115` 的后一句（运行时、内容后端）不冲突。与 `:115` 前一句「没有按百分比放开的灰度」字面并列时，才需要消歧 | 不把 Apple phased release 写进产品契约，也不把 L17 改成审计草案。确认前不必先回答 `DOCS-AUDIT.md:146` |
| M5 | README「本地草稿 / 不是产品决策」与「唯一产品权威」矛盾 | 拒收 | `README.md:4` 的「不是产品决策」与「不替代 `develop`」在同一行。`README.md:13` 写 `PRODUCT.md` 是本分支权威，且要 PO 书面确认。`Docs/PRODUCT.md:4-5` 同时写「候选契约，未书面确认」和「唯一产品权威」。候选文件可以是这条分支的权威，同时仍未成为替代 `develop` 的决策 | 不改 README 的地位句。标题里的「本地草稿」与 `README.md:3`「已推送」用词不一致，只是旧标题，不是第二套权威 |
| M6 | `ENGINEERING.md:65` 的 Docs 清单与实际文件数不符；审计文件使差距变成 6 | 拒收 | `Docs/ENGINEERING.md:56` 写明该树「待 PO 确认后再落地」。同树中的 `App/`、`CI/` 目前不存在，所以 L65 不是现行目录清单。现行清单是 `README.md:21-31`，`01f38513` 已把审计文件写入 L30。`git ls-tree -r --name-only f992aaa5 Docs` 在审计提交之前已有 `STAGE0-REVIEW-RESPONSE.md`，L65 当时就不是 4=实际 | 不把「审计制造了新的逻辑矛盾」成立。骨架未落地是原状态。不因本复核去改 L65 |
| M7 | 阶段 0 产出「三份」与「六项」不一致 | 需澄清 | `Docs/PRODUCT.md:8` 把产出称为三份，并写明都在同一文件。`:91-93` 把设备矩阵、受众和发版顺序定为阶段 0 内容，位置在第 6 节，不在第 3 节的标题里。`Docs/ENGINEERING.md:12` 把第 6 节拆开点名 | 这是列举粗细不同，不是两套范围。不为对齐措辞修改产品文件 |
| M8 | 不能对 `develop` 开对比 PR，与路径 B 仍询问是否替换 `develop`，构成可执行性缺口 | 拒收 | `Docs/PRODUCT.md:156` 陈述的是没有共同祖先，不能直接开对比 PR。`Docs/CUTOVER.md:17-21` 把「替换还是新建」列为需 PO 逐项确认的问题，不是一条已经授权的操作。`Docs/CUTOVER.md:29` 禁止 force push 和 rewrite history | 不补 `--allow-unrelated-histories`。那是不可逆动作的做法，`Docs/ENGINEERING.md:35` 要求逐次单独确认 |
| X1 | `STAGE0-REVIEW-RESPONSE.md` §3 用 §7 的五条当阶段 0 准出，尺子用错 | 接受 | 准出在 `Docs/PRODUCT.md:48`：审查、书面确认、合入后才 effective。§7 在 `:135-142`。其中 `:139-141` 是有构建之后才能观察的结果。`Docs/PRODUCT.md:157` 写明用例未执行是因为没有构建。`Docs/STAGE0-REVIEW-RESPONSE.md:58-67` 把这三条标成 ❌，和「书面确认」放在同一张准出表里 | 区分本身成立。`:137-138` 是现在就能核对的文档规则；`:139-141` 不是阶段 0 关卡。不回头改那份审查回应的正文，避免把历史审查改写成新结论 |
| Q1 | 书面确认没有载体，是最后一个上游歧义，应按 §4.1 写死 | 拒收 | `Docs/PRODUCT.md:10`、`:47-48`、`:147` 定义了确认的效果：冻结基线、进入阶段 1 另一次确认、确认不等于 effective。没有 frontmatter 字段。`README.md:17` 与 `REVIEW.md:117` 把产品语义、阶段准出和不可逆动作的决定权留给 PO。`Docs/DOCS-AUDIT.md:94` 若生效，会规定「未写入本文件的确认不成立」，并在 `:108` 指定签署方式 | 不新增 `Docs/CONFIRMATION.md`，不在 `PRODUCT.md` §8 引用它。格式未写是事实，不是确认前的缺口。PO 的一句指向某个 `PRODUCT.md` sha 的书面确认，在 PO 另定格式之前就够用 |
| Q2 | §6.3 lineage 没有独立 oracle，因而是追溯缺口 | 拒收 | `Docs/PRODUCT.md:137` 要求第 4 节每条结果至少一个可观察现象。`:138` 要求每条用例能指回第 4 节或第 6 节，没有要求第 6 节每一句都有独立用例。`Docs/ACCEPTANCE.md:4` 的「每条结果」与 A1–A11 对应第 4 节。`Docs/ACCEPTANCE.md:9-19` 没有一行同时检查 commit、版本号、构建号、ASC build。这是「没有专行」，不是「违反 §7」 | 不新增 A12，不落地 `DOCS-AUDIT.md:137`。L129 仍由 `Docs/PRODUCT.md:129` 约束；T4 的位置在 `Docs/ENGINEERING.md:27` 与 `Docs/ACCEPTANCE.md:29` |
| Q3 | §5 非目标与英文兜底、免费、全球版缺少系统性负面用例 | 拒收 | 同 Q2：`Docs/PRODUCT.md:137-138` 不是第 5 节的覆盖配额。非目标在 `Docs/PRODUCT.md:75-87`。公开构建的总闸是结果 11（`:70`）和 `Docs/ACCEPTANCE.md:19`。账户墙在 `Docs/ACCEPTANCE.md:9` | 不按非目标逐条加负面用例 |
| Q4 | A10/A11 的观察涉及 §6，结果列只写 10/11 | 接受 | `Docs/ACCEPTANCE.md:18-19` 的观察含旋转、图片方向和构建记录不继承。`Docs/PRODUCT.md:107-109`、`:121`、`:129` 是这些观察的出处。结果列只写了 `10` 和 `11`。文件头 `Docs/ACCEPTANCE.md:3-4` 允许验收第 6 节，列里没写出来 | 若以后改验收表，只改这两格的引用写法。本次不改 `ACCEPTANCE.md` |
| Q5 | A4/A8 的杀进程与切后台只落在 T1，而 T1 不证明运行行为 | 接受「运行时半句没有落点」；拒收「整条 A4/A8 被错误地只放在 T1」 | `Docs/ENGINEERING.md:24`：T1 不能证明 UI 与无障碍。`Docs/ACCEPTANCE.md:26` 写的是「A4、A8 的逻辑」，不是整条场景。`:12` 与 `:16` 含切后台、杀进程、崩溃。这些半句不在 `:27` 的 T2 行 | 以后把杀进程、切后台、崩溃恢复改挂到 T2。本次不改表 |
| Q6 | A9/A11 没写抓包和运行时检查工具 | 拒收 | 工具和命令属于完成报告，`Docs/ENGINEERING.md:29`。`Docs/ACCEPTANCE.md:31` 写明没有构建，所以这些用例没有执行记录。阶段 0 的用例是可观察结果，不是操作手册 | 不在确认前补工具名 |
| Q7 | 五个状态词没有转换表 | 拒收「因此阶段 0 不合格」；接受「`未 ratify` 是已删除词」 | 转换已写在 `Docs/PRODUCT.md:10` 与 `:48`：书面确认后冻结基线，合入选定主干后 effective。`Docs/ENGINEERING.md:39` 写明去掉五态生命周期和 ratify。`README.md:4` 仍使用「未 ratify」 | 以后从 README 状态行去掉「未 ratify」。本次不改 README 的地位句，只在本复核中记录 |

## 需要 PO 裁决的问题

下列问题经过这次复核之后仍然要由 PO 决定。审计 §5 的五问不在此列。

1. 是否书面确认当前 `Docs/PRODUCT.md` 为阶段 0 需求基线。确认前不进入阶段 1。本复核不代为确认。
2. 审计 §5 的深色模式、崩溃监控 SDK、Apple phased release、工具链版本、`CONFIRMATION.md` 五问，按 R8、R10、M4、R4、Q1 撤回，不作为确认前的必答。
3. `Docs/CUTOVER.md:25` 的 offline 从句、`REVIEW.md:82` 与 `:170` 的占位身份从句、`README.md:4` 的「未 ratify」，是过期句子。要不要改，不改变产品语义；本复核按约束不落地审计 §4 的替换文本。

---

*复核文件。不改产品语义，不落地 `Docs/DOCS-AUDIT.md` §4。*
