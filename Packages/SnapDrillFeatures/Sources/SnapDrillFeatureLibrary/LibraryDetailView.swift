//
//  LibraryDetailView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
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
    @State private var shareImage: UIImage?
    @State private var isShowingShareCardSheet = false
    @State private var printAnchorView: UIView?
    @State private var isPrinting = false
    @State private var showPrintError = false

    @Environment(\.profileManager) private var profileManager
    @Environment(\.services) private var services
    @Environment(\.printPresenter) private var printPresenter
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

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
                    // 动态分类：每个有值的维度一行（维度名 + 值徽标），取代固定 学科/来源/标签/年级
                    ForEach(item.categoryValuesByDimension, id: \.dimension.id) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Text(entry.dimension.name)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 36, alignment: .leading)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(entry.values) { value in
                                        Text(value.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: value.colorHex).opacity(0.15))
                                            .foregroundStyle(Color(hex: value.colorHex))
                                            .clipShape(Capsule())
                                    }
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

                // 难度（年级等已并入上方动态维度展示）
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= item.difficulty ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(level <= item.difficulty ? .orange : .gray.opacity(0.3))
                        }
                    }
                    .accessibleGroup(label: L10n.Accessibility.starRating(difficulty: item.difficulty))
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
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
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
        .background {
            LibraryPrintAnchorView { view in
                if printAnchorView !== view {
                    printAnchorView = view
                }
            }
            .frame(width: 0, height: 0)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // 分享题目卡片
                    Button {
                        shareQuestionCard()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibleButton(label: L10n.Library.share)

                    // 单题快速打印
                    Button {
                        printSingleItem()
                    } label: {
                        Image(systemName: "printer")
                    }
                    .accessibleButton(label: L10n.Library.printSingle)
                    .disabled(isPrinting)

                    Button(L10n.Common.edit) {
                        isEditing = true
                    }
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
        .sheet(isPresented: $isShowingShareCardSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .alert(L10n.Errors.pdfGenerateFailed, isPresented: $showPrintError) {
            Button(L10n.Common.ok, role: .cancel) {}
        }
    }

    // MARK: - 分享题目卡片

    private func shareQuestionCard() {
        let cardView = ShareCardView(
            content: item.content,
            image: loadedImage,
            subject: item.subjectCategoryName ?? "",
            difficulty: item.difficulty,
            tags: item.tagCategoryNames
        )

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UITraitCollection.current.displayScale
        guard let uiImage = renderer.uiImage else {
            SnapDrillLogger.generic.error("分享卡片图片渲染失败")
            return
        }
        shareImage = uiImage
        isShowingShareCardSheet = true
    }

    // MARK: - 单题快速打印

    private func printSingleItem() {
        guard !isPrinting else { return }
        Task {
            let snapshot = item.toExportSnapshot()
            let storage = imageStorage
            let service = services.pdfExport
            let activityTracker = services.activityTracker
            let presenter = printPresenter
            let options = PDFExportOptions(itemsPerPage: 1)
            isPrinting = true
            activityTracker.begin(.printing)
            defer {
                activityTracker.end(.printing)
                isPrinting = false
            }
            do {
                let data = try await service.createPDF(
                    from: [snapshot],
                    options: options,
                    imageProvider: { path in storage.loadImage(path: path) }
                )
                guard let printAnchorView else {
                    throw PrintError.presentationFailed
                }
                _ = try await presenter.present(
                    pdfData: data,
                    jobName: L10n.Library.detail,
                    anchor: .view(printAnchorView)
                )
            } catch {
                SnapDrillLogger.generic.error("单题打印失败: \(error.localizedDescription)")
                showPrintError = true
            }
        }
    }
}

private struct LibraryPrintAnchorView: UIViewRepresentable {
    let onResolve: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        resolve(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        resolve(uiView)
    }

    private func resolve(_ view: UIView) {
        DispatchQueue.main.async {
            onResolve(view)
        }
    }
}

/// 系统分享表的 UIKit 桥接
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "Sample Domain Question")
        container.mainContext.insert(i)
        return i
    }()
    NavigationStack {
        LibraryDetailView(router: LibraryRouter(), item: item)
    }
    .modelContainer(container)
}
