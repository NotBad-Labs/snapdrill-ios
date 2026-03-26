//
//  LibraryDetailView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  错题详情页，展示题目的完整信息（原题、答案、解析）。
//

import SwiftUI
import SwiftData
import SnapDrillData
import SnapDrillUI
import SnapDrillCore

/// 题目详情视图
struct LibraryDetailView: View {

    // MARK: - Properties

    @Bindable var router: LibraryRouter

    /// 要展示的题目数据模型
    let item: ReviewItemModel

    @State private var isEditing = false
    @State private var showingFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var loadedImage: UIImage?
    @State private var loadedAnswerImage: UIImage?

    private let imageStorage = ImageStorage()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Header（异步加载，避免阻塞主线程）
                if item.imagePath != nil {
                    if let image = loadedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            .onTapGesture {
                                fullScreenImage = image
                                showingFullScreenImage = true
                            }
                            .accessibleImage(label: L10n.Accessibility.questionImage)
                            .accessibilityHint(L10n.Accessibility.tapToEnlarge)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 200)
                            .overlay(ProgressView())
                            .padding(.horizontal)
                    }
                }

                // 元信息
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // 学科徽标
                        Text(item.subject)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())

                        // 来源徽标
                        Text(item.source)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())

                        Spacer()
                    }
                    .accessibleGroup(label: L10n.Accessibility.metadataGroup(subject: item.subject, source: item.source, difficulty: item.difficulty))

                    let tagNames = (item.tags ?? []).map { $0.name }
                    if !tagNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tagNames, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    HStack {
                        Label(item.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if item.isScheduled {
                            Text("\(L10n.Library.nextReview): \(item.nextReviewAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else {
                            Text(L10n.Library.notScheduled)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Content（纯图片题时 content 为 nil，跳过渲染）
                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.horizontal)
                }

                // 难度与年级
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= item.difficulty ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(level <= item.difficulty ? .orange : .gray.opacity(0.3))
                        }
                    }
                    .accessibleGroup(label: L10n.Accessibility.starRating(difficulty: item.difficulty))

                    if !item.grade.isEmpty {
                        Text(item.grade)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)

                // 答案区
                if item.answerText.map({ !$0.isEmpty }) ?? false || item.answerImagePath != nil {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label(L10n.Library.answerSection, systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)

                        if let answerText = item.answerText, !answerText.isEmpty {
                            Text(answerText)
                                .font(.body)
                                .lineSpacing(6)
                                .padding(.horizontal)
                        }

                        if item.answerImagePath != nil {
                            if let answerImage = loadedAnswerImage {
                                Image(uiImage: answerImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        fullScreenImage = answerImage
                                        showingFullScreenImage = true
                                    }
                                    .accessibleImage(label: L10n.Accessibility.answerImage)
                                    .accessibilityHint(L10n.Accessibility.tapToEnlarge)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(height: 150)
                                    .overlay(ProgressView())
                                    .padding(.horizontal)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.top)
        }
        .task(id: item.imagePath) {
            guard let path = item.imagePath else { loadedImage = nil; return }
            let image = await imageStorage.loadImageAsync(path: path)
            if !Task.isCancelled { loadedImage = image }
        }
        .task(id: item.answerImagePath) {
            guard let path = item.answerImagePath else { loadedAnswerImage = nil; return }
            let image = await imageStorage.loadImageAsync(path: path)
            if !Task.isCancelled { loadedAnswerImage = image }
        }
        .navigationTitle(L10n.Library.detail)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.Common.edit) {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            LibraryEditView(item: item)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let image = fullScreenImage {
                FullScreenImageView(image: image) {
                    showingFullScreenImage = false
                }
            }
        }
    }

}

#Preview {
    let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, TagModel.self, GradeModel.self])
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "Sample Domain Question", subject: "Math")
        container.mainContext.insert(i)
        return i
    }()
    NavigationStack {
        LibraryDetailView(router: LibraryRouter(), item: item)
    }
    .modelContainer(container)
}
