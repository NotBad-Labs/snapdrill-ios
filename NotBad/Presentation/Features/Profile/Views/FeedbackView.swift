//
//  FeedbackView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import MessageUI

// MARK: - FeedbackView

/// 意见反馈视图
///
/// 收集用户反馈和建议。
struct FeedbackView: View {
    
    // MARK: - State
    
    @State private var feedbackType: FeedbackType = .suggestion
    @State private var feedbackContent = ""
    @State private var contactInfo = ""
    @State private var showMailComposer = false
    @State private var showSuccessAlert = false
    @State private var showCopiedToast = false
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        List {
            typeSection
            contentSection
            contactSection
            submitSection
        }
        .navigationTitle("意见反馈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isFocused = false
                }
            }
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: feedbackSubject,
                body: feedbackBody,
                recipients: ["feedback@notbad.app"]
            )
        }
        .alert("感谢反馈！", isPresented: $showSuccessAlert) {
            Button("好的") { }
        } message: {
            Text("我们已收到你的反馈，会认真阅读并持续改进。")
        }
        .overlay {
            if showCopiedToast {
                VStack {
                    Spacer()
                    ToastView(toast: Toast.success("已复制到剪贴板"))
                        .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showCopiedToast)
            }
        }
    }
    
    // MARK: - Type Section
    
    private var typeSection: some View {
        Section("反馈类型") {
            ForEach(FeedbackType.allCases) { type in
                Button {
                    feedbackType = type
                } label: {
                    HStack {
                        Label(type.displayName, systemImage: type.icon)
                            .foregroundStyle(.primary)
                        Spacer()
                        if feedbackType == type {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.brand.primary)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Section {
            TextEditor(text: $feedbackContent)
                .frame(minHeight: 150)
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if feedbackContent.isEmpty {
                        Text("请详细描述你的问题或建议...")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        } header: {
            Text("详细描述")
        } footer: {
            Text("\(feedbackContent.count)/500 字")
                .foregroundStyle(feedbackContent.count > 500 ? Color.brand.error : .secondary)
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        Section {
            TextField("邮箱或手机号（选填）", text: $contactInfo)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .focused($isFocused)
        } header: {
            Text("联系方式")
        } footer: {
            Text("留下联系方式，方便我们跟进处理。")
        }
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        Section {
            if MFMailComposeViewController.canSendMail() {
                Button {
                    showMailComposer = true
                } label: {
                    HStack {
                        Spacer()
                        Label("发送邮件反馈", systemImage: "envelope.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValid)
            } else {
                Button {
                    copyFeedbackToClipboard()
                } label: {
                    HStack {
                        Spacer()
                        Label("复制反馈内容", systemImage: "doc.on.doc.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!isValid)
            }
        } footer: {
            if !MFMailComposeViewController.canSendMail() {
                Text("设备未配置邮箱，点击复制后可粘贴发送到 feedback@notbad.app")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !feedbackContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        feedbackContent.count <= 500
    }
    
    private var feedbackSubject: String {
        "[NotBad 反馈] \(feedbackType.displayName)"
    }
    
    private var feedbackBody: String {
        """
        反馈类型：\(feedbackType.displayName)
        
        反馈内容：
        \(feedbackContent)
        
        联系方式：\(contactInfo.isEmpty ? "未填写" : contactInfo)
        
        ---
        设备信息：
        • 应用版本：1.0.0
        • 系统版本：iOS \(UIDevice.current.systemVersion)
        • 设备型号：\(UIDevice.current.model)
        """
    }
    
    // MARK: - Methods
    
    private func copyFeedbackToClipboard() {
        UIPasteboard.general.string = feedbackBody
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }
}

// MARK: - FeedbackType

enum FeedbackType: String, CaseIterable, Identifiable {
    case bug
    case suggestion
    case question
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bug: return "问题反馈"
        case .suggestion: return "功能建议"
        case .question: return "使用疑问"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .suggestion: return "lightbulb.fill"
        case .question: return "questionmark.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - MailComposerView

struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipients: [String]
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.setToRecipients(recipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        @MainActor
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
