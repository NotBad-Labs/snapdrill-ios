#!/usr/bin/env python3
"""
Script to add missing education localization keys to Localizable.xcstrings
"""

import json
from pathlib import Path

# Define translations for all missing keys
translations = {
    # International grades
    "intl_grade_1": {"en": "Grade 1", "zh-Hans": "一年级", "zh-Hant": "一年級", "ja": "1年生", "ko": "1학년"},
    "intl_grade_2": {"en": "Grade 2", "zh-Hans": "二年级", "zh-Hant": "二年級", "ja": "2年生", "ko": "2학년"},
    "intl_grade_3": {"en": "Grade 3", "zh-Hans": "三年级", "zh-Hant": "三年級", "ja": "3年生", "ko": "3학년"},
    "intl_grade_4": {"en": "Grade 4", "zh-Hans": "四年级", "zh-Hant": "四年級", "ja": "4年生", "ko": "4학년"},
    "intl_grade_5": {"en": "Grade 5", "zh-Hans": "五年级", "zh-Hant": "五年級", "ja": "5年生", "ko": "5학년"},
    "intl_grade_6": {"en": "Grade 6", "zh-Hans": "六年级", "zh-Hant": "六年級", "ja": "6年生", "ko": "6학년"},
    "intl_grade_7": {"en": "Grade 7", "zh-Hans": "七年级", "zh-Hant": "七年級", "ja": "7年生", "ko": "7학년"},
    "intl_grade_8": {"en": "Grade 8", "zh-Hans": "八年级", "zh-Hant": "八年級", "ja": "8年生", "ko": "8학년"},
    "intl_grade_9": {"en": "Grade 9", "zh-Hans": "九年级", "zh-Hant": "九年級", "ja": "9年生", "ko": "9학년"},
    "intl_grade_10": {"en": "Grade 10", "zh-Hans": "十年级", "zh-Hant": "十年級", "ja": "10年生", "ko": "10학년"},
    "intl_grade_11": {"en": "Grade 11", "zh-Hans": "十一年级", "zh-Hant": "十一年級", "ja": "11年生", "ko": "11학년"},
    "intl_grade_12": {"en": "Grade 12", "zh-Hans": "十二年级", "zh-Hant": "十二年級", "ja": "12年生", "ko": "12학년"},
    "intl_school_level_primary": {"en": "Primary School", "zh-Hans": "小学", "zh-Hant": "小學", "ja": "小学校", "ko": "초등학교"},
    "intl_school_level_middle": {"en": "Middle School", "zh-Hans": "初中", "zh-Hant": "初中", "ja": "中学校", "ko": "중학교"},
    "intl_school_level_high": {"en": "High School", "zh-Hans": "高中", "zh-Hant": "高中", "ja": "高等学校", "ko": "고등학교"},
    "intl_subject_category_language": {"en": "Languages", "zh-Hans": "语言", "zh-Hant": "語言", "ja": "言語", "ko": "언어"},
    "intl_subject_category_science": {"en": "Science", "zh-Hans": "科学", "zh-Hant": "科學", "ja": "理科", "ko": "과학"},
    "intl_subject_category_humanities": {"en": "Humanities", "zh-Hans": "人文", "zh-Hant": "人文", "ja": "人文科学", "ko": "인문"},
    "intl_subject_category_other": {"en": "Other", "zh-Hans": "其他", "zh-Hant": "其他", "ja": "その他", "ko": "기타"},

    # Japan grades
    "jp_grade_1": {"en": "Grade 1", "zh-Hans": "一年级", "zh-Hant": "一年級", "ja": "小学1年生", "ko": "1학년"},
    "jp_grade_2": {"en": "Grade 2", "zh-Hans": "二年级", "zh-Hant": "二年級", "ja": "小学2年生", "ko": "2학년"},
    "jp_grade_3": {"en": "Grade 3", "zh-Hans": "三年级", "zh-Hant": "三年級", "ja": "小学3年生", "ko": "3학년"},
    "jp_grade_4": {"en": "Grade 4", "zh-Hans": "四年级", "zh-Hant": "四年級", "ja": "小学4年生", "ko": "4학년"},
    "jp_grade_5": {"en": "Grade 5", "zh-Hans": "五年级", "zh-Hant": "五年級", "ja": "小学5年生", "ko": "5학년"},
    "jp_grade_6": {"en": "Grade 6", "zh-Hans": "六年级", "zh-Hant": "六年級", "ja": "小学6年生", "ko": "6학년"},
    "jp_grade_7": {"en": "Grade 7", "zh-Hans": "初一", "zh-Hant": "初一", "ja": "中学1年生", "ko": "중학교 1학년"},
    "jp_grade_8": {"en": "Grade 8", "zh-Hans": "初二", "zh-Hant": "初二", "ja": "中学2年生", "ko": "중학교 2학년"},
    "jp_grade_9": {"en": "Grade 9", "zh-Hans": "初三", "zh-Hant": "初三", "ja": "中学3年生", "ko": "중학교 3학년"},
    "jp_grade_10": {"en": "Grade 10", "zh-Hans": "高一", "zh-Hant": "高一", "ja": "高校1年生", "ko": "고등학교 1학년"},
    "jp_grade_11": {"en": "Grade 11", "zh-Hans": "高二", "zh-Hant": "高二", "ja": "高校2年生", "ko": "고등학교 2학년"},
    "jp_grade_12": {"en": "Grade 12", "zh-Hans": "高三", "zh-Hant": "高三", "ja": "高校3年生", "ko": "고등학교 3학년"},
    "jp_school_level_primary": {"en": "Elementary School", "zh-Hans": "小学", "zh-Hant": "小學", "ja": "小学校", "ko": "초등학교"},
    "jp_school_level_middle": {"en": "Junior High School", "zh-Hans": "中学", "zh-Hant": "中學", "ja": "中学校", "ko": "중학교"},
    "jp_school_level_high": {"en": "High School", "zh-Hans": "高中", "zh-Hant": "高中", "ja": "高等学校", "ko": "고등학교"},
    "jp_subject_category_language": {"en": "Languages", "zh-Hans": "语言", "zh-Hant": "語言", "ja": "言語", "ko": "언어"},
    "jp_subject_category_science": {"en": "Science", "zh-Hans": "科学", "zh-Hant": "科學", "ja": "理科", "ko": "과학"},
    "jp_subject_category_humanities": {"en": "Humanities", "zh-Hans": "人文", "zh-Hant": "人文", "ja": "人文科学", "ko": "인문"},
    "jp_subject_category_other": {"en": "Other", "zh-Hans": "其他", "zh-Hant": "其他", "ja": "その他", "ko": "기타"},

    # Korea grades
    "kr_grade_1": {"en": "Grade 1", "zh-Hans": "一年级", "zh-Hant": "一年級", "ja": "1年生", "ko": "초등학교 1학년"},
    "kr_grade_2": {"en": "Grade 2", "zh-Hans": "二年级", "zh-Hant": "二年級", "ja": "2年生", "ko": "초등학교 2학년"},
    "kr_grade_3": {"en": "Grade 3", "zh-Hans": "三年级", "zh-Hant": "三年級", "ja": "3年生", "ko": "초등학교 3학년"},
    "kr_grade_4": {"en": "Grade 4", "zh-Hans": "四年级", "zh-Hant": "四年級", "ja": "4年生", "ko": "초등학교 4학년"},
    "kr_grade_5": {"en": "Grade 5", "zh-Hans": "五年级", "zh-Hant": "五年級", "ja": "5年生", "ko": "초등학교 5학년"},
    "kr_grade_6": {"en": "Grade 6", "zh-Hans": "六年级", "zh-Hant": "六年級", "ja": "6年生", "ko": "초등학교 6학년"},
    "kr_grade_7": {"en": "Grade 7", "zh-Hans": "初一", "zh-Hant": "初一", "ja": "中学1年生", "ko": "중학교 1학년"},
    "kr_grade_8": {"en": "Grade 8", "zh-Hans": "初二", "zh-Hant": "初二", "ja": "中学2年生", "ko": "중학교 2학년"},
    "kr_grade_9": {"en": "Grade 9", "zh-Hans": "初三", "zh-Hant": "初三", "ja": "中学3年生", "ko": "중학교 3학년"},
    "kr_grade_10": {"en": "Grade 10", "zh-Hans": "高一", "zh-Hant": "高一", "ja": "高校1年生", "ko": "고등학교 1학년"},
    "kr_grade_11": {"en": "Grade 11", "zh-Hans": "高二", "zh-Hant": "高二", "ja": "高校2年生", "ko": "고등학교 2학년"},
    "kr_grade_12": {"en": "Grade 12", "zh-Hans": "高三", "zh-Hant": "高三", "ja": "高校3年生", "ko": "고등학교 3학년"},
    "kr_school_level_primary": {"en": "Elementary School", "zh-Hans": "小学", "zh-Hant": "小學", "ja": "小学校", "ko": "초등학교"},
    "kr_school_level_middle": {"en": "Middle School", "zh-Hans": "中学", "zh-Hant": "中學", "ja": "中学校", "ko": "중학교"},
    "kr_school_level_high": {"en": "High School", "zh-Hans": "高中", "zh-Hant": "高中", "ja": "高等学校", "ko": "고등학교"},
    "kr_subject_category_language": {"en": "Languages", "zh-Hans": "语言", "zh-Hant": "語言", "ja": "言語", "ko": "언어"},
    "kr_subject_category_science": {"en": "Science", "zh-Hans": "科学", "zh-Hant": "科學", "ja": "理科", "ko": "과학"},
    "kr_subject_category_humanities": {"en": "Humanities", "zh-Hans": "人文", "zh-Hant": "人文", "ja": "人文科学", "ko": "인문"},
    "kr_subject_category_other": {"en": "Other", "zh-Hans": "其他", "zh-Hant": "其他", "ja": "その他", "ko": "기타"},

    # Singapore grades
    "sg_grade_p1": {"en": "Primary 1", "zh-Hans": "小一", "zh-Hant": "小一", "ja": "小学1年生", "ko": "초등학교 1학년"},
    "sg_grade_p2": {"en": "Primary 2", "zh-Hans": "小二", "zh-Hant": "小二", "ja": "小学2年生", "ko": "초등학교 2학년"},
    "sg_grade_p3": {"en": "Primary 3", "zh-Hans": "小三", "zh-Hant": "小三", "ja": "小学3年生", "ko": "초등학교 3학년"},
    "sg_grade_p4": {"en": "Primary 4", "zh-Hans": "小四", "zh-Hant": "小四", "ja": "小学4年生", "ko": "초등학교 4학년"},
    "sg_grade_p5": {"en": "Primary 5", "zh-Hans": "小五", "zh-Hant": "小五", "ja": "小学5年生", "ko": "초등학교 5학년"},
    "sg_grade_p6": {"en": "Primary 6", "zh-Hans": "小六", "zh-Hant": "小六", "ja": "小学6年生", "ko": "초등학교 6학년"},
    "sg_grade_s1": {"en": "Secondary 1", "zh-Hans": "中一", "zh-Hant": "中一", "ja": "中学1年生", "ko": "중학교 1학년"},
    "sg_grade_s2": {"en": "Secondary 2", "zh-Hans": "中二", "zh-Hant": "中二", "ja": "中学2年生", "ko": "중학교 2학년"},
    "sg_grade_s3": {"en": "Secondary 3", "zh-Hans": "中三", "zh-Hant": "中三", "ja": "中学3年生", "ko": "중학교 3학년"},
    "sg_grade_s4": {"en": "Secondary 4", "zh-Hans": "中四", "zh-Hant": "中四", "ja": "中学4年生", "ko": "중학교 4학년"},
    "sg_grade_jc1": {"en": "JC 1", "zh-Hans": "初院一", "zh-Hant": "初院一", "ja": "高校1年生", "ko": "고등학교 1학년"},
    "sg_grade_jc2": {"en": "JC 2", "zh-Hans": "初院二", "zh-Hant": "初院二", "ja": "高校2年生", "ko": "고등학교 2학년"},
    "sg_school_level_primary": {"en": "Primary School", "zh-Hans": "小学", "zh-Hant": "小學", "ja": "小学校", "ko": "초등학교"},
    "sg_school_level_middle": {"en": "Secondary School", "zh-Hans": "中学", "zh-Hant": "中學", "ja": "中等学校", "ko": "중학교"},
    "sg_school_level_high": {"en": "Junior College", "zh-Hans": "初级学院", "zh-Hant": "初級學院", "ja": "ジュニアカレッジ", "ko": "주니어 칼리지"},
    "sg_subject_category_language": {"en": "Languages", "zh-Hans": "语言", "zh-Hant": "語言", "ja": "言語", "ko": "언어"},
    "sg_subject_category_science": {"en": "Science", "zh-Hans": "科学", "zh-Hant": "科學", "ja": "理科", "ko": "과학"},
    "sg_subject_category_other": {"en": "Other", "zh-Hans": "其他", "zh-Hant": "其他", "ja": "その他", "ko": "기타"},
}


def create_localization_entry(translations_dict: dict) -> dict:
    """Create a localization entry in the xcstrings format"""
    localizations = {}
    for lang, value in translations_dict.items():
        localizations[lang] = {
            "stringUnit": {
                "state": "translated",
                "value": value
            }
        }
    return {
        "extractionState": "manual",
        "localizations": localizations
    }


def main():
    xcstrings_path = Path(__file__).parent.parent / "NotBad" / "Resources" / "Localizable.xcstrings"
    
    print(f"Reading {xcstrings_path}...")
    with open(xcstrings_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    strings = data["strings"]
    added_count = 0
    
    for key, trans in translations.items():
        if key not in strings:
            strings[key] = create_localization_entry(trans)
            added_count += 1
            print(f"  Added: {key}")
        else:
            print(f"  Skipped (exists): {key}")
    
    # Sort keys for cleaner git diffs
    data["strings"] = dict(sorted(strings.items()))
    
    print(f"\nWriting {xcstrings_path}...")
    with open(xcstrings_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\nDone! Added {added_count} new localization keys.")


if __name__ == "__main__":
    main()
