# Definition of Done（DoD）

> **上游依赖**：`workflow.md`（Git 工作流、Code Review 流程）、`conventions.md`（编码规范）、`principles.md`（工程哲学）
>
> 本文件定义「什么叫完成」——PR 合并前的统一质量门禁。
> 具体编码规则见 `conventions.md`，Review 流程见 `workflow.md`，发版检查见 `release-checklist.md`。
>
> **使用方式**：PR 创建前，逐项核对。无法判断的项标注 `[待用户确认]`。

---

## PR 级 DoD（每个 PR 必须满足）

### 自动化检查

- [ ] `swiftlint --strict`：0 violations
- [ ] `xcodebuild build`：BUILD SUCCEEDED

> 如果 SwiftLint 版本升级导致新规则产生大量 violations，创建 chore Issue 处理，
> 期间临时在 `.swiftlint.yml` 中禁用新规则，而非跳过整个 lint 步骤。

### 测试验证

按修改涉及的包执行：

| 修改了哪个包 | 执行什么 |
|---|---|
| SnapDrillCore | `cd Packages/SnapDrillCore && swift test` |
| SnapDrillData | `cd Packages/SnapDrillData && swift test`（Predicate 测试预期跳过） |
| SnapDrillFeatures | 通过 Xcode GUI 运行对应 Feature 的测试 |
| SnapDrillUI / SnapDrillInfrastructure | 无独立测试套件，由 `xcodebuild build` 覆盖编译 |
| 未修改任何包 | 无需运行测试 |

- [ ] 修改涉及的包的测试全部通过
- [ ] 推荐：`xcodebuild test -scheme SnapDrill` 全量测试通过（如未执行，在 PR 描述中说明）

### 文档同步

- [ ] 代码变更未使 `.claude/` 下任何文档描述失实

常见触发点速查：

| 改动类型 | 可能需要更新的文档 |
|---|---|
| 新增/修改公开 API | `infrastructure.md` |
| 新增架构决策 | ADR + `decisions/README.md` |
| 修改包结构/依赖方向 | `architecture.md` |
| 修改编码规范/约定 | `conventions.md` |
| 修改工作流程 | `workflow.md` |

### Review 流程

- [ ] 三方 Code Review 完成且严重问题已修复（见 `workflow.md`「Code Review 铁律」）
- [ ] 非本 PR 范围的有效 finding 已创建 Issue
- [ ] 新增的 `// TODO` 注释关联 GitHub Issue 编号（格式：`// TODO: (#N) 描述`）

---

## 功能级 DoD（满足触发条件时额外检查）

### 触发条件

以下任一条件成立时，除 PR 级 DoD 外还需满足功能级检查：

- **UI 变更**：新增/修改/删除 View 文件，或修改 ViewModel 中影响 UI 状态的属性
- **数据变更**：修改 `@Model` 定义、Repository 写入方法、备份/恢复流程
- **行为变更**：修改 SM-2 调度逻辑、OCR 流程、PDF 导出格式

纯重构（不改变外部行为）、纯文档、纯测试的 PR 只需满足 PR 级 DoD。

### 额外检查

- [ ] 影响用户数据的改动 → S0/S1 场景验证（参照 `workflow.md`「工作优先级框架」的判级标准）
- [ ] `@Model` 属性变更 → 确认是否需要更新 `SchemaMigrationPlan`
- [ ] UI 改动 → 研究声明已输出（见 `principles.md`「决策前研究铁律」和「Apple 原生优先铁律」）

---

## 发版级 DoD

发版前的完整检查见 → **`.claude/release-checklist.md`**（TestFlight 发版前真机手动测试）

---

## 「不能上 UI」规则

以下情况的功能**不得出现在界面上**（宁可藏起来）：
- 点击后无任何有意义的反馈
- 显示「开发中」「敬请期待」等占位文案
- 数据为假数据或硬编码

唯一例外：明确标注为「Beta」或「即将推出」的功能模块入口（整个模块级别的占位，而非局部功能）。
