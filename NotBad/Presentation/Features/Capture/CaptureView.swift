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

    @Environment(\.dependencyFactory) private var dependencyFactory

    // MARK: - State

    @State private var orchestrator = CaptureOrchestrator()
    @State private var isKeyboardVisible = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(LocalizedStringKey("capture_title"))
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    if let factory = dependencyFactory {
                        orchestrator.configure(with: factory)
                    }
                }
                .onChange(of: orchestrator.imageSelectionVM.selectedItem) { _, newValue in
                    Task {
                        await orchestrator.imageSelectionVM.loadTransferable(from: newValue)
                    }
                }
                .dropDestination(for: Data.self) { items, _ in
                    guard let item = items.first, let image = UIImage(data: item) else { return false }
                    orchestrator.handleNewImage(image)
                    return true
                }
                .sheet(isPresented: $orchestrator.imageSelectionVM.showCamera) {
                    ImagePicker(sourceType: .camera) { image in
                        orchestrator.handleNewImage(image)
                    }
                }
                .fullScreenCover(isPresented: $orchestrator.imageSelectionVM.showLiveScanner) {
                    liveScannerSheet
                }
                .alert(orchestrator.alertMessage, isPresented: $orchestrator.showAlert) {
                    Button(LocalizedStringKey("common_confirm")) {
                        if orchestrator.isSuccessAlert {
                            orchestrator.reset()
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
            if orchestrator.imageSelectionVM.selectedImage == nil {
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
            if !isKeyboardVisible {
                imageSourceBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
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
        if let image = orchestrator.imageSelectionVM.selectedImage {
            SelectedImageCard(
                selectedImage: image,
                isRecognizingText: orchestrator.ocrVM.isRecognizing,
                showLiveScannerSupport: LiveTextScannerView.isSupported,
                onCameraPressed: {
                    orchestrator.imageSelectionVM.showCamera = true
                },
                onLiveScanPressed: {
                    orchestrator.imageSelectionVM.showLiveScanner = true
                },
                onRecognizeText: {
                    Task {
                        if let uiImage = orchestrator.imageSelectionVM.selectedUIImage {
                            _ = await orchestrator.ocrVM.recognizeText(from: uiImage)
                        }
                    }
                },
                onClearImage: {
                    orchestrator.reset()
                }
            )
        }
    }
}

// MARK: - Form Section

extension CaptureView {
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            BasicInfoFormSection(viewModel: orchestrator.formVM)
            ReviewItemContentFormSection(ocrVM: orchestrator.ocrVM)
            AdditionalInfoFormSection(viewModel: orchestrator.formVM)
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
}

// MARK: - Image Source Bar

extension CaptureView {
    /// 底部图片来源选择栏 - 参考 iOS 备忘录风格
    private var imageSourceBar: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            // 相册
            PhotosPicker(selection: $orchestrator.imageSelectionVM.selectedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Text("capture_album"))
            
            Spacer()
            
            // 智能识别（主按钮）
            if LiveTextScannerView.isSupported {
                Button {
                    orchestrator.imageSelectionVM.showLiveScanner = true
                } label: {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: DesignTokens.IconSize.xxl, height: DesignTokens.IconSize.xxl)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .accessibilityLabel(Text("capture_live_text"))
            }
            
            Spacer()
            
            // 拍照
            Button {
                orchestrator.imageSelectionVM.showCamera = true
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Text("capture_camera"))
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Save Button

extension CaptureView {
    private var saveButtonBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                Task {
                    await orchestrator.save()
                }
            } label: {
                saveButtonLabel
            }
            .buttonStyle(SaveButtonStyle())
            .disabled(orchestrator.isSaving)
            .accessibilityLabel(Text("capture_save_to_library"))
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }

    private var saveButtonLabel: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if orchestrator.isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            Text(orchestrator.isSaving ? "capture_saving" : "capture_save_to_library")
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
                    if let data = imageData, let image = UIImage(data: data) {
                        orchestrator.handleNewImage(image)
                    }
                    orchestrator.imageSelectionVM.showLiveScanner = false
                },
                onCancel: {
                    orchestrator.imageSelectionVM.showLiveScanner = false
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        orchestrator.imageSelectionVM.showLiveScanner = false
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
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
