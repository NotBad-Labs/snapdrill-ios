//
//  PrivacyPolicyView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私政策展示页面（符合 GDPR/CCPA/App Store 要求）
//

import SnapDrillCore
import SwiftUI

/// 隐私政策展示视图（符合 GDPR/CCPA/App Store 要求）
public struct PrivacyPolicyView: View {
    /// 创建隐私政策视图
    public init() {}

    // MARK: - Body

    /// 隐私政策内容视图
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.PrivacyPolicy.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L10n.PrivacyPolicy.lastUpdated)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)

                sectionView(
                    title: L10n.PrivacyPolicy.introTitle,
                    content: L10n.PrivacyPolicy.introContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.collectionTitle,
                    content: L10n.PrivacyPolicy.collectionContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.usageTitle,
                    content: L10n.PrivacyPolicy.usageContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.securityTitle,
                    content: L10n.PrivacyPolicy.securityContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.rightsTitle,
                    content: L10n.PrivacyPolicy.rightsContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.thirdPartyTitle,
                    content: L10n.PrivacyPolicy.thirdPartyContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.childrenTitle,
                    content: L10n.PrivacyPolicy.childrenContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.gdprTitle,
                    content: L10n.PrivacyPolicy.gdprContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.ccpaTitle,
                    content: L10n.PrivacyPolicy.ccpaContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.updateTitle,
                    content: L10n.PrivacyPolicy.updateContent
                )

                sectionView(
                    title: L10n.PrivacyPolicy.contactTitle,
                    content: L10n.PrivacyPolicy.contactContent
                )

                // 查看完整版
                if let url = URL(string: "https://notbadhq.com/privacy") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text(L10n.PrivacyPolicy.viewFullVersion)
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
        .accessibilityIdentifier("settings.privacyPolicy.root")
        .navigationTitle(L10n.PrivacyPolicy.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
