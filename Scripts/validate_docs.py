#!/usr/bin/env python3
"""Validate high-risk documentation drift.

This is intentionally narrow. It does not judge product strategy; it catches
document states that have repeatedly misled agents: historical ADRs presented as
current truth, stale Firebase-era claims outside historical records, and feature
specs without explicit intent traceability.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"

HISTORICAL_ADRS = {
    DOCS_ROOT / "decisions" / "ADR-003-dual-region-release.md": "suspended",
    DOCS_ROOT / "decisions" / "ADR-004-china-build-firebase-free.md": "superseded",
}

STALE_CURRENT_CLAIMS = {
    "海外版保留 Firebase",
    "海外版 Firebase",
    "待 C 路径",
    "编译层彻底剔除待",
}

STALE_ALLOWED = set(HISTORICAL_ADRS)
VISION_REF_PATTERN = re.compile(r"^vision:P([1-9][0-9]*)$")
ADR_REF_PATTERN = re.compile(r"^ADR-[0-9]{3}$")
HEADING_PATTERN = re.compile(r"^#+\s+(.+?)\s*$", re.MULTILINE)


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_frontmatter(text: str) -> tuple[dict[str, object], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end == -1:
        return {}, text

    data: dict[str, object] = {}
    current_key: str | None = None
    for raw_line in text[4:end].splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            existing = data.setdefault(current_key, [])
            if isinstance(existing, list):
                existing.append(line[4:].strip().strip('"'))
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        current_key = key
        if not value:
            data[key] = []
        elif value in {"true", "false"}:
            data[key] = value == "true"
        else:
            data[key] = value.strip('"')
    return data, text[end + 4 :]


def line_number(text: str, needle: str) -> int:
    index = text.find(needle)
    if index == -1:
        return 1
    return text[:index].count("\n") + 1


def heading_slug(heading: str) -> str:
    slug = heading.strip().lower()
    slug = re.sub(r"[^\w\u4e00-\u9fff\s-]", "", slug)
    slug = re.sub(r"\s+", "-", slug)
    return slug


def has_heading_anchor(path: Path, anchor: str) -> bool:
    text = read(path)
    wanted = anchor.lstrip("#").lower()
    return any(heading_slug(match.group(1)) == wanted for match in HEADING_PATTERN.finditer(text))


def resolve_doc_ref(ref: str) -> tuple[Path | None, str | None]:
    base, _, anchor = ref.partition("#")

    if VISION_REF_PATTERN.match(base):
        return DOCS_ROOT / "explanations" / "vision.md", base

    if ADR_REF_PATTERN.match(base):
        matches = sorted((DOCS_ROOT / "decisions").glob(f"{base}-*.md"))
        if len(matches) == 1:
            return matches[0], anchor or None
        return None, None

    direct = DOCS_ROOT / base
    if direct.suffix != ".md":
        direct = direct.with_suffix(".md")
    if direct.exists():
        return direct, anchor or None

    matches = sorted(path for path in DOCS_ROOT.rglob("*.md") if path.stem == base)
    if len(matches) == 1:
        return matches[0], anchor or None
    return None, None


def ref_target_exists(target: Path, anchor: str | None) -> bool:
    if anchor is None:
        return True

    vision_match = VISION_REF_PATTERN.match(anchor)
    if vision_match:
        principle_number = vision_match.group(1)
        pattern = rf"^###\s+P{principle_number}\."
        return re.search(pattern, read(target), re.MULTILINE) is not None

    return has_heading_anchor(target, anchor)


def validate_historical_adrs(errors: list[str]) -> None:
    for path, expected_status in HISTORICAL_ADRS.items():
        text = read(path)
        fm, body = parse_frontmatter(text)
        current_status = fm.get("current_status")
        if current_status != expected_status:
            errors.append(
                f"{rel(path)}: frontmatter current_status must be {expected_status!r}"
            )
        if fm.get("historical_record") is not True:
            errors.append(f"{rel(path)}: frontmatter historical_record must be true")
        if "current_authority" not in fm:
            errors.append(f"{rel(path)}: frontmatter must name current_authority")

        first_block = "\n".join(body.splitlines()[:12])
        if "历史" not in first_block or "不代表当前" not in first_block:
            errors.append(
                f"{rel(path)}: opening warning must say it is historical and not current truth"
            )


def validate_stale_claims(errors: list[str]) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if path in STALE_ALLOWED:
            continue
        text = read(path)
        for phrase in STALE_CURRENT_CLAIMS:
            if phrase in text:
                errors.append(f"{rel(path)}:{line_number(text, phrase)} stale claim: {phrase}")


def validate_feature_intent(errors: list[str]) -> None:
    for path in sorted((DOCS_ROOT / "features").rglob("feat-*.md")):
        if path.name == "template.md":
            continue
        text = read(path)
        fm, _ = parse_frontmatter(text)
        intent_refs = fm.get("intent_refs")
        if not isinstance(intent_refs, list) or not intent_refs:
            errors.append(f"{rel(path)}: frontmatter intent_refs must be a non-empty list")
        elif isinstance(intent_refs, list):
            for ref in intent_refs:
                target, anchor = resolve_doc_ref(ref)
                if target is None:
                    errors.append(f"{rel(path)}: intent_refs entry does not resolve: {ref}")
                    continue
                if not ref_target_exists(target, anchor):
                    errors.append(f"{rel(path)}: intent_refs anchor not found in {rel(target)}: {ref}")
        if "## 意图追溯" not in text:
            errors.append(f"{rel(path)}: missing section '## 意图追溯'")
        if "| 验收证据 |" not in text:
            errors.append(f"{rel(path)}: missing intent traceability row '验收证据'")


def run_checks() -> list[str]:
    errors: list[str] = []
    validate_historical_adrs(errors)
    validate_stale_claims(errors)
    validate_feature_intent(errors)
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
    print("[ok] docs health checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
