# AGENTS.md

> SnapDrill 编码 Agent 的最小启动契约。它负责路由权威、执行边界和完成证据，不是产品
> SSOT、架构快照或 API 手册。`CLAUDE.md` 是指向本文件的兼容软链接。

## 1. 优先级与真相源

具体权威高于通用启发式。本文件中的行为原则不能覆盖产品、数据、安全、隐私、发布、平台
指令或当前任务的精确契约。

- **产品应该是什么**：`develop` 中 effective 的 Product Constitution
  (`docs/explanations/vision.md`) > 当前 Release Product Contract > 所属产品政策 /
  typed decision > owning feature spec > 验收标准。
- **产品现在是什么**：live 代码、测试、构建、设备和发布实证 > 自动生成状态与当前事实文档
  > 历史材料与 Agent 私有记忆。
- **实现方式**：owning 架构、数据或操作契约约束实现边界；当前 task brief / acceptance /
  red lines 在该边界内固定本 slice；本文件的默认行为原则只在两者未规定处补充判断。

代码只能证明当前实现，不能反向改写产品目标。对话中的新意图先进入
`exploration -> shaped candidate -> ratified -> effective -> superseded`；只有归属权威合入
`develop` 后才替换其他 lane 的 tracked baseline。PO ratify 不等于授权 merge、上传或发布。

## 2. 工程行为原则

以下是默认判断方式，不是可覆盖精确契约的“最高铁律”。

1. **先理解再修改**：读取 owning SSOT、live 实现和调用方。只有歧义会改变产品语义、数据
   结果、公开承诺、法律 / 发布边界或验收结果时才停下询问；其余采用保守假设，说明后继续。
   项目内行为先读 owning contract 与 live precedent；外部平台 / API 事实先读官方一手资料，
   已验证社区实践只作补充，star 数不是证据。
2. **最小且完整**：在已 shaping 的 outcome、scope 与 appetite 内选择最简单清晰的完整方案；
   不增加未要求功能或投机配置。抽象只在真实多实现、重复变化成本、易变外部边界或已批准
   契约接缝出现时提出；以可读性、边界和验证成本判断，不用行数替代设计判断。
3. **严格控制范围**：每项改动必须追溯到 outcome、根因、验收标准，或为保持编译、测试、
   生成物和契约一致所必需。保护用户与其他 lane 的改动；无关问题记录到独立候选，不顺手清理。
4. **用证据完成**：开工前定义 pass / fail，按 T0-T4 选择验证。oracle 可来自产品 / Release /
   feature spec、数据与安全契约、NFR、平台规范和已批准验收；不能只验证代码自洽。明确区分
   已运行、未运行、失败和外部阻塞；build 成功不能写成 tests 通过。

## 3. 开工与协作

开工先读 `docs/how-to/definition-of-ready.md`，再按
`docs/how-to/parallel-lanes.md` 做 T0：

- 确认目标分支、`origin/develop` HEAD、dirty files、未合并工作与引用的 live path:line；
- 使用独立 worktree / 分支，不修改或清理主 checkout、其他 worktree、stash 或未知文件；
- shaping 明确 outcome、scope、red lines、owner、acceptance、验证等级和 PO / legal / fact gate；
- 共享接缝先用小契约 PR 冻结当前 slice 所需接口，再让文件集不相交的实现并行；
- write WIP 不超过 2；合并永远串行，每次 merge 都需 PO 明确授权。

工具或模型不永久拥有文件。当前默认由 Codex C1 统筹 shaping、本地实证、实现整合与完成报告；
Claude、Gemini / Antigravity、Grok 等默认是独立只读 reviewer，只有 PO 或 shaping 明确分配
独立 write lane 时才能写入。角色、文件集和验证责任以当次 task brief 为准。
当次 task brief 已明确要求某窗口实施并给出 scope / acceptance 时，即完成该窗口的 write
lane 分配；模型默认角色不能反向拒绝已明确的实施任务。
PO 在当次会话中的明确指令可以分配本 slice 的调查 / 实施；它不使新的产品语义跨 lane
effective，也不自动授权 merge、上传或发布。

跨窗口不依赖聊天同步；只通过 commit、PR、report、测试和 tracked docs 交接。外部 Agent
输出只是候选证据，进入仓库前必须由当前 DRI 复核其 path:line、命令和 live 行为。

## 4. 必须询问 PO 的边界

当 current task brief 或 owning effective contract 尚未明确时，只有以下问题必须停下请 PO 裁决；
已经有精确裁决的，不重复询问：

- 产品定位、默认行为、免费 / 付费边界或用户可见语义发生变化；
- 多个合理交互方案会改变信息架构、默认路径、功能语义或用户可感知结果；遵循 owning spec /
  design system 的纯视觉 token 由 owning UI lane 自主选择；
- 法律 / 合规 guardrail 与现有功能冲突；
- 删除或不可逆迁移用户数据，修改账号、签名、发布资源或外部 wire 承诺；
- 把私有仓库内容、用户数据、密钥、签名材料或其他非公开证据发送给外部模型 / 服务；
- 上传 TestFlight、扩大可用人群、go / no-go、App Store 提交或正式发布。

纯工程实现、事实校准、测试补齐和已 effective 方案的落地由 owning lane 自主完成。任何 push、
PR、分支删除或 merge 仍服从 `parallel-lanes.md` 的显式授权规则。

## 5. 项目不变量

- SnapDrill 是 iOS 26+、Swift 6 strict concurrency 的 SwiftUI App。Release 1 的产品范围以
  Product Constitution 与 Release 1 Contract 为准，不从当前代码、旧 ADR 或 Draft PR 反推。
- App 是 composition root。Package 依赖必须朝 Core 收敛；Core 不反向依赖 Feature / UI /
  Data，且保持零第三方依赖。精确 DAG 与当前偏差只在 `docs/explanations/architecture.md` 维护。
- Release 1 是 local-first、无 SnapDrill 账户的单一资料库。数据路径、恢复、备份、删除和
  incident 生命周期服从 Local Library Data Contract 与 Backup Wire Contract。
- 用户图片入库前必须去除 EXIF GPS / 位置信息；持久化图片路径必须在读、写、删边界验证。
  不得通过 UI 绕过数据、恢复或隐私契约。
- 当前生产不使用 Firebase 或后端行为分析。任何遥测、同步、IAP、账号、区域或平台范围重入
  都需要新的产品、数据、隐私和发布 contract。
- accessibilityIdentifier、wire key、schema、迁移、Bundle / Team / App Group 和签名资源
  不是可顺手重命名的文案；变更前读取 owning contract 并通过相应 gate。

## 6. 验证与完成

Canonical local source gate（要求 clean committed checkout）：

```bash
bash Scripts/ci-local.sh
```

精确 Xcode、SwiftLint 和 simulator runtime 只在 `Configs/Toolchain.env` 维护。`swift test`
不适用于本仓库；测试入口、targeted UI / AX、archive、真机和发布证据见
`docs/how-to/release-and-ci.md`。

验证重量服从 `parallel-lanes.md` 的 T0-T4。最低要求：

- T0 文档：`git diff --check`；涉及 docs 时运行
  `python3 Scripts/validate_document_control.py --check` 与
  `python3 Scripts/validate_docs.py --check`；生成索引按 owner generator `--check`。
- 进入编译产物的任何改动至少 T2；用户交互至少 T3；Core / Data / 存储 / 隐私 / wire /
  migration / release 至少 T4。
- canonical gate 不覆盖 app UI / AX、archive、安装、隐私网络实证或发布候选 lineage；高层
  验收不能被较低层绿色替代。

完成报告必须列出：验证等级、实际命令、已验证路径、未运行项、失败 / 阻塞和剩余风险。

## 7. 按需读取

| 任务 | 权威入口 |
|---|---|
| 产品身份、原则、当前发布范围 | `docs/explanations/vision.md` + `docs/reference/release-1-contract.md` |
| 单功能行为与状态 | owning `docs/features/**/feat-*.md` + `docs/reference/feature-status.md` |
| 开工、PO gate、worktree、授权与 T0-T4 | `docs/how-to/definition-of-ready.md` + `docs/how-to/parallel-lanes.md` |
| 架构、依赖、并发、DI | `docs/explanations/architecture.md` |
| 数据、备份、恢复与 wire | `docs/reference/local-library-data-contract.md` + `docs/reference/backup-wire-format.md` |
| API 已知坑点 | `docs/reference/api-pitfalls.md` |
| UI / UX、AX、本地化与术语 | owning feature spec + `docs/explanations/design-principles.md` + `docs/reference/glossary.md` |
| CI、签名、TestFlight 与发布 | `docs/how-to/release-and-ci.md` + `Configs/Toolchain.env` |
| 本地 hooks 与脚本行为 | tracked `Scripts/pre-commit` + `Scripts/hooks/pre-push` + owning script tests |
| 隐私、平台与 NFR | `docs/explanations/privacy-compliance.md` + `docs/reference/apple-platform-limits.md` + `docs/reference/non-functional-requirements.md` |
| 文档角色 / 生命周期、生成状态和意图索引 | `docs/reference/document-control.md` + `docs/README.md` |

私有记忆只是可丢弃缓存。项目 Skill 只封装重复工作流，运行时必须读取 live SSOT；不得复制
产品基线、架构快照、角色品牌或发布状态。Agent 控制面若改变权威、PO gate、数据安全、
验证或 merge / release 边界，必须使用独立 PR 评审，不能在功能补丁中顺手修改。
