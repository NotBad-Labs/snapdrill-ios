---
last_verified: 2026-05-18
layer: pattern
---
# 执行门禁总表（Execution Gates SSOT）

> 每个执行门禁必须能追溯到 docs/ 中的上游文档说明其存在理由。
> 本表是门禁清单的单一真相源。新增/修改/退役门禁时必须同步更新本表。

## 1. CI 门禁

| 门禁 | 触发点 | 执行器 | 失败语义 | 上游文档 | Owner |
|---|---|---|---|---|---|
| Docs Audit | PR → develop/main, push → develop/main | `.github/workflows/ci.yml` → `docaudit all --strict --baseline` | 阻断合并（error 级） | `docs/workflow.md` §文档审计, `Scripts/audit/README.md` | docaudit policy |
| Build & Test | PR → develop/main, push → develop/main | `.github/workflows/ci.yml` → `xcodebuild build-for-testing + test-without-building` | 阻断合并 | `docs/workflow.md` DoD, `docs/tech/deployment.md` | CI runner |
| SwiftLint | CI build job step | `swiftlint --strict` | 阻断合并 | `docs/workflow.md:70`（原则 4）, `docs/standards/coding.md` | `.swiftlint.yml` |

## 2. docaudit 子检查

| 子命令 | 级别 | 检查什么 | 为什么存在 | 上游文档 | 豁免方式 |
|---|---|---|---|---|---|
| `links` | error | Markdown 内部引用指向不存在的文件 | 文档间引用断链导致信息不可达 | `docs/DOC_DEPENDENCY_MAP.md:28`（文档→代码锚点）, `docs/workflow.md:167` | 无豁免（error 级必须修复） |
| `archived-refs` | error | 对已归档研究的旧路径硬引用 | 旧路径误导新维护者，归档文件只能通过新路径叙述性引用 | `docs/archive/README.md:21-24`, `docs/DOC_DEPENDENCY_MAP.md` 传播规则 | `policy.yaml` legacy_whitelist（过渡期） |
| `orphans` | warning | docs/**/*.md 在全仓零引用 | 孤儿文档无人维护，内容可能严重过时 | `docs/standards/memory-routing.md`（反模式：信息无归属）, `docs/KNOWLEDGE_MAP.md` 索引职责 | `policy.yaml` orphans.whitelist（产品文档/归档/索引自身豁免） |
| `home-path-refs` | warning | 仓库内对 `~/.claude/` 私有路径的硬编码 | 私有路径其他智能体（Codex/Gemini）读不到，产生单点依赖 | `docs/standards/memory-routing.md:38-44`（公开 vs 私有分离原则） | `policy.yaml` allowed_contexts + legacy_whitelist |
| `rule-pointer-sync` | error | `.claude/rules/*.md` 必须指向存在的 docs/standards/ 或 docs/tech/ 文件（或为自包含 F 规则） | 防止 rule 指针目标漂移。`.claude/rules/` 已精简为 3 个自包含 F 规则 | `docs/standards/engineering.md:122-156`（F-XXX 编号规则）, 本表 | `policy.yaml` allowlist_rules（自包含 F 规则 `f-*`） |
| `rule-usage` | info | F-NNN 规则在全仓的外部引用计数（0 引用 → dead rule 候选） | 防止退役规则残留、F 规则体系膨胀 | `docs/standards/engineering.md:122-156`（F-XXX 生命周期） | 无（info 级，不阻断） |

## 3. SwiftLint 规则族

> 具体规则配置见 `.swiftlint.yml`。本表只解释**规则族的上游原则**，不逐条镜像配置。

| 规则族 | 代表规则 | 为什么存在 | 上游文档 |
|---|---|---|---|
| Safety | `force_unwrapping: error`, `force_cast: warning` | 编译期不能拦的运行时崩溃 | `docs/workflow.md:70`（原则 4：编译器能拦的不留到运行时） |
| Complexity | `file_length`, `function_body_length`, `cyclomatic_complexity`, `nesting` | 单文件/函数过大导致认知负担和合并冲突 | `docs/standards/coding.md:77-78`（file_length 600 硬限）, `docs/standards/engineering.md` 原则 2（删掉比添加好） |
| Structure | `type_body_length` | 类型职责过重 | `docs/standards/coding.md:70-77`（单文件单主类型） |
| Style | `empty_count`, `first_where`, `redundant_nil_coalescing`, `operator_usage_whitespace`, `switch_case_alignment` | 代码风格一致性 | `docs/standards/coding.md`, `docs/standards/collaboration.md:66`（反复出现→提升为自动化门禁） |
| Diagnostics | `fatal_error_message`, `yoda_condition` | 调试信息完整性和可读性 | `docs/standards/coding.md` |

## 4. Git Hooks

| Hook | 事件 | 职责 | 级别 | 上游文档 |
|---|---|---|---|---|
| `block-dangerous-bash.sh` | PreToolUse Bash | 拦截 `rm -rf /`, `git push --force`, `git reset --hard` 等危险命令 | **T3 守门** | `docs/standards/permission-model.md` §2 |
| `swift-autolint.sh` | PostToolUse Edit/Write | 改 `.swift` 后即时 lint | T2 校验 | `docs/workflow.md:70`, `docs/standards/coding.md` |
| `docaudit-on-doc-edit.sh` | PostToolUse Edit/Write | 改 docs `.md` 后即时 `docaudit links` | T2 校验 | `docs/workflow.md:167`, `docs/DOC_DEPENDENCY_MAP.md` |
| `prepush-lint.sh` | PreToolUse Bash (`git push`) | push 前全仓 swiftlint | T2 合并门禁 | `docs/workflow.md:70` |
| `premerge-checklist.sh` | PreToolUse Bash (`gh pr merge`) | merge 前检查 STATUS.md 近 24h 更新 | T2 合并门禁 | `docs/workflow.md` DoD |
| `docaudit-preflight.sh` | PreToolUse Bash (`git push`/`gh pr merge`/`commit --amend`) | 关键 git 操作前跑 `docaudit all --strict --baseline` | T2 合并门禁 | `docs/workflow.md:167` |
| `post-merge-checkpoint.sh` | PostToolUse Bash (`gh pr merge`) | merge 后提示反模式扫描 | T2 观察 | `docs/memory/feedback.md` F-019, `docs/standards/harness-recall.md` |
| `log-file-change.sh` | PostToolUse Edit/Write | 记录改动文件到 session-log | T1 观察 | `docs/standards/permission-model.md` §3 |
| `session-metrics.sh` | PostToolUse `.*` | 记录所有 tool call 时间戳 | T1 观察 | `docs/standards/permission-model.md` §3 |
| `long-session-guard.sh` | PreToolUse Bash | 会话 > 60 min 提示 compact | T1 观察 | `docs/workflow.md`（WIP 约束） |
| `compact-reminder.md` | SessionStart (`compact`) | 压缩后重载上下文提示 | T1 | `docs/standards/permission-model.md` §3 |

## 5. Skill 执行门禁

> 角色类 skill（developer/qa-engineer/devops/security-engineer）不在此列——它们是行为指南，不阻断流程。
> 本表仅列**有强制执行语义**的 skill。

| Skill | 触发时机 | 强制执行什么 | 上游文档 |
|---|---|---|---|
| `sprint-contract` | Issue 进入 Building | F-018 编码前契约（Touches/No-Touch/Interface Delta/Test Additions/DoD） | `docs/workflow.md` §编码前契约, F-013, F-014 |
| `cross-audit` | 审计启动/PR 合并前 | F-008 三方相同任务 + F-011 审计只读 + F-016 质疑方批准 | `docs/standards/collaboration.md`, F-005 |
| `verify-audit-report` | 收到审计报告后 | F-006 深度验证 + F-012 全量做 | `docs/standards/collaboration.md` |
| `post-merge` | PR 合并后 | F-007 CI 双时点 + F-019 反模式回流 | `docs/workflow.md` DoD |
| `api-research` | UI/SDK 改动前 | F-017 Apple 最新文档调研 | `docs/standards/engineering.md` 原则 1, `docs/standards/apple-native.md` |
| `snapshot-diff-review` | Snapshot baseline 变更时 | 人工审查 visual diff 确认变更有意 | `docs/standards/testing.md:90-97`, `docs/workflow.md:127` |
| `dependency-propagation` | 文档变更后 | DOC_DEPENDENCY_MAP.md 下游同步 | `docs/DOC_DEPENDENCY_MAP.md` |
| `phase-closeout` | phase 收官 | handoff.md 状态更新 + Harness Recall + knowledge-health | `docs/workflow.md` §长任务, `docs/standards/harness-recall.md` |
| `update-status` | PR 合并后 | STATUS.md 直推 develop（文档化例外） | `docs/workflow.md:61`（STATUS.md 例外） |
| `resume-from-handoff` | 新会话接手 | 最小上下文加载顺序 | `docs/workflow.md` §Boot, `docs/memory/handoff.md` |

## 6. xcodebuild 门禁

| 门禁 | 命令 | 失败语义 | 上游文档 |
|---|---|---|---|
| Build for Testing | `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` | 阻断合并 | `docs/workflow.md` DoD（原则 4）, CLAUDE.md 执行门 |

## 7. 维护规则

1. **新增门禁**：必须先在本表登记（名称/触发点/执行器/上游文档），再落地实现
2. **修改门禁**：实现变更后 24h 内同步本表
3. **退役门禁**：保留行但标注 `[retired YYYY-MM-DD]` + 去向，不物理删除
4. **本表自身**：受 `docs/KNOWLEDGE_MAP.md` 索引，受 `docs/DOC_DEPENDENCY_MAP.md` 传播规则约束
5. **验证命令**：`python3 Scripts/audit/docaudit.py all --strict --baseline` 须 exit 0
