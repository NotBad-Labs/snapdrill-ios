#!/usr/bin/env python3
"""将 HTML 注释式 frontmatter 迁移到 YAML frontmatter。

用法：
    python migrate_to_yaml_frontmatter.py --dry-run
    python migrate_to_yaml_frontmatter.py --apply

输入：docs/ 目录下所有 *.md 文件
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import List, Optional

# 允许命令行覆盖 REPO_ROOT
REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

COMMENT_RE = re.compile(r"^<!--\s*(?P<key>[\w_-]+(?: \w+)?)\s*:\s*(?P<value>.*?)\s*-->\s*$")
INLINE_LAYER_RE = re.compile(r"layer\s*=\s*(?P<layer>[\w-]+)")

LAYER_ENUM = {"principle", "pattern", "snapshot", "archive", "decision"}
STATUS_ENUM = {"active", "archived", "deprecated"}


@dataclass
class Frontmatter:
    last_verified: Optional[str] = None
    layer: Optional[str] = None
    freshness_max_age_days: Optional[int] = None
    freshness_decay_trigger: List[str] = field(default_factory=list)
    status: Optional[str] = None
    reason: Optional[str] = None

    def to_yaml(self) -> str:
        lines = ["---"]
        if self.last_verified:
            lines.append(f"last_verified: {self.last_verified}")
        if self.layer:
            lines.append(f"layer: {self.layer}")
        if self.freshness_max_age_days or self.freshness_decay_trigger:
            lines.append("freshness:")
            if self.freshness_max_age_days:
                lines.append(f"  max_age_days: {self.freshness_max_age_days}")
            if self.freshness_decay_trigger:
                triggers = ", ".join(self.freshness_decay_trigger)
                lines.append(f"  decay_trigger: [{triggers}]")
        if self.status:
            lines.append(f"status: {self.status}")
        if self.reason:
            safe = self.reason.replace('"', '\\"')
            lines.append(f'reason: "{safe}"')
        lines.append("---")
        return "\n".join(lines) + "\n"


DECAY_TRIGGER_RE = re.compile(r"decay_trigger\s*=\s*\[(?P<inner>[^\]]*)\]")
MAX_AGE_RE = re.compile(r"max_age_days\s*=\s*(?P<n>\d+)")


def parse_freshness_value(value):
    max_age = None
    triggers = []
    inline_layer = None

    m = INLINE_LAYER_RE.search(value)
    if m:
        inline_layer = m.group("layer")

    m_age = MAX_AGE_RE.search(value)
    if m_age:
        try:
            max_age = int(m_age.group("n"))
        except ValueError:
            pass

    m_dt = DECAY_TRIGGER_RE.search(value)
    if m_dt:
        triggers = [t.strip() for t in m_dt.group("inner").split(",") if t.strip()]

    return max_age, triggers, inline_layer


def parse_existing_frontmatter(text):
    lines = text.splitlines()
    fm = Frontmatter()
    consumed = 0

    if lines and lines[0].strip() == "---":
        return None, 0

    for line in lines:
        stripped = line.strip()
        if not stripped:
            consumed += 1
            continue
        m = COMMENT_RE.match(stripped)
        if not m:
            break
        key = m.group("key").strip().replace(" ", "_")
        value = m.group("value").strip()

        if key in ("last_verified", "last_updated"):
            fm.last_verified = value
        elif key == "layer":
            fm.layer = value
        elif key == "freshness":
            max_age, triggers, inline_layer = parse_freshness_value(value)
            if max_age is not None:
                fm.freshness_max_age_days = max_age
            if triggers:
                fm.freshness_decay_trigger = triggers
            if inline_layer and not fm.layer:
                fm.layer = inline_layer
        elif key == "status":
            fm.status = value
        elif key == "reason":
            fm.reason = value

        consumed += 1

    return fm, consumed


def infer_layer_from_path(path):
    rel = path.relative_to(REPO_ROOT)
    parts = rel.parts
    if "decisions" in parts:
        return "decision"
    if "archive" in parts:
        return "archive"
    if "principles" in parts:
        return "pattern"
    if "memory" in parts:
        return "pattern"
    return None


def migrate_file(path, dry_run):
    text = path.read_text(encoding="utf-8")
    fm, consumed = parse_existing_frontmatter(text)

    if fm is None:
        return ("SKIP", None)

    if not fm.last_verified and not fm.layer:
        fm.layer = infer_layer_from_path(path)
        fm.last_verified = date.today().isoformat()
        if fm.layer is None:
            return ("NEEDS_MANUAL", f"cannot infer layer for {path}")

    if fm.layer and fm.layer not in LAYER_ENUM:
        return ("NEEDS_MANUAL", f"invalid layer '{fm.layer}' in {path}")

    new_header = fm.to_yaml()
    remaining = "\n".join(text.splitlines()[consumed:])
    new_text = new_header + remaining.lstrip("\n") + (
        "\n" if remaining and not remaining.endswith("\n") else ""
    )

    if dry_run:
        return ("MIGRATED", new_header)

    path.write_text(new_text, encoding="utf-8")
    return ("MIGRATED", None)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--repo-root", default=None, help="覆盖 REPO_ROOT 用于测试")
    parser.add_argument("--files", nargs="*", help="限定文件列表（相对 repo 根）")
    args = parser.parse_args()

    if args.dry_run == args.apply:
        print("必须指定 --dry-run 或 --apply 之一", file=sys.stderr)
        return 2

    global REPO_ROOT, DOCS_ROOT
    if args.repo_root:
        REPO_ROOT = Path(args.repo_root).resolve()
        DOCS_ROOT = REPO_ROOT / "docs"

    if args.files:
        candidates = [REPO_ROOT / f for f in args.files]
    else:
        candidates = sorted(DOCS_ROOT.rglob("*.md"))

    results = {"SKIP": 0, "MIGRATED": 0, "NEEDS_MANUAL": 0}
    errors = []

    for path in candidates:
        action, detail = migrate_file(path, args.dry_run)
        results[action] += 1
        if action == "NEEDS_MANUAL":
            errors.append(f"{path}: {detail}")
        if args.dry_run and action == "MIGRATED" and detail:
            print(f"--- {path.relative_to(REPO_ROOT)} ---")
            print(detail)

    print(f"\nSummary: {results}")
    if errors:
        print("\nManual intervention required:")
        for e in errors:
            print(f"  - {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
