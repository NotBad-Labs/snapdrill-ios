#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scripts/validate_release_metadata.py

Validate release metadata consistency for Git Flow PRs:
- VERSION file must exist and follow SemVer MAJOR.MINOR.PATCH
- NotBad/Info.plist must set CFBundleShortVersionString to VERSION
- CHANGELOG.md must contain a section header: ## [x.y.z] - YYYY-MM-DD (the version from VERSION)

Exit with non-zero on failures.
"""
import os
import re
import sys
import plistlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_FILE = os.path.join(ROOT, 'VERSION')
INFO_PLIST = os.path.join(ROOT, 'NotBad', 'Info.plist')
CHANGELOG = os.path.join(ROOT, 'CHANGELOG.md')
SEMVER_RE = re.compile(r'^(\d+)\.(\d+)\.(\d+)$')


def fail(msg: str) -> None:
    print(f"❌ {msg}", file=sys.stderr)
    sys.exit(1)


def read_version() -> str:
    if not os.path.exists(VERSION_FILE):
        fail(f"VERSION file not found: {VERSION_FILE}")
    with open(VERSION_FILE, 'r', encoding='utf-8') as f:
        v = f.read().strip()
    if not SEMVER_RE.match(v):
        fail(f"Invalid VERSION '{v}', expected MAJOR.MINOR.PATCH")
    return v


def check_info_plist(version: str):
    """Return (short_version, build) or (None, None) if Info.plist missing."""
    if not os.path.exists(INFO_PLIST):
        print(f"⚠️ Info.plist not found at {INFO_PLIST}, skipping Info.plist checks")
        return None, None
    with open(INFO_PLIST, 'rb') as f:
        plist = plistlib.load(f)
    short = plist.get('CFBundleShortVersionString')
    build = str(plist.get('CFBundleVersion', '')).strip()
    if short != version:
        fail(f"Info.plist CFBundleShortVersionString '{short}' != VERSION '{version}'")
    return short, build


def check_changelog(version: str, expected_build: str | None) -> None:
    if not os.path.exists(CHANGELOG):
        fail(f"CHANGELOG.md not found: {CHANGELOG}")
    header_prefix = f"## [{version}] - "
    with open(CHANGELOG, 'r', encoding='utf-8') as f:
        lines = f.read().splitlines()
    header_line = None
    for line in lines:
        if line.startswith(header_prefix):
            header_line = line
            break
    if header_line is None:
        fail(f"CHANGELOG.md missing section header for version {version} (expected line starting with '{header_prefix}')")
    # If we have an expected build (Info.plist existed), enforce it is present and matches
    if expected_build:
        m = re.search(r"\(Build\s+([^)]+)\)", header_line)
        if not m:
            fail(f"CHANGELOG header for version {version} must include '(Build {expected_build})' but no build suffix found: '{header_line}'")
        actual_build = m.group(1).strip()
        if actual_build != expected_build:
            fail(f"CHANGELOG header build mismatch: found '(Build {actual_build})' but Info.plist CFBundleVersion is '{expected_build}'")


def main() -> None:
    version = read_version()
    _, build = check_info_plist(version)
    check_changelog(version, build)
    print("✅ Release metadata looks consistent: VERSION, Info.plist, CHANGELOG")


if __name__ == '__main__':
    main()
