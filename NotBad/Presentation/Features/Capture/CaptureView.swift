//
//  CaptureView.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI
import PhotosUI
import SwiftData
import TipKit

// MARK: - CaptureView

/// 错题录入视图
///
/// 符合 Apple HIG 的现代化录入界面：
/// - 图片选择卡片（拍照/扫描/相册）
/// - Form 表单布局
/// - 固定底部保存按钮
/// - 实时表单验证
struct CaptureView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = CaptureViewModel()
    @State private var selectedItem: PhotosPickerItem?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(LocalizedStringKey("capture_title"))
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    viewModel.configure(with: modelContext)
                }
                .onChange(of: selectedItem) { _, newValue in
                    Task {
                        await viewModel.loadTransferable(from: newValue)
                    }
                }
                .dropDestination(for: Data.self) { items, _ in
                    guard let item = items.first, let image = UIImage(data: item) else { return false }
                    viewModel.handlePickedImage(image)
                    return true
                }
                .sheet(isPresented: $viewModel.showCamera) {
                    ImagePicker(sourceType: .camera) { image in
                        viewModel.handlePickedImage(image)
                    }
                }
                .fullScreenCover(isPresented: $viewModel.showLiveScanner) {
                    liveScannerSheet
                }
                .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                    Button(LocalizedStringKey("common_confirm")) {
                        if viewModel.isSuccessAlert {
                            viewModel.resetForm()
                            selectedItem = nil
                        }
                    }
                }
        }
    }
}

// MARK: - Main Content

extension CaptureView {
    private var mainContent: some View {
        Group {
            if viewModel.selectedImage == nil {
                // 未选择图片：显示表单 + 底部选择按钮
                initialInputView
            } else {
                // 已选择图片：显示完整编辑表单 + 保存按钮
                editFormView
            }
        }
    }
    
    /// 初始录入视图（未选择图片）
    private var initialInputView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 首次使用提示
                TipView(CapturePhotoTip(), arrowEdge: .bottom)
                    .tipBackground(Color(.secondarySystemBackground))
                
                formSection
            }
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            hideKeyboard()
        }
        .safeAreaInset(edge: .bottom) {
            imageSourceBar
        }
    }
    
    /// 编辑表单视图（选择图片后）
    private var editFormView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                imageCard
                formSection
            }
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            hideKeyboard()
        }
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Image Card

extension CaptureView {
    @ViewBuilder
    private var imageCard: some View {
        if let image = viewModel.selectedImage {
            SelectedImageCard(
                selectedImage: image,
                isRecognizingText: viewModel.isRecognizingText,
                showLiveScannerSupport: LiveTextScannerView.isSupported,
                onCameraPressed: {
                    viewModel.showCamera = true
                },
                onLiveScanPressed: {
                    viewModel.showLiveScanner = true
                },
                onRecognizeText: {
                    Task {
                        await viewModel.recognizeText()
                    }
                },
                onClearImage: {
                    viewModel.clearImage()
                    selectedItem = nil
                }
            )
        }
    }
}

// MARK: - Form Section

extension CaptureView {
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            basicInfoSection(viewModel: viewModel)
            questionContentSection
            additionalInfoSection(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("common_done") {
                    hideKeyboard()
                }
            }
        }
    }

    private var questionContentSection: some View {
        FormCard {
            ZStack(alignment: .topLeading) {
                if viewModel.recognizedText.isEmpty {
                    Text("capture_question_content_placeholder")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm + 4)
                        .padding(.vertical, DesignTokens.Spacing.sm + 8)
                }

                TextEditor(text: $viewModel.recognizedText)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(DesignTokens.Spacing.sm)
                    .scrollContentBackground(.hidden)
            }
        } header: {
            HStack {
                Text("capture_section_question_content")
                Spacer()
                if !viewModel.recognizedText.isEmpty {
                    Text("\(viewModel.recognizedText.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Image Source Bar

extension CaptureView {
    /// 底部图片来源选择栏（初始状态显示）
    private var imageSourceBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            // 轻量化设计：三个等大的文字按钮，简洁不侵入
            HStack(spacing: 0) {
                // 相册
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 22))
                        Text("capture_album")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                
                // 智能识别（核心功能）
                if LiveTextScannerView.isSupported {
                    Button {
                        viewModel.showLiveScanner = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 22, weight: .semibold))
                            Text("capture_live_text")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                
                // 拍照
                Button {
                    viewModel.showCamera = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "camera")
                            .font(.system(size: 22))
                        Text("capture_camera")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 12)
        }
        .background(.bar)
    }
}

// MARK: - Save Button

extension CaptureView {
    private var saveButtonBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                if viewModel.isValid {
                    viewModel.saveItem()
                } else {
                    viewModel.showValidationError()
                }
            } label: {
                saveButtonLabel
            }
            .buttonStyle(SaveButtonStyle())
            .disabled(viewModel.isSaving)
            .accessibilityLabel(Text("capture_save_to_library"))
            .accessibilityHint(
                viewModel.isValid
                    ? Text("hig_double_tap_to_save")
                    : Text("hig_fill_required_fields")
            )
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    private var saveButtonLabel: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if viewModel.isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            Text(viewModel.isSaving ? "capture_saving" : "capture_save_to_library")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            LinearGradient(
                colors: [Color.brand.primary, Color.brand.primary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .shadow(
            color: Color.brand.primary.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private struct SaveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}

// MARK: - Live Scanner

extension CaptureView {
    @ViewBuilder
    private var liveScannerSheet: some View {
        NavigationStack {
            LiveTextScannerContainer(
                onResult: { text, imageData in
                    viewModel.handleLiveScanResult(text, imageData: imageData)
                },
                onCancel: {
                    viewModel.showLiveScanner = false
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        viewModel.showLiveScanner = false
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
