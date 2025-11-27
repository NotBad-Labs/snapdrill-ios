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
/// 符合 Apple HIG 的现代化录入界面：
/// - 图片选择卡片（拍照/扫描/相册）
/// - Form 表单布局
/// - 固定底部保存按钮
/// - 实时表单验证
///
/// ## 设计理念
///
/// - 单页完成，减少步骤
/// - 图片为主，表单为辅
/// - 必填项明确标注
/// - 保存按钮始终可见
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
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 图片选择卡片
                imageCard
                
                // 表单区域
                formSection
            }
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, 100) // 为底部按钮留空间
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            hideKeyboard()
        }
        .safeAreaInset(edge: .bottom) {
            saveButtonBar
        }
    }
    
    // MARK: - Keyboard
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Image Card
    
    private var imageCard: some View {
        ImageSelectionCard(
            selectedItem: $selectedItem,
            selectedImage: viewModel.selectedImage,
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
            }
        )
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 基本信息
            FormCard {
                VStack(spacing: 0) {
                    // 标题（必填）
                    FormRow(isLast: false) {
                        HStack {
                            Text("capture_field_title")
                                .foregroundStyle(.primary)
                            Text("*")
                                .foregroundStyle(Color.brand.error)
                            Spacer()
                        }
                    } content: {
                        TextField(
                            String(localized: "capture_field_title_placeholder"),
                            text: $viewModel.title
                        )
                        .multilineTextAlignment(.trailing)
                        .submitLabel(.done)
                    }
                    
                    // 学科
                    FormRow(isLast: false) {
                        Text("capture_field_subject")
                    } content: {
                        Picker("", selection: $viewModel.subject) {
                            ForEach(Subject.allCases) { subject in
                                Text(subject.displayName)
                                    .tag(subject)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                    
                    // 年级
                    FormRow(isLast: true) {
                        Text("capture_field_grade")
                    } content: {
                        Picker("", selection: $viewModel.grade) {
                            // 中国 K12 不包含幼儿园
                            ForEach(Grade.allCases.filter { $0 != .kindergarten }) { grade in
                                Text(grade.displayName)
                                    .tag(grade)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                }
            } header: {
                Text("capture_section_basic")
            }
            
            // 题目内容（可手动输入或 OCR 识别）
            questionContentSection
            
            // 补充信息
            FormCard {
                VStack(spacing: 0) {
                    // 知识点
                    FormRow(isLast: false) {
                        Text("capture_field_knowledge_points")
                    } content: {
                        TextField(
                            String(localized: "capture_field_knowledge_points_placeholder"),
                            text: $viewModel.knowledgePointsInput
                        )
                        .multilineTextAlignment(.trailing)
                        .submitLabel(.done)
                    }
                    
                    // 笔记
                    FormRow(isLast: true, alignment: .top) {
                        Text("capture_field_note")
                            .padding(.top, DesignTokens.Spacing.sm)
                    } content: {
                        TextField(
                            String(localized: "capture_field_note_placeholder"),
                            text: $viewModel.note,
                            axis: .vertical
                        )
                        .lineLimit(2...4)
                        .multilineTextAlignment(.trailing)
                        .submitLabel(.done)
                    }
                }
            } header: {
                Text("capture_section_additional")
            }
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
    
    // MARK: - Save Button Bar
    
    // MARK: - Question Content Section
    
    private var questionContentSection: some View {
        FormCard {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.recognizedText.isEmpty {
                    Text("capture_question_content_placeholder")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm + 4)
                        .padding(.vertical, DesignTokens.Spacing.sm + 8)
                }
                
                // 文本编辑器
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
                // 字数统计（有内容时显示）
                if !viewModel.recognizedText.isEmpty {
                    Text("\(viewModel.recognizedText.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Save Button Bar
    
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
            .buttonStyle(SaveButtonStyle())
            .disabled(viewModel.isSaving)
            .accessibilityLabel(Text("capture_save_to_library"))
            .accessibilityHint(viewModel.isValid ? Text("hig_double_tap_to_save") : Text("hig_fill_required_fields"))
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Save Button Style
    
    private struct SaveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    // MARK: - Live Scanner Sheet
    
    @ViewBuilder
    private var liveScannerSheet: some View {
        NavigationStack {
            LiveTextScannerContainer(
                onResult: { text in
                    viewModel.handleLiveScanResult(text)
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

// MARK: - FormCard

/// 表单卡片容器
private struct FormCard<Content: View, Header: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            header()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.sm)
            
            content()
                .background(Color.semantic.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
    }
}

// MARK: - FormRow

/// 表单行
private struct FormRow<Label: View, Content: View>: View {
    let isLast: Bool
    var alignment: VerticalAlignment = .center
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: alignment) {
                label()
                    .font(.body)
                Spacer()
                content()
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
            
            if !isLast {
                Divider()
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
