//
//  L10n+Library.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 题库分片：Library / Export。
//

import Foundation

nonisolated extension L10n {

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
        public static let sortByReviewStatus = NSLocalizedString("library.sort_by_review_status", value: "按复习状态", comment: "按复习状态排序")

        // 排序短名（LibrarySortOption.displayName 用）
        public static let sortTime = NSLocalizedString("library.sort_time", value: "时间", comment: "排序选项：时间")
        public static let sortSubject = NSLocalizedString("library.sort_subject", value: "学科", comment: "排序选项：学科")
        public static let sortDifficulty = NSLocalizedString("library.sort_difficulty", value: "难度", comment: "排序选项：难度")
        public static let sortReviewStatus = NSLocalizedString("library.sort_review_status", value: "复习状态", comment: "排序选项：复习状态")

        // 列表
        public static let allSubjects = NSLocalizedString("library.all_subjects", value: "全部", comment: "全部学科")
        public static let noContent = NSLocalizedString("library.no_content", value: "无文字内容", comment: "无文字内容占位")
        public static let noCategory = NSLocalizedString("library.no_category", value: "未分类", comment: "未分类占位")
        public static let loadingMore = NSLocalizedString("library.loading_more", value: "正在加载更多…", comment: "列表分页加载")
        public static let loadingLibrary = NSLocalizedString("library.loading_library", value: "正在整理资料", comment: "题库加载中")
        public static let loadingLibraryHint = NSLocalizedString("library.loading_library_hint", value: "稍候即可浏览已归档内容", comment: "题库加载中提示")

        // 详情
        public static let detail = NSLocalizedString("library.detail", value: "题目详情", comment: "详情页标题")
        public static let questionImage = NSLocalizedString("library.question_image", value: "题目图片", comment: "题目图片标签")
        public static let questionText = NSLocalizedString("library.question_text", value: "题目内容", comment: "题目内容")
        public static let answerSection = NSLocalizedString("library.answer_section", value: "答案与备注", comment: "答案与备注区")
        public static let answerPrivacyHint = NSLocalizedString("library.answer_privacy_hint", value: "默认隐藏，轻点展开或收起", comment: "答案默认隐藏提示")
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
        public static let filterDifficulty = NSLocalizedString("library.filter_difficulty", value: "难度", comment: "过滤难度标签")
        public static let filterTags = NSLocalizedString("library.filter_tags", value: "标签", comment: "过滤标签标签")

        // 批量标签
        public static let batchTag = NSLocalizedString("library.batch_tag", value: "标签", comment: "批量打标签按钮")
        public static let noTags = NSLocalizedString("library.no_tags", value: "还没有标签", comment: "批量标签空状态")
        public static func batchTagHint(_ count: Int) -> String {
            String(format: NSLocalizedString("library.batch_tag_hint", value: "为 %d 道题添加标签", comment: "批量打标签提示"), count)
        }

        // 导出
        public static let export = NSLocalizedString("library.export", value: "导出", comment: "导出按钮")
        public static let exportTitle = NSLocalizedString("library.export_title", value: "导出选项", comment: "导出选项标题")
        public static let exportPDF = NSLocalizedString("library.export_pdf", value: "PDF / 打印", comment: "PDF 导出")
        public static let exportPDFHint = NSLocalizedString("library.export_pdf_hint", value: "适合打印复习", comment: "PDF 导出提示")
        public static let exportCSV = NSLocalizedString("library.export_csv", value: "CSV", comment: "CSV 导出")
        public static let exportCSVHint = NSLocalizedString("library.export_csv_hint", value: "适合表格处理", comment: "CSV 提示")
        public static let exportImages = NSLocalizedString("library.export_images", value: "原图 ZIP", comment: "原图 ZIP 导出")
        public static let exportImagesHint = NSLocalizedString("library.export_images_hint", value: "导出所有题目原图", comment: "原图导出提示")
        public static let exportingImages = NSLocalizedString("library.exporting_images", value: "正在打包原图…", comment: "导出原图进度提示")
        public static let noImages = NSLocalizedString("library.no_images", value: "选中的题目没有图片", comment: "无图片提示")
        public static let noExportItems = NSLocalizedString("library.no_export_items", value: "没有可导出的条目", comment: "导出空状态")
        public static let noExportItemsHint = NSLocalizedString("library.no_export_items_hint", value: "返回列表后重新选择需要导出的内容", comment: "导出空状态提示")
        public static let exportPreview = NSLocalizedString("library.export_preview", value: "导出预览", comment: "导出预览页标题")
        public static let shareOrPrint = NSLocalizedString("library.share_or_print", value: "分享 / 打印", comment: "分享或打印")
        public static let generating = NSLocalizedString("library.generating", value: "正在生成...", comment: "正在生成")
        public static let generatingHint = NSLocalizedString("library.generating_hint", value: "正在准备预览文件", comment: "PDF 生成中提示")
        public static let generateFailed = NSLocalizedString("library.generate_failed", value: "生成失败", comment: "生成失败")
        public static let preparingPrint = NSLocalizedString("library.preparing_print", value: "正在准备打印", comment: "打印准备中")
        public static let printFailed = NSLocalizedString("library.print_failed", value: "无法开始打印", comment: "打印失败")
        public static let shareFailed = NSLocalizedString("library.share_failed", value: "无法生成分享卡", comment: "分享卡失败")

        // 过滤
        public static let clearFilters = NSLocalizedString("library.clear_filters", value: "清除", comment: "清除过滤条件按钮")

        // 批量操作
        public static let selectItems = NSLocalizedString("library.select_items", value: "选择", comment: "选择模式按钮")
        public static let selectAll = NSLocalizedString("library.select_all", value: "全选", comment: "全选按钮")
        public static let deselectAll = NSLocalizedString("library.deselect_all", value: "取消全选", comment: "取消全选按钮")
        public static let deleteSelected = NSLocalizedString("library.delete_selected", value: "删除", comment: "删除已选")
        public static let exportSelected = NSLocalizedString("library.export_selected", value: "导出", comment: "导出已选")
        public static let printSingle = NSLocalizedString("library.print_single", value: "打印", comment: "单题打印按钮")
        public static let share = NSLocalizedString("library.share", value: "分享", comment: "分享按钮")
        public static let shareCardTitle = NSLocalizedString("library.share_card_title", value: "SnapDrill 摘录卡", comment: "分享卡片标题")

        // 删除确认
        public static let deleteConfirmTitle = NSLocalizedString("library.delete_confirm_title", value: "确认删除", comment: "删除确认标题")
        public static let deleteConfirmMessage = NSLocalizedString("library.delete_confirm_message", value: "删除后可在 5 秒内撤销", comment: "删除确认信息")
        public static func deletedCount(_ count: Int) -> String {
            String(format: NSLocalizedString("library.deleted_count", value: "已删除 %d 道题", comment: "撤销 Toast 显示已删除数量"), count)
        }
        public static let undo = NSLocalizedString("library.undo", value: "撤销", comment: "撤销删除按钮")

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
        public static let iconCategoryCommon = NSLocalizedString("library.icon_category_common", value: "常用", comment: "图标分类-常用")
        public static let iconCategoryDocuments = NSLocalizedString("library.icon_category_documents", value: "文档", comment: "图标分类-文档")
        public static let iconCategoryWork = NSLocalizedString("library.icon_category_work", value: "工作", comment: "图标分类-工作")
        public static let iconCategoryIdeas = NSLocalizedString("library.icon_category_ideas", value: "想法", comment: "图标分类-想法")
        public static let iconCategoryWriting = NSLocalizedString("library.icon_category_writing", value: "书写", comment: "图标分类-书写")
        public static let iconCategoryPlaces = NSLocalizedString("library.icon_category_places", value: "地点", comment: "图标分类-地点")
        public static let iconCategoryPeople = NSLocalizedString("library.icon_category_people", value: "人物", comment: "图标分类-人物")
        public static let iconCategoryNature = NSLocalizedString("library.icon_category_nature", value: "自然", comment: "图标分类-自然")
        public static let iconCategoryTools = NSLocalizedString("library.icon_category_tools", value: "工具", comment: "图标分类-工具")
        public static let iconCategoryMeasurement = NSLocalizedString("library.icon_category_measurement", value: "度量", comment: "图标分类-度量")

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

        // 分类管理 — 重名提示
        public static let duplicateName = NSLocalizedString("library.duplicate_name", value: "名称已存在", comment: "重名弹窗标题")
        public static func duplicateNameMessage(_ name: String) -> String {
            String(format: NSLocalizedString("library.duplicate_name_message", value: "「%@」已被使用，请输入其他名称。", comment: "重名提示"), name)
        }

        // MARK: - 分类维度管理（L3 动态维度）

        public static let categoryManager = NSLocalizedString("library.category_manager", value: "管理分类", comment: "分类维度管理页标题")
        public static let dimensionsSection = NSLocalizedString("library.dimensions_section", value: "维度", comment: "维度列表分区标题")
        public static let addDimension = NSLocalizedString("library.add_dimension", value: "新建维度", comment: "新建维度")
        public static let editDimension = NSLocalizedString("library.edit_dimension", value: "编辑维度", comment: "编辑维度")
        public static let dimensionNamePlaceholder = NSLocalizedString("library.dimension_name_placeholder", value: "例如：章节、错因", comment: "维度名输入占位")
        public static let builtInBadge = NSLocalizedString("library.built_in_badge", value: "内置", comment: "内置维度标记")
        public static let dimensionSettings = NSLocalizedString("library.dimension_settings", value: "维度设置", comment: "维度设置分区标题")
        public static let multiValue = NSLocalizedString("library.multi_value", value: "允许多选", comment: "维度单值/多值开关")
        public static let multiValueDescription = NSLocalizedString("library.multi_value_description", value: "开启后，一道题在该维度下可同时贴多个值（如标签）；关闭则只能选一个（如学科）。内置维度不可更改。", comment: "单值多值开关说明")
        public static let showInCapture = NSLocalizedString("library.show_in_capture", value: "在录入页显示", comment: "维度可见性开关")
        public static let showInCaptureDescription = NSLocalizedString("library.show_in_capture_description", value: "关闭后，录入和编辑题目时不显示该维度（减少干扰，随时可重新打开）。", comment: "维度可见性说明")
        public static let valuesSection = NSLocalizedString("library.values_section", value: "值", comment: "维度值列表分区标题")
        public static let addValue = NSLocalizedString("library.add_value", value: "添加值", comment: "添加维度值")
        public static let editValue = NSLocalizedString("library.edit_value", value: "编辑值", comment: "编辑维度值")
        public static let noValues = NSLocalizedString("library.no_values", value: "暂无值，点右上角 + 添加", comment: "维度值空状态")
        public static func valueHasItems(_ name: String) -> String {
            String(format: NSLocalizedString("library.value_has_items", value: "「%@」下仍有题目，请先移动或删除对应题目。", comment: "维度值删除受阻"), name)
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
        public static let pdfTitle = NSLocalizedString("export.pdf_title", value: "SnapDrill 资料集", comment: "PDF 导出封面标题")
        public static func pdfGenerationDate(_ date: String) -> String {
            String(format: NSLocalizedString("export.pdf_generation_date", value: "生成日期: %@", comment: "PDF 导出封面副标题"), date)
        }
        public static let hideAnswers = NSLocalizedString("export.hide_answers", value: "隐藏答案", comment: "导出选项：隐藏答案开关")
        public static let answerLabel = NSLocalizedString("export.answer_label", value: "答案：", comment: "PDF 导出中答案区域前缀")
        public static let showBlankArea = NSLocalizedString("export.show_blank_area", value: "显示答题区", comment: "导出选项：显示答题留白区开关")
        public static let showHeader = NSLocalizedString("export.show_header", value: "显示页眉页码", comment: "导出选项：显示页眉页码开关")
        public static let mixedSubject = NSLocalizedString("export.mixed_subject", value: "综合练习", comment: "PDF 页眉：多学科混合时显示")
        public static let defaultSubject = NSLocalizedString("export.default_subject", value: "资料集", comment: "PDF 页眉：无学科信息时的默认标题")
        public static let itemsPerPage = NSLocalizedString("export.items_per_page", value: "每页题数", comment: "导出选项：每页题目数量")
        public static let pdfOptions = NSLocalizedString("export.pdf_options", value: "打印选项", comment: "导出选项区域标题")
        public static func pageNumber(_ current: Int, _ total: Int) -> String {
            String(format: NSLocalizedString("export.page_number", value: "第 %d/%d 页", comment: "PDF 页眉：页码"), current, total)
        }
    }
}
