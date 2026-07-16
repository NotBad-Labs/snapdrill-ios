# 多 Agent / 多窗口协作边界

> 当前版本：2026-07-16。适用于 Codex Desktop 与经 PO / shaping 授权的 Claude、Gemini /
> Antigravity、Grok 或其他工具。目标是让角色、文件集、证据和授权清楚，不让模型品牌成为
> 永久组织结构。

## 1. 共同真相源

不同问题使用不同裁决链：

- **产品意图**：`develop` 中 effective 的 Product Constitution > 当前 Release Product
  Contract > 产品政策 / typed decision > feature spec > 验收标准。
- **实现事实**：live 代码、测试、构建、设备与发布实证 > 自动生成状态与当前事实文档 >
  历史材料和 Agent 私有记忆。
- **当前执行**：owning 技术或操作 contract 约束边界；task brief 的 outcome / scope / red lines /
  acceptance 在边界内固定本 slice；通用 Agent 启发式只补未规定处。

代码不能覆盖产品意图；规划和聊天不能覆盖 live evidence。任何影响其他 lane 的结论必须进入
commit、PR、report、测试或 tracked docs，不能只留在私有会话。

## 2. 角色而非模型所有权

工具或模型不永久拥有目录、文件或结果。每个阶段由 shaping 在 task brief 中分配以下角色；
同一工具可以在不同阶段承担不同角色，但同一 slice 的写入与独立复核不能由同一会话兼任。

### PO

- 决定产品定位、默认行为、体验取舍、商业与法律风险；
- ratify 产品候选并单独授权 merge、上传、开放 TestFlight、go / no-go 和发布；
- 不负责替 Agent 选择具体实现，只审阅决策点和可验证产物。

### Orchestrator

- 当前默认是 Codex C1，除非 PO 明确更换；
- 负责 T0、DoR、shaping、切分 bounded slices、依赖顺序、本地实证复核、WIP 和完成报告；
- 可以调用外部 Agent，但其输出只是候选证据；
- 不得代理 PO 改产品语义，也不得用协调身份覆盖 owning contract 或 live code。

### Write lane

- **主刀**：当前主 write slice，负责实现、验证、commit 和 handoff；
- **副刀**：仅当 shaping 明确声明文件集不相交、验收可独立时启用；
- task brief 已明确要求某窗口实施并给出 scope / acceptance 时，即完成该窗口的 write lane
  分配；默认模型角色不能反向拒绝；
- PO 在当次会话中的明确指令可以分配本 slice 的调查 / 实施；它不使新的产品语义跨 lane
  effective，也不自动授权 merge、上传或发布；
- 每刀都必须有独立 worktree / 分支、明确 owner、文件集、red lines 和验证方式；
- 共享接缝先拆小契约 PR，冻结当前 slice 需要的接口后再并行。

### Operations

- 负责 push、PR 状态、CI、rerun、授权后串行 merge 和 worktree / 分支卫生；
- 永不写产品代码或在合并时顺手修复；
- 每次 merge 前重新确认授权 head、顺序、状态与 base。

### QA / Reviewer

- 只读 dogfood、审计、盲审、威胁建模和报告；
- 不直接修改代码或文档，不把自身输出称为项目真相；
- 结论必须带 base、scope、path:line / 命令、已验证和未验证项，由 orchestrator 复核。

## 3. 开工 T0 与 DoR

任何 write、跨 Agent 规划、复核或合并前都先做 T0：

1. `git fetch` 后确认目标 `origin/develop` / 授权 head；
2. 记录当前 branch、HEAD、upstream、ahead / behind 和 worktree dirty files；
3. 列出已合并、未合并、被取代和未知来源的工作；
4. 重开规划引用的 live path:line，确认根因与接口仍成立；
5. 把结果写入 task brief、PR 描述或 report，不新增并行状态 SSOT。

任务还必须通过 `definition-of-ready.md`，至少写清：

```text
Outcome:
Scope / owned files:
Out of scope / red lines:
Authority and decision state:
Dependencies / merge order:
Acceptance criteria:
Validation level and commands:
PO / legal / fact gates:
```

缺失产品、数据 / wire、公开承诺、商业或平台上游 contract 时，可以调查或创建 Draft 实验，
但不得把实验反向写成产品事实，也不得合入改变跨 lane baseline 的实现。

## 4. 并行与 worktree

- 同时进行的 write WIP 不超过 2；审计 / reviewer 不计入 write WIP。
- 每个 write lane 使用独立 worktree、分支和 DerivedData；不动主 checkout。
- 不修改、清理或恢复其他 lane 的 worktree、stash、未提交文件和未知 artifact。
- 窗口之间零口头依赖；协作只经 commit、PR、report、测试和 tracked docs。
- 合并永远串行，顺序由 shaping 标注；每次 merge 都需 PO 对精确 head 明确授权。
- 依赖另一个 slice 时，消费者等待契约 commit 合入或明确 rebase 基线，不能猜测未冻结接口。

并行构建沿用 `release-and-ci.md` 的 canonical 参数，并为每个 lane 追加独立 DerivedData：

```bash
xcodebuild <canonical arguments> -derivedDataPath /tmp/snapdrill-derived-<lane>
```

### PO 暂时不在线

- 可继续已明确任务的调查、实现、测试和本地 commit；
- 可准备 Draft PR / handoff，但不能自行改变产品、法律、商业或公开语义；
- 不得自行 merge、上传、扩大 TestFlight 可用人群、提交审核或发布；
- S0 / S1、安全或数据问题可立即分诊并准备独立 hotfix；不可逆处置和对外动作等待 PO。

## 5. 外部 Agent

外部 Agent 默认是只读 reviewer。只有 PO 或 shaping 明确分配 write lane 时才可修改仓库，而且
必须使用独立 worktree、文件集和验收。

调用前：

- 私有仓库内容发给第三方模型 / 服务前，取得 PO 对 vendor 与最小 payload 的明确授权；公开资料
  可按任务事实 gate 使用，但订阅关系本身不构成私有数据外发授权；
- 只准备任务必需的最小、可审计目录；移除密钥、用户数据、签名材料、auth / debug log 和
  无关源码；
- 固定 base、cwd、模型和新会话；
- 关闭记忆、subagent、web、plugin / MCP 和写工具，除非任务明确需要；
- 使用当前 binary `--help` 验证参数，不能照抄过期 CLI 记忆；
- prompt 写明 scope、red lines、证据格式和不确定性处理。

调用后：

- 检查 worktree 没有 reviewer 产生的改动；
- 丢弃错误模型、越界搜索、写入、超时或缺 path:line 的 run；
- orchestrator 逐项复现后，才可把结论写入 finding、代码或 PR；
- raw transcript、debug / auth log 和 brain artifact 留在临时目录并及时删除。

项目级调用示例与当前已验证参数见
`docs/reference/audits/2026-07-repository/agent-invocation-protocol.md`。

## 6. 验证与完成信号

验证重量按风险分级，不按文件数量或 Agent 自信度降级。

| 等级 | 适用改动 | 本地验证 | PR / CI 策略 |
|---|---|---|---|
| T0 | 纯文档、注释、Markdown 指针，不进入编译产物 | `git diff --check`；涉及 docs 跑 `python3 Scripts/validate_document_control.py --check` + `python3 Scripts/validate_docs.py --check`；生成索引跑 owner generator `--check` | 可先开 PR，不要求 iOS build |
| T1 | 开发者可见但不影响编译结果的 Swift 注释、`#Preview` 名称 | scoped 或完整 `swiftlint --strict`；必要时 `git diff --check` | 报告未跑 build 的理由 |
| T2 | 进入编译产物的代码、常量、L10n 值、资源、测试或配置 | `swiftlint --strict` + `AllTests` build-for-testing | 合并前本地或 CI build 绿 |
| T3 | 用户交互、状态、导航、导出 / 打印、权限、错误态、ViewModel 消费 | T2 + targeted test / UI / AX / 手动路径；必要时截图、录屏、真机 | 等对应 CI；列已验与未验路径 |
| T4 | Core / Data / 存储 / 隐私 / 安全 / wire / migration / 签名 / release | T3 + contract / regression / fault injection / 发布专项证据；必要时独立复核 | 等对应 CI 和外部 gate，不靠自述 |

`swiftlint` 不是编译器，`build-for-testing` 不是 tests green，canonical source gate 也不覆盖
UI / AX、archive、安装、网络和发布 lineage。完成报告必须区分验证等级、实际命令、已验证、
未运行、失败、外部阻塞和剩余风险。

## 7. 必须询问 PO

当 current task brief 或 owning effective contract 尚未明确时，以下情况必须停下问 PO；
已经有精确裁决的，不重复询问：

- 改变产品定位、默认行为、免费 / 付费边界或用户可见语义；
- 多个合理交互方案会改变信息架构、默认路径、功能语义或用户可感知结果；遵循 owning spec /
  design system 的纯视觉 token 由 owning UI lane 自主选择；
- 法律 / 合规 guardrail 与现有功能冲突；
- 删除或不可逆迁移用户数据，修改外部 wire、账号、签名或发布资源；
- 把私有仓库内容、用户数据、密钥、签名材料或非公开证据发送给外部模型 / 服务；
- 上传、non-PO availability、go / no-go、提交审核或发布。

纯工程实现、事实校准、测试补齐和 effective 方案的落地由 owning lane 自主完成。

## 8. 提交、授权与分支生命周期

- Agent 不直推 `develop` / `main`；所有写入在独立分支。
- 本地交付至少包含 clean diff、commit hash、验证结果和未覆盖范围。
- push、创建 / 关闭 PR、merge、部署和删分支按当次 PO 授权执行；授权不得从近似标题或旧
  hash 推断。
- 合并后删除分支前确认历史已进入目标分支；关闭未合并分支还需 unique-commit /
  supersession 校验和 PO 授权。
- 不从私有记忆中的旧 hash 复活工作；先 fetch，核对 live Git / GitHub 后再决定恢复。

## 9. Handoff

跨层发现至少记录：

- 问题与用户 / 数据影响；
- 固定 base、复现与 path:line；
- owning layer、所需契约和不可触碰边界；
- 推荐下一刀、依赖顺序和验证方式；
- `FACT` / `JUDGMENT` / `PENDING-PO`；
- 已验证、未验证和外部阻塞。

发现者不自动拥有修复权；orchestrator 负责把问题路由到独立 slice，直到关闭、明确 defer 或
提交 PO 裁决。
