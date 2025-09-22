#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scripts/generate_changelog_from_git.py

Generate a CHANGELOG snippet from conventional commits between two refs.
Groups commits into sections: Added, Changed, Fixed, Docs, Chore, Refactor, Test, Build, CI, Revert, Others.

Usage examples:
  python3 Scripts/generate_changelog_from_git.py --from v6.0.0 --to HEAD
  python3 Scripts/generate_changelog_from_git.py --since-tag v6.0.0

The output is printed to stdout; you can paste it into CHANGELOG.md under the version section.
"""
import argparse
import subprocess
import sys
from collections import defaultdict

TYPE_MAP = [
    ("feat", "Added"),
    ("fix", "Fixed"),
    ("docs", "Docs"),
    ("chore", "Chore"),
    ("refactor", "Refactor"),
    ("test", "Test"),
    ("build", "Build"),
    ("ci", "CI"),
    ("revert", "Revert"),
]


def run(cmd):
    return subprocess.check_output(cmd, universal_newlines=True)


def parse_commits(lines):
    groups = defaultdict(list)
    for line in lines:
        line = line.strip()
        if not line:
            continue
        # Conventional commit type is before ':'
        typ = line.split(':', 1)[0].lower()
        section = None
        for t, sec in TYPE_MAP:
            if typ.startswith(t):
                section = sec
                break
        if section is None:
            section = 'Changed' if 'merge' not in typ else 'Others'
        groups[section].append(line)
    return groups


def main():
    ap = argparse.ArgumentParser(description='Generate CHANGELOG snippet from conventional commits')
    ap.add_argument('--from', dest='from_ref', help='From ref (exclusive)')
    ap.add_argument('--to', dest='to_ref', default='HEAD', help='To ref (inclusive)')
    ap.add_argument('--since-tag', dest='since_tag', help='Shorthand for --from <tag> --to HEAD')
    args = ap.parse_args()

    if args.since_tag and args.from_ref:
        print('Do not use --since-tag together with --from', file=sys.stderr)
        sys.exit(2)

    if args.since_tag:
        from_ref = args.since_tag
        to_ref = 'HEAD'
    else:
        from_ref = args.from_ref
        to_ref = args.to_ref

    if from_ref:
        rev_range = f"{from_ref}..{to_ref}"
    else:
        rev_range = to_ref

    try:
        out = run(['git', '--no-pager', 'log', '--pretty=format:%s', rev_range])
    except subprocess.CalledProcessError as e:
        print(f"git log failed: {e}", file=sys.stderr)
        sys.exit(1)

    lines = out.splitlines()
    groups = parse_commits(lines)

    order = ["Added", "Changed", "Fixed", "Docs", "Refactor", "Test", "Build", "CI", "Chore", "Revert", "Others"]

    for sec in order:
        entries = groups.get(sec, [])
        if not entries:
            continue
        print(f"### {sec}")
        print()
        for msg in entries:
            print(f"- {msg}")
        print()


if __name__ == '__main__':
    main()
