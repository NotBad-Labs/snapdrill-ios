#!/usr/bin/env python3
"""
Import translations from XLIFF file into Localizable.xcstrings.

Usage:
    python3 tools/localization/import_xliff.py tools/localization/ja_translations.xliff
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
XCSTRINGS_FILE = ROOT / 'NotBad' / 'Resources' / 'Localizable.xcstrings'

XLIFF_NS = {'xliff': 'urn:oasis:names:tc:xliff:document:1.2'}


def parse_xliff(xliff_path: Path) -> dict:
    """Parse XLIFF file and return dict of {key: (target_value, state)}"""
    tree = ET.parse(xliff_path)
    root = tree.getroot()
    
    translations = {}
    target_lang = None
    
    for file_elem in root.findall('xliff:file', XLIFF_NS):
        target_lang = file_elem.get('target-language')
        for trans_unit in file_elem.findall('.//xliff:trans-unit', XLIFF_NS):
            key = trans_unit.get('id')
            target_elem = trans_unit.find('xliff:target', XLIFF_NS)
            if target_elem is not None and target_elem.text:
                state = target_elem.get('state', 'translated')
                translations[key] = (target_elem.text, state)
    
    return target_lang, translations


def update_xcstrings(xcstrings_path: Path, target_lang: str, translations: dict):
    """Update xcstrings file with translations"""
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data.get('strings', {})
    updated = 0
    
    for key, (value, state) in translations.items():
        if key in strings:
            entry = strings[key]
            if 'localizations' not in entry:
                entry['localizations'] = {}
            
            entry['localizations'][target_lang] = {
                'stringUnit': {
                    'state': state,
                    'value': value
                }
            }
            updated += 1
    
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    return updated


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 import_xliff.py <xliff_file>")
        sys.exit(1)
    
    xliff_path = Path(sys.argv[1])
    if not xliff_path.exists():
        print(f"Error: {xliff_path} not found")
        sys.exit(1)
    
    print(f"Parsing {xliff_path}...")
    target_lang, translations = parse_xliff(xliff_path)
    print(f"Found {len(translations)} translations for '{target_lang}'")
    
    print(f"Updating {XCSTRINGS_FILE}...")
    updated = update_xcstrings(XCSTRINGS_FILE, target_lang, translations)
    print(f"Updated {updated} entries")
    
    print("Done!")


if __name__ == '__main__':
    main()
