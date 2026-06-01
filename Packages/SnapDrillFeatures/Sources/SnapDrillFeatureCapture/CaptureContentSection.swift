//
//  CaptureContentSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的正文编辑 section：OCR 文本编辑 + 复制到剪贴板 + 识别中状态。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 采集结果页 — 正文编辑 section
struct CaptureContentSection: View {
    @Bindable var viewModel: CaptureResultViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Capture.questionContent)
                    .font(.headline)
                if viewModel.isRecognizing {
                    Text(L10n.Capture.reRecognizing)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // 复制 OCR 文本到剪贴板
                if !viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        UIPasteboard.general.string = viewModel.content
                        viewModel.copyConfirmationCount += 1
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibleButton(
                        label: L10n.Capture.copyContent,
                        hint: L10n.Accessibility.copyContentHint
                    )
                    .sensoryFeedback(.success, trigger: viewModel.copyConfirmationCount)
                }
            }

            TextEditor(text: $viewModel.content)
                .font(.body)
                .padding(12)
                .frame(minHeight: 120)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(viewModel.isRecognizing ? 0.6 : 1)
                .disabled(viewModel.isRecognizing)
                .accessibilityIdentifier("capture.contentEditor")
        }
        .padding(.horizontal)
    }
}
