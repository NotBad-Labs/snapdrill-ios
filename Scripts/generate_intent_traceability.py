#!/usr/bin/env python3
"""Generate the feature intent traceability index.

The source of truth is each `docs/features/**/feat-*.md` frontmatter
`intent_refs`, `release_refs`, and active-feature `release_outcomes` fields.
This script renders read-only forward and reverse indexes for durable intent,
the effective Release PRD, and Release 1 Must ownership without
hand-syncing another status document.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
FEATURES_DIR = DOCS_ROOT / "features"
OUTPUT = DOCS_ROOT / "reference" / "intent-traceability.md"

STATUS_LABEL = {
    "implemented": "🧩 实现存在",
    "in-progress": "🛠 进行中",
    "blocked": "⛔ 阻塞",
    "poc-needed": "🔬 需 PoC",
    "backlog": "📋 Backlog",
}
TIER_LABEL = {"free": "免费", "pro": "Pro", "undecided": "未定"}

STATIC_REFS = {
    "positioning-and-audience": {
        "label": "定位与受众 guardrail",
        "path": "../explanations/positioning-and-audience.md",
    }
}
RELEASE_REF_PREFIX = "release-1:"
SECTION_7_REF = f"{RELEASE_REF_PREFIX}section-7"
SECTION_7_HEADING = "## 7. 明确非目标与隐藏能力"
RELEASE_ORACLE_HEADING = "### M1-M10 双向追溯"
SECTION_7_FEATURE_IDS = frozenset(
    {
        "feat-advanced-stats",
        "feat-icloud-sync",
        "feat-word-export",
    }
)
MUST_OUTCOME_PATTERN = re.compile(r"^\d+\. \*\*(M(?:10|[1-9]))\*\* — .+$", re.MULTILINE)
RATIFIED_DECISION_PATTERN = re.compile(
    r"^\|\s*([^|]+?)\s*\|\s*RATIFIED\s*\|",
    re.MULTILINE,
)


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def parse_frontmatter(path: Path) -> dict | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    data = yaml.safe_load(parts[1]) or {}
    data["__path"] = path
    return data


def markdown_title(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem


def historical_adr_label(path: Path, label: str) -> str:
    fm = parse_frontmatter(path) or {}
    if fm.get("historical_record") is not True:
        return label

    status = fm.get("current_status")
    authority = fm.get("current_authority")
    status_label = {
        "suspended": "已挂起",
        "superseded": "已取代",
    }.get(status, "历史记录")

    if isinstance(authority, str) and authority:
        authority_path = Path(authority)
        authority_name = authority_path.stem
        if authority_name.startswith("ADR-"):
            authority_ref = "-".join(authority_name.split("-")[:2])
        else:
            authority_ref = authority_name
        return f"历史记录（{status_label}，当前权威：{authority_ref}）：{label}"

    return f"历史记录（{status_label}）：{label}"


def collect_vision_refs() -> dict[str, dict[str, str]]:
    vision_path = DOCS_ROOT / "product" / "vision.md"
    text = vision_path.read_text(encoding="utf-8")
    refs: dict[str, dict[str, str]] = {}
    for match in re.finditer(r"^### (P\d+)\.\s+(.+)$", text, flags=re.MULTILINE):
        refs[f"vision:{match.group(1)}"] = {
            "label": match.group(2).strip(),
            "path": "../product/vision.md",
        }
    return refs


def collect_adr_refs() -> dict[str, dict[str, str]]:
    refs: dict[str, dict[str, str]] = {}
    for path in sorted((DOCS_ROOT / "decisions").glob("ADR-*.md")):
        key = path.stem.split("-", 2)
        if len(key) < 2:
            continue
        ref = f"ADR-{key[1]}"
        label = markdown_title(path).removeprefix(f"{ref}: ").strip()
        refs[ref] = {
            "label": historical_adr_label(path, label),
            "path": "../decisions/" + path.name,
        }
    return refs


def collect_known_refs() -> dict[str, dict[str, str]]:
    refs = collect_vision_refs()
    refs.update(collect_adr_refs())
    refs.update(STATIC_REFS)
    return refs


def fail(errors: list[str]) -> None:
    for error in errors:
        print(f"[error] {error}", file=sys.stderr)
    sys.exit(1)


def parse_prd_list(
    value: object,
    *,
    field: str,
    path: Path,
    allow_empty: bool,
) -> tuple[list[str], list[str]]:
    if not isinstance(value, list):
        return [], [f"{rel(path)}: {field} must be a list"]
    if not value and not allow_empty:
        return [], [f"{rel(path)}: {field} must be a non-empty list"]

    errors: list[str] = []
    values: list[str] = []
    for entry in value:
        if not isinstance(entry, str) or not entry:
            errors.append(f"{rel(path)}: {field} entries must be non-empty strings")
            continue
        values.append(entry)

    duplicates = sorted({entry for entry in values if values.count(entry) > 1})
    if duplicates:
        errors.append(f"{rel(path)}: duplicate {field} {duplicates}")
    return values, errors


def collect_release_outcomes() -> list[str]:
    path = DOCS_ROOT / "product" / "release-1-prd.md"
    outcomes = MUST_OUTCOME_PATTERN.findall(path.read_text(encoding="utf-8"))
    expected = [f"M{index}" for index in range(1, 11)]
    if outcomes != expected:
        fail(
            [
                f"{rel(path)}: Must outcomes must be labeled exactly M1-M10 "
                f"in order; found {outcomes}"
            ]
        )
    return outcomes


def collect_release_operations_refs(
    known_release_refs: set[str],
    pending_release_refs: set[str],
) -> set[str]:
    path = DOCS_ROOT / "how-to" / "release-and-ci.md"
    fm = parse_frontmatter(path)
    if fm is None:
        fail([f"{rel(path)}: missing frontmatter"])

    refs, errors = parse_prd_list(
        fm.get("release_refs"),
        field="release_refs",
        path=path,
        allow_empty=False,
    )
    pending = sorted(ref for ref in refs if ref in pending_release_refs)
    if pending:
        errors.append(f"{rel(path)}: pending release_refs {pending}")
    unknown = sorted(
        ref
        for ref in refs
        if ref not in known_release_refs and ref not in pending_release_refs
    )
    if unknown:
        errors.append(f"{rel(path)}: unknown release_refs {unknown}")
    if SECTION_7_REF in refs:
        errors.append(f"{rel(path)}: {SECTION_7_REF} is not an operations decision")
    if errors:
        fail(errors)
    return set(refs)


def collect_release_oracles(outcomes: list[str]) -> dict[str, dict[str, str]]:
    path = DOCS_ROOT / "how-to" / "release-and-ci.md"
    lines = path.read_text(encoding="utf-8").splitlines()
    heading_indexes = [
        index for index, line in enumerate(lines) if line == RELEASE_ORACLE_HEADING
    ]
    if len(heading_indexes) != 1:
        fail(
            [
                f"{rel(path)}: requires exactly one exact heading "
                f"'{RELEASE_ORACLE_HEADING}'"
            ]
        )

    section: list[str] = []
    for line in lines[heading_indexes[0] + 1 :]:
        if line.startswith("#"):
            break
        section.append(line)

    rows: list[tuple[str, str, str]] = []
    errors: list[str] = []
    for line in section:
        if not line.startswith("|"):
            continue
        raw_cells = line.split("|")
        outcome = raw_cells[1].strip() if len(raw_cells) > 1 else ""
        if re.fullmatch(r"M\d+", outcome) is None:
            continue
        if len(raw_cells) != 5 or raw_cells[0] or raw_cells[-1]:
            errors.append(
                f"{rel(path)}: {outcome} oracle row must contain exactly 3 columns"
            )
            continue
        cells = [cell.strip() for cell in raw_cells[1:-1]]
        rows.append((cells[0], cells[1], cells[2]))

    row_ids = [row[0] for row in rows]
    if row_ids != outcomes:
        errors.append(
            f"{rel(path)}: M1-M10 oracle rows must match PRD order exactly; "
            f"found {row_ids}"
        )
    for outcome, oracle, owner in rows:
        if not oracle or oracle == "—":
            errors.append(f"{rel(path)}: {outcome} requires a non-empty outcome oracle")
        if not owner or owner == "—":
            errors.append(f"{rel(path)}: {outcome} requires a non-empty DRI")
    if errors:
        fail(errors)
    return {
        outcome: {"oracle": oracle, "owner": owner}
        for outcome, oracle, owner in rows
    }


def collect_release_refs() -> tuple[dict[str, dict[str, str | None]], set[str]]:
    path = DOCS_ROOT / "product" / "release-1-prd.md"
    fm = parse_frontmatter(path)
    if fm is None:
        fail([f"{rel(path)}: missing frontmatter"])

    ratified, errors = parse_prd_list(
        fm.get("ratified_decisions"),
        field="ratified_decisions",
        path=path,
        allow_empty=False,
    )
    pending, pending_errors = parse_prd_list(
        fm.get("pending_decisions"),
        field="pending_decisions",
        path=path,
        allow_empty=True,
    )
    errors.extend(pending_errors)

    overlap = sorted(set(ratified) & set(pending))
    if overlap:
        errors.append(f"{rel(path)}: decisions cannot be both ratified and pending {overlap}")

    prd_text = path.read_text(encoding="utf-8")
    body_ratified = RATIFIED_DECISION_PATTERN.findall(prd_text)
    if body_ratified != ratified:
        errors.append(
            f"{rel(path)}: ratified_decisions frontmatter must match RATIFIED "
            f"decision-summary rows exactly; frontmatter={ratified}, body={body_ratified}"
        )
    if SECTION_7_HEADING not in prd_text.splitlines():
        errors.append(f"{rel(path)}: missing exact heading '{SECTION_7_HEADING}'")

    if errors:
        fail(errors)

    known_refs: dict[str, dict[str, str | None]] = {}
    for decision in ratified:
        ref = f"{RELEASE_REF_PREFIX}{decision}"
        known_refs[ref] = {
            "label": decision,
            "path": "../product/release-1-prd.md",
            "operations_consumer": None,
        }
    known_refs[SECTION_7_REF] = {
        "label": "§7 明确非目标与隐藏能力",
        "path": "../product/release-1-prd.md",
        "operations_consumer": None,
    }
    pending_refs = {f"{RELEASE_REF_PREFIX}{decision}" for decision in pending}
    operations_refs = collect_release_operations_refs(set(known_refs), pending_refs)
    for ref in operations_refs:
        known_refs[ref]["operations_consumer"] = "release-operations"
    return known_refs, pending_refs


def collect_features(
    known_refs: dict[str, dict[str, str]],
    known_release_refs: dict[str, dict[str, str | None]],
    pending_release_refs: set[str],
) -> list[dict]:
    features: list[dict] = []
    errors: list[str] = []
    known_outcomes = collect_release_outcomes()
    operations_refs = {
        ref
        for ref, info in known_release_refs.items()
        if info["operations_consumer"] is not None
    }
    for path in sorted(FEATURES_DIR.rglob("feat-*.md")):
        if path.name == "template.md":
            continue
        fm = parse_frontmatter(path)
        if fm is None:
            errors.append(f"{rel(path)}: missing frontmatter")
            continue
        refs = fm.get("intent_refs")
        if not isinstance(refs, list) or not refs:
            errors.append(f"{rel(path)}: intent_refs must be a non-empty list")
            continue
        unknown = [ref for ref in refs if ref not in known_refs]
        if unknown:
            errors.append(f"{rel(path)}: unknown intent_refs {unknown}")

        release_refs = fm.get("release_refs")
        if not isinstance(release_refs, list):
            errors.append(f"{rel(path)}: release_refs must be a non-empty list")
            features.append(fm)
            continue
        if not release_refs:
            errors.append(f"{rel(path)}: release_refs must be a non-empty list")
            features.append(fm)
            continue

        non_string_refs = [
            ref for ref in release_refs if not isinstance(ref, str) or not ref
        ]
        if non_string_refs:
            errors.append(
                f"{rel(path)}: release_refs entries must be non-empty strings"
            )
            features.append(fm)
            continue

        duplicate_release_refs = sorted(
            {ref for ref in release_refs if release_refs.count(ref) > 1}
        )
        if duplicate_release_refs:
            errors.append(
                f"{rel(path)}: duplicate release_refs {duplicate_release_refs}"
            )

        pending = [ref for ref in release_refs if ref in pending_release_refs]
        if pending:
            errors.append(f"{rel(path)}: pending release_refs {pending}")
        unknown_release_refs = [
            ref
            for ref in release_refs
            if ref not in known_release_refs and ref not in pending_release_refs
        ]
        if unknown_release_refs:
            errors.append(
                f"{rel(path)}: unknown release_refs {unknown_release_refs}"
            )

        invalid_feature_consumers = [
            ref for ref in release_refs if ref in operations_refs
        ]
        if invalid_feature_consumers:
            errors.append(
                f"{rel(path)}: release_refs are release-operations-only "
                f"{invalid_feature_consumers}"
            )

        is_active = path.parent.name == "active"
        exact_release_refs = [
            ref
            for ref in release_refs
            if ref in known_release_refs and ref != SECTION_7_REF
        ]
        if is_active and not exact_release_refs:
            errors.append(
                f"{rel(path)}: active feature requires at least one exact "
                "ratified release ref"
            )

        if SECTION_7_REF in release_refs:
            feature_id = fm.get("id")
            if (
                path.parent.name != "backlog"
                or feature_id not in SECTION_7_FEATURE_IDS
            ):
                errors.append(
                    f"{rel(path)}: {SECTION_7_REF} is allowed only for "
                    f"{sorted(SECTION_7_FEATURE_IDS)}"
                )

        release_outcomes = fm.get("release_outcomes")
        if is_active and not isinstance(release_outcomes, list):
            errors.append(f"{rel(path)}: active feature release_outcomes must be a list")
            release_outcomes = []
        elif release_outcomes is None:
            release_outcomes = []
        elif not isinstance(release_outcomes, list):
            errors.append(f"{rel(path)}: release_outcomes must be a list")
            release_outcomes = []

        invalid_outcomes = [
            outcome
            for outcome in release_outcomes
            if not isinstance(outcome, str) or outcome not in known_outcomes
        ]
        if invalid_outcomes:
            errors.append(f"{rel(path)}: unknown release_outcomes {invalid_outcomes}")
        duplicate_outcomes = sorted(
            {
                outcome
                for outcome in release_outcomes
                if release_outcomes.count(outcome) > 1
            }
        )
        if duplicate_outcomes:
            errors.append(f"{rel(path)}: duplicate release_outcomes {duplicate_outcomes}")
        if not is_active and release_outcomes:
            errors.append(
                f"{rel(path)}: release_outcomes may be non-empty only for active features"
            )
        fm["release_outcomes"] = release_outcomes
        features.append(fm)

    consumed_release_refs = set(operations_refs)
    for feature in features:
        feature_release_refs = feature.get("release_refs")
        if isinstance(feature_release_refs, list):
            consumed_release_refs.update(
                ref for ref in feature_release_refs if isinstance(ref, str)
            )

    unconsumed_release_refs = [
        ref
        for ref in known_release_refs
        if ref != SECTION_7_REF and ref not in consumed_release_refs
    ]
    if unconsumed_release_refs:
        errors.append(
            "ratified release refs require at least one Feature or "
            f"release-operations consumer {unconsumed_release_refs}"
        )

    owned_outcomes = {
        outcome
        for feature in features
        if feature["__path"].parent.name == "active"
        for outcome in feature.get("release_outcomes", [])
        if isinstance(outcome, str)
    }
    unowned_outcomes = [
        outcome for outcome in known_outcomes if outcome not in owned_outcomes
    ]
    if unowned_outcomes:
        errors.append(
            "Release 1 Must outcomes require at least one active Feature owner "
            f"{unowned_outcomes}"
        )

    if errors:
        fail(errors)
    return features


def link_ref(ref: str, known_refs: dict[str, dict[str, str]]) -> str:
    info = known_refs[ref]
    return f"[`{ref}`]({info['path']})"


def render_known_refs(known_refs: dict[str, dict[str, str]]) -> list[str]:
    lines = [
        "## 可引用上游",
        "",
        "| 引用 | 含义 | 来源 |",
        "|---|---|---|",
    ]
    for ref in sorted(known_refs):
        info = known_refs[ref]
        lines.append(f"| `{ref}` | {info['label']} | [{info['path']}]({info['path']}) |")
    lines.append("")
    return lines


def render_feature_table(features: list[dict], known_refs: dict[str, dict[str, str]]) -> list[str]:
    lines = [
        "## Feature -> Durable Intent",
        "",
        "| Feature | 实现状态 | 层级 | 上游意图 |",
        "|---|---|---|---|",
    ]
    for feature in features:
        path = "../" + feature["__path"].relative_to(DOCS_ROOT).as_posix()
        title = feature["title"]
        status = STATUS_LABEL.get(feature["status"], feature["status"])
        tier = TIER_LABEL.get(feature["tier"], feature["tier"])
        refs = " / ".join(link_ref(ref, known_refs) for ref in feature["intent_refs"])
        lines.append(f"| [{title}]({path}) | {status} | {tier} | {refs} |")
    lines.append("")
    return lines


def render_reverse_index(features: list[dict], known_refs: dict[str, dict[str, str]]) -> list[str]:
    by_ref: dict[str, list[dict]] = {ref: [] for ref in known_refs}
    for feature in features:
        for ref in feature["intent_refs"]:
            by_ref[ref].append(feature)

    lines = [
        "## Durable Intent -> Feature",
        "",
        "| 上游意图 | 承接 Feature |",
        "|---|---|",
    ]
    for ref in sorted(known_refs):
        linked_features = by_ref[ref]
        if linked_features:
            value = " / ".join(
                f"[{feature['title']}](../{feature['__path'].relative_to(DOCS_ROOT).as_posix()})"
                for feature in linked_features
            )
        else:
            value = "—"
        lines.append(f"| {link_ref(ref, known_refs)} | {value} |")
    lines.append("")
    return lines


def link_release_ref(
    ref: str,
    known_release_refs: dict[str, dict[str, str | None]],
) -> str:
    info = known_release_refs[ref]
    return f"[`{ref}`]({info['path']})"


def ordered_release_refs(
    refs: list[str],
    known_release_refs: dict[str, dict[str, str | None]],
) -> list[str]:
    order = {ref: index for index, ref in enumerate(known_release_refs)}
    return sorted(refs, key=order.__getitem__)


def render_release_feature_table(
    features: list[dict],
    known_release_refs: dict[str, dict[str, str | None]],
) -> list[str]:
    lines = [
        "## Feature -> Release 1",
        "",
        "| Feature | Release 1 消费引用 | Must outcome owner / contributor |",
        "|---|---|---|",
    ]
    for feature in features:
        path = "../" + feature["__path"].relative_to(DOCS_ROOT).as_posix()
        refs = " / ".join(
            link_release_ref(ref, known_release_refs)
            for ref in ordered_release_refs(
                feature["release_refs"],
                known_release_refs,
            )
        )
        outcomes = " / ".join(f"`{value}`" for value in feature["release_outcomes"])
        lines.append(
            f"| [{feature['title']}]({path}) | {refs} | {outcomes or '—'} |"
        )
    lines.append("")
    return lines


def render_release_outcome_index(
    features: list[dict],
    outcomes: list[str],
    oracles: dict[str, dict[str, str]],
) -> list[str]:
    by_outcome: dict[str, list[dict]] = {outcome: [] for outcome in outcomes}
    for feature in features:
        if feature["__path"].parent.name != "active":
            continue
        for outcome in feature["release_outcomes"]:
            by_outcome[outcome].append(feature)

    lines = [
        "## Release 1 Must Outcome -> Feature / Proof Plan",
        "",
        "| Must | Owning / contributing active Feature | Operational outcome oracle | DRI |",
        "|---|---|---|---|",
    ]
    for outcome in outcomes:
        linked_features = " / ".join(
            f"[{feature['title']}](../{feature['__path'].relative_to(DOCS_ROOT).as_posix()})"
            for feature in by_outcome[outcome]
        )
        oracle = oracles[outcome]
        lines.append(
            f"| [`{outcome}`](../product/release-1-prd.md#31-must-outcomes) | "
            f"{linked_features} | {oracle['oracle']} | {oracle['owner']} |"
        )
    lines.append("")
    return lines


def render_release_reverse_index(
    features: list[dict],
    known_release_refs: dict[str, dict[str, str | None]],
) -> list[str]:
    by_ref: dict[str, list[dict]] = {ref: [] for ref in known_release_refs}
    for feature in features:
        for ref in feature["release_refs"]:
            by_ref[ref].append(feature)

    lines = [
        "## Release 1 -> Feature / Operations Consumers",
        "",
        "| Release 1 引用 | Feature / operations consumer |",
        "|---|---|",
    ]
    for ref, info in known_release_refs.items():
        consumers: list[str] = []
        operations_consumer = info["operations_consumer"]
        if operations_consumer is not None:
            consumers.append(f"`{operations_consumer}`")
        consumers.extend(
            f"[{feature['title']}](../{feature['__path'].relative_to(DOCS_ROOT).as_posix()})"
            for feature in by_ref[ref]
        )
        value = " / ".join(consumers) if consumers else "—"
        lines.append(f"| {link_release_ref(ref, known_release_refs)} | {value} |")
    lines.append("")
    return lines


def render(
    features: list[dict],
    known_refs: dict[str, dict[str, str]],
    known_release_refs: dict[str, dict[str, str | None]],
) -> str:
    outcomes = collect_release_outcomes()
    oracles = collect_release_oracles(outcomes)
    lines = [
        "# 意图追溯索引（自动生成）",
        "",
        "> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。",
        "> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs` / `release_refs` / `release_outcomes`；",
        "> Release 1 精确 ID 从 effective `docs/product/release-1-prd.md` 的 `ratified_decisions` 读取。",
        "> 实现状态只描述代码路径，不证明 Release 1 PRD 符合、公开可达或发布就绪。",
        "> `release_refs` 只表示 Feature 消费 / 追溯边，不把 Feature 变成上游裁决 owner；",
        "> `release_outcomes` 与 operational oracle 行只证明 owner / proof-plan 声明完整；",
        "> 它们不证明语义正确、实现符合、M1-M10 已执行证据、Capability Manifest inclusion 或发布授权。",
        "",
    ]
    lines.extend(render_known_refs(known_refs))
    lines.extend(render_feature_table(features, known_refs))
    lines.extend(render_reverse_index(features, known_refs))
    lines.extend(render_release_feature_table(features, known_release_refs))
    lines.extend(render_release_reverse_index(features, known_release_refs))
    lines.extend(render_release_outcome_index(features, outcomes, oracles))
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="生成 feature 意图追溯索引")
    parser.add_argument("--check", action="store_true", help="只校验索引是否最新，不写")
    args = parser.parse_args()

    known_refs = collect_known_refs()
    known_release_refs, pending_release_refs = collect_release_refs()
    features = collect_features(
        known_refs,
        known_release_refs,
        pending_release_refs,
    )
    content = render(features, known_refs, known_release_refs)

    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current.strip() != content.strip():
            print(
                "[error] intent-traceability.md 已过期，请运行 "
                "`python3 Scripts/generate_intent_traceability.py` 重新生成",
                file=sys.stderr,
            )
            sys.exit(1)
        print("[ok] intent-traceability.md 最新")
        return

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(content, encoding="utf-8")
    print(f"[ok] 已生成 {rel(OUTPUT)}")


if __name__ == "__main__":
    main()
