//
//  LocalizationKeys.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  本地化键值定义，所有 UI 可见字符串的唯一来源。
//

import Foundation

/// 本地化字符串键值
///
/// 使用枚举组织所有本地化字符串，提供类型安全的访问方式。
/// 所有条目使用 `NSLocalizedString(_:value:comment:)` 确保中文为默认值，
/// 未来添加 `.strings` 文件即可支持多语言。
public enum L10n {

    // MARK: - AppRoot

    public enum AppRoot {
        public static let degradedModeTitle = NSLocalizedString("app_root.degraded_mode_title", value: "数据保护模式", comment: "降级模式标题")
        public static let degradedModeDescription = NSLocalizedString("app_root.degraded_mode_description", value: "数据仅保存在内存中，重启后将丢失。建议重启应用以恢复正常。", comment: "降级模式描述")
        public static let maintenanceTitle = NSLocalizedString("app_root.maintenance_title", value: "测试版维护中", comment: "维护页标题")
        public static let maintenanceDescription = NSLocalizedString("app_root.maintenance_description", value: "当前测试版本正在进行紧急维护或已失效，请稍后再试或前往 TestFlight 下载最新版本。", comment: "维护页描述")
        public static let checkUpdate = NSLocalizedString("app_root.check_update", value: "检查更新", comment: "检查更新按钮")
    }

    // MARK: - Common

    public enum Common {
        public static let ok = NSLocalizedString("common.ok", value: "确定", comment: "确定按钮")
        public static let cancel = NSLocalizedString("common.cancel", value: "取消", comment: "取消按钮")
        public static let save = NSLocalizedString("common.save", value: "保存", comment: "保存按钮")
        public static let delete = NSLocalizedString("common.delete", value: "删除", comment: "删除按钮")
        public static let edit = NSLocalizedString("common.edit", value: "编辑", comment: "编辑按钮")
        public static let done = NSLocalizedString("common.done", value: "完成", comment: "完成按钮")
        public static let retry = NSLocalizedString("common.retry", value: "重试", comment: "重试按钮")
        public static let close = NSLocalizedString("common.close", value: "关闭", comment: "关闭按钮")
        public static let loading = NSLocalizedString("common.loading", value: "加载中", comment: "加载中")
        public static let error = NSLocalizedString("common.error", value: "错误", comment: "错误")
        public static let create = NSLocalizedString("common.create", value: "创建", comment: "创建按钮")
        public static let discard = NSLocalizedString("common.discard", value: "放弃", comment: "放弃按钮")
        public static let reset = NSLocalizedString("common.reset", value: "重置", comment: "重置按钮")
        public static let notSelected = NSLocalizedString("common.not_selected", value: "未选择", comment: "未选择占位")
        public static let processing = NSLocalizedString("common.processing", value: "正在处理...", comment: "正在处理中")
        public static let comingSoon = NSLocalizedString("common.coming_soon", value: "即将上线", comment: "即将上线占位")
        public static let openSettings = NSLocalizedString("common.open_settings", value: "打开设置", comment: "打开设置按钮")
        public static let restartApp = NSLocalizedString("common.restart_app", value: "重启应用", comment: "重启应用按钮")
        public static let unknownError = NSLocalizedString("common.unknown_error", value: "未知错误", comment: "未知错误")

        public static func itemCount(_ count: Int) -> String {
            String(format: NSLocalizedString("common.item_count", value: "%d 道题", comment: "题目数量"), count)
        }

        public static func itemCountShort(_ count: Int) -> String {
            String(format: NSLocalizedString("common.item_count_short", value: "%d 题", comment: "题目数量（短格式）"), count)
        }

        // Onboarding
        public static let onboardingSkip = NSLocalizedString("onboarding.skip", value: "跳过", comment: "引导页跳过按钮")
        public static let onboardingPrevious = NSLocalizedString("onboarding.previous", value: "上一页", comment: "引导页上一页按钮")
        public static let onboardingNext = NSLocalizedString("onboarding.next", value: "下一页", comment: "引导页下一页按钮")
        public static let onboardingGetStarted = NSLocalizedString("onboarding.get_started", value: "开始使用", comment: "引导页开始使用按钮")
        public static let onboardingAccessibilityGroup = NSLocalizedString("onboarding.accessibility_group", value: "欢迎引导", comment: "引导页无障碍分组标签")
    }

    // MARK: - Onboarding

    public enum Onboarding {
        public static let pageWelcomeTitle = NSLocalizedString("onboarding.page_welcome_title", value: "欢迎使用 SnapDrill", comment: "引导页欢迎标题")
        public static let pageWelcomeDescription = NSLocalizedString("onboarding.page_welcome_description", value: "智能错题管理，让学习更高效", comment: "引导页欢迎描述")
        public static let pageCaptureTitle = NSLocalizedString("onboarding.page_capture_title", value: "智能拍摄", comment: "引导页拍摄标题")
        public static let pageCaptureDescription = NSLocalizedString("onboarding.page_capture_description", value: "使用相机快速捕捉错题，自动识别文字内容", comment: "引导页拍摄描述")
        public static let pageReviewTitle = NSLocalizedString("onboarding.page_review_title", value: "科学复习", comment: "引导页复习标题")
        public static let pageReviewDescription = NSLocalizedString("onboarding.page_review_description", value: "基于艾宾浩斯遗忘曲线，智能安排复习计划", comment: "引导页复习描述")
        public static let pageExportTitle = NSLocalizedString("onboarding.page_export_title", value: "数据导出", comment: "引导页导出标题")
        public static let pageExportDescription = NSLocalizedString("onboarding.page_export_description", value: "支持导出为 PDF、CSV 等格式，方便分享和打印", comment: "引导页导出描述")
        public static let fieldConfigTitle = NSLocalizedString("onboarding.field_config_title", value: "选择录入字段", comment: "引导页字段配置标题")
        public static let fieldConfigDescription = NSLocalizedString("onboarding.field_config_description", value: "选择录入题目时需要填写的字段，之后可在设置中随时调整", comment: "引导页字段配置描述")
        public static let fieldSubject = NSLocalizedString("onboarding.field_subject", value: "学科", comment: "引导页字段：学科")
        public static let fieldSource = NSLocalizedString("onboarding.field_source", value: "来源", comment: "引导页字段：来源")
        public static let fieldDifficulty = NSLocalizedString("onboarding.field_difficulty", value: "难度", comment: "引导页字段：难度")
        public static let fieldGrade = NSLocalizedString("onboarding.field_grade", value: "年级", comment: "引导页字段：年级")
        public static let fieldAnswer = NSLocalizedString("onboarding.field_answer", value: "答案", comment: "引导页字段：答案")
        public static let dismissTooltip = NSLocalizedString("onboarding.dismiss_tooltip", value: "关闭提示", comment: "关闭功能提示气泡按钮")
        public static let fieldConfigIcon = NSLocalizedString("onboarding.field_config_icon", value: "字段配置", comment: "字段配置图标无障碍标签")
        public static let fieldConfigHeader = NSLocalizedString("onboarding.field_config_header", value: "选择录入字段", comment: "字段配置标题无障碍标签")
    }

    // MARK: - Capture

    public enum Capture {
        public static let title = NSLocalizedString("capture.title", value: "采集", comment: "采集页标题")
        public static let entryMethodTitle = NSLocalizedString("capture.entry_method_title", value: "录入方式", comment: "录入方式标题")
        public static let cameraTitle = NSLocalizedString("capture.camera_title", value: "拍照识题", comment: "拍照识题")
        public static let cameraSubtitle = NSLocalizedString("capture.camera_subtitle", value: "自动裁剪与识别", comment: "拍照副标题")
        public static let albumTitle = NSLocalizedString("capture.album_title", value: "相册导入", comment: "相册导入")
        public static let albumSubtitle = NSLocalizedString("capture.album_subtitle", value: "识别已有照片", comment: "相册副标题")
        public static let manualTitle = NSLocalizedString("capture.manual_title", value: "手动录入", comment: "手动录入")
        public static let manualSubtitle = NSLocalizedString("capture.manual_subtitle", value: "纯文本编辑", comment: "手动录入副标题")
        public static let clipboardTitle = NSLocalizedString("capture.clipboard_title", value: "粘贴板", comment: "粘贴板")
        public static let clipboardSubtitle = NSLocalizedString("capture.clipboard_subtitle", value: "从剪贴板读取", comment: "粘贴板副标题")
        public static let pdfTitle = NSLocalizedString("capture.pdf_title", value: "PDF 导入", comment: "PDF 导入")
        public static let pdfSubtitle = NSLocalizedString("capture.pdf_subtitle", value: "从文件选择 PDF", comment: "PDF 副标题")

        // 草稿恢复
        public static let draftAlertTitle = NSLocalizedString("capture.draft_alert_title", value: "恢复草稿", comment: "草稿恢复弹窗标题")
        public static let draftContinue = NSLocalizedString("capture.draft_continue", value: "继续编辑", comment: "继续编辑草稿")
        public static let draftAlertMessage = NSLocalizedString("capture.draft_alert_message", value: "检测到未保存的采集内容，是否恢复？", comment: "草稿恢复提示")

        // 结果编辑页
        public static let previewAndEdit = NSLocalizedString("capture.preview_and_edit", value: "预览与编辑", comment: "预览与编辑页标题")
        public static let questionContent = NSLocalizedString("capture.question_content", value: "题目内容", comment: "题目内容标签")
        public static let reRecognizing = NSLocalizedString("capture.re_recognizing", value: "正在重新识别...", comment: "重新 OCR 识别中")
        public static let categoryInfo = NSLocalizedString("capture.category_info", value: "分类信息", comment: "分类信息标签")
        public static let questionDetails = NSLocalizedString("capture.question_details", value: "题目详情", comment: "题目详情标签")
        public static let subject = NSLocalizedString("capture.subject", value: "学科", comment: "学科标签")
        public static let source = NSLocalizedString("capture.source", value: "来源", comment: "来源标签")
        public static let tags = NSLocalizedString("capture.tags", value: "标签", comment: "标签标签")
        public static let difficulty = NSLocalizedString("capture.difficulty", value: "难度", comment: "难度标签")
        public static let grade = NSLocalizedString("capture.grade", value: "年级/程度", comment: "年级标签")
        public static let answer = NSLocalizedString("capture.answer", value: "参考答案", comment: "参考答案标签")
        public static let addAnswerImage = NSLocalizedString("capture.add_answer_image", value: "添加答案图片", comment: "添加答案图片")
        public static let saveFailed = NSLocalizedString("capture.save_failed", value: "保存失败", comment: "保存失败弹窗标题")

        // 新建分类弹窗
        public static let newSubject = NSLocalizedString("capture.new_subject", value: "新建学科", comment: "新建学科")
        public static let subjectNamePlaceholder = NSLocalizedString("capture.subject_name_placeholder", value: "学科名称", comment: "学科名称输入占位")
        public static let newSubjectMessage = NSLocalizedString("capture.new_subject_message", value: "输入新学科名称，创建后自动选中", comment: "新建学科提示")
        public static let newSource = NSLocalizedString("capture.new_source", value: "新建来源", comment: "新建来源")
        public static let sourceNamePlaceholder = NSLocalizedString("capture.source_name_placeholder", value: "来源名称", comment: "来源名称输入占位")
        public static let newSourceMessage = NSLocalizedString("capture.new_source_message", value: "输入新来源名称，创建后自动选中", comment: "新建来源提示")
        public static let newGrade = NSLocalizedString("capture.new_grade", value: "新建年级", comment: "新建年级")
        public static let gradeNamePlaceholder = NSLocalizedString("capture.grade_name_placeholder", value: "年级名称", comment: "年级名称输入占位")
        public static let newGradeMessage = NSLocalizedString("capture.new_grade_message", value: "输入新年级名称，创建后自动选中", comment: "新建年级提示")

        // PDF 页面选择
        public static let selectPage = NSLocalizedString("capture.select_page", value: "选择页面", comment: "PDF 页面选择标题")
        public static let loadingPage = NSLocalizedString("capture.loading_page", value: "正在加载...", comment: "正在加载页面")
        public static let recognizingPage = NSLocalizedString("capture.recognizing_page", value: "正在识别...", comment: "正在 OCR 识别")

        public static func pdfPageHint(_ count: Int) -> String {
            String(format: NSLocalizedString("capture.pdf_page_hint", value: "共 %d 页，点击选择要录入的页面", comment: "PDF 页数提示"), count)
        }

        public static func pageNumber(_ number: Int) -> String {
            String(format: NSLocalizedString("capture.page_number", value: "第 %d 页", comment: "第 N 页"), number)
        }

        // PDF 大文件警告
        public static let pdfFileTooLargeTitle = NSLocalizedString(
            "capture.pdf_file_too_large_title", value: "文件较大", comment: "PDF 文件过大警告标题")
        public static let pdfContinueAnyway = NSLocalizedString(
            "capture.pdf_continue_anyway", value: "继续导入", comment: "PDF 文件过大时继续导入按钮")

        /// PDF 文件过大警告内容
        /// - Parameter sizeMB: 文件大小（MB）
        public static func pdfFileTooLarge(_ sizeMB: Int) -> String {
            String(format: NSLocalizedString(
                "capture.pdf_file_too_large", value: "PDF 文件大小为 %d MB，可能导致内存不足，建议使用更小的文件",
                comment: "PDF 文件过大警告内容"), sizeMB)
        }

    }

    // MARK: - Dashboard

    public enum Dashboard {
        public static let title = NSLocalizedString("dashboard.title", value: "首页", comment: "首页 Tab 标题")

        // 空状态
        public static let emptyTitle = NSLocalizedString("dashboard.empty_title", value: "还没有任何题目", comment: "空状态标题")
        public static let emptyDescription = NSLocalizedString("dashboard.empty_description", value: "拍摄一道错题，开始你的间隔复习之旅", comment: "空状态描述")
        public static let goCapture = NSLocalizedString("dashboard.go_capture", value: "去采集", comment: "去采集按钮")

        // Bento 卡片
        public static let smartScan = NSLocalizedString("dashboard.smart_scan", value: "智能扫描", comment: "智能扫描卡片标题")
        public static let addNew = NSLocalizedString("dashboard.add_new", value: "录入新题", comment: "录入新题副标题")
        public static let browseLibrary = NSLocalizedString("dashboard.browse_library", value: "题库浏览", comment: "题库浏览卡片标题")
        public static let manageKnowledge = NSLocalizedString("dashboard.manage_knowledge", value: "管理知识", comment: "管理知识副标题")
        public static let subjectManage = NSLocalizedString("dashboard.subject_manage", value: "科目管理", comment: "科目管理卡片标题")
        public static let customize = NSLocalizedString("dashboard.customize", value: "自定义", comment: "自定义副标题")

        // 每日统计
        public static let todayAdded = NSLocalizedString("dashboard.today_added", value: "今日新增", comment: "今日新增")
        public static let todayReviewed = NSLocalizedString("dashboard.today_reviewed", value: "今日复习", comment: "今日复习")
        public static let dueReview = NSLocalizedString("dashboard.due_review", value: "待复习", comment: "待复习")

        // 草稿恢复
        public static let draftAlertTitle = NSLocalizedString("dashboard.draft_alert_title", value: "恢复未完成的题目？", comment: "Dashboard 草稿恢复弹窗")
        public static let draftStartNew = NSLocalizedString("dashboard.draft_start_new", value: "开始新的", comment: "开始新的按钮")
        public static let draftRestore = NSLocalizedString("dashboard.draft_restore", value: "恢复", comment: "恢复按钮")
        public static let draftAlertMessage = NSLocalizedString("dashboard.draft_alert_message", value: "您有上次未保存的拍摄内容，是否继续编辑？", comment: "Dashboard 草稿恢复提示")

        // Hero 卡片
        public static let welcome = NSLocalizedString("dashboard.welcome", value: "欢迎使用", comment: "欢迎使用")
        public static let welcomeSubtitle = NSLocalizedString("dashboard.welcome_subtitle", value: "添加第一道错题，开启复习之旅", comment: "欢迎副标题")
        public static let captureItem = NSLocalizedString("dashboard.capture_item", value: "录入题目", comment: "录入题目按钮")
        public static let todayDue = NSLocalizedString("dashboard.today_due", value: "今日待复习", comment: "今日待复习")
        public static let startNow = NSLocalizedString("dashboard.start_now", value: "立即开始", comment: "立即开始按钮")
        public static let allDone = NSLocalizedString("dashboard.all_done", value: "太棒了！", comment: "全部完成")
        public static let allDoneSubtitle = NSLocalizedString("dashboard.all_done_subtitle", value: "今日复习任务已清空", comment: "全部完成副标题")

        // 问候语
        public static let defaultName = NSLocalizedString("dashboard.default_name", value: "同学", comment: "默认用户名")
        public static let greetingNight = NSLocalizedString("dashboard.greeting_night", value: "夜深了，注意休息", comment: "夜间问候")

        public static func greetingMorning(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_morning", value: "早安，%@", comment: "早间问候"), name)
        }

        public static func greetingAfternoon(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_afternoon", value: "午安，%@", comment: "午间问候"), name)
        }

        public static func greetingEvening(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_evening", value: "晚上好，%@", comment: "晚间问候"), name)
        }
    }

    // MARK: - Library

    public enum Library {
        public static let title = NSLocalizedString("library.title", value: "题库", comment: "题库标题")
        public static let searchPlaceholder = NSLocalizedString("library.search_placeholder", value: "搜索题目", comment: "搜索占位符")
        public static let noItems = NSLocalizedString("library.no_items", value: "还没有题目", comment: "无题目提示")
        public static let noItemsHint = NSLocalizedString("library.no_items_hint", value: "拍摄或导入题目后将在此处显示", comment: "无题目副提示")
        public static let noSearchResults = NSLocalizedString("library.no_search_results", value: "无结果", comment: "搜索无结果")
        public static let noSearchResultsHint = NSLocalizedString("library.no_search_results_hint", value: "尝试调整搜索词或过滤条件", comment: "搜索无结果提示")

        // 排序
        public static let sortByDate = NSLocalizedString("library.sort_by_date", value: "按时间", comment: "按时间排序")
        public static let sortBySubject = NSLocalizedString("library.sort_by_subject", value: "按学科", comment: "按学科排序")
        public static let sortByDifficulty = NSLocalizedString("library.sort_by_difficulty", value: "按难度", comment: "按难度排序")

        // 列表
        public static let allSubjects = NSLocalizedString("library.all_subjects", value: "全部", comment: "全部学科")
        public static let noContent = NSLocalizedString("library.no_content", value: "无文字内容", comment: "无文字内容占位")

        // 详情
        public static let detail = NSLocalizedString("library.detail", value: "题目详情", comment: "详情页标题")
        public static let questionImage = NSLocalizedString("library.question_image", value: "题目图片", comment: "题目图片标签")
        public static let questionText = NSLocalizedString("library.question_text", value: "题目内容", comment: "题目内容")
        public static let answerSection = NSLocalizedString("library.answer_section", value: "参考答案", comment: "参考答案区")
        public static let answerText = NSLocalizedString("library.answer_text", value: "答案文本", comment: "答案文本")
        public static let answerImage = NSLocalizedString("library.answer_image", value: "答案图片", comment: "答案图片")
        public static let noAnswer = NSLocalizedString("library.no_answer", value: "暂无答案", comment: "暂无答案")
        public static let createdAt = NSLocalizedString("library.created_at", value: "录入时间", comment: "录入时间")
        public static let nextReview = NSLocalizedString("library.next_review", value: "下次复习", comment: "下次复习时间")
        public static let notScheduled = NSLocalizedString("library.not_scheduled", value: "未安排", comment: "未安排复习")

        // 编辑
        public static let editTitle = NSLocalizedString("library.edit_title", value: "编辑题目", comment: "编辑题目页标题")
        public static let editQuestion = NSLocalizedString("library.edit_question", value: "编辑题目", comment: "编辑题目按钮")
        public static let editContent = NSLocalizedString("library.edit_content", value: "编辑内容", comment: "编辑内容按钮")
        public static let noImage = NSLocalizedString("library.no_image", value: "无图片", comment: "无图片占位")
        public static let changeImage = NSLocalizedString("library.change_image", value: "更换图片 & 重新识别", comment: "更换图片")
        public static let removeAnswerImage = NSLocalizedString("library.remove_answer_image", value: "移除答案图片", comment: "移除答案图片")
        public static let addAnswerImage = NSLocalizedString("library.add_answer_image", value: "添加答案图片", comment: "添加答案图片")
        public static let metadata = NSLocalizedString("library.metadata", value: "属性", comment: "属性区标签")

        // 过滤
        public static let filter = NSLocalizedString("library.filter", value: "过滤", comment: "过滤按钮")
        public static let filterSubjects = NSLocalizedString("library.filter_subjects", value: "学科", comment: "过滤学科标签")
        public static let filterTags = NSLocalizedString("library.filter_tags", value: "标签", comment: "过滤标签标签")

        // 导出
        public static let export = NSLocalizedString("library.export", value: "导出", comment: "导出按钮")
        public static let exportTitle = NSLocalizedString("library.export_title", value: "导出选项", comment: "导出选项标题")
        public static let exportPDF = NSLocalizedString("library.export_pdf", value: "PDF / 打印", comment: "PDF 导出")
        public static let exportPDFHint = NSLocalizedString("library.export_pdf_hint", value: "适合打印复习", comment: "PDF 导出提示")
        public static let exportMarkdown = NSLocalizedString("library.export_markdown", value: "Markdown", comment: "Markdown 导出")
        public static let exportMarkdownHint = NSLocalizedString("library.export_markdown_hint", value: "适合笔记软件", comment: "Markdown 提示")
        public static let exportCSV = NSLocalizedString("library.export_csv", value: "CSV", comment: "CSV 导出")
        public static let exportCSVHint = NSLocalizedString("library.export_csv_hint", value: "适合表格处理", comment: "CSV 提示")
        public static let exportPreview = NSLocalizedString("library.export_preview", value: "导出预览", comment: "导出预览页标题")
        public static let shareOrPrint = NSLocalizedString("library.share_or_print", value: "分享 / 打印", comment: "分享或打印")
        public static let generating = NSLocalizedString("library.generating", value: "正在生成...", comment: "正在生成")
        public static let generateFailed = NSLocalizedString("library.generate_failed", value: "生成失败", comment: "生成失败")

        // 批量操作
        public static let selectItems = NSLocalizedString("library.select_items", value: "选择", comment: "选择模式按钮")
        public static let deleteSelected = NSLocalizedString("library.delete_selected", value: "删除", comment: "删除已选")
        public static let exportSelected = NSLocalizedString("library.export_selected", value: "导出", comment: "导出已选")

        // 删除确认
        public static let deleteConfirmTitle = NSLocalizedString("library.delete_confirm_title", value: "确认删除", comment: "删除确认标题")
        public static let deleteConfirmMessage = NSLocalizedString("library.delete_confirm_message", value: "此操作不可撤销，确定要删除选中的题目吗？", comment: "删除确认信息")

        // 分类管理
        public static let subjectManager = NSLocalizedString("library.subject_manager", value: "管理学科", comment: "管理学科")
        public static let sourceManager = NSLocalizedString("library.source_manager", value: "管理来源", comment: "管理来源")
        public static let gradeManager = NSLocalizedString("library.grade_manager", value: "管理年级", comment: "管理年级")
        public static let addSubject = NSLocalizedString("library.add_subject", value: "添加学科", comment: "添加学科")
        public static let editSubject = NSLocalizedString("library.edit_subject", value: "编辑学科", comment: "编辑学科")
        public static let addSource = NSLocalizedString("library.add_source", value: "添加来源", comment: "添加来源")
        public static let editSource = NSLocalizedString("library.edit_source", value: "编辑来源", comment: "编辑来源")
        public static let addGrade = NSLocalizedString("library.add_grade", value: "添加年级", comment: "添加年级")
        public static let editGrade = NSLocalizedString("library.edit_grade", value: "编辑年级", comment: "编辑年级")
        public static let name = NSLocalizedString("library.name", value: "名称", comment: "名称标签")
        public static let icon = NSLocalizedString("library.icon", value: "图标", comment: "图标标签")
        public static let color = NSLocalizedString("library.color", value: "颜色", comment: "颜色标签")
        public static let customColor = NSLocalizedString("library.custom_color", value: "自定义颜色", comment: "自定义颜色")
        public static let namePlaceholder = NSLocalizedString("library.name_placeholder", value: "请输入名称", comment: "名称输入占位")
        public static let cannotDeleteInUse = NSLocalizedString("library.cannot_delete_in_use", value: "无法删除", comment: "无法删除弹窗标题")

        public static func cannotDeleteMessage(_ count: Int) -> String {
            String(format: NSLocalizedString("library.cannot_delete_message", value: "该项正在被 %d 道题使用，请先修改相关题目。", comment: "无法删除提示"), count)
        }

        public static func selectedCount(_ count: Int) -> String {
            String(format: NSLocalizedString("library.selected_count", value: "已选 %d 项", comment: "已选项数"), count)
        }

        // 图标选择器
        public static let iconPicker = NSLocalizedString("library.icon_picker", value: "选择图标", comment: "图标选择器标题")
        public static let iconSearch = NSLocalizedString("library.icon_search", value: "搜索图标", comment: "搜索图标")
        public static let iconManualInput = NSLocalizedString("library.icon_manual_input", value: "手动输入", comment: "手动输入图标名")
        public static let iconManualPlaceholder = NSLocalizedString("library.icon_manual_placeholder", value: "输入 SF Symbol 名称", comment: "手动输入图标占位")

        // 全屏图片
        public static let fullScreenImage = NSLocalizedString("library.full_screen_image", value: "查看图片", comment: "全屏查看图片")

        // 分类管理 — 删除受阻提示
        public static func subjectHasItems(_ name: String) -> String {
            String(format: NSLocalizedString("library.subject_has_items", value: "学科「%@」下仍有题目，请先将题目移动到其他学科或删除对应题目。", comment: "学科删除受阻"), name)
        }
        public static func sourceHasItems(_ name: String) -> String {
            String(format: NSLocalizedString("library.source_has_items", value: "来源「%@」下仍有题目，请先将题目移动到其他来源或删除对应题目。", comment: "来源删除受阻"), name)
        }
        public static func gradeHasItems(_ name: String) -> String {
            String(format: NSLocalizedString("library.grade_has_items", value: "年级「%@」下仍有题目，请先将题目移动到其他年级或删除对应题目。", comment: "年级删除受阻"), name)
        }
    }

    // MARK: - Review

    public enum Review {
        public static let title = NSLocalizedString("review.title", value: "复习", comment: "复习标题")

        // 暂停弹窗
        public static let pauseAlertTitle = NSLocalizedString("review.pause_alert_title", value: "确认暂停复习？", comment: "暂停复习弹窗")
        public static let pauseContinue = NSLocalizedString("review.pause_continue", value: "继续", comment: "继续按钮")
        public static let pauseConfirm = NSLocalizedString("review.pause_confirm", value: "暂停", comment: "暂停按钮")
        public static let pauseMessage = NSLocalizedString("review.pause_message", value: "当前进度将保存，您可以稍后继续。", comment: "暂停提示")

        // 滑动标记
        public static let stampForgot = NSLocalizedString("review.stamp_forgot", value: "忘记", comment: "忘记标记")
        public static let stampRemember = NSLocalizedString("review.stamp_remember", value: "记得", comment: "记得标记")

        // Dashboard
        public static let pending = NSLocalizedString("review.pending", value: "待复习", comment: "待复习")
        public static let completed = NSLocalizedString("review.completed", value: "已完成", comment: "已完成")
        public static let todayReview = NSLocalizedString("review.today_review", value: "今日复习", comment: "今日复习")
        public static let cardsPending = NSLocalizedString("review.cards_pending", value: "张卡片待处理", comment: "张卡片待处理")
        public static let welcomeBack = NSLocalizedString("review.welcome_back", value: "欢迎回来", comment: "欢迎回来")
        public static let emptyHint = NSLocalizedString("review.empty_hint", value: "还没有题目，快去录入吧！", comment: "空状态提示")
        public static let excellent = NSLocalizedString("review.excellent", value: "太棒了！", comment: "太棒了")
        public static let startReview = NSLocalizedString("review.start_review", value: "开始复习", comment: "开始复习按钮")
        public static let goRest = NSLocalizedString("review.go_rest", value: "去休息", comment: "去休息按钮")

        public static func reviewedToday(_ count: Int) -> String {
            String(format: NSLocalizedString("review.reviewed_today", value: "今日已复习 %d 张", comment: "今日已复习张数"), count)
        }

        // 会话摘要
        public static let summaryTitle = NSLocalizedString("review.summary_title", value: "今日复习完成", comment: "复习完成标题")
        public static let summaryGood = NSLocalizedString("review.summary_good", value: "掌握", comment: "掌握")
        public static let summaryAgain = NSLocalizedString("review.summary_again", value: "待加强", comment: "待加强")
        public static let summaryDismiss = NSLocalizedString("review.summary_dismiss", value: "好的", comment: "好的按钮")

        // 鼓励语
        public static let encourageRest = NSLocalizedString("review.encourage_rest", value: "休息一下，明天继续。", comment: "鼓励语-休息")
        public static let encourageAllGood = NSLocalizedString("review.encourage_all_good", value: "全部掌握，太棒了！", comment: "鼓励语-全部掌握")
        public static let encourageKeepGoing = NSLocalizedString("review.encourage_keep_going", value: "别灰心，多复习几次就记住了！", comment: "鼓励语-继续加油")

        public static func encouragePartial(_ count: Int) -> String {
            String(format: NSLocalizedString("review.encourage_partial", value: "继续加油，%d 题稍后会再出现。", comment: "鼓励语-部分掌握"), count)
        }
    }

    // MARK: - Settings

    public enum Settings {
        public static let title = NSLocalizedString("settings.title", value: "设置", comment: "设置标题")

        // 录入字段
        public static let captureFields = NSLocalizedString("settings.capture_fields", value: "录入字段", comment: "录入字段区标题")
        public static let fieldSubject = NSLocalizedString("settings.field_subject", value: "学科", comment: "学科字段")
        public static let fieldSource = NSLocalizedString("settings.field_source", value: "来源", comment: "来源字段")
        public static let fieldDifficulty = NSLocalizedString("settings.field_difficulty", value: "难度", comment: "难度字段")
        public static let fieldGrade = NSLocalizedString("settings.field_grade", value: "年级", comment: "年级字段")
        public static let fieldAnswer = NSLocalizedString("settings.field_answer", value: "答案", comment: "答案字段")

        // 复习设置
        public static let reviewSettings = NSLocalizedString("settings.review_settings", value: "复习设置", comment: "复习设置区标题")
        public static let cardAppearance = NSLocalizedString("settings.card_appearance", value: "卡片外观", comment: "卡片外观")
        public static let reviewReminder = NSLocalizedString("settings.review_reminder", value: "复习提醒", comment: "复习提醒")
        public static let privacyAndExport = NSLocalizedString("settings.privacy_export", value: "隐私与导出", comment: "隐私与导出")

        // 数据与同步
        public static let dataAndSync = NSLocalizedString("settings.data_and_sync", value: "数据与云同步", comment: "数据与云同步")

        // 通用
        public static let general = NSLocalizedString("settings.general", value: "通用", comment: "通用区标题")
        public static let appearance = NSLocalizedString("settings.appearance", value: "外观", comment: "外观")
        public static let followSystem = NSLocalizedString("settings.follow_system", value: "跟随系统", comment: "跟随系统")
        public static let lightMode = NSLocalizedString("settings.light_mode", value: "浅色", comment: "浅色模式")
        public static let darkMode = NSLocalizedString("settings.dark_mode", value: "深色", comment: "深色模式")
        public static let language = NSLocalizedString("settings.language", value: "语言", comment: "语言")
        public static let simplifiedChinese = NSLocalizedString("settings.simplified_chinese", value: "简体中文", comment: "简体中文")

        // 数据管理
        public static let dataManagement = NSLocalizedString("settings.data_management", value: "数据管理", comment: "数据管理区标题")
        public static let manageSubjects = NSLocalizedString("settings.manage_subjects", value: "管理学科", comment: "管理学科")
        public static let manageSources = NSLocalizedString("settings.manage_sources", value: "管理来源", comment: "管理来源")
        public static let manageGrades = NSLocalizedString("settings.manage_grades", value: "管理年级", comment: "管理年级")
        public static let clearAllData = NSLocalizedString("settings.clear_all_data", value: "清空所有数据", comment: "清空所有数据")
        public static let clearConfirmTitle = NSLocalizedString("settings.clear_confirm_title", value: "确认清空所有数据？", comment: "清空确认标题")
        public static let clearConfirmMessage = NSLocalizedString("settings.clear_confirm_message", value: "此操作将删除所有题目、分类和标签，且不可恢复。", comment: "清空确认信息")
        public static let clearConfirmButton = NSLocalizedString("settings.clear_confirm_button", value: "清空所有", comment: "确认清空按钮")

        // 关于
        public static let about = NSLocalizedString("settings.about", value: "关于", comment: "关于区标题")
        public static let version = NSLocalizedString("settings.version", value: "版本", comment: "版本")
        public static let privacyPolicy = NSLocalizedString("settings.privacy_policy", value: "隐私政策", comment: "隐私政策")
        public static let termsOfService = NSLocalizedString("settings.terms_of_service", value: "服务条款", comment: "服务条款")
        public static let licenses = NSLocalizedString("settings.licenses", value: "开源许可", comment: "开源许可")

        // 通知设置
        public static let notificationTitle = NSLocalizedString("settings.notification_title", value: "复习提醒", comment: "通知设置标题")
        public static let dailyReminder = NSLocalizedString("settings.daily_reminder", value: "每日复习提醒", comment: "每日复习提醒")
        public static let reminderTime = NSLocalizedString("settings.reminder_time", value: "提醒时间", comment: "提醒时间")
        public static let reminderSound = NSLocalizedString("settings.reminder_sound", value: "提醒声音", comment: "提醒声音")
        public static let reminderBadge = NSLocalizedString("settings.reminder_badge", value: "图标标记", comment: "图标标记")
        public static let notificationDenied = NSLocalizedString("settings.notification_denied", value: "通知权限未开启", comment: "通知权限弹窗标题")
        public static let notificationDeniedMessage = NSLocalizedString("settings.notification_denied_message", value: "请在 iPhone 设置中开启 SnapDrill 的通知权限。", comment: "通知权限提示")
        public static let goToSettings = NSLocalizedString("settings.go_to_settings", value: "前往设置", comment: "前往设置按钮")

        // 语言设置
        public static let languageTitle = NSLocalizedString("settings.language_title", value: "语言设置", comment: "语言设置页标题")
        public static let languageHint = NSLocalizedString("settings.language_hint", value: "应用语言跟随系统设置。如需更改，请在 iPhone 的「设置 > 通用 > 语言与地区」中调整。", comment: "语言设置提示")
        public static let openSystemSettings = NSLocalizedString("settings.open_system_settings", value: "打开系统设置", comment: "打开系统设置")
        public static let currentLanguage = NSLocalizedString("settings.current_language", value: "当前语言", comment: "当前语言")

        public static let backup = NSLocalizedString("settings.backup", value: "备份与恢复", comment: "备份与恢复区标题")
        public static let createBackup = NSLocalizedString("settings.create_backup", value: "创建备份", comment: "创建备份")
        public static let restoreBackup = NSLocalizedString("settings.restore_backup", value: "恢复备份", comment: "恢复备份")
        public static let backupHint = NSLocalizedString("settings.backup_hint", value: "备份文件包含所有题目和分类数据", comment: "备份说明")
        public static let restoreConfirmTitle = NSLocalizedString("settings.restore_confirm_title", value: "确认恢复？", comment: "恢复确认标题")
        public static let restoreConfirmMessage = NSLocalizedString("settings.restore_confirm_message", value: "恢复将覆盖当前所有数据，恢复前会自动创建备份。", comment: "恢复确认信息")
        public static let restoreConfirmButton = NSLocalizedString("settings.restore_confirm_button", value: "恢复", comment: "确认恢复按钮")
        public static let localDataWarning = NSLocalizedString("settings.local_data_warning", value: "数据仅存储在本设备，卸载应用将丢失所有数据。建议定期创建备份。", comment: "本地数据警告")

        // 隐私设置
        public static let privacyTitle = NSLocalizedString("settings.privacy_title", value: "隐私与数据导出", comment: "隐私设置标题")
        public static let analyticsEnabled = NSLocalizedString("settings.analytics_enabled", value: "匿名使用统计", comment: "匿名使用统计")
        public static let analyticsHint = NSLocalizedString("settings.analytics_hint", value: "帮助我们改进应用体验，不收集任何个人信息。", comment: "匿名统计说明")
        public static let crashReporting = NSLocalizedString("settings.crash_reporting", value: "崩溃报告", comment: "崩溃报告")
        public static let crashReportingHint = NSLocalizedString("settings.crash_reporting_hint", value: "自动发送匿名崩溃信息，帮助修复问题。", comment: "崩溃报告说明")
        public static let dataExport = NSLocalizedString("settings.data_export", value: "数据导出", comment: "数据导出区标题")
        public static let exportJSON = NSLocalizedString("settings.export_json", value: "导出为 JSON", comment: "JSON 导出")
        public static let exportCSV = NSLocalizedString("settings.export_csv", value: "导出为 CSV", comment: "CSV 导出")
        public static let exportHint = NSLocalizedString("settings.export_hint", value: "导出所有题目数据，可用于数据迁移或备份。", comment: "导出说明")

        // 卡片外观
        public static let cardAppearanceTitle = NSLocalizedString("settings.card_appearance_title", value: "卡片外观", comment: "卡片外观设置标题")
        public static let cardFront = NSLocalizedString("settings.card_front", value: "正面（题目）", comment: "正面区标签")
        public static let cardBack = NSLocalizedString("settings.card_back", value: "背面（答案 Header）", comment: "背面区标签")
        public static let textAlignment = NSLocalizedString("settings.text_alignment", value: "文字对齐", comment: "文字对齐")
        public static let alignLeft = NSLocalizedString("settings.align_left", value: "左对齐", comment: "左对齐")
        public static let alignCenter = NSLocalizedString("settings.align_center", value: "居中", comment: "居中")
        public static let alignRight = NSLocalizedString("settings.align_right", value: "右对齐", comment: "右对齐")
        public static let fontSize = NSLocalizedString("settings.font_size", value: "字体大小", comment: "字体大小")
        public static let previewText = NSLocalizedString("settings.preview_text", value: "预览效果文字", comment: "预览效果文字")

        // 个人资料
        public static let editProfile = NSLocalizedString("settings.edit_profile", value: "个人资料", comment: "个人资料")
        public static let nickname = NSLocalizedString("settings.nickname", value: "昵称", comment: "昵称")
        public static let nicknamePlaceholder = NSLocalizedString("settings.nickname_placeholder", value: "请输入昵称", comment: "昵称输入占位")
        public static let dailyGoal = NSLocalizedString("settings.daily_goal", value: "每日复习目标", comment: "每日复习目标")
        public static let cardsUnit = NSLocalizedString("settings.cards_unit", value: "张", comment: "张（单位）")
        public static let motto = NSLocalizedString("settings.motto", value: "学习座右铭", comment: "学习座右铭")
        public static let mottoPlaceholder = NSLocalizedString("settings.motto_placeholder", value: "写一句话激励自己...", comment: "座右铭输入占位")
        public static let mottoFooter = NSLocalizedString("settings.motto_footer", value: "座右铭将显示在个人资料中", comment: "座右铭说明")
        public static let themeColor = NSLocalizedString("settings.theme_color", value: "图标主题色", comment: "图标主题色")
        public static let avatarSource = NSLocalizedString("settings.avatar_source", value: "选择头像来源", comment: "选择头像来源")
        public static let fromPhotoLibrary = NSLocalizedString("settings.from_photo_library", value: "从相册选择", comment: "从相册选择")
        public static let systemIcon = NSLocalizedString("settings.system_icon", value: "使用系统图标", comment: "使用系统图标")
        public static let removeAvatar = NSLocalizedString("settings.remove_avatar", value: "移除当前头像", comment: "移除当前头像")

        // 反馈
        public static let feedbackAndSupport = NSLocalizedString("settings.feedback_and_support", value: "反馈与支持", comment: "反馈与支持")
        public static let feedbackTitle = NSLocalizedString("settings.feedback_title", value: "意见反馈", comment: "意见反馈弹窗标题")
        public static let copyEmail = NSLocalizedString("settings.copy_email", value: "复制邮箱", comment: "复制邮箱按钮")
        public static let maybeLater = NSLocalizedString("settings.maybe_later", value: "以后再说", comment: "以后再说按钮")
        public static let feedbackMessage = NSLocalizedString("settings.feedback_message", value: "感谢您使用 SnapDrill！您可以发送邮件至 hello@notbadhq.com，或直接在 TestFlight 中反馈。", comment: "反馈提示信息")
        public static let editProfileSubtitle = NSLocalizedString("settings.edit_profile_subtitle", value: "编辑个人资料", comment: "编辑个人资料副标题")

        public static let backupData = NSLocalizedString("settings.backup_data", value: "备份数据", comment: "备份数据按钮")
        public static let restoreData = NSLocalizedString("settings.restore_data", value: "恢复数据", comment: "恢复数据按钮")
        public static let backupFooter = NSLocalizedString("settings.backup_footer", value: "备份文件包含所有题目、分类设置和图片。恢复操作将替换当前全部数据。", comment: "备份说明")
        public static let restoreDialogTitle = NSLocalizedString("settings.restore_dialog_title", value: "恢复数据", comment: "恢复数据对话框标题")
        public static let selectBackupFile = NSLocalizedString("settings.select_backup_file", value: "选择备份文件", comment: "选择备份文件按钮")
        public static let restoreDialogMessage = NSLocalizedString("settings.restore_dialog_message", value: "恢复将替换当前所有数据，此操作不可撤销。恢复前会自动备份当前数据到临时目录。", comment: "恢复对话框提示")
        public static let operationFailed = NSLocalizedString("settings.operation_failed", value: "操作失败", comment: "操作失败弹窗标题")
        public static let unknownError = NSLocalizedString("settings.unknown_error", value: "未知错误", comment: "未知错误")
        public static let restoreSuccess = NSLocalizedString("settings.restore_success", value: "恢复成功", comment: "恢复成功弹窗标题")

        // 存储空间
        public static let storageSpace = NSLocalizedString("settings.storage_space", value: "存储空间", comment: "存储空间区标题")
        public static let mediaCacheUsage = NSLocalizedString("settings.media_cache_usage", value: "媒体缓存占用", comment: "媒体缓存占用")
        public static let calculating = NSLocalizedString("settings.calculating", value: "计算中...", comment: "计算中")
        public static let clearCache = NSLocalizedString("settings.clear_cache", value: "清理缓存", comment: "清理缓存按钮")
        public static let clearCacheTitle = NSLocalizedString("settings.clear_cache_title", value: "清理缓存", comment: "清理缓存弹窗标题")
        public static let clearCacheAction = NSLocalizedString("settings.clear_cache_action", value: "清理", comment: "清理按钮")
        public static let clearCacheMessage = NSLocalizedString("settings.clear_cache_message", value: "清理缓存不会删除您的题目数据，仅删除临时图片和下载的资源。", comment: "清理缓存提示")

        // 数据维护
        public static let dataMaintenance = NSLocalizedString("settings.data_maintenance", value: "数据维护", comment: "数据维护区标题")
        public static let autoArchiveOldItems = NSLocalizedString("settings.auto_archive_old_items", value: "自动归档旧题目", comment: "自动归档旧题目")
        public static let archiveTime = NSLocalizedString("settings.archive_time", value: "归档时间", comment: "归档时间")
        public static let daysAgo30 = NSLocalizedString("settings.days_ago_30", value: "30 天前", comment: "30 天前")
        public static let daysAgo60 = NSLocalizedString("settings.days_ago_60", value: "60 天前", comment: "60 天前")
        public static let daysAgo90 = NSLocalizedString("settings.days_ago_90", value: "90 天前", comment: "90 天前")
        public static let daysAgo180 = NSLocalizedString("settings.days_ago_180", value: "180 天前", comment: "180 天前")
        public static let dataMaintenanceFooter = NSLocalizedString("settings.data_maintenance_footer", value: "自动归档长期未复习的题目，保持题库轻量化。归档后的题目仍可搜索但不会自动安排复习。", comment: "数据维护说明")

        // 通知设置详情
        public static let enableDailyReminder = NSLocalizedString("settings.enable_daily_reminder", value: "启用每日复习提醒", comment: "启用每日复习提醒")
        public static let dailyReminderSection = NSLocalizedString("settings.daily_reminder_section", value: "每日提醒", comment: "每日提醒区标题")
        public static let notificationStyle = NSLocalizedString("settings.notification_style", value: "通知样式", comment: "通知样式区标题")
        public static let sound = NSLocalizedString("settings.sound", value: "声音", comment: "声音")
        public static let badge = NSLocalizedString("settings.badge", value: "角标", comment: "角标")
        public static let notificationStyleFooter = NSLocalizedString("settings.notification_style_footer", value: "声音和角标设置在下次触发通知时生效", comment: "通知样式说明")
        public static let notificationAndReminder = NSLocalizedString("settings.notification_and_reminder", value: "通知与提醒", comment: "通知与提醒页标题")
        public static let permissionDeniedTitle = NSLocalizedString("settings.permission_denied_title", value: "通知权限被拒绝", comment: "通知权限被拒绝弹窗标题")
        public static let permissionDeniedMessage = NSLocalizedString("settings.permission_denied_message", value: "请在「设置 → 通知 → SnapDrill」中开启通知权限，才能接收每日复习提醒。", comment: "通知权限被拒绝说明")
        public static let rescheduleFailedTitle = NSLocalizedString("settings.reschedule_failed_title", value: "更新提醒时间失败", comment: "更新提醒时间失败")
        public static let rescheduleFailedMessage = NSLocalizedString("settings.reschedule_failed_message", value: "无法设置提醒时间，请稍后重试", comment: "更新提醒时间失败说明")

        public static func reminderEnabledFooter(_ hour: Int, _ minute: String) -> String {
            String(format: NSLocalizedString("settings.reminder_enabled_footer", value: "将在每天 %d:%@ 提醒你复习今日题目", comment: "提醒已开启说明"), hour, minute)
        }

        public static let reminderDisabledFooter = NSLocalizedString("settings.reminder_disabled_footer", value: "开启后系统将在固定时间推送复习提醒", comment: "提醒未开启说明")

        // 隐私设置详情
        public static let dataCollection = NSLocalizedString("settings.data_collection", value: "数据收集", comment: "数据收集区标题")
        public static let useAnalytics = NSLocalizedString("settings.use_analytics", value: "使用数据分析", comment: "使用数据分析")
        public static let dataCollectionFooter = NSLocalizedString("settings.data_collection_footer", value: "帮助我们改进应用体验，您的数据将被匿名处理", comment: "数据收集说明")
        public static let exportMyData = NSLocalizedString("settings.export_my_data", value: "导出我的数据", comment: "导出我的数据")
        public static let exporting = NSLocalizedString("settings.exporting", value: "导出中...", comment: "导出中")
        public static let chooseExportFormat = NSLocalizedString("settings.choose_export_format", value: "选择导出格式", comment: "选择导出格式")
        public static let jsonFormat = NSLocalizedString("settings.json_format", value: "JSON 格式", comment: "JSON 格式")
        public static let csvFormat = NSLocalizedString("settings.csv_format", value: "CSV 格式", comment: "CSV 格式")
        public static let exportDataFooter = NSLocalizedString("settings.export_data_footer", value: "导出所有学习数据为 JSON 或 CSV 格式", comment: "导出数据说明")
        public static let privacyAndSecurity = NSLocalizedString("settings.privacy_and_security", value: "隐私与安全", comment: "隐私与安全页标题")

        public static func exportFailed(_ message: String) -> String {
            String(format: NSLocalizedString("settings.export_failed", value: "导出失败: %@", comment: "导出失败"), message)
        }

        // 语言设置详情
        public static let languageControlledBySystem = NSLocalizedString("settings.language_controlled_by_system", value: "语言由 iOS 系统控制", comment: "语言由系统控制")
        public static let languageSystemHint = NSLocalizedString("settings.language_system_hint", value: "在系统设置中为 SnapDrill 单独指定语言。", comment: "语言系统设置提示")
        public static let languageFooter = NSLocalizedString("settings.language_footer", value: "前往「设置 → SnapDrill → 语言」，选择偏好语言后重新启动应用即可生效。目前支持简体中文，更多语言持续开发中。", comment: "语言设置说明")

        // 卡片外观详情
        public static let cardFrontSection = NSLocalizedString("settings.card_front_section", value: "卡片正面 (题目)", comment: "卡片正面区标题")
        public static let cardBackSection = NSLocalizedString("settings.card_back_section", value: "卡片背面 (Header)", comment: "卡片背面区标题")
        public static let alignment = NSLocalizedString("settings.alignment", value: "对齐方式", comment: "对齐方式")

        public static func fontSizeLabel(_ size: Int) -> String {
            String(format: NSLocalizedString("settings.font_size_label", value: "字体大小: %d", comment: "字体大小标签"), size)
        }

        // DEBUG
        public static let debugTitle = NSLocalizedString("settings.debug_title", value: "开发调试", comment: "开发调试区标题")
        public static let generateMockData = NSLocalizedString("settings.generate_mock_data", value: "生成模拟数据", comment: "生成模拟数据")
        public static let clearMockData = NSLocalizedString("settings.clear_mock_data", value: "清空模拟数据", comment: "清空模拟数据")
        public static let generating = NSLocalizedString("settings.generating", value: "生成中...", comment: "生成中")

        public static func generateTestData(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.generate_test_data", value: "生成测试数据 (%d条)", comment: "生成测试数据按钮"), count)
        }
    }

    // MARK: - EditProfile

    public enum EditProfile {
        public static let title = NSLocalizedString("edit_profile.title", value: "个人资料", comment: "个人资料页标题")
        public static let setAvatar = NSLocalizedString("edit_profile.set_avatar", value: "设置头像", comment: "设置头像按钮")
        public static let nickname = NSLocalizedString("edit_profile.nickname", value: "昵称", comment: "昵称标签")
        public static let nicknamePlaceholder = NSLocalizedString("edit_profile.nickname_placeholder", value: "请输入昵称", comment: "昵称占位符")
        public static let dailyGoal = NSLocalizedString("edit_profile.daily_goal", value: "每日目标", comment: "每日目标标签")
        public static let cardsCount = NSLocalizedString("edit_profile.cards_count", value: "张题目", comment: "张题目单位")
        public static let motto = NSLocalizedString("edit_profile.motto", value: "学习座右铭", comment: "座右铭标签")
        public static let mottoPlaceholder = NSLocalizedString("edit_profile.motto_placeholder", value: "写一句话激励自己...", comment: "座右铭占位符")
        public static let mottoFooter = NSLocalizedString("edit_profile.motto_footer", value: "这句话会显示在首页，每次打开都能看到", comment: "座右铭底部说明")
        public static let themeColor = NSLocalizedString("edit_profile.theme_color", value: "图标主题色", comment: "主题色标签")
        public static let fromPhotoLibrary = NSLocalizedString("edit_profile.from_photo_library", value: "从相册选择", comment: "从相册选择按钮")
        public static let systemIcon = NSLocalizedString("edit_profile.system_icon", value: "使用系统图标", comment: "系统图标按钮")
        public static let removeAvatar = NSLocalizedString("edit_profile.remove_avatar", value: "移除当前头像", comment: "移除头像按钮")
        public static let chooseAvatarSource = NSLocalizedString("edit_profile.choose_avatar_source", value: "选择头像来源", comment: "头像来源选择")
    }

    // MARK: - Errors

    public enum Errors {
        public static let cameraPermissionDenied = NSLocalizedString("errors.camera_permission_denied", value: "相机权限被拒绝", comment: "相机权限错误")
        public static let photoPermissionDenied = NSLocalizedString("errors.photo_permission_denied", value: "相册权限被拒绝", comment: "相册权限错误")
        public static let ocrFailed = NSLocalizedString("errors.ocr_failed", value: "文字识别失败", comment: "OCR 识别失败错误")
        public static let exportFailed = NSLocalizedString("errors.export_failed", value: "导出失败，请稍后重试", comment: "导出失败错误")
        public static let importFailed = NSLocalizedString("errors.import_failed", value: "导入失败", comment: "导入失败错误")
        public static let dataCorrupted = NSLocalizedString("errors.data_corrupted", value: "数据损坏", comment: "数据损坏错误")
        public static let encodingFailed = NSLocalizedString("errors.encoding_failed", value: "数据编码失败", comment: "数据编码失败错误")

        // 采集模块
        public static let imageLoadFailed = NSLocalizedString("errors.image_load_failed", value: "无法加载图片，请确认图片文件未损坏后重试", comment: "图片加载失败")
        public static let imageDecodeFailed = NSLocalizedString("errors.image_decode_failed", value: "图片格式无法识别，请尝试使用其他图片", comment: "图片解码失败")
        public static let clipboardEmpty = NSLocalizedString("errors.clipboard_empty", value: "剪贴板为空或没有可用的文本内容", comment: "剪贴板为空")
        public static let pdfReadFailed = NSLocalizedString("errors.pdf_read_failed", value: "无法读取 PDF 文件，请确认文件未损坏", comment: "PDF 读取失败")
        public static let pdfParseFailed = NSLocalizedString("errors.pdf_parse_failed", value: "PDF 文件格式无法解析，请尝试其他文件", comment: "PDF 解析失败")
        public static let pdfEmpty = NSLocalizedString("errors.pdf_empty", value: "PDF 文件不包含任何页面", comment: "PDF 为空")
        public static let filePickerFailed = NSLocalizedString("errors.file_picker_failed", value: "文件选择失败，请检查文件或稍后重试", comment: "文件选择器错误")

        // 保存模块
        public static let saveFailed = NSLocalizedString("errors.save_failed", value: "保存失败，请检查存储空间后重试", comment: "题目保存失败")
        public static func createTaxonomyFailed(_ name: String) -> String {
            String(format: NSLocalizedString("errors.create_taxonomy_failed", value: "新建「%@」失败，请重试", comment: "分类创建失败"), name)
        }

        // 备份恢复
        public static let backupFailed = NSLocalizedString("errors.backup_failed", value: "备份失败，请检查存储空间后重试", comment: "备份失败")
        public static let restoreFailed = NSLocalizedString("errors.restore_failed", value: "恢复失败，请确认备份文件未损坏后重试", comment: "恢复失败")
        public static let fileAccessDenied = NSLocalizedString("errors.file_access_denied", value: "无法访问选择的文件，请重新选取", comment: "文件访问被拒绝")
    }

    // MARK: - Subjects (预设学科)

    public enum Subjects {
        public static let math = NSLocalizedString("subjects.math", value: "数学", comment: "数学")
        public static let chinese = NSLocalizedString("subjects.chinese", value: "语文", comment: "语文")
        public static let english = NSLocalizedString("subjects.english", value: "英语", comment: "英语")
        public static let physics = NSLocalizedString("subjects.physics", value: "物理", comment: "物理")
        public static let chemistry = NSLocalizedString("subjects.chemistry", value: "化学", comment: "化学")
        public static let biology = NSLocalizedString("subjects.biology", value: "生物", comment: "生物")
        public static let history = NSLocalizedString("subjects.history", value: "历史", comment: "历史")
        public static let geography = NSLocalizedString("subjects.geography", value: "地理", comment: "地理")
        public static let politics = NSLocalizedString("subjects.politics", value: "政治", comment: "政治")
        public static let other = NSLocalizedString("subjects.other", value: "其他", comment: "其他")
    }

    // MARK: - Difficulty

    public enum Difficulty {
        public static let veryEasy = NSLocalizedString("difficulty.very_easy", value: "非常简单", comment: "非常简单")
        public static let easy = NSLocalizedString("difficulty.easy", value: "简单", comment: "简单")
        public static let medium = NSLocalizedString("difficulty.medium", value: "中等", comment: "中等")
        public static let hard = NSLocalizedString("difficulty.hard", value: "困难", comment: "困难")
        public static let veryHard = NSLocalizedString("difficulty.very_hard", value: "非常困难", comment: "非常困难")

        public static func text(for level: Int) -> String {
            switch level {
            case 1: return veryEasy
            case 2: return easy
            case 3: return medium
            case 4: return hard
            case 5: return veryHard
            default: return medium
            }
        }
    }

    // MARK: - Export

    public enum Export {
        public static let title = NSLocalizedString("export.title", value: "导出", comment: "导出标题")
        public static let pdf = NSLocalizedString("export.pdf", value: "PDF格式", comment: "PDF格式")
        public static let csv = NSLocalizedString("export.csv", value: "CSV格式", comment: "CSV格式")
        public static let json = NSLocalizedString("export.json", value: "JSON格式", comment: "JSON格式")
        public static let exporting = NSLocalizedString("export.exporting", value: "导出中", comment: "导出中")
        public static let success = NSLocalizedString("export.success", value: "导出成功", comment: "导出成功")
        public static let failed = NSLocalizedString("export.failed", value: "导出失败", comment: "导出失败")
    }

    // MARK: - TermsOfService

    public enum TermsOfService {
        public static let title = NSLocalizedString("terms.title", value: "用户协议", comment: "用户协议标题")
        public static let lastUpdated = NSLocalizedString("terms.last_updated", value: "最后更新日期：2026年1月2日", comment: "最后更新日期")
        public static let acceptanceTitle = NSLocalizedString("terms.acceptance_title", value: "接受条款", comment: "章节标题：接受条款")
        public static let acceptanceContent = NSLocalizedString(
            "terms.acceptance_content",
            value: "欢迎使用 SnapDrill！通过下载、安装或使用本应用，您同意遵守本用户协议的所有条款和条件。如果您不同意这些条款，请不要使用本应用。",
            comment: "接受条款内容"
        )
        public static let serviceTitle = NSLocalizedString("terms.service_title", value: "服务描述", comment: "章节标题：服务描述")
        public static let serviceContent = NSLocalizedString(
            "terms.service_content",
            value: """
            SnapDrill 是一款个人学习助手应用，旨在帮助用户通过间隔重复技术来采集、组织和复习知识。

            主要功能包括：
            • 智能扫描与 OCR 文字识别
            • 错题管理和分类
            • 间隔重复复习系统
            • 数据导出（PDF/JSON/CSV）
            """,
            comment: "服务描述内容"
        )
        public static let dataStorageTitle = NSLocalizedString("terms.data_storage_title", value: "数据存储", comment: "章节标题：数据存储")
        public static let dataStorageContent = NSLocalizedString(
            "terms.data_storage_content",
            value: """
            SnapDrill 无需创建账户即可使用，所有数据默认存储在您的设备本地。

            您有责任：
            • 保护您的设备安全
            • 定期备份重要数据
            • 注意：卸载应用将永久删除所有本地数据
            """,
            comment: "数据存储内容"
        )
        public static let licenseTitle = NSLocalizedString("terms.license_title", value: "许可授权", comment: "章节标题：许可授权")
        public static let licenseContent = NSLocalizedString(
            "terms.license_content",
            value: """
            我们授予您有限的、非独占的、不可转让的、可撤销的许可，允许您在个人设备上使用 SnapDrill 应用。

            您不得：
            • 复制、修改或反编译应用
            • 出售、出租或转让应用
            • 移除任何版权或所有权声明
            • 将应用用于非法目的
            """,
            comment: "许可授权内容"
        )
        public static let userContentTitle = NSLocalizedString("terms.user_content_title", value: "用户内容", comment: "章节标题：用户内容")
        public static let userContentContent = NSLocalizedString(
            "terms.user_content_content",
            value: """
            您在应用中创建的所有内容（包括文本、图片、笔记等）归您所有。

            您声明并保证：
            • 您拥有上传内容的所有权或必要权利
            • 您的内容不侵犯任何第三方的权利
            • 您的内容不包含非法、有害或不当的材料

            我们不会访问、使用或分享您的个人学习内容。
            """,
            comment: "用户内容"
        )
        public static let ipTitle = NSLocalizedString("terms.ip_title", value: "知识产权", comment: "章节标题：知识产权")
        public static let ipContent = NSLocalizedString(
            "terms.ip_content",
            value: """
            SnapDrill 应用及其所有内容、功能和特性（包括但不限于软件、文本、图形、标识、图标、图像）均由 NotBad Labs L.L.C. 拥有，受美国及国际版权、商标和其他知识产权法律保护。

            "SnapDrill" 名称和标识是 NotBad Labs L.L.C. 的商标。未经我们事先书面许可，您不得使用这些商标。
            """,
            comment: "知识产权内容"
        )
        public static let disclaimerTitle = NSLocalizedString("terms.disclaimer_title", value: "免责声明", comment: "章节标题：免责声明")
        public static let disclaimerContent = NSLocalizedString(
            "terms.disclaimer_content",
            value: """
            SnapDrill 应用按"现状"和"可用"基础提供，不提供任何明示或暗示的保证。

            我们不保证：
            • 应用将无错误或不间断运行
            • 缺陷将被纠正
            • 应用将满足您的特定需求
            • OCR 识别的准确性

            您使用本应用的风险由您自行承担。
            """,
            comment: "免责声明内容"
        )
        public static let liabilityTitle = NSLocalizedString("terms.liability_title", value: "责任限制", comment: "章节标题：责任限制")
        public static let liabilityContent = NSLocalizedString(
            "terms.liability_content",
            value: """
            在法律允许的最大范围内，NotBad Labs L.L.C. 及其关联方不对以下情况承担责任：

            • 任何间接、偶然、特殊或后果性损害
            • 数据丢失或损坏
            • 业务中断或利润损失
            • 因使用或无法使用应用而产生的任何损害

            建议您定期备份重要数据。
            """,
            comment: "责任限制内容"
        )
        public static let backupTitle = NSLocalizedString("terms.backup_title", value: "数据备份", comment: "章节标题：数据备份")
        public static let backupContent = NSLocalizedString(
            "terms.backup_content",
            value: """
            虽然我们努力确保数据的安全性和可靠性，但我们强烈建议您：

            • 定期通过应用内的备份功能导出数据
            • 保留重要内容的副本

            我们不对数据丢失承担责任。
            """,
            comment: "数据备份内容"
        )
        public static let changesTitle = NSLocalizedString("terms.changes_title", value: "服务变更和终止", comment: "章节标题：服务变更和终止")
        public static let changesContent = NSLocalizedString(
            "terms.changes_content",
            value: """
            我们保留随时修改、暂停或终止应用或其任何功能的权利，无需事先通知。

            我们可能会：
            • 更新应用功能
            • 修复 bug 和安全漏洞
            • 改进用户体验

            您可以随时停止使用应用并删除它。
            """,
            comment: "服务变更和终止内容"
        )
        public static let thirdPartyTitle = NSLocalizedString("terms.third_party_title", value: "第三方链接", comment: "章节标题：第三方链接")
        public static let thirdPartyContent = NSLocalizedString(
            "terms.third_party_content",
            value: "应用可能包含指向第三方网站或服务的链接。我们不对这些第三方网站的内容、隐私政策或做法负责。访问第三方链接的风险由您自行承担。",
            comment: "第三方链接内容"
        )
        public static let lawTitle = NSLocalizedString("terms.law_title", value: "适用法律", comment: "章节标题：适用法律")
        public static let lawContent = NSLocalizedString(
            "terms.law_content",
            value: "本协议受美国怀俄明州法律管辖并按其解释，不考虑法律冲突原则。因本协议引起的任何争议，双方应首先通过友好协商解决。如协商不成，双方同意提交至怀俄明州有管辖权的法院解决。",
            comment: "适用法律内容"
        )
        public static let modificationTitle = NSLocalizedString("terms.modification_title", value: "协议修改", comment: "章节标题：协议修改")
        public static let modificationContent = NSLocalizedString(
            "terms.modification_content",
            value: """
            我们保留随时修改本用户协议的权利。如有重大变更，我们将通过应用内通知或更新日期告知您。

            修改后继续使用应用即表示您接受修改后的条款。如果您不同意修改后的条款，请停止使用应用。
            """,
            comment: "协议修改内容"
        )
        public static let severabilityTitle = NSLocalizedString("terms.severability_title", value: "可分割性", comment: "章节标题：可分割性")
        public static let severabilityContent = NSLocalizedString(
            "terms.severability_content",
            value: "如果本协议的任何条款被认定为无效或不可执行，该条款将被删除，其余条款将继续有效。",
            comment: "可分割性内容"
        )
        public static let entireAgreementTitle = NSLocalizedString("terms.entire_agreement_title", value: "完整协议", comment: "章节标题：完整协议")
        public static let entireAgreementContent = NSLocalizedString(
            "terms.entire_agreement_content",
            value: "本用户协议构成您与 NotBad Labs L.L.C. 之间关于使用本应用的完整协议，并取代之前的所有口头或书面协议。",
            comment: "完整协议内容"
        )
        public static let contactTitle = NSLocalizedString("terms.contact_title", value: "联系我们", comment: "章节标题：联系我们")
        public static let contactContent = NSLocalizedString(
            "terms.contact_content",
            value: """
            如果您对本用户协议有任何疑问，请通过以下方式联系我们：

            邮箱：hello@notbadhq.com
            应用内反馈：设置 → 关于 → 反馈与支持

            我们将在 48 小时内回复您的询问。
            """,
            comment: "联系我们内容"
        )
    }

    // MARK: - PrivacyPolicy

    public enum PrivacyPolicy {
        public static let title = NSLocalizedString("privacy.title", value: "隐私政策", comment: "隐私政策标题")
        public static let lastUpdated = NSLocalizedString("privacy.last_updated", value: "最后更新日期：2026年3月", comment: "最后更新日期")
        public static let introTitle = NSLocalizedString("privacy.intro_title", value: "引言", comment: "章节标题：引言")
        public static let introContent = NSLocalizedString(
            "privacy.intro_content",
            value: "欢迎使用 SnapDrill！我们非常重视您的隐私。本隐私政策说明了我们如何收集、使用、存储和保护您的个人信息。使用 SnapDrill 应用即表示您同意本隐私政策中描述的做法。",
            comment: "引言内容"
        )
        public static let collectionTitle = NSLocalizedString("privacy.collection_title", value: "我们收集的信息", comment: "章节标题：信息收集")
        public static let collectionContent = NSLocalizedString(
            "privacy.collection_content",
            value: """
            SnapDrill 是一款完全离线优先的应用，我们不会主动收集您的个人信息。您在应用中创建的所有数据（包括错题内容、图片、笔记等）都存储在您的设备上。

            您创建的内容：错题文本、上传或拍摄的图片、学科分类和标签、复习记录和进度。

            自动收集的信息：应用崩溃日志（仅用于改进应用稳定性）、设备类型和操作系统版本（用于兼容性测试）。
            """,
            comment: "信息收集内容"
        )
        public static let icloudTitle = NSLocalizedString("privacy.icloud_title", value: "iCloud 同步（未来功能）", comment: "章节标题：iCloud 同步")
        public static let icloudContent = NSLocalizedString(
            "privacy.icloud_content",
            value: """
            iCloud 同步是计划中的 Pro 付费功能，当前版本尚未提供。未来启用后：

            您的数据将通过 Apple 的 iCloud 服务在您的设备之间同步。所有数据都存储在您的个人 iCloud 账户中，我们无法访问您的 iCloud 数据。数据传输由 Apple 加密保护。您可以随时在设置中关闭 iCloud 同步。
            """,
            comment: "iCloud 同步内容"
        )
        public static let usageTitle = NSLocalizedString("privacy.usage_title", value: "数据使用", comment: "章节标题：数据使用")
        public static let usageContent = NSLocalizedString(
            "privacy.usage_content",
            value: """
            我们使用收集的信息仅用于：提供核心功能（存储和管理您的错题数据）、改进应用（分析崩溃日志以修复 bug）、用户支持（回应您的反馈和技术支持请求）。

            我们不会：出售您的个人信息、将您的数据用于广告目的、与第三方共享您的学习内容。
            """,
            comment: "数据使用内容"
        )
        public static let securityTitle = NSLocalizedString("privacy.security_title", value: "数据安全", comment: "章节标题：数据安全")
        public static let securityContent = NSLocalizedString(
            "privacy.security_content",
            value: "我们采取以下措施保护您的数据：本地存储（数据存储在您的设备上，受 iOS 沙盒保护）、无服务器（我们不运行服务器存储您的数据）、手动备份（您可以通过应用内的备份功能导出和恢复数据）。",
            comment: "数据安全内容"
        )
        public static let rightsTitle = NSLocalizedString("privacy.rights_title", value: "您的权利", comment: "章节标题：您的权利")
        public static let rightsContent = NSLocalizedString(
            "privacy.rights_content",
            value: """
            您对自己的数据拥有完全控制权：访问权（您可以随时查看应用中的所有数据）、导出权（通过"导出"功能导出您的数据）、删除权（您可以删除单个错题或清空所有数据）、备份权（通过备份功能保护您的数据）。

            如需完全删除所有数据，请在设置中选择"清空所有数据"或卸载应用。
            """,
            comment: "用户权利内容"
        )
        public static let thirdPartyTitle = NSLocalizedString("privacy.third_party_title", value: "第三方服务", comment: "章节标题：第三方服务")
        public static let thirdPartyContent = NSLocalizedString(
            "privacy.third_party_content",
            value: """
            SnapDrill 使用以下第三方服务：

            • Apple Vision Framework：用于 OCR 文字识别，完全在设备本地处理，数据不离开设备。
            • Firebase Analytics（Google）：匿名使用行为统计，用于了解功能使用情况并改进产品。不收集任何可识别个人身份的信息。在 iOS 上，此功能仅在您通过「应用跟踪透明度（ATT）」授权后才会启用。
            • Firebase Crashlytics（Google）：崩溃日志收集，用于识别和修复应用稳定性问题。仅收集设备类型、操作系统版本及崩溃堆栈信息。

            我们不使用任何第三方广告服务，不会将您的数据用于广告目的。
            """,
            comment: "第三方服务内容"
        )
        public static let childrenTitle = NSLocalizedString("privacy.children_title", value: "儿童隐私", comment: "章节标题：儿童隐私")
        public static let childrenContent = NSLocalizedString(
            "privacy.children_content",
            value: "SnapDrill 适合所有年龄段的用户使用。我们不会有意收集 13 岁以下儿童的个人信息。如果您是家长或监护人，发现您的孩子在未经您同意的情况下向我们提供了个人信息，请联系我们，我们将采取措施删除相关信息。",
            comment: "儿童隐私内容"
        )
        public static let gdprTitle = NSLocalizedString("privacy.gdpr_title", value: "GDPR 合规（欧盟用户）", comment: "章节标题：GDPR 合规")
        public static let gdprContent = NSLocalizedString(
            "privacy.gdpr_content",
            value: "如果您位于欧盟，您享有访问、更正、删除、限制处理和数据可携带等权利。由于 SnapDrill 不收集或存储您的数据在我们的服务器上，您可以通过应用内功能直接行使这些权利。",
            comment: "GDPR 合规内容"
        )
        public static let ccpaTitle = NSLocalizedString("privacy.ccpa_title", value: "CCPA 合规（加州用户）", comment: "章节标题：CCPA 合规")
        public static let ccpaContent = NSLocalizedString(
            "privacy.ccpa_content",
            value: "如果您是加州居民，您享有了解我们收集的个人信息类别、了解我们是否出售您的个人信息（我们不会）、删除您的个人信息等权利。SnapDrill 不会出售您的个人信息，也不会与第三方共享您的学习内容。",
            comment: "CCPA 合规内容"
        )
        public static let updateTitle = NSLocalizedString("privacy.update_title", value: "隐私政策更新", comment: "章节标题：隐私政策更新")
        public static let updateContent = NSLocalizedString(
            "privacy.update_content",
            value: "我们可能会不时更新本隐私政策。如有重大变更，我们将通过应用内通知或更新日期告知您。建议您定期查看本政策以了解我们如何保护您的信息。",
            comment: "隐私政策更新内容"
        )
        public static let contactTitle = NSLocalizedString("privacy.contact_title", value: "联系我们", comment: "章节标题：联系我们")
        public static let contactContent = NSLocalizedString(
            "privacy.contact_content",
            value: """
            如果您对本隐私政策有任何疑问或顾虑，请通过以下方式联系我们：

            邮箱：hello@notbadhq.com
            应用内反馈：设置 → 关于 → 反馈与支持

            我们将在 48 小时内回复您的询问。
            """,
            comment: "联系我们内容"
        )
        public static let viewFullVersion = NSLocalizedString("privacy.view_full_version", value: "在浏览器中查看完整版（中英双语）", comment: "查看完整版链接文字")
    }

    // MARK: - Help

    public enum Help {
        // 导航与搜索
        public static let title = NSLocalizedString("help.title", value: "帮助中心", comment: "帮助中心导航标题")
        public static let searchPrompt = NSLocalizedString("help.search_prompt", value: "搜索帮助...", comment: "帮助搜索栏占位符")

        // 主题标题
        public static let topicGettingStarted = NSLocalizedString("help.topic_getting_started", value: "开始使用", comment: "帮助主题标题")
        public static let topicSmartCapture = NSLocalizedString("help.topic_smart_capture", value: "智能拍摄", comment: "帮助主题标题")
        public static let topicReviewSystem = NSLocalizedString("help.topic_review_system", value: "复习系统", comment: "帮助主题标题")
        public static let topicDataManagement = NSLocalizedString("help.topic_data_management", value: "数据管理", comment: "帮助主题标题")
        public static let topicPrivacySecurity = NSLocalizedString("help.topic_privacy_security", value: "隐私与安全", comment: "帮助主题标题")
        public static let topicFaq = NSLocalizedString("help.topic_faq", value: "常见问题", comment: "帮助主题标题")

        // 开始使用
        public static let questionAddFirstItem = NSLocalizedString("help.question_add_first_item", value: "如何添加第一道错题？", comment: "帮助问题")
        public static let answerAddFirstItem = NSLocalizedString("help.answer_add_first_item", value: "点击主界面的「+」按钮，选择「拍摄」或「从相册选择」，系统会自动识别题目内容。您也可以手动输入题目和答案。", comment: "帮助答案")
        public static let questionStartReview = NSLocalizedString("help.question_start_review", value: "如何开始复习？", comment: "帮助问题")
        public static let answerStartReview = NSLocalizedString("help.answer_start_review", value: "在仪表板中点击「开始复习」按钮，系统会根据艾宾浩斯遗忘曲线为您安排今日需要复习的题目。", comment: "帮助答案")
        public static let questionSetSubjectSource = NSLocalizedString("help.question_set_subject_source", value: "如何设置学科和来源？", comment: "帮助问题")
        public static let answerSetSubjectSource = NSLocalizedString("help.answer_set_subject_source", value: "在添加或编辑错题时，可以选择学科（如数学、语文等）和来源（如期中考试、作业等），方便后续分类查看。", comment: "帮助答案")

        // 智能拍摄
        public static let questionBestCapture = NSLocalizedString("help.question_best_capture", value: "如何获得最佳拍摄效果？", comment: "帮助问题")
        public static let answerBestCapture = NSLocalizedString("help.answer_best_capture", value: "确保光线充足，将题目放在平整的表面上，保持相机稳定。系统会自动检测题目区域并提示您拍摄。", comment: "帮助答案")
        public static let questionOcrInaccurate = NSLocalizedString("help.question_ocr_inaccurate", value: "文字识别不准确怎么办？", comment: "帮助问题")
        public static let answerOcrInaccurate = NSLocalizedString("help.answer_ocr_inaccurate", value: "您可以在识别后手动编辑题目内容。建议拍摄时保持题目清晰、光线充足，避免反光和阴影。", comment: "帮助答案")
        public static let questionCropImage = NSLocalizedString("help.question_crop_image", value: "可以裁剪图片吗？", comment: "帮助问题")
        public static let answerCropImage = NSLocalizedString("help.answer_crop_image", value: "可以。拍摄后会进入裁剪界面，您可以调整裁剪区域，确保只保留题目部分。", comment: "帮助答案")

        // 复习系统
        public static let questionReviewSchedule = NSLocalizedString("help.question_review_schedule", value: "复习计划是如何安排的？", comment: "帮助问题")
        public static let answerReviewSchedule = NSLocalizedString("help.answer_review_schedule", value: "系统基于艾宾浩斯遗忘曲线，在最佳时间点提醒您复习。首次复习在 1 天后，之后间隔逐渐延长（3天、7天、15天、30天）。", comment: "帮助答案")
        public static let questionMarkDifficulty = NSLocalizedString("help.question_mark_difficulty", value: "如何标记题目难度？", comment: "帮助问题")
        public static let answerMarkDifficulty = NSLocalizedString("help.answer_mark_difficulty", value: "在复习时，您可以为每道题目标记难度（1-5星）。系统会根据难度调整复习频率，难题会更频繁地出现。", comment: "帮助答案")
        public static let questionCustomReview = NSLocalizedString("help.question_custom_review", value: "可以自定义复习计划吗？", comment: "帮助问题")
        public static let answerCustomReview = NSLocalizedString("help.answer_custom_review", value: "目前系统使用科学的复习算法自动安排。您可以在设置中调整每日复习目标数量。", comment: "帮助答案")

        // 数据管理
        public static let questionDataBackup = NSLocalizedString("help.question_data_backup", value: "如何备份我的数据？", comment: "帮助问题")
        public static let answerDataBackup = NSLocalizedString("help.answer_data_backup", value: "建议定期手动备份。进入「设置」-「备份与恢复」，点击「创建备份」即可。升级 Pro 后还可使用 iCloud 自动同步。", comment: "帮助答案")
        public static let questionExportData = NSLocalizedString("help.question_export_data", value: "如何导出数据？", comment: "帮助问题")
        public static let answerExportData = NSLocalizedString("help.answer_export_data", value: "进入「设置」-「隐私与安全」-「导出数据」，选择导出格式（PDF、CSV、JSON），系统会生成文件供您分享或备份。", comment: "帮助答案")
        public static let questionDataLoss = NSLocalizedString("help.question_data_loss", value: "数据会丢失吗？", comment: "帮助问题")
        public static let answerDataLoss = NSLocalizedString("help.answer_data_loss", value: "数据默认存储在本设备上，卸载应用会导致数据永久丢失。建议定期手动备份，或升级 Pro 后使用 iCloud 自动同步。", comment: "帮助答案")

        // 隐私与安全
        public static let questionDataSafe = NSLocalizedString("help.question_data_safe", value: "我的数据安全吗？", comment: "帮助问题")
        public static let answerDataSafe = NSLocalizedString("help.answer_data_safe", value: "所有数据都存储在您的设备和 iCloud 账号中，我们不会收集或上传您的个人数据。崩溃报告和分析数据都是匿名的。", comment: "帮助答案")
        public static let questionDisableAnalytics = NSLocalizedString("help.question_disable_analytics", value: "如何关闭数据分析？", comment: "帮助问题")
        public static let answerDisableAnalytics = NSLocalizedString("help.answer_disable_analytics", value: "进入「设置」-「隐私与安全」，关闭「数据分析」开关。这不会影响应用的核心功能。", comment: "帮助答案")
        public static let questionPermissions = NSLocalizedString("help.question_permissions", value: "相机和相册权限用于什么？", comment: "帮助问题")
        public static let answerPermissions = NSLocalizedString("help.answer_permissions", value: "相机权限用于拍摄错题，相册权限用于从相册选择图片。我们只在您使用相关功能时请求权限，不会访问其他照片。", comment: "帮助答案")

        // 常见问题
        public static let questionCrashOrLag = NSLocalizedString("help.question_crash_or_lag", value: "应用崩溃或卡顿怎么办？", comment: "帮助问题")
        public static let answerCrashOrLag = NSLocalizedString("help.answer_crash_or_lag", value: "请尝试重启应用。如果问题持续，可以在设置中清除缓存。我们会自动收集崩溃报告（如果您已启用）并尽快修复。", comment: "帮助答案")
        public static let questionContactSupport = NSLocalizedString("help.question_contact_support", value: "如何联系技术支持？", comment: "帮助问题")
        public static let answerContactSupport = NSLocalizedString("help.answer_contact_support", value: "您可以通过「设置」-「关于」-「反馈与支持」联系我们，或发送邮件到 support@snapdrill.app。", comment: "帮助答案")
        public static let questionIsFree = NSLocalizedString("help.question_is_free", value: "应用是免费的吗？", comment: "帮助问题")
        public static let answerIsFree = NSLocalizedString("help.answer_is_free", value: "SnapDrill 核心功能完全免费，包括无限录题、OCR 识别、分类管理和间隔复习。高级功能（如 iCloud 同步、高级导出格式）可通过订阅 Pro 解锁。我们绝不限制录入数量。", comment: "帮助答案")
    }
}

// swiftlint:enable type_body_length file_length

/// 本地化辅助工具
public enum LocalizationHelper {
    /// 获取当前语言代码
    public static var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "zh"
    }

    /// 是否为中文环境
    public static var isChineseLocale: Bool {
        currentLanguageCode.hasPrefix("zh")
    }

    /// 是否为英文环境
    public static var isEnglishLocale: Bool {
        currentLanguageCode.hasPrefix("en")
    }

    /// 格式化数字（带本地化）
    public static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// 格式化日期（带本地化）
    public static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// 格式化时间（带本地化）
    public static func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = style
        return formatter.string(from: date)
    }

    /// 格式化日期时间（带本地化）
    public static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

}
