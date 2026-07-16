#!/usr/bin/env python3
"""Generate the feature intent traceability index.

The source of truth is each `docs/features/**/feat-*.md` frontmatter
`intent_refs` and `release_refs` fields. This script renders read-only forward
and reverse indexes for durable intent and the effective Release Product
Contract without hand-syncing another status document.
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
SECTION_7_FEATURE_IDS = frozenset(
    {
        "feat-advanced-stats",
        "feat-icloud-sync",
        "feat-word-export",
    }
)
RELEASE_OPERATIONS_DECISIONS = frozenset({"C1-A", "C6-A"})


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
    vision_path = DOCS_ROOT / "explanations" / "vision.md"
    text = vision_path.read_text(encoding="utf-8")
    refs: dict[str, dict[str, str]] = {}
    for match in re.finditer(r"^### (P\d+)\.\s+(.+)$", text, flags=re.MULTILINE):
        refs[f"vision:{match.group(1)}"] = {
            "label": match.group(2).strip(),
            "path": "../explanations/vision.md",
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


def parse_contract_list(
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


def collect_release_refs() -> tuple[dict[str, dict[str, str | None]], set[str]]:
    path = DOCS_ROOT / "reference" / "release-1-contract.md"
    fm = parse_frontmatter(path)
    if fm is None:
        fail([f"{rel(path)}: missing frontmatter"])

    ratified, errors = parse_contract_list(
        fm.get("ratified_decisions"),
        field="ratified_decisions",
        path=path,
        allow_empty=False,
    )
    pending, pending_errors = parse_contract_list(
        fm.get("pending_decisions"),
        field="pending_decisions",
        path=path,
        allow_empty=True,
    )
    errors.extend(pending_errors)

    overlap = sorted(set(ratified) & set(pending))
    if overlap:
        errors.append(f"{rel(path)}: decisions cannot be both ratified and pending {overlap}")

    missing_operations = sorted(RELEASE_OPERATIONS_DECISIONS - set(ratified))
    if missing_operations:
        errors.append(
            f"{rel(path)}: release-operations decisions are not ratified "
            f"{missing_operations}"
        )

    contract_text = path.read_text(encoding="utf-8")
    if SECTION_7_HEADING not in contract_text.splitlines():
        errors.append(f"{rel(path)}: missing exact heading '{SECTION_7_HEADING}'")

    if errors:
        fail(errors)

    known_refs: dict[str, dict[str, str | None]] = {}
    for decision in ratified:
        ref = f"{RELEASE_REF_PREFIX}{decision}"
        known_refs[ref] = {
            "label": decision,
            "path": "release-1-contract.md",
            "operations_owner": (
                "release-operations"
                if decision in RELEASE_OPERATIONS_DECISIONS
                else None
            ),
        }
    known_refs[SECTION_7_REF] = {
        "label": "§7 明确非目标与隐藏能力",
        "path": "release-1-contract.md",
        "operations_owner": None,
    }
    pending_refs = {f"{RELEASE_REF_PREFIX}{decision}" for decision in pending}
    return known_refs, pending_refs


def collect_features(
    known_refs: dict[str, dict[str, str]],
    known_release_refs: dict[str, dict[str, str | None]],
    pending_release_refs: set[str],
) -> list[dict]:
    features: list[dict] = []
    errors: list[str] = []
    operations_refs = {
        ref
        for ref, info in known_release_refs.items()
        if info["operations_owner"] is not None
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

        fabricated_feature_owners = [
            ref for ref in release_refs if ref in operations_refs
        ]
        if fabricated_feature_owners:
            errors.append(
                f"{rel(path)}: release_refs are release-operations-only "
                f"{fabricated_feature_owners}"
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
        features.append(fm)

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
        "| Feature | Release 1 规范归属 |",
        "|---|---|",
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
        lines.append(f"| [{feature['title']}]({path}) | {refs} |")
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
        "## Release 1 -> Feature / Operations",
        "",
        "| Release 1 引用 | Feature / operations owner |",
        "|---|---|",
    ]
    for ref, info in known_release_refs.items():
        owners: list[str] = []
        operations_owner = info["operations_owner"]
        if operations_owner is not None:
            owners.append(f"`{operations_owner}`")
        owners.extend(
            f"[{feature['title']}](../{feature['__path'].relative_to(DOCS_ROOT).as_posix()})"
            for feature in by_ref[ref]
        )
        value = " / ".join(owners) if owners else "—"
        lines.append(f"| {link_release_ref(ref, known_release_refs)} | {value} |")
    lines.append("")
    return lines


def render(
    features: list[dict],
    known_refs: dict[str, dict[str, str]],
    known_release_refs: dict[str, dict[str, str | None]],
) -> str:
    lines = [
        "# 意图追溯索引（自动生成）",
        "",
        "> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。",
        "> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs` / `release_refs`；",
        "> Release 1 精确 ID 从 effective `release-1-contract.md` 的 `ratified_decisions` 读取。",
        "> 实现状态只描述代码路径，不证明 Release 1 合同符合、公开可达或发布就绪。",
        "> `release_refs` 只表示规范归属，不证明语义正确、实现符合或候选纳入；",
        "> 也不证明 M1-M10 已有证据、Capability Manifest inclusion 或发布授权。",
        "",
    ]
    lines.extend(render_known_refs(known_refs))
    lines.extend(render_feature_table(features, known_refs))
    lines.extend(render_reverse_index(features, known_refs))
    lines.extend(render_release_feature_table(features, known_release_refs))
    lines.extend(render_release_reverse_index(features, known_release_refs))
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
