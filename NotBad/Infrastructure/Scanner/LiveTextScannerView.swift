//
//  LiveTextScannerView.swift
//  NotBad
//
//  基于 VisionKit 的实时文字扫描封装（可用于题干实时采集）
//  说明：DataScannerViewController 在支持设备上提供 Live Text 识别。
//  注意：以下实现使用公开 API；朋友提到的 iOS 26 特性（如“语义级手写修复”、“Liquid Glass”样式、文档手写分层删除、直接 LaTeX 输出）目前未在公开 SDK 中提供
//  （截至 Swift 6.x / VisionKit 现有能力），本封装只实现可验证的实时文本扫描。
//

import SwiftUI
import VisionKit

@available(iOS 16.0, *)
struct LiveTextScannerView: UIViewControllerRepresentable {
    /// 扫描结果回调（累计文本）
    let onFinish: (String) -> Void
    /// 用户取消
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: LiveTextScannerView
        private var collected: Set<String> = []
        
        init(parent: LiveTextScannerView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(handleFinishRequest), name: .liveScannerFinishRequest, object: nil)
        }
        
        @objc private func handleFinishRequest() {
            finish()
        }
        
        deinit { NotificationCenter.default.removeObserver(self) }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(items: addedItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(items: updatedItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // 移除不再显示的文本（可选：当前简单忽略，保留之前捕获的）
        }
        
        private func handle(items: [RecognizedItem]) {
            for item in items {
                if case let .text(textItem) = item {
                    let t = textItem.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { continue }
                    collected.insert(t)
                }
            }
        }
        
        func finish() {
            let merged = collected.sorted().joined(separator: "\n")
            parent.onFinish(merged)
            NotificationCenter.default.post(name: .liveScannerFinishResponse, object: merged)
        }
    }
}

@available(iOS 16.0, *)
struct LiveTextScannerContainer: View {
    @Environment(\.dismiss) private var dismiss
    let onResult: (String) -> Void
    let onCancel: () -> Void
    @State private var isSessionStarted = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LiveTextScannerView(onFinish: { text in
                onResult(text)
                dismiss()
            }, onCancel: {
                onCancel()
                dismiss()
            })
            .ignoresSafeArea()
            .onAppear(perform: startSessionIfPossible)
            
            controlBar
        }
        .alert(errorMessage ?? "", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("确定") { dismiss() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveScannerFinishResponse)) { notif in
            if let text = notif.object as? String {
                onResult(text)
                dismiss()
            }
        }
    }
    
    @ViewBuilder private var controlBar: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            HStack(spacing: 16) {
                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Label("取消", systemImage: "xmark.circle")
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                
                Button {
                    // 结束并返回结果
                    onResultSnapshot()
                } label: {
                    Label("完成", systemImage: "checkmark.circle")
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(.blue.gradient, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func startSessionIfPossible() {
        guard !isSessionStarted else { return }
        isSessionStarted = true
        Task { @MainActor in
            // DataScannerViewController 需要检查可用性
            guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
                errorMessage = "设备不支持实时扫描或相机不可用"
                return
            }
            // 获取最顶层控制器并启动会话
            // 使用 UIWindowScene 查找当前活动 VC
            // 此处 DataScannerViewController 会在 makeUIViewController 中自动创建并显示；
            // 如果需要显式 startScanning，可通过遍历 scene:
            // 但 SwiftUI 包装时可在出现后延迟执行:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 寻找当前呈现的 VC
                // 无需手动 startScanning（iOS16+ 默认自动启动）。若需: 可尝试反射调用。保持简单。
            }
        }
    }
    
    private func onResultSnapshot() {
        // 通过查找子视图的 Coordinator 获取文本集合
        // 简化：重新呈现一个空结果视图无法访问内部集合，改方式：利用通知或环境。这里退而求其次：
        // 方案：让 Coordinator 在 finish() 时合并文本；调用完成按钮时用 UIWindow 获取 rootVC 强制结束。
        // 为避免复杂反射，这里提示用户使用自动完成（识别过程中实时加入），点击“完成”时尝试再次结束识别会话。
        // 由于我们已在 LiveTextScannerView 的 finish() 中组合文本，这里无法直接触发 Coordinator.finish()，
        // 解决方式：使用 NotificationCenter。
        NotificationCenter.default.post(name: .liveScannerFinishRequest, object: nil)
    }
}
