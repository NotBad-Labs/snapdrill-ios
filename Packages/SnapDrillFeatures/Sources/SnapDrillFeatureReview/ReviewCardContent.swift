//
//  ReviewCardContent.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾卡片的内容视图，展示原内容和参考信息（翻转后）。
//

import SwiftUI
import SwiftData
import SnapDrillData
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 回顾卡片正面：展示原内容
struct ReviewCardFront: View {

    // MARK: - Properties

    let item: ReviewItemModel
    let showsActions: Bool

    @State private var showingEditSheet = false
    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }
    @State private var loadedImage: UIImage?

    // 用户偏好：正面卡片排版
    @AppStorage(UDKey.cardFrontAlignment) private var alignmentRaw: String = "leading"
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

            // 原内容图片（纯图片或图文混合）
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .accessibleImage(label: L10n.Accessibility.questionImage)
            }

            // 原内容文字
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: fontSizeRaw, weight: .semibold))
                    .multilineTextAlignment(alignment)
                    .lineSpacing(7)
                    .padding(.horizontal, 24)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }

            Spacer()

            // 元数据底栏
            HStack(spacing: 8) {
                // 分类徽标（动态维度：主分类维度首值，无则取首个有值维度首值，再无则不显示）
                if let categoryLabel = item.primaryCategoryName
                    ?? item.categoryValuesByDimension.first?.values.first?.name {
                    Text(categoryLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.10))
                        .clipShape(Capsule())
                        .accessibilityLabel("\(L10n.Settings.fieldCategory)：\(categoryLabel)")
                }

                // 难度指示器
                let starCount = item.difficultyValue.starCount
                if starCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<starCount, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.10))
                    .clipShape(Capsule())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L10n.Accessibility.starRating(difficulty: starCount))
                }

                // 标签（动态维度：标签维度值）
                let tagNames = item.tagCategoryNames
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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(L10n.Capture.tags)：\(tagNames.joined(separator: "、"))")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
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
        .overlay(alignment: .topTrailing) {
            if showsActions {
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
                .accessibilityIdentifier("review.card.front.more")
                .accessibilityLabel(L10n.Accessibility.moreActions)
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
        // 卡片显示区域约 400px，降采样到 800px 足够 2x Retina 清晰度，
        // 避免加载 2000px+ 全分辨率图片（每张 ~8-12MB 解码后内存）
        let image = await Task.detached(priority: .userInitiated) { [imageStorage] in
            imageStorage.loadDownsampledImage(path: path, maxLongSide: 800)
        }.value
        loadedImage = image
    }
}

// MARK: - Previews

#Preview("卡片正面") {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。")
        container.mainContext.insert(i)
        return i
    }()
    ReviewCardFront(item: item, showsActions: true)
        .frame(height: 400)
        .padding()
        .modelContainer(container)
}

#Preview("卡片背面") {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(
            content: "已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。",
            answerText: "∠B = ∠C = (180° - 36°) / 2 = 72°"
        )
        container.mainContext.insert(i)
        return i
    }()
    ReviewCardBack(item: item, showsActions: true)
        .frame(height: 400)
        .padding()
        .modelContainer(container)
}
