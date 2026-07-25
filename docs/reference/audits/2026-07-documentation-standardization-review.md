# 2026-07 文档标准化独立复核

> **文档状态：固定基线历史证据。** 本文只记录一次只读监督及 C1 的本地复核，不是产品、
> 文档或执行权威；当前入口仍是根 `README.md`。

## 固定输入

- 日期：2026-07-24
- base：`origin/develop@6494d32dbdd9b2becaf019575da59253a8b7c33f`
- reviewed candidate：`a4c4e5f2a7230b640754bb050bf9e1469cd9b91a`
- 最小输入包：1.0 MB，只含文档控制面、生成器 / validator、相关测试和 candidate patch
- 同题 prompt SHA-256：
  `990ba0909d9abe969b35203c0ec74bb11e056439e14bd037f2fbf69ffa60e6ea`
- 输入 manifest SHA-256：
  `b4ab0374fab97e40675869a509d3ab22587907fd90fdeb7a9463c00fe49bd4e4`

两路均使用新会话、固定 cwd、只读 `Read/Grep/Glob`、无 web、无 subagent 和无持久记忆：

| Reviewer | CLI / model | 结果 |
|---|---|---|
| Claude | Claude Code `2.1.217` / `claude-fable-5[1m]` | `ACCEPT-WITH-CHANGES` |
| Grok | Grok CLI `0.2.111` / `grok-4.5`, high | `ACCEPT-WITH-CHANGES` |

raw transcript、debug / auth log 与会话材料未入仓；reviewer 没有仓库写工具。调用合同与已验证
参数由当前 [`external-agent-review.md`](../../how-to/external-agent-review.md)
维护。

## 复核共识

C1 重新打开候选文件后确认：

1. 根 README、Product Vision & Principles、Release 1 PRD 与 Feature Specs 的层级成立，
   stable decision / intent IDs 保留，候选没有改 Swift 代码或产品行为。
2. `definition-of-ready.md` 仍有跨行的旧英文权威名称；旧 validator 只扫描三个入口、skills
   和 Package 文档，无法发现该缺口。
3. 关键事实需要 existing `document-control.md` 中的唯一 tracked owner 规则；外部 reviewer
   输出必须由 DRI 复核后进入 owner，raw transcript 不是事实或权威。
4. 8 个 active feature spec 仍使用“Release 1 合同符合”，应统一为“Release 1 PRD 符合”。
5. `po-decision-log.md` 的一个仓库外 scorecard 与一条 Claude 私有记忆是唯一持有者，违反
   新事实归属规则；前者应转录最小历史回执，后者应路由到现有执行规范。
6. Product Vision 不应把 Team / Bundle / signing 事实归给已精简的根 README；实际 owner
   是 tracked config、Xcode project / entitlements、archive 和 release guide。

## 处置边界

上述六项均为可本地复现的工程 / 文档控制问题，不需要新增产品裁决。修复进入同一
documentation-standardization 分支；validator 只检查可确定的结构、生命周期、旧术语和已知
私有 holder，不尝试用关键字自动判断语义完整性。

本回执只证明两路独立复核及其已复现 finding。最终候选是否可合并，仍取决于修复后的 tracked
门禁、Draft PR 复核和 PO 对精确 head 的单独授权。

## 修复后验证

2026-07-24，C1 在独立 worktree 对上述 finding 完成修复，并运行：

- `python3 -m unittest Scripts.tests.test_validate_docs`：39 项通过；
- `python3 Scripts/validate_document_control.py --check`：通过；
- `python3 Scripts/validate_docs.py --check`：通过，仅保留既有语义 / legal 人工复核提示；
- `bash Scripts/pre-commit`：SwiftLint 280 个文件零违规，生成器 / 文档 / Capture /
  Release 配置门禁通过，35 项生成器测试与 167 项脚本回归测试通过；
- `git diff --check`：通过。

本 slice 没有改 Swift 源码、产品需求、stable decision / intent ID 或用户行为。修复后不再依赖
reviewer raw transcript、私有记忆或仓库外绝对路径重建上述事实。

## Exact-head 精简复核

2026-07-25，C1 对 Draft PR #980 的
`96c88dd531bd3e7f0efe34c82a2fce09a9d7e756` 固定 head 再做一次同题只读监督：

- 输入包约 324 KiB，只含 README、Product Vision & Principles、Release 1 PRD、active
  feature specs、roadmap、文档控制面、validator 与测试；
- prompt SHA-256：
  `c13db80327898287c5a035dca658925260658cf0f92abaa8597ec31cd8054e91`；
- Claude Code `2.1.217` / `claude-fable-5[1m]` 与 Grok CLI `0.2.111` /
  `grok-4.5` high 均使用新会话、固定 cwd、只读工具、无 web、无 subagent 和无持久记忆；
- 两路独立结论均为 `ACCEPT-WITH-CHANGES`。

C1 随后在本地逐条重现并确认：

1. `scope-and-roadmap.md` 重复了 Vision 的耐久边界和 PRD 的当前发布分类，应只保留候选组合、
   重入条件与探索证据；
2. 九个 active feature spec 在 Why / What / How / Verify 之外又增加 Contracts 或 PRD
   H2，形成同一文件内的平行规范面；耐久正文必须保全并分别并入 What 与 Verify；
3. `feat-review.md` 中带日期的 UI slice checklist 是历史执行材料，不应留在 effective spec；
4. `design-principles.md` 不应再逐项复制 Dashboard 的产品要求；
5. Release 1 PRD 的决策摘要必须声明自己只是索引，完整约束仍由 owning 正文拥有；
6. validator 应只判断上述可确定结构，不用 LLM 或关键词推断需求语义。

对应修复全部留在同一 documentation-standardization candidate 中；Feature Spec 原 Contracts
除标题外的正文、表格和精确中英文文案经机械逐行比对均保留。raw reviewer transcript、debug /
auth log 与临时输入包仍不入仓。

修复后本地证据：

- 稳定 decision / vision ID 集合与修复前 head 完全一致；
- `python3 -m unittest Scripts.tests.test_validate_docs`：48 项通过；
- `python3 Scripts/validate_docs.py --check` 与
  `python3 Scripts/validate_document_control.py --check`：通过；
- `bash Scripts/pre-commit`：SwiftLint 280 个文件零违规，35 项生成器测试和 176 项脚本
  回归测试通过，其余文档、Capture 与 Release 配置门禁通过；
- `xcodebuild build-for-testing -scheme AllTests -destination
  'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`：通过；
- `git diff --check`：通过。

本轮仍未修改 Swift 源码、产品需求、stable decision / intent ID、data / wire policy 或用户行为。

## 目标级完成性审计

2026-07-25，C1 以 `1f48987c4f059ba0abebac979879f0ccb9ed5935` 为 candidate parent，
按目标而不是现有 diff 反推逐项证据：

| 目标要求 | 当前证据 | 结论 |
|---|---|---|
| 根 README 是唯一冷启动入口 | 根 `README.md` 明确路由 Vision / PRD / Feature Specs；`docs/README.md` 只作导航，`AGENTS.md` 先路由回根 README | 内容成立；补 fail-closed marker 与竞争声明门禁 |
| 长期方向只有一个 Product Vision & Principles | tracked Markdown 中只有 `docs/product/vision.md` 声明 `layer: product-vision` | 成立 |
| 当前发布需求只有一个 Release 1 PRD | tracked Markdown 中只有 `docs/product/release-1-prd.md` 声明 Release 1 `product_role: release-prd`，且无第二个 PRD 命名文件 | 成立 |
| 单功能行为只有 Feature Spec | 九个 active spec 均只有 Why / What / How / Verify 四个编号 H2；roadmap 与设计原则不复制当前发布要求 | 成立 |
| 文档角色、生命周期与链接受控 | 129 个 tracked Markdown 全部分配唯一 registry rule；critical entry / authority / generated 文件的 role / lifecycle 新增固定断言 | 成立 |
| 追溯与生成状态可重建 | feature-status 与 intent-traceability `--check` 通过；未知、pending、重复、未消费 release ref 和无 owner outcome 均 fail closed | 成立 |
| 需求语义和稳定 ID 不变 | base 与 candidate 的 Vision ID 都是 `P1`–`P6`；31 个 `ratified_decisions` 逐字一致；两轮外部只读监督的保留 finding 均由 C1 本地重现 | 成立 |
| 代码行为不变 | candidate 相对 `origin/develop` 只改 Markdown、文档 registry JSON、validator Python 与测试，没有 Swift 或产品配置差异；本地和 PR `Build & Test` 通过 | 成立 |

门禁扩展后，51 项 `validate_docs` 测试、12 项 `validate_document_control` 测试、35 项生成器测试、
182 项脚本回归测试与 SwiftLint 280 个文件零违规全部通过。

本节不把 candidate 提前声明为 effective。只有包含上述门禁的精确 head 经 CI 绿色、PO 单独授权并
合入 `develop` 后，本次文档标准化目标才满足生效条件。
