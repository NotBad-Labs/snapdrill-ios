//
//  PrivacyPolicyView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私政策展示页面（符合 GDPR/CCPA/App Store 要求）
//

import SwiftUI

public struct PrivacyPolicyView: View {
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("最后更新日期：2026年3月")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                
                // 引言
                sectionView(
                    title: "引言",
                    content: "欢迎使用 SnapDrill！我们非常重视您的隐私。本隐私政策说明了我们如何收集、使用、存储和保护您的个人信息。使用 SnapDrill 应用即表示您同意本隐私政策中描述的做法。"
                )
                
                // 信息收集
                sectionView(
                    title: "我们收集的信息",
                    content: """
                    SnapDrill 是一款完全离线优先的应用，我们不会主动收集您的个人信息。您在应用中创建的所有数据（包括错题内容、图片、笔记等）都存储在您的设备上。
                    
                    您创建的内容：错题文本、上传或拍摄的图片、学科分类和标签、复习记录和进度。
                    
                    自动收集的信息：应用崩溃日志（仅用于改进应用稳定性）、设备类型和操作系统版本（用于兼容性测试）。
                    """
                )
                
                // iCloud 同步
                sectionView(
                    title: "iCloud 同步",
                    content: """
                    如果您启用了 iCloud 同步功能，您的数据将通过 Apple 的 iCloud 服务在您的设备之间同步。
                    
                    重要说明：所有数据都存储在您的个人 iCloud 账户中，我们无法访问您的 iCloud 数据。数据传输由 Apple 加密保护。您可以随时在设置中关闭 iCloud 同步。
                    """
                )
                
                // 数据使用
                sectionView(
                    title: "数据使用",
                    content: """
                    我们使用收集的信息仅用于：提供核心功能（存储和管理您的错题数据）、改进应用（分析崩溃日志以修复 bug）、用户支持（回应您的反馈和技术支持请求）。
                    
                    我们不会：出售您的个人信息、将您的数据用于广告目的、与第三方共享您的学习内容。
                    """
                )
                
                // 数据安全
                sectionView(
                    title: "数据安全",
                    content: "我们采取以下措施保护您的数据：本地存储（数据存储在您的设备上，受 iOS 沙盒保护）、iCloud 加密（通过 iCloud 同步的数据由 Apple 加密）、无服务器（我们不运行服务器存储您的数据）。"
                )
                
                // 用户权利
                sectionView(
                    title: "您的权利",
                    content: """
                    您对自己的数据拥有完全控制权：访问权（您可以随时查看应用中的所有数据）、导出权（通过"导出"功能导出您的数据）、删除权（您可以删除单个错题或清空所有数据）、关闭同步（随时在设置中关闭 iCloud 同步）。
                    
                    如需完全删除所有数据，请在设置中选择"清空所有数据"或卸载应用。
                    """
                )
                
                // 第三方服务
                sectionView(
                    title: "第三方服务",
                    content: """
                    SnapDrill 使用以下第三方服务：

                    • Apple Vision Framework：用于 OCR 文字识别，完全在设备本地处理，数据不离开设备。
                    • Firebase Analytics（Google）：匿名使用行为统计，用于了解功能使用情况并改进产品。不收集任何可识别个人身份的信息。在 iOS 上，此功能仅在您通过「应用跟踪透明度（ATT）」授权后才会启用。
                    • Firebase Crashlytics（Google）：崩溃日志收集，用于识别和修复应用稳定性问题。仅收集设备类型、操作系统版本及崩溃堆栈信息。

                    我们不使用任何第三方广告服务，不会将您的数据用于广告目的。
                    """
                )
                
                // 儿童隐私
                sectionView(
                    title: "儿童隐私",
                    content: "SnapDrill 适合所有年龄段的用户使用。我们不会有意收集 13 岁以下儿童的个人信息。如果您是家长或监护人，发现您的孩子在未经您同意的情况下向我们提供了个人信息，请联系我们，我们将采取措施删除相关信息。"
                )
                
                // GDPR 合规
                sectionView(
                    title: "GDPR 合规（欧盟用户）",
                    content: "如果您位于欧盟，您享有访问、更正、删除、限制处理和数据可携带等权利。由于 SnapDrill 不收集或存储您的数据在我们的服务器上，您可以通过应用内功能直接行使这些权利。"
                )
                
                // CCPA 合规
                sectionView(
                    title: "CCPA 合规（加州用户）",
                    content: "如果您是加州居民，您享有了解我们收集的个人信息类别、了解我们是否出售您的个人信息（我们不会）、删除您的个人信息等权利。SnapDrill 不会出售您的个人信息，也不会与第三方共享您的学习内容。"
                )
                
                // 政策更新
                sectionView(
                    title: "隐私政策更新",
                    content: "我们可能会不时更新本隐私政策。如有重大变更，我们将通过应用内通知或更新日期告知您。建议您定期查看本政策以了解我们如何保护您的信息。"
                )
                
                // 联系我们
                sectionView(
                    title: "联系我们",
                    content: """
                    如果您对本隐私政策有任何疑问或顾虑，请通过以下方式联系我们：
                    
                    邮箱：hello@notbadhq.com
                    应用内反馈：设置 → 关于 → 反馈与支持

                    我们将在 48 小时内回复您的询问。
                    """
                )
                // 查看完整版
                if let url = URL(string: "https://notbadhq.com/privacy") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text("在浏览器中查看完整版（中英双语）")
                                .font(.footnote)
                            Image(systemName: "arrow.up.right.square")
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
