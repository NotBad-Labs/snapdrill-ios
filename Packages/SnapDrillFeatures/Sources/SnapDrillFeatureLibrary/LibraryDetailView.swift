//
//  LibraryDetailView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  资料详情页，展示条目的完整信息。
//

import SwiftUI
import SwiftData
import SnapDrillData
import SnapDrillUI
import SnapDrillCore

/// 资料详情视图
struct LibraryDetailView: View {

    // MARK: - Properties

    @Bindable var router: LibraryRouter

    /// 要展示的资料数据模型
    let item: ArchiveItemModel

    @State private var isEditing = false
    @State private var fullScreenImage: UIImage?
    @State private var loadedImage: UIImage?
    @State private var loadedAnswerImage: UIImage?
    @State private var shareImage: UIImage?
    @State private var isShowingShareCardSheet = false
    @State private var printAnchorView: UIView?
    @State private var isAnswerExpanded = false
    @State private var isSharing = false
    @State private var isPrinting = false
    @State private var showShareError = false
    @State private var showPrintError = false
    @State private var printErrorMessage = L10n.Library.printFailed

    @Environment(\.profileManager) private var profileManager
    @Environment(\.services) private var services
    @Environment(\.printPresenter) private var printPresenter
    private static let answerContentScrollID = "library.detail.answerContentScroll"
    private let tabBarBreathingRoom: CGFloat = 150
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // Image Header（异步加载，避免阻塞主线程）
                if item.imagePath != nil {
                    if let image = loadedImage {
                        Button {
                            fullScreenImage = image
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibleButton(
                            label: L10n.Accessibility.questionImage,
                            hint: L10n.Accessibility.tapToEnlarge
                        )
                        .accessibilityIdentifier("library.detail.questionImage")
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
                    // 动态分类：每个有值的维度一行（维度名 + 值徽标），取代固定分类/来源/标签/级别
                    ForEach(item.categoryValuesByDimension, id: \.dimension.id) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Text(entry.dimension.name)
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                                .frame(minWidth: 36, alignment: .leading)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(entry.values) { value in
                                        Text(value.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(.secondarySystemGroupedBackground))
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Label(item.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        if LibraryReleaseSurface.exposesOptionalCapabilities {
                            Spacer()

                            if item.isScheduled {
                                Text("\(L10n.Library.nextReview): \(item.nextReviewAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            } else {
                                Text(L10n.Library.notScheduled)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Content（纯图片条目时 content 为 nil，跳过渲染）
                if let content = item.content, !content.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(L10n.Library.questionText, systemImage: "doc.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(content)
                            .font(.body.weight(.medium))
                            .lineSpacing(7)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
                }

                // 答案与备注区：默认隐藏，避免从列表进入详情时直接泄露答案。
                if hasAnswerContent {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.snappy(duration: 0.22)) {
                                isAnswerExpanded.toggle()
                            }
                            if isAnswerExpanded {
                                DispatchQueue.main.async {
                                    withAnimation(.snappy(duration: 0.22)) {
                                        scrollProxy.scrollTo(Self.answerContentScrollID, anchor: .top)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .frame(width: 34, height: 34)
                                    .background(.orange.opacity(0.14))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(L10n.Library.answerSection)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(L10n.Library.answerPrivacyHint)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isAnswerExpanded ? 180 : 0))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibleButton(
                            label: isAnswerExpanded ? L10n.Accessibility.hideAnswer : L10n.Accessibility.showAnswer,
                            hint: L10n.Library.answerPrivacyHint
                        )
                        .accessibilityIdentifier("library.detail.answerToggle")

                        if isAnswerExpanded {
                            AnswerContentView(
                                item: item,
                                loadedAnswerImage: loadedAnswerImage,
                                onTapImage: { answerImage in
                                    fullScreenImage = answerImage
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .id(Self.answerContentScrollID)
                            .accessibilityIdentifier("library.detail.answerContent")
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: tabBarBreathingRoom)
                .allowsHitTesting(false)
        }
        .accessibilityIdentifier("library.detail.root")
        .task(id: item.imagePath) {
            guard let path = item.imagePath else { loadedImage = nil; return }
            let image = await imageStorage.loadImageAsync(path: path)
            if !Task.isCancelled { loadedImage = image }
        }
        .task(id: answerImageTaskID) {
            guard isAnswerExpanded, let path = item.answerImagePath else {
                loadedAnswerImage = nil
                return
            }
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
                    if LibraryReleaseSurface.exposesOptionalCapabilities {
                        Button {
                            shareQuestionCard()
                        } label: {
                            if isSharing {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .accessibleButton(label: L10n.Library.share)
                        .accessibilityIdentifier("library.detail.shareButton")
                        .disabled(isSharing)

                        Button {
                            printSingleItem()
                        } label: {
                            if isPrinting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "printer")
                            }
                        }
                        .accessibleButton(label: L10n.Library.printSingle)
                        .accessibilityIdentifier("library.detail.printButton")
                        .disabled(isPrinting)
                    }

                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(L10n.Common.edit)
                    .accessibilityIdentifier("library.detail.editButton")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            LibraryEditView(item: item)
        }
        .fullScreenCover(isPresented: isShowingFullScreenImage) {
            if let image = fullScreenImage {
                FullScreenImageView(image: image) {
                    fullScreenImage = nil
                }
            }
        }
        .sheet(isPresented: $isShowingShareCardSheet) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .alert(L10n.Library.shareFailed, isPresented: $showShareError) {
            Button(L10n.Common.ok, role: .cancel) {}
        }
        .alert(L10n.Library.printFailed, isPresented: $showPrintError) {
            Button(L10n.Common.retry) { printSingleItem() }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(printErrorMessage)
        }
    }

    private var hasAnswerContent: Bool {
        (item.answerText?.isEmpty == false) || item.answerImagePath != nil
    }

    private var answerImageTaskID: String {
        guard isAnswerExpanded else { return "collapsed" }
        return item.answerImagePath ?? "expanded-no-image"
    }

    private var isShowingFullScreenImage: Binding<Bool> {
        Binding(
            get: { fullScreenImage != nil },
            set: { isPresented in
                if !isPresented {
                    fullScreenImage = nil
                }
            }
        )
    }

    // MARK: - 分享题目卡片

    private func shareQuestionCard() {
        guard !isSharing else { return }
        isSharing = true
        defer { isSharing = false }

        let cardView = ShareCardView(
            content: item.content,
            image: loadedImage,
            category: item.primaryCategoryName ?? "",
            tags: item.tagCategoryNames
        )

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UITraitCollection.current.displayScale
        guard let uiImage = renderer.uiImage else {
            SnapDrillLogger.generic.error("分享卡片图片渲染失败")
            showShareError = true
            return
        }
        shareImage = uiImage
        isShowingShareCardSheet = true
    }

    // MARK: - 单题快速打印

    private func printSingleItem() {
        guard !isPrinting else { return }
        printErrorMessage = L10n.Library.printFailed
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
                if let exportError = error as? PDFExportError {
                    printErrorMessage = exportError.localizedDescription
                }
                showPrintError = true
            }
        }
    }
}

private struct AnswerContentView: View {
    let item: ArchiveItemModel
    let loadedAnswerImage: UIImage?
    let onTapImage: (UIImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let answerText = item.answerText, !answerText.isEmpty {
                Text(answerText)
                    .font(.body)
                    .lineSpacing(6)
                    .textSelection(.enabled)
            }

            if item.answerImagePath != nil {
                if let answerImage = loadedAnswerImage {
                    Button {
                        onTapImage(answerImage)
                    } label: {
                        Image(uiImage: answerImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibleButton(
                        label: L10n.Accessibility.answerImage,
                        hint: L10n.Accessibility.tapToEnlarge
                    )
                    .accessibilityIdentifier("library.detail.answerImage")
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 150)
                        .overlay(ProgressView())
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

#if DEBUG
#Preview {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ArchiveItemModel = {
        let i = ArchiveItemModel(content: "Sample Domain Question")
        container.mainContext.insert(i)
        return i
    }()
    NavigationStack {
        LibraryDetailView(router: LibraryRouter(), item: item)
    }
    .modelContainer(container)
    .environment(\.services, MockServiceContainer())
}
#endif
