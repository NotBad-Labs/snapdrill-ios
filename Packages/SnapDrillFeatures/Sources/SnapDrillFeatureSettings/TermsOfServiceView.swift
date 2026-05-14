//
//  TermsOfServiceView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  用户协议/服务条款页面
//

import SnapDrillCore
import SwiftUI

/// 用户协议视图
public struct TermsOfServiceView: View {
    /// 创建用户协议视图
    public init() {}

    // MARK: - Body

    /// 用户协议内容视图
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.TermsOfService.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L10n.TermsOfService.lastUpdated)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)

                sectionView(
                    title: L10n.TermsOfService.acceptanceTitle,
                    content: L10n.TermsOfService.acceptanceContent
                )

                sectionView(
                    title: L10n.TermsOfService.serviceTitle,
                    content: L10n.TermsOfService.serviceContent
                )

                sectionView(
                    title: L10n.TermsOfService.dataStorageTitle,
                    content: L10n.TermsOfService.dataStorageContent
                )

                sectionView(
                    title: L10n.TermsOfService.licenseTitle,
                    content: L10n.TermsOfService.licenseContent
                )

                sectionView(
                    title: L10n.TermsOfService.userContentTitle,
                    content: L10n.TermsOfService.userContentContent
                )

                sectionView(
                    title: L10n.TermsOfService.ipTitle,
                    content: L10n.TermsOfService.ipContent
                )

                sectionView(
                    title: L10n.TermsOfService.disclaimerTitle,
                    content: L10n.TermsOfService.disclaimerContent
                )

                sectionView(
                    title: L10n.TermsOfService.liabilityTitle,
                    content: L10n.TermsOfService.liabilityContent
                )

                sectionView(
                    title: L10n.TermsOfService.backupTitle,
                    content: L10n.TermsOfService.backupContent
                )

                sectionView(
                    title: L10n.TermsOfService.changesTitle,
                    content: L10n.TermsOfService.changesContent
                )

                sectionView(
                    title: L10n.TermsOfService.thirdPartyTitle,
                    content: L10n.TermsOfService.thirdPartyContent
                )

                sectionView(
                    title: L10n.TermsOfService.lawTitle,
                    content: L10n.TermsOfService.lawContent
                )

                sectionView(
                    title: L10n.TermsOfService.modificationTitle,
                    content: L10n.TermsOfService.modificationContent
                )

                sectionView(
                    title: L10n.TermsOfService.severabilityTitle,
                    content: L10n.TermsOfService.severabilityContent
                )

                sectionView(
                    title: L10n.TermsOfService.entireAgreementTitle,
                    content: L10n.TermsOfService.entireAgreementContent
                )

                sectionView(
                    title: L10n.TermsOfService.contactTitle,
                    content: L10n.TermsOfService.contactContent
                )
            }
            .padding()
        }
        .navigationTitle(L10n.TermsOfService.title)
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
        TermsOfServiceView()
    }
}
