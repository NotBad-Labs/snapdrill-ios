#!/usr/bin/env python3
"""Keep the current documentation set deliberately small."""

from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]

ALLOWED_MARKDOWN = {
    ".github/ISSUE_TEMPLATE/bug_report.md",
    ".github/ISSUE_TEMPLATE/chore.md",
    ".github/ISSUE_TEMPLATE/feature_request.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/copilot-instructions.md",
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "docs/ARCHITECTURE.md",
    "docs/DATA.md",
    "docs/DEVELOPMENT.md",
    "docs/PRD.md",
    "docs/RELEASE.md",
}

REQUIRED_SYMLINKS = {
    "CLAUDE.md": "AGENTS.md",
    ".github/copilot-instructions.md": "../AGENTS.md",
}


def tracked_markdown() -> set[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
    )
    return {
        path
        for path in result.stdout.decode("utf-8").split("\0")
        if path.endswith(".md")
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate without writing (the script is always read-only)",
    )
    parser.parse_args()

    errors: list[str] = []
    tracked = tracked_markdown()

    for path in sorted(ALLOWED_MARKDOWN - tracked):
        errors.append(f"missing current Markdown file: {path}")
    for path in sorted(tracked - ALLOWED_MARKDOWN):
        errors.append(f"unexpected current Markdown file: {path}")

    for path, expected_target in REQUIRED_SYMLINKS.items():
        candidate = REPO_ROOT / path
        if not candidate.is_symlink():
            errors.append(f"{path}: must be a symlink")
        elif os.readlink(candidate) != expected_target:
            errors.append(
                f"{path}: expected symlink target {expected_target}, "
                f"found {os.readlink(candidate)}"
            )

    if errors:
        for error in errors:
            print(f"[error] {error}")
        return 1

    print(f"[ok] documentation: {len(ALLOWED_MARKDOWN)} current Markdown files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
