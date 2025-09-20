#!/usr/bin/env python3
"""
Docs Consistency Checker for NotBad

Validates:
- Required key docs exist
- Cross-link targets exist (basic heuristic)
- Platform/device baseline mentions are consistent (iOS 26, Swift 6.2, Xcode 26, iPhone 17)
- Banned filename suffix patterns are absent

Exit with non-zero status if issues are found.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ROOT / "docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md",
    ROOT / "docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v6.0.md",
    ROOT / "docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v6.0.md",
    ROOT / "docs/glossary/NotBad App - 技术术语表 v6.0.md",
]

BASELINE_KEYWORDS = [
    r"iOS\s*26",
    r"Swift\s*6\.2",
    r"Xcode\s*26",
    r"iPhone\s*17",
]

BANNED_SUFFIX_PATTERNS = [
    # Historically used suffixes we want to avoid in links or headings
    r"\(Swift\s*6\.2\s*\+\s*iOS\s*26\)",
    r"（Swift\s*6\.2\s*\+\s*iOS\s*26）",
]

LINK_START_PATTERN = re.compile(r"\]\(")


def find_markdown_files(root: Path) -> List[Path]:
    return [p for p in root.rglob("*.md") if ".git" not in p.parts and "node_modules" not in p.parts]


def check_required_files() -> List[str]:
    errors = []
    for f in REQUIRED_FILES:
        if not f.exists():
            errors.append(f"缺少关键文档: {f.relative_to(ROOT)}")
    return errors


def _extract_markdown_links(text: str) -> List[str]:
    links: List[str] = []
    i = 0
    end = len(text)
    while i < end:
        idx = text.find("](", i)
        if idx == -1:
            break
        # start of url is right after ']("?'; support optional quote but keep simple
        j = idx + 2
        depth = 1
        # capture until matching ')'
        start_url = j
        while j < end and depth > 0:
            ch = text[j]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    # capture from start_url to j
                    links.append(text[start_url:j])
                    break
            j += 1
        i = j + 1
    return links


def check_links_exist(md_files: List[Path]) -> List[str]:
    errors = []
    for p in md_files:
        try:
            text = p.read_text(encoding="utf-8")
        except Exception as e:
            errors.append(f"无法读取 {p}: {e}")
            continue
        for raw in _extract_markdown_links(text):
            raw = raw.strip()
            # Skip obvious placeholders
            if raw.upper() == "TBD":
                continue
            # Parse and normalize
            parsed = urlparse(raw)
            target_path_str = parsed.path
            if not target_path_str:
                continue
            target = unquote(target_path_str).strip()
            # Skip external links and anchors
            if raw.startswith("http://") or raw.startswith("https://"):
                continue
            if raw.startswith("#") or target.startswith("#"):
                continue
            # Normalize relative path
            target_path = (p.parent / target).resolve()
            if not target_path.exists():
                errors.append(f"链接失效: {p.relative_to(ROOT)} -> {raw}")
    return errors


def check_baseline_mentions(md_files: List[Path]) -> List[str]:
    # Ensure at least one baseline keyword appears in core files; warn if old devices referenced
    missing = []
    core_files = [
        ROOT / "README.md",
        ROOT / "docs/README.md",
    ]
    for cf in core_files:
        if not cf.exists():
            # Non-blocking if missing
            continue
        text = cf.read_text(encoding="utf-8")
        if not all(re.search(k, text, flags=re.IGNORECASE) for k in BASELINE_KEYWORDS):
            missing.append(f"基线关键字未完全覆盖: {cf.relative_to(ROOT)} 需包含 {BASELINE_KEYWORDS}")
    return missing


def check_banned_suffixes(md_files: List[Path]) -> List[str]:
    errors = []
    for p in md_files:
        text = p.read_text(encoding="utf-8", errors="ignore")
        for pat in BANNED_SUFFIX_PATTERNS:
            if re.search(pat, text):
                errors.append(f"发现已禁用的后缀样式: {p.relative_to(ROOT)} 包含 {pat}")
    return errors


def main() -> int:
    md_files = find_markdown_files(ROOT)
    problems: List[Tuple[str, List[str]]] = []

    checks = [
        ("关键文档存在性", check_required_files()),
        ("本地链接有效性", check_links_exist(md_files)),
        ("基线关键字覆盖", check_baseline_mentions(md_files)),
        ("禁止后缀样式", check_banned_suffixes(md_files)),
    ]

    total_errors = 0
    for title, errs in checks:
        if errs:
            print(f"[❌] {title} 发现 {len(errs)} 个问题：")
            for e in errs:
                print(f"  - {e}")
            total_errors += len(errs)
        else:
            print(f"[✅] {title} 无问题")

    if total_errors > 0:
        print(f"\n共计发现 {total_errors} 个问题。")
        return 1
    print("\n文档一致性检查通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
