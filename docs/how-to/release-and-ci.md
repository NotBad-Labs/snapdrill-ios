---
last_verified: 2026-07-16
layer: pattern
freshness:
  max_age_days: 60
  decay_trigger: [ci_change, distribution_change]
---
# SnapDrill 部署与运维

> App Store 发布流程、版本管理、CI/CD、监控。
> DevOps 详细 checklist 见下文 §发版检查清单（已合并入本文件）。
> Release DRI 由当次 task brief / candidate manifest 指定；未指定时由当前 orchestrator
> （默认 Codex C1）汇总。PO 保留 TestFlight / App Store 上传、审核提交和正式发布授权。

---

## 版本管理

### 版本号单一来源

```
Configs/Shared.xcconfig
├── MARKETING_VERSION = 1.1.0    ← App Store 显示版本
└── CURRENT_PROJECT_VERSION = 6  ← Build 号（每次提交递增）
```

**铁律**：只改 `Shared.xcconfig`，不在 Xcode Target 设置中改版本号。

### 语义版本规则

- **Major**（x.0.0）：重大功能变更或破坏性改动
- **Minor**（1.x.0）：新功能
- **Build**（递增整数）：每次 TestFlight/App Store 提交递增

---

## CI/CD

### 本地 canonical source gate

代码 PR 在 clean committed head 达到 merge-ready 前运行：

```bash
bash Scripts/ci-local.sh
```

该入口 fail closed，并把一次绿色结果绑定到 exact checkout SHA、[`Configs/Toolchain.env`](../../Configs/Toolchain.env) 中的 Xcode / SwiftLint 身份和请求的 simulator destination。它按 routine source gate 的语义顺序执行 SwiftLint、脚本 / 文档生成与校验、依赖方向、`AllTests.xctestplan` CI configuration、唯一 `.xctestrun` 的 `build-for-testing` + `test-without-building`。Apple 的测试 action 同样采用 [build-for-testing 后接 test-without-building](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions) 的两阶段模型。

该脚本只记录 name-based requested destination，不擦除用户 simulator，也不证明实际 UDID / runtime 或多 worktree 分配；GitHub Actions 另行绑定 exact simulator，local 多 worktree 分配属于 #933。绿色只证明当前 source/package 层；不证明 app XCUITest / AX、signed archive、已安装 runtime、隐私 / 网络、Release candidate conformance，也不授权 merge、upload、TestFlight、go/no-go 或 release。`SnapshotRecord` 不在默认路径，任何重录必须限定具体测试并人工审查 baseline diff。

### GitHub Actions

```yaml
# .github/workflows/ci.yml
触发条件：PR → develop/main，push → develop/main，或手动触发（workflow_dispatch）
Runner：Mac mini 自托管（self-hosted, macOS）。两个 job：
  - `build`（Build & Test，timeout 60min）：每次 PR/push 都跑——门禁。
  - `ui-tests`（UI Tests，timeout 45min）：仅 develop push（合并）或手动触发，且 `needs: build`。

【build job 步骤】
  1. Checkout（actions/checkout v5 固定完整 SHA；contents:read；不保留凭据）并验证 HEAD == GITHUB_SHA
  2. 从 Configs/Toolchain.env 精确校验 Xcode 版本/build、SwiftLint 与预期 simulator runtime；缺失或不匹配 fail closed
  3. Lint、脚本/文档门禁与依赖方向检查
  4. 从 simctl JSON 在 pinned runtime 内按名称 + device type 唯一选择 exact iPhone 17，记录 UDID/runtime；零个或多个均失败
  5. 用该 UDID clean/boot，并校验 AllTests.xctestplan JSON
  6. 单次 resolve package dependencies（失败不自动重试）
  7. xcodebuild build-for-testing -scheme AllTests -testPlan AllTests
     -derivedDataPath $GITHUB_WORKSPACE/DerivedData
     -destination 'platform=iOS Simulator,id=<selected UDID>'
     CODE_SIGNING_ALLOWED=NO
  8. 唯一解析 AllTests_*.xctestrun；零个或多个均失败
  9. xcodebuild test-without-building（单次执行）
     -xctestrun <exact path>
     -only-test-configuration CI
     -destination 'platform=iOS Simulator,id=<same selected UDID>'
     -parallel-testing-enabled NO
     -test-timeouts-enabled YES
     -default-test-execution-time-allowance 120
     -maximum-test-execution-time-allowance 300
     -resultBundlePath $RUNNER_TEMP/<run-job-attempt>.xcresult
  10. `if: always()` 将日志、可用 xcresult 和结构化摘要复制到 checkout 外的受管 evidence root

【ui-tests job 步骤】（app 级 XCUITest，慢且对模拟器生命周期敏感，故隔离出门禁）
  1. 同样验证 checkout 与精确工具身份
  2. 独立结构化选择唯一 exact iPhone 17，并用同一 UDID clean/boot/build/test
  3. Validate UITests.xctestplan JSON；单次 resolve package dependencies
  4. xcodebuild build-for-testing -scheme SnapDrill -testPlan UITests
     -derivedDataPath $GITHUB_WORKSPACE/DerivedDataUI
     -destination 'platform=iOS Simulator,id=<selected UDID>'
  5. 唯一解析 SnapDrill_UITests_*.xctestrun
  6. xcodebuild test-without-building（单次执行；不做 generic whole-suite retry）
     -xctestrun <exact path>
     -only-test-configuration CI -parallel-testing-enabled NO
     -destination 'platform=iOS Simulator,id=<same selected UDID>'
     -test-timeouts-enabled YES
     -default-test-execution-time-allowance 300
     -maximum-test-execution-time-allowance 600
     -resultBundlePath $RUNNER_TEMP/<run-job-attempt>.xcresult
  7. `if: always()` 执行同一 durable evidence finalizer
```

注：
- **门禁 build job** 跑 `AllTests.xctestplan` 的 CI configuration，含 5 个 test target（SnapDrillCoreTests / SnapDrillDataTests / SnapDrillFeaturesTests / SnapDrillShareTests + 包级 SnapDrillUITests 单元烟雾测试）。
- **ui-tests job** 跑独立 `UITests.xctestplan` 的完整 app 级 `SnapDrillUITests`。它刻意不进每-PR 门禁；2026-07-16 的 [develop run 29464280148](https://github.com/NotBad-Labs/snapdrill-ios/actions/runs/29464280148) 与 [manual run 29466417966](https://github.com/NotBad-Labs/snapdrill-ios/actions/runs/29466417966) 分别约 28.5 / 29 分钟，仅 develop 合并或手动 `workflow_dispatch` 时跑，`needs: build` 保证 source gate 先过。更细的 targeted/nightly/candidate cadence 由 #933 定义。
- 两个 job 各自选择并绑定本 job 的唯一 simulator；这不声称在未来多 runner 环境中跨 job 使用同一设备。结构化 helper 记录 runtime identifier，但 Release candidate 的 runtime/device matrix 仍由候选证据门禁负责。
- `pull_request` 事件中的 `GITHUB_SHA` 是 GitHub 生成的 `refs/pull/<n>/merge` 临时 merge commit，不是 PR head；push / manual dispatch 则是触发 ref 的 commit。日志中的 checkout identity 只按对应事件语义解释，临时 merge SHA 不能代替长期候选证据。
- `test-without-building` 复用本 job 的 `build-for-testing` 产物。generic UI retry 已删除：任何产品断言、crash 或基础设施失败都保持红色，不会被后续成功覆盖。
- 单项测试 timeout 仅由 CI 命令行启用，不改共享 test plan：source tests 默认 120 秒、硬上限 300 秒；app UI tests 默认 300 秒、硬上限 600 秒。60 / 45 分钟 job timeout 仍是外层兜底。超时保持失败并进入同一 finalizer，不做自动重跑。
- `SnapshotRecord` configuration 仅本地显式重录 baseline 使用，不参与 CI。

### Runner 本地 CI 证据

两个 job 的测试日志和 xcresult 先写入按 run / job / attempt 唯一命名的 `$RUNNER_TEMP` 路径。紧随测试命令的 `if: always()` step 调用 `Scripts/ci_github.py evidence`，将当次可用材料复制到：

```text
$HOME/.snapdrill/ci-evidence/
└── run-<GITHUB_RUN_ID>/
    └── <GITHUB_JOB>/
        └── attempt-<GITHUB_RUN_ATTEMPT>/
            ├── summary.json
            ├── summary.md
            ├── test.log
            └── results.xcresult/   # xcodebuild 已产出时
```

- `summary.json` 区分 GitHub trigger SHA 与经 checkout-identity step 验证的 checkout SHA，并记录 event/run/job/attempt、结果与 exit code、经 toolchain step 验证的工具版本与 Developer 目录、simulator name/UDID/runtime/device type/destination、scheme/test plan/configuration、CI-only timeout 和实际保存的附件。未经对应 step 验证的 checkout / toolchain 字段只能是 `null` / `false`。
- test step 成功必须同时有日志与完整 xcresult；失败必须保留日志，并在 xcodebuild 已能 finalise 时复制 partial xcresult。若 checkout 已取得 helper、但之后的 identity、toolchain 或其他前置 step 失败导致测试被跳过，finalizer 仍写诚实的 `skipped` 摘要，不重新读取故障配置，也不虚构测试附件。若 `actions/checkout` 本身未取得 helper，则无法由 checkout 内脚本生成本地摘要。
- finalizer 把 durable local path 和 routine-only 限制写入 `GITHUB_STEP_SUMMARY`。Operator 可从 Actions 页面直接定位 Mac mini 上的材料。
- evidence root 首次使用时必须为空并写入固定 ownership marker；以后 marker 不匹配、root 与 checkout 任一方向嵌套、root 或其直接父目录 / run 为 symlink、lock 非普通文件或出现非受管直属项均 fail closed。finalization 与清理在同一 root lock 下串行，清理器不接管或删除无 marker 的目录。
- 每次 finalization 先删除超过 14 天的旧 run，再按最旧优先把文件系统实际分配空间限制到 20 GiB；当前 run 永不为满足预算而删除。若当前 run 单独超限，保留材料并让 CI 失败，等待 operator 处置。
- 这是当前 Mac mini 的 bounded、runner-local 诊断证据，不是 GitHub artifact，不跨 runner 复制。GitHub artifact 上传仍停用，避免再次耗尽 Actions 存储配额。
- `if: always()` 只覆盖 GitHub job 仍能继续调度 step 的 success / failure / skipped / cancelled 控制流；runner 断电、job 强制终止或进程收到不可恢复的 hard kill 时不能保证 finalizer 执行。此时 Actions 状态本身是事故信号，不能把缺失的本地材料解释为测试通过。
- self-hosted runner 会执行 checkout 中的 PR 代码；仓库写权限、fork policy、branch protection 与 runner 隔离属于本 helper 之外的信任边界，不能由 evidence marker 替代。
- 分类固定为 `routine-ci-only`：它不证明签名 archive / 安装变体、隐私 / 网络运行时或 Release candidate conformance，也不授权 merge、upload、TestFlight、go/no-go 或 release。候选不可变证据仍归 #895 / #896 / #897。

### GitHub Token 配置

严禁把 GitHub token 写入 `.claude/settings.local.json`、脚本、文档或任何可提交文件。`.claude/settings.local.json` 只允许保存本机权限偏好，已由 `.gitignore` 排除。

本地命令优先读取环境变量：

```bash
export GITHUB_TOKEN="<your-github-token>"
```

需要长期保存时使用 macOS 钥匙串：

```bash
security add-generic-password -a "$USER" -s snapdrill-github-token -w "$GITHUB_TOKEN" -U
export GITHUB_TOKEN="$(security find-generic-password -a "$USER" -s snapdrill-github-token -w)"
```

### Mac mini Runner

- 自托管 runner（self-hosted, macOS）
- 离线时任务排队等待

---

## 发布流程

### 发布就绪责任

Release DRI 维护本文件中的发版检查清单并汇总各方结果：

- Engineering / 数据完整性 / 隐私技术事实：当次 owning Engineering / Data / Security lane
- UI / 无障碍 / 本地化最终呈现 / 截图真实性：当次 owning UI / QA lane
- 元数据 / 官网 / ASO / 公开政策：当次 owning Copy / Compliance lane
- 真机产品验收与最终 go/no-go：PO

任何一方发现未满足项都应记录证据；Release DRI 负责分诊与追踪，但无权代替 PO 发布，
也无权覆盖 owning UI DRI 与 PO 已确定的视觉方案。

### 当前发布实证快照（2026-06-21）

已验证：

- `xcodebuild archive -scheme SnapDrill -configuration Release -destination 'generic/platform=iOS'` 成功产出当前 HEAD 的 `.xcarchive`。
- Archive 属性：`CFBundleIdentifier = com.snapdrill.global`，`CFBundleShortVersionString = 1.1.0`，`CFBundleVersion = 6`，`Team = J58U72W335`，`SigningIdentity = Apple Development: Yiming Liao (PBRAUAP3KL)`。
- 主 App 与 Share Extension entitlements 均为 `J58U72W335.*`，并包含 `group.com.snapdrill.global`。
- `xcodebuild build -scheme SnapDrill -configuration Release -destination 'platform=iOS,id=<paired iPhone 17>'` 成功产出开发签名 Release 真机包，`xcrun devicectl device install app` 成功安装 `com.snapdrill.global`。
- `xcrun devicectl device process launch ... com.snapdrill.global` 成功启动开发签名真机安装包。

未验证 / 不得视为已完成：

- 本机 keychain 仅发现 Apple Development identity，未发现 Apple Distribution identity。
- `xcodebuild -exportArchive -exportOptionsPlist <app-store-connect export>` 当前失败：缺 `com.snapdrill.global` 与 `com.snapdrill.global.share` 的 distribution/export profiles；TestFlight / App Store distribution signing、export、upload 尚未验证。
- Capture / Export / Print dogfood 尚未验证。
- 当前主 App 与 Share Extension archive 的 `UIDeviceFamily = [1]`，即 iPhone-only；iPad / 通用发行需 PO 决策、target family 配置变更和 UI dogfood 后再进入发版口径。

### TestFlight（内部测试）

```
1. Shared.xcconfig 递增 CURRENT_PROJECT_VERSION
2. Xcode → Product → Archive
3. Organizer → Distribute App → TestFlight Internal
4. 等待 Apple 处理（通常 < 30 分钟）
5. TestFlight App 自动收到更新
```

### App Store（正式发布）

```
1. TestFlight 验证通过
2. App Store Connect 填写发布信息
   - 截图（Release 1 仅 iPhone，尺寸按当期 App Store Connect 要求）
   - ASO 文案（标题/副标题/关键词/描述，中英双语）
   - 隐私政策 URL + 服务条款 URL
   - 审核备注
3. 提交审核（通常 24-48 小时）
4. 审核通过后手动发布或定时发布
```

### 审核注意事项

- 年龄分级 4+（无不当内容）
- 不进入 Kids Category
- 隐私清单与实际一致
- 避免 "children" "kids" 等触发审查的措辞
- 首次提交附审核备注说明 App 功能

---

## 监控与反馈

### 当前全球版技术监控

- 生产基线为 `com.snapdrill.global`，注入 `NoOpAnalyticsService`；Firebase 与 `SnapDrillInfrastructure` 已在 #803 删除
- 崩溃与设备性能使用 Apple 原生 **Xcode Organizer / MetricKit**；产品趋势使用 App Store Connect 聚合数据
- 当次技术监控 DRI 在每次外部 TestFlight 后、每次正式发布后检查崩溃、watchdog、启动、
  内存和能耗异常；出现 S0 / S1 信号立即分诊
- 零正式用户阶段不设置“每日监控”仪式；有真实用户后按实际风险调整检查频率

### 用户反馈闭环

1. owning Feedback / Copy lane 汇总支持渠道、TestFlight 和 App Store 反馈，去重并标注事实、
   复现条件和用户影响
2. PO 判断产品含义和优先级
3. owning Engineering / Data / Performance lane 负责技术分析，owning UI / UX lane 负责交互分析
4. 对应 lane 实现后，由原验收责任方复验，Release DRI 确认跨层工程闭环

原始反馈不是需求；未经 PO 判断，不得直接改变产品默认行为或路线。

### 隐私一致性检查

每次发布前由 designated Data / Security DRI 核对实际数据流、第三方依赖、Privacy Manifest
和 App Store Privacy 标签所依据的技术事实。owning Copy / Compliance lane 使用该事实维护
官网与政策文案；PO 在必要时结合律师意见作最终风险签署。发现不一致时先阻止发布，再决定
修代码或修声明。

### 技术事故与紧急修复

```
1. Incident DRI 依据证据分级：S0 = 数据不可逆丢失；S1 = 启动崩溃或核心流程完全阻断。
   隐私 / 安全事件是独立 release blocker，再按实际数据与流程后果映射 S0-S3，不自动等同 S0
2. Incident DRI 立即停止普通工程集成，创建 hotfix worktree，完成复现、影响范围和技术止损方案
3. 数据迁移问题必须使用上一已发布版本的数据存档验证升级路径，不以全新数据库测试代替
4. owning UI / UX lane 复验受影响交互；owning Copy / Compliance lane 准备必要沟通草案
5. PO 决定上传、暂停分阶段发布、下架、对外通知或申请加急审核
6. iOS 已安装版本不能真正回滚：技术处理是回到已知良好代码、递增 build/version 并前滚发布修复版
```

PO 离线时，Incident DRI 可以完成分诊、修复、验证和本地 commit，但不得自行上传或发布。
安全 / 隐私事件的对外处置由 PO 决定，必要时咨询律师。

---

## 环境配置

| 环境 | 用途 | 分析配置 |
|---|---|---|
| Debug | 本地开发 + Simulator | `NoOpAnalyticsService` |
| Release | 全球版 TestFlight + App Store | `NoOpAnalyticsService` + 端侧 MetricKit |

**注意**：当前全球版不包含 `GoogleService-Info.plist` 或 Firebase SDK。恢复任何后端遥测都属于新的产品与隐私决策，必须经 PO 批准并同步 Privacy Manifest、App Store Privacy 标签与公开政策。

## 发版检查清单
---
# Release 1 dogfood 与发布证据计划

> **规范状态（2026-07-15）**：[Release 1 Product Contract](../reference/release-1-contract.md) 已承载 ratified Gate C 与后续 D1-B 至 D5-A、#932-A、#891 文案裁决，合入 `develop` 后成为本计划的产品 oracle。下列清单仍不授权实现、上传或发布；未纳入冻结 Capability Manifest 的 optional 能力必须隐藏，Review / SmartPaper 在 `public-candidate` 必须隐藏。
>
> **上游依赖**：Product Constitution v1 + [Release 1 Product Contract](../reference/release-1-contract.md) + 本文件 §发布流程。
>
> Capability Manifest validator 经独立 slice 落地、候选冻结且 PO 授权对应动作后，才在真机上走完被纳入范围的项目。
> 标注 ❌ 的项目必须修复后才能发版。
>
> Checklist structure aligned: 2026-07-12。具体项目仍须在每次待发布 build 上逐项实测。

---

## Evidence plan（QA / Data / Security / Release DRI）

本节承接 Release 1 Contract C6 的发布政策，但不是产品范围来源。DRI 可以随工具链和实现调整命令、设备、test ID 与 fault-injection 点；不得降低 M1-M10 结果覆盖。每份证据必须记录 candidate ID、audience、source commit、版本、build、ASC build ID、本地 archive hash、上传回执、安装变体身份、环境和附件路径。

| 阶段 | 最低进入条件 | 该阶段不能证明 |
|---|---|---|
| PO-only 上传前 | `audience: po-only` manifest 冻结；lint / build / relevant tests；静态隐私 / entitlement；已知 S0 / S1 为零；PO upload 授权 | 市场需求、公开发布质量 |
| PO-only 安装后 | TestFlight 安装 / 启动；clean + existing-data 核心闭环；主要拒权 / 失败路径；结构化反馈 | 非 PO 用户行为、公开 binary 结果 |
| Research（条件式） | DATA-1、Local Library Data Contract 与精确 Backup v3 Wire 已 effective，正式 writer-reader round-trip 通过；`audience: research`；PO 已授权本次 non-PO availability；目标成年人资格、完整 cohort 与 TestFlight group / ACL / public-link 状态预登记并存证；开放即触发 / 延续 epoch；相关 optional 的无提示路径与结果 oracle | 自动 include 或公开 go / no-go |
| Public candidate | `audience: public-candidate`；M1-M10 全覆盖；本地 archive / 上传回执 / TestFlight 安装变体 / App Store submission 映射到同一 ASC build；S0 / S1 为零；S2 PO 接受；PO go / upload / non-PO availability / release 分别授权 | 上线后的市场结果 |

### M1-M10 双向追溯

| Must | 最低结果 oracle | Evidence owner |
|---|---|---|
| M1 | clean install 到首次可保存路径，全程无注册、身份或资料空间 gate | QA / Product |
| M2 | 相机 / 文扫、相册、PDF 分别完成确认、保存和读回；确认后的裁剪 / 方向图片可读且持久化 / backup 图片无 GPS；印刷体中英文分别验证可见可编辑 OCR，人工修正值读回；OCR 失败 / 空结果仍可保存 | Capture / QA |
| M3 | 首次 / 既有拒权、各输入取消和 OCR failure 均能经替代路径保存，无残留 cover / overlay / 失效导航 | Capture / QA |
| M4 | 分类 / 标签选择保存并读回；搜索与基础过滤命中正确集合；查看、编辑、删除；删除从点击时持久化五秒绝对期限，后台 / 重启不缩短，期限内撤销完整恢复，期限后只硬删除一次 | Library / Data / QA |
| M5 | `N >= 1` 的 selected set 与 PDF 条目一一对应且顺序稳定；基础 PDF 无封面且物理页数严格为 `ceil(N / itemsPerPage)`，空选择在渲染前失败；图片 / 纯文字 / 混合资料均可读且无空白 / 重复；真实 AirPrint 完成并检查输出；系统 share sheet 与“存储到文件”分别覆盖成功 / 取消 / 失败；已明确保存到 App 外的副本保留，无打印机 / 取消 / 失败不误报且清理 App-owned 临时输出 | Export / QA |
| M6 | 后台 / 终止注入后重启，只出现可完整恢复草稿或明确无草稿 / 丢弃结果，不出现半状态 | Capture / Data / QA |
| M7 | 正式 writer-reader round-trip 覆盖完整资料库；损坏 / 恶意 / 超限输入在 mutation 前拒绝或进入明确恢复态，原库不变 | Data / Security |
| M8 | store 打不开、停在裁决页终止、重启、恢复 / 放弃 / 双失败；始终保留 DATA-1 要求的材料且正常 UI 不假空 | Data / QA |
| M9 | 静态数据流 / entitlement / manifest / policy 对账；禁网运行全部可达 Must + included optional；受控联网覆盖启动 / 后台 / 升级 / Share Extension，区分用户主动外发、Apple 系统流量与意外外发；持久化 / 备份图片 GPS 检查；结论一致 | Privacy / Security / Release |
| M10 | 中英文、iPhone 17e / 17 / 17 Pro Max、默认 / xxxLarge / Accessibility 5 与 VoiceOver 最低矩阵；覆盖全部 Must、included optional、loading / empty / error / confirmation 和系统面板，旅程可完成且无阻断截断 / 遮挡 / 不可达操作；source settings、signed archive 与 ASC availability 同时证明 Mac / Vision Pro compatibility opt-out | UI / AX / QA / Release |

成功标准和产品边界只来自 effective Release Contract；本表定义如何证明。每次候选必须保存一份 M1-M10 -> test / dogfood / attachment 索引，未覆盖项直接阻断 public go / no-go。

---

## 历史 current-build 路由清单（非 C6 oracle）

以下旧清单保留为现有界面盘点。只有某行被映射到上表 Must、effective policy 或该 build manifest 中的 included capability 后，才进入候选证据；否则它不能扩大范围或阻断 optional 隐藏。

## 启动与首屏

- [ ] App 冷启动不崩溃
- [ ] 首次安装：Onboarding 正确显示
- [ ] Onboarding 翻页有轻触震动，点击「开始使用」有 success 震动
- [ ] 非首次安装：直接进入主界面
- [ ] 非首次普通启动进入 Dashboard；Capture / Library 一步可达，Profile / Pro / analytics / Review hero 不出现

## 采集流程（Capture）

- [ ] 相机权限弹窗正常出现（首次）
- [ ] 相机预览正常
- [ ] 拍照后进入裁剪器，裁剪后 OCR 识别并进入编辑界面
- [ ] OCR 识别结果可手动修正，修正后保存的是修正值
- [ ] 相册导入：选择照片后进入裁剪器，裁剪后 OCR 识别结果正确
- [ ] 手动编辑录入：不拍照，直接输入文字创建资料
- [ ] 保存后自动返回摄像头界面（连续录入）
- [ ] 保存后资料库和回顾界面按当前实现刷新
- [ ] 字段自动推断：第二次录入时，分类自动沿用上次选值
- [ ] 草稿恢复：录入中途退出 App，重新进入后 Dashboard 显示「恢复草稿」提示
- [ ] 选择「恢复草稿」进入编辑界面，图片和文字完整保留

## 资料库（Library）

- [ ] 无资料时显示空状态（通用受众资料库文案 +「去采集」按钮）
- [ ] 列表正常显示所有资料
- [ ] 搜索功能有效（基于 OCR 文字）
- [ ] 分类/标签过滤有效（多维组合）
- [ ] 排序切换有效（时间/分类/复习状态）
- [ ] 点击资料进入详情
- [ ] 详情页可以编辑并保存（补答案、改动态字段、加标签）
- [ ] 删除资料后列表更新
- [ ] 过滤后 PDF 导出：预览窗口可见，PDF 可分享

## 回顾（Review；仅在候选 Capability Manifest 纳入时）

以下项目只验证 C4-D 允许且被 `po-only` / `research` manifest 明确纳入的实验能力；`public-candidate` 必须证明 Review 完全隐藏且无调度副作用。

- [ ] `po-only` / `research` 只有 Library 的一个静态次级入口；无主 Tab、Dashboard cue / 计数、Onboarding、Settings、通知 / 徽标或隐式恢复入口
- [ ] `public-candidate` 无 Review 入口、可达 AX 元素、通知、状态恢复或后台调度副作用
- [ ] 从 Library 实验入口进入卡片
- [ ] 资料正面内容正常显示（文字、图片均测试）
- [ ] 翻转卡片显示答案
- [ ] 翻转卡片时有轻触震动反馈
- [ ] 向右滑：记住了，下一张
- [ ] 向左滑：忘了，下一张
- [ ] 点击「忘记/记得」评分按钮有 medium 震动反馈
- [ ] 点击「撤销/显示答案」按钮有 light 震动反馈
- [ ] 撤销按钮有效
- [ ] 所有卡片完成后显示完成界面，并触发 success 震动
- [ ] 退出回顾后返回 Library，已提交进度正确保留
- [ ] VoiceOver：翻卡公告、完成摘要公告、操作按钮辅助标签可读

## 首页（Dashboard）

- [ ] 完成 Onboarding 后的普通启动进入 Dashboard；显式 deep link 与阻塞性 store 恢复可覆盖默认目的地
- [ ] Capture 与 Library 均可从 Dashboard 一次操作到达，且在视觉与 AX 内容顺序中先于任何 Review 入口
- [ ] 无资料时显示真实空状态，并可一次操作进入 Capture；不显示伪造数据
- [ ] 若显示草稿、最近资料或其他本地事实，每一项都能直接进入对应任务；不展示纯趋势、比较、完成率或行为统计
- [ ] 不出现 Profile / Workspace、昵称 / 头像身份面、Pro / IAP、locked / coming-soon、analytics 或 Review hero
- [ ] 当前卡片、指标、问候语、排序和五 Tab 结构不作为验收 oracle

## 设置（Settings）

- [ ] 字段 / 动态维度管理仅在冻结 manifest 显式 include 时出现并通过数据完整性与 AX 验证
- [ ] 不出现 Profile / Workspace、昵称 / 头像 / 座右铭、Review 目标 / 排序 / 外观 / 提醒 / 通知或多个资料库管理入口
- [ ] 外观模式切换：跟随系统 / 浅色 / 深色 三种模式均可
- [ ] 语言设置：App 内直选中文 / 英文，切换后界面立即生效且不依赖系统语言
- [ ] 使用数据设置与当前零后端采集事实一致，不暗示 Firebase 或第三方崩溃上报已启用
- [ ] 媒体缓存清理入口完全隐藏；若底层实现暂留，targeted test 证明只清 `Caches/` 且不影响 App-managed 主图、备份或资料数据
- [ ] 隐私政策页面可以打开
- [ ] 服务条款页面可以打开
- [ ] 开源许可页面可以打开，且列出当前实际依赖（Mantis、ZIPFoundation 等），不再列出 Firebase
- [ ] 帮助中心、角色预设、诊断 / 遥测等未获范围授权的 Settings 表面完全隐藏；现有外部链接不构成 Release 1 可见性依据
- [ ] 生成测试数据、调试清库等开发者表面在候选 build 完全不可达；底层资料变更后的 Library 刷新由 targeted test 验证

## 单一本地资料库（B5-A）

- [ ] 首启和日常使用均不出现 Profile / Workspace 的创建、切换、删除或命名入口
- [ ] 采集、资料库、导出、打印、设置、手动备份及清单纳入的可选能力直接作用于同一个本地资料库
- [ ] 不出现「至少保留一个 Profile」、当前 Profile 头像或切换阻塞等用户可见文案
- [ ] 不同主题可通过搜索、基础分类和标签整理；只有冻结 manifest 纳入动态字段时，才追加验证来源 / 级别 / 自定义字段
- [ ] 备份 wire、恢复安全与旧 fixture 的最终验收按 DATA-1 下游 Data Contract 执行，不从当前 Multi-Profile build 反推

## 数据出口（Release 1 不含同步）

- [ ] 备份：每次点击先展示已批准的未加密 / 私人文字与图片提示；Cancel 不生成文件，Continue 只创建一个 `.snapdrillbackup` 并进入一个系统分享面板
- [ ] 恢复：点击后打开文件选择器，选择备份文件后数据和图片均完整恢复
- [ ] 恢复期间有进度提示
- [ ] 若 manifest include JSON 导出：文件可打开且字段声明准确，不冒充完整备份
- [ ] 若 manifest include CSV 导出：Excel 可打开、格式正确且通过公式注入防护，不冒充完整备份
- [ ] 不展示 CloudKit、同步、Pro、订阅或“即将推出”入口

## 引导与提醒

- [ ] 首次录入保存后：弹出字段配置引导提示
- [ ] Feature Tooltips：首次使用某功能时弹出轻量提示气泡（每个只显示一次）
- [ ] 卸载数据丢失提醒：设置页有明确 local-first 提示，并提供手动备份入口

## 稳定性

- [ ] 连续使用 10 分钟不崩溃
- [ ] 切换 Tab 多次不崩溃
- [ ] 后台切换后回到前台状态正确恢复

---

## 发版信息核对

- [ ] Build Number 已更新（每次发版 +1，只改 `Configs/Shared.xcconfig`）
- [ ] 没有 Debug 专用 UI 暴露在外
- [ ] 没有硬编码的测试账号或假数据
- [ ] Data / Security DRI 已核对依赖、实际数据流、Privacy Manifest 与 App Store Privacy 标签的技术事实一致
- [ ] UI / AX / QA DRI 已确认可达界面、无障碍、本地化布局和商店截图与当前 binary 一致
- [ ] Release Operations 已确认元数据、官网链接、支持渠道与公开政策基于当前产品事实
- [ ] PO 已完成真机产品验收并明确授权本次上传/发布

## 文档健康检查（每次发版必做）

- [ ] tracked SSOT、feature status 与 intent traceability 门禁全绿；首次 capability manifest freeze 前已另刀实现 schema v1 validator，之后每个不可变冻结件校验全绿
- [ ] 发布事实只引用当前 commit / binary 的仓库证据；私有 agent memory、聊天与本地 skill 不作为发布依据
