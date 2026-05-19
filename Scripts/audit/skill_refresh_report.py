#!/usr/bin/env python3
"""Report vendored skill drift against an upstream checkout.

This script is intentionally read-only. It compares `skills-lock.json` vendored
entries with the current repository files and a supplied upstream checkout or
tarball extraction directory.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Row:
    skill: str
    kind: str
    path: str
    upstream_commit: str
    expected_blob: str
    actual_blob: str
    status: str
    local_vs_upstream: str


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    header = f"blob {len(data)}\0".encode("utf-8")
    return hashlib.sha1(header + data).hexdigest()


def load_vendored_entries(lockfile: Path) -> dict[str, dict[str, object]]:
    payload = json.loads(lockfile.read_text(encoding="utf-8"))
    skills = payload.get("skills", {})
    if not isinstance(skills, dict):
        raise ValueError("skills-lock.json must contain a mapping at key 'skills'")
    return {
        name: entry
        for name, entry in skills.items()
        if isinstance(entry, dict) and entry.get("kind") == "vendored"
    }


def scoped_path(root: Path, path: str) -> Path | None:
    root = root.resolve()
    full_path = (root / path).resolve()
    if not full_path.is_relative_to(root):
        return None
    return full_path


def check_blob(root: Path, path: str, expected_blob: str) -> tuple[str, str]:
    full_path = scoped_path(root, path)
    if full_path is None:
        return "", "out-of-scope"
    if not full_path.is_file():
        return "", "missing"
    actual_blob = git_blob_sha(full_path)
    if actual_blob == expected_blob:
        return actual_blob, "ok"
    return actual_blob, "changed"


def git_head(root: Path) -> str | None:
    if not (root / ".git").exists():
        return None
    completed = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(root),
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        return None
    return completed.stdout.strip()


def strip_frontmatter(text: str) -> str:
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return text
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return "".join(lines[index + 1:])
    return text


def local_vs_upstream(repo_root: Path, local_path: str, upstream_root: Path, upstream_path: str) -> str:
    local_file = scoped_path(repo_root, local_path)
    upstream_file = scoped_path(upstream_root, upstream_path)
    if local_file is None or upstream_file is None:
        return "unavailable"
    if not local_file.is_file() or not upstream_file.is_file():
        return "unavailable"
    local_text = local_file.read_text(encoding="utf-8")
    upstream_text = upstream_file.read_text(encoding="utf-8")
    if local_text == upstream_text:
        return "equal"
    if strip_frontmatter(local_text) == strip_frontmatter(upstream_text):
        return "frontmatter-only"
    return "body-diff"


def collect_rows(repo_root: Path, upstream_root: Path, lockfile: Path) -> list[Row]:
    rows: list[Row] = []
    upstream_root_head = git_head(upstream_root)
    for skill, entry in sorted(load_vendored_entries(lockfile).items()):
        local_path = str(entry.get("localPath", ""))
        local_blob = str(entry.get("localBlob", ""))
        upstream_path = str(entry.get("upstreamPath", ""))
        upstream_blob = str(entry.get("upstreamBlob", ""))
        upstream_commit = str(entry.get("upstreamCommit", ""))

        if upstream_root_head and upstream_root_head != upstream_commit:
            rows.append(Row(
                skill,
                "upstream-root",
                str(upstream_root),
                upstream_commit,
                upstream_commit,
                upstream_root_head,
                "wrong-commit",
                "",
            ))

        relation = local_vs_upstream(repo_root, local_path, upstream_root, upstream_path)

        actual, status = check_blob(repo_root, local_path, local_blob)
        rows.append(Row(skill, "skill-local", local_path, upstream_commit, local_blob, actual, status, relation))

        actual, status = check_blob(upstream_root, upstream_path, upstream_blob)
        rows.append(Row(skill, "skill-upstream", upstream_path, upstream_commit, upstream_blob, actual, status, ""))

        support_files = entry.get("supportFiles", [])
        if not isinstance(support_files, list):
            rows.append(Row(skill, "support-schema", "supportFiles", upstream_commit, "", "", "schema", ""))
            continue

        for support in support_files:
            if not isinstance(support, dict):
                rows.append(Row(skill, "support-schema", "supportFiles[]", upstream_commit, "", "", "schema", ""))
                continue

            support_local_path = str(support.get("localPath", ""))
            support_local_blob = str(support.get("localBlob", ""))
            support_upstream_path = str(support.get("upstreamPath", ""))
            support_upstream_blob = str(support.get("upstreamBlob", ""))
            relation = local_vs_upstream(repo_root, support_local_path, upstream_root, support_upstream_path)

            actual, status = check_blob(repo_root, support_local_path, support_local_blob)
            rows.append(Row(
                skill,
                "support-local",
                support_local_path,
                upstream_commit,
                support_local_blob,
                actual,
                status,
                relation,
            ))

            actual, status = check_blob(upstream_root, support_upstream_path, support_upstream_blob)
            rows.append(Row(
                skill,
                "support-upstream",
                support_upstream_path,
                upstream_commit,
                support_upstream_blob,
                actual,
                status,
                "",
            ))

    return rows


def print_rows(rows: list[Row]) -> None:
    print("skill\tkind\tpath\tupstream_commit\texpected_blob\tactual_blob\tstatus\tlocal_vs_upstream")
    for row in rows:
        print(
            f"{row.skill}\t{row.kind}\t{row.path}\t{row.upstream_commit}\t"
            f"{row.expected_blob}\t{row.actual_blob}\t{row.status}\t{row.local_vs_upstream}"
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--upstream-root",
        required=True,
        type=Path,
        help="Path to an extracted upstream repository checkout.",
    )
    parser.add_argument(
        "--lockfile",
        default=REPO_ROOT / "skills-lock.json",
        type=Path,
        help="Path to skills-lock.json.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 when any row is not ok.",
    )
    args = parser.parse_args(argv)

    upstream_root = args.upstream_root.resolve()
    if not upstream_root.is_dir():
        print(f"ERROR: upstream root does not exist: {upstream_root}", file=sys.stderr)
        return 2
    if not args.lockfile.is_file():
        print(f"ERROR: lockfile does not exist: {args.lockfile}", file=sys.stderr)
        return 2

    try:
        rows = collect_rows(REPO_ROOT, upstream_root, args.lockfile)
    except (json.JSONDecodeError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print_rows(rows)
    if args.strict and any(row.status != "ok" for row in rows):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
