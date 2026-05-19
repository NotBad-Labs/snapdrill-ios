---
last_verified: 2026-05-19
layer: archive
status: archived
reason: "5/18 Codex 接手任务的 P1-1~P1-6 已全部闭环（commit f40fcdcf 等）；52-doc audit ledger 已从 PENDING 推进到 47/4/1/0；保留作历史溯源"
---

> ⚠️ **已归档**：本 handoff 是 5/18 Codex 接手文档审计修复任务的现场状态，所有 P1 项已闭环（Phase 5.4 finding G）。

# Codex 接手 — 文档审计修复（2026-05-18）

## 背景

三方（Claude + Codex + Gemini）完成 52 文档系统审计。Phase 0-2 完成，部分 P0 已修。

## 审计产物位置

- Rubric: `docs/standards/audit-rubric.md`
- Ledger: `~/.claude/plans/audit-ledger.tsv`（52 文件，全部 PENDING verdict）
- Claude findings: `~/.claude/plans/phase2-claude-batch1.md`, `batch2.md`
- Codex findings: `/private/tmp/phase2-codex-batch1.md` ~ `batch5.md`
- Gemini findings: 在 Claude 会话中，口头报告

## 你的 P1 修复清单（按优先级）

### P1-1: engineering.md ↔ feedback.md SSOT 矛盾 ⚠️ 最高优先
- **问题**: `docs/standards/engineering.md` 行 139/149 仍写"feedback.md 是 SSOT"、"新规则在 feedback.md 加 body"
- **实际**: `docs/memory/feedback.md` 行 7-8 已改为"本文件为索引，权威定义在 skill"
- **修复**: 更新 engineering.md 的 F-XXX 段，将 SSOT 指向改为"权威定义在各 skill/rule 文件，feedback.md 为索引"

### P1-2: KNOWLEDGE_MAP.md 旧 rules 模型
- **问题**: 行 97 写"新 rules 文件…从 feedback 提升为 rule"
- **实际**: .claude/rules/ 已删除，F 规则已 skill 化
- **修复**: 更新入口描述，改为"新 skill 文件…权威定义在 SKILL.md"

### P1-3: deployment.md 内部日期不一致
- **问题**: frontmatter `last_verified: 2026-04-21`，正文内嵌 `Last verified: 2026-05-15`
- **修复**: 统一为 2026-05-18，同时更新 CI 描述以匹配当前 .github/workflows/ci.yml

### P1-4: standards/README.md 缺条目
- **问题**: 缺 `audit-rubric.md`、`execution-gates.md` 条目，last_verified 为 2026-04-14
- **修复**: 补条目，刷新 last_verified

### P1-5: 三个 snapshot 文档 freshness 接近过期
- `docs/tech/api-pitfalls.md` last_verified 2026-04-14 (34天/60天)
- `docs/tech/apple-limits.md` last_verified 2026-04-14 (34天/60天)
- `docs/product/appstore-metadata.md` last_verified 2026-04-16 (32天/60天)
- **修复**: 逐个验证内容仍准确，更新 last_verified 到 2026-05-18

### P1-6: CLAUDE.md + AGENTS.md 冗余
- **问题**: 90%+ 内容重复
- **修复**: 可选——低优先级

## 验证命令

```bash
python3 Scripts/audit/docaudit.py all --strict --baseline  # 必须 exit 0
swiftlint --strict  # 必须 0 violations
```

## 关键原则

- F-008: 独立审计，不依赖 Claude 未写入文件的口头结论
- 每次修改后运行 docaudit 验证
- 只修内容问题，不改文档结构（除非必要）
