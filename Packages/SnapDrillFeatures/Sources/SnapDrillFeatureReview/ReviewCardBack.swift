//
//  ReviewCardBack.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾卡片背面：展示参考信息和编辑入口。
//

import SwiftUI
import SnapDrillData
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 回顾卡片背面：展示参考信息
struct ReviewCardBack: View {

    // MARK: - Properties

    let item: ArchiveItemModel
    let showsActions: Bool

    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }
    @State private var showingEditSheet = false
    @State private var loadedAnswerImage: UIImage?
    @State private var answerImageLoadFailed = false
    // 纯图片资料（content == nil）时，背面 header 同步展示图片，让用户看到上下文
    @State private var loadedQuestionImage: UIImage?

    // 用户偏好：背面卡片排版
    @AppStorage(UDKey.cardContextAlignment) private var alignmentRaw: String = "leading"
    @AppStorage(UDKey.cardContextFontSize) private var fontSizeRaw: Double = 16.0

    private var alignment: TextAlignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }

    private var frameAlignment: Alignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: fontSizeRaw, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(alignment)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                } else if let image = loadedQuestionImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibleImage(label: L10n.Accessibility.questionImage)
                } else {
                    Spacer()
                }

                if showsActions {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label(L10n.Library.editContent, systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                            .padding(12)
                            .contentShape(Circle())
                    }
                    .accessibilityIdentifier("review.card.back.more")
                    .accessibilityLabel(L10n.Accessibility.moreActions)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()
                .background(.quaternary)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let answerText = item.answerText, !answerText.isEmpty {
                        Text(answerText)
                            .font(.title3)
                            .fontWeight(.regular)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                    }

                    if let imagePath = item.answerImagePath {
                        if let uiImage = loadedAnswerImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .accessibleImage(label: L10n.Accessibility.answerImage)
                        } else if answerImageLoadFailed {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 150)
                                .overlay {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.title2)
                                            .foregroundStyle(.secondary)
                                        Text(L10n.Errors.imageLoadFailed)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 150)
                                .overlay(ProgressView())
                                .task {
                                    await loadAnswerImage(path: imagePath)
                                }
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color(UIColor.separator).opacity(0.12), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .task {
            await loadQuestionImage()
        }
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }

    // MARK: - Private Helpers

    private func loadQuestionImage() async {
        guard item.content == nil || item.content?.isEmpty == true,
              let path = item.imagePath else { return }
        if let image = await loadImage(from: path) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.loadedQuestionImage = image
            }
        }
    }

    private func loadAnswerImage(path: String) async {
        if let image = await loadImage(from: path) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.loadedAnswerImage = image
            }
        } else {
            self.answerImageLoadFailed = true
        }
    }

    private func loadImage(from path: String) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { [imageStorage] in
            imageStorage.loadDownsampledImage(path: path, maxLongSide: 800)
        }.value
    }
}
