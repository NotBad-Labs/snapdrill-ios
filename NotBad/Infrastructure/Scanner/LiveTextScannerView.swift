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
/// - 完成时自动截取画面保存
///
/// ## 使用示例
///
/// ```swift
/// LiveTextScannerContainer(
///     onResult: { text, imageData in
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

    /// 扫描完成回调（累计文本 + 截图数据）
    let onFinish: (String, Data?) -> Void

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
        
        // 保存引用到 coordinator
        context.coordinator.scanner = scanner
        
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
        var scanner: DataScannerViewController?

        /// 通知观察者令牌
        /// - Note: 标记为 nonisolated(unsafe) 以允许 deinit 访问
        nonisolated(unsafe) private var notificationToken: Any?

        init(parent: LiveTextScannerView) {
            self.parent = parent
            super.init()

            // 监听完成通知 - 使用自身保存的 scanner 引用
            notificationToken = NotificationCenter.default.addObserver(
                forName: .liveScannerFinishRequest,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    if let scanner = self?.scanner {
                        self?.finishWithCapture(scanner: scanner)
                    } else {
                        self?.finish(imageData: nil)
                    }
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

        /// 完成扫描并截取画面
        func finishWithCapture(scanner: DataScannerViewController) {
            // 使用 capturePhoto API 获取相机画面
            Task {
                do {
                    let photo = try await scanner.capturePhoto()
                    let imageData = photo.jpegData(compressionQuality: 0.8)
                    await MainActor.run {
                        finish(imageData: imageData)
                    }
                } catch {
                    #if DEBUG
                    print("📷 截图失败: \(error)")
                    #endif
                    await MainActor.run {
                        finish(imageData: nil)
                    }
                }
            }
        }

        /// 完成扫描并返回结果
        func finish(imageData: Data?) {
            let merged = collected.sorted().joined(separator: "\n")
            
            // 只通过通知返回结果，避免重复回调
            NotificationCenter.default.post(
                name: .liveScannerFinishResponse,
                object: ScannerResult(text: merged, imageData: imageData)
            )
        }

        /// 当前已识别的文本数量
        var collectedCount: Int {
            collected.count
        }
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
            return String(localized: "scanner_unsupported_device")
        }
        if !DataScannerViewController.isAvailable {
            return String(localized: "scanner_unavailable_permission")
        }
        return nil
    }
}

