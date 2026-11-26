import PhotosUI
import SwiftUI

/// Step 1: Perspective corner adjustment & enhancement mode selector.
struct CaptureCorrectionStepView: View {
    let page: CapturePage?
    let pages: [CapturePage]
    @Binding var currentPageIndex: Int
    @Binding var isEditingCorners: Bool
    let cameraAuthState: CameraAuthorizationState
    let maxPhotoCount: Int
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    let onUpdateCornersLive: (UUID, QuadCorners) -> Void
    let onCommitCorners: (UUID, QuadCorners, Bool) -> Void
    let onSelectEnhancement: (UUID, ImageEnhancementMode) -> Void
    let onSelectPage: (Int) -> Void
    let onRemovePage: (UUID) -> Void
    let onOpenCamera: () -> Void
    let onNextStep: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let page {
                Picker("Step 1 View Mode", selection: $isEditingCorners) {
                    Text("Preview Sheet").tag(false)
                    Text("Adjust Corners").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, SnapDrillTheme.screenPadding)

                let displayData = isEditingCorners ? page.rawImageData : page.enhancedImageData
                if let uiImage = UIImage(data: displayData) {
                    GeometryReader { geo in
                        let imageFrame = AspectFitCalculator.fittedRect(imageSize: uiImage.size, in: geo.size)

                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)

                            // Guarantee PerspectiveCornerOverlay ALWAYS maps over unwarped rawImageData coordinates.
                            if isEditingCorners {
                                PerspectiveCornerOverlay(
                                    corners: Binding(
                                        get: { page.corners },
                                        set: { onUpdateCornersLive(page.id, $0) }
                                    ),
                                    imageFrame: imageFrame
                                ) { committed in
                                    onCommitCorners(page.id, committed, false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }

                if isEditingCorners {
                    Button {
                        onCommitCorners(page.id, page.corners, true)
                    } label: {
                        Label("Apply Corners & Straighten", systemImage: "checkmark.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, SnapDrillTheme.screenPadding)
                } else {
                    HStack(spacing: 8) {
                        ForEach(ImageEnhancementMode.allCases) { mode in
                            let selected = page.enhancementMode == mode
                            Button {
                                onSelectEnhancement(page.id, mode)
                            } label: {
                                Text(mode.localizedTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.cardSurface)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(selected ? Color.clear : SnapDrillTheme.ruledLine, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, SnapDrillTheme.screenPadding)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomActionBarContainer {
                VStack(spacing: 10) {
                    CapturePageThumbnailStrip(
                        pages: pages,
                        currentPageIndex: currentPageIndex,
                        showBoxCountBadges: false,
                        allowAddingMore: true,
                        cameraAuthState: cameraAuthState,
                        maxPhotoCount: maxPhotoCount,
                        selectedPhotoItems: $selectedPhotoItems,
                        onSelectPage: onSelectPage,
                        onRemovePage: onRemovePage,
                        onOpenCamera: onOpenCamera
                    )

                    Button(action: onNextStep) {
                        Text("Next: Frame Questions")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Step 2: Single-page multi-box and multi-page question framing.
struct CaptureCroppingStepView: View {
    let page: CapturePage?
    let pages: [CapturePage]
    let totalBoxCount: Int
    let currentPageIndex: Int
    @Binding var activeBoxID: UUID?
    let maxBoxesPerPage: Int
    let isPro: Bool
    let cameraAuthState: CameraAuthorizationState
    let maxPhotoCount: Int
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    let onUpdateBox: (UUID, CaptureCropBox) -> Void
    let onDeleteBox: (UUID, UUID) -> Void
    let onAddBox: (UUID) -> Void
    let onSmartFrame: (UUID) -> Void
    let onDragEnded: () -> Void
    let onSelectPage: (Int) -> Void
    let onRemovePage: (UUID) -> Void
    let onNextStep: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let page, let uiImage = UIImage(data: page.enhancedImageData) {
                GeometryReader { geo in
                    let imageFrame = AspectFitCalculator.fittedRect(imageSize: uiImage.size, in: geo.size)

                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        MultiBoxCropOverlay(
                            boxes: page.boxes,
                            activeBoxID: activeBoxID,
                            imageFrame: imageFrame,
                            onSelectBox: { activeBoxID = $0 },
                            onUpdateBox: { onUpdateBox(page.id, $0) },
                            onDeleteBox: { onDeleteBox(page.id, $0) },
                            onDragEnded: onDragEnded
                        )
                    }
                }
                .padding(.horizontal, 12)

                HStack(spacing: 10) {
                    Button {
                        onAddBox(page.id)
                    } label: {
                        Label("Add Question (\(page.boxes.count)/10)", systemImage: "plus.rectangle.on.rectangle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(page.boxes.count >= maxBoxesPerPage)

                    Button {
                        onSmartFrame(page.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isPro ? "sparkles" : "lock.fill")
                            Text("Smart Frame")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, SnapDrillTheme.screenPadding)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomActionBarContainer {
                VStack(spacing: 10) {
                    CapturePageThumbnailStrip(
                        pages: pages,
                        currentPageIndex: currentPageIndex,
                        showBoxCountBadges: true,
                        allowAddingMore: false,
                        cameraAuthState: cameraAuthState,
                        maxPhotoCount: maxPhotoCount,
                        selectedPhotoItems: $selectedPhotoItems,
                        onSelectPage: onSelectPage,
                        onRemovePage: onRemovePage,
                        onOpenCamera: {}
                    )

                    Button(action: onNextStep) {
                        Text("Next: Clean & Save (\(totalBoxCount))")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Shared horizontal page thumbnail strip with async off-main-actor decoding and single-page deletion.
struct CapturePageThumbnailStrip: View {
    let pages: [CapturePage]
    let currentPageIndex: Int
    let showBoxCountBadges: Bool
    let allowAddingMore: Bool
    let cameraAuthState: CameraAuthorizationState
    let maxPhotoCount: Int
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let onSelectPage: (Int) -> Void
    let onRemovePage: (UUID) -> Void
    let onOpenCamera: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { idx, page in
                    let selected = idx == currentPageIndex
                    ZStack(alignment: .topTrailing) {
                        Button {
                            onSelectPage(idx)
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                CapturePageThumbnailView(
                                    imageData: page.enhancedImageData,
                                    revisionKey: "\(page.id.uuidString)-\(page.enhancementMode.rawValue)-\(page.enhancedImageData.count)"
                                )
                                .frame(width: 48, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.ruledLine, lineWidth: selected ? 2.5 : 1)
                                )

                                if showBoxCountBadges {
                                    Text("\(page.boxes.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(SnapDrillTheme.inkBlue, in: Capsule())
                                        .offset(x: 3, y: 3)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Page \(idx + 1)"))
                        .contextMenu {
                            Button(role: .destructive) {
                                onRemovePage(page.id)
                            } label: {
                                Label("Remove Page", systemImage: "trash")
                            }
                        }

                        if selected && pages.count > 1 {
                            Button {
                                onRemovePage(page.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: 8, y: -8)
                            .accessibilityLabel(String(localized: "Remove Page \(idx + 1)"))
                        }
                    }
                    .padding(.top, 6)
                }

                if allowAddingMore && pages.count < maxPhotoCount {
                    if cameraAuthState == .authorized || cameraAuthState == .notDetermined {
                        Button(action: onOpenCamera) {
                            Image(systemName: "camera.badge.ellipsis")
                                .frame(width: 48, height: 60)
                                .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .accessibilityLabel(String(localized: "Capture Another Page"))
                        .padding(.top, 6)
                    }

                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: maxPhotoCount - pages.count,
                        matching: .images
                    ) {
                        Image(systemName: "plus.rectangle.on.folder")
                            .frame(width: 48, height: 60)
                            .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .accessibilityLabel(String(localized: "Import More Photos"))
                    .padding(.top, 6)
                }
            }
            .padding(.trailing, 8)
        }
    }
}

/// Decodes page strip thumbnails off the main actor via ImageIO so 10-page batches stay smooth.
struct CapturePageThumbnailView: View {
    let imageData: Data
    let revisionKey: String

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                SnapDrillTheme.elevatedSurface
            }
        }
        .task(id: revisionKey) {
            let data = imageData
            let decoded = await Task.detached(priority: .utility) {
                CapturePipelineFactory.makePageThumbnail(from: data, maxPixel: 160)
            }.value
            guard !Task.isCancelled else { return }
            thumbnail = decoded
        }
    }
}
