#!/usr/bin/env python3
"""
Generate localization xcstrings templates for zh-Hant (Traditional Chinese), ja (Japanese), ko (Korean).

Behavior:
- Reads `NotBad/Resources/Localizable.xcstrings` (assumed JSON-like structure)
- For each key, keeps existing `en` and `zh-Hans` localizations
- Adds `zh-Hant` by converting `zh-Hans` via OpenCC if available; otherwise copies `zh-Hans` as fallback
- Adds `ja` and `ko` entries as empty placeholders with state "needs_translation"
- Writes three files:
  - `NotBad/Resources/Localizable.zh-Hant.xcstrings`
  - `NotBad/Resources/Localizable.ja.xcstrings`
  - `NotBad/Resources/Localizable.ko.xcstrings`

Usage:
    python3 tools/localization/generate_localization_files.py

Requirements (optional):
    pip install opencc-python-reimplemented

"""

import argparse
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / 'NotBad' / 'Resources'
SRC_FILE = RESOURCES / 'Localizable.xcstrings'

OUT_ZH_HANT = RESOURCES / 'Localizable.zh-Hant.xcstrings'
OUT_JA = RESOURCES / 'Localizable.ja.xcstrings'
OUT_KO = RESOURCES / 'Localizable.ko.xcstrings'


def load_src(path: Path):
    try:
        with path.open('r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    except Exception as e:
        print(f"Failed to parse {path}: {e}")
        sys.exit(1)


# Try to import OpenCC for accurate Simplified->Traditional conversion
try:
    from opencc import OpenCC
    opencc = OpenCC('s2t')
    def convert_s2t(s: str) -> str:
        return opencc.convert(s)
    print('OpenCC available: using proper Simplified->Traditional conversion')
except Exception:
    opencc = None
    def convert_s2t(s: str) -> str:
        # Fallback: return original string (user should run OpenCC externally)
        return s
    print('OpenCC not available: zh-Hant will be same as zh-Hans (please install opencc-python-reimplemented for real conversion)')


def make_placeholder_translation(value: str, lang_state: str = 'needs_translation'):
    return {
        'stringUnit': {
            'state': lang_state,
            'value': value
        }
    }


def build_new_localization_entry(key_obj: dict, fill_ja_ko_with_en: bool = False):
    # key_obj is the original value for a string key
    localizations = key_obj.get('localizations', {})
    en_unit = localizations.get('en', {'stringUnit': {'state': 'translated', 'value': ''}})
    zh_hans_unit = localizations.get('zh-Hans', {'stringUnit': {'state': 'translated', 'value': ''}})
    zh_hans_value = zh_hans_unit.get('stringUnit', {}).get('value', '')
    zh_hant_value = convert_s2t(zh_hans_value)

    new_localizations = {}
    # preserve en and zh-Hans as-is if present
    if 'en' in localizations:
        new_localizations['en'] = localizations['en']
    else:
        new_localizations['en'] = make_placeholder_translation('', 'needs_translation')

    if 'zh-Hans' in localizations:
        new_localizations['zh-Hans'] = localizations['zh-Hans']
    else:
        new_localizations['zh-Hans'] = make_placeholder_translation('', 'needs_translation')

    # zh-Hant (generated)
    new_localizations['zh-Hant'] = make_placeholder_translation(zh_hant_value if zh_hant_value else '', 'needs_review' if opencc else 'needs_translation')
    # ja and ko placeholders (empty or filled with English if requested)
    if fill_ja_ko_with_en:
        en_value = en_unit.get('stringUnit', {}).get('value', '')
        new_localizations['ja'] = make_placeholder_translation(en_value, 'needs_review')
        new_localizations['ko'] = make_placeholder_translation(en_value, 'needs_review')
    else:
        new_localizations['ja'] = make_placeholder_translation('', 'needs_translation')
        new_localizations['ko'] = make_placeholder_translation('', 'needs_translation')

    # Build the full entry
    new_entry = {
        'extractionState': key_obj.get('extractionState', 'manual'),
        'localizations': new_localizations
    }
    # Preserve comment if present
    if 'comment' in key_obj:
        new_entry['comment'] = key_obj['comment']
    return new_entry


def main():
    parser = argparse.ArgumentParser(description='Generate localization xcstrings for zh-Hant/ja/ko')
    parser.add_argument('--fill-ja-ko-with-en', action='store_true', help='Fill ja/ko placeholders with English values for easier translation review')
    args = parser.parse_args()

    if not SRC_FILE.exists():
        print(f"Source `{SRC_FILE}` not found. Aborting.")
        sys.exit(1)

    data = load_src(SRC_FILE)

    # Support files that use a top-level "strings" dictionary (Xcode string catalog format)
    if isinstance(data, dict) and 'strings' in data and isinstance(data['strings'], dict):
        strings = data['strings']

        zh_hant_strings = {}
        ja_strings = {}
        ko_strings = {}

        for key, value in strings.items():
            if not isinstance(value, dict) or 'localizations' not in value:
                zh_hant_strings[key] = value
                ja_strings[key] = value
                ko_strings[key] = value
                continue

            new_entry = build_new_localization_entry(value, fill_ja_ko_with_en=args.fill_ja_ko_with_en)
            zh_hant_strings[key] = new_entry
            ja_strings[key] = new_entry
            ko_strings[key] = new_entry

        zh_hant_out = dict(data)
        ja_out = dict(data)
        ko_out = dict(data)

        zh_hant_out['strings'] = zh_hant_strings
        ja_out['strings'] = ja_strings
        ko_out['strings'] = ko_strings
    else:
        # Fallback: original behavior (flat mapping)
        zh_hant_out = {}
        ja_out = {}
        ko_out = {}

        for key, value in data.items():
            # Skip top-level metadata keys if any (like "sourceLanguage" or "version")
            if not isinstance(value, dict) or 'localizations' not in value:
                # preserve as-is across outputs
                zh_hant_out[key] = value
                ja_out[key] = value
                ko_out[key] = value
                continue

            new_entry = build_new_localization_entry(value, fill_ja_ko_with_en=args.fill_ja_ko_with_en)
            zh_hant_out[key] = new_entry
            ja_out[key] = new_entry
            ko_out[key] = new_entry

    # Write outputs
    def write_json(path: Path, obj: dict):
        with path.open('w', encoding='utf-8') as f:
            json.dump(obj, f, ensure_ascii=False, indent=2)
        print(f'Wrote {path} ({len(obj)} entries)')

    write_json(OUT_ZH_HANT, zh_hant_out)
    write_json(OUT_JA, ja_out)
    write_json(OUT_KO, ko_out)

    print('\nDone. Review the generated files and import them into Xcode if desired.')


if __name__ == '__main__':
    main()
