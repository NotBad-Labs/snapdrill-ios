# SnapDrill · 工程约定（greenfield candidate）

> 状态：本分支上的工程约定，未 effective
> 阶段 0 以 `Docs/PRODUCT.md` 为唯一产品输入。不从旧仓库回补需求

---

## 1. 链路与准出

| 阶段 | 准出条件 | 说明 |
| --- | --- | --- |
| **0 产品定义** | 书面确认 `PRODUCT.md` | 不写代码。产出是愿景、立项、Release 1 结果、设备矩阵、受众和发版顺序。确认前不进入阶段 1 |
| **1 需求与验收** | 第一份产物是「采集 → 保存」的单功能说明，含 Why / What / How / Verify | 只落实 `PRODUCT.md` 已有结果，不新增用户可见能力。11 条总验收已在 `ACCEPTANCE.md`，本阶段不重写那张表 |
| **2 设计与契约** | 数据契约、隐私契约、发布证据各自有唯一 owner 文件，且备份格式已冻结 | 依赖朝 Core 收敛，Core 零第三方依赖。未指定 owner 的契约不能进入实现 |
| **3 实现与验证** | source gate + 分层验证通过 | 独立分支，改动可回滚 |
| **4 集成候选** | 每个 build 独立证据包 | 签名、隐私、安装、ASC 事实逐 build 重收，证据不跨 build 继承 |
| **5 提审与发布后** | go / no-go | 分阶段放量、崩溃监控、迁移与恢复 |

## 2. 验证分层（保留，这是 iOS 的硬约束）

| 层 | 内容 | 不能证明 |
| --- | --- | --- |
| T0 | lint、脚本与文档门禁、依赖方向检查 | 任何运行行为 |
| T1 | build-for-testing + test-without-building | UI 与无障碍 |
| T2 | XCUITest、VoiceOver、动态字体、模拟器与真机矩阵 | archive 与隐私 |
| T3 | archive、签名、安装、隐私与网络实证 | 发布 lineage |
| T4 | TestFlight 上传、ASC 事实、逐 build 重验 | 需 PO 单独授权 |

**低层绿灯不能替代高层验收。** 完成报告固定写明：验证等级、实际命令、已验证路径、未运行项、失败/阻塞、剩余风险。

## 3. 三条硬规则（旧体系里值得留下的）

1. 产品契约定义「应该是什么」，代码/测试/构建只证明「现在是什么」；两者不一致时记录偏差，**不用实现反向改需求**。
2. 分层验证不可跳级；build 成功不等于测试通过，更不等于验收通过。
3. **不可逆动作逐次单独确认**：merge、改数据 wire、删除历史、force push、上传 TestFlight、App Store 发布、go/no-go。

## 4. 明确简化掉的旧包袱

- 五态决策生命周期、30 项裁决台账、Gate B/C/P 编号、ratify 决策 ID
- Current Admission 五字段 brief、frozen merge queue、WIP ≤ 2、exact-head 逐头授权
- 106 份 docs 分层、`document-control.json` registry、生成索引与三套文档门禁脚本
- 多 agent lane 分工、cross-audit、docaudit、反哺协议、`agent:codex` 之类的标签体系
- 历史审计目录与固定基线证据的持续维护

## 5. 环境事实（当前，决定了什么能做）

| 项 | 现状 |
| --- | --- |
| Windows 工作机 | 2026-11-04 记录：无 `xcodebuild` / `swift` / `swiftlint` / `fastlane`，不能在那台机器编译 |
| Mac 工作机 | 2026-11-04 可见 Xcode 27.1。本分支没有工程文件，所以这里也不能跑验收 |
| CI runner | `mac-mini`（`self-hosted` / `macOS` / `ARM64`）于 2026-11-05 核查为 **online**，`busy=false`。本分支没有代码和 CI，上线不等于用例已执行 |
| 工具链针 | 旧仓库 `develop` 的快照仍是 Xcode 26.6。该针不是本分支的产品决定 |

阶段 3 之后的验证要使用在线的 macOS runner。runner 在线只说明机器可达，不说明本分支已经有可运行的工程。

## 6. 最小目录骨架（待 PO 确认后再落地）

```text
App/                     # composition root
Packages/Core/           # 零第三方依赖
Packages/Data/
Packages/Features/
Packages/UI/
Tests/
Docs/                    # PRODUCT.md、ACCEPTANCE.md、ENGINEERING.md、CUTOVER.md
CI/
```

## 7. 不做的工程动作

- 因整洁偏好删除能跑的代码
- 让当前实现或旧测试 oracle 反向定义产品范围
- 把聊天、agent 私有记忆、仓库外报告写成关键事实的唯一持有者

---

*本分支的工程约定。阶段 0 未书面确认，未 effective。*
