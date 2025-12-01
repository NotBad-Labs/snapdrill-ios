#!/usr/bin/env python3
"""
为 NotBad 项目添加多语言支持
- zh-Hant (繁体中文): 从 zh-Hans 自动转换
- ja (日语): 创建待翻译模板
- ko (韩语): 创建待翻译模板
"""

import json
import os
from opencc import OpenCC

# 简体转繁体转换器 (s2twp = 简体到台湾繁体，带词汇转换)
cc = OpenCC('s2twp')

# 日语常用翻译映射 (教育类 App 核心词汇)
JA_TRANSLATIONS = {
    # 通用
    "app_name": "NotBad",
    "app_tagline": "間違いノート、賢く復習",
    "common_ok": "OK",
    "common_cancel": "キャンセル",
    "common_save": "保存",
    "common_delete": "削除",
    "common_edit": "編集",
    "common_done": "完了",
    "common_close": "閉じる",
    "common_back": "戻る",
    "common_next": "次へ",
    "common_confirm": "確認",
    "common_retry": "再試行",
    "common_loading": "読み込み中...",
    "common_error": "エラー",
    "common_success": "成功",
    
    # 导航
    "tab_dashboard": "ホーム",
    "tab_library": "ライブラリ",
    "tab_capture": "追加",
    "tab_review": "復習",
    "tab_profile": "プロフィール",
    
    # 仪表盘
    "dashboard_title": "ホーム",
    "dashboard_today_review": "今日の復習",
    "dashboard_pending_review": "復習待ち",
    "dashboard_total_items": "問題総数",
    "dashboard_mastery_rate": "習得率",
    "dashboard_streak_days": "連続学習日数",
    "dashboard_quick_actions": "クイックアクション",
    "dashboard_recent_items": "最近の問題",
    "dashboard_empty_title": "まだ問題がありません",
    "dashboard_empty_subtitle": "最初の間違いノートを追加しましょう",
    
    # 复习
    "review_title": "復習",
    "review_start": "復習開始",
    "review_complete": "復習完了",
    "review_progress": "進捗",
    "review_correct": "正解",
    "review_incorrect": "不正解",
    "review_skip": "スキップ",
    "review_show_answer": "答えを見る",
    "review_next_question": "次の問題",
    "review_session_complete": "セッション完了",
    "review_items_reviewed": "復習した問題",
    "review_time_spent": "所要時間",
    "review_accuracy": "正答率",
    
    # 复习模式
    "review_mode_smart": "スマート",
    "review_mode_weakest": "苦手優先",
    "review_mode_random": "ランダム",
    "review_mode_newest": "最新優先",
    "review_mode_overdue": "期限切れのみ",
    "review_mode_smart_desc": "エビングハウス曲線に基づく最適化",
    "review_mode_weakest_desc": "習得度の低い問題を優先",
    "review_mode_random_desc": "ランダムに出題",
    "review_mode_newest_desc": "最近追加した問題を優先",
    "review_mode_overdue_desc": "期限切れの問題のみ表示",
    
    # 拍照/添加
    "capture_title": "問題を追加",
    "capture_camera": "カメラ",
    "capture_album": "アルバム",
    "capture_scan": "スキャン",
    "capture_manual": "手動入力",
    "capture_field_title": "問題タイトル",
    "capture_field_subject": "科目",
    "capture_field_source": "出典",
    "capture_field_note": "メモ",
    "capture_save_success": "保存しました",
    "capture_save_error": "保存に失敗しました",
    
    # 题库
    "library_title": "ライブラリ",
    "library_empty_title": "問題がありません",
    "library_empty_subtitle": "最初の問題を追加しましょう",
    "library_search_placeholder": "検索...",
    "library_filter_all": "すべて",
    "library_filter_mastered": "習得済み",
    "library_filter_learning": "学習中",
    "library_sort_newest": "最新順",
    "library_sort_oldest": "古い順",
    
    # 个人
    "profile_title": "プロフィール",
    "profile_statistics": "統計",
    "profile_total_items": "問題総数",
    "profile_mastered": "習得済み",
    "profile_total_reviews": "総復習回数",
    "profile_study_days": "学習日数",
    "profile_settings": "設定",
    "profile_about": "このアプリについて",
    "profile_feedback": "フィードバック",
    
    # 科目
    "subject_math": "数学",
    "subject_chinese": "国語",
    "subject_english": "英語",
    "subject_physics": "物理",
    "subject_chemistry": "化学",
    "subject_biology": "生物",
    "subject_history": "歴史",
    "subject_geography": "地理",
    "subject_politics": "政治",
    "subject_other": "その他",
    
    # 掌握程度
    "mastery_none": "未習得",
    "mastery_glimpse": "理解が浅い",
    "mastery_partial": "半分理解",
    "mastery_good": "ほぼ習得",
    "mastery_mastered": "完全習得",
    
    # 错误类型
    "error_type_concept": "概念エラー",
    "error_type_calculation": "計算ミス",
    "error_type_careless": "ケアレスミス",
    "error_type_method": "解法エラー",
    "error_type_memory": "記憶エラー",
    "error_type_understanding": "理解不足",
    "error_type_other": "その他",
    
    # Onboarding
    "onboarding_welcome_title": "NotBadへようこそ",
    "onboarding_welcome_subtitle": "間違いを宝に変えましょう",
    "onboarding_get_started": "始める",
    "onboarding_skip": "スキップ",
    
    # 设置
    "settings_title": "設定",
    "settings_appearance": "外観",
    "settings_notifications": "通知",
    "settings_data": "データ管理",
    "settings_privacy": "プライバシー",
    "settings_language": "言語",
    "settings_theme": "テーマ",
    "settings_theme_light": "ライト",
    "settings_theme_dark": "ダーク",
    "settings_theme_system": "システム設定に従う",
}

# 韩语常用翻译映射
KO_TRANSLATIONS = {
    # 通用
    "app_name": "NotBad",
    "app_tagline": "오답노트, 스마트하게 복습하세요",
    "common_ok": "확인",
    "common_cancel": "취소",
    "common_save": "저장",
    "common_delete": "삭제",
    "common_edit": "편집",
    "common_done": "완료",
    "common_close": "닫기",
    "common_back": "뒤로",
    "common_next": "다음",
    "common_confirm": "확인",
    "common_retry": "재시도",
    "common_loading": "로딩 중...",
    "common_error": "오류",
    "common_success": "성공",
    
    # 导航
    "tab_dashboard": "홈",
    "tab_library": "라이브러리",
    "tab_capture": "추가",
    "tab_review": "복습",
    "tab_profile": "프로필",
    
    # 仪表盘
    "dashboard_title": "홈",
    "dashboard_today_review": "오늘의 복습",
    "dashboard_pending_review": "복습 대기",
    "dashboard_total_items": "총 문제 수",
    "dashboard_mastery_rate": "숙달률",
    "dashboard_streak_days": "연속 학습일",
    "dashboard_quick_actions": "빠른 작업",
    "dashboard_recent_items": "최근 문제",
    "dashboard_empty_title": "아직 문제가 없습니다",
    "dashboard_empty_subtitle": "첫 번째 오답을 추가해보세요",
    
    # 复习
    "review_title": "복습",
    "review_start": "복습 시작",
    "review_complete": "복습 완료",
    "review_progress": "진행률",
    "review_correct": "정답",
    "review_incorrect": "오답",
    "review_skip": "건너뛰기",
    "review_show_answer": "정답 보기",
    "review_next_question": "다음 문제",
    "review_session_complete": "세션 완료",
    "review_items_reviewed": "복습한 문제",
    "review_time_spent": "소요 시간",
    "review_accuracy": "정답률",
    
    # 复习模式
    "review_mode_smart": "스마트",
    "review_mode_weakest": "취약 우선",
    "review_mode_random": "랜덤",
    "review_mode_newest": "최신 우선",
    "review_mode_overdue": "기한 지난 것만",
    "review_mode_smart_desc": "에빙하우스 곡선 기반 최적화",
    "review_mode_weakest_desc": "숙달도가 낮은 문제 우선",
    "review_mode_random_desc": "랜덤 순서로 출제",
    "review_mode_newest_desc": "최근 추가한 문제 우선",
    "review_mode_overdue_desc": "기한 지난 문제만 표시",
    
    # 拍照/添加
    "capture_title": "문제 추가",
    "capture_camera": "카메라",
    "capture_album": "앨범",
    "capture_scan": "스캔",
    "capture_manual": "직접 입력",
    "capture_field_title": "문제 제목",
    "capture_field_subject": "과목",
    "capture_field_source": "출처",
    "capture_field_note": "메모",
    "capture_save_success": "저장되었습니다",
    "capture_save_error": "저장에 실패했습니다",
    
    # 题库
    "library_title": "라이브러리",
    "library_empty_title": "문제가 없습니다",
    "library_empty_subtitle": "첫 번째 문제를 추가해보세요",
    "library_search_placeholder": "검색...",
    "library_filter_all": "전체",
    "library_filter_mastered": "숙달됨",
    "library_filter_learning": "학습 중",
    "library_sort_newest": "최신순",
    "library_sort_oldest": "오래된순",
    
    # 个人
    "profile_title": "프로필",
    "profile_statistics": "통계",
    "profile_total_items": "총 문제 수",
    "profile_mastered": "숙달됨",
    "profile_total_reviews": "총 복습 횟수",
    "profile_study_days": "학습 일수",
    "profile_settings": "설정",
    "profile_about": "앱 정보",
    "profile_feedback": "피드백",
    
    # 科目
    "subject_math": "수학",
    "subject_chinese": "국어",
    "subject_english": "영어",
    "subject_physics": "물리",
    "subject_chemistry": "화학",
    "subject_biology": "생물",
    "subject_history": "역사",
    "subject_geography": "지리",
    "subject_politics": "정치",
    "subject_other": "기타",
    
    # 掌握程度
    "mastery_none": "미숙달",
    "mastery_glimpse": "이해 부족",
    "mastery_partial": "부분 이해",
    "mastery_good": "거의 숙달",
    "mastery_mastered": "완전 숙달",
    
    # 错误类型
    "error_type_concept": "개념 오류",
    "error_type_calculation": "계산 실수",
    "error_type_careless": "부주의 실수",
    "error_type_method": "풀이 오류",
    "error_type_memory": "암기 오류",
    "error_type_understanding": "이해 부족",
    "error_type_other": "기타",
    
    # Onboarding
    "onboarding_welcome_title": "NotBad에 오신 것을 환영합니다",
    "onboarding_welcome_subtitle": "실수를 보물로 바꿔보세요",
    "onboarding_get_started": "시작하기",
    "onboarding_skip": "건너뛰기",
    
    # 设置
    "settings_title": "설정",
    "settings_appearance": "외관",
    "settings_notifications": "알림",
    "settings_data": "데이터 관리",
    "settings_privacy": "개인정보",
    "settings_language": "언어",
    "settings_theme": "테마",
    "settings_theme_light": "라이트",
    "settings_theme_dark": "다크",
    "settings_theme_system": "시스템 설정 따르기",
}


def add_languages_to_xcstrings(file_path: str):
    """添加新语言到 xcstrings 文件"""
    
    print(f"读取文件: {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    strings = data['strings']
    stats = {
        'zh-Hant': {'added': 0, 'skipped': 0},
        'ja': {'added': 0, 'skipped': 0},
        'ko': {'added': 0, 'skipped': 0},
    }
    
    for key, value in strings.items():
        if 'localizations' not in value:
            value['localizations'] = {}
        
        locs = value['localizations']
        
        # 1. 添加繁体中文 (从简体转换)
        if 'zh-Hant' not in locs:
            # 优先从 zh-Hans 转换，否则尝试从 en 获取
            source_text = None
            if 'zh-Hans' in locs and 'stringUnit' in locs['zh-Hans']:
                source_text = locs['zh-Hans']['stringUnit'].get('value', '')
            
            if source_text:
                # 使用 OpenCC 转换
                traditional = cc.convert(source_text)
                locs['zh-Hant'] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': traditional
                    }
                }
                stats['zh-Hant']['added'] += 1
            else:
                stats['zh-Hant']['skipped'] += 1
        
        # 2. 添加日语
        if 'ja' not in locs:
            if key in JA_TRANSLATIONS:
                locs['ja'] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': JA_TRANSLATIONS[key]
                    }
                }
                stats['ja']['added'] += 1
            else:
                # 对于没有翻译的 key，标记为需要翻译
                # 使用英文作为占位符
                en_value = ''
                if 'en' in locs and 'stringUnit' in locs['en']:
                    en_value = locs['en']['stringUnit'].get('value', key)
                
                if en_value:
                    locs['ja'] = {
                        'stringUnit': {
                            'state': 'needs_review',
                            'value': en_value  # 使用英文作为占位
                        }
                    }
                stats['ja']['skipped'] += 1
        
        # 3. 添加韩语
        if 'ko' not in locs:
            if key in KO_TRANSLATIONS:
                locs['ko'] = {
                    'stringUnit': {
                        'state': 'translated',
                        'value': KO_TRANSLATIONS[key]
                    }
                }
                stats['ko']['added'] += 1
            else:
                # 使用英文作为占位符
                en_value = ''
                if 'en' in locs and 'stringUnit' in locs['en']:
                    en_value = locs['en']['stringUnit'].get('value', key)
                
                if en_value:
                    locs['ko'] = {
                        'stringUnit': {
                            'state': 'needs_review',
                            'value': en_value
                        }
                    }
                stats['ko']['skipped'] += 1
    
    # 保存文件
    print(f"\n保存文件: {file_path}")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # 打印统计
    print("\n=== 处理完成 ===")
    print(f"繁体中文 (zh-Hant): 已翻译 {stats['zh-Hant']['added']}, 跳过 {stats['zh-Hant']['skipped']}")
    print(f"日语 (ja): 核心词汇已翻译 {stats['ja']['added']}, 待翻译 {stats['ja']['skipped']}")
    print(f"韩语 (ko): 核心词汇已翻译 {stats['ko']['added']}, 待翻译 {stats['ko']['skipped']}")
    print("\n提示: state='needs_review' 的条目需要人工翻译")


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    xcstrings_path = os.path.join(project_root, 'NotBad', 'Resources', 'Localizable.xcstrings')
    
    if not os.path.exists(xcstrings_path):
        print(f"错误: 找不到文件 {xcstrings_path}")
        exit(1)
    
    add_languages_to_xcstrings(xcstrings_path)
