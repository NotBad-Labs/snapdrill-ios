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

// 本文件是 L10n 命名空间的原始容器，正在按 Issue #666 方案 B 逐步拆分到
// `Support/L10n/L10n+<Module>.swift`。根类型见 `Support/L10n/L10n.swift`。
// `.swiftlint.yml` excluded 条目豁免 file_length，commit 5 收口时一并删除。
// `nonisolated` 需在 extension 级显式标注，defaultIsolation(MainActor) 下
// 不自动从根类型的 `nonisolated public enum L10n` 传递到 extension。
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
            • Firebase Analytics（Google）：匿名使用行为统计，用于了解功能使用情况并改进产品。不收集任何可识别个人身份的信息。您可以在设置中随时关闭。
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

    // MARK: - Help（v1.0 帮助入口跳转外部网页 FAQ，App 内 FAQ 已移除）

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
        public static let badgeToggleHint = NSLocalizedString("accessibility.badge_toggle_hint", value: "在应用图标上显示待复习数量", comment: "VoiceOver 角标开关提示")
        public static func fontSizeValue(_ size: Int) -> String {
            String(format: NSLocalizedString("accessibility.font_size_value", value: "%d 磅", comment: "VoiceOver 字号值"), size)
        }
        public static let backupDataHint = NSLocalizedString("accessibility.backup_data_hint", value: "导出完整数据备份文件", comment: "VoiceOver 备份数据提示")
        public static let restoreDataHint = NSLocalizedString("accessibility.restore_data_hint", value: "从备份文件恢复所有数据，会覆盖当前数据", comment: "VoiceOver 恢复数据提示")
        public static let analyticsToggleHint = NSLocalizedString("accessibility.analytics_toggle_hint", value: "匿名使用数据帮助我们改进产品", comment: "VoiceOver 分析开关提示")
        public static let crashReportingHint = NSLocalizedString("accessibility.crash_reporting_hint", value: "自动发送崩溃报告帮助修复问题", comment: "VoiceOver 崩溃报告提示")
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
