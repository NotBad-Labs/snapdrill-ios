# 三路协作边界与交接协议

> 当前版本：2026-06-11。适用于 Codex Desktop、Claude Code 与 Antigravity 并行协作。
> 目标是减少文件冲突与认知摩擦，不建立额外管理层。PO 对产品意图和争议拥有最终裁决权。

## 1. 共同真相源

冲突时按以下顺序裁决：

1. PO 最新明确决策
2. 当前代码、构建结果与运行实证
3. 根 `README.md`、`AGENTS.md` 与本文
4. feature spec、ADR、各 lane 的追溯日志
5. agent 私有记忆、旧计划和 `docs/research/` 历史材料

私有记忆只是可丢弃缓存。任何会影响其他 lane 的结论必须进入 git-tracked 文档、代码或 commit，不能只留在某个 agent 会话中。

## 2. Lane 所有权

### Codex Desktop：UI 设计与 UI 实现

拥有：

- `Packages/SnapDrillUI/`
- `Packages/SnapDrillFeatures/**/**View.swift`
- UI snapshot / XCUITest 中与视觉和交互表现直接相关的文件
- `SnapDrill/App/AppRootView.swift`、`SnapDrill/App/AppRouter.swift` 的导航外观与视觉壳
- `docs/ui-redesign/`

不拥有：

- 任何 `*ViewModel.swift`
- Core/Data、Repository、DataExecutor、`@Model`
- CI、签名、pbxproj、Package lockfile
- 保存编排、错误恢复、通知监听、筛选/分页算法等非视觉业务逻辑

Codex 可以从实际交互中审计跨层问题，但只记录契约、复现与建议；实现交给对应 lane。UI 设计决策由 Codex 与 PO 决定，Claude 不代理设计。

### Claude Code：工程与集成

拥有：

- `Packages/SnapDrillCore/`
- `Packages/SnapDrillData/`
- `Packages/SnapDrillFeatures/**/*ViewModel.swift`
- Feature 内非视觉服务、解析、导出编排与状态机
- `SnapDrill/App/` 的 composition root、依赖装配与生命周期逻辑
- `.github/`、`Scripts/`、签名/构建配置、`project.pbxproj`、`Package.resolved`
- Core/Data/ViewModel 测试与最终集成闸

Claude 不修改 Codex 已确定的 UI 视觉方案。跨层修复需要新增 UI 接口时，先定义最小契约并在共享文档记录，再由 Codex接入 View。

### Antigravity：官网、运营与合规文案

拥有：

- 官网仓库内容与页面
- App Store 元数据、ASO、运营材料、合规文案草案
- 本仓库中明确分配的文档与追溯日志

Antigravity 不修改 Swift 业务逻辑。法律结论必须标注来源与是否需律师确认；产品定位文案必须服从 PO 已决策的 general-audience 效率工具定位。

## 3. 共享接缝

以下改动不是某个 lane 可静默完成的局部改动：

| 接缝 | 主责 | 协作要求 |
|---|---|---|
| Core service / DTO / Notification name | Claude | 改前记录消费者；改后提供签名、迁移说明与验证结果 |
| Feature public View init / Environment key | Codex | 改前 grep 所有调用点并通知 Claude；由拥有调用文件的 lane 接入 |
| View 与 ViewModel 状态契约 | 双方 | View 只表达所需状态/动作；ViewModel 负责业务时序和副作用 |
| 打印/分享系统呈现 | Core 产物由 Claude，UIKit/SwiftUI presentation adapter 由 Codex | 当前契约见 `docs/ui-redesign/flagship-cross-layer-contracts.md` |
| 本地化文案 | 提议方起草 | 产品含义由 PO，合规措辞由 Antigravity，UI 容器适配由 Codex，资源集成由 Claude |
| `project.pbxproj` / lockfile / target membership | Claude | 其他 lane 只提交需求，不并行编辑这些高冲突文件 |

冻结集的成员与数量必须从 live code grep，不凭记忆。2026-06-11 实证锚点：

- `ServiceContainer`：14 个属性，含 `metricService`
- SwiftData `@Model`：`ReviewItemModel` / `CategoryDimensionModel` / `CategoryValueModel`
- Library public View：`CategoryManagerView` / `LibraryEditView` / `LibraryView` / `SFSymbolPickerView`
- SPM package：Core / Data / Features / UI，共 4 个；Features 内含 5 个 feature target

## 4. 交接方式

Agents 不会自动读取彼此的私有会话，也不应互相调用对方模型。当前规则：

- Claude 不调用 Codex CLI、ChatGPT 或 Codex 插件
- Codex Desktop 与 Claude 通过共享仓库中的文档、commit hash、测试结果交接
- PO 不需要人工复制完整上下文；只需在需要启动另一 lane 或作产品裁决时通知
- 跨层发现写入拥有明确路径的文档，例如 `docs/ui-redesign/REDESIGN-LOG.md` 或专项 contract
- handoff 至少包含：问题、复现、责任层、所需契约、不可触碰边界、验证方式

## 5. Worktree 与提交

- 每个活跃 lane 使用独立 worktree 和独立分支
- 开工前记录 base commit；集成前 rebase 到最新 `origin/develop`
- 不改、不清理其他 lane 的 worktree、stash 或未提交文件
- 依赖顺序：Core/Data 契约先落地，UI/Feature 消费方后 rebase 接入
- PO 要求本地交付时，完成信号是：clean diff + 本地 commit + commit hash + 验证结果
- push、PR、merge、部署只有在 PO 明确授权时执行

建议每个 worktree 使用独立 DerivedData，避免并行构建互相清缓存：

```bash
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests \
  -derivedDataPath /tmp/snapdrill-derived-<lane>
```

## 6. 验证与完成信号

Swift 改动必须通过：

```bash
swiftlint --strict
xcodebuild build-for-testing -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests
```

文档/流程改动至少通过：

- `python3 Scripts/generate_feature_status.py --check`
- 链接、路径与数字对 live code 的 grep 复核
- `git diff --check`

完成报告必须区分：已验证、未运行、外部阻塞。不能用“代码看起来正确”替代 DoD。

## 7. 产品决策闸

只有以下情况必须停下问 PO：

- 改变产品定位、默认行为、免费/付费边界或用户可见语义
- 多个合理交互方案会形成不同产品体验
- 法律/合规 guardrail 与现有功能冲突
- 需要删除或不可逆迁移用户数据、账号、签名或发布资源

纯工程实现、事实校准、测试补齐、已决策方案的落地由对应 lane 自主完成。
