#!/usr/bin/env python3
"""校验 docs/ 下 md 文件的 YAML frontmatter 是否符合 schema。

用法：
    python validate_frontmatter.py --check
    python validate_frontmatter.py --check --files a.md b.md

退出码：0 = 通过；1 = 校验失败；2 = 参数错误。
"""

from __future__ import annotations

import argparse
import re
import sys
from datetime import date, timedelta
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
LAYER_ENUM = {"principle", "pattern", "snapshot", "archive", "decision", "contract"}
STATUS_ENUM = {"active", "archived", "deprecated", "draft"}
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def extract_frontmatter(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end < 0:
        return None
    return text[4:end]


def validate_file(path, strict=False):
    errors = []
    warnings = []
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as exc:
        return [f"{path}: cannot read: {exc}"], []

    fm_raw = extract_frontmatter(text)
    if fm_raw is None:
        errors.append(f"{path}: missing YAML frontmatter (must start with '---')")
        return errors, []

    if yaml is None:
        data = {}
        for line in fm_raw.splitlines():
            if ":" in line and not line.startswith(" "):
                k, _, v = line.partition(":")
                data[k.strip()] = v.strip()
    else:
        try:
            data = yaml.safe_load(fm_raw) or {}
        except yaml.YAMLError as exc:
            return [f"{path}: invalid YAML: {exc}"], []

    lv = data.get("last_verified")
    lv_date = None
    if not lv:
        errors.append(f"{path}: missing 'last_verified'")
    elif isinstance(lv, date):
        lv_date = lv
    elif isinstance(lv, str) and DATE_RE.match(lv):
        lv_date = date.fromisoformat(lv)
    else:
        errors.append(f"{path}: invalid 'last_verified' format (expected YYYY-MM-DD)")

    layer = data.get("layer")
    if not layer:
        errors.append(f"{path}: missing 'layer'")
    elif layer not in LAYER_ENUM:
        errors.append(f"{path}: invalid layer '{layer}' (must be one of {sorted(LAYER_ENUM)})")

    status = data.get("status")
    if status is not None and status not in STATUS_ENUM:
        errors.append(f"{path}: invalid status '{status}'")

    fr = data.get("freshness")
    max_age = None
    if fr is not None:
        if not isinstance(fr, dict):
            errors.append(f"{path}: freshness must be a mapping")
        else:
            m = fr.get("max_age_days")
            if m is None or not isinstance(m, int) or m < 1:
                errors.append(f"{path}: freshness.max_age_days must be positive int")
            else:
                max_age = m
            t = fr.get("decay_trigger")
            if t is not None and not isinstance(t, list):
                errors.append(f"{path}: freshness.decay_trigger must be a list")

    # freshness 过期检查：仅当 last_verified 和 max_age_days 都有效时才计算
    if lv_date is not None and max_age is not None:
        expiration = lv_date + timedelta(days=max_age)
        days_left = (expiration - date.today()).days
        if days_left < 0:
            msg = f"{path}: freshness expired — last_verified={lv_date}, max_age_days={max_age}, expired {-days_left}d ago"
            if strict:
                errors.append(msg)
            else:
                warnings.append(msg)
        elif days_left <= 7:
            warnings.append(f"{path}: freshness expiring soon — {days_left}d left (last_verified={lv_date}, max_age_days={max_age})")

    return errors, warnings


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--check", action="store_true")
    p.add_argument("--strict", action="store_true",
                   help="expired freshness is an error (exit 1) instead of a warning")
    p.add_argument("--repo-root", default=None)
    p.add_argument("--files", nargs="*")
    args = p.parse_args()

    if not args.check:
        print("请使用 --check 参数", file=sys.stderr)
        return 2

    global REPO_ROOT, DOCS_ROOT
    if args.repo_root:
        REPO_ROOT = Path(args.repo_root).resolve()
        DOCS_ROOT = REPO_ROOT / "docs"

    if args.files:
        candidates = [Path(f) for f in args.files]
    else:
        candidates = sorted(DOCS_ROOT.rglob("*.md"))

    all_errors = []
    all_warnings = []
    for path in candidates:
        errors, warnings = validate_file(path, strict=args.strict)
        all_errors.extend(errors)
        all_warnings.extend(warnings)

    if all_warnings:
        for w in all_warnings:
            print(f"WARNING: {w}", file=sys.stderr)

    if all_errors:
        for e in all_errors:
            print(f"ERROR: {e}", file=sys.stderr)
        print(f"\nFAILED: {len(all_errors)} violations in {len(candidates)} files", file=sys.stderr)
        if all_warnings:
            print(f"       {len(all_warnings)} warnings", file=sys.stderr)
        return 1

    status = f"OK: {len(candidates)} files validated"
    if all_warnings:
        status += f", {len(all_warnings)} warnings"
    print(status)
    return 0


if __name__ == "__main__":
    sys.exit(main())
