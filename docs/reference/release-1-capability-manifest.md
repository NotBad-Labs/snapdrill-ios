---
last_verified: 2026-07-14
layer: release-evidence
release: 1
schema_version: 1
status: pre-freeze
owner: release-operations
authority: release-1-contract.md
---
# Release 1 Capability Manifest

> **当前不是候选构建声明，也不是可直接复制的机器 schema。** 本文件是 [Release 1 Product Contract](release-1-contract.md) 的 schema v1 人类可读 shaping 模板。实际字段语法、稳定 ID、revision event、阶段矩阵和 validator 尚未冻结；首次 freeze 前必须由独立实现 slice 固化并接入门禁。预期冻结件路径仍为 `docs/reference/releases/release-1/manifests/<candidate-id>/manifest-rNN.<structured-format>`；一个 candidate 只对应一个精确 audience / build / capability set，每个 revision 是不可变证据快照。它不能新增产品范围，也不能把 Candidate optional 提升为 Must。

## 冻结规则

1. 本模板保持 `pre-freeze`，不得 `include`、上传或开放任何候选。即使 Release 1 Contract 随本更新合入 `develop` 后 effective，首次 freeze 前仍必须由独立实现 slice 固化并测试 schema v1 validator；validator 不存在或不通过时不得生成冻结件。
2. Release Operations 在某个 commit 被提名时创建 candidate ID，并在上传前冻结 `manifest-r01.<structured-format>`。candidate ID 的最终语法必须在 validator slice 中纳入 capability-set digest；上传回执、ASC processing、安装变体和后续证据各通过新的递增 revision 固化，旧 revision 不得改写。source commit、build、audience 或 capability set 任一变化都创建新 candidate；只增加同一 build 的证据才增加 revision。旧 candidate 的证据只可逐项引用，不能自动继承绿色结论。
3. audience 只能是 `po-only`、`research` 或 `public-candidate`。`included` 只能用于 effective Release Contract 允许的 Candidate optional / experiment，并且该能力通过对应 audience 的数据、隐私、AX、S0 / S1 和受影响测试门禁。
4. `hidden` 表示该 build 对能力零入口、零激活、零副作用：除无 Tab / 页面入口 / 通知 / deep link / App Intent / Shortcut / Spotlight / widget / 状态恢复 / AX / 元数据外，启动、后台、升级和遗留调度也不执行、写状态或产生网络 / 文件 / 数据副作用。不可达且不执行的代码可以保留；fresh install 与 existing-data upgrade 均须有负向证据。
5. PO 上传授权、non-PO availability 授权、公开 go / no-go 与发布授权分别记录；未取得对应阶段授权的 manifest 不授权该动作。若未经授权却已实际向非 PO 开放，必须如实记录并按 DATA-1 触发 epoch。
6. manifest 只能缩小候选能力，不能覆盖 Must、非目标、C3 或 DATA-1。要扩大范围必须先修改上游 contract。

## 候选标识

| 字段 | 当前值 |
|---|---|
| Manifest Schema | 1 |
| Candidate ID | — |
| Manifest Revision | r00-template |
| Audience | — |
| Distribution Channel | — |
| Source Commit | — |
| Evidence Index Commit | — |
| Marketing Version | — |
| Build | — |
| App Store Connect Build ID | — |
| Local Archive SHA-256 | — |
| Upload Receipt / Processing ID | — |
| Installed Variant Identity | — |
| Distribution ACL Snapshot | — |
| Backup Schema | — |
| DATA-1 epoch | pre-epoch |
| Non-PO available at | — |
| Freeze 状态 | pre-freeze |
| PO upload 授权（引用 + 时间） | 未授权 |
| PO non-PO availability 授权（引用 + 时间） | 未授权 |
| PO public go / no-go（引用 + 时间） | 不适用 / 未授权 |
| PO release 授权（引用 + 时间） | 不适用 / 未授权 |

## 能力处置

| 能力 | 当前候选处置 | 纳入前置 |
|---|---|---|
| 手动录入 | hidden | 冻结时显式 include + targeted / AX |
| 剪贴板录入 | hidden | 冻结时显式 include + 隐私 / targeted / AX |
| Share Extension | hidden | 冻结时显式 include + App Group / GPS / targeted / AX |
| JSON / CSV 导出 | hidden | 冻结时显式 include + 字段 / 注入 / 隐私测试 |
| 自定义字段 / 动态维度管理 | hidden | 冻结时显式 include + 数据完整性 / targeted / AX |
| 批量打标签 / 批量删除 | hidden | 冻结时显式 include + 部分失败摘要 / targeted / AX |
| 去答案 / 留白 / 页眉页码 / 单条快速打印 | hidden | 冻结时显式 include + PDF fidelity / 打印测试 |
| ShareCard | hidden | 上游 contract 当前默认为 hidden，不可由本 manifest 单独 include |
| CSV 导入 | hidden | C2-Optional 下为 optional；GAP-R6 修复及对应门禁完成前不可 include |
| Review | hidden | C4-D 只允许 `po-only` / `research` 冻结件显式 include；`public-candidate` 必须 hidden |
| SmartPaper | hidden | C5-E / C5-S1 只允许 `po-only` / `research` 冻结件显式 include；可见即无 quota / Pro，`public-candidate` 必须 hidden |

Must 与明确 out-of-scope 能力不在本表重复；它们分别由 Release Contract §3 和 §7 直接约束。

## 证据索引

冻结件为 M1-M10、每个 `included` capability、每个 hidden 负向证明和每项授权各保留一行：

| Contract / capability | Outcome / negative oracle | Test / dogfood record | Attachment / ACL snapshot | Status |
|---|---|---|---|---|
| — | — | — | — | pending |
