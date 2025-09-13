//
//  CaptureTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import SwiftUI

/// 录入Tab视图 - 核心功能模块
struct CaptureTabView: View {
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var showingEditView = false
    @StateObject private var ocrService = OCRServiceManager.shared
    
    // 依赖注入 - 从父视图传递
    let createReviewItemUseCase: CreateReviewItemUseCase
    
    var body: some View {
        VStack(spacing: 24) {
            // 主要操作按钮
            VStack(spacing: 16) {
                // 拍照按钮
                Button(action: { showingCamera = true }) {
                    cameraButtonContent
                }
                
                // 相册导入按钮
                Button(action: { showingImagePicker = true }) {
                    galleryButtonContent
                }
            }
            .padding(.horizontal)
            
            // 功能介绍
            VStack(spacing: 12) {
                Text("📷 智能录入")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("快速拍照识别错题，让学习更高效")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 功能特性
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "camera.viewfinder", title: "OCR识别", description: "智能识别题目内容")
                FeatureRow(icon: "tag.fill", title: "自动分类", description: "按学科和知识点分类")
                FeatureRow(icon: "square.stack.3d.up", title: "批量导入", description: "支持多张图片同时处理")
                FeatureRow(icon: "brain.head.profile", title: "AI分析", description: "智能推荐学习建议")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("录入")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera, capturedImage: $capturedImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            SingleImagePickerView(isPresented: $showingImagePicker, selectedImage: $capturedImage)
        }
        .sheet(isPresented: $showingEditView) {
            if let image = capturedImage {
                OCRResultEditView(
                    image: image, 
                    isPresented: $showingEditView,
                    createReviewItemUseCase: createReviewItemUseCase
                )
            }
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if newValue != nil {
                showingEditView = true
            }
        }
    }
    
    // MARK: - View Components
    
    private var cameraButtonContent: some View {
        HStack {
            Image(systemName: "camera.fill")
                .font(.title2)
            Text("拍照录入")
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.blue)
        .cornerRadius(16)
    }
    
    private var galleryButtonContent: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
                .font(.title2)
            Text("从相册导入")
                .font(.headline)
        }
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

/// 功能特性行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}


#Preview {
    NavigationView {
        let mockUseCase = CreateReviewItemUseCaseImpl(repository: MockReviewItemRepository())
        return CaptureTabView(createReviewItemUseCase: mockUseCase)
    }
}
