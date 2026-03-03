//
//  PrivacyPrePromptView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import SnapDrillCore

/// 隐私授权预热弹窗
///
/// 在系统 ATT 弹窗之前展示，解释为什么需要追踪权限，提升用户信任感。
/// A pre-prompt screen shown before the system ATT dialog to explain tracking value.
public struct PrivacyPrePromptView: View {

    // MARK: - Properties

    private let onContinue: () -> Void

    @Environment(\.openURL) private var openURL

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon Group (Glassmorphism inspired)
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .offset(x: 15, y: -10)

                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .offset(x: -15, y: 10)
            }
            .padding(.bottom, 20)

            // Title & Description
            VStack(spacing: 12) {
                Text(isChinese ? "帮助小本本变得更好" : "Help SnapDrill Improve")
                    .font(.title2.bold())

                Text(isChinese
                    ? "通过允许追踪，我们可以衡量功能的使用情况，并更快速地修复潜在的崩溃，为您提供更好的学习体验。您的数据仍将保持匿名，仅用于产品改进。"
                    : "By allowing tracking, we can measure feature usage and fix issues faster, giving you a better learning experience. Your data remains anonymous and is only used for product improvement.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Actions
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Text(isChinese ? "继续" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    if let url = URL(string: "https://www.notbadhq.com/privacy") {
                        openURL(url)
                    }
                } label: {
                    Text(isChinese ? "了解更多" : "Learn More")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background {
            // Subtle Radial Gradient
            RadialGradient(colors: [Color.blue.opacity(0.05), .clear], center: .top, startRadius: 0, endRadius: 300)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    Text("Preview Wrapper")
        .sheet(isPresented: .constant(true)) {
            PrivacyPrePromptView(onContinue: {})
        }
}
