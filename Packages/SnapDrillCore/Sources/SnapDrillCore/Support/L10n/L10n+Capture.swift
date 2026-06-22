//
//  L10n+Capture.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 采集流程分片：Capture / Category presets / Difficulty。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Capture

    public enum Capture {
        public static let title = NSLocalizedString("capture.title", value: "采集", comment: "采集页标题")
        public static let entryMethodTitle = NSLocalizedString("capture.entry_method_title", value: "添加内容", comment: "采集入口标题")
        public static let cameraTitle = NSLocalizedString("capture.camera_title", value: "拍摄资料", comment: "相机采集")
        public static let cameraSubtitle = NSLocalizedString("capture.camera_subtitle", value: "拍摄并识别文字", comment: "拍照副标题")
        public static let albumTitle = NSLocalizedString("capture.album_title", value: "相册导入", comment: "相册导入")
        public static let albumSubtitle = NSLocalizedString("capture.album_subtitle", value: "识别已有图片", comment: "相册副标题")
        public static let manualTitle = NSLocalizedString("capture.manual_title", value: "手动录入", comment: "手动录入")
        public static let manualSubtitle = NSLocalizedString("capture.manual_subtitle", value: "直接输入文本", comment: "手动录入副标题")
        public static let clipboardTitle = NSLocalizedString("capture.clipboard_title", value: "剪贴板", comment: "剪贴板")
        public static let clipboardSubtitle = NSLocalizedString("capture.clipboard_subtitle", value: "从剪贴板读取", comment: "粘贴板副标题")
        public static let pdfTitle = NSLocalizedString("capture.pdf_title", value: "PDF 导入", comment: "PDF 导入")
        public static let pdfSubtitle = NSLocalizedString("capture.pdf_subtitle", value: "从文件导入资料", comment: "PDF 副标题")
        public static let docScanTitle = NSLocalizedString("capture.doc_scan_title", value: "文档扫描", comment: "文档扫描")
        public static let docScanSubtitle = NSLocalizedString("capture.doc_scan_subtitle", value: "扫描纸质资料", comment: "文档扫描副标题")

        // 草稿恢复
        public static let draftAlertTitle = NSLocalizedString("capture.draft_alert_title", value: "恢复草稿", comment: "草稿恢复弹窗标题")
        public static let draftContinue = NSLocalizedString("capture.draft_continue", value: "继续编辑", comment: "继续编辑草稿")
        public static let draftAlertMessage = NSLocalizedString("capture.draft_alert_message", value: "检测到未保存的采集内容，是否恢复？", comment: "草稿恢复提示")

        // 结果编辑页
        public static let previewAndEdit = NSLocalizedString("capture.preview_and_edit", value: "预览与编辑", comment: "预览与编辑页标题")
        public static let questionContent = NSLocalizedString("capture.question_content", value: "内容", comment: "正文内容标签")
        public static let copyContent = NSLocalizedString("capture.copy_content", value: "复制文本", comment: "复制 OCR 文本到剪贴板按钮")
        public static let reRecognizing = NSLocalizedString("capture.re_recognizing", value: "正在重新识别...", comment: "重新 OCR 识别中")
        public static let categoryInfo = NSLocalizedString("capture.category_info", value: "分类信息", comment: "分类信息标签")
        public static let questionDetails = NSLocalizedString("capture.question_details", value: "资料详情", comment: "资料详情标签")
        public static let category = NSLocalizedString("capture.category", value: "分类", comment: "分类标签")
        public static let source = NSLocalizedString("capture.source", value: "来源", comment: "来源标签")
        public static let tags = NSLocalizedString("capture.tags", value: "标签", comment: "标签标签")
        public static let tagInputPlaceholder = NSLocalizedString("capture.tag_input_placeholder", value: "输入标签，空格添加", comment: "标签输入框占位提示")
        public static let difficulty = NSLocalizedString("capture.difficulty", value: "难度", comment: "难度标签")
        public static let level = NSLocalizedString("capture.level", value: "阶段/级别", comment: "阶段标签")
        public static let answer = NSLocalizedString("capture.answer", value: "参考内容", comment: "参考内容标签")
        public static let addAnswerImage = NSLocalizedString("capture.add_answer_image", value: "添加参考图片", comment: "添加参考图片")
        public static let saveFailed = NSLocalizedString("capture.save_failed", value: "保存失败", comment: "保存失败弹窗标题")
        public static let saving = NSLocalizedString("capture.saving", value: "正在保存...", comment: "保存进行中")
        public static let saveSucceeded = NSLocalizedString("capture.save_succeeded", value: "已保存到资料库", comment: "保存成功")
        public static let manualEmptyHint = NSLocalizedString("capture.manual_empty_hint", value: "输入或粘贴需要归档的内容。", comment: "手动输入空态提示")
        public static let ocrEmptyHint = NSLocalizedString("capture.ocr_empty_hint", value: "未识别到文字，可以手动输入或重新采集。", comment: "OCR 空结果提示")

        // 新建分类弹窗
        public static let newCategory = NSLocalizedString("capture.new_category", value: "新建分类", comment: "新建分类")
        public static let categoryNamePlaceholder = NSLocalizedString("capture.category_name_placeholder", value: "分类名称", comment: "分类名称输入占位")
        public static let newCategoryMessage = NSLocalizedString("capture.new_category_message", value: "输入新分类名称，创建后自动选中", comment: "新建分类提示")
        public static let newSource = NSLocalizedString("capture.new_source", value: "新建来源", comment: "新建来源")
        public static let sourceNamePlaceholder = NSLocalizedString("capture.source_name_placeholder", value: "来源名称", comment: "来源名称输入占位")
        public static let newSourceMessage = NSLocalizedString("capture.new_source_message", value: "输入新来源名称，创建后自动选中", comment: "新建来源提示")
        public static let newLevel = NSLocalizedString("capture.new_level", value: "新建阶段", comment: "新建阶段")
        public static let levelNamePlaceholder = NSLocalizedString("capture.level_name_placeholder", value: "阶段名称", comment: "阶段名称输入占位")
        public static let newLevelMessage = NSLocalizedString("capture.new_level_message", value: "输入新阶段名称，创建后自动选中", comment: "新建阶段提示")

        // 动态维度通用（L3：取代上面固定分类/来源/级别专用串，S6 删旧）
        public static let addValuePlaceholder = NSLocalizedString("capture.add_value_placeholder", value: "名称", comment: "新建维度值名称占位")
        public static let selectValue = NSLocalizedString("capture.select_value", value: "选择", comment: "单值维度未选时占位")
        public static func addValueTitle(_ dimensionName: String) -> String {
            String(format: NSLocalizedString("capture.add_value_title", value: "新建%@", comment: "新建维度值标题（含维度名）"), dimensionName)
        }

        // PDF 页面选择
        public static let selectPage = NSLocalizedString("capture.select_page", value: "选择页面", comment: "PDF 页面选择标题")
        public static let loadingPage = NSLocalizedString("capture.loading_page", value: "正在加载...", comment: "正在加载页面")
        public static let recognizingPage = NSLocalizedString("capture.recognizing_page", value: "正在识别...", comment: "正在 OCR 识别")

        public static func pdfPageHint(_ count: Int) -> String {
            String(format: NSLocalizedString("capture.pdf_page_hint", value: "共 %d 页，点击选择要导入的页面", comment: "PDF 页数提示"), count)
        }

        public static func pageNumber(_ number: Int) -> String {
            String(format: NSLocalizedString("capture.page_number", value: "第 %d 页", comment: "第 N 页"), number)
        }

        // 相机取景
        public static let cameraScanningHint = NSLocalizedString("capture.camera_scanning_hint", value: "寻找文字区域...", comment: "相机扫描提示")
        public static let cameraReadyHint = NSLocalizedString("capture.camera_ready_hint", value: "可以拍摄了", comment: "相机稳定后提示可以拍摄")
        public static let cameraCapturingHint = NSLocalizedString("capture.camera_capturing_hint", value: "正在拍摄...", comment: "相机拍摄进行中")
        public static let ocrFailedHint = NSLocalizedString("capture.ocr_failed_hint", value: "文字识别失败，可以继续手动编辑。", comment: "OCR 失败时提示用户手动输入")
        public static let ocrEmptyTitle = NSLocalizedString("capture.ocr_empty_title", value: "未识别到文字", comment: "OCR 空结果标题")
        public static let ocrFailedTitle = NSLocalizedString("capture.ocr_failed_title", value: "识别未完成", comment: "OCR 失败标题")
        public static let ocrRetry = NSLocalizedString("capture.ocr_retry", value: "重新识别", comment: "OCR 失败后重试按钮")
        public static let ocrContinueEdit = NSLocalizedString("capture.ocr_continue_edit", value: "继续编辑", comment: "OCR 失败后继续手动编辑按钮")
        public static let scanUnavailableTitle = NSLocalizedString("capture.scan_unavailable_title", value: "模拟器不支持文档扫描", comment: "模拟器文档扫描不可用标题")
        public static let scanUnavailableMessage = NSLocalizedString("capture.scan_unavailable_message", value: "请在真机上使用文档扫描，或改用相册、PDF 与手动输入。", comment: "模拟器文档扫描不可用说明")

        // 默认值（自动推断兜底）
        public static let defaultCategory = NSLocalizedString("capture.default_category", value: "题目", comment: "默认分类")
        public static let defaultSource = NSLocalizedString("capture.default_source", value: "资料", comment: "默认来源")

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

    // MARK: - Category Presets

    public enum CategoryPresets {
        public static let questions = NSLocalizedString("categories.questions", value: "题目", comment: "题目")
        public static let documents = NSLocalizedString("categories.documents", value: "文档", comment: "文档")
        public static let receipts = NSLocalizedString("categories.receipts", value: "票据", comment: "票据")
        public static let training = NSLocalizedString("categories.training", value: "培训", comment: "培训")
        public static let work = NSLocalizedString("categories.work", value: "工作", comment: "工作")
        public static let other = NSLocalizedString("categories.other", value: "其他", comment: "其他")
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
}
