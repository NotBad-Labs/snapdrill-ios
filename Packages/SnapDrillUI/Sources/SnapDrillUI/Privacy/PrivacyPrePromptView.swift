//
//  PrivacyPrePromptView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ATT 隐私授权预热弹窗，在系统弹窗前向用户解释追踪权限用途。
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

    /// 创建隐私授权预热弹窗
    /// - Parameter onContinue: 用户点击"继续"后的回调（通常触发系统 ATT 弹窗）
    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 图标组（毛玻璃风格）
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

            // 标题与说明
            VStack(spacing: 12) {
                Text(L10n.PrivacyPrePrompt.title)
                    .font(.title2.bold())

                Text(L10n.PrivacyPrePrompt.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // 操作按钮
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Text(L10n.PrivacyPrePrompt.continueButton)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background {
            // 淡色径向渐变
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
