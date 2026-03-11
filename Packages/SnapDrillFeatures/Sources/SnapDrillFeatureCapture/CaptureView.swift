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
                
                // Abstract Mesh Gradient Simulation (iOS 18+)
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
                            // 1. Smart Scanner
                            CaptureMethodCard(
                                icon: "camera.viewfinder",
                                title: L10n.Capture.cameraTitle,
                                subtitle: L10n.Capture.cameraSubtitle,
                                color: .blue
                            ) {
                                viewModel.isShowingScanner = true
                            }
                            
                            // 2. Photo Library
                            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                                CaptureMethodCardContent(
                                    icon: "photo.on.rectangle",
                                    title: L10n.Capture.albumTitle,
                                    subtitle: L10n.Capture.albumSubtitle,
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain) // Important for Card look
                            
                            // 3. Manual
                            CaptureMethodCard(
                                icon: "keyboard",
                                title: L10n.Capture.manualTitle,
                                subtitle: L10n.Capture.manualSubtitle,
                                color: .orange
                            ) {
                                // Navigate to result view with empty state
                                router.push(.scannerResult(content: "", image: nil))
                            }
                            
                            // 4. Clipboard
                            CaptureMethodCard(
                                icon: "doc.on.clipboard",
                                title: L10n.Capture.clipboardTitle,
                                subtitle: L10n.Capture.clipboardSubtitle,
                                color: .gray
                            ) {
                                viewModel.pasteFromClipboard(router: router)
                            }

                        }
                        .padding(.horizontal)

                        // 5. PDF Import（独立全宽行，避免 2 列网格奇数不对称）
                        CaptureMethodCard(
                            icon: "doc.richtext",
                            title: L10n.Capture.pdfTitle,
                            subtitle: L10n.Capture.pdfSubtitle,
                            color: .red
                        ) {
                            viewModel.isShowingPDFPicker = true
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top)
                }
                .scrollIndicators(.hidden)
                
                // Loading Overlay
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
                        ocrService: OCRService(),
                        analyticsService: analyticsService,
                        router: router
                    )
                    CaptureResultView(viewModel: resultViewModel)

                case .pdfPagePicker:
                    PDFPagePickerView(router: router)
                }
            }
            // Scanner Sheet
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
            }
            // Photo Picker Handling
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
                    // 精准区分：shouldContinuousCrop 在 saveResult 中同步设置且先于退栈，
                    // 若此标志为 false，说明是用户手动点返回，需释放原图内存
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
                Text(L10n.Capture.draftAlertMessage)
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
                case .failure(let error):
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
        }
    }
}

// MARK: - Subviews

// Helper for consistency between Button and PhotosPicker
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            CaptureMethodCardContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
    }
}

#Preview {
    @Bindable var router = CaptureRouter()
    return CaptureView(router: router)
}
