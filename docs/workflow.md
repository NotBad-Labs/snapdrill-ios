---
last_verified: 2026-05-19
layer: pattern
---
# SnapDrill 协作流程

> 开发闭环、Git 工作流、Code Review、优先级。
> 工程哲学见 `docs/standards/engineering.md`，协作模式见 `docs/standards/collaboration.md`。
> CI 操作细节见 `docs/tech/deployment.md`，测试执行见 `docs/standards/testing.md`。

---

## 开发闭环

```
Research → Shaped → Building (WIP≤2) → Reviewing → Done
```

**Research**：不确定就先研究（engineering 原则 1）。涉及新 API、新交互模式、性能敏感的改动，先读 Apple 文档/WWDC/现有代码再进 Shape。Research 必须产出 Issue comment 证据（文档链接/grep 结论/取舍理由），受 Appetite 预算约束。trivial 改动（单行 typo/注释/日志）跳过 Research。

**WIP 约束**：同时进行的 Building + Reviewing 任务 ≤ 2。PR 提交 Review 后释放一个 WIP 槽位，可以开始下一个 Building。Review 通过后合并，不通过则修完重新提交 Review。

---

## Issue 流程

### 模板

SSOT：`.github/ISSUE_TEMPLATE/feature_request.md`（feature）、`.github/ISSUE_TEMPLATE/bug_report.md`（bug）、`.github/ISSUE_TEMPLATE/chore.md`（杂项）。

核心字段：问题/用户场景 · MoSCoW · Severity · Appetite · Scope/No-Go · 风险与不确定性 · 验收标准（Given-When-Then）。

### Scope 控制

1. **Appetite 预算**：超预算砍 scope，不加时间
2. **No-Go 清单**：Issue 明确不做什么
3. **发现即建 Issue**：Build 中范围外的新发现不在当前 PR 处理（engineering 原则 3）

### 编码前契约（Sprint Contract）

**何时需要**：feature 类 Issue，或 Appetite >= Medium 的 chore。

**何时豁免**：bug_report（scope 天然小）、trivial（不改行为、不改接口、不改测试/baseline、不改约束语义，且单文件小改）。Small chore 只需填 Touches / No-Touch / DoD 最小集三条。

> 注：F-018 的历史阈值是 `chore Appetite >= Small`。本文件为当前协作规则 SSOT，以此处为准。

在 Issue 回复 Sprint Contract comment，覆盖：Touches / No-Touch / Interface Delta / Test Additions / DoD 最小集 / 预期不确定点。编码中 contract 变更须先改 comment 再改代码。

详见 `sprint-contract` skill（F-018 权威源）。

---

## Git 工作流

> **F-001 权威定义**。本段是 F-001（Git 工作流纪律）的事实权威源。

```
main ← App Store，只接受 develop 的 PR
develop ← TestFlight，只接受 feature/fix/chore 分支的 PR
```

**铁律**：禁止直推 develop/main。每个任务：Issue → 分支 → PR（`Closes #N`）→ Review → 合并。
**例外**：STATUS.md 允许直推 develop。

---

## Definition of Done

> 基于 `docs/standards/engineering.md` 7 条原则。每条 DoD 项标注对应原则编号。

### 代码质量
- [ ] `swiftlint --strict` 0 violations（原则 4：编译拦截）
- [ ] `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` 0 errors（原则 4）
- [ ] CI test 通过（已有测试不得回归）（原则 4）
- [ ] 改接口签名后 grep 测试同步（原则 4）
- [ ] 涉及新 API/新交互时 PR 描述留有研究证据（原则 1：先判断方向）
- [ ] 新增抽象有明确必要性（原则 2：删掉比添加好）
- [ ] 功能不超出 Issue scope，无假设性需求（原则 3：不为假设需求写代码）
- [ ] 跨模块边界有明确的契约定义（原则 5：跨边界先定义契约）
- [ ] 复杂业务状态由 ViewModel 集中编排（原则 6：状态所有权明确）
- [ ] 不可逆决策有记录（原则 7：不可逆决策门槛高）—— 重大决策走 ADR，小决策在 PR 描述说明
- [ ] Codex 对抗性审查通过（每个 PR 必须）
- [ ] Xcode Review 核实通过（UI 改动必须）
- [ ] AI 反模式检查通过（见 `collaboration.md` 检查表），附证据

### 功能完整性
- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] VoiceOver 辅助标签已补齐（新增 UI 元素）

### 文档同步
- [ ] `product-requirements.md` 已更新（新增功能）
- [ ] 新增第三方库 → 更新开源许可展示
- [ ] 术语与 `product-glossary.md` 一致
- [ ] 合并后立即更新 `STATUS.md`
- [ ] `api-pitfalls.md` 已更新（实现中发现新 API 陷阱——原则 4 补充）
- [ ] `apple-limits.md` 已更新（实现中发现 Apple 平台新限制——原则 1 补充）
- [ ] `architecture.md` 已更新（新增/移除/重命名模块）
- [ ] `non-functional-requirements.md` 已评估（触及性能/内存边界时）

### Review
- [ ] Review 结论已留痕（PR comment 或 PR 描述）

---

## Code Review

> **F-005 权威定义**。本段是 F-005（对抗性审查）的事实权威源；详细执行流程见 `cross-audit` skill（F-008/F-011/F-016 权威源）。

**所有 PR 必须完成 review 后合并。Review 结论必须留痕。**

1. **对抗性审查**：Codex（终端内）审查每个 PR（engineering 原则 4 补充——编译器管不了的行为用对抗审查覆盖）
2. **UI Review**：涉及 UI 改动的 PR 用 Xcode Intelligence Review
3. **核实**：Claude 逐条确认 finding 真实性
4. **合并**：所有 finding 解决后，由人类操作者确认或明确授权后合并（人类拥有最终裁决权）

**纪律**：
- 禁止自审自批
- 范围外发现立即建 Issue
- Review 无留痕的 PR 不得合并

---

## CI

CI 使用 Mac mini self-hosted runner（Xcode 26.5 / iPhone 17 Simulator）。PR 提交后自动触发 Build & Test + Docs Audit。

**流程规则**（操作细节见 `docs/tech/deployment.md`）：
- 本地必须能复现 CI test（两步：build-for-testing → test-without-building）
- Snapshot baseline 变更必须 git diff 确认后提交，禁止盲目 record
- CI 失败立即修复（engineering 原则 7 补充——CI 是合并的不可逆门禁）。另见 `post-merge` skill（F-007 双时点门禁）

---

## 优先级（S0-S3）

按「用户失去了什么」排序：

| 级别 | 含义 | 典型场景 |
|---|---|---|
| **S0** | 数据不可逆丢失 | 保存静默失败、备份损坏 |
| **S1** | 流程完全阻断 | 崩溃、功能不可用、OOM |
| **S2** | 能完成但有摩擦 | OCR 不准、搜索不准、卡顿 |
| **S3** | 更好但不紧急 | UI 打磨、测试补充、重构 |

**执行**：S0 → S1 → S2 → S3，严格按序。同级内的模块优先级参考 `docs/product/product-vision.md`§文档使用规则（测试优先级）。

---

## 决策变更收尾

产品决策变更后必须闭环：

1. **影响评估**：grep 受影响的下游文档（见 `docs/DOC_DEPENDENCY_MAP.md` 变更传播规则）
2. **同步更新**：对受影响的产品主链（requirements / design / cases / glossary / business）和技术主链（architecture / compliance / NFR / deployment）逐文件更新，由 `dependency-propagation` skill 执行
3. **ADR**：重大决策（影响架构、商业模式、数据模型）创建 ADR 或更新已有 ADR
4. **Issue 关闭**：关联 Issue 更新状态并关闭
5. **STATUS.md**：合并后更新

---

## 交叉审计

三方审计的组合、流程、工具链见 `docs/standards/collaboration.md`；核心纪律见 `cross-audit` skill（F-008 权威源）。

---

## 文档审计（docaudit）

合并前必须通过 `docaudit all --strict --baseline`。命中 error 必须修复或走 `Scripts/audit/policy.yaml` legacy_whitelist 豁免。PR 描述不是豁免通道，同 PR 禁止为过审降级规则级别。

完整处置协议、留痕要求和禁止项见 `Scripts/audit/README.md`。

---

## 长任务 Phase Compaction

跨多 PR、多天的长任务，每合并 3-5 个 PR 后在 `docs/memory/handoff.md` 的 Risks 段记录阶段状态：

```markdown
## Phase <主题> — <日期>

- Done: ...
- Open: ...
- Risks: ...
- Next: ...
```
