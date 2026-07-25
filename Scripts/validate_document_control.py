#!/usr/bin/env python3
"""Validate Markdown classification, lifecycle markers, and local links."""
from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parent.parent
REGISTRY_PATH = REPO_ROOT / "docs" / "reference" / "document-control.json"

VALID_ROLE_LIFECYCLES = {
    "authority": {"effective", "candidate", "superseded", "suspended"},
    "operations": {"current", "superseded"},
    "evidence": {"current", "candidate", "frozen", "superseded"},
    "generated": {"current"},
    "template": {"current"},
    "alias": {"current"},
}
REQUIRED_ASSIGNMENTS = {
    "README.md": ("evidence", "current"),
    "AGENTS.md": ("operations", "current"),
    "docs/README.md": ("operations", "current"),
    "docs/product/vision.md": ("authority", "effective"),
    "docs/product/release-1-prd.md": ("authority", "effective"),
    "docs/reference/analytics-events.md": ("evidence", "current"),
    "docs/reference/feature-status.md": ("generated", "current"),
    "docs/reference/intent-traceability.md": ("generated", "current"),
}

INLINE_LINK_PATTERN = re.compile(
    r"!?\[[^\]\n]*\]\(\s*(?P<target><[^>\n]+>|[^)\s\n]+)"
)
REFERENCE_LINK_PATTERN = re.compile(
    r"^\s*\[[^\]\n]+\]:\s*(?P<target><[^>\n]+>|\S+)",
    re.MULTILINE,
)
HEADING_PATTERN = re.compile(r"^#{1,6}\s+(.+?)\s*$", re.MULTILINE)
WIKI_LINK_PATTERN = re.compile(r"\[\[[^\]\n]+\]\]")
EXTERNAL_PREFIXES = (
    "http://",
    "https://",
    "mailto:",
    "tel:",
    "app://",
)


def rel(path: Path, root: Path = REPO_ROOT) -> str:
    return path.relative_to(root).as_posix()


def load_registry(path: Path = REGISTRY_PATH) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def tracked_markdown_paths(root: Path = REPO_ROOT) -> set[str]:
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
            "--",
            "*.md",
            "*.MD",
        ],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return {
        item.decode("utf-8")
        for item in result.stdout.split(b"\0")
        if item
    }


def matches_rule(path: str, rule: dict[str, object]) -> bool:
    exact_paths = rule.get("paths", [])
    patterns = rule.get("patterns", [])
    if isinstance(exact_paths, list) and path in exact_paths:
        return True
    if not isinstance(patterns, list):
        return False
    return any(
        isinstance(pattern, str) and fnmatch.fnmatchcase(path, pattern)
        for pattern in patterns
    )


def strip_fenced_code(text: str) -> str:
    output: list[str] = []
    fence: str | None = None
    for line in text.splitlines():
        stripped = line.lstrip()
        marker = "```" if stripped.startswith("```") else "~~~" if stripped.startswith("~~~") else None
        if marker:
            fence = None if fence == marker else marker if fence is None else fence
            continue
        if fence is None:
            output.append(line)
    return "\n".join(output)


def heading_slug(heading: str) -> str:
    heading = re.sub(r"<[^>]+>", "", heading)
    heading = re.sub(r"[`*_~]", "", heading).strip().lower()
    heading = re.sub(r"[^\w\u4e00-\u9fff\s-]", "", heading)
    return re.sub(r"[\s-]+", "-", heading).strip("-")


def heading_anchors(path: Path) -> set[str]:
    text = strip_fenced_code(path.read_text(encoding="utf-8"))
    return {
        heading_slug(match.group(1))
        for match in HEADING_PATTERN.finditer(text)
    }


def iter_link_targets(text: str) -> Iterable[str]:
    text = strip_fenced_code(text)
    for pattern in (INLINE_LINK_PATTERN, REFERENCE_LINK_PATTERN):
        for match in pattern.finditer(text):
            target = match.group("target").strip()
            if target.startswith("<") and target.endswith(">"):
                target = target[1:-1]
            yield target


def validate_local_links(
    root: Path,
    markdown_paths: Iterable[str],
    alias_paths: set[str],
) -> list[str]:
    errors: list[str] = []
    root_resolved = root.resolve()
    anchor_cache: dict[Path, set[str]] = {}

    for relative_path in sorted(set(markdown_paths) - alias_paths):
        source = root / relative_path
        text = strip_fenced_code(source.read_text(encoding="utf-8"))
        for match in WIKI_LINK_PATTERN.finditer(text):
            errors.append(
                f"{relative_path}: unsupported wiki link; use Markdown: {match.group(0)}"
            )
        for target in iter_link_targets(text):
            lower_target = target.lower()
            if lower_target.startswith(EXTERNAL_PREFIXES) or target.startswith("//"):
                continue

            path_part, separator, anchor = target.partition("#")
            path_part = unquote(path_part.split("?", 1)[0])
            if path_part:
                linked = Path(path_part)
                if linked.is_absolute():
                    errors.append(f"{relative_path}: absolute local link is not portable: {target}")
                    continue
                candidate = (source.parent / linked).resolve(strict=False)
            else:
                candidate = source.resolve()

            try:
                candidate.relative_to(root_resolved)
            except ValueError:
                errors.append(f"{relative_path}: local link escapes repository: {target}")
                continue

            if not candidate.exists():
                errors.append(f"{relative_path}: missing local link target: {target}")
                continue

            if separator and anchor and candidate.suffix.lower() == ".md":
                anchors = anchor_cache.setdefault(candidate, heading_anchors(candidate))
                if unquote(anchor).lower() not in anchors:
                    errors.append(f"{relative_path}: missing heading anchor: {target}")

    return errors


def validate_registry(
    root: Path,
    registry: dict[str, object],
    markdown_paths: set[str],
) -> tuple[list[str], dict[str, dict[str, object]]]:
    errors: list[str] = []
    assignments: dict[str, dict[str, object]] = {}
    rules = registry.get("rules")

    if registry.get("schema_version") != 1:
        errors.append("document-control.json: schema_version must be 1")
    if not isinstance(rules, list):
        return errors + ["document-control.json: rules must be a list"], assignments

    seen_rule_ids: set[str] = set()
    for raw_rule in rules:
        if not isinstance(raw_rule, dict):
            errors.append("document-control.json: every rule must be an object")
            continue
        rule = raw_rule
        rule_id = rule.get("id")
        role = rule.get("role")
        lifecycle = rule.get("lifecycle")
        if not isinstance(rule_id, str) or not rule_id:
            errors.append("document-control.json: every rule needs a non-empty id")
            continue
        if rule_id in seen_rule_ids:
            errors.append(f"document-control.json: duplicate rule id: {rule_id}")
        seen_rule_ids.add(rule_id)
        if role not in VALID_ROLE_LIFECYCLES:
            errors.append(f"document-control.json: {rule_id} has invalid role: {role}")
            continue
        if lifecycle not in VALID_ROLE_LIFECYCLES[role]:
            errors.append(
                f"document-control.json: {rule_id} has invalid role/lifecycle: "
                f"{role}/{lifecycle}"
            )
            continue

        for field in ("paths", "patterns"):
            matchers = rule.get(field, [])
            if not isinstance(matchers, list):
                errors.append(
                    f"document-control.json: {rule_id} {field} must be a list"
                )
                continue
            if any(not isinstance(matcher, str) for matcher in matchers):
                errors.append(
                    f"document-control.json: {rule_id} {field} must contain only strings"
                )
        if not rule.get("paths") and not rule.get("patterns"):
            errors.append(
                f"document-control.json: {rule_id} needs at least one path or pattern"
            )
        marker = rule.get("status_marker")
        if marker is not None and not isinstance(marker, str):
            errors.append(
                f"document-control.json: {rule_id} status_marker must be a string"
            )

        matched = sorted(path for path in markdown_paths if matches_rule(path, rule))
        if not matched:
            errors.append(f"document-control.json: rule matches no tracked Markdown: {rule_id}")
        for path in matched:
            if path in assignments:
                errors.append(
                    f"document-control.json: {path} matches both "
                    f"{assignments[path]['id']} and {rule_id}"
                )
                continue
            assignments[path] = rule

        exact_paths = rule.get("paths", [])
        if isinstance(exact_paths, list):
            for path in exact_paths:
                if not isinstance(path, str):
                    errors.append(f"document-control.json: {rule_id} contains a non-string path")
                elif path not in markdown_paths:
                    errors.append(
                        f"document-control.json: {rule_id} names untracked Markdown: {path}"
                    )

    for path in sorted(markdown_paths - assignments.keys()):
        errors.append(f"document-control.json: unclassified repository Markdown: {path}")

    for path, rule in assignments.items():
        filesystem_path = root / path
        is_alias = rule.get("role") == "alias"
        if is_alias and not filesystem_path.is_symlink():
            errors.append(f"document-control.json: alias is not a symlink: {path}")
        elif not is_alias and filesystem_path.is_symlink():
            errors.append(f"document-control.json: symlink must use alias role: {path}")

        marker = rule.get("status_marker")
        if isinstance(marker, str):
            opening = "\n".join(filesystem_path.read_text(encoding="utf-8").splitlines()[:12])
            if marker not in opening:
                errors.append(f"{path}: opening must contain visible status marker: {marker}")

    return errors, assignments


def validate_required_assignments(
    assignments: dict[str, dict[str, object]],
    requirements: dict[str, tuple[str, str]] = REQUIRED_ASSIGNMENTS,
) -> list[str]:
    errors: list[str] = []
    for path, (expected_role, expected_lifecycle) in requirements.items():
        rule = assignments.get(path)
        if rule is None:
            errors.append(f"document-control.json: required assignment missing: {path}")
            continue
        actual_role = rule.get("role")
        actual_lifecycle = rule.get("lifecycle")
        if (actual_role, actual_lifecycle) == (
            expected_role,
            expected_lifecycle,
        ):
            continue
        errors.append(
            f"document-control.json: {path} must be "
            f"{expected_role}/{expected_lifecycle}, found "
            f"{actual_role}/{actual_lifecycle}"
        )
    return errors


def run_checks(
    root: Path = REPO_ROOT,
    registry_path: Path = REGISTRY_PATH,
) -> list[str]:
    try:
        registry = load_registry(registry_path)
        markdown_paths = tracked_markdown_paths(root)
    except (OSError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        return [f"document control setup failed: {error}"]

    errors, assignments = validate_registry(root, registry, markdown_paths)
    errors.extend(validate_required_assignments(assignments))
    alias_paths = {
        path
        for path, rule in assignments.items()
        if rule.get("role") == "alias"
    }
    errors.extend(validate_local_links(root, markdown_paths, alias_paths))
    return errors


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate without modifying files")
    parser.parse_args(argv)

    errors = run_checks()
    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        return 1
    print("[ok] document roles, lifecycles, and local links passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
