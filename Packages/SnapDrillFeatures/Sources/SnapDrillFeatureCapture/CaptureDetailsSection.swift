//
//  CaptureDetailsSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的题目详情 section：难度（有序刻度，保留星级）/ 答案 + 答案图。
//  L3：年级已并入动态维度（CaptureMetadataSection），不再在此渲染。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI
import PhotosUI

/// 采集结果页 — 题目详情 section
struct CaptureDetailsSection: View {
    @Bindable var viewModel: CaptureResultViewModel
    let showDifficulty: Bool
    let showAnswer: Bool

    var body: some View {
        if showDifficulty || showAnswer {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.Capture.questionDetails)
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    if showDifficulty { difficultyRow }
                    if showAnswer {
                        if showDifficulty { Divider().padding(.leading) }
                        answerSection
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - 难度（保留星级，有序刻度不进动态维度）

    private var difficultyRow: some View {
        HStack {
            Text(L10n.Capture.difficulty)
            Spacer()
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        viewModel.difficulty = Difficulty(rawValue: level) ?? .one
                    } label: {
                        Image(systemName: level <= viewModel.difficulty.rawValue ? "star.fill" : "star")
                            .foregroundStyle(level <= viewModel.difficulty.rawValue ? .orange : .gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel(L10n.Accessibility.starRating(difficulty: level))
                    .accessibilityAddTraits(level <= viewModel.difficulty.rawValue ? .isSelected : [])
                    .accessibilityIdentifier("capture.difficulty.\(level)")
                }
            }
        }
        .padding()
    }

    // MARK: - 答案

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    Label(L10n.Capture.addAnswerImage, systemImage: "photo.badge.plus")
                        .font(.subheadline)
                }
            }
            .sensoryFeedback(.warning, trigger: viewModel.answerImage) { old, new in
                old != nil && new == nil
            }
        }
        .padding()
    }
}
