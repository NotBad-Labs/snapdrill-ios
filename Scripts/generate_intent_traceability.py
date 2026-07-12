#!/usr/bin/env python3
"""Generate the feature intent traceability index.

The source of truth is each `docs/features/**/feat-*.md` frontmatter
`intent_refs` field. This script renders a read-only reverse index so agents can
see which features inherit from each durable product intent without hand-syncing
another status document.
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
    "implemented": "✅ 已实现",
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


def collect_features(known_refs: dict[str, dict[str, str]]) -> list[dict]:
    features: list[dict] = []
    errors: list[str] = []
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
        features.append(fm)

    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        sys.exit(1)
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
        "## Feature -> Intent",
        "",
        "| Feature | 状态 | 层级 | 上游意图 |",
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
        "## Intent -> Feature",
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


def render(features: list[dict], known_refs: dict[str, dict[str, str]]) -> str:
    lines = [
        "# 意图追溯索引（自动生成）",
        "",
        "> ⚠️ 本文件由 `Scripts/generate_intent_traceability.py` 自动生成，**禁止手动编辑**。",
        "> 来源 = 各 `docs/features/**/feat-*.md` frontmatter 的 `intent_refs`。",
        "> 本索引证明“已声明上游引用”，不证明语义完全正确；语义仍需人工 review 和代码/测试实证。",
        "",
    ]
    lines.extend(render_known_refs(known_refs))
    lines.extend(render_feature_table(features, known_refs))
    lines.extend(render_reverse_index(features, known_refs))
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="生成 feature 意图追溯索引")
    parser.add_argument("--check", action="store_true", help="只校验索引是否最新，不写")
    args = parser.parse_args()

    known_refs = collect_known_refs()
    content = render(collect_features(known_refs), known_refs)

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
