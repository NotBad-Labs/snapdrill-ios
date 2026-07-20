---
last_verified: 2026-07-20
layer: evidence
lifecycle: current
base_sha: 4fb6eecc4e1b4c3b0b78e5fe17fc38feabfe93ba
gate: P
tracking_issue: 956
---
# Release 1 Contract 完整性审计

> 本文是 Gate P 的当前实证，不是第四层产品 SSOT，也不修改任何产品要求。产品规范仍按
> Product Constitution -> Release 1 Product Contract -> owning feature spec 裁决。
> 结论固定于 `develop@4fb6eecc4e1b4c3b0b78e5fe17fc38feabfe93ba`；后续实现、测试或权威
> 文档变化后必须重新核验。

## 1. 结论

Release 1 的核心产品方向和 M1-M10 已经写清，现有 Release 1 Product Contract 可以继续承担
唯一 PRD；**Gate P 的产品定义 / PRD 完整性子门通过**。当前不足不是需要再写一份 PRD，而是
Gate P 的下游追溯、实现收敛和实证尚未闭合：

1. `intent-traceability.md` 只能证明 feature 引用了某个 ratified decision，不能证明每个
   M1-M10 都有 owner、结果 oracle 或可执行证据。
2. 现有 Release evidence plan 已定义每个 Must 的最低 oracle，但没有 candidate-bound 的
   M1-M10 -> test / dogfood / attachment 索引。
3. M5、M6、M8、M10 和 public UI 的当前 source / success-path tests 与 effective contract 直接
   冲突；M6 的 split-generation 草稿写入已经达到 S0，M8 的假空库达到 P1。M7 的当前 writer /
   reader 尚未实现 v3。全绿 CI 不能证明 Release 1 合同符合。
4. 若干 current/effective 文档仍混合规范、当前实现和历史目标；其中草稿自动过期、法律口径、
   用户旅程中的新增要求和 App Store 类别需要 PO、legal 或 ASO 裁决。

因此 Gate P 的 PRD 子门已经通过，但 Gate P **整体退出条件尚未完成**，当前 build 也不是可提名的
Release 1 public candidate。该判断不否定已有单测、CI 和安全修复的价值；它只拒绝把产品定义
充分性、组件级绿色和 public candidate 符合性混为同一结论。

## 2. 证据层级

| 层级 | 当前 owner | 本次判断 |
|---|---|---|
| Release 1 产品定义 | `docs/reference/release-1-contract.md` | M1-M10、范围、非目标和发布政策清楚；继续作为唯一 PRD |
| 单功能产品行为 | `docs/features/active/feat-*.md` | 多数 feature 有 GWT，但 outcome edge、owner 和 test ID 不完整 |
| 跨功能结果 oracle | `docs/how-to/release-and-ci.md` §M1-M10 | 最低 oracle 已定义；属于 evidence plan，不扩大产品范围 |
| 自动追溯 | `docs/reference/intent-traceability.md` | 只证明 decision consumer edge；明确不证明 M1-M10 证据 |
| 候选实证 | Capability Manifest + candidate evidence index | 尚未冻结；M1-M10 evidence 行仍为空 |
| 当前代码和测试 | source、AllTests、UITests、真机 / 发布实证 | 证明当前实现；不能覆盖上游产品合同 |

## 3. M1-M10 完整性矩阵

“产品 oracle”表示上游已说明如何判断用户结果；“可执行实证”表示当前仓库或设备证据是否足以
证明该结果。`部分` 不等于失败，只表示不能用于 public go / no-go。

| Must | 产品 owner / 最低 oracle | 当前可执行实证 | 主要缺口 | P-A |
|---|---|---|---|---|
| M1 | Contract `:88`；release plan `:311` | Onboarding 截图；hidden manual entry 的保存 E2E | 无 clean install -> Must 输入 -> save；Onboarding / Profile / Settings 缺精确 M1 edge | Green |
| M2 | Capture；plan `:312` | OCR、图片保存、方向 normalization、GPS 剥离组件测试 | 无相机 / 文扫 / 相册 / PDF 分别保存读回；无中英文 OCR + 人工修正结果级闭环 | Green |
| M3 | Capture；plan `:313` | 相机拒权 alert；OCR failure 进入可编辑 route | 无首次 / 既有拒权、各输入取消后的替代保存闭环及残留 UI 检查 | Green |
| M4 | Library / Data；plan `:314` | 搜索、过滤、编辑和 soft-delete 列表更新 | 无持久化五秒绝对期限、后台 / 重启、期限内 undo、期限后 hard-delete-once oracle | Green |
| M5 | Export；plan `:315` | PDF 与 print presenter 组件测试 | 现有测试反向要求标题页、接受空选择 / 空白资料；无精确页数、真实 AirPrint 和外部副本 / 临时文件结果 | Green |
| M6 | Capture / Data；plan `:316` | 草稿 round-trip；OCR 前持久化图片 | **S0 当前违约**：图片与 UserDefaults 元数据分两步原地改写，失败可销毁旧图、混合新旧 generation 或发布假草稿；生产调用方仍分裂在静态单例与注入实例。无五条 Must 图片通道、正式保存 settlement、终止 / 重启 fault oracle；七天静默删除另待 P1 裁决 | Green repair + Red retention policy |
| M7 | Data / Security；plan `:317` | Profile ZIP v2 round-trip、hostile ZIP 与 size tests | 当前 writer / reader 仍为 Profile ZIP v2；正式 v3 DDL 未批准 / 未实现；无 Profile-free v3、closed generation、barrier、snapshot detach 和 partial-export oracle | Red |
| M8 | Data / QA；plan `:318` | 损坏 store 隔离 / 保留；本次进程展示裁决页 | **P1 当前违约**：隔离后立即发布新空 store，恢复事件只在内存；终止重启会把空 store 当健康库且不再展示裁决。无从备份恢复、rollback / 双失败完整矩阵 | Green |
| M9 | Privacy / Security / Release；plan `:319` | App-managed JPEG GPS 剥离；TelemetryGate 组件测试 | 无 candidate 静态对账、禁网 Must 旅程、受控联网与 Share Extension / backup GPS 实证 | Green |
| M10 | UI / AX / QA / Release；plan `:320` | 单设备 AX audit、部分 XXXL 截图、平台 source validator | 无双语 / 三 viewport / Dynamic Type / VoiceOver 旅程矩阵；source 仍允许 landscape；无 archive / runtime / ASC 证据 | Green |

### 3.1 已复核的反向 oracle 与直接冲突

- **M6（S0）**：`CaptureDraftService.swift:63-93` 先原地覆盖 / 删除旧 JPEG，再单独写
  UserDefaults 元数据；图片压缩或写入失败仍继续发布元数据并记录成功。`:118-137` 又把缺失 /
  无法解码的图片降为 `nil` 草稿，无法区分合法纯文字与损坏 generation。
  `CaptureViewModel.swift:95`、`CaptureResultViewModel.swift:141` 与 Dashboard 默认值仍回退
  `CaptureDraftService.shared`，而 composition 另建 `services.captureDraft`，因此不存在唯一
  production authority。#953 已将 Profile-free root 与 durable publisher 合入 develop，#888
  的最后一个工程前置已满足；它是下一个写槽的 S0 修复，不等待 #889。
- **M5**：`PDFExportServiceTests.swift:53-54` 要求空选择仍生成“标题页”；
  `:69-70` 按“标题页”估算分页；`:85-93` 接受无文字且图片不可读的资料。这与
  Contract `:92` 和 release plan `:315` 的“无封面、空选择渲染前失败、每条资料可读”相反。
- **M7**：当前 writer / reader 与 `SettingsViewModelTests.swift:171-189` 仍把多 Profile ZIP v2
  当成功路径，不能充当 Profile-free `.snapdrillbackup` v3 的 Release oracle。
  `BackupDTOTests.swift:20-28,162-178` 的 v2 golden fixture 本身应继续保留，供 epoch 前格式识别、
  明确拒绝和历史解释；问题不是 fixture 存在，而是当前实现尚未进入 v3。
- **M8（P1）**：`DataExecutor.swift:74-82,158-175` 在损坏 store 两次打开失败后移动原材料，
  随即在原路径创建并发布新空 store；`storeRecoveryEvent` 只存在于本次 executor 内存。
  进程终止后该空 store 会作为健康库打开，不再产生事件或阻塞裁决。这直接违反 Local Data
  Contract `:127-129` 的“非 first launch 不得自动发布新空库”和 M8 的终止重启裁决要求。
- **M10**：`project.pbxproj:1038,1075` 的 Debug / Release iPhone orientations 仍包含
  landscape；`validate_release_configuration.py:19-23` 未检查 ORI-A，因此 source validator
  会对不合规配置返回绿色。
- **UI 范围**：`AppRootView.swift:59-78` 当前直接呈现五个主 Tab 和 Review；
  `SettingsView.swift:81-96` 当前直接呈现 Profile 编辑 / 切换；`LibraryView.swift:127-131`
  当前直接呈现 SmartPaper。对应 `SnapDrillUITests.swift:233,782,1311` 起的 freeze tests
  不是规范 oracle，却是 live build 违反 public / hidden manifest 边界的有效负向实证。

## 4. 控制面与派生文档

| ID | 事实 | 影响 | 分类 / 下一步 |
|---|---|---|---|
| GP-01 | `generate_intent_traceability.py:324-341` 只检查 decision ref 是否被消费；生成页 `:493-495` 明示不证明 M1-M10 | C2-Core 有任一 consumer 即可过门禁，无法发现 M8 / M10 无结果 owner | **Green**：增加独立 outcome traceability，不把测试绿色伪装成 evidence complete |
| GP-02 | Capability Manifest 仍为 `pre-freeze`，evidence index 为空 | 所有现有测试都未绑定 candidate、audience、source/build identity | **Green**：冻结候选时生成 M1-M10 evidence index；冻结前保持未提名 |
| GP-03 | `architecture.md` 开头称只描述当前代码，后文仍把 Multi-Profile、后台立即提交删除和 superseded UI 文档写成设计规则 | Agent 可能按旧架构继续扩展已退休目标 | **Green**：改成当前偏差 / 退场风险，并指向 owning effective contract |
| GP-04 | `glossary.md` 同时承担术语、taxonomy contract、optional 范围和 current code mapping | 术语表可能越权新增功能范围或数据边界 | **Green**：只保留标准词义与 owner 指针；范围 / 数据值回归 owning contract |
| GP-05 | NFR、Local Data Contract、Backup Wire 重复规定增量 BLOB I/O 等实现机制 | 多 owner 漂移，修改一处可能产生冲突 | **Yellow**：先裁决跨 NFR / Data / Wire / Architecture 的 owner 边界，再机械对齐 |
| GP-06 | Registry 将 Constitution、feature、architecture、privacy、glossary、NFR、Data Contract 全部放在同一 `authority/effective` 桶 | 机器能识别角色，却不能识别 authority tier、domain 或 upstream | **Yellow**：先批准最小 authority tier / domain / upstream 模型，再扩展 validator |

## 5. 需要裁决的卡片

下列内容不是 Agent 可自行清理的 Green drift。它们在裁决并进入 owning authority 前，不驱动实现。

### P1：未保存草稿保留期

- **事实**：M6 只承诺中断后可恢复或明确丢弃；NFR 与 Capture spec 另写“仅一份、7 天自动清理”。
- **A（推荐）**：Release 1 不按时间自动删除未保存草稿；只在成功正式保存或用户明确丢弃后删除。
- **B**：保留 7 天过期，但把期限、提醒和删除语义提升为明确产品 / Data / Privacy contract。
- **影响**：A 最贴合当前 M6 且避免静默内容消失；B 需要新的用户可见语义和时间故障测试。

### P2：`user-journeys.md` 中的新增要求

- **事实**：该文件登记为 current evidence，却规定 `<30 秒`、自动框选、连续录入、一图多项、
  元数据沿用和“不做回收站”等行为，且未直接声明 derived from Release Contract。
- **A（推荐）**：旅程只做说明 / 验证场景；未被 Contract 或 feature spec 接纳的数字与行为降为
  假设，不作为 Release requirement。
- **B**：逐项 shaping 并将批准项写入 owning feature spec，再由旅程引用。
- **影响**：A 不扩大 Release 1；B 会增加范围和测试义务。

### P3：隐私 / 合规文档状态

- **事实**：`privacy-compliance.md` 仍是 `last_verified: 2026-05-25`，正文要求法律复核，却在
  registry 中是 effective authority，并包含年龄、版权和投诉处置结论。
- **A（推荐）**：技术事实保留；未经当前基线 legal / PO 复核的法律结论降为 candidate / fact gate。
- **B**：完成法律复核并将批准口径作为 current release authority。
- **影响**：复核完成前，不能把该文件单独用作发布法律充分性证明。

### P4：App Store 类别

- **事实**：定位文档写“优先 Productivity / Utilities”，候选元数据一处称已批准，另一处又要求
  提交前确认。
- **A**：现在固定主 / 次类别并写入 positioning / metadata。
- **B（推荐）**：保持候选，待最终 binary、文案与 ASO 一并裁决。
- **影响**：不阻塞代码收敛，但阻塞最终 metadata freeze。

### P5：Backup v3 不可逆 wire

- **事实**：D1-B 只批准 SQLite container family；exact DDL、defensive opening、fixtures 和兼容
  转换尚未成为 effective contract。
- **裁决方式**：Data DRI 先提交完整 wire candidate 与对抗性实证，再由 PO 对精确版本批准或退回。
- **影响**：批准前可以继续只读审计和原型，不能合入正式 writer / reader 或触发 compatibility epoch。

### P6：跨文档 owner 与 authority registry 模型

- **事实**：NFR、Data Contract、Backup Wire 和 Architecture 存在 owner bleed；registry 又把不同
  层级 / domain 的 authority 放在同一桶。直接重分 owner 或新增 registry 模型会改变控制面，不是
  P-A Green 机械清理。
- **A（推荐）**：固定 NFR 只拥有预算，Data Contract 只拥有可观察数据语义，Wire 只拥有外部格式，
  Architecture 只拥有工程边界；registry 增加最小 `tier` / `domain` / `upstream`，不另建状态 SSOT。
- **B**：保持现有 registry，只逐处增加 owner pointer；接受 validator 暂时不能机器识别 authority
  层级与上游。
- **影响**：裁决前只可记录冲突和做不改变 owner 的机械链接修复，不能自主重写跨文档归属。

## 6. Green 收敛顺序

1. 将 #958 的 ORI-A source 配置与 fail-closed validator 合入；当前精确 head 已绿但仍待 PO
   单独授权，不能把 Draft PR 当 effective。
2. 队列释放后，主安全 lane 先关闭 #888 的 M6/S0：用一个 Profile-free、old-or-new 的 typed
   draft generation 替换 JPEG + UserDefaults split state，统一 production 注入，补齐五条图片
   通道与正式保存 settlement。#953 已 effective；#886 的 M5 renderer / selection 文件集与它
   不相交，可占第二 write lane 并行修复无封面、空选择前置失败、精确页数与每条可读；真机打印
   仍单独存证。
3. #888 effective 后，串行完成 #884-A1 / A2 的持久删除 identity、显式 SwiftData V1 -> V2 migration、active-only
   query / boot reconciliation 和统一 operation coordinator。它既关闭 M4，也为恢复路径提供
   same-ID stale-operation fence 与有序 barrier。
4. 在 post-#884 develop 重建关闭的 #944 中仍有效的 restore regression，再从 #884-A + #888 +
   successor 基线做 #889-A；M8 的 durable incident / 用户裁决生命周期随后消费 #953 seam。
   在 durable incident 前不得发布会被下次启动误认成健康库的新空 store。
5. 按 public / po-only / research manifest 隐藏或移除 live UI 入口，再重写或降级旧 UI-freeze
   oracle；不删除仍有用的历史截图。
6. 建立 M1-M10 独立 outcome edge 和 candidate evidence schema；区分“计划中的 oracle”、
   “已执行测试”和“真机 / 发布附件”。
7. 将 M1-M4、M6、M8-M10 缺失的结果级测试按文件集和风险拆成独立 T3/T4 slices。

M7 正式实现等待 P5；跨文档 owner / tier 清理等待 P6；P1-P4、P6 可集中由 PO 裁决。任何 Green
修复仍需独立 worktree、对应验证和 Draft PR；merge、产品裁决、上传和发布继续由 PO 单独授权。

## 7. 本次验证

已在固定 base 上执行：

```text
python3 Scripts/validate_document_control.py --check
python3 Scripts/validate_docs.py --check
python3 Scripts/generate_feature_status.py --check
python3 Scripts/generate_intent_traceability.py --check
python3 Scripts/validate_capture_contract.py --check
python3 Scripts/validate_release_configuration.py --check
python3 Scripts/test_doc_generators.py
python3 -m unittest discover Scripts/tests
git diff --check
```

上述命令均返回绿色；generator tests 为 20 项，`Scripts/tests` 为 105 项。`validate_docs.py`
保留已有 warnings，但无 error。本报告已列出这些门禁不覆盖的范围。未运行新的 app build、
UITests、真机、archive 或网络流量验证；已有 CI 结果不被重新解释为 candidate conformance。
独立只读语义 review 首轮提出 5 项事实 / 分类问题；修正后复核为 `No findings`。
