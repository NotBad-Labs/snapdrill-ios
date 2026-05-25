---
last_verified: 2026-05-23
derived_from: [M-000 §3, M-001]
layer: pattern
scope: workflow
paths:
  M0: docs/meta/M-000-meta-vision.md
  log: docs/meta/user-decision-log.md
  sprint: .claude/skills/sprint-contract/SKILL.md
  gates: docs/standards/execution-gates.md
  audit: .claude/skills/cross-audit/SKILL.md
  postmerge: .claude/skills/post-merge/SKILL.md
freshness:
  max_age_days: 365
  decay_trigger: [meta_vision_change]
---
# Protocol

> M-000 §3 派生；Action Gate。路径见 frontmatter `paths`。

Plan:不清/取舍->M0+log
Code:改代码/文档->sprint
DoD:lint/test前->gates
Review:PR/合并前->audit
Merge:合并/直推前->postmerge

<!-- nwc: 172 -->
