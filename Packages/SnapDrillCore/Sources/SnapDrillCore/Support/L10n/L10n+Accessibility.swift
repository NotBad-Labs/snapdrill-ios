//
//  L10n+Accessibility.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 无障碍分片：VoiceOver 标签、提示与公告。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Accessibility

    public enum Accessibility {
        // 复习卡片
        public static let flipToAnswer = NSLocalizedString("accessibility.flip_to_answer", value: "双击翻转查看答案", comment: "VoiceOver 翻卡提示")
        public static let flipToQuestion = NSLocalizedString("accessibility.flip_to_question", value: "双击翻转回到题目", comment: "VoiceOver 翻卡提示")
        public static let flippedToAnswer = NSLocalizedString("accessibility.flipped_to_answer", value: "已翻到答案面", comment: "VoiceOver 翻卡公告")
        public static let flippedToQuestion = NSLocalizedString("accessibility.flipped_to_question", value: "已翻到题目面", comment: "VoiceOver 翻卡公告")
        public static let showAnswer = NSLocalizedString("accessibility.show_answer", value: "显示答案", comment: "VoiceOver 翻面按钮")
        public static let hideAnswer = NSLocalizedString("accessibility.hide_answer", value: "隐藏答案", comment: "VoiceOver 翻面按钮")
        public static let undo = NSLocalizedString("accessibility.undo", value: "撤销", comment: "VoiceOver 撤销按钮")
        public static let undoHint = NSLocalizedString("accessibility.undo_hint", value: "撤销上一次滑动评估", comment: "VoiceOver 撤销按钮提示")
        public static let pauseReview = NSLocalizedString("accessibility.pause_review", value: "暂停复习", comment: "VoiceOver 暂停按钮")
        public static let moreActions = NSLocalizedString("accessibility.more_actions", value: "更多操作", comment: "VoiceOver 省略号菜单")
        public static let questionImage = NSLocalizedString("accessibility.question_image", value: "题目图片", comment: "VoiceOver 题目图片")
        public static let answerImage = NSLocalizedString("accessibility.answer_image", value: "答案图片", comment: "VoiceOver 答案图片")
        public static let forgotHint = NSLocalizedString("accessibility.forgot_hint", value: "标记为忘记，稍后会再次出现", comment: "VoiceOver 忘记按钮提示")
        public static let rememberHint = NSLocalizedString("accessibility.remember_hint", value: "标记为记得，延长复习间隔", comment: "VoiceOver 记得按钮提示")

        // 复习摘要
        public static func summaryAnnouncement(good: Int, again: Int) -> String {
            String(format: NSLocalizedString("accessibility.summary_announcement", value: "复习完成，掌握 %d 题，待加强 %d 题", comment: "VoiceOver 复习摘要公告"), good, again)
        }
        public static func statCard(title: String, count: Int) -> String {
            String(format: NSLocalizedString("accessibility.stat_card", value: "%@ %d 题", comment: "VoiceOver 统计卡片"), title, count)
        }

        // 复习 Dashboard
        public static func pendingReview(count: Int) -> String {
            String(format: NSLocalizedString("accessibility.pending_review", value: "待复习 %d 道题", comment: "VoiceOver 待复习数"), count)
        }
        public static func reviewedToday(count: Int) -> String {
            String(format: NSLocalizedString("accessibility.reviewed_today", value: "今日已复习 %d 道题", comment: "VoiceOver 已复习数"), count)
        }
        public static let startReviewHint = NSLocalizedString("accessibility.start_review_hint", value: "开始今日复习会话", comment: "VoiceOver 开始复习提示")

        // AccessibilityHelper 使用的键
        public static func reviewItemLabel(subject: String, difficulty: String, content: String) -> String {
            String(format: NSLocalizedString("accessibility.review_item_label", value: "%@题目，难度%@，内容：%@", comment: "VoiceOver 复习项目完整标签"), subject, difficulty, content)
        }
        public static func reviewButtonHint(count: Int) -> String {
            String(format: NSLocalizedString("accessibility.review_button_hint", value: "轻点开始复习 %d 道题目", comment: "VoiceOver 复习按钮提示"), count)
        }
        public static func exportButtonHint(format: String) -> String {
            String(format: NSLocalizedString("accessibility.export_button_hint", value: "轻点导出为 %@ 格式", comment: "VoiceOver 导出按钮提示"), format)
        }
        public static func progressDescription(current: Int, total: Int, percentage: Int) -> String {
            String(format: NSLocalizedString("accessibility.progress_description", value: "已完成 %d 道，共 %d 道，进度 %d%%", comment: "VoiceOver 进度描述"), current, total, percentage)
        }
        public static func difficultyLevel(_ difficulty: Int) -> String {
            NSLocalizedString("accessibility.difficulty_\(difficulty)", value: {
                switch difficulty {
                case 1: return "非常简单"
                case 2: return "简单"
                case 3: return "中等"
                case 4: return "困难"
                case 5: return "非常困难"
                default: return "未知"
                }
            }(), comment: "VoiceOver 难度描述")
        }

        // 标签
        public static func deleteTag(_ name: String) -> String {
            String(format: NSLocalizedString("accessibility.delete_tag", value: "删除标签%@", comment: "VoiceOver 删除标签按钮"), name)
        }
        public static func addTag(_ name: String) -> String {
            String(format: NSLocalizedString("accessibility.add_tag", value: "添加标签%@", comment: "VoiceOver 添加标签按钮"), name)
        }

        // 首页仪表盘
        public static let profile = NSLocalizedString("accessibility.profile", value: "个人资料", comment: "VoiceOver 头像按钮")
        public static let profileHint = NSLocalizedString("accessibility.profile_hint", value: "打开设置页面", comment: "VoiceOver 头像按钮提示")
        public static let captureFirstItemHint = NSLocalizedString("accessibility.capture_first_item_hint", value: "拍照录入第一道错题", comment: "VoiceOver 首次录入按钮提示")
        public static let startReviewNowHint = NSLocalizedString("accessibility.start_review_now_hint", value: "开始复习待复习的题目", comment: "VoiceOver 立即开始按钮提示")
        public static let allDoneLabel = NSLocalizedString("accessibility.all_done_label", value: "太棒了，今日复习已完成，好好休息吧", comment: "VoiceOver 全部完成卡片")
        public static func dueCountLabel(count: Int) -> String {
            String(format: NSLocalizedString("accessibility.due_count_label", value: "今日待复习 %d 道题", comment: "VoiceOver 待复习数"), count)
        }
        public static func reviewProgressLabel(reviewed: Int, total: Int) -> String {
            String(format: NSLocalizedString("accessibility.review_progress_label", value: "今日复习进度，已完成 %d 道，共 %d 道", comment: "VoiceOver 复习进度环"), reviewed, total)
        }
        public static func dailyStatsLabel(added: Int, reviewed: Int, due: Int) -> String {
            String(format: NSLocalizedString("accessibility.daily_stats_label", value: "今日统计：新增 %d 题，已复习 %d 题，待复习 %d 题", comment: "VoiceOver 每日统计"), added, reviewed, due)
        }

        // 采集模块
        public static let takePhoto = NSLocalizedString("accessibility.take_photo", value: "拍照", comment: "VoiceOver 快门按钮")
        public static let cancelCamera = NSLocalizedString("accessibility.cancel_camera", value: "取消拍照", comment: "VoiceOver 取消相机按钮")
        public static let cameraHint = NSLocalizedString("accessibility.camera_hint", value: "打开相机拍摄题目", comment: "VoiceOver 拍照录入提示")
        public static let albumHint = NSLocalizedString("accessibility.album_hint", value: "从相册选择题目图片", comment: "VoiceOver 相册导入提示")
        public static let manualHint = NSLocalizedString("accessibility.manual_hint", value: "手动输入题目文字", comment: "VoiceOver 手动录入提示")
        public static let clipboardHint = NSLocalizedString("accessibility.clipboard_hint", value: "读取剪贴板中的文字或图片", comment: "VoiceOver 粘贴板提示")
        public static let pdfHint = NSLocalizedString("accessibility.pdf_hint", value: "选择 PDF 文件导入题目", comment: "VoiceOver PDF 导入提示")
        public static let docScanHint = NSLocalizedString("accessibility.doc_scan_hint", value: "使用系统文档扫描仪拍摄试卷", comment: "VoiceOver 文档扫描提示")
        public static let cropImage = NSLocalizedString("accessibility.crop_image", value: "裁剪图片", comment: "VoiceOver 裁剪按钮")
        public static let cropImageHint = NSLocalizedString("accessibility.crop_image_hint", value: "裁剪题目图片区域", comment: "VoiceOver 裁剪按钮提示")
        public static let reRecognizeHint = NSLocalizedString("accessibility.re_recognize_hint", value: "对裁剪后的图片重新进行文字识别", comment: "VoiceOver 重新识别提示")
        public static let copyContentHint = NSLocalizedString("accessibility.copy_content_hint", value: "将识别文字复制到剪贴板", comment: "VoiceOver 复制文本按钮提示")
        public static func pdfPageButton(page: Int) -> String {
            String(format: NSLocalizedString("accessibility.pdf_page_button", value: "第 %d 页，轻点选择此页", comment: "VoiceOver PDF 页面按钮"), page)
        }
        public static let pdfLoadingThumbnail = NSLocalizedString("accessibility.pdf_loading_thumbnail", value: "正在加载缩略图", comment: "VoiceOver PDF 缩略图加载中")
        public static let processingOverlay = NSLocalizedString("accessibility.processing_overlay", value: "正在处理中，请稍候", comment: "VoiceOver 处理中遮罩")

        // 题库模块
        public static func selectAllButton(selected: Int, total: Int) -> String {
            String(format: NSLocalizedString("accessibility.select_all_button", value: "已选中 %d 项，共 %d 项", comment: "VoiceOver 全选按钮值"), selected, total)
        }
        public static func filterSubject(_ name: String) -> String {
            String(format: NSLocalizedString("accessibility.filter_subject", value: "过滤 %@", comment: "VoiceOver 学科过滤按钮"), name)
        }
        public static func removeTagFilter(_ name: String) -> String {
            String(format: NSLocalizedString("accessibility.remove_tag_filter", value: "移除标签过滤 %@", comment: "VoiceOver 移除标签过滤"), name)
        }
        public static let longPressToSelect = NSLocalizedString("accessibility.long_press_to_select", value: "长按进入多选模式", comment: "VoiceOver 长按多选提示")
        public static let tapToEnlarge = NSLocalizedString("accessibility.tap_to_enlarge", value: "轻点放大查看", comment: "VoiceOver 图片点击放大提示")
        public static func metadataGroup(subject: String, source: String, difficulty: Int) -> String {
            let diffDesc = difficultyDescription(difficulty)
            return String(format: NSLocalizedString("accessibility.metadata_group", value: "%@ · %@ · 难度%@", comment: "VoiceOver 元数据组合"), subject, source, diffDesc)
        }
        public static let closeFullScreenImage = NSLocalizedString("accessibility.close_full_screen_image", value: "关闭全屏图片", comment: "VoiceOver 关闭全屏图片")
        public static let fullScreenQuestionImage = NSLocalizedString("accessibility.full_screen_question_image", value: "题目图片全屏预览", comment: "VoiceOver 全屏题目图片")
        public static let exportPDFHint = NSLocalizedString("accessibility.export_pdf_hint", value: "生成 PDF 格式导出", comment: "VoiceOver 导出 PDF 提示")
        public static let exportCSVHint = NSLocalizedString("accessibility.export_csv_hint", value: "生成 CSV 格式导出", comment: "VoiceOver 导出 CSV 提示")
        public static let pdfPreviewLabel = NSLocalizedString("accessibility.pdf_preview_label", value: "PDF 预览", comment: "VoiceOver PDF 预览")
        public static let generatingPDF = NSLocalizedString("accessibility.generating_pdf", value: "正在生成 PDF，请稍候", comment: "VoiceOver PDF 生成中")
        public static let addGradeHint = NSLocalizedString("accessibility.add_grade_hint", value: "添加新的年级或学习阶段", comment: "VoiceOver 添加年级提示")
        public static func editGradeHint(_ name: String) -> String {
            String(format: NSLocalizedString("accessibility.edit_grade_hint", value: "编辑年级 %@", comment: "VoiceOver 编辑年级提示"), name)
        }
        public static func selectIcon(_ symbol: String) -> String {
            String(format: NSLocalizedString("accessibility.select_icon", value: "图标 %@", comment: "VoiceOver 选择图标"), symbol)
        }

        // Settings
        public static let fieldSubjectHint = NSLocalizedString("accessibility.field_subject_hint", value: "开启后录入时显示学科选择", comment: "VoiceOver 学科字段提示")
        public static let fieldSourceHint = NSLocalizedString("accessibility.field_source_hint", value: "开启后录入时显示来源选择", comment: "VoiceOver 来源字段提示")
        public static let fieldDifficultyHint = NSLocalizedString("accessibility.field_difficulty_hint", value: "开启后录入时显示难度选择", comment: "VoiceOver 难度字段提示")
        public static let fieldGradeHint = NSLocalizedString("accessibility.field_grade_hint", value: "开启后录入时显示年级选择", comment: "VoiceOver 年级字段提示")
        public static let fieldAnswerHint = NSLocalizedString("accessibility.field_answer_hint", value: "开启后录入时显示答案输入", comment: "VoiceOver 答案字段提示")
        public static let clearAllDataHint = NSLocalizedString("accessibility.clear_all_data_hint", value: "删除所有题目、标签和复习记录，不可恢复", comment: "VoiceOver 清除数据提示")
        public static let generateTestDataHint = NSLocalizedString("accessibility.generate_test_data_hint", value: "生成模拟数据用于调试", comment: "VoiceOver 生成测试数据提示")
        public static let setAvatarHint = NSLocalizedString("accessibility.set_avatar_hint", value: "从相册或系统图标中选择头像", comment: "VoiceOver 设置头像提示")
        public static func avatarColorName(_ index: Int) -> String {
            let names = [
                NSLocalizedString("accessibility.color_blue_purple", value: "蓝紫", comment: "VoiceOver 颜色"),
                NSLocalizedString("accessibility.color_warm_orange", value: "暖橙", comment: "VoiceOver 颜色"),
                NSLocalizedString("accessibility.color_green", value: "绿色", comment: "VoiceOver 颜色"),
                NSLocalizedString("accessibility.color_pink_indigo", value: "粉紫", comment: "VoiceOver 颜色"),
                NSLocalizedString("accessibility.color_gray_black", value: "灰黑", comment: "VoiceOver 颜色"),
                NSLocalizedString("accessibility.color_sunny_yellow", value: "明黄", comment: "VoiceOver 颜色")
            ]
            let name = index < names.count ? names[index] : ""
            return String(format: NSLocalizedString("accessibility.avatar_color_name", value: "主题色 %@", comment: "VoiceOver 头像颜色名称"), name)
        }
        public static let enableReminderHint = NSLocalizedString("accessibility.enable_reminder_hint", value: "每天定时提醒你复习到期的题目", comment: "VoiceOver 开启提醒提示")
        public static let soundToggleHint = NSLocalizedString("accessibility.sound_toggle_hint", value: "提醒时播放提示音", comment: "VoiceOver 声音开关提示")
        public static func fontSizeValue(_ size: Int) -> String {
            String(format: NSLocalizedString("accessibility.font_size_value", value: "%d 磅", comment: "VoiceOver 字号值"), size)
        }
        public static let backupDataHint = NSLocalizedString("accessibility.backup_data_hint", value: "导出完整数据备份文件", comment: "VoiceOver 备份数据提示")
        public static let restoreDataHint = NSLocalizedString("accessibility.restore_data_hint", value: "从备份文件恢复所有数据，会覆盖当前数据", comment: "VoiceOver 恢复数据提示")
        public static let analyticsToggleHint = NSLocalizedString("accessibility.analytics_toggle_hint", value: "设置本地诊断偏好；当前版本不会发送使用数据", comment: "VoiceOver 分析开关提示")
        public static let crashReportingHint = NSLocalizedString("accessibility.crash_reporting_hint", value: "当前版本不会自动发送崩溃报告", comment: "VoiceOver 崩溃报告提示")
        public static let exportDataHint = NSLocalizedString("accessibility.export_data_hint", value: "导出个人数据副本", comment: "VoiceOver 导出数据提示")

        // 难度
        private static func difficultyDescription(_ difficulty: Int) -> String {
            NSLocalizedString("accessibility.difficulty_\(difficulty)", value: {
                switch difficulty {
                case 1: return "非常简单"
                case 2: return "简单"
                case 3: return "中等"
                case 4: return "困难"
                case 5: return "非常困难"
                default: return "未知"
                }
            }(), comment: "VoiceOver 难度描述")
        }
        public static func starRating(difficulty: Int, maxStars: Int = 5) -> String {
            let desc = difficultyDescription(difficulty)
            return String(format: NSLocalizedString("accessibility.star_rating", value: "难度 %d 星（共 %d 星），%@", comment: "VoiceOver 难度星级"), difficulty, maxStars, desc)
        }
    }
}
