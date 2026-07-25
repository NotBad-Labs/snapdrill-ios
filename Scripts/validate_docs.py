#!/usr/bin/env python3
"""Validate high-risk documentation drift.

This is intentionally narrow. It does not judge product strategy; it catches
document states that have repeatedly misled agents: historical ADRs presented as
current truth, stale Firebase-era claims outside historical records, product
positioning resets, duplicate release PRD authority, and feature specs without
explicit intent traceability.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable

try:
    from Scripts import validate_document_control
except ModuleNotFoundError:
    import validate_document_control

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
PACKAGES_ROOT = REPO_ROOT / "Packages"
PRODUCT_VISION = DOCS_ROOT / "product" / "vision.md"
RELEASE_ONE_PRD = DOCS_ROOT / "product" / "release-1-prd.md"
ACTIVE_FEATURES_ROOT = DOCS_ROOT / "features" / "active"
SCOPE_AND_ROADMAP = DOCS_ROOT / "reference" / "scope-and-roadmap.md"
ADR_ROOT = DOCS_ROOT / "decisions"
ADR_POLICY = ADR_ROOT / "README.md"
RETIRED_DECISIONS = ADR_ROOT / "retired-decisions.md"

LEGACY_PRODUCT_AUTHORITY_PATTERNS = (
    ("Product Constitution", re.compile(r"Product\s+Constitution")),
    ("Release Product Contract", re.compile(r"Release\s+Product\s+Contract")),
    ("Release 1 Product Contract", re.compile(r"Release\s+1\s+Product\s+Contract")),
    ("Release Contract", re.compile(r"Release\s+Contract")),
    ("Release 合同", re.compile(r"Release\s+(?:1\s+)?合同")),
)
STALE_CURRENT_CLAIMS = {
    "海外版保留 Firebase",
    "海外版 Firebase",
    "待 C 路径",
    "编译层彻底剔除待",
}

POSITIONING_RESET_CLAIMS = {
    "错题本 App 市场已形成三个梯队",
}

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
REPOSITORY_FACT_POLICY_REQUIREMENTS = {
    DOCS_ROOT / "reference" / "document-control.md": {
        "key facts have a tracked owner": (
            "仓库事实归属",
            "关键客观事实",
            "owning tracked source",
        ),
        "private state is not an owner": ("不得成为关键事实的", "唯一持有者"),
        "external findings require verification": (
            "外部复核输出只是候选证据",
            "当前 DRI 必须重新验证",
        ),
        "raw transcripts and secrets stay out of Git": (
            "raw transcript 不入仓",
            "不得进入 Git",
        ),
    },
}
POST_PIVOT_BASELINE = "2026-06-13"
VISION_REF_PATTERN = re.compile(r"^vision:P([1-9][0-9]*)$")
ADR_REF_PATTERN = re.compile(r"^ADR-[0-9]{3}$")
ADR_FILENAME_PATTERN = re.compile(r"^(ADR-[0-9]{3})-[a-z0-9-]+\.md$")
ADR_TITLE_PATTERN = re.compile(r"^# (ADR-[0-9]{3}): .+$", re.MULTILINE)
RETIRED_ADR_ROW_PATTERN = re.compile(
    r"^\|\s*(ADR-[0-9]{3})\s*\|[^|]+\|\s*(superseded|suspended|withdrawn)\b",
    re.MULTILINE,
)
CURRENT_ADR_ROW_PATTERN = re.compile(
    r"^\|\s*\[(ADR-[0-9]{3})\]\((ADR-[0-9]{3}-[a-z0-9-]+\.md)\)"
    r"\s*\|[^|]+\|\s*accepted\s*\|$",
    re.MULTILINE,
)
HEADING_PATTERN = re.compile(r"^#+\s+(.+?)\s*$", re.MULTILINE)
FRONTMATTER_DATE_PATTERN = re.compile(
    r"^(last_verified|last_updated):\s*([0-9]{4}-[0-9]{2}-[0-9]{2})$",
    re.MULTILINE,
)
PRD_FILENAME_PATTERN = re.compile(r"(?:^|[-_.])prd(?:[-_.]|$)", re.IGNORECASE)
H2_PATTERN = re.compile(r"^## ([^\n]+)$", re.MULTILINE)

ACTIVE_FEATURE_NUMBERED_HEADINGS = (
    "1. 为什么做 (Why)",
    "2. 需求规则 (What)",
    "3. 技术设计 (How)",
    "4. 验证标准 (Verify)",
)
ACTIVE_FEATURE_ALLOWED_H2 = {
    *ACTIVE_FEATURE_NUMBERED_HEADINGS,
    "意图追溯（永久保留）",
    "当前执行准入（非产品 SSOT）",
    "关联",
}
ACTIVE_ADR_STATUSES = {"proposed", "accepted"}
ACTIVE_ADR_REQUIRED_HEADINGS = (
    "背景（Context）",
    "决策（Decision）",
    "备选方案（Alternatives）",
    "后果（Consequences）",
    "验证与复议触发器（Validation）",
    "关联权威（Related authorities）",
)
ADR_POLICY_REQUIREMENTS = {
    "ADR scope": ("只保存当前可用于指导实现的", "技术取舍"),
    "admission criteria": ("## 准入标准", "至少存在两个真实可行的技术方案"),
    "non-ADR routing": ("以下内容不得创建 ADR", "Release 范围", "商业政策"),
    "active statuses": ("`proposed`", "`accepted`"),
    "proposed decisions stay candidates": (
        "`authority/candidate`",
        "不得被 feature",
        "`intent_refs`",
    ),
    "retirement path": ("retired-decisions.md", "Git 历史"),
}
RETIRED_DECISION_REQUIREMENTS = {
    "history-only role": (
        "固定基线历史证据",
        "不能",
        "定义当前需求、范围、架构或执行顺序",
    ),
    "follow current owner": ("只跟随“当前 owner”列",),
}
ROADMAP_REQUIRED_MARKERS = {
    "candidate-only role": (
        "只维护尚未进入当前发布承诺的跨功能候选及其重入条件",
        "不定义当前发布范围",
    ),
    "product authority pointers": (
        "Product Vision & Principles",
        "Release 1 PRD",
        "feature spec",
    ),
    "candidate table disclaimer": (
        "不是功能承诺或 Release 1 状态表",
    ),
}
ROADMAP_PARALLEL_AUTHORITY_HEADINGS = (
    "## 当前上游边界",
    "## Release 1 投资边界",
    "## 能力簇状态",
    "## 耐久非目标",
)
COLD_START_ENTRYPOINT_REQUIREMENTS = {
    REPO_ROOT / "README.md": {
        "unique cold-start entrypoint": (
            "根 README 是人和 Agent 的唯一冷启动入口",
        ),
        "product authority routes": (
            "docs/product/vision.md",
            "docs/product/release-1-prd.md",
            "docs/features/",
        ),
        "AGENTS is not product authority": (
            "AGENTS.md",
            "不是产品文档",
        ),
    },
    DOCS_ROOT / "README.md": {
        "route back to root README": (
            "从仓库根 [README](../README.md) 开始",
        ),
        "root owns cold start": (
            "它是人和 Agent 的唯一冷启动入口",
        ),
        "navigation only": (
            "本页只负责",
            "不复制产品范围",
        ),
    },
    REPO_ROOT / "AGENTS.md": {
        "read root README first": (
            "先读根 [`README.md`](README.md)",
        ),
        "execution rules are not product authority": (
            "不是产品",
            "文档、架构快照或 API 手册",
        ),
    },
}
COLD_START_DECLARATION = "唯一冷启动入口"
COLD_START_DECLARATION_OWNERS = {
    REPO_ROOT / "README.md",
    DOCS_ROOT / "README.md",
}

CURRENT_ADMISSION_POLICY_REQUIREMENTS = {
    REPO_ROOT / "AGENTS.md": {
        "Current Admission owner link": ("definition-of-ready.md#current-admission",),
        "historical artifacts are evidence only": ("默认只作证据",),
        "queue entry requires current admission": (
            "bet、active write 或 frozen merge queue",
        ),
    },
    DOCS_ROOT / "README.md": {
        "Current Admission owner link": ("definition-of-ready.md#current-admission",),
        "historical artifacts are evidence only": ("默认只是证据",),
        "admission is not product authority": ("执行准入不产生", "产品要求"),
    },
    DOCS_ROOT / "how-to" / "definition-of-ready.md": {
        "historical artifacts are evidence only": ("are evidence by default",),
        "age or number does not authorize": ("Age, number",),
        "workflow state does not authorize": (
            "open / closed state, Draft / Ready state",
        ),
        "label or author does not authorize": ("label, author",),
        "prior authorization does not authorize": ("prior authorization",),
        "historical CI does not authorize": ("historical CI success",),
        "queue entry requires current admission": (
            "bet, active write, or frozen merge queue",
        ),
    },
    DOCS_ROOT / "how-to" / "parallel-lanes.md": {
        "Current Admission owner link": ("definition-of-ready.md#current-admission",),
        "historical artifacts are evidence only": ("默认只作证据",),
        "artifact metadata does not admit work": ("不能单独准入",),
    },
    DOCS_ROOT / "how-to" / "shape-up.md": {
        "Current Admission owner link": ("definition-of-ready.md#current-admission",),
        "historical artifacts are evidence only": ("默认只作历史证据",),
        "accepted bet still requires admission": ("不能绕过 Current Admission",),
    },
    DOCS_ROOT / "reference" / "document-control.md": {
        "Current Admission owner link": ("definition-of-ready.md#current-admission",),
        "historical artifacts are evidence only": ("默认只作", "证据"),
        "admission is not product authority": ("不新增产品 SSOT",),
    },
}

MERGE_AUTHORIZATION_POLICY_REQUIREMENTS = {
    DOCS_ROOT / "how-to" / "parallel-lanes.md": {
        "PO need not transcribe the SHA": ("PO 无需抄写",),
        "merge binds the displayed exact head": ("`expected_head_sha`",),
        "a moved head invalidates authorization": ("head 移动", "原授权失效"),
    },
    REPO_ROOT / ".github" / "PULL_REQUEST_TEMPLATE.md": {
        "PO need not transcribe the SHA": ("PO 无需抄写",),
        "merge binds the displayed exact head": ("`expected_head_sha`",),
        "a moved head invalidates authorization": ("head 移动", "原授权失效"),
    },
}

CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS = {
    "base and current evidence": ("Base / current evidence",),
    "authority and outcome": ("Authority / outcome",),
    "owner scope and red lines": ("Owner / scope / red lines",),
    "acceptance and validation": ("Acceptance / validation",),
    "routing dependencies and gates": (
        "Routing / dependencies / unresolved gates",
    ),
}

CURRENT_ADMISSION_TEMPLATE_REQUIREMENTS = {
    REPO_ROOT / ".github" / "ISSUE_TEMPLATE" / "bug_report.md": {
        "current admission section": ("## Current Admission",),
        **CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS,
        "outcome": ("## 期望行为",),
        "scope": ("## Scope（做什么）",),
        "red lines": ("## No-Go（不做什么）",),
        "acceptance criteria": ("## 验收标准",),
        "validation level": ("## 验证等级",),
    },
    REPO_ROOT / ".github" / "ISSUE_TEMPLATE" / "chore.md": {
        "current admission section": ("## Current Admission",),
        **CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS,
        "outcome": ("## 任务描述",),
        "scope": ("## Scope（做什么）",),
        "red lines": ("## No-Go（不做什么）",),
        "acceptance criteria": ("## 验收标准",),
        "validation level": ("## 验证等级",),
    },
    REPO_ROOT / ".github" / "ISSUE_TEMPLATE" / "feature_request.md": {
        "current admission section": ("## Current Admission",),
        **CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS,
        "outcome": ("## Repo-visible Outcome",),
        "scope": ("## Scope（做什么）",),
        "red lines": ("## No-Go（不做什么）",),
        "acceptance criteria": ("## 验收标准",),
        "validation level": ("## 验证等级",),
    },
    REPO_ROOT / ".github" / "PULL_REQUEST_TEMPLATE.md": {
        "current admission section": ("## Current Admission / T0",),
        **CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS,
        "outcome": ("## Summary",),
        "scope": ("## Scope",),
        "red lines": ("## Out of Scope / Red Lines",),
        "acceptance criteria": ("验收标准（Given-When-Then）",),
        "validation level": ("## Validation",),
    },
    DOCS_ROOT / "features" / "template.md": {
        "current admission section": ("## 当前执行准入（非产品 SSOT）",),
        **CURRENT_ADMISSION_COMMON_TEMPLATE_FIELDS,
        "outcome": ("## 1. 为什么做",),
        "scope": ("## 2. 需求规则",),
        "red lines": ("**边界 / 不做**",),
        "acceptance criteria": ("## 4. 验证标准",),
    },
}

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


def document_rule(path: Path) -> dict[str, object] | None:
    relative_path = rel(path)
    registry = validate_document_control.load_registry()
    matches = [
        rule
        for rule in registry.get("rules", [])
        if isinstance(rule, dict)
        and validate_document_control.matches_rule(relative_path, rule)
    ]
    return matches[0] if len(matches) == 1 else None


def is_inactive_historical_doc(path: Path) -> bool:
    rule = document_rule(path)
    return rule is not None and rule.get("lifecycle") in {
        "frozen",
        "superseded",
        "suspended",
    }


def should_skip_positioning_term_scan(path: Path) -> bool:
    return (
        is_inactive_historical_doc(path)
        or path in GENERATED_DOCS
        or path in POSITIONING_POLICY_DOCS
    )


def should_skip_taxonomy_canonical_scan(path: Path) -> bool:
    return (
        is_inactive_historical_doc(path)
        or path in GENERATED_DOCS
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


def iter_current_product_authority_surfaces() -> Iterable[Path]:
    markdown_paths = validate_document_control.tracked_markdown_paths(REPO_ROOT)
    for relative_path in sorted(markdown_paths):
        path = REPO_ROOT / relative_path
        if not is_inactive_historical_doc(path):
            yield path


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
        return DOCS_ROOT / "product" / "vision.md", base

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


def validate_architecture_decisions(errors: list[str]) -> None:
    validate_required_markers(
        ADR_POLICY,
        ADR_POLICY_REQUIREMENTS,
        "ADR policy",
        errors,
    )

    active_ids: set[str] = set()
    accepted_files: dict[str, str] = {}
    for path in sorted(ADR_ROOT.glob("ADR-*.md")):
        text = read(path)
        frontmatter, body = parse_frontmatter(text)
        filename_match = ADR_FILENAME_PATTERN.fullmatch(path.name)
        if filename_match is None:
            errors.append(
                f"{rel(path)}: active ADR filename must match ADR-NNN-kebab-case.md"
            )
            continue

        expected_id = filename_match.group(1)
        active_ids.add(expected_id)
        required_fields = {
            "last_verified",
            "layer",
            "decision_id",
            "status",
            "decided_at",
        }
        missing = sorted(required_fields - frontmatter.keys())
        if missing:
            errors.append(f"{rel(path)}: missing ADR frontmatter fields {missing}")
        if frontmatter.get("layer") != "architecture-decision":
            errors.append(
                f"{rel(path)}: layer must be 'architecture-decision'"
            )
        if frontmatter.get("decision_id") != expected_id:
            errors.append(
                f"{rel(path)}: decision_id must match filename ID {expected_id}"
            )
        status = frontmatter.get("status")
        if status not in ACTIVE_ADR_STATUSES:
            errors.append(
                f"{rel(path)}: active ADR status must be one of "
                f"{sorted(ACTIVE_ADR_STATUSES)}"
            )
        elif status == "accepted":
            accepted_files[expected_id] = path.name
        forbidden_fields = {
            "current_authority",
            "current_status",
            "historical_record",
        }
        present_forbidden = sorted(forbidden_fields & frontmatter.keys())
        if present_forbidden:
            errors.append(
                f"{rel(path)}: retired ADR fields are not allowed in active ADRs "
                f"{present_forbidden}"
            )

        title_match = ADR_TITLE_PATTERN.search(body)
        if title_match is None or title_match.group(1) != expected_id:
            errors.append(
                f"{rel(path)}: H1 must start with '# {expected_id}: '"
            )
        headings = H2_PATTERN.findall(body)
        if tuple(headings) != ACTIVE_ADR_REQUIRED_HEADINGS:
            errors.append(
                f"{rel(path)}: ADR H2 headings must be exactly "
                f"{list(ACTIVE_ADR_REQUIRED_HEADINGS)}"
            )

    policy_rows = {
        match.group(1): match.group(2)
        for match in CURRENT_ADR_ROW_PATTERN.finditer(read(ADR_POLICY))
    }
    if policy_rows != accepted_files:
        errors.append(
            f"{rel(ADR_POLICY)}: current ADR table must match accepted ADR files; "
            f"found {policy_rows}, expected {accepted_files}"
        )

    validate_required_markers(
        RETIRED_DECISIONS,
        RETIRED_DECISION_REQUIREMENTS,
        "retired decision index",
        errors,
    )
    retired_text = read(RETIRED_DECISIONS)
    retired_frontmatter, retired_body = parse_frontmatter(retired_text)
    if retired_frontmatter.get("layer") != "decision-history":
        errors.append(
            f"{rel(RETIRED_DECISIONS)}: layer must be 'decision-history'"
        )
    retired_ids_value = retired_frontmatter.get("retired_ids")
    if not isinstance(retired_ids_value, list) or not retired_ids_value:
        errors.append(
            f"{rel(RETIRED_DECISIONS)}: retired_ids must be a non-empty list"
        )
        retired_ids: list[str] = []
    else:
        retired_ids = [
            item for item in retired_ids_value if isinstance(item, str)
        ]
        if len(retired_ids) != len(retired_ids_value):
            errors.append(
                f"{rel(RETIRED_DECISIONS)}: retired_ids entries must be strings"
            )
    if len(retired_ids) != len(set(retired_ids)):
        errors.append(f"{rel(RETIRED_DECISIONS)}: retired_ids must be unique")

    row_ids = [match.group(1) for match in RETIRED_ADR_ROW_PATTERN.finditer(retired_body)]
    if row_ids != retired_ids:
        errors.append(
            f"{rel(RETIRED_DECISIONS)}: table ADR IDs must match retired_ids "
            f"in order; found {row_ids}"
        )
    overlap = sorted(active_ids & set(retired_ids))
    if overlap:
        errors.append(
            f"{rel(RETIRED_DECISIONS)}: IDs cannot be both active and retired {overlap}"
        )

    allowed_support_files = {"README.md", "retired-decisions.md"}
    unexpected = sorted(
        path.name
        for path in ADR_ROOT.glob("*.md")
        if not path.name.startswith("ADR-") and path.name not in allowed_support_files
    )
    if unexpected:
        errors.append(
            f"{rel(ADR_ROOT)}: unexpected decision documents {unexpected}; "
            "route them to an owning authority or frozen evidence"
        )


def validate_stale_claims(errors: list[str]) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if is_inactive_historical_doc(path):
            continue
        text = read(path)
        for phrase in STALE_CURRENT_CLAIMS:
            if phrase in text:
                errors.append(f"{rel(path)}:{line_number(text, phrase)} stale claim: {phrase}")


def validate_positioning_resets(errors: list[str]) -> None:
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        if is_inactive_historical_doc(path):
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
                base_ref = ref.partition("#")[0]
                if ADR_REF_PATTERN.match(base_ref):
                    target_frontmatter, _ = parse_frontmatter(read(target))
                    if target_frontmatter.get("status") != "accepted":
                        errors.append(
                            f"{rel(path)}: intent_refs ADR must be accepted: {ref}"
                        )
                if not ref_target_exists(target, anchor):
                    errors.append(f"{rel(path)}: intent_refs anchor not found in {rel(target)}: {ref}")
        if "## 意图追溯" not in text:
            errors.append(f"{rel(path)}: missing section '## 意图追溯'")
        if "| 验收证据 |" not in text:
            errors.append(f"{rel(path)}: missing intent traceability row '验收证据'")


def validate_frontmatter_document_references(errors: list[str]) -> None:
    repo_root = REPO_ROOT.resolve()
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        frontmatter, _ = parse_frontmatter(read(path))
        for field in ("derived_from", "upstream"):
            references = frontmatter.get(field)
            if references is None:
                continue
            if not isinstance(references, list):
                errors.append(f"{rel(path)}: {field} must be a list")
                continue
            for reference in references:
                if not isinstance(reference, str):
                    errors.append(f"{rel(path)}: {field} entry must be a string")
                    continue
                raw_path, _, anchor = reference.partition("#")
                if not raw_path.endswith(".md"):
                    continue
                target = (path.parent / raw_path).resolve()
                if not is_under(target, repo_root) or not target.is_file():
                    errors.append(
                        f"{rel(path)}: {field} target does not exist: {reference}"
                    )
                    continue
                if anchor and not has_heading_anchor(target, anchor):
                    errors.append(
                        f"{rel(path)}: {field} anchor not found: {reference}"
                    )


def validate_active_feature_structure(errors: list[str]) -> None:
    for path in sorted(ACTIVE_FEATURES_ROOT.glob("feat-*.md")):
        headings = H2_PATTERN.findall(read(path))
        numbered_headings = [
            heading for heading in headings if re.match(r"^[0-9]+\.", heading)
        ]
        if numbered_headings != list(ACTIVE_FEATURE_NUMBERED_HEADINGS):
            errors.append(
                f"{rel(path)}: numbered H2 sections must be exactly "
                "Why / What / How / Verify in that order"
            )
        for heading in headings:
            if heading in ACTIVE_FEATURE_ALLOWED_H2:
                continue
            errors.append(
                f"{rel(path)}: unexpected H2 '{heading}'; merge durable content "
                "into Why / What / How / Verify instead of creating a parallel "
                "contract or PRD surface"
            )


def validate_roadmap_boundaries(errors: list[str]) -> None:
    validate_required_markers(
        SCOPE_AND_ROADMAP,
        ROADMAP_REQUIRED_MARKERS,
        "candidate roadmap boundary",
        errors,
    )
    text = read(SCOPE_AND_ROADMAP)
    for heading in ROADMAP_PARALLEL_AUTHORITY_HEADINGS:
        if heading not in text:
            continue
        errors.append(
            f"{rel(SCOPE_AND_ROADMAP)}: parallel product authority heading "
            f"'{heading}'; point to Product Vision / Release PRD instead"
        )


def validate_cold_start_entrypoint(errors: list[str]) -> None:
    for path, requirements in COLD_START_ENTRYPOINT_REQUIREMENTS.items():
        validate_required_markers(
            path,
            requirements,
            "cold-start entrypoint",
            errors,
        )

    markdown_paths = validate_document_control.tracked_markdown_paths(REPO_ROOT)
    for relative_path in sorted(markdown_paths):
        path = REPO_ROOT / relative_path
        if (
            path in COLD_START_DECLARATION_OWNERS
            or is_inactive_historical_doc(path)
        ):
            continue
        if COLD_START_DECLARATION in read(path):
            errors.append(
                f"{rel(path)}: competing cold-start declaration; root README "
                "is the only cold-start owner and docs/README.md is its router"
            )


def validate_product_document_authority(errors: list[str]) -> None:
    vision_frontmatter, _ = parse_frontmatter(read(PRODUCT_VISION))
    if vision_frontmatter.get("layer") != "product-vision":
        errors.append("docs/product/vision.md: layer must be 'product-vision'")
    if vision_frontmatter.get("authority") != "po":
        errors.append("docs/product/vision.md: authority must be 'po'")

    prd_frontmatter, _ = parse_frontmatter(read(RELEASE_ONE_PRD))
    if prd_frontmatter.get("layer") != "release-prd":
        errors.append(
            "docs/product/release-1-prd.md: layer must be 'release-prd'"
        )
    if str(prd_frontmatter.get("release")) != "1":
        errors.append("docs/product/release-1-prd.md: release must be 1")
    if prd_frontmatter.get("product_role") != "release-prd":
        errors.append(
            "docs/product/release-1-prd.md: product_role must be 'release-prd'"
        )
    prd_text = read(RELEASE_ONE_PRD)
    if (
        "下表只是稳定决策 ID 的审阅索引" not in prd_text
        or "不独立定义完整约束" not in prd_text
    ):
        errors.append(
            "docs/product/release-1-prd.md: decision summary must state that it "
            "is an index and does not independently define complete constraints"
        )

    product_visions: list[Path] = []
    release_one_prds: list[Path] = []
    release_one_prd_layers: list[Path] = []
    markdown_paths = validate_document_control.tracked_markdown_paths(REPO_ROOT)
    for relative_path in sorted(markdown_paths):
        path = REPO_ROOT / relative_path
        frontmatter, _ = parse_frontmatter(read(path))
        if frontmatter.get("layer") == "product-vision":
            product_visions.append(path)
        if (
            frontmatter.get("product_role") == "release-prd"
            and str(frontmatter.get("release")) == "1"
        ):
            release_one_prds.append(path)
        if (
            frontmatter.get("layer") == "release-prd"
            and str(frontmatter.get("release")) == "1"
        ):
            release_one_prd_layers.append(path)
        if path != RELEASE_ONE_PRD and PRD_FILENAME_PATTERN.search(path.stem):
            errors.append(
                f"{rel(path)}: PRD-named Markdown duplicates or obscures the owning "
                "Release PRD"
            )

    if product_visions != [PRODUCT_VISION]:
        rendered = ", ".join(rel(path) for path in product_visions) or "none"
        errors.append(
            "Product direction must have exactly one product-vision layer at "
            f"docs/product/vision.md; found: {rendered}"
        )
    if release_one_prds != [RELEASE_ONE_PRD]:
        rendered = ", ".join(rel(path) for path in release_one_prds) or "none"
        errors.append(
            "Release 1 must have exactly one declared PRD authority at "
            f"docs/product/release-1-prd.md; found: {rendered}"
        )
    if release_one_prd_layers != [RELEASE_ONE_PRD]:
        rendered = ", ".join(rel(path) for path in release_one_prd_layers) or "none"
        errors.append(
            "Release 1 must have exactly one release-prd layer at "
            f"docs/product/release-1-prd.md; found: {rendered}"
        )


def validate_current_product_authority_terms(errors: list[str]) -> None:
    for path in iter_current_product_authority_surfaces():
        text = read(path)
        for term, pattern in LEGACY_PRODUCT_AUTHORITY_PATTERNS:
            match = pattern.search(text)
            if match is None:
                continue
            errors.append(
                f"{rel(path)}:{text[:match.start()].count(chr(10)) + 1}: "
                "obsolete product authority "
                f"term '{term}'; use Product Vision & Principles or Release 1 PRD"
            )


def validate_repository_fact_ownership(errors: list[str]) -> None:
    for path, requirements in REPOSITORY_FACT_POLICY_REQUIREMENTS.items():
        validate_required_markers(
            path,
            requirements,
            "repository fact ownership policy",
            errors,
        )


def validate_required_markers(
    path: Path,
    requirements: dict[str, tuple[str, ...]],
    error_prefix: str,
    errors: list[str],
) -> None:
    text = read(path)
    for field, markers in requirements.items():
        if all(marker in text for marker in markers):
            continue
        errors.append(f"{rel(path)}: {error_prefix} missing requirement: {field}")


def validate_current_admission(errors: list[str]) -> None:
    for path, requirements in CURRENT_ADMISSION_POLICY_REQUIREMENTS.items():
        validate_required_markers(
            path,
            requirements,
            "current admission policy",
            errors,
        )
    for path, requirements in CURRENT_ADMISSION_TEMPLATE_REQUIREMENTS.items():
        validate_required_markers(
            path,
            requirements,
            "current admission template",
            errors,
        )


def validate_merge_authorization(errors: list[str]) -> None:
    for path, requirements in MERGE_AUTHORIZATION_POLICY_REQUIREMENTS.items():
        validate_required_markers(
            path,
            requirements,
            "merge authorization policy",
            errors,
        )


def run_checks() -> list[str]:
    errors: list[str] = []
    warnings: list[str] = []
    validate_architecture_decisions(errors)
    validate_stale_claims(errors)
    validate_positioning_resets(errors)
    validate_contextual_positioning_terms(errors, warnings)
    validate_taxonomy_canonical_terms(errors, warnings)
    validate_product_document_authority(errors)
    validate_current_product_authority_terms(errors)
    validate_repository_fact_ownership(errors)
    validate_feature_intent(errors)
    validate_frontmatter_document_references(errors)
    validate_active_feature_structure(errors)
    validate_roadmap_boundaries(errors)
    validate_cold_start_entrypoint(errors)
    validate_current_admission(errors)
    validate_merge_authorization(errors)
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
