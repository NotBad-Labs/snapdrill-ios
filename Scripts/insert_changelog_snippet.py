#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scripts/insert_changelog_snippet.py

Insert or replace an auto-generated changelog snippet into CHANGELOG.md
under the current version section taken from root VERSION.

- Looks for a section header starting with:  ## [<version>] - 
- Within that section, replaces content between markers:
    <!-- AUTO-CHANGELOG-SNIPPET BEGIN -->
    ...
    <!-- AUTO-CHANGELOG-SNIPPET END -->
  If markers are missing, inserts after the version header.
- Ensures markdownlint-friendly blank lines around blocks.

Usage:
  python3 Scripts/insert_changelog_snippet.py changelog_snippet.md
"""
import os
import re
import sys
import plistlib
from typing import List

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERSION_FILE = os.path.join(ROOT, 'VERSION')
CHANGELOG = os.path.join(ROOT, 'CHANGELOG.md')
INFO_PLIST = os.path.join(ROOT, 'NotBad', 'Info.plist')

BEGIN = '<!-- AUTO-CHANGELOG-SNIPPET BEGIN -->'
END = '<!-- AUTO-CHANGELOG-SNIPPET END -->'


def read_version() -> str:
    if not os.path.exists(VERSION_FILE):
        print(f"VERSION file not found: {VERSION_FILE}", file=sys.stderr)
        sys.exit(1)
    with open(VERSION_FILE, 'r', encoding='utf-8') as f:
        return f.read().strip()


def load_lines(path: str) -> List[str]:
    with open(path, 'r', encoding='utf-8') as f:
        return f.read().splitlines()


def save_lines(path: str, lines: List[str]) -> None:
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines).rstrip() + '\n')


def find_version_section(lines: List[str], version: str):
    header_prefix = f"## [{version}] - "
    start = None
    for i, line in enumerate(lines):
        if line.startswith(header_prefix):
            start = i
            break
    if start is None:
        return None, None
    # Section ends at next version header or EOF
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith('## ['):
            end = j
            break
    return start, end


def read_build_number() -> str:
    try:
        if os.path.exists(INFO_PLIST):
            with open(INFO_PLIST, 'rb') as f:
                plist = plistlib.load(f)
            return str(plist.get('CFBundleVersion', '')).strip()
    except Exception:
        return ''
    return ''


def insert_or_replace(lines: List[str], section_start: int, section_end: int, snippet_lines: List[str]) -> List[str]:
    # Ensure snippet has a heading and blank lines around
    block: List[str] = []
    block.append(BEGIN)
    # Add build number line if available
    build = read_build_number()
    if build:
        block.append(f"Build: {build}")
        block.append('')
    # Optional heading to separate
    if snippet_lines and not snippet_lines[0].startswith('### '):
        block.append('### Changes (generated)')
        block.append('')
    block.extend(snippet_lines)
    block.append(END)

    # Ensure blank line before and after block for markdownlint
    before = section_start + 1  # insert right after header
    after = section_end

    # Look for existing markers within the section
    exist_begin = exist_end = -1
    for idx in range(section_start + 1, section_end):
        if lines[idx].strip() == BEGIN:
            exist_begin = idx
            # find end
            for k in range(idx + 1, section_end):
                if lines[k].strip() == END:
                    exist_end = k
                    break
            break

    new_lines = lines[:]

    if exist_begin != -1 and exist_end != -1:
        # Replace existing block, keeping one blank line padding
        new_content = []
        # Ensure a blank line preceding block
        if exist_begin - 1 >= 0 and new_lines[exist_begin - 1].strip() != '':
            new_content.append('')
        new_content.extend(block)
        if exist_end + 1 < len(new_lines) and new_lines[exist_end + 1].strip() != '':
            new_content.append('')
        new_lines = new_lines[:exist_begin] + new_content + new_lines[exist_end + 1:]
        return new_lines

    # No existing block: insert after header line
    insert_at = section_start + 1
    # Add a blank line after header if missing
    if insert_at < len(new_lines) and new_lines[insert_at].strip() != '':
        ins_block = [''] + block + ['']
    else:
        ins_block = block + ['']
    new_lines = new_lines[:insert_at] + ins_block + new_lines[insert_at:]
    return new_lines


def main():
    if len(sys.argv) != 2:
        print('Usage: insert_changelog_snippet.py <snippet_file>', file=sys.stderr)
        sys.exit(2)
    snippet_file = sys.argv[1]
    if not os.path.exists(snippet_file):
        print(f"Snippet file not found: {snippet_file}", file=sys.stderr)
        sys.exit(1)

    version = read_version()
    changelog_lines = load_lines(CHANGELOG)
    snippet_lines = load_lines(snippet_file)

    start, end = find_version_section(changelog_lines, version)
    if start is None:
        print(f"Version section not found in CHANGELOG for {version}", file=sys.stderr)
        sys.exit(1)

    updated = insert_or_replace(changelog_lines, start, end, snippet_lines)
    save_lines(CHANGELOG, updated)
    print("✅ Inserted/updated generated changelog snippet in CHANGELOG.md")


if __name__ == '__main__':
    main()
