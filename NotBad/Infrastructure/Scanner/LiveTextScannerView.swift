//
//  LiveTextScannerView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import VisionKit

// MARK: - LiveTextScannerView

/// 实时文字扫描视图
///
/// 基于 VisionKit `DataScannerViewController` 的实时文字扫描功能。
///
/// ## 功能特性
///
/// - 实时文字识别与高亮显示
/// - 支持多文本区域识别
/// - 捏合缩放支持
/// - 引导提示
///
/// ## 使用示例
///
/// ```swift
/// LiveTextScannerContainer(
///     onResult: { text in
///         print("识别结果: \(text)")
///     },
///     onCancel: {
///         print("用户取消")
///     }
/// )
/// ```
///
/// - Important: 使用前应通过 `isSupported` 检查设备支持
/// - Note: 需要相机权限
struct LiveTextScannerView: UIViewControllerRepresentable {
    
    // MARK: - Callbacks
    
    /// 扫描完成回调（累计文本）
    let onFinish: (String) -> Void
    
    /// 用户取消回调
    let onCancel: () -> Void
    
    // MARK: - Configuration
    
    /// 扫描配置
    var configuration: ScannerConfiguration = .default
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: configuration.recognizedDataTypes,
            qualityLevel: configuration.qualityLevel,
            recognizesMultipleItems: configuration.recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: configuration.isHighFrameRateTrackingEnabled,
            isPinchToZoomEnabled: configuration.isPinchToZoomEnabled,
            isGuidanceEnabled: configuration.isGuidanceEnabled,
            isHighlightingEnabled: configuration.isHighlightingEnabled
        )
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // 安全启动扫描
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                #if DEBUG
                print("扫描启动失败: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // MARK: - Coordinator
    
    /// 协调器，处理 DataScannerViewController 的代理回调
    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        private let parent: LiveTextScannerView
        private var collected: Set<String> = []
        
        /// 通知观察者令牌
        /// - Note: 标记为 nonisolated(unsafe) 以允许 deinit 访问
        nonisolated(unsafe) private var notificationToken: Any?
        
        init(parent: LiveTextScannerView) {
            self.parent = parent
            super.init()
            
            // 监听完成通知
            notificationToken = NotificationCenter.default.addObserver(
                forName: .liveScannerFinishRequest,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.finish()
                }
            }
        }
        
        deinit {
            if let token = notificationToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        
        // MARK: - DataScannerViewControllerDelegate
        
        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            processItems(addedItems)
        }
        
        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            processItems(updatedItems)
        }
        
        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            // 保留已采集的文本，不做移除
        }
        
        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
        ) {
            #if DEBUG
            print("扫描器不可用: \(error.localizedDescription)")
            #endif
        }
        
        // MARK: - Processing
        
        private func processItems(_ items: [RecognizedItem]) {
            for item in items {
                if case let .text(textItem) = item {
                    let transcript = textItem.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !transcript.isEmpty else { continue }
                    collected.insert(transcript)
                }
            }
        }
        
        /// 完成扫描并返回结果
        func finish() {
            let merged = collected.sorted().joined(separator: "\n")
            parent.onFinish(merged)
            
            // 发送完成响应通知
            NotificationCenter.default.post(
                name: .liveScannerFinishResponse,
                object: merged
            )
        }
        
        /// 当前已识别的文本数量
        var collectedCount: Int {
            collected.count
        }
    }
}

// MARK: - ScannerConfiguration

extension LiveTextScannerView {
    
    /// 扫描器配置
    ///
    /// - Note: 由于 `RecognizedDataType` 不是 Sendable，使用 `@unchecked Sendable`
    struct ScannerConfiguration: @unchecked Sendable {
        /// 识别的数据类型
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
        
        /// 识别质量级别
        let qualityLevel: DataScannerViewController.QualityLevel
        
        /// 是否识别多个项目
        let recognizesMultipleItems: Bool
        
        /// 是否启用高帧率追踪
        let isHighFrameRateTrackingEnabled: Bool
        
        /// 是否启用捏合缩放
        let isPinchToZoomEnabled: Bool
        
        /// 是否启用引导提示
        let isGuidanceEnabled: Bool
        
        /// 是否启用高亮显示
        let isHighlightingEnabled: Bool
        
        /// 默认配置
        static let `default` = ScannerConfiguration(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        /// 精确配置
        static let accurate = ScannerConfiguration(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        /// 快速配置
        static let fast = ScannerConfiguration(
            recognizedDataTypes: [.text()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: true
        )
    }
}

// MARK: - Availability

extension LiveTextScannerView {
    
    /// 检查设备是否支持实时文字扫描
    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    /// 获取不支持的原因
    static var unsupportedReason: String? {
        if !DataScannerViewController.isSupported {
            return "您的设备不支持实时文字扫描功能"
        }
        if !DataScannerViewController.isAvailable {
            return "实时文字扫描功能当前不可用，请检查相机权限"
        }
        return nil
    }
}

// MARK: - LiveTextScannerContainer

/// 实时扫描容器视图
///
/// 封装 `LiveTextScannerView` 并提供控制栏 UI。
struct LiveTextScannerContainer: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Callbacks
    
    /// 扫描结果回调
    let onResult: (String) -> Void
    
    /// 取消回调
    let onCancel: () -> Void
    
    // MARK: - State
    
    @State private var isSessionStarted = false
    @State private var errorMessage: String?
    @State private var recognizedCount = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            scannerView
            controlBar
        }
        .alert(
            "scanner_error_title",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("common_confirm") { dismiss() }
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveScannerFinishResponse)) { notification in
            if let text = notification.object as? String {
                onResult(text)
                dismiss()
            }
        }
    }
    
    // MARK: - Scanner View
    
    @ViewBuilder
    private var scannerView: some View {
        LiveTextScannerView(
            onFinish: { text in
                onResult(text)
                dismiss()
            },
            onCancel: {
                onCancel()
                dismiss()
            }
        )
        .ignoresSafeArea()
        .onAppear(perform: startSessionIfPossible)
    }
    
    // MARK: - Control Bar
    
    @ViewBuilder
    private var controlBar: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // 错误提示
            if let errorMessage {
                errorBanner(errorMessage)
            }
            
            // 识别状态
            statusIndicator
            
            // 操作按钮
            actionButtons
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom)
    }
    
    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.brand.error.opacity(0.8), in: Capsule())
    }
    
    private var statusIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "text.viewfinder")
                .symbolEffect(.pulse)
            Text("scanner_aim_prompt")
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(.black.opacity(0.5), in: Capsule())
    }
    
    private var actionButtons: some View {
        // 完成按钮（取消按钮已移至导航栏）
        Button {
            requestFinish()
        } label: {
            Label("scanner_finish", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md + 2)
                .background(Color.brand.primary.gradient, in: Capsule())
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Actions
    
    private func startSessionIfPossible() {
        guard !isSessionStarted else { return }
        isSessionStarted = true
        
        Task { @MainActor in
            guard LiveTextScannerView.isSupported else {
                errorMessage = LiveTextScannerView.unsupportedReason ?? "设备不支持实时扫描"
                return
            }
        }
    }
    
    private func requestFinish() {
        NotificationCenter.default.post(name: .liveScannerFinishRequest, object: nil)
    }
}

// MARK: - Preview

#Preview("扫描器容器") {
    if LiveTextScannerView.isSupported {
        LiveTextScannerContainer(
            onResult: { text in
                print("识别结果: \(text)")
            },
            onCancel: {
                print("用户取消")
            }
        )
    } else {
        ContentUnavailableView(
            "设备不支持",
            systemImage: "text.viewfinder",
            description: Text(LiveTextScannerView.unsupportedReason ?? "未知原因")
        )
    }
}
