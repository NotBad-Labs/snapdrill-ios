#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scripts/bump_version.py

SemVer bump script for NotBad:
- Reads current version from root VERSION (format: MAJOR.MINOR.PATCH)
- Bumps part (major/minor/patch) or sets explicit version via --set
- Updates NotBad/Info.plist:
  - CFBundleShortVersionString: x.y.z
  - CFBundleVersion: build number (auto-increment or --build)
- Updates CHANGELOG.md: inserts a new section for the version if missing

Usage examples:
  python3 Scripts/bump_version.py --part patch
  python3 Scripts/bump_version.py --set 6.1.0
  python3 Scripts/bump_version.py --part minor --build 42
"""

import argparse
import datetime as dt
import os
import plistlib
import re
import sys
from typing import Tuple

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_FILE = os.path.join(ROOT, 'VERSION')
INFO_PLIST = os.path.join(ROOT, 'NotBad', 'Info.plist')
CHANGELOG = os.path.join(ROOT, 'CHANGELOG.md')

SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def read_version() -> Tuple[int, int, int]:
    if not os.path.exists(VERSION_FILE):
        print(f"ERROR: VERSION file not found at {VERSION_FILE}", file=sys.stderr)
        sys.exit(1)
    with open(VERSION_FILE, 'r', encoding='utf-8') as f:
        line = f.read().strip()
    m = SEMVER_RE.match(line)
    if not m:
        print(f"ERROR: Invalid version in VERSION: '{line}' (expected MAJOR.MINOR.PATCH)", file=sys.stderr)
        sys.exit(1)
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def write_version(major: int, minor: int, patch: int) -> None:
    with open(VERSION_FILE, 'w', encoding='utf-8') as f:
        f.write(f"{major}.{minor}.{patch}\n")


def bump(major: int, minor: int, patch: int, part: str) -> Tuple[int, int, int]:
    if part == 'major':
        return major + 1, 0, 0
    if part == 'minor':
        return major, minor + 1, 0
    if part == 'patch':
        return major, minor, patch + 1
    raise ValueError(f"Unknown part: {part}")


def update_info_plist(short_version: str, build_number: int) -> None:
    if not os.path.exists(INFO_PLIST):
        print(f"WARNING: Info.plist not found at {INFO_PLIST}, skipping.")
        return
    with open(INFO_PLIST, 'rb') as f:
        plist = plistlib.load(f)
    plist['CFBundleShortVersionString'] = short_version
    plist['CFBundleVersion'] = str(build_number)
    with open(INFO_PLIST, 'wb') as f:
        plistlib.dump(plist, f)


def ensure_changelog_section(version: str, date_str: str) -> None:
    header = f"## [{version}] - {date_str}"
    template = (
        f"\n{header}\n\n"
        "### Added\n\n"
        "- \n\n"
        "### Changed\n\n"
        "- \n\n"
        "### Fixed\n\n"
        "- \n\n"
    )
    if not os.path.exists(CHANGELOG):
        with open(CHANGELOG, 'w', encoding='utf-8') as f:
            f.write('# Changelog\n\n')
            f.write('All notable changes to this project will be documented in this file.\n\n')
            f.write('The format is based on Keep a Changelog and this project adheres to Semantic Versioning.\n\n')
            f.write(template)
        return
    with open(CHANGELOG, 'r', encoding='utf-8') as f:
        content = f.read()
    if header in content:
        return
    # Insert new section at top after the intro (after first existing version or end of header block)
    lines = content.splitlines()
    insert_idx = 0
    # Keep initial header/introduction (up to the first version header or end)
    for i, line in enumerate(lines):
        if line.startswith('## ['):
            insert_idx = i
            break
    else:
        insert_idx = len(lines)
    new_content = '\n'.join(lines[:insert_idx] + [''] + template.strip('\n').split('\n') + [''] + lines[insert_idx:])
    with open(CHANGELOG, 'w', encoding='utf-8') as f:
        f.write(new_content)


def main() -> None:
    parser = argparse.ArgumentParser(description='Bump version and update Info.plist and CHANGELOG.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--part', choices=['major', 'minor', 'patch'], help='Which part of SemVer to bump')
    group.add_argument('--set', dest='set_version', help='Explicit version to set (MAJOR.MINOR.PATCH)')
    parser.add_argument('--build', type=int, help='Explicit build number (CFBundleVersion). If omitted, auto-increment.')

    args = parser.parse_args()

    major, minor, patch = read_version()

    if args.set_version:
        m = SEMVER_RE.match(args.set_version)
        if not m:
            print("ERROR: --set expects MAJOR.MINOR.PATCH", file=sys.stderr)
            sys.exit(1)
        new_major, new_minor, new_patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
    else:
        new_major, new_minor, new_patch = bump(major, minor, patch, args.part)

    write_version(new_major, new_minor, new_patch)
    new_version_str = f"{new_major}.{new_minor}.{new_patch}"

    # Build number handling
    build_number = args.build if args.build is not None else 0
    # If not specified, try to read current build and +1
    if build_number == 0 and os.path.exists(INFO_PLIST):
        try:
            with open(INFO_PLIST, 'rb') as f:
                plist = plistlib.load(f)
            current_build = int(plist.get('CFBundleVersion', '0'))
            build_number = current_build + 1
        except Exception:
            build_number = 1
    elif build_number == 0:
        build_number = 1

    update_info_plist(new_version_str, build_number)

    today = dt.date.today().strftime('%Y-%m-%d')
    ensure_changelog_section(new_version_str, today)

    print(f"Bumped version: {major}.{minor}.{patch} -> {new_version_str}")
    print(f"Build number set to: {build_number}")
    print("Updated: VERSION, Info.plist (if present), CHANGELOG.md")


if __name__ == '__main__':
    main()
