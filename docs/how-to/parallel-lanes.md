# 多 Agent / 多窗口协作边界

> 当前版本：2026-07-23。适用于 Codex Desktop 与经 PO / shaping 授权的 Claude、Gemini /
> Antigravity、Grok 或其他工具。目标是让角色、文件集、证据和授权清楚，不让模型品牌成为
> 永久组织结构。

## 1. 共同真相源

规范链、实证链与当前执行优先级只在 `AGENTS.md` §1 维护。本文件不复制产品 SSOT。
任何影响其他 lane 的结论必须进入 commit、PR、report、测试或 tracked docs，不能只留在
私有会话。

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
- 当前已接受 bet 内、通过 DoR 的 P-A Green 任务可由 owning agent 自主推进至 Draft PR，
  不需要逐 slice 重新申请 branch、commit、push 或 Draft PR 操作授权；
- 每刀都必须有独立 worktree / 分支、明确 owner、文件集、red lines 和验证方式；
- 共享接缝先拆小契约 PR，冻结当前 slice 需要的接口后再并行。

### Operations

- 负责 Green 任务的 push、Draft PR、CI、rerun，以及授权后串行 merge 和 worktree / 分支卫生；
- 永不写产品代码或在合并时顺手修复；
- 每次 merge 前重新确认授权 head、顺序、状态与 base。
- 长时间 CI 在后台观察；常规轮询不打扰 PO，只在需要裁决、失败或最终完成时报告。

### QA / Reviewer

- 只读 dogfood、审计、盲审、威胁建模和报告；
- 不直接修改代码或文档，不把自身输出称为项目真相；
- 结论必须带 base、scope、path:line / 命令、已验证和未验证项，由 orchestrator 复核。

## 3. 开工 T0 与 DoR

任何 write、跨 Agent 规划、复核或合并前都先做与风险相称的 T0。

日常 Green 任务使用轻量 T0：

1. `git fetch` 后确认目标 base / 授权候选；
2. 确认当前 HEAD、worktree、dirty files 和 active write 没有冲突；
3. 重开 owning authority 与当前 live evidence，确认 outcome、scope 和验收仍成立。

Yellow / Red、T4、恢复历史任务、跨 lane、外部复核、事故与发布工作再展开：记录 upstream、
ahead / behind、已合并 / 未合并 / superseded 工作、继承假设、依赖和 merge order。merge T0
始终重新确认 PR 当前精确 head、base、mergeability、必需门禁与授权绑定。

T0 是当前实证刷新，不会让历史工作项自动恢复执行权。issue、PR、审计、报告、聊天交接、
label、历史评论 / 授权和旧 CI 默认只作证据；编号、时间、open / closed、Draft / Ready 或
绿色状态不能单独准入。任务进入 bet 或 write lane 前，必须通过
[`Current Admission`](definition-of-ready.md#current-admission)。Green 使用其五字段短 brief；
只有该门定义的风险触发项才使用 expanded admission。T0 结果写入 brief、PR 或 report，不能
新增并行状态 SSOT。

缺失产品、数据 / wire、公开承诺、商业或平台上游 contract 时，可以调查或创建 Draft 实验，
但不得把实验反向写成产品事实，也不得合入改变跨 lane baseline 的实现。

## 4. 并行与 worktree

- active write WIP 不超过 2；冻结待合并队列不超过 2；审计 / reviewer 不计入 write WIP。
- 每个 write lane 使用独立 worktree、分支和 DerivedData；不动主 checkout。
- 不修改、清理或恢复其他 lane 的 worktree、stash、未提交文件和未知 artifact。
- 窗口之间零口头依赖；协作只经 commit、PR、report、测试和 tracked docs。
- 合并永远串行，顺序由 shaping 标注；每次 merge 都需 PO 对当次已展示候选明确授权，工具
  必须绑定候选的精确 head。
- 依赖另一个 slice 时，消费者等待契约 commit 合入或明确 rebase 基线，不能猜测未冻结接口。

### 内部 WIP 状态

write slice 的状态必须写入 PR 描述或 handoff；GitHub 的 Draft / Ready 标签本身不决定 WIP
归类，也不构成合并授权。以下术语用于 Agent 调度；PO-facing 更新只显示 **自动处理中**、
**需要 PO 裁决** 或 **等待合并授权**。

- **active write**：已通过 Current Admission，且 head 仍可能变化，或实现、必需验证、冲突处理、
  必需复核仍未完成；总数不超过 2。
- **frozen merge queue**：head / scope 已冻结，worktree clean，必需门禁和复核完成，无未决
  finding、冲突或上游 gate，只剩 PO 授权或串行 merge slot；不计入 active write，总数不超过 2。
- frozen slice 一旦新增 commit、需要解决冲突、必需门禁失败或出现未解决评审 finding，必须先退回
  active write，再继续修改。
- base 前进但 head 不变时，Operations 重新做 T0、mergeability 与所需验证判断；无需修改且门禁仍
  充分时可保持 frozen，需要改动或补救时退回 active。
- 已 merged、closed 或明确 superseded 的 branch 不计入两类 WIP，但仍按 §8 做分支生命周期处置。

该内部状态只控制并行上限，不需要 PO 学习或维护；它不改变单一主 bet、文件集不相交准入、
串行合并或逐次 PO merge 授权。

并行构建沿用 `release-and-ci.md` 的 canonical 参数，并为每个 lane 追加独立 DerivedData：

```bash
xcodebuild <canonical arguments> -derivedDataPath /tmp/snapdrill-derived-<lane>
```

### PO 暂时不在线

- 可继续已明确 Green 任务的调查、实现、测试、commit、push、Draft PR 和 CI rerun；
- 可准备 Yellow / Red handoff，但不能自行改变产品、法律、商业或公开语义；
- 不得自行转 Ready、merge、删除未合并分支、上传、扩大 TestFlight 可用人群、提交审核或发布；
- S0 / S1、安全或数据问题可立即分诊并准备独立 hotfix；不可逆处置和对外动作等待 PO。

## 5. 外部 Agent

Green 日常任务默认不调用外部 Agent。只在 PO 明确要求、T4 / 发布 / 事故需要独立复核、事实
存在争议、需要外部平台 / 法律专长或当前 reviewer 不能独立验证时调用。调用后默认角色是只读
reviewer；只有 PO 或 shaping 明确分配 write lane 时才可修改仓库，而且必须使用独立 worktree、
文件集和验收。

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
`external-agent-review.md`。

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

唯一清单见 `definition-of-ready.md` 的 [Stop And Ask](definition-of-ready.md#stop-and-ask)。
本文件不复制 PO 权限边界。纯工程实现、事实校准、测试补齐和 effective 方案的落地由 owning
lane 自主完成。

## 8. 提交、授权与分支生命周期

- Agent 不直推 `develop` / `main`；所有写入在独立分支。
- 本地交付至少包含 clean diff、commit hash、验证结果和未覆盖范围。
- Green 任务可自主 push 并创建 / 更新 Draft PR；转 Ready、关闭 PR、merge、部署和删除
  未合并分支按当次 PO 授权执行。Orchestrator 应向 PO 展示自然语言候选与 PR，并在技术元数据
  中记录精确 head；PO 无需抄写 40 位 SHA，可以授权“上述候选”。执行时必须使用当前展示的
  `expected_head_sha`，head 移动即视为原授权失效，重新展示后再请求授权。
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
