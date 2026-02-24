//
//  CaptureView.swift
//  NotBadFeatureCapture
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集功能主界面，提供拍照识题入口
//

import SwiftUI
import Observation
import NotBadCore
import NotBadUI
import NotBadData
import SwiftData
import PhotosUI

/// 采集功能界面
///
/// 提供拍照识题和题目录入功能的入口。
public struct CaptureView: View {
    @Bindable private var router: CaptureRouter
    @Environment(\.modelContext) private var modelContext
    
    // Scanner State
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    
    // Photo Picker State
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // Service
    private let ocrService = OCRService()
    
    @State private var isViewActive = false
    
    // Draft Recovery State
    @State private var showDraftAlert = false
    @State private var pendingDraft: CaptureDraftService.Draft?
    
    // Error State
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    /// 初始化采集视图
    /// - Parameter router: 注入的路由器
    public init(router: CaptureRouter) {
        self.router = router
    }
    
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
                                isShowingScanner = true
                            }
                            
                            // 2. Photo Library
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
                                if let string = UIPasteboard.general.string {
                                    router.push(.scannerResult(content: string, image: nil))
                                } else {
                                    // Feedback for empty clipboard?
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
                .scrollIndicators(.hidden)
                
                // Loading Overlay
                if isProcessing {
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
                    CaptureResultView(router: router, content: content, image: image)
                }
            }
            // Scanner Sheet
            .fullScreenCover(isPresented: $isShowingScanner) {
                SmartCameraView(
                    onCapture: { image in
                        isShowingScanner = false
                        processScannedImage(image)
                    },
                    onCancel: {
                        isShowingScanner = false
                    }
                )
            }
            // Photo Picker Handling
            .onChange(of: selectedPhotoItem) { _, newItem in
                if let newItem {
                    loadPhoto(newItem)
                }
            }
            .onAppear {
                isViewActive = true
                // Check for draft on appear
                if let draft = CaptureDraftService.shared.loadDraft() {
                    pendingDraft = draft
                    showDraftAlert = true
                }
            }
            .onDisappear {
                isViewActive = false
            }
            .alert("恢复草稿", isPresented: $showDraftAlert) {
                Button("继续编辑") {
                    if let draft = pendingDraft {
                        router.push(.scannerResult(content: draft.content, image: draft.image))
                        CaptureDraftService.shared.clearDraft()
                    }
                    pendingDraft = nil
                }
                Button("放弃", role: .destructive) {
                    CaptureDraftService.shared.clearDraft()
                    pendingDraft = nil
                }
            } message: {
                Text("检测到未保存的采集内容，是否恢复？")
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadPhoto(_ item: PhotosPickerItem) {
        isProcessing = true
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Determine if we need OCR
                await processImageOCR(image)
            } else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "图片加载失败，请重试"
                    showErrorAlert = true
                }
            }
        }
        selectedPhotoItem = nil // Reset picker
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessing = true
        Task {
            await processImageOCR(image)
        }
    }
    
    private func processImageOCR(_ image: UIImage) async {
        do {
            guard let cgImage = image.cgImage else {
                throw OCRError.invalidImage
            }
            let text = try await ocrService.recognizeText(from: cgImage)
            await MainActor.run {
                isProcessing = false
                router.push(.scannerResult(content: text, image: image))
            }
        } catch {
            print("OCR Error: \(error)")
            await MainActor.run {
                isProcessing = false
                // Even if OCR fails, pass the image
                router.push(.scannerResult(content: "", image: image))
            }
        }
    }
}

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
