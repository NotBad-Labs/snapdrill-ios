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


def check_info_plist(version: str) -> None:
    if not os.path.exists(INFO_PLIST):
        print(f"⚠️ Info.plist not found at {INFO_PLIST}, skipping this check")
        return
    with open(INFO_PLIST, 'rb') as f:
        plist = plistlib.load(f)
    short = plist.get('CFBundleShortVersionString')
    if short != version:
        fail(f"Info.plist CFBundleShortVersionString '{short}' != VERSION '{version}'")


def check_changelog(version: str) -> None:
    if not os.path.exists(CHANGELOG):
        fail(f"CHANGELOG.md not found: {CHANGELOG}")
    header = f"## [{version}] - "
    with open(CHANGELOG, 'r', encoding='utf-8') as f:
        content = f.read()
    if header not in content:
        fail(f"CHANGELOG.md missing section header for version {version} (expected line starting with '{header}')")


def main() -> None:
    version = read_version()
    check_info_plist(version)
    check_changelog(version)
    print("✅ Release metadata looks consistent: VERSION, Info.plist, CHANGELOG")


if __name__ == '__main__':
    main()
