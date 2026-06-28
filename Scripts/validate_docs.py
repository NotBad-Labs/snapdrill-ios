#!/usr/bin/env python3
"""Validate high-risk documentation drift.

This is intentionally narrow. It does not judge product strategy; it catches
document states that have repeatedly misled agents: historical ADRs presented as
current truth, stale Firebase-era claims outside historical records, product
positioning resets, and feature specs without explicit intent traceability.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
PACKAGES_ROOT = REPO_ROOT / "Packages"

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

POSITIONING_RESET_CLAIMS = {
    "错题本 App 市场已形成三个梯队",
}

STALE_ALLOWED = set(HISTORICAL_ADRS)
GENERATED_DOCS = {
    DOCS_ROOT / "reference" / "feature-status.md",
    DOCS_ROOT / "reference" / "intent-traceability.md",
}
POSITIONING_POLICY_DOCS = {
    DOCS_ROOT / "explanations" / "positioning-and-audience.md",
}
LEGAL_OR_FACT_GATED_DOCS = {
    DOCS_ROOT / "reference" / "appstore-metadata.md",
    DOCS_ROOT / "explanations" / "privacy-compliance.md",
    DOCS_ROOT / "explanations" / "competitive-analysis.md",
    DOCS_ROOT / "decisions" / "ADR-005-analytics-privacy-strategy.md",
}
POST_PIVOT_BASELINE = "2026-06-13"
VISION_REF_PATTERN = re.compile(r"^vision:P([1-9][0-9]*)$")
ADR_REF_PATTERN = re.compile(r"^ADR-[0-9]{3}$")
HEADING_PATTERN = re.compile(r"^#+\s+(.+?)\s*$", re.MULTILINE)
FRONTMATTER_DATE_PATTERN = re.compile(
    r"^(last_verified|last_updated):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})$",
    re.MULTILINE,
)

POSITIONING_TERMS = {
    "儿童",
    "学生",
    "同学",
    "作业",
    "children",
    "kids",
    "student",
    "students",
    "homework",
}
TAXONOMY_TERMS = {"学科", "年级"}
TAXONOMY_CANONICAL_TERMS = {"学科", "年级"}
TAXONOMY_ALLOW_MARKER = "taxonomy-allow"
TAXONOMY_CODELIKE_PATTERNS = [
    re.compile(pattern)
    for pattern in (
        r"`[^`]*(?:subject|grade|Subject|Grade)[^`]*`",
        r"\bCategorySystemKey\.(?:subject|grade)\b",
        r"\b(?:subject|grade)(?:RawValue|Value|Values|Model|Repository|Manager|Filter|Trend|Totals)\b",
        r"\b(?:Subject|Grade)(?:Model|Repository|Manager|View|ViewModel|Filter|Trend|Totals)\b",
        r"\b[a-zA-Z0-9_.-]+_(?:subject|grade)\b",
        r"\b(?:subject|grade)_[a-zA-Z0-9_.-]+\b",
    )
]
TAXONOMY_AMBIGUOUS_ENGLISH_PATTERN = re.compile(
    r"\b(?:subject|grade|Subject|Grade)\b"
)
NEGATION_MARKERS = {
    "避免",
    "不得",
    "不面向",
    "不建立",
    "不表达",
    "不预期",
    "不对外呈现",
    "不要求",
    "不进入",
    "不申请",
    "不是",
    "非",
    "avoid",
    "do not",
    "does not",
    "not ",
    "not-",
    "non-",
}
POSITIVE_POSITIONING_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in (
        r"面向.*(儿童|学生|同学)",
        r"(儿童|学生)作业(工具|App|应用)",
        r"作业(工具|App|应用)",
        r"(儿童|学生)(用户|市场)",
        r"错题本\s*App",
        r"错题工具",
        r"homework-first",
        r"for\s+(students|kids|children)",
        r"children'?s\s+homework",
    )
]


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


def is_under(path: Path, directory: Path) -> bool:
    try:
        path.relative_to(directory)
    except ValueError:
        return False
    return True


def should_skip_positioning_term_scan(path: Path) -> bool:
    return (
        path in HISTORICAL_ADRS
        or path in GENERATED_DOCS
        or path in POSITIONING_POLICY_DOCS
        or is_under(path, DOCS_ROOT / "ui-redesign")
    )


def should_skip_taxonomy_canonical_scan(path: Path) -> bool:
    return (
        path in HISTORICAL_ADRS
        or path in GENERATED_DOCS
        or is_under(path, DOCS_ROOT / "ui-redesign")
    )


def is_current_or_active_doc(path: Path) -> bool:
    if should_skip_positioning_term_scan(path):
        return False
    return path.suffix == ".md" and is_under(path, DOCS_ROOT)


def is_repo_owned_package_doc(path: Path) -> bool:
    if path.suffix != ".md" or not is_under(path, PACKAGES_ROOT):
        return False
    parts = path.relative_to(PACKAGES_ROOT).parts
    return ".build" not in parts


def iter_taxonomy_contract_docs() -> Iterable[Path]:
    yield from sorted(DOCS_ROOT.rglob("*.md"))
    if PACKAGES_ROOT.exists():
        yield from sorted(path for path in PACKAGES_ROOT.rglob("*.md") if is_repo_owned_package_doc(path))


def has_any(haystack: str, needles: set[str]) -> bool:
    lower = haystack.lower()
    return any(needle.lower() in lower for needle in needles)


def classify_positioning_line(path: Path, line: str) -> tuple[str | None, str | None]:
    """Classify one line for post-pivot positioning drift.

    Only explicit positive positioning regressions are hard errors. Ambiguous
    term hits stay warnings so this heuristic gate cannot block PRs on uncertain
    natural-language interpretation.
    """
    if not has_any(line, POSITIONING_TERMS | TAXONOMY_TERMS):
        return None, None

    if has_any(line, NEGATION_MARKERS):
        return None, None

    if path in LEGAL_OR_FACT_GATED_DOCS:
        return "warning", "legal/fact-gated positioning term requires owner review"

    if any(pattern.search(line) for pattern in POSITIVE_POSITIONING_PATTERNS):
        return "error", "positive pre-pivot positioning term"

    if has_any(line, TAXONOMY_TERMS):
        return "warning", "taxonomy term requires PO context, not a hard fail"

    return "warning", "ambiguous positioning term requires human review"


def classify_taxonomy_canonical_line(path: Path, line: str) -> tuple[str | None, str | None]:
    """Classify current docs for old subject/grade taxonomy contracts.

    The canonical built-in dimension keys are category/source/level/tag. Historical
    logs and legal/fact-gated surfaces are not scrubbed here. English terms are
    only hard-failed when they look like code/contracts; ordinary prose remains a
    warning to avoid false positives such as "subject to".
    """
    if TAXONOMY_ALLOW_MARKER in line:
        return None, None
    if has_any(line, NEGATION_MARKERS):
        return None, None

    has_cn_term = has_any(line, TAXONOMY_CANONICAL_TERMS)
    has_codelike_term = any(pattern.search(line) for pattern in TAXONOMY_CODELIKE_PATTERNS)
    has_ambiguous_english_term = TAXONOMY_AMBIGUOUS_ENGLISH_PATTERN.search(line) is not None
    if not has_cn_term and not has_codelike_term and not has_ambiguous_english_term:
        return None, None

    if path in LEGAL_OR_FACT_GATED_DOCS:
        return "warning", "legal/fact-gated taxonomy term requires owner review"

    if has_cn_term or has_codelike_term:
        return "error", "old taxonomy term; use category/level canonical terminology"

    return "warning", "ambiguous taxonomy term requires human review"


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


def validate_positioning_resets(errors: list[str]) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if path in STALE_ALLOWED:
            continue
        text = read(path)
        for phrase in POSITIONING_RESET_CLAIMS:
            if phrase in text:
                errors.append(
                    f"{rel(path)}:{line_number(text, phrase)} positioning reset: {phrase}"
                )


def validate_contextual_positioning_terms(
    errors: list[str], warnings: list[str]
) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if not is_current_or_active_doc(path):
            continue
        for number, line in enumerate(read(path).splitlines(), start=1):
            severity, message = classify_positioning_line(path, line)
            if severity is None or message is None:
                continue
            rendered = f"{rel(path)}:{number} {message}: {line.strip()}"
            if severity == "error":
                errors.append(rendered)
            else:
                warnings.append(rendered)


def validate_taxonomy_canonical_terms(
    errors: list[str], warnings: list[str]
) -> None:
    for path in iter_taxonomy_contract_docs():
        if path.suffix != ".md" or should_skip_taxonomy_canonical_scan(path):
            continue
        for number, line in enumerate(read(path).splitlines(), start=1):
            severity, message = classify_taxonomy_canonical_line(path, line)
            if severity is None or message is None:
                continue
            rendered = f"{rel(path)}:{number} {message}: {line.strip()}"
            if severity == "error":
                errors.append(rendered)
            else:
                warnings.append(rendered)


def validate_frontmatter_freshness(warnings: list[str]) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if not is_current_or_active_doc(path):
            continue
        text = read(path)
        match = FRONTMATTER_DATE_PATTERN.search(text)
        if match is None:
            continue
        verified_date = match.group(2)
        if verified_date >= POST_PIVOT_BASELINE:
            continue
        if "review_gate:" in text or "audit_note:" in text:
            continue
        warnings.append(
            f"{rel(path)}:{line_number(text, verified_date)} frontmatter date "
            f"{verified_date} predates post-pivot baseline {POST_PIVOT_BASELINE}"
        )


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
    warnings: list[str] = []
    validate_historical_adrs(errors)
    validate_stale_claims(errors)
    validate_positioning_resets(errors)
    validate_contextual_positioning_terms(errors, warnings)
    validate_taxonomy_canonical_terms(errors, warnings)
    validate_feature_intent(errors)
    return errors


def run_warnings() -> list[str]:
    warnings: list[str] = []
    errors: list[str] = []
    validate_contextual_positioning_terms(errors, warnings)
    validate_taxonomy_canonical_terms(errors, warnings)
    validate_frontmatter_freshness(warnings)
    return warnings


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate without modifying files")
    parser.parse_args(argv)

    errors = run_checks()
    warnings = run_warnings()
    for warning in warnings:
        print(f"[warning] {warning}", file=sys.stderr)
    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        return 1
    print("[ok] docs health checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
