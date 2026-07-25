#!/usr/bin/env python3
"""Validate SnapDrill's deliberately small current documentation set."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]

CURRENT_DOCS = {
    "docs/PRD.md",
    "docs/ARCHITECTURE.md",
    "docs/DATA.md",
    "docs/DEVELOPMENT.md",
    "docs/RELEASE.md",
}

ALLOWED_MARKDOWN = CURRENT_DOCS | {
    "README.md",
    "AGENTS.md",
    "CLAUDE.md",
    ".github/copilot-instructions.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/bug_report.md",
    ".github/ISSUE_TEMPLATE/chore.md",
    ".github/ISSUE_TEMPLATE/feature_request.md",
}

DOC_RANK = {
    "docs/PRD.md": 0,
    "docs/ARCHITECTURE.md": 1,
    "docs/DATA.md": 1,
    "docs/DEVELOPMENT.md": 2,
    "docs/RELEASE.md": 3,
}

REQUIRED_PRD_PATTERNS = {
    r"通用(?:型)?效率工具": "general productivity positioning",
    r"不是.*教辅软件": "not an education-content product",
    r"(?:一个本地|单一)资料库": "one local library",
    r"首版免费": "free initial release",
    r"无广告": "no advertising",
    r"无 IAP": "no in-app purchases",
    r"Review.*SmartPaper.*高级统计.*公开入口": "optional features hidden",
    r"首版不包含.*Share Extension": "Share Extension excluded from initial release",
}

REQUIRED_DATA_PATTERNS = {
    r"Review、SmartPaper、Pro、Profile.*不进入正式\s*备份": (
        "legacy implementation state excluded from backup"
    ),
    r"CSV.*`=`.*`\+`.*`-`.*`@`.*tab": "CSV formula-injection protection",
}

FORBIDDEN_CURRENT_TERMS = {
    "Release 1": "use the conventional initial-release wording in PRD.md",
    "Product Constitution": "PRD.md is the product authority",
    "docs/product/": "old document tree",
    "docs/features/": "old document tree",
    "docs/explanations/": "old document tree",
    "docs/reference/": "old document tree",
    "docs/how-to/": "old document tree",
    "docs/decisions/": "old document tree",
    "docs/ui-redesign/": "old document tree",
}

INLINE_MARKDOWN_LINK = re.compile(
    r"""(?x)
    (?<!!)
    \[[^\]\n]+\]
    \(
        \s*
        (<[^>\n]+>|[^)\s]+)
        (?:\s+(?:"[^"\n]*"|'[^'\n]*'|\([^)\n]*\)))?
        \s*
    \)
    """
)
REFERENCE_DEFINITION = re.compile(
    r"(?m)^[ ]{0,3}\[([^\]\n]+)\]:[ \t]*(<[^>\n]+>|[^ \t\n]+)"
)
REFERENCE_USAGE = re.compile(r"(?<!!)\[([^\]\n]+)\]\[([^\]\n]*)\]")
SHORTCUT_REFERENCE_USAGE = re.compile(r"(?<!!)\[([^\]\n]+)\](?![ \t]*[\[(])")
REQUIREMENT_ROW = re.compile(r"^\| PRD-(\d{2}) \|", re.MULTILINE)


def tracked_markdown(root: Path) -> set[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return {
        path
        for path in result.stdout.decode("utf-8").split("\0")
        if path.endswith(".md")
    }


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def link_target(source: str, raw_target: str) -> str | None:
    target = raw_target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    if (
        not target
        or target.startswith("#")
        or "://" in target
        or target.startswith("mailto:")
    ):
        return None

    target = target.split("#", 1)[0]
    if not target:
        return None

    source_parent = Path(source).parent
    return os.path.normpath(str(source_parent / target))


def normalize_reference_label(label: str) -> str:
    return " ".join(label.strip().casefold().split())


def markdown_link_targets(content: str) -> tuple[list[str], list[str]]:
    targets = [
        match.group(1) for match in INLINE_MARKDOWN_LINK.finditer(content)
    ]
    definitions = {
        normalize_reference_label(match.group(1)): match.group(2)
        for match in REFERENCE_DEFINITION.finditer(content)
    }
    errors: list[str] = []

    for match in REFERENCE_USAGE.finditer(content):
        label = match.group(2) or match.group(1)
        normalized = normalize_reference_label(label)
        target = definitions.get(normalized)
        if target is None:
            errors.append(f"undefined reference link: {label}")
        else:
            targets.append(target)

    without_definitions = REFERENCE_DEFINITION.sub("", content)
    shortcut_content = REFERENCE_USAGE.sub("", without_definitions)
    for match in SHORTCUT_REFERENCE_USAGE.finditer(shortcut_content):
        normalized = normalize_reference_label(match.group(1))
        target = definitions.get(normalized)
        if target is not None:
            targets.append(target)

    return targets, errors


def doc_graph(root: Path) -> tuple[dict[str, set[str]], list[str]]:
    graph = {path: set() for path in CURRENT_DOCS}
    errors: list[str] = []

    for source in sorted(ALLOWED_MARKDOWN):
        source_path = root / source
        if not source_path.exists():
            continue
        raw_targets, reference_errors = markdown_link_targets(read(source_path))
        errors.extend(f"{source}: {error}" for error in reference_errors)
        for raw_target in raw_targets:
            target = link_target(source, raw_target)
            if target is None:
                continue
            target_path = root / target
            if not target_path.exists():
                errors.append(f"{source}: broken local link: {raw_target}")
                continue
            if source in CURRENT_DOCS and target in CURRENT_DOCS:
                graph[source].add(target)
                if DOC_RANK[target] > DOC_RANK[source]:
                    errors.append(
                        f"{source}: dependency points upward to {target}"
                    )

    return graph, errors


def graph_cycles(graph: dict[str, set[str]]) -> list[list[str]]:
    cycles: list[list[str]] = []
    visiting: list[str] = []
    visited: set[str] = set()

    def visit(node: str) -> None:
        if node in visiting:
            start = visiting.index(node)
            cycles.append(visiting[start:] + [node])
            return
        if node in visited:
            return

        visiting.append(node)
        for child in sorted(graph[node]):
            visit(child)
        visiting.pop()
        visited.add(node)

    for node in sorted(graph):
        visit(node)
    return cycles


def validate(root: Path, tracked: set[str]) -> list[str]:
    errors: list[str] = []

    missing = ALLOWED_MARKDOWN - tracked
    extra = tracked - ALLOWED_MARKDOWN
    for path in sorted(missing):
        errors.append(f"missing required Markdown: {path}")
    for path in sorted(extra):
        errors.append(f"unapproved Markdown outside the minimal set: {path}")

    for path in sorted(ALLOWED_MARKDOWN & tracked):
        if not (root / path).exists():
            errors.append(f"tracked Markdown is missing from worktree: {path}")

    aliases = {
        "CLAUDE.md": "AGENTS.md",
        ".github/copilot-instructions.md": "../AGENTS.md",
    }
    for path, expected in aliases.items():
        alias = root / path
        if not alias.is_symlink():
            errors.append(f"{path}: must be a symlink")
        elif os.readlink(alias) != expected:
            errors.append(
                f"{path}: expected symlink target {expected}, "
                f"found {os.readlink(alias)}"
            )

    prd_path = root / "docs/PRD.md"
    if prd_path.exists():
        prd = read(prd_path)
        for pattern, label in sorted(REQUIRED_PRD_PATTERNS.items()):
            if re.search(pattern, prd, re.DOTALL) is None:
                errors.append(f"docs/PRD.md: missing product boundary: {label}")

        identifiers = REQUIREMENT_ROW.findall(prd)
        expected_ids = {f"{number:02d}" for number in range(1, 16)}
        actual_ids = set(identifiers)
        if actual_ids != expected_ids:
            errors.append(
                "docs/PRD.md: requirement IDs must be exactly PRD-01...PRD-15"
            )
        duplicates = sorted(
            identifier for identifier in actual_ids if identifiers.count(identifier) > 1
        )
        if duplicates:
            errors.append(
                "docs/PRD.md: duplicate requirement IDs: "
                + ", ".join(f"PRD-{identifier}" for identifier in duplicates)
            )

    data_path = root / "docs/DATA.md"
    if data_path.exists():
        data_contract = read(data_path)
        for pattern, label in sorted(REQUIRED_DATA_PATTERNS.items()):
            if re.search(pattern, data_contract, re.DOTALL) is None:
                errors.append(f"docs/DATA.md: missing data boundary: {label}")

    current_surfaces = {"README.md", "AGENTS.md"} | CURRENT_DOCS
    for path in sorted(current_surfaces):
        candidate = root / path
        if not candidate.exists():
            continue
        content = read(candidate)
        for term, reason in FORBIDDEN_CURRENT_TERMS.items():
            if term in content:
                errors.append(f"{path}: forbidden stale term '{term}' ({reason})")
        if re.search(r"github\.com/[^)\s]+/(?:issues|pull)/\d+", content):
            errors.append(f"{path}: current docs must not depend on historical PR/issue URLs")

    readme_path = root / "README.md"
    if readme_path.exists():
        readme = read(readme_path)
        for path in sorted(CURRENT_DOCS):
            relative = path.removeprefix("docs/")
            if f"(docs/{relative})" not in readme:
                errors.append(f"README.md: missing route to {path}")

    graph, link_errors = doc_graph(root)
    errors.extend(link_errors)
    for cycle in graph_cycles(graph):
        errors.append("docs dependency cycle: " + " -> ".join(cycle))

    return errors


def run_checks(root: Path = REPO_ROOT) -> list[str]:
    return validate(root, tracked_markdown(root))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate without writing (the validator is always read-only)",
    )
    parser.parse_args()

    errors = run_checks()
    if errors:
        for error in errors:
            print(f"[error] {error}")
        return 1

    print(
        "[ok] documentation: 5 current docs, valid links, "
        "single-direction dependencies, no historical document tree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
