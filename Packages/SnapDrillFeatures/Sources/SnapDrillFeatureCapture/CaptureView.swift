//
//  CaptureView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集功能主界面，提供多种资料录入入口
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData
import PhotosUI
import UniformTypeIdentifiers
#if DEBUG
import UIKit
#endif

/// 采集功能界面，提供拍摄、导入与手动录入入口。
public struct CaptureView: View {
    
    // MARK: - Properties
    
    @Bindable private var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.profileManager) private var profileManager
    @Environment(\.analyticsService) private var analyticsService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var viewModel: CaptureViewModel
    private let draftService: CaptureDraftServiceProtocol
    private let activityTracker: AppActivityTracker
    /// 连续裁剪模式：是否正在显示裁剪器
    @State private var isShowingContinuousCropper = false
    @State private var activeMethod: CaptureMethod?
#if DEBUG
    @State private var didOpenUITestImageResult = false
    @State private var didOpenUITestPagePicker = false
    @State private var didPrepareUITestDraft = false
#endif
    private let tabBarBreathingRoom: CGFloat = 180
    
    public init(
        router: CaptureRouter,
        ocrService: OCRServiceProtocol,
        draftService: CaptureDraftServiceProtocol,
        activityTracker: AppActivityTracker
    ) {
        self.router = router
        self.draftService = draftService
        self.activityTracker = activityTracker
        _viewModel = State(
            initialValue: CaptureViewModel(
                ocrService: ocrService,
                draftService: draftService,
                activityTracker: activityTracker
            )
        )
    }

    private var methodColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible())]
        } else {
            [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
    
    // MARK: - Body
    
    /// 采集功能界面的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text(L10n.Capture.entryMethodTitle)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        GlassEffectContainer {
                        LazyVGrid(columns: methodColumns, spacing: 16) {
                            // 1. 智能扫描（先检查权限再打开相机）
                            CaptureMethodCard(
                                icon: "camera.viewfinder",
                                title: L10n.Capture.cameraTitle,
                                subtitle: L10n.Capture.cameraSubtitle,
                                color: .blue,
                                accessibilityHint: L10n.Accessibility.cameraHint,
                                accessibilityID: "capture.camera",
                                isBusy: activeMethod == .camera,
                                isDisabled: isInteractionDisabled
                            ) {
                                activeMethod = .camera
                                Task {
                                    let granted = await viewModel.checkCameraPermission()
                                    if granted {
                                        viewModel.isShowingScanner = true
                                    }
                                    activeMethod = nil
                                }
                            }
                            
                            // 2. 相册导入
                            let isAlbumProcessing = viewModel.isProcessing
                            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                                CaptureMethodCardContent(
                                    icon: "photo.on.rectangle",
                                    title: L10n.Capture.albumTitle,
                                    subtitle: L10n.Capture.albumSubtitle,
                                    color: .purple,
                                    isBusy: isAlbumProcessing
                                )
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                            .opacity(isInteractionDisabled ? 0.55 : 1)
                            .disabled(isInteractionDisabled)
                            .accessibleButton(label: L10n.Capture.albumTitle, hint: L10n.Accessibility.albumHint)
                            .accessibilityIdentifier("capture.album")
                            
                            // 3. 手动录入
                            CaptureMethodCard(
                                icon: "keyboard",
                                title: L10n.Capture.manualTitle,
                                subtitle: L10n.Capture.manualSubtitle,
                                color: .orange,
                                accessibilityHint: L10n.Accessibility.manualHint,
                                accessibilityID: "capture.manual",
                                isDisabled: isInteractionDisabled
                            ) {
                                // 以空状态导航到结果编辑页
                                router.push(
                                    .scannerResult(content: "", image: nil, draftToken: nil)
                                )
                            }
                            
                            // 4. 剪贴板粘贴
                            CaptureMethodCard(
                                icon: "doc.on.clipboard",
                                title: L10n.Capture.clipboardTitle,
                                subtitle: L10n.Capture.clipboardSubtitle,
                                color: .gray,
                                accessibilityHint: L10n.Accessibility.clipboardHint,
                                accessibilityID: "capture.clipboard",
                                isBusy: activeMethod == .clipboard,
                                isDisabled: isInteractionDisabled
                            ) {
                                activeMethod = .clipboard
                                viewModel.pasteFromClipboard(router: router)
                                activeMethod = nil
                            }

                            // 5. 文档扫描
                            CaptureMethodCard(
                                icon: "doc.text.viewfinder",
                                title: L10n.Capture.docScanTitle,
                                subtitle: L10n.Capture.docScanSubtitle,
                                color: .green,
                                accessibilityHint: L10n.Accessibility.docScanHint,
                                accessibilityID: "capture.documentScan",
                                isBusy: activeMethod == .documentScan,
                                isDisabled: isInteractionDisabled
                            ) {
                                activeMethod = .documentScan
                                viewModel.isShowingDocumentScanner = true
                                activeMethod = nil
                            }

                            // 6. PDF 导入
                            CaptureMethodCard(
                                icon: "doc.richtext",
                                title: L10n.Capture.pdfTitle,
                                subtitle: L10n.Capture.pdfSubtitle,
                                color: .red,
                                accessibilityHint: L10n.Accessibility.pdfHint,
                                accessibilityID: "capture.pdf",
                                isBusy: activeMethod == .pdf,
                                isDisabled: isInteractionDisabled
                            ) {
                                activeMethod = .pdf
                                viewModel.isShowingPDFPicker = true
                                activeMethod = nil
                            }

                        }
                        .padding(.horizontal)
                        } // GlassEffectContainer

                        Spacer()
                    }
                    .padding(.top)
                    .padding(.bottom, tabBarBreathingRoom)
                }
                .scrollIndicators(.hidden)
                
                // 加载中遮罩
                if viewModel.isProcessing {
                    Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                            Text(L10n.Common.processing)
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessible(label: L10n.Accessibility.processingOverlay)
                    }
                }
            }
            .accessibilityIdentifier("capture.root")
            .navigationTitle(L10n.Capture.title)
            .navigationDestination(for: CaptureDestination.self) { destination in
                switch destination {
                case .placeholder:
                    ContentUnavailableView(L10n.Common.comingSoon, systemImage: "clock")
                case .scannerResult(let content, let image, let draftToken):
                    let resultViewModel = CaptureResultViewModel(
                        content: content,
                        image: image,
                        draftToken: draftToken,
                        repositories: repositories,
                        ocrService: viewModel.ocrService,
                        analyticsService: analyticsService,
                        imageStorage: profileManager.activeImageStorage,
                        router: router,
                        draftService: draftService,
                        activityTracker: activityTracker
                    )
                    CaptureResultView(viewModel: resultViewModel)

                case .pdfPagePicker:
                    PDFPagePickerView(
                        router: router,
                        ocrService: viewModel.ocrService,
                        draftService: draftService,
                        activityTracker: activityTracker
                    )

                case .scanPagePicker:
                    ScanPagePickerView(
                        router: router,
                        ocrService: viewModel.ocrService,
                        draftService: draftService,
                        activityTracker: activityTracker
                    )
                }
            }
            // 扫描器全屏覆盖
            .fullScreenCover(isPresented: $viewModel.isShowingScanner) {
                SmartCameraView(
                    onCapture: { image in
                        viewModel.isShowingScanner = false
                        viewModel.processScannedImage(image, router: router)
                    },
                    onCancel: {
                        viewModel.isShowingScanner = false
                    }
                )
                .onAppear {
                    analyticsService.track(.cameraOpened, parameters: [:])
                }
            }
            // 文档扫描仪全屏覆盖
            .fullScreenCover(isPresented: $viewModel.isShowingDocumentScanner) {
                DocumentScannerView(
                    onCompletion: { images in
                        viewModel.isShowingDocumentScanner = false
                        // 标记来源为文档扫描（单页/多页均设置，供 performNavigation 判断）
                        router.scannedPages = images
                        if images.count == 1 {
                            // 单页直接走 OCR 流程
                            viewModel.processScannedImage(images[0], router: router)
                        } else {
                            // 多页推入页面选择器
                            router.push(.scanPagePicker)
                        }
                    },
                    onCancel: {
                        viewModel.isShowingDocumentScanner = false
                    },
                    onError: { error in
                        viewModel.isShowingDocumentScanner = false
                        SnapDrillLogger.capture.error("文档扫描失败: \(error.localizedDescription)")
                        viewModel.errorMessage = error.localizedDescription
                        viewModel.showErrorAlert = true
                    }
                )
            }
            // 相册选择器处理
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                if let newItem {
                    activeMethod = nil
                    viewModel.loadPhoto(newItem, router: router)
                } else {
                    activeMethod = nil
                }
            }
            .task(id: router.path.count) {
                await checkDraftAdmission()
            }
            .onAppear {
#if DEBUG
                if !didOpenUITestImageResult {
                    didOpenUITestImageResult = CaptureUITestFixtures.openImageResultIfRequested(
                        router: router
                    )
                }
                if !didOpenUITestPagePicker {
                    didOpenUITestPagePicker = CaptureUITestFixtures.openPagePickerIfRequested(
                        router: router
                    )
                }
#endif
            }
            // 连续录入：保存成功后自动重新打开摄像头（拍照模式）
            .onChange(of: router.shouldReopenScanner) { _, shouldReopen in
                if shouldReopen {
                    router.shouldReopenScanner = false
                    viewModel.isShowingScanner = true
                }
            }
            // 连续裁剪：保存成功后自动弹出裁剪器（相册导入模式，同一张原图裁剪不同区域）
            // 延迟弹出：等退栈动画完成后再呈现 fullScreenCover，避免同帧竞争
            .onChange(of: router.shouldContinuousCrop) { _, shouldCrop in
                if shouldCrop {
                    Task {
                        try? await Task.sleep(for: .milliseconds(150)) // best-effort: 等退栈动画完成，取消不影响正确性
                        isShowingContinuousCropper = ContinuousCropperPresentationPolicy.shouldPresent(
                            originalAlbumImage: router.originalAlbumImage
                        )
                        router.shouldContinuousCrop = false
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingContinuousCropper) {
                if let originalImage = router.originalAlbumImage {
                    ImageCropperView(
                        originalImage: originalImage,
                        onCrop: { croppedImage in
                            isShowingContinuousCropper = false
                            // 对裁剪结果做 OCR 后推入编辑页
                            viewModel.processScannedImage(croppedImage, router: router)
                        },
                        onCancel: {
                            // 用户点取消 = 结束连续裁剪模式
                            isShowingContinuousCropper = false
                            router.originalAlbumImage = nil
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    Color.clear
                        .accessibilityIdentifier("capture.continuousCropper.missingImageFallback")
                        .onAppear {
                            isShowingContinuousCropper = false
                        }
                }
            }
            .onDisappear {
                viewModel.cancelOngoingTasks()
            }
            // 导航栈回到根视图时释放 PDF 文档内存（不能在 PDFPagePickerView.onDisappear 中清理，
            // 因为 NavigationStack push 新页面时也会触发子视图的 onDisappear）
            .onChange(of: router.path) {
                if router.path.isEmpty {
                    router.pdfDocument = nil
                    router.scannedPages = nil
                    if !router.shouldContinuousCrop {
                        router.originalAlbumImage = nil
                    }
                }
            }
            .alert(L10n.Capture.draftAlertTitle, isPresented: $viewModel.showDraftAlert) {
                Button(L10n.Capture.draftContinue) {
                    viewModel.startEditingDraft(router: router)
                }
                .accessibilityIdentifier("capture.draft.continue")
                Button(L10n.Common.discard, role: .destructive) {
                    Task { await viewModel.clearDraft() }
                }
                .accessibilityIdentifier("capture.draft.discard")
            } message: {
                Text(viewModel.draftAlertMessage)
            }
            .alert(
                L10n.Capture.draftUnrecoverableTitle,
                isPresented: $viewModel.showUnrecoverableDraftAlert
            ) {
                if viewModel.pendingDraftFailure?.discardToken != nil {
                    Button(L10n.Common.discard, role: .destructive) {
                        Task { await viewModel.clearDraft() }
                    }
                }
                Button(L10n.Common.cancel, role: .cancel) { }
            } message: {
                Text(L10n.Capture.draftUnrecoverableMessage)
            }
            .fileImporter(
                isPresented: $viewModel.isShowingPDFPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                activeMethod = nil
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    viewModel.loadPDF(url, router: router)
                case .failure:
                    viewModel.errorMessage = L10n.Errors.filePickerFailed
                    viewModel.showErrorAlert = true
                }
            }
            .alert(L10n.Common.error, isPresented: $viewModel.showErrorAlert) {
                if viewModel.draftCheckNeedsRetry {
                    Button(L10n.Common.retry) {
                        Task { await checkDraftAdmission() }
                    }
                }
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            // PDF 大文件警告
            .alert(L10n.Capture.pdfFileTooLargeTitle, isPresented: $viewModel.showLargeFileAlert) {
                Button(L10n.Capture.pdfContinueAnyway) {
                    viewModel.confirmLargeFileImport(router: router)
                }
                Button(L10n.Common.cancel, role: .cancel) {
                    viewModel.pendingPDFURL = nil
                }
            } message: {
                Text(L10n.Capture.pdfFileTooLarge(viewModel.largeFileSizeMB))
            }
            // OCR 失败重试
            .alert(L10n.Capture.ocrFailedHint, isPresented: $viewModel.showOCRRetryAlert) {
                Button(L10n.Capture.ocrRetry) {
                    viewModel.retryOCR()
                }
                Button(L10n.Capture.ocrContinueEdit, role: .cancel) {
                    viewModel.skipOCRAndEdit()
                }
            }
            // 相机权限拒绝引导
            .alert(L10n.Errors.cameraPermissionDenied, isPresented: $viewModel.showCameraPermissionDenied) {
                Button(L10n.Common.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(L10n.Common.cancel, role: .cancel) { }
            } message: {
                Text(L10n.Errors.cameraPermissionHelp)
            }
        }
    }

}

private extension CaptureView {
    var isInteractionDisabled: Bool {
        viewModel.isProcessing || activeMethod != nil || viewModel.isDraftAdmissionBlocked
    }

    func checkDraftAdmission() async {
#if DEBUG
        if !didPrepareUITestDraft {
            didPrepareUITestDraft = true
            if await CaptureUITestFixtures.openDurableDraftIfRequested(
                router: router,
                draftService: draftService
            ) {
                return
            }
        }
#endif
        await viewModel.checkDraftOnAppear(router: router) { captureID in
            try repositories.archive.fetchModel(by: captureID) != nil
        }
    }
}
