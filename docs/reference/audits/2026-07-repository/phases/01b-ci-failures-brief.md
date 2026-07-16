# Phase 01b Brief: CI Failure and Rerun Taxonomy

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Evidence

- base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Actions runs: `/private/tmp/snapdrill-repository-audit-phase01/runs.json` (`1,881`, SHA-256 `77592057257f00f4f9b9b6d1506ff0d44e06e5fdc100a84d60e56a36629d5381`)
- workflows: `/private/tmp/snapdrill-repository-audit-phase01/workflows.json`
- issue/PR metadata: sibling JSON files in the same directory

## Question

What portion of 506 failed runs is plausibly product failure, test/runner flake, expected iterative failure, configuration churn or duplicate rerun? Build a defensible taxonomy instead of treating every red run as waste.

## Rules

- New session; do not read other agent reports, private memory or chat history.
- Start with local JSON using `jq`/Python. You may use authenticated read-only `gh api` for at most 40 carefully selected run/job requests; record every endpoint. Do not download all logs.
- Stratify samples across time, workflow, event, branch, run attempt and failure streak. Avoid convenience sampling of only recent runs.
- Distinguish metadata facts from root-cause inference. A run title is not a failure reason.
- Identify the smallest additional sample needed to tighten uncertainty.
- No edits, reruns, dispatches, cancellations or GitHub mutations.

## Output

Return Markdown with Metadata, Sampling Method, Taxonomy With Counts/Ranges, High-Cost Clusters, Evidence Against the Waste Hypothesis, Candidate Findings, Uncertainty and Handoff. Every candidate needs run IDs/URLs and a C1 reproduction command.
