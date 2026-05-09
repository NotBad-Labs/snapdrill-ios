---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 5: 智能体治理体系审计

## Goal

审计 rules、skills、hooks、settings、workflow、feedback、agent-harness 契约的完整性和一致性。

## Scope

44 文件：.claude/rules(13) + .claude/skills(11) + .claude/hooks(10) + settings.json(1) + workflow.md(1) + feedback.md(1) + agent-harness(4) + CLAUDE.md + CODEX.md

## Findings

### Warning (5)

**W1: 2 个 docs/principles/ 文件无 .claude/rules/ 路由**
- `docs/principles/memory-routing.md` — 无对应 `.claude/rules/memory-routing.md`
- `docs/principles/review-prompt-guide.md` — 无对应 `.claude/rules/review-prompt-guide.md`
- 后果：这两个文件不会被 Claude Code 的规则系统自动加载到上下文
- review-prompt-guide.md 被 pr-review-workflow skill 引用，但缺乏自动路由
- memory-routing.md 定义了"哪类内容写哪里"的关键路由规则，但 Agent 不会自动读到

**W2: security-engineer skill 缺少 Bash 权限**
- `allowed-tools: WebSearch, Read, Grep, Glob`
- 安全工程师的职责包括"Keychain 审查、数据持久化安全、网络通信安全"
- 无法运行安全扫描脚本、检查 Keychain 状态、验证文件权限
- 这是功能缺口

**W3: agent-harness overlay 声明不完整 — 7 个 skill 未声明归属**
- project.yaml 仅声明 4 个 skill 为 snapdrill-ios overlay：developer、devops、qa-engineer、security-engineer
- 7 个 skill 既不在 overlay 路径中，也未从 upstream 获取：cross-audit、cross-audit-consensus、knowledge-health、phase-closeout、pr-review-workflow、resume-from-handoff、update-status
- 当前"并行模式"下这些 skill 存在于本地但归属不明
- 如果未来激活 agent-harness symlink，可能发生冲突

**W4: F-005（对抗审查）无自动化合并前门禁**
- F-005 是产品质量最关键的纪律之一："完成前必须对抗性审查"
- 当前落地：cross-audit skill（手动调用）+ workflow.md DoD 清单
- 缺失：没有 hook 确保 PR 合并前完成了对抗审查
- 对比：F-007（CI 双时点门禁）有 premerge-checklist + prepush-lint hook 落地，F-005 缺乏同等自动化

**W5: 5 条活跃 F 规则完全依赖行为纪律，无自动化强制**
- F-001（Git 工作流）：无 hook 防止无 Issue/无分支开发
- F-006（深度读源码）：纯行为纪律
- F-011/F-012/F-017：纯行为纪律
- 部分规则（F-001、F-016、F-018）理论上可通过 hook 强制执行，但当前仅靠人工遵守

### Info (3)

**I1: settings.json 无显式 permission 块**
- 所有工具权限通过 hook 系统隐式管理（block-dangerous-bash + docaudit-preflight）
- permission-model.md 定义了完整的 T1/T2/T3 权限矩阵
- 但 settings.json 中无 `permissions` 字段
- 当前通过 hook 实现的功能等效，但缺少声明式权限配置

**I2: hook 触发条件存在冗余和性能问题**
- `docaudit-preflight.sh` 在 `git rebase` 上触发不合理
- `session-metrics.sh` 匹配 `.*`（每次工具调用后执行）
- `gh pr merge` 触发双门控：premerge-checklist + docaudit-preflight 依次执行

**I3: codex-delegation.md 中的 --effort 参数已过时**
- 文档建议 `--effort high` 用于审计任务
- Codex CLI 0.130.0 的 `exec` 子命令不支持 `--effort` 标志
- 实际可用的是 `-m gpt-5.5` 模型选择，无 effort 级别

## Positive Findings

- ✅ 13 条 rules 全部正确路由到存在的 docs/principles/ 文件（零死引用）
- ✅ 11 个 skills 全部有 SKILL.md + allowed-tools 声明
- ✅ 10 个 hooks 全部存在且功能明确
- ✅ feedback.md 退役规则全部保留墓碑指针，外部引用安全
- ✅ workflow.md 覆盖完整（DoD、S0-S3、审计协议、Phase Compaction）
- ✅ clause/rules/ 和 docs/principles/ 的双层架构（路由+源）设计合理
- ✅ block-dangerous-bash.sh 覆盖了关键高危命令
- ✅ swift-autolint + prepush-lint 形成 lint 双重保障

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 正确性 | 7/10 | 核心机制有效，但 2 个文件无路由、codex doc 过时 |
| 完整性 | 6/10 | F-005 缺自动化门禁、5 条 F 规则缺强制、7 个 skill 归属不明 |
| 一致性 | 7/10 | 双层架构一致，但 agent-harness overlay 不全、permission 实现偏离 |
| 可维护性 | 7/10 | Hook 之间有冗余、部分文档过时 |
| **综合** | **6.8/10** | |

## Next

全部 7 步审计完成。进入综合汇总。
