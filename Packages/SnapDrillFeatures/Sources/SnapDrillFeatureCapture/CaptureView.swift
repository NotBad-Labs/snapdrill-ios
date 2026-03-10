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
                        
                        Text("录入方式")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            // 1. Smart Scanner
                            CaptureMethodCard(
                                icon: "camera.viewfinder",
                                title: "拍照识题",
                                subtitle: "自动裁剪与识别",
                                color: .blue
                            ) {
                                viewModel.isShowingScanner = true
                            }
                            
                            // 2. Photo Library
                            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                                CaptureMethodCardContent(
                                    icon: "photo.on.rectangle",
                                    title: "相册导入",
                                    subtitle: "识别已有照片",
                                    color: .purple
                                )
                            }
                            .buttonStyle(.plain) // Important for Card look
                            
                            // 3. Manual
                            CaptureMethodCard(
                                icon: "keyboard",
                                title: "手动录入",
                                subtitle: "纯文本编辑",
                                color: .orange
                            ) {
                                // Navigate to result view with empty state
                                router.push(.scannerResult(content: "", image: nil))
                            }
                            
                            // 4. Clipboard
                            CaptureMethodCard(
                                icon: "doc.on.clipboard",
                                title: "粘贴板",
                                subtitle: "从剪贴板读取",
                                color: .gray
                            ) {
                                viewModel.pasteFromClipboard(router: router)
                            }

                        }
                        .padding(.horizontal)

                        // 5. PDF Import（独立全宽行，避免 2 列网格奇数不对称）
                        CaptureMethodCard(
                            icon: "doc.richtext",
                            title: "PDF 导入",
                            subtitle: "从文件选择 PDF",
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
                            Text("正在处理...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .navigationTitle("采集")
            .navigationDestination(for: CaptureDestination.self) { destination in
                switch destination {
                case .placeholder:
                    ContentUnavailableView("即将上线", systemImage: "clock")
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
            // 连续录入：保存成功后自动重新打开摄像头
            .onChange(of: router.shouldReopenScanner) { _, shouldReopen in
                if shouldReopen {
                    router.shouldReopenScanner = false
                    viewModel.isShowingScanner = true
                }
            }
            .onDisappear {
                viewModel.cancelOngoingTasks()
            }
            .alert("恢复草稿", isPresented: $viewModel.showDraftAlert) {
                Button("继续编辑") {
                    viewModel.startEditingDraft(router: router)
                }
                Button("放弃", role: .destructive) {
                    viewModel.clearDraft()
                }
            } message: {
                Text("检测到未保存的采集内容，是否恢复？")
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
                    viewModel.errorMessage = "选择文件失败: \(error.localizedDescription)"
                    viewModel.showErrorAlert = true
                }
            }
            .alert("错误", isPresented: $viewModel.showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
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
