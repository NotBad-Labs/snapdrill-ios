---
name: snapdrill-release-readiness
description: SnapDrill 发布就绪检查的薄执行层。当用户要求"发版前检查"、"发布就绪"、"release readiness"、"能不能发版"、"TestFlight 前检查"、"隐私一致性核对"、"跑一遍发版检查清单"、"发布前验证"时触发。执行工程门禁验证、隐私技术事实核对与发布就绪状态汇总，输出五态结果（通过/失败/未验证/外部阻塞/需要 PO 裁决）。只检查与报告，不执行 push、merge、TestFlight 上传、提交审核或发布。法律充分性与政策措辞问题不在本 skill 范围（路由 notbad-legal-counsel / Antigravity / PO）。
---

# SnapDrill 发布就绪检查（薄执行层）

## 唯一事实源

`docs/how-to/release-and-ci.md` 是发布流程、发版检查清单、监控与责任分工的唯一事实源。本 skill 只是它的执行层，不是第二份发布文档：

1. **每次运行的第一步**：完整读取 live checkout 的 `docs/how-to/release-and-ci.md`（含其中的发版检查清单与文档健康检查），以当次读取的内容为准执行。
2. 本文件**不记载任何易变事实**：版本号、Build 号、Team ID、Bundle ID、依赖清单、服务数量、检查清单条目、当前发布状态，一律以当次读取的文档与 live 代码实证为准。
3. 冲突裁决优先级（高 → 低）：**PO 最新明确决策 > live 代码、构建与运行实证 > `README.md` / `AGENTS.md` / `docs/how-to/parallel-lanes.md` > `release-and-ci.md` > 本 skill / 私有 Memory**。`release-and-ci.md` 是发布流程与检查清单**内容**的事实源（查流程读它），但在冲突裁决中**不得覆盖 AGENTS.md 的工程铁律**。发现任何冲突：按上述优先级执行，并在报告中提出修正低位文档或本 skill。

## 执行流程

### 第 0 步：对齐基线

- 读 `docs/how-to/release-and-ci.md` 全文。
- 读 `AGENTS.md` §构建命令 与 §改代码后的 DoD（用于命令比对；冲突按 §唯一事实源 的优先级裁决——AGENTS.md 工程铁律高于 release-and-ci.md）。
- 记录 git 基线：HEAD、当前分支、与 `origin/develop` 的 ahead/behind、工作树是否 clean。
- 从 `Configs/Shared.xcconfig` 读取当前 `MARKETING_VERSION` 与 `CURRENT_PROJECT_VERSION`，只读取上报；目标版本号是否正确递增属于"需要 PO 裁决"，除非 PO 已在本次会话给出目标。

### 第 1 步：工程门禁（本地可实证）

下列命令是 `AGENTS.md` DoD 的转录；与当次读取的文档不一致时按 §唯一事实源 的优先级裁决，并在报告中提出修正本文件：

```bash
swiftlint --strict
xcodebuild build-for-testing -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests
```

环境允许时继续跑单测——具体命令以当次读取的 `release-and-ci.md` §CI/CD（build job 的 `test-without-building` 步骤）为准，不在本文件转录。

另跑文档/状态校验：

```bash
python3 Scripts/generate_feature_status.py --check
git diff --check
```

任一失败即整体"失败"并立即如实上报；修复属于另一项工作（见边界节），不带病汇总。

### 第 2 步：隐私技术事实核对（live 实证，不凭记忆）

逐项采集 live 事实，与当次读取的文档/ADR 中的声明比对；**期望值来自文档，实际值来自代码，本文件两边都不预设**：

- **依赖清点**：全仓 `find . -name Package.resolved`（workspace 级 + 各 package 级，路径不预设）+ 各 `Package.swift` 的实际第三方依赖 → 与设置页开源许可列表、Privacy Manifest、App Store 隐私标签依据是否一致。
- **网络出口**：grep 全仓网络 API 使用（`URLSession`、`Network`、第三方网络封装）→ 与文档声明的采集/上报口径是否一致；新增未声明出口按"失败"处理。
- **分析注入**：Release 构建实际注入的 AnalyticsService 实现（看 Composition Root 实际装配代码）→ 与文档声明一致。
- **Entitlements**：主 App 与 Share Extension 的 entitlements 实际内容（iCloud/CloudKit/App Group/Push 等）→ 与文档声明的签名与能力基线一致。
- **Privacy Manifest**：`SnapDrill/PrivacyInfo.xcprivacy` 声明的收集类目与 Required Reason API → 与实际代码行为一致。
- **EXIF 剥离**：图片入库链路确实经过 `ImageStorage` 的位置信息剥离，无绕过路径。

发现声明与代码行为不一致：**一律先阻止发布**，再按性质分流——

- **纯技术事实类**（依赖清单漂移、Privacy Manifest 与实际 API 使用不符、陈旧工程文档、声明落后于代码的事实错误）：Claude 作为隐私技术事实 DRI **自主修正或提出工程修复**，按 `parallel-lanes.md` worktree 纪律另行进行，不在本次检查运行内改；报告中记录修复项与去向。
- **产品语义 / 法律风险取舍 / 公开政策策略类**（是否对外声明某数据流、政策口径的取向、披露策略）：标"需要 PO 裁决"。

### 第 3 步：清单分诊

把当次读取的发版检查清单逐项归类：

- **本地可验证**：立即执行并记录证据；无法执行的标"未验证"并写明原因。
- **需真机/人工操作**：标"未验证"，写明执行人与所需环境。
- **归属其他 lane 或 PO**：标"外部阻塞"，写明等待谁、等待什么。归属判定按当次读取的 `release-and-ci.md` §发布就绪责任 与 `docs/how-to/parallel-lanes.md` §3，本文件不转录分工表。

### 第 4 步：汇总报告

报告在会话内输出（不落盘新文档），每项附证据（命令输出、`file:line`、文档条目原文），并区分"实际运行过"与"推断"：

| 状态 | 含义 |
|---|---|
| 通过 | 本次实际执行且有证据 |
| 失败 | 本次实际执行且不满足，附失败输出与影响 |
| 未验证 | 本次未执行（写明原因与执行条件），不得冒充通过 |
| 外部阻塞 | 等待 Codex / Antigravity / 外部系统，写明等待对象 |
| 需要 PO 裁决 | 产品语义、风险取舍、版本目标、声明 vs 代码的取向 |

结尾固定给出单行总结论：**当前是否发布就绪 + 最短阻塞路径**。

## 边界（硬约束）

- 本 skill 只做检查与报告。修复检查发现的问题是另一项工作，按 `docs/how-to/parallel-lanes.md` 的 worktree 纪律另行进行。
- 禁止执行：push、merge、创建 PR、TestFlight 上传、App Store 提交审核、发布、改版本号、改隐私声明。
- 真机产品验收与发布 go/no-go 永远归 PO；本 skill 的产出是供 PO 决策的就绪状态汇总。
- 本 skill 不是运维或事故响应 skill。线上技术事故按 `release-and-ci.md` §技术事故与紧急修复处理；是否建立独立 incident-triage skill，待出现真实用户与重复事故流程后再评估。
- 不新增与 `docs/` 重复的说明文档；发布流程的任何改进直接改 `release-and-ci.md`，不写进本文件。
