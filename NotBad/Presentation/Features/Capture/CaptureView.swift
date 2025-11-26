//
//  CaptureView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import PhotosUI
import SwiftData

// MARK: - CaptureView

/// 错题录入视图
///
/// 支持多种方式录入错题：
/// - 相机拍摄
/// - 相册选择
/// - 实时文字扫描（OCR）
///
/// ## 功能特性
///
/// - 图片选择与预览
/// - OCR 文字识别
/// - 表单验证
/// - 自动保存
///
/// ## 使用示例
///
/// ```swift
/// NavigationStack {
///     CaptureView()
/// }
/// .modelContainer(for: ReviewItem.self)
/// ```
struct CaptureView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var viewModel = CaptureViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showImageSourcePicker = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    imageSelectionSection
                    
                    if viewModel.selectedUIImage != nil && viewModel.title.isEmpty {
                        ocrButton
                    }
                    
                    inputSection
                    
                    saveButton
                }
                .padding()
            }
            .navigationTitle("录入错题")
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    await viewModel.loadTransferable(from: newValue)
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    viewModel.handlePickedImage(image)
                }
            }
            .sheet(isPresented: $viewModel.showLiveScanner) {
                liveScannerSheet
            }
            .confirmationDialog("选择图片来源", isPresented: $showImageSourcePicker) {
                Button("拍照") {
                    viewModel.showCamera = true
                }
                Button("从相册选择") {
                    // PhotosPicker 会自动处理
                }
                Button("取消", role: .cancel) {}
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("确定") {
                    if viewModel.alertMessage.contains("成功") {
                        viewModel.resetForm()
                        selectedItem = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Image Selection Section
    
    @ViewBuilder
    private var imageSelectionSection: some View {
        if let selectedImage = viewModel.selectedImage {
            selectedImageView(selectedImage)
        } else {
            imageSourceButtons
        }
    }
    
    private func selectedImageView(_ image: Image) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            image
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .shadow(radius: 5)
            
            Button {
                showImageSourcePicker = true
            } label: {
                Label("重新选择", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Color.brand.primary)
            }
        }
    }
    
    private var imageSourceButtons: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 拍照按钮
            SourceButton(
                icon: "camera.fill",
                title: "拍照录入",
                color: Color.brand.primary
            ) {
                viewModel.showCamera = true
            }
            
            // 实时扫描按钮
            if LiveTextScannerView.isSupported {
                SourceButton(
                    icon: "doc.viewfinder",
                    title: "实时扫描题干",
                    subtitle: "无需拍照，直接提取文字",
                    color: Color.brand.secondary
                ) {
                    viewModel.showLiveScanner = true
                }
            }
            
            // 相册选择
            PhotosPicker(selection: $selectedItem, matching: .images) {
                SourceButtonContent(
                    icon: "photo.on.rectangle",
                    title: "从相册选择",
                    color: Color.brand.success
                )
            }
        }
    }
    
    // MARK: - OCR Button
    
    private var ocrButton: some View {
        Button {
            Task {
                await viewModel.recognizeText()
            }
        } label: {
            HStack {
                if viewModel.isRecognizingText {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "text.viewfinder")
                }
                Text(viewModel.isRecognizingText ? "识别中..." : "自动识别文字")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.brand.warning)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .disabled(viewModel.isRecognizingText)
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            titleField
            subjectAndGradeRow
            knowledgePointsField
            noteField
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("标题")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("例如: 数学-三角函数 (必填)", text: $viewModel.title)
                .textFieldStyle(.roundedBorder)
                .font(.headline)
        }
    }
    
    private var subjectAndGradeRow: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("学科")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("学科", selection: $viewModel.subject) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        Text(subject.displayName).tag(subject)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .background(Color.semantic.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("年级")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker("年级", selection: $viewModel.grade) {
                    ForEach(Grade.allCases, id: \.self) { grade in
                        Text(grade.displayName).tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .background(Color.semantic.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
            }
        }
    }
    
    private var knowledgePointsField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("知识点标签")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("例如: 函数, 导数 (逗号分隔)", text: $viewModel.knowledgePointsInput)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var noteField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("备注")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("记录解题思路或知识点...", text: $viewModel.note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            viewModel.saveItem()
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 5)
                }
                Text(viewModel.isSaving ? "保存中..." : "保存到题库")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValid ? Color.brand.primary : Color.semantic.separator)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .disabled(!viewModel.isValid || viewModel.isSaving)
    }
    
    // MARK: - Live Scanner Sheet
    
    @ViewBuilder
    private var liveScannerSheet: some View {
        LiveTextScannerContainer(
            onResult: { text in
                viewModel.handleLiveScanResult(text)
            },
            onCancel: {}
        )
    }
}

// MARK: - SourceButton

/// 来源选择按钮
private struct SourceButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SourceButtonContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: title)
        .accessibilityLabel(subtitle != nil ? "\(title)，\(subtitle!)" : title)
        .accessibilityAddTraits(.isButton)
    }
}

/// 来源按钮内容
private struct SourceButtonContent: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: subtitle != nil ? 120 : 100)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
}

// MARK: - Preview

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
