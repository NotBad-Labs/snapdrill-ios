//
//  CaptureView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集功能主界面，提供拍照识题入口
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData
import PhotosUI
import UniformTypeIdentifiers

/// 采集功能界面
///
/// 提供拍照识题和题目录入功能的入口。
public struct CaptureView: View {
    
    // MARK: - Properties
    
    @Bindable private var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService
    
    @State private var viewModel = CaptureViewModel()
    /// 连续裁剪模式：是否正在显示裁剪器
    @State private var isShowingContinuousCropper = false
    
    /// 初始化采集视图
    /// - Parameter router: 注入的路由器
    public init(router: CaptureRouter) {
        self.router = router
    }
    
    // MARK: - Body
    
    /// 采集功能界面的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // 抽象网格渐变模拟（iOS 18+）
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -50, y: -50)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: proxy.size.width - 250, y: 100)
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text(L10n.Capture.entryMethodTitle)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            // 1. 智能扫描（先检查权限再打开相机）
                            CaptureMethodCard(
                                icon: "camera.viewfinder",
                                title: L10n.Capture.cameraTitle,
                                subtitle: L10n.Capture.cameraSubtitle,
                                color: .blue,
                                accessibilityHint: L10n.Accessibility.cameraHint
                            ) {
                                Task {
                                    let granted = await viewModel.checkCameraPermission()
                                    if granted {
                                        viewModel.isShowingScanner = true
                                    }
                                }
                            }
                            
                            // 2. 相册导入
                            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                                CaptureMethodCardContent(
                                    icon: "photo.on.rectangle",
                                    title: L10n.Capture.albumTitle,
                                    subtitle: L10n.Capture.albumSubtitle,
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain) // 保持卡片外观
                            .accessibleButton(label: L10n.Capture.albumTitle, hint: L10n.Accessibility.albumHint)
                            
                            // 3. 手动录入
                            CaptureMethodCard(
                                icon: "keyboard",
                                title: L10n.Capture.manualTitle,
                                subtitle: L10n.Capture.manualSubtitle,
                                color: .orange,
                                accessibilityHint: L10n.Accessibility.manualHint,
                                accessibilityID: "capture.manual"
                            ) {
                                // 以空状态导航到结果编辑页
                                router.push(.scannerResult(content: "", image: nil))
                            }
                            
                            // 4. 剪贴板粘贴
                            CaptureMethodCard(
                                icon: "doc.on.clipboard",
                                title: L10n.Capture.clipboardTitle,
                                subtitle: L10n.Capture.clipboardSubtitle,
                                color: .gray,
                                accessibilityHint: L10n.Accessibility.clipboardHint
                            ) {
                                viewModel.pasteFromClipboard(router: router)
                            }

                            // 5. 文档扫描
                            CaptureMethodCard(
                                icon: "doc.text.viewfinder",
                                title: L10n.Capture.docScanTitle,
                                subtitle: L10n.Capture.docScanSubtitle,
                                color: .green,
                                accessibilityHint: L10n.Accessibility.docScanHint
                            ) {
                                viewModel.isShowingDocumentScanner = true
                            }

                            // 6. PDF 导入
                            CaptureMethodCard(
                                icon: "doc.richtext",
                                title: L10n.Capture.pdfTitle,
                                subtitle: L10n.Capture.pdfSubtitle,
                                color: .red,
                                accessibilityHint: L10n.Accessibility.pdfHint
                            ) {
                                viewModel.isShowingPDFPicker = true
                            }

                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top)
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
            .navigationTitle(L10n.Capture.title)
            .navigationDestination(for: CaptureDestination.self) { destination in
                switch destination {
                case .placeholder:
                    ContentUnavailableView(L10n.Common.comingSoon, systemImage: "clock")
                case .scannerResult(let content, let image):
                    let resultViewModel = CaptureResultViewModel(
                        content: content,
                        image: image,
                        repositories: repositories,
                        ocrService: viewModel.ocrService,
                        analyticsService: analyticsService,
                        router: router
                    )
                    CaptureResultView(viewModel: resultViewModel)

                case .pdfPagePicker:
                    PDFPagePickerView(router: router, ocrService: viewModel.ocrService)

                case .scanPagePicker:
                    ScanPagePickerView(router: router, ocrService: viewModel.ocrService)
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
                    viewModel.loadPhoto(newItem, router: router)
                }
            }
            .onAppear {
                viewModel.checkDraftOnAppear()
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
                    router.shouldContinuousCrop = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(150))
                        isShowingContinuousCropper = true
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
                Button(L10n.Common.discard, role: .destructive) {
                    viewModel.clearDraft()
                }
            } message: {
                Text(viewModel.draftAlertMessage)
            }
            .fileImporter(
                isPresented: $viewModel.isShowingPDFPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
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

// MARK: - Subviews

// Button 和 PhotosPicker 共享的卡片内容视图
struct CaptureMethodCardContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CaptureMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let accessibilityHintText: String
    let accessibilityID: String?
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        accessibilityHint: String = "",
        accessibilityID: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.accessibilityHintText = accessibilityHint
        self.accessibilityID = accessibilityID
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            CaptureMethodCardContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .accessibleButton(label: title, hint: accessibilityHintText.isEmpty ? subtitle : accessibilityHintText)
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}

#Preview {
    @Bindable var router = CaptureRouter()
    return CaptureView(router: router)
}
