//
//  CaptureDetailsSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的题目详情 section：难度 / 年级（含内联新建）/ 答案 + 答案图。
//  三者全部关闭时整个 section 隐藏；字段可见性由父 View 经 @AppStorage 以 Bool 传入。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI
import PhotosUI

/// 采集结果页 — 题目详情 section
struct CaptureDetailsSection: View {
    @Bindable var viewModel: CaptureResultViewModel
    let showDifficulty: Bool
    let showGrade: Bool
    let showAnswer: Bool

    var body: some View {
        if showDifficulty || showGrade || showAnswer {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.Capture.questionDetails)
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    // 难度
                    if showDifficulty {
                        HStack {
                            Text(L10n.Capture.difficulty)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { level in
                                    Button {
                                        viewModel.difficulty = Difficulty(rawValue: level) ?? .one
                                    } label: {
                                        Image(systemName: level <= viewModel.difficulty.rawValue ? "star.fill" : "star")
                                            .foregroundStyle(level <= viewModel.difficulty.rawValue ? .orange : .gray.opacity(0.3))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(L10n.Accessibility.starRating(difficulty: level))
                                }
                            }
                        }
                        .padding()
                    }

                    // Grade/Mastery — Menu label 仅右侧，保留内联新建
                    if showGrade {
                        if showDifficulty { Divider().padding(.leading) }
                        HStack {
                            Text(L10n.Capture.grade)
                                .foregroundStyle(.primary)
                            Spacer()
                            Menu {
                                ForEach(viewModel.availableGrades) { grade in
                                    Button {
                                        viewModel.grade = grade.name
                                    } label: {
                                        Text(grade.name)
                                    }
                                }
                                Divider()
                                Button {
                                    viewModel.showNewGradeAlert = true
                                } label: {
                                    Label(L10n.Capture.newGrade, systemImage: "plus")
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.grade.isEmpty ? L10n.Common.notSelected : viewModel.grade)
                                        .foregroundStyle(viewModel.grade.isEmpty ? .tertiary : .secondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                    }

                    // 答案
                    if showAnswer {
                        if showDifficulty || showGrade { Divider().padding(.leading) }
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.Capture.answer)
                            TextEditor(text: $viewModel.answerText)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(Color(UIColor.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            // 答案图片选择
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
                            // HIG：破坏性操作用 warning 反馈；挂在 HStack（稳定父视图）上，
                            // 避免挂在 if let 条件分支内导致 modifier 随 View 移除而失效
                            .sensoryFeedback(.warning, trigger: viewModel.answerImage) { old, new in
                                old != nil && new == nil
                            }
                        }
                        .padding()
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}
