# External Agent Invocation Protocol

> Validated 2026-07-16 for the repository audit. This file records the exact local CLI contracts used by Codex C1; it does not grant any external agent write, merge or release authority.

## Sources

- Claude Code CLI reference: <https://code.claude.com/docs/en/cli-usage>
- Claude Code permission modes: <https://code.claude.com/docs/en/permission-modes>
- Antigravity CLI reference: <https://antigravity.google/docs/cli-reference>
- Antigravity sandbox: <https://antigravity.google/docs/cli-sandbox>
- Antigravity troubleshooting: <https://antigravity.google/docs/cli-troubleshooting>
- Grok CLI reference: <https://docs.x.ai/build/cli/reference>
- Grok headless/scripting: <https://docs.x.ai/build/cli/headless-scripting>

The installed binary's `--help` remains the final compatibility check for the pinned local version. A public page can describe a newer CLI than the current machine.

## Common Rules

1. Before transmitting private repository material, record explicit PO authorization for the vendor and
   smallest required payload. Subscription access is not data-export authorization.
2. Build a minimal auditable input directory. Exclude secrets, user data, signing material, auth/debug logs
   and unrelated source or evidence.
3. Run `--version` and the model-list command before the first slice of a phase.
4. Pin the product base and working directory explicitly; do not let a CLI search parent folders for the repository.
5. Use a new, non-resumed session for each blind slice. Disable memory, subagents, plugins/MCP and web access where the CLI exposes such controls.
6. Give reviewers read-only tools only. A natural-language “do not edit” instruction is not a substitute for a tool/sandbox restriction.
7. External output is candidate evidence. C1 reopens every cited path and reproduces the claim before it enters `findings.md`.
8. Raw transcript/debug/brain artifacts stay temporary and are removed after normalization. Never retain auth/debug logs: they may contain credentials.
9. After every external run, confirm the audit worktree and main checkout have no new tracked or untracked changes attributable to the reviewer.

## Claude Code 2.1.206

Official docs distinguish `--allowedTools` from `--tools`: the former only pre-approves matching tools, while the latter restricts the available built-ins. Audit calls therefore use `--tools`.

```bash
claude \
  --safe-mode \
  --strict-mcp-config \
  --permission-mode plan \
  --tools 'Read,Grep,Glob' \
  --disallowedTools 'mcp__*' \
  --no-session-persistence \
  --model 'claude-fable-5[1m]' \
  --effort high \
  --output-format text \
  -p "$PROMPT"
```

- `--safe-mode` disables CLAUDE.md auto-loading, skills, plugins, hooks, MCP and auto-memory for this invocation. The reviewer may still read an in-scope file explicitly.
- `--no-session-persistence` prevents the print-mode conversation from becoming resumable local state.
- Smoke result: with the audit worktree as cwd, the command read `AGENTS.md` and returned its exact first heading without creating files.

## Antigravity 1.1.2

Antigravity uses project/workspace scoping. Running from an unregistered `/private/tmp` worktree once caused
it to search unrelated parent/user directories. Use a fresh project plus an explicit minimal directory:
an isolated supplied-doc directory for narrow review, or a dedicated clean fixed-base worktree for a repository
audit. Never use the dirty main checkout merely to satisfy project discovery; discard any run that leaves the
explicit directory.

```bash
AGY_CLI_DISABLE_AUTO_UPDATE=true agy \
  --new-project \
  --add-dir "$FIXED_BASE_CHECKOUT" \
  --mode plan \
  --sandbox \
  --model 'Gemini 3.5 Flash (High)' \
  --print-timeout 15m \
  --print "$PROMPT"
```

- Put all flags before `--print`; in this CLI version `--print` consumes the following argument as the prompt. Placing `--mode` after it caused the agent to answer a question about `--mode` instead of running the audit.
- `--new-project` avoids resuming prior project conversation context; `--add-dir` fixes the readable workspace.
- `--mode plan` and `--sandbox` are the available hard controls in 1.1.2. The prompt must also prohibit network access and artifact creation; any generated Antigravity brain artifact is temporary output, not repository evidence.
- `AGY_CLI_DISABLE_AUTO_UPDATE=true` follows the official troubleshooting guidance and prevents a background updater from changing the tool during a scripted phase.
- Smoke result: from `develop@d62fead8`, the command read `AGENTS.md` and returned its exact first heading without repository changes.

## Grok CLI 0.2.101

```bash
grok \
  --no-auto-update \
  --cwd "$AUDIT_WORKTREE" \
  --model grok-4.5 \
  --reasoning-effort high \
  --permission-mode plan \
  --tools Read,Grep,Glob \
  --no-memory \
  --no-subagents \
  --disable-web-search \
  --verbatim \
  --output-format plain \
  -p "$PROMPT"
```

- `--permission-mode plan` and the read-only tool list provide separate controls. An authenticated 0.2.101
  smoke with fixed `grok-4.5` returned the requested sentinel without tool use; the temporary session was
  deleted afterward.
- `grok models` must show `grok-4.5` before the phase. A one-time debug smoke confirmed `currentModelId=grok-4.5`, high reasoning effort and response metadata `modelId=grok-4.5`; the debug file was then deleted because debug logs can include auth material.
- `--no-auto-update` is the official headless recommendation; `--no-memory`, `--no-subagents` and `--disable-web-search` make the independent reviewer boundary explicit.
- The current repository is larger than Grok's 50 MiB automatic bundle limit because of UI evidence. `bundle_create_failed` is non-fatal for local Read/Grep/Glob, but must be reported if it accompanies an incomplete audit.

## Invalid Runs

Discard a run rather than repairing its prose when any of these occurs:

- wrong model or unresolved fallback;
- prompt parsed as a CLI-help question;
- workspace/path search leaves the fixed repository;
- forbidden write, network, memory or subagent use;
- output lacks enough `path:line` evidence for C1 reproduction;
- timeout or partial report presented as complete.
