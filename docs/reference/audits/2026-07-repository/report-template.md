# Agent Report Template

```yaml
phase: "00b"
agent: "codex|claude|antigravity|grok"
model: "exact model id"
cli_version: "exact version"
base_sha: "40-char sha"
started_at: "ISO-8601"
completed_at: "ISO-8601"
outcome: "COMPLETE|PARTIAL|BLOCKED"
scope:
  - "path or contract"
excluded:
  - "explicit exclusion"
commands_run:
  - "exact read-only command"
```

## Coverage

列出实际读取的主要文件、未覆盖内容和原因。不得用“已审计全仓”替代文件集。

## Findings

每条候选项使用以下字段：

```yaml
id: "<phase>-<agent>-NN"
severity: "P0|P1|P2|P3"
category: "correctness|data|security|privacy|architecture|ui|test|ci|docs|release|waste"
claim: "one falsifiable sentence"
expected: "upstream requirement or invariant"
actual: "observed behavior"
evidence:
  - "path:line"
reproduction:
  - "exact command or deterministic steps"
impact: "specific consequence"
confidence: "high|medium|low"
next_check: "smallest independent verification"
```

无 finding 时明确写 `No findings`。不得为了报告非空而降格制造问题。

## Hypotheses

只放缺少直接证据的疑点，说明还缺什么；不得混入 Findings。

## Rejected During Review

记录已被上游 guard、测试、代码或范围排除推翻的候选项，避免下一方重复消耗。

## Handoff

只写下一条可执行核验命令、阻塞和需要的 PO 裁决。不得在报告中自行授权修复、合并或发布。
