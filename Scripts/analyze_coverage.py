#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Analyze xccov JSON and list the lowest-covered files.
Usage:
  python Scripts/analyze_coverage.py <xccov.json> [--exclude-path-regex REGEX] [--min-executable-lines N] [--limit K]

Notes:
- Expects JSON produced by: xcrun xccov view --report --json <.xcresult>
- Aggregates by file path; for duplicates across targets, keeps the worst coverage entry.
"""
import argparse
import json
import os
import re
from typing import Dict, List, Tuple


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("json_path", help="Path to xccov JSON report")
    p.add_argument("--exclude-path-regex", default=None, help="Regex to exclude file paths")
    p.add_argument("--min-executable-lines", type=int, default=1, help="Only consider files with at least N executable lines")
    p.add_argument("--limit", type=int, default=20, help="Max number of files to list")
    return p.parse_args()


def load_report(path: str) -> Dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def collect_files(report: Dict) -> List[Dict]:
    files: List[Dict] = []
    for target in report.get("targets", []):
        for f in target.get("files", []):
            # Some entries may miss fields; guard defensively
            path = f.get("path") or f.get("name")
            if not path:
                continue
            files.append({
                "path": path,
                "name": f.get("name", os.path.basename(path)),
                "lineCoverage": float(f.get("lineCoverage", 0.0)),
                "executableLines": int(f.get("executableLines", 0)),
                "coveredLines": int(f.get("coveredLines", 0)),
            })
    return files


def filter_and_reduce(files: List[Dict], exclude_regex: str, min_exec: int) -> Dict[str, Dict]:
    """Deduplicate by path; keep the worst coverage per path to highlight problems."""
    rx = re.compile(exclude_regex) if exclude_regex else None
    best: Dict[str, Dict] = {}
    for f in files:
        path = f["path"]
        if rx and rx.search(path):
            continue
        if f["executableLines"] < min_exec:
            continue
        if path not in best:
            best[path] = f
        else:
            # Keep the lower coverage entry
            if f["lineCoverage"] < best[path]["lineCoverage"]:
                best[path] = f
    return best


def main():
    args = parse_args()
    report = load_report(args.json_path)
    files = collect_files(report)
    reduced = filter_and_reduce(files, args.exclude_path_regex, args.min_executable_lines)
    sorted_files = sorted(reduced.values(), key=lambda x: x["lineCoverage"])
    limit = max(1, args.limit)

    print("🔎 最低覆盖文件 (按覆盖率升序):")
    print(f"来源: {args.json_path}")
    print(f"排除: {args.exclude_path_regex or '无'} | 最小可执行行数: {args.min_executable_lines} | Top {limit}")
    print("")
    for f in sorted_files[:limit]:
        pct = f["lineCoverage"] * 100.0
        cov = f["coveredLines"]
        exe = f["executableLines"]
        print(f"{pct:6.2f}%  ({cov:4d}/{exe:4d})  {f['path']}")


if __name__ == "__main__":
    main()
