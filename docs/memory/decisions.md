---
last_verified: 2026-05-15
layer: pattern
---
# 项目决策记录

> 项目执行中的关键决策。与 docs/decisions/ADR-*.md（架构决策）互补，本文件记录工程和流程层面的决策。

## D-001: Typed throws 五方论证结论（2026-04-02）

**决策**：Repository CRUD 代理方法保持 untyped throws，业务验证方法用 typed throws，禁止 `underlying(Error)` 逃生舱。

**论证参与者**：Codex + Gemini ×2 + Coze + GLM4.7 + MiniMax（六方独立论证，Gemini 跑了 2 次）

**共识（4:2 采纳）**：SnapDrill 无 Domain/UseCase 层（ViewModel 直连 Repository），错误转换的理论收益被扁平架构削弱。ViewModel 对 `DataError.saveFailed` 和 generic `Error` 处理方式相同。多数派 = Codex + Gemini ×2 + Coze；少数派 = GLM4.7 + MiniMax。

**异议**：GLM4.7 和 MiniMax 认为 Repository 层本职是错误转换，应主动包装。

**条件**：如果未来引入 Domain 层或 SwiftData 原生支持 typed throws，重新评估。

## D-002: 项目主权架构重组（2026-04-13）

**决策**：项目知识属于项目（`docs/standards/`），智能体配置只做指针。

**背景**：多智能体协作中出现治理冲突 — Codex 擅自将 .claude/rules/ 搬到 docs/agent/ 并声称接管项目。项目规则被锁在各智能体私有空间。

**原则**：
1. 项目文档是真相（agent-agnostic），任何智能体来了都能读懂
2. 智能体配置是指针（agent-specific），只做引导和格式适配
3. 持久化记忆分两层：项目级记忆（属于项目）vs 智能体级记忆（属于智能体）
4. 人类拥有最高裁决权

## D-003: 抽出 agent-harness 独立仓库（2026-04-22）

**决策**：把自主迭代系统（docaudit / hooks / skills / 文档契约 / 反哺协议）抽到独立仓库 [NotBad-Labs/agent-harness](https://github.com/NotBad-Labs/agent-harness)。snapdrill-ios 既是孵化器（提供实战经验），又是消费者（通过 `.agent-harness/` 接入）。

**战略锚（用户 2026-04-22 拍板）**：
1. 自主迭代系统应**普遍通用**，能被不同项目复用，随项目演进
2. 定位为**any-agent harness**（不自限 Claude Code），但当前实现聚焦 Claude Code + Codex + Gemini
3. 独立仓库 + 直接开空仓 + 双仓并行推进

**三方 cross-audit consensus 共识（Claude / Codex / Gemini）**：
- 独立仓库优于单仓分层（3/3 ✅）
- 形态：CLI 工具 + 模板仓库（2/3 ✅，Codex + Gemini 一致）
- B 档务实骨架（3/3 ✅）
- Phase D 非破坏性消费试点（2/3 ✅，Claude 初提的"删 snapdrill 本地副本"被 override）
- 反哺硬门槛：Codex **two-consumer rule** + Gemini **3 迭代周期** + Claude **去项目化 grep**

**Phase D 落地（2026-04-22 一天全收官）**：
- PR-D1（agent-harness #1）：骨架建仓 + 3 原则契约 + 4 层分层契约
- PR-D2（agent-harness #2）：docaudit 引擎迁入 + 完全参数化（34 tests）
- PR-D3（agent-harness #3）：CLI init / doctor / sync --check（21 tests）
- PR-D4（agent-harness #4）：adapter-claude hooks + skills + settings + policy.starter
- **PR-D5（本 PR）**：snapdrill-ios 消费试点（`.agent-harness/project.yaml` + lock.json）

**异议处理**：
- Claude 原主张"Claude Code 原生 meta-dev-loop"定位被用户 override 为"any-agent"
- Claude 原主张 submodule + symlink 方案被 Codex + Gemini 的 CLI 工具方案 override

**下一步**：Phase E 反哺机制（extract-candidate CLI + harness-introspection skill + 首次反哺实战）

**完整 consensus 归档**：`~/.claude/plans/phase-de-consensus-20260422.md`（Claude 私有记忆）

## D-004: 双统帅架构 + 零信任审计 Phase A 启动（2026-05-14）

**决策**：

1. **双统帅**：Claude Opus 4.7 + Codex GPT-5.5 high effort = 平等决策者，每个技术选型协商达成共识
2. **DeepSeek V4-Pro = 执行者**：单文件贪吃蛇模式串行扫描，curl 直调 API（不走 wrapper agent loop，避免长任务挂死）
3. **Gemini = 参考不裁决**：依 `feedback_gemini_adversarial.md`，Critical 结论必须代码验证
4. **零信任审计范围**：全 50 文件（docs/ 46 + root 4），6 维 rubric（D1 vision-align / D2 cross-ref / D3 code-fact / D4 staleness / D5 structure / D6 redundancy）

**背景**：用户怀疑文档体系不够稳定，要求对除源代码外的全文档体系做零信任独立审计。三方对抗保留 + 互不引用，最大化独立视角。

**实施成果（Phase A 完工）**：
- Codex 第 1 轮全量审：16 finding（1C/6H/8M/1L），覆盖 13 文件
- DeepSeek 贪吃蛇 50 文件：~235 finding（9C/53H/117M/72L），全覆盖
- 总 251 finding，aggregate `~/.claude/plans/audit-findings-20260514/master-findings.tsv`
- 自动 evidence 预筛：17 HIT / 7 MISS / 92 NO_CMD / 120 NOT_GREP

**关键决策点**：

| 议题 | 决策 |
|---|---|
| DeepSeek wrapper vs curl | curl 直调（wrapper agent loop 跑长任务挂死） |
| 单文件 vs batch 粒度 | 单文件（用户原话：「贪吃蛇 + 不能任务量过大」） |
| 互补提示是否污染独立性 | 用 Codex 措辞「已有一轮发现用于最终去重；本轮独立审计，优先报告新证据链和跨文件矛盾」 |
| D3 code-fact 无工具怎么核 | Claude 端预先 `rg` 生成 code-evidence packet 喂 DeepSeek，无证据标 UNVERIFIED |
| 文件顺序 | Codex 提案：依赖优先（CLAUDE/STATUS/vision/workflow/ADR → product → tech → standards → memory → 索引 → root） |
| 重叠低是问题吗 | trade-off 不是问题，Phase 3 按 root cause / 被违反的项目声称归并 |

**附带紧急发现**：CI 三天没跑，根因 ci.yml 缺 push trigger。修复链 5 层洋葱：
1. ci.yml push trigger（commit 51b3c035 已合 develop）
2. PR #749 五轮 emergency fix 解锁 49172637 commit 累积的 build + runtime fatal
3. PR #748 pre-push hook 软治 GitHub Free + private repo 无 branch protection

**Phase 2-5 后续路径**：
- Phase 2: Claude verify-audit-report skill 核验 92 个高优先 finding（9C + 53H + MISS/AMBIGUOUS）
- Phase 3: 三家共识/独有/冲突分类（按 root cause 归并）
- Phase 4: 综合报告 + action-plan.md PR 清单
- Phase 5: PR 批量落地修复

**Codex 第 2 轮按维度 6 批审**：建议等 Claude Phase 2 核验完压成 canonical list 再启动，避免在噪声上消耗配额。维度拆分 = D2 cross-ref / D4 staleness / D3 code-fact / D1 governance / memory drift / D5+D6 structure-redundancy。

**未决技术债**（Codex review 指出）：
- Runtime detection `XCTestConfigurationFilePath` 是 runtime 约定不是编译期边界
- `MainActor.assumeIsolated` 在非 MainActor 测试路径会 trap
- 长期更优解：测试入口给 `-Xswiftc -D -Xswiftc SNAPDRILL_TESTING` 编译期 define

**完整审计归档**：`~/.claude/plans/doc-zero-trust-audit-20260514.md`（plan）+ `~/.claude/plans/audit-findings-20260514/`（产物）
