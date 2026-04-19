//
//  L10n+Errors.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 错误提示分片：Errors / DataErrors / PersistenceErrors / BackupErrors。
//

import Foundation

nonisolated extension L10n {

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

        // 恢复建议（ContextualErrorView 用）
        public static let cameraPermissionHelp = NSLocalizedString("errors.camera_permission_help", value: "请在「设置」→「SnapDrill」→「相机」中允许访问", comment: "相机权限恢复建议")
        public static let photoPermissionHelp = NSLocalizedString("errors.photo_permission_help", value: "请在「设置」→「SnapDrill」→「照片」中允许访问", comment: "相册权限恢复建议")
        public static let ocrFailedHelp = NSLocalizedString("errors.ocr_failed_help", value: "请确保图片清晰且包含文字内容", comment: "OCR 失败恢复建议")
        public static let exportFailedHelp = NSLocalizedString("errors.export_failed_help", value: "请稍后重试", comment: "导出失败恢复建议")
        public static let importFailedHelp = NSLocalizedString("errors.import_failed_help", value: "请确保文件格式正确", comment: "导入失败恢复建议")
        public static let dataCorruptedHelp = NSLocalizedString("errors.data_corrupted_help", value: "数据文件已损坏，请尝试重新启动应用", comment: "数据损坏恢复建议")
        public static let unknownErrorHelp = NSLocalizedString("errors.unknown_error_help", value: "请稍后重试，如问题持续请重启应用", comment: "未知错误恢复建议")
        public static let errorOccurred = NSLocalizedString("errors.error_occurred", value: "发生错误", comment: "通用错误后备文本")

        // 数据加载
        public static let loadFailed = NSLocalizedString("errors.load_failed", value: "加载失败", comment: "数据加载失败标题")
        public static let tryAgainLater = NSLocalizedString("errors.try_again_later", value: "请稍后重试，或重启应用", comment: "加载失败恢复建议")
        public static let deleteFailed = NSLocalizedString("errors.delete_failed", value: "删除失败，请稍后重试", comment: "题目删除失败")
        public static let batchTagFailed = NSLocalizedString("errors.batch_tag_failed", value: "标签操作失败，请稍后重试", comment: "批量打标签失败")
        public static let pdfGenerateFailed = NSLocalizedString("errors.pdf_generate_failed", value: "PDF 生成失败，请稍后重试", comment: "PDF 生成失败")
        public static let reviewSaveFailed = NSLocalizedString("errors.review_save_failed", value: "复习记录保存失败，请重试", comment: "复习评分持久化失败")
        public static let formDataLoadFailed = NSLocalizedString("errors.form_data_load_failed", value: "表单数据加载失败，请返回重试", comment: "采集表单下拉数据加载失败")

        // 保存模块
        public static let saveFailed = NSLocalizedString("errors.save_failed", value: "保存失败，请检查存储空间后重试", comment: "题目保存失败")
        public static func createTaxonomyFailed(_ name: String) -> String {
            String(format: NSLocalizedString("errors.create_taxonomy_failed", value: "新建「%@」失败，请重试", comment: "分类创建失败"), name)
        }

        // 备份恢复
        public static let backupFailed = NSLocalizedString("errors.backup_failed", value: "备份失败，请检查存储空间后重试", comment: "备份失败")
        public static let restoreFailed = NSLocalizedString("errors.restore_failed", value: "恢复失败，请确认备份文件未损坏后重试", comment: "恢复失败")
        public static let fileAccessDenied = NSLocalizedString("errors.file_access_denied", value: "无法访问选择的文件，请重新选取", comment: "文件访问被拒绝")

        // 业务验证
        public static let contentAndImageEmpty = NSLocalizedString("errors.content_and_image_empty", value: "题目文字和图片不能同时为空", comment: "保存时内容和图片均为空")

        // SnapDrillError 描述
        public static let dataNotFound = NSLocalizedString("errors.data_not_found", value: "未找到请求的数据。", comment: "SnapDrillError.dataNotFound 描述")
        public static let captureFailed = NSLocalizedString("errors.capture_failed", value: "图像采集或识别失败。", comment: "SnapDrillError.captureFailed 描述")
        public static func unknownErrorWithMessage(_ message: String) -> String {
            String(format: NSLocalizedString("errors.unknown_error_with_message", value: "未知错误: %@", comment: "SnapDrillError.unknown 描述"), message)
        }

        // 个人资料
        public static let avatarSaveFailed = NSLocalizedString("edit_profile.avatar_save_failed", value: "头像保存失败，请重试", comment: "头像保存失败提示")
    }

    // MARK: - DataErrors（数据层错误）

    public enum DataErrors {
        public static func duplicateName(_ name: String, _ type: String) -> String {
            String(format: NSLocalizedString("data_errors.duplicate_name", value: "%@ '%@' 已存在", comment: "重复名称"), type, name)
        }
        public static let recoverySuggestionDuplicate = NSLocalizedString("data_errors.recovery_duplicate", value: "请使用不同的名称或检查是否已存在相同项目", comment: "重复项恢复建议")
    }

    // MARK: - PersistenceErrors（持久化错误）

    public enum PersistenceErrors {
        public static let containerInitFailed = NSLocalizedString("persistence_errors.container_init_failed", value: "数据库初始化失败", comment: "容器初始化失败")
        public static let migrationFailed = NSLocalizedString("persistence_errors.migration_failed", value: "数据迁移失败", comment: "迁移失败")
        public static let storageUnavailable = NSLocalizedString("persistence_errors.storage_unavailable", value: "存储空间不可用", comment: "存储不可用")
        public static let recoveryContainerInit = NSLocalizedString("persistence_errors.recovery_container_init", value: "请重启应用，如果问题持续请联系技术支持", comment: "容器初始化恢复建议")
        public static let recoveryMigration = NSLocalizedString("persistence_errors.recovery_migration", value: "请尝试更新到最新版本，如果问题持续请联系技术支持", comment: "迁移恢复建议")
        public static let recoveryStorage = NSLocalizedString("persistence_errors.recovery_storage", value: "请检查设备存储空间是否充足", comment: "存储恢复建议")
    }

    // MARK: - BackupErrors（备份错误）

    public enum BackupErrors {
        public static let archiveCreationFailed = NSLocalizedString("backup_errors.archive_creation_failed", value: "无法创建备份文件", comment: "备份创建失败")
        public static let invalidArchive = NSLocalizedString("backup_errors.invalid_archive", value: "备份文件格式无效或已损坏", comment: "无效备份")
        public static let missingManifest = NSLocalizedString("backup_errors.missing_manifest", value: "备份文件缺少清单信息", comment: "缺少清单")
        public static let missingDataFile = NSLocalizedString("backup_errors.missing_data_file", value: "备份文件中缺少数据文件", comment: "缺少数据")
        public static func schemaVersionTooNew(_ fileVersion: Int, _ appVersion: Int) -> String {
            String(format: NSLocalizedString("backup_errors.schema_version_too_new", value: "备份文件版本（%d）高于当前应用支持的版本（%d），请更新应用", comment: "版本过新"), fileVersion, appVersion)
        }
        public static let insufficientDiskSpace = NSLocalizedString("backup_errors.insufficient_disk_space", value: "磁盘空间不足，无法完成操作", comment: "空间不足")
    }
}
