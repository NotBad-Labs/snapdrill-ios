#!/usr/bin/env python3
"""F-005 PR Review Trace 校验器（S-D7-002 共识落地）。

校验 PR body 含 `## F-005 Review Trace` 字段化段 + 占位符防御 + 路径豁免规则。

使用方式：
    python3 Scripts/audit/pr_review_trace.py --pr 742
    python3 Scripts/audit/pr_review_trace.py --pr 742 --policy .github/review-trace-policy.yml
    python3 Scripts/audit/pr_review_trace.py --commit-range origin/develop..HEAD  # 直推路径

Override（紧急）：
    F005_REVIEW_TRACE_OVERRIDE=1 python3 Scripts/audit/pr_review_trace.py ...
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

SECTION_RE = re.compile(r"^## F-005 Review Trace\s*$", re.M)
FIELD_RE = re.compile(r"^([A-Za-z][A-Za-z \-]+):\s*(.*?)\s*$")


def run(cmd: list[str]) -> str:
    """Run shell command, return stripped stdout. Raises on failure."""
    return subprocess.check_output(cmd, text=True).strip()


def pr_body(pr: str) -> str:
    return run(["gh", "pr", "view", pr, "--json", "body", "--jq", ".body // \"\""])


def changed_paths(pr: str) -> list[str]:
    out = run(["gh", "pr", "diff", pr, "--name-only"])
    return [line.strip() for line in out.splitlines() if line.strip()]


def commit_range_files(commit_range: str) -> list[str]:
    """For direct-push paths: enumerate changed files in commit range."""
    out = run(["git", "diff", "--name-only", commit_range])
    return [line.strip() for line in out.splitlines() if line.strip()]


def commit_range_msgs(commit_range: str) -> str:
    """For direct-push paths: concat commit messages in range."""
    return run(["git", "log", "--format=%B", commit_range])


def parse_trace(body: str) -> dict[str, str]:
    """Extract Review Trace fields. Raises ValueError if section missing."""
    match = SECTION_RE.search(body)
    if not match:
        raise ValueError("missing required section: ## F-005 Review Trace")
    block = body[match.end():]
    next_heading = re.search(r"^##\s+", block, re.M)
    if next_heading:
        block = block[:next_heading.start()]
    fields: dict[str, str] = {}
    for line in block.splitlines():
        m = FIELD_RE.match(line.strip())
        if m:
            fields[m.group(1)] = m.group(2)
    return fields


def _glob_to_regex(pattern: str) -> str:
    """Convert glob with ** support to regex.

    fnmatch.fnmatch 不支持 ** 跨目录匹配。本实现：
    - `**/` → 0 或多层目录段
    - `**` 在末尾 → 任意（含 0 层）后续路径
    - `*` → 单段不含 `/` 的字符序列
    - `?` → 单字符不含 `/`
    """
    out: list[str] = []
    i = 0
    n = len(pattern)
    while i < n:
        c = pattern[i]
        if c == "*" and i + 1 < n and pattern[i + 1] == "*":
            # `**`
            if i + 2 < n and pattern[i + 2] == "/":
                # `**/` 0 或多层目录
                out.append("(?:.*/)?")
                i += 3
            else:
                # `**` 末尾或独立 ** 段
                out.append(".*")
                i += 2
        elif c == "*":
            out.append("[^/]*")
            i += 1
        elif c == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    return "^" + "".join(out) + "$"


def matches_any(path: str, globs: list[str]) -> bool:
    for pattern in globs:
        if "**" in pattern:
            if re.match(_glob_to_regex(pattern), path):
                return True
        elif fnmatch.fnmatch(path, pattern):
            return True
    return False


def is_placeholder(value: str, patterns: list[str]) -> bool:
    """Antigravity-derived placeholder defense for Evidence fields."""
    if not value:
        return True
    for pat in patterns:
        try:
            if re.search(pat, value, re.IGNORECASE):
                return True
        except re.error:
            continue
    return False


def validate_exemption(fields: dict[str, str], paths: list[str], policy: dict) -> list[str]:
    errors: list[str] = []
    exemption = fields.get("Review Exemption", "")
    rule = policy["exemptions"].get(exemption)
    if not rule:
        return [f"unknown Review Exemption: {exemption!r}"]
    denied = [p for p in paths if matches_any(p, rule.get("denied_globs", []))]
    allowed = [p for p in paths if matches_any(p, rule.get("allowed_globs", []))]
    if denied:
        errors.append("review exemption denied for paths: " + ", ".join(denied))
    if len(allowed) != len(paths):
        non_allowed = sorted(set(paths) - set(allowed))
        errors.append("review exemption has non-allowed paths: " + ", ".join(non_allowed))
    if "max_files" in rule and len(paths) > int(rule["max_files"]):
        errors.append(
            f"review exemption {exemption} allows max_files={rule['max_files']}, got {len(paths)}"
        )
    for key in rule.get("required_fields", []):
        if not fields.get(key):
            errors.append(f"missing exemption field: {key}")
    if fields.get("Disallowed Paths Present", "").lower() not in {"", "no"}:
        if fields.get("Disallowed Paths Present", "").lower() != "no":
            errors.append("Disallowed Paths Present must be 'no' when exempted")
    return errors


def validate_normal(fields: dict[str, str], paths: list[str], policy: dict) -> list[str]:
    errors: list[str] = []
    normal = policy["normal_review"]
    placeholders = policy.get("placeholder_patterns", [])

    for key in normal["required_fields"]:
        if not fields.get(key):
            errors.append(f"missing review field: {key}")

    verdict = fields.get("Codex Review", "")
    if verdict not in normal["accepted_verdicts"]:
        errors.append(
            f"Codex Review must be one of {normal['accepted_verdicts']}, got {verdict!r}"
        )

    # Codex Evidence: 必须非空 + 占位符防御（Antigravity 增强）
    codex_evidence = fields.get("Codex Evidence", "")
    if is_placeholder(codex_evidence, placeholders):
        errors.append(
            f"Codex Evidence is placeholder or empty: {codex_evidence!r}; "
            "fill in PR comment URL, report path, or commit SHA"
        )

    if fields.get("Findings Resolved", "").lower() != "yes":
        errors.append("Findings Resolved must be 'yes'")
    if fields.get("Human Merge Approval", "").lower() != "yes":
        errors.append("Human Merge Approval must be 'yes'")

    # UI-impacting check
    ui_policy = policy["ui_review"]
    ui_paths = [p for p in paths if matches_any(p, ui_policy["path_globs"])]
    if ui_paths:
        xcode_verdict = fields.get("Xcode Review", "")
        if xcode_verdict not in ui_policy["ui_accepted_verdicts"]:
            errors.append(
                f"UI-impacting PR requires Xcode Review in "
                f"{ui_policy['ui_accepted_verdicts']}, got {xcode_verdict!r}; "
                f"UI paths: {', '.join(ui_paths)}"
            )
        xcode_evidence = fields.get("Xcode Evidence", "")
        if is_placeholder(xcode_evidence, placeholders):
            errors.append(
                f"Xcode Evidence is placeholder or empty: {xcode_evidence!r}"
            )
    return errors


def validate(body: str, paths: list[str], policy: dict) -> list[str]:
    try:
        fields = parse_trace(body)
    except ValueError as exc:
        return [str(exc)]
    for key in policy["required_fields"]:
        if not fields.get(key):
            return [f"missing required field: {key}"]
    required = fields.get("Review Required", "").lower()
    if required == "exempt":
        return validate_exemption(fields, paths, policy)
    if required == "yes":
        return validate_normal(fields, paths, policy)
    return [f"Review Required must be 'yes' or 'exempt', got {required!r}"]


def validate_direct_push(
    commit_range: str, paths: list[str], policy: dict
) -> list[str]:
    """Direct-push path: check commit msgs for F-005 trailer or all paths exempted."""
    # 若全部文件都满足 docs-only 豁免路径，等价豁免（不需要 trailer）
    docs_only = policy["exemptions"]["docs-only"]
    docs_only_allowed = docs_only.get("allowed_globs", [])
    docs_only_denied = docs_only.get("denied_globs", [])
    fully_docs_only = paths and all(matches_any(p, docs_only_allowed) for p in paths)
    has_denied = any(matches_any(p, docs_only_denied) for p in paths)
    if fully_docs_only and not has_denied:
        return []

    trailer = policy["direct_push"]["commit_msg_trailer"]
    msgs = commit_range_msgs(commit_range)
    if trailer.lower() not in msgs.lower():
        return [
            f"Direct push to protected branch requires commit trailer: {trailer}",
            f"Or restrict the push to docs-only paths.",
        ]
    return []


def main() -> int:
    parser = argparse.ArgumentParser(description="F-005 PR review trace validator")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--pr", help="PR number to validate")
    group.add_argument(
        "--commit-range",
        help="Direct-push validation: commit range like origin/develop..HEAD",
    )
    parser.add_argument(
        "--policy", default=".github/review-trace-policy.yml", help="Policy YAML path"
    )
    parser.add_argument(
        "--body-stdin",
        action="store_true",
        help="Read PR body from stdin (for testing without gh CLI)",
    )
    parser.add_argument(
        "--paths-file",
        help="Read changed paths from file (one per line; for testing)",
    )
    args = parser.parse_args()

    if os.environ.get("F005_REVIEW_TRACE_OVERRIDE") == "1":
        print(
            "⚠️  F005_REVIEW_TRACE_OVERRIDE=1 — bypassing F-005 review trace check. "
            "PR body MUST be patched with Review Trace before next merge.",
            file=sys.stderr,
        )
        return 0

    policy_path = Path(args.policy)
    if not policy_path.exists():
        print(f"policy file not found: {policy_path}", file=sys.stderr)
        return 2
    policy = yaml.safe_load(policy_path.read_text(encoding="utf-8"))

    try:
        if args.commit_range:
            paths = (
                [line.strip() for line in Path(args.paths_file).read_text().splitlines() if line.strip()]
                if args.paths_file
                else commit_range_files(args.commit_range)
            )
            errors = validate_direct_push(args.commit_range, paths, policy)
        else:
            body = (
                sys.stdin.read()
                if args.body_stdin
                else pr_body(args.pr)
            )
            paths = (
                [line.strip() for line in Path(args.paths_file).read_text().splitlines() if line.strip()]
                if args.paths_file
                else changed_paths(args.pr)
            )
            errors = validate(body, paths, policy)
    except Exception as exc:
        errors = [f"{type(exc).__name__}: {exc}"]

    if errors:
        print("F-005 review trace check FAILED:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        print("", file=sys.stderr)
        print("Add a standard '## F-005 Review Trace' block to PR body.", file=sys.stderr)
        print("Format spec: .github/review-trace-policy.yml + PR template.", file=sys.stderr)
        print("Override: F005_REVIEW_TRACE_OVERRIDE=1 (audit trail in stderr).", file=sys.stderr)
        return 1
    print("F-005 review trace check PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
