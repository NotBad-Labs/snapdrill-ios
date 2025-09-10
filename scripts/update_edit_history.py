#!/usr/bin/env python3
"""Auto-update '编辑历史 / 贡献者' tables in docs.

Usage:
  ./scripts/update_edit_history.py <file1> <file2> ...

Behavior:
  - Insert a new row below the table header in each target file.
  - Detect table by heading line starting with '###' and containing '编辑历史'.
  - Row format: | YYYY-MM-DD | <version> | <summary> | <author> |
  - Version heuristic: if file name contains vX.Y, append +auto; else use v?+auto.
  - Summary comes from --summary arg or defaults to '批量治理: ADR索引 & 流程脚本'.

Example:
  ./scripts/update_edit_history.py --author "Docs Maintainer" --summary "添加 ADR 索引与脚本" docs/prd/...md
"""
from __future__ import annotations
import argparse
import datetime as _dt
import pathlib
import re
import sys

HEADING_PATTERN = re.compile(r"^### .*编辑历史.*")
TABLE_HEADER_PATTERN = re.compile(r"^\| *日期 *\| *版本 *\| *说明 *\| *作者 *\|")
VERSION_IN_NAME = re.compile(r"v(\d+\.\d+)")


def infer_version(path: pathlib.Path) -> str:
    m = VERSION_IN_NAME.search(path.name)
    if m:
        return f"v{m.group(1)}+auto"
    return "v?+auto"


def build_row(version: str, summary: str, author: str) -> str:
    today = _dt.date.today().isoformat()
    return f"| {today} | {version} | {summary} | {author} |"


def process_file(path: pathlib.Path, row: str) -> bool:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if HEADING_PATTERN.match(line):
            # scan forward to find table header
            for j in range(i + 1, min(i + 15, len(lines))):
                if TABLE_HEADER_PATTERN.match(lines[j]):
                    insert_at = j + 2  # after header + separator
                    lines.insert(insert_at, row)
                    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
                    return True
    return False


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="*")
    parser.add_argument("--author", default="Docs Maintainer")
    parser.add_argument("--summary", default="批量治理: ADR索引 & 流程脚本")
    args = parser.parse_args(argv)

    if not args.files:
        print("No files provided", file=sys.stderr)
        return 1

    any_failed = False
    for f in args.files:
        path = pathlib.Path(f)
        if not path.exists():
            print(f"[skip] missing {f}")
            any_failed = True
            continue
        version = infer_version(path)
        row = build_row(version, args.summary, args.author)
        if process_file(path, row):
            print(f"[ok] updated {f}")
        else:
            print(f"[fail] pattern not found in {f}")
            any_failed = True
    return 0 if not any_failed else 2

if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1:]))
