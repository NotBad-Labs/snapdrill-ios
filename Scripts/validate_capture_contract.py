#!/usr/bin/env python3
"""Validate Capture contract policy boundaries.

The check is intentionally narrow: it only scans Capture-facing strings and
permission-purpose copy. Historical docs and other screens are out of scope.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable, Sequence

REPO_ROOT = Path(__file__).resolve().parent.parent

FORBIDDEN_TERMS = ("错题", "作业", "儿童", "年级")
CAPTURE_LOCALIZED_PREFIXES = ("capture.", "accessibility.capture_")
PERMISSION_KEYS = ("NSCameraUsageDescription", "NSPhotoLibraryUsageDescription")

CAPTURE_SWIFT_DIR = Path("Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture")
CAPTURE_L10N_SWIFT = Path(
    "Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Capture.swift"
)
ACCESSIBILITY_L10N_SWIFT = Path(
    "Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift"
)
LOCALIZABLE_FILES = (
    Path("SnapDrill/Resources/zh-Hans.lproj/Localizable.strings"),
    Path("SnapDrill/Resources/en.lproj/Localizable.strings"),
)
INFOPLIST_FILES = (
    Path("SnapDrill/Resources/zh-Hans.lproj/InfoPlist.strings"),
    Path("SnapDrill/Resources/en.lproj/InfoPlist.strings"),
)

STRINGS_ENTRY = re.compile(r'^\s*"(?P<key>(?:\\.|[^"\\])*)"\s*=\s*"(?P<value>(?:\\.|[^"\\])*)"\s*;')
SWIFT_STRING = re.compile(r'"(?:\\.|[^"\\])*"')


def rel(path: Path, repo_root: Path = REPO_ROOT) -> str:
    return path.relative_to(repo_root).as_posix()


def line_has_forbidden_term(value: str) -> str | None:
    return next((term for term in FORBIDDEN_TERMS if term in value), None)


def scan_strings_file(path: Path, allowed_keys: Sequence[str], repo_root: Path = REPO_ROOT) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    for line_number, line in enumerate(text.splitlines(), start=1):
        match = STRINGS_ENTRY.match(line)
        if not match:
            continue
        key = match.group("key")
        if key not in allowed_keys and not key.startswith(CAPTURE_LOCALIZED_PREFIXES):
            continue
        value = match.group("value")
        if term := line_has_forbidden_term(value):
            errors.append(
                f"{rel(path, repo_root)}:{line_number} forbidden Capture copy term {term!r}: {key}"
            )
    return errors


def scan_swift_strings(
    path: Path,
    only_lines_containing: str | None = None,
    repo_root: Path = REPO_ROOT,
) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("//"):
            continue
        if only_lines_containing and only_lines_containing not in line:
            continue
        for match in SWIFT_STRING.finditer(line):
            literal = match.group(0).strip('"')
            if term := line_has_forbidden_term(literal):
                errors.append(
                    f"{rel(path, repo_root)}:{line_number} forbidden Capture copy term {term!r}"
                )
    return errors


def required_paths(repo_root: Path) -> Iterable[Path]:
    yield repo_root / CAPTURE_L10N_SWIFT
    yield repo_root / ACCESSIBILITY_L10N_SWIFT
    yield from (repo_root / item for item in LOCALIZABLE_FILES)
    yield from (repo_root / item for item in INFOPLIST_FILES)
    if (repo_root / CAPTURE_SWIFT_DIR).exists():
        yield from sorted((repo_root / CAPTURE_SWIFT_DIR).glob("*.swift"))


def run_checks(repo_root: Path = REPO_ROOT) -> list[str]:
    missing = [path for path in required_paths(repo_root) if not path.exists()]
    if missing:
        return [f"missing required scan path: {path.relative_to(repo_root).as_posix()}" for path in missing]

    errors: list[str] = []
    errors.extend(scan_swift_strings(repo_root / CAPTURE_L10N_SWIFT, repo_root=repo_root))
    errors.extend(
        scan_swift_strings(
            repo_root / ACCESSIBILITY_L10N_SWIFT,
            only_lines_containing="captureFirstItemHint",
            repo_root=repo_root,
        )
    )

    for strings_file in LOCALIZABLE_FILES:
        errors.extend(scan_strings_file(repo_root / strings_file, allowed_keys=(), repo_root=repo_root))

    for info_file in INFOPLIST_FILES:
        errors.extend(
            scan_strings_file(repo_root / info_file, allowed_keys=PERMISSION_KEYS, repo_root=repo_root)
        )

    capture_dir = repo_root / CAPTURE_SWIFT_DIR
    for swift_file in sorted(capture_dir.glob("*.swift")):
        errors.extend(scan_swift_strings(swift_file, repo_root=repo_root))

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
    print("[ok] Capture contract checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
