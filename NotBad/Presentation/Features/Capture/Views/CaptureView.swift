//
//  CaptureView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI
import UIKit

/// 拍照视图
/// 提供拍照和图片识别功能
struct CaptureView: View {
    /// 拍照内容类型
    enum Content {
        case main
    }

    /// 协调器引用
    @ObservedObject var coordinator: CaptureCoordinator
    /// 视图模型
    @StateObject var viewModel: CaptureViewModel
    /// 应用环境
    @Environment(\.appEnvironment) private var appEnvironment

    init(coordinator: CaptureCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: CaptureViewModel(
            captureUseCase: ServiceContainer.shared.captureReviewItemUseCase,
            coordinator: coordinator
        ))
    }

    init(viewModel: CaptureViewModel, coordinator: CaptureCoordinator) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            CaptureMainContentView(viewModel: viewModel)
                .navigationTitle("拍照")
                // 标识当前屏幕，便于 UITests 
                .accessibilityIdentifier("screen_capture")
                .navigationDestination(for: CaptureCoordinator.CaptureRoute.self) { route in
                    switch route {
                    case .ocr(let imageBase64):
                        OCRResultView(imageBase64: imageBase64, coordinator: coordinator)
                    case .edit(let text):
                        OCREditView(initialText: text, coordinator: coordinator)
                    case .save(let content):
                        SaveReviewItemView(content: content, coordinator: coordinator)
                    }
                }
                .sheet(isPresented: $viewModel.showCamera) {
                    CameraView(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showPhotoLibrary) {
                    PhotoLibraryView(viewModel: viewModel)
                }
        }
        .onAppear {
            // 从全局环境注入错误处理器
            viewModel.configure(errorHandler: appEnvironment.errorHandler)
        }
    }
}

/// 拍照主内容视图
struct CaptureMainContentView: View {
    @ObservedObject var viewModel: CaptureViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            CaptureHeaderView()
            Spacer()
            CaptureCameraButtonView(viewModel: viewModel)
            Spacer()
            CaptureOptionsView(viewModel: viewModel)
            Spacer()
        }
    }
}

/// 拍照页面标题视图
struct CaptureHeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("拍照识别")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityIdentifier("capture_title")

            Text("拍摄题目，智能识别文字")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// 拍照按钮视图
struct CaptureCameraButtonView: View {
    @ObservedObject var viewModel: CaptureViewModel

    var body: some View {
        Button(
            action: {
                viewModel.showCameraView()
            },
            label: {
                VStack(spacing: 15) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("拍摄题目")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(width: 200, height: 200)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                )
            }
        )
        .accessibilityIdentifier("capture_main_button")
    }
}

/// 功能选项视图
struct CaptureOptionsView: View {
    @ObservedObject var viewModel: CaptureViewModel

    var body: some View {
        HStack(spacing: 20) {
            CaptureOptionButton(
                icon: "doc.text.viewfinder",
                title: "扫描文档",
                color: .green,
                action: {
                    viewModel.showCameraView()
                }
            )
            .accessibilityIdentifier("capture_option_scan")

            CaptureOptionButton(
                icon: "photo.on.rectangle",
                title: "从相册选择",
                color: .orange,
                action: {
                    viewModel.showPhotoLibraryView()
                }
            )
            .accessibilityIdentifier("capture_option_library")
        }
        .padding(.horizontal)
    }
}

/// 拍照选项按钮
struct CaptureOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    CaptureView(coordinator: CaptureCoordinator())
        .withAppEnvironment()
}

// MARK: - OCR 结果展示视图
struct OCRResultView: View {
    let imageBase64: String
    let coordinator: CaptureCoordinator
    @State private var recognizedText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("OCR 结果预览")
                .font(.title2)
                .fontWeight(.semibold)

            if let data = Data(base64Encoded: imageBase64), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .cornerRadius(12)
            } else {
                Text("无法加载图片")
                    .foregroundColor(.secondary)
            }

            TextEditor(text: $recognizedText)
                .frame(minHeight: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button("返回编辑") {
                    coordinator.goBack()
                }
                .buttonStyle(.bordered)

                Button("继续编辑文本") {
                    coordinator.coordinate(to: .ocrEdit(result: recognizedText))
                }
                .buttonStyle(.borderedProminent)
                .disabled(recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .onAppear {
            // TODO: 集成Vision OCR，当前先占位
            if recognizedText.isEmpty {
                recognizedText = "识别到的文本将显示在这里，当前为占位文本。"
            }
        }
        .navigationTitle("OCR 结果")
    }
}

// MARK: - OCR 文本编辑视图
struct OCREditView: View {
    @State private var text: String
    let coordinator: CaptureCoordinator

    init(initialText: String, coordinator: CaptureCoordinator) {
        self._text = State(initialValue: initialText)
        self.coordinator = coordinator
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("编辑识别文本")
                .font(.title2)
                .fontWeight(.semibold)

            TextEditor(text: $text)
                .frame(minHeight: 240)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            Button("保存为复习项…") {
                coordinator.coordinate(to: .saveReviewItem(content: text))
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
        .padding()
        .navigationTitle("编辑")
    }
}

// MARK: - 保存复习项视图（简单表单）
struct SaveReviewItemView: View {
    let content: String
    let coordinator: CaptureCoordinator
    @Environment(\.serviceContainer) private var services

    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var subject: ReviewItem.Subject = .other
    @State private var difficulty: ReviewItem.Difficulty = .medium
    @State private var tags: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(header: Text("题目与答案")) {
                TextField("题目（必填）", text: $question)
                TextField("答案（必填）", text: $answer)
                TextField("备注", text: $notes)
            }

            Section(header: Text("分类与难度")) {
                Picker("学科", selection: $subject) {
                    ForEach(ReviewItem.Subject.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                Picker("难度", selection: $difficulty) {
                    ForEach(ReviewItem.Difficulty.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
            }

            Section(header: Text("标签"), footer: Text("使用逗号分隔多个标签")) {
                TextField("例如：函数, 高一", text: $tags)
            }

            if let msg = errorMessage {
                Section {
                    Text(msg).foregroundColor(.red)
                }
            }

            Section {
                Button(isSaving ? "正在保存…" : "保存") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            // 注意：不再进行自动解析，用户需要手动输入所有信息
            // 可以将原始内容作为参考显示在题目字段中
            if question.isEmpty {
                question = content
            }
        }
        .navigationTitle("保存复习项")
    }

    private func save() async {
        errorMessage = nil
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "题目和答案不能为空"
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let userInput = ReviewItemUserInput(
                question: question,
                answer: answer,
                subject: subject,
                difficulty: difficulty,
                tags: Set(tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }),
                notes: notes.isEmpty ? nil : notes
            )
            
            let id = try await services.captureReviewItemUseCase.captureFromUserInput(userInput)
            print("Saved ReviewItem with id: \(id)")
            coordinator.completeWorkflow(nextAction: .returnToLibrary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
