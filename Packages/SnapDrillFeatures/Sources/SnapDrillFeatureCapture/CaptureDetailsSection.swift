//
//  CaptureDetailsSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的答案详情 section：答案 + 答案图。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI
import PhotosUI

/// 采集结果页 — 题目详情 section
struct CaptureDetailsSection: View {
    @Bindable var viewModel: CaptureResultViewModel
    let showAnswer: Bool

    var body: some View {
        if showAnswer {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.Capture.questionDetails)
                    .font(.headline)
                    .padding(.horizontal)

                answerSection
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - 答案

    private var answerSection: some View {
        let isAnswerPhotoLoading = viewModel.isAnswerPhotoLoading
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Capture.answer)
            TextEditor(text: $viewModel.answerText)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier("capture.answerEditor")

            HStack {
                if let answerImage = viewModel.answerImage {
                    Image(uiImage: answerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button(role: .destructive) {
                        viewModel.answerImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                PhotosPicker(selection: $viewModel.answerPhotoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Label(L10n.Capture.addAnswerImage, systemImage: "photo.badge.plus")
                            .font(.subheadline)
                        if isAnswerPhotoLoading {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityLabel(L10n.Common.loading)
                        }
                    }
                }
                .disabled(viewModel.isSaving || viewModel.isSaved)
            }
            .sensoryFeedback(.warning, trigger: viewModel.answerImage) { old, new in
                old != nil && new == nil
            }
        }
        .padding()
    }
}
