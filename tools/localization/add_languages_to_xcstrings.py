#!/usr/bin/env python3
"""
Add zh-Hant, ja, ko languages to the existing Localizable.xcstrings file.

This script:
1. Reads the existing Localizable.xcstrings
2. For each string entry, adds zh-Hant (converted from zh-Hans), ja, ko placeholders
3. Writes back to the same file (backup created first)

Usage:
    python3 tools/localization/add_languages_to_xcstrings.py

The zh-Hant conversion uses a built-in simplified-to-traditional character mapping
for common educational terms used in this app.
"""

import json
import shutil
import sys
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / 'NotBad' / 'Resources'
XCSTRINGS_FILE = RESOURCES / 'Localizable.xcstrings'

# Common simplified -> traditional character mappings for education domain
S2T_MAP = {
    # Common characters
    '复': '複', '习': '習', '题': '題', '错': '錯', '学': '學',
    '书': '書', '页': '頁', '选': '選', '择': '擇', '确': '確',
    '认': '認', '设': '設', '计': '計', '统': '統', '语': '語',
    '问': '問', '关': '關', '闭': '閉', '开': '開', '启': '啟',
    '动': '動', '图': '圖', '标': '標', '签': '簽', '记': '記',
    '录': '錄', '历': '歷', '史': '史', '时': '時', '间': '間',
    '显': '顯', '示': '示', '隐': '隱', '藏': '藏', '编': '編',
    '辑': '輯', '删': '刪', '除': '除', '添': '添', '加': '加',
    '减': '減', '乘': '乘', '除': '除', '数': '數', '学': '學',
    '科': '科', '目': '目', '课': '課', '程': '程', '练': '練',
    '测': '測', '试': '試', '验': '驗', '结': '結', '果': '果',
    '成': '成', '绩': '績', '分': '分', '析': '析', '报': '報',
    '告': '告', '导': '導', '出': '出', '入': '入', '进': '進',
    '步': '步', '级': '級', '别': '別', '类': '類', '型': '型',
    '难': '難', '度': '度', '简': '簡', '单': '單', '容': '容',
    '易': '易', '掌': '掌', '握': '握', '理': '理', '解': '解',
    '懂': '懂', '会': '會', '能': '能', '力': '力', '知': '知',
    '识': '識', '点': '點', '考': '考', '试': '試', '答': '答',
    '案': '案', '解': '解', '释': '釋', '说': '說', '明': '明',
    '注': '註', '释': '釋', '备': '備', '份': '份', '还': '還',
    '原': '原', '恢': '恢', '复': '復', '同': '同', '步': '步',
    '云': '雲', '端': '端', '本': '本', '地': '地', '存': '存',
    '储': '儲', '空': '空', '满': '滿', '清': '清', '理': '理',
    '优': '優', '化': '化', '更': '更', '新': '新', '版': '版',
    '帮': '幫', '助': '助', '反': '反', '馈': '饋', '意': '意',
    '见': '見', '建': '建', '议': '議', '联': '聯', '系': '繫',
    '我': '我', '们': '們', '你': '你', '他': '他', '她': '她',
    '它': '它', '这': '這', '那': '那', '里': '裡', '哪': '哪',
    '谁': '誰', '什': '什', '么': '麼', '怎': '怎', '样': '樣',
    '为': '為', '因': '因', '所': '所', '以': '以', '但': '但',
    '是': '是', '不': '不', '没': '沒', '有': '有', '在': '在',
    '于': '於', '与': '與', '和': '和', '或': '或', '而': '而',
    '且': '且', '只': '只', '就': '就', '都': '都', '也': '也',
    '还': '還', '再': '再', '又': '又', '已': '已', '经': '經',
    '过': '過', '来': '來', '去': '去', '到': '到', '从': '從',
    '向': '向', '往': '往', '给': '給', '让': '讓', '被': '被',
    '把': '把', '将': '將', '用': '用', '以': '以', '及': '及',
    '等': '等', '如': '如', '果': '果', '若': '若', '虽': '雖',
    '然': '然', '当': '當', '须': '須', '应': '應', '该': '該',
    '必': '必', '需': '需', '要': '要', '想': '想', '愿': '願',
    '请': '請', '谢': '謝', '对': '對', '不': '不', '起': '起',
    '抱': '抱', '歉': '歉', '欢': '歡', '迎': '迎', '感': '感',
    '激': '激', '祝': '祝', '贺': '賀', '恭': '恭', '喜': '喜',
    # Education specific
    '错题': '錯題', '复习': '複習', '练习': '練習', '测试': '測試',
    '成绩': '成績', '分数': '分數', '答案': '答案', '解析': '解析',
    '知识点': '知識點', '难度': '難度', '掌握': '掌握', '理解': '理解',
    '学科': '學科', '科目': '科目', '年级': '年級', '学期': '學期',
    '课程': '課程', '教材': '教材', '章节': '章節', '单元': '單元',
    '题目': '題目', '选择题': '選擇題', '填空题': '填空題',
    '计算题': '計算題', '应用题': '應用題', '证明题': '證明題',
    '阅读理解': '閱讀理解', '作文': '作文', '听力': '聽力',
    '语法': '語法', '词汇': '詞彙', '发音': '發音', '口语': '口語',
    '写作': '寫作', '翻译': '翻譯', '数学': '數學', '语文': '語文',
    '英语': '英語', '物理': '物理', '化学': '化學', '生物': '生物',
    '历史': '歷史', '地理': '地理', '政治': '政治', '体育': '體育',
    '音乐': '音樂', '美术': '美術', '信息技术': '資訊技術',
}

def convert_simplified_to_traditional(text: str) -> str:
    """Convert simplified Chinese to traditional Chinese using character mapping."""
    if not text:
        return text
    
    result = text
    # First try phrase replacements (longer matches first)
    phrases = sorted([k for k in S2T_MAP.keys() if len(k) > 1], key=len, reverse=True)
    for phrase in phrases:
        if phrase in result:
            result = result.replace(phrase, S2T_MAP[phrase])
    
    # Then do character-by-character replacement
    chars = []
    for char in result:
        chars.append(S2T_MAP.get(char, char))
    
    return ''.join(chars)


def add_languages_to_entry(entry: dict) -> dict:
    """Add zh-Hant, ja, ko to a string entry's localizations."""
    if 'localizations' not in entry:
        return entry
    
    localizations = entry['localizations']
    
    # Get zh-Hans value for conversion to zh-Hant
    zh_hans_value = ''
    if 'zh-Hans' in localizations:
        zh_hans_unit = localizations['zh-Hans'].get('stringUnit', {})
        zh_hans_value = zh_hans_unit.get('value', '')
    
    # Get en value for ja/ko placeholders
    en_value = ''
    if 'en' in localizations:
        en_unit = localizations['en'].get('stringUnit', {})
        en_value = en_unit.get('value', '')
    
    # Add zh-Hant if not present
    if 'zh-Hant' not in localizations:
        zh_hant_value = convert_simplified_to_traditional(zh_hans_value) if zh_hans_value else ''
        localizations['zh-Hant'] = {
            'stringUnit': {
                'state': 'needs_review' if zh_hant_value else 'needs_translation',
                'value': zh_hant_value
            }
        }
    
    # Add ja if not present (use English as placeholder)
    if 'ja' not in localizations:
        localizations['ja'] = {
            'stringUnit': {
                'state': 'needs_translation',
                'value': en_value  # Use English as reference for translators
            }
        }
    
    # Add ko if not present (use English as placeholder)
    if 'ko' not in localizations:
        localizations['ko'] = {
            'stringUnit': {
                'state': 'needs_translation',
                'value': en_value  # Use English as reference for translators
            }
        }
    
    entry['localizations'] = localizations
    return entry


def main():
    if not XCSTRINGS_FILE.exists():
        print(f"Error: {XCSTRINGS_FILE} not found")
        sys.exit(1)
    
    # Create backup
    backup_file = XCSTRINGS_FILE.with_suffix(f'.xcstrings.backup.{datetime.now().strftime("%Y%m%d_%H%M%S")}')
    shutil.copy(XCSTRINGS_FILE, backup_file)
    print(f"Created backup: {backup_file.name}")
    
    # Load xcstrings
    with open(XCSTRINGS_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'strings' not in data:
        print("Error: Invalid xcstrings format (no 'strings' key)")
        sys.exit(1)
    
    strings = data['strings']
    updated_count = 0
    
    for key, entry in strings.items():
        if isinstance(entry, dict):
            strings[key] = add_languages_to_entry(entry)
            updated_count += 1
    
    # Write back
    with open(XCSTRINGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Updated {updated_count} string entries with zh-Hant, ja, ko languages")
    print(f"File saved: {XCSTRINGS_FILE}")
    print("\nNext steps:")
    print("1. Open Xcode and check the String Catalog")
    print("2. Review zh-Hant translations (auto-converted, may need review)")
    print("3. Send ja/ko entries to translators or use Xcode's export feature")


if __name__ == '__main__':
    main()
