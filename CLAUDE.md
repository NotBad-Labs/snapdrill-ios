---
last_verified: 2026-05-26
layer: entry
scope: claude-adapter
derived_from: [M-000]
freshness:
  max_age_days: 180
  decay_trigger: [boot_sequence_change, m_000_revision, claude_code_version_change]
---
@AGENTS.md

# Claude Code

This file is a Claude Code adapter, not a separate knowledge source. Shared Boot, Action Gate, Context Map, and project instructions live in `AGENTS.md` and `docs/`.

## Claude-Specific Context

- Project skills are discovered from `.claude/skills/`; shared cross-agent skills live in `.agents/skills/`.
- Claude-only runtime configuration stays under `.claude/` (`hooks/`, `settings.json`, `compact-reminder.md`).
- Personal or local Claude state must stay out of git (`.claude/settings.local.json`, `.claude/session-log.txt`, `CLAUDE.local.md`).

## Skill Routing

- Use `.agents/skills/` as the SSOT for portable skills that do not depend on Claude-only frontmatter or hooks.
- Keep Claude governance skills in `.claude/skills/` when they depend on Claude Code concepts such as hooks, `allowed-tools`, `context: fork`, or private Claude planning paths.
- Do not use symlinked `.claude/skills` as the migration mechanism until it has been verified in the current Claude Code version.
