//
//  ReviewCardContent.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习卡片的内容视图，展示题目和答案（翻转后）。
//

import SwiftUI
import SwiftData
import SnapDrillData
import SnapDrillCore
import SnapDrillFeatureLibrary

/// 复习卡片正面：展示题目
struct ReviewCardFront: View {

    // MARK: - Properties

    let item: ReviewItemModel

    @State private var showingEditSheet = false
    private let imageStorage = ImageStorage()
    @State private var loadedImage: UIImage?

    // 用户偏好：正面卡片排版
    @AppStorage(UDKey.cardFrontAlignment) private var alignmentRaw: String = "center"
    @AppStorage(UDKey.cardFrontFontSize) private var fontSizeRaw: Double = 32.0

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

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()

            // 题目图片（纯图片题或图文混合）
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
            }

            // 题目文字
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: fontSizeRaw, weight: .bold, design: .serif))
                    .multilineTextAlignment(alignment)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }

            Spacer()

            // Metadata Footer
            HStack(spacing: 8) {
                // 学科徽标
                Text(item.subject)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.8))
                    .clipShape(Capsule())

                // 难度指示器
                let starCount = item.difficultyValue.starCount
                if starCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<starCount, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }

                // 标签
                let tagNames = (item.tags ?? []).map { $0.name }
                if !tagNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(tagNames, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label(L10n.Library.editQuestion, systemImage: "pencil")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .padding(24)
                    .contentShape(Circle())
            }
        }
        .task {
            await loadFrontImage()
        }
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }

    // MARK: - Private Helpers

    private func loadFrontImage() async {
        guard let path = item.imagePath else { return }
        let image = await Task.detached(priority: .userInitiated) {
            imageStorage.loadImage(path: path)
        }.value
        loadedImage = image
    }
}

/// 复习卡片背面：展示答案
struct ReviewCardBack: View {

    // MARK: - Properties

    let item: ReviewItemModel

    private let imageStorage = ImageStorage()
    @State private var showingEditSheet = false
    @State private var loadedAnswerImage: UIImage?
    // 纯图片题（content == nil）时，背面 header 同步展示题目图，让用户记得题目是什么
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
                        .font(.system(size: fontSizeRaw, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(alignment)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: frameAlignment)
                } else if let image = loadedQuestionImage {
                    // 纯图片题：在背面 header 展示题目图，让用户看到题目上下文
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }

                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(L10n.Library.editContent, systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue.opacity(0.8))
                        .padding(12)
                        .contentShape(Circle())
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
                            .font(.system(size: 20, weight: .regular, design: .default))
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
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.1), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
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
        }
    }

    private func loadImage(from path: String) async -> UIImage? {
        // 显式捕获 imageStorage，避免隐式捕获 self
        await Task.detached(priority: .userInitiated) { [imageStorage] in
            imageStorage.loadImage(path: path)
        }.value
    }
}

// MARK: - Previews

#Preview("卡片正面") {
    let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, TagModel.self, GradeModel.self])
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。", subject: "数学")
        container.mainContext.insert(i)
        return i
    }()
    ReviewCardFront(item: item)
        .frame(height: 400)
        .padding()
        .modelContainer(container)
}

#Preview("卡片背面") {
    let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, TagModel.self, GradeModel.self])
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(
            content: "已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。",
            subject: "数学",
            answerText: "∠B = ∠C = (180° - 36°) / 2 = 72°"
        )
        container.mainContext.insert(i)
        return i
    }()
    ReviewCardBack(item: item)
        .frame(height: 400)
        .padding()
        .modelContainer(container)
}
