//
//  L10n+Policy.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 法律文本分片：TermsOfService / PrivacyPolicy。
//

import Foundation

nonisolated extension L10n {

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
}
