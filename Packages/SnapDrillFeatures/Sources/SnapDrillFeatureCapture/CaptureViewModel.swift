//
//  CaptureViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  相机拍摄、图库选图、OCR 识别的主 ViewModel。
//

import AVFoundation
import Foundation
import Observation
import SnapDrillCore
import SwiftUI
import PhotosUI
import PDFKit

/// 采集功能主 ViewModel
///
/// 负责协调相机扫描、相册选图、OCR 识别等流程，并驱动导航跳转到结果编辑页。
@Observable
public final class CaptureViewModel {

    // MARK: - State

    /// 是否正在显示文档扫描器
    public var isShowingScanner = false
    /// 用户从相册选择的照片项
    public var selectedPhotoItem: PhotosPickerItem?
    /// 是否正在执行 OCR 或图片加载
    public var isProcessing = false
    /// 是否弹出草稿恢复提示
    public var showDraftAlert = false
    /// 当前待恢复的草稿（弹窗显示时有值）
    public var pendingDraft: CaptureDraftService.Draft? = nil

    /// 草稿提示详情文案（含学科和编辑时间）
    public var draftAlertMessage: String {
        guard let draft = pendingDraft else {
            return L10n.Capture.draftAlertMessage
        }
        let timeAgo = draft.date.relativeDescription()
        if let subject = draft.subject, !subject.isEmpty {
            return "有一道\(subject)题未保存，上次编辑于\(timeAgo)。"
        }
        return "有一道题未保存，上次编辑于\(timeAgo)。"
    }
    /// 是否弹出错误提示
    public var showErrorAlert = false
    /// 错误提示文本
    public var errorMessage = ""
    /// 是否弹出相机权限拒绝提示（需要"打开设置"按钮，区别于通用错误 alert）
    public var showCameraPermissionDenied = false
    /// 是否弹出 OCR 失败重试提示（需要"重新识别"和"继续编辑"按钮）
    public var showOCRRetryAlert = false
    /// OCR 失败时暂存的图片和路由器引用，用于重试
    public var pendingOCRImage: UIImage?
    @ObservationIgnored
    public var pendingOCRRouter: CaptureRouter?
    /// 是否正在显示 PDF 文件选择器
    public var isShowingPDFPicker = false
    /// 是否显示 PDF 大文件警告对话框
    public var showLargeFileAlert = false
    /// 大文件警告中显示的文件大小（MB）
    public var largeFileSizeMB = 0
    /// 暂存待确认导入的 PDF URL（用户确认大文件警告后使用）
    public var pendingPDFURL: URL?
    
    // MARK: - Dependencies
    
    private let ocrService: OCRServiceProtocol
    
    // MARK: - Initialization
    
    /// 创建采集功能 ViewModel
    /// - Parameter ocrService: OCR 识别服务，默认使用 `OCRService()`
    public init(ocrService: OCRServiceProtocol = OCRService()) {
        self.ocrService = ocrService
    }
    
    // MARK: - Public API

    /// 检查相机权限，未授权时弹出引导提示
    ///
    /// - Returns: `true` 表示权限已授权，可以打开相机；`false` 表示权限被拒绝或受限
    public func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            showCameraPermissionDenied = true
            return false
        @unknown default:
            showCameraPermissionDenied = true
            return false
        }
    }

    /// 页面出现时检查是否有未完成草稿，若有则弹出恢复提示
    public func checkDraftOnAppear() {
        if let draft = CaptureDraftService.shared.loadDraft() {
            pendingDraft = draft
            showDraftAlert = true
        }
    }
    
    /// 恢复草稿并导航到结果编辑页
    public func startEditingDraft(router: CaptureRouter) {
        if let draft = pendingDraft {
            router.push(.scannerResult(content: draft.content, image: draft.image))
        }
        clearDraft()
    }
    
    /// 丢弃当前草稿并清除持久化记录
    public func clearDraft() {
        CaptureDraftService.shared.clearDraft()
        pendingDraft = nil
    }
    
    /// 加载相册图片并触发 OCR 识别流程
    ///
    /// 同时将原图存入 `router.originalAlbumImage`，用于连续裁剪模式。
    public func loadPhoto(_ item: PhotosPickerItem, router: CaptureRouter) {
        isProcessing = true
        photoLoadTask = Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    guard !Task.isCancelled else { return }
                    // 存储原图用于连续裁剪（保存后可从同一张图裁剪不同区域）
                    router.originalAlbumImage = image
                    await processImageOCR(image, router: router)
                } else {
                    guard !Task.isCancelled else { return }
                    self.isProcessing = false
                    self.errorMessage = L10n.Errors.imageDecodeFailed
                    self.showErrorAlert = true
                }
            } catch is CancellationError {
                SnapDrillLogger.capture.info("相册加载任务已取消。")
            } catch {
                self.isProcessing = false
                self.errorMessage = L10n.Errors.imageLoadFailed
                self.showErrorAlert = true
            }
        }
        selectedPhotoItem = nil
    }
    
    /// OCR 失败后用户选择重新识别
    public func retryOCR() {
        guard let image = pendingOCRImage, let router = pendingOCRRouter else { return }
        pendingOCRImage = nil
        pendingOCRRouter = nil
        isProcessing = true
        Task {
            await processImageOCR(image, router: router)
        }
    }

    /// OCR 失败后用户选择继续编辑（跳转到空白编辑页）
    public func skipOCRAndEdit() {
        guard let image = pendingOCRImage, let router = pendingOCRRouter else { return }
        pendingOCRImage = nil
        pendingOCRRouter = nil
        router.push(.scannerResult(content: "", image: image))
    }

    /// 从剪贴板读取文本并跳转到编辑页
    ///
    /// 剪贴板为空或无文本时，展示错误提示。
    public func pasteFromClipboard(router: CaptureRouter) {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            router.push(.scannerResult(content: text, image: nil))
        } else {
            errorMessage = L10n.Errors.clipboardEmpty
            showErrorAlert = true
        }
    }

    /// 处理文档扫描仪返回的图片并触发 OCR 识别流程
    public func processScannedImage(_ image: UIImage, router: CaptureRouter) {
        isProcessing = true
        // 保存句柄到 photoLoadTask，使 cancelOngoingTasks() 可取消此任务
        photoLoadTask = Task {
            await processImageOCR(image, router: router)
        }
    }
    
    /// 大文件阈值（字节），超过此值时弹出警告
    private static let largeFileThreshold: Int = 50 * 1024 * 1024 // 50 MB 阈值

    /// 加载 PDF 文件并存入 Router，跳转到页面选择器
    ///
    /// 在安全域权限窗口内用 `Data(contentsOf:)` 完整读取文件数据，
    /// 再通过 `PDFDocument(data:)` 构建文档对象，避免权限释放后懒加载失败。
    /// 超过 50 MB 的文件会弹出警告，用户确认后才继续导入。
    ///
    /// - Parameters:
    ///   - url: 用户选择的 PDF 文件路径
    ///   - router: 采集模块路由器
    public func loadPDF(_ url: URL, router: CaptureRouter) {
        let accessing = url.startAccessingSecurityScopedResource()

        // 检查文件大小，超过阈值时弹出警告让用户确认
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize ?? 0
            if fileSize > Self.largeFileThreshold {
                let sizeMB = fileSize / (1024 * 1024)
                largeFileSizeMB = sizeMB
                pendingPDFURL = url
                showLargeFileAlert = true
                SnapDrillLogger.capture.warning("PDF 文件较大（\(sizeMB) MB），弹出用户确认")
                if accessing { url.stopAccessingSecurityScopedResource() }
                return
            }
        } catch {
            SnapDrillLogger.capture.error("读取文件属性失败: \(error.localizedDescription)")
            // 属性读取失败不阻塞导入，继续后续流程
        }

        performLoadPDF(url, router: router, accessing: accessing)
    }

    /// 用户确认大文件警告后继续导入 PDF
    public func confirmLargeFileImport(router: CaptureRouter) {
        guard let url = pendingPDFURL else { return }
        pendingPDFURL = nil
        let accessing = url.startAccessingSecurityScopedResource()
        performLoadPDF(url, router: router, accessing: accessing)
    }

    /// 实际执行 PDF 加载逻辑（内部方法，由 loadPDF 和 confirmLargeFileImport 共用）
    private func performLoadPDF(_ url: URL, router: CaptureRouter, accessing: Bool) {
        isProcessing = true

        // 后台读取 PDF 数据，避免大文件阻塞主线程
        pdfLoadTask = Task {
            // 在安全域权限窗口内后台读取原始数据
            let data: Data? = await Task.detached(priority: .userInitiated) {
                try? Data(contentsOf: url)
            }.value

            if accessing { url.stopAccessingSecurityScopedResource() }
            guard !Task.isCancelled else { return }

            guard let data else {
                isProcessing = false
                errorMessage = L10n.Errors.pdfReadFailed
                showErrorAlert = true
                return
            }

            // PDFDocument 不是 Sendable，必须在主线程创建
            guard let document = PDFDocument(data: data) else {
                isProcessing = false
                errorMessage = L10n.Errors.pdfParseFailed
                showErrorAlert = true
                return
            }

            guard document.pageCount > 0 else {
                isProcessing = false
                errorMessage = L10n.Errors.pdfEmpty
                showErrorAlert = true
                return
            }

            isProcessing = false
            router.pdfDocument = document
            router.push(.pdfPagePicker)
        }
    }

    // MARK: - Private Logic
    
    private func processImageOCR(_ image: UIImage, router: CaptureRouter) async {
        ocrTask = Task {
            do {
                guard let cgImage = image.cgImage else {
                    throw OCRError.invalidImage
                }
                let text = try await ocrService.recognizeText(from: cgImage)
                
                // 检查任务是否已取消
                try Task.checkCancellation()

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isProcessing = false
                    if text.isEmpty {
                        SnapDrillLogger.capture.warning("OCR 识别结果为空文本。")
                    }
                    router.push(.scannerResult(content: text, image: image))
                }
            } catch is CancellationError {
                SnapDrillLogger.capture.info("OCR 任务已取消。")
            } catch {
                SnapDrillLogger.capture.error("OCR 识别失败: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isProcessing = false
                    // 暂存图片和路由器，弹出重试 alert 让用户选择
                    self.pendingOCRImage = image
                    self.pendingOCRRouter = router
                    self.showOCRRetryAlert = true
                }
            }
        }
    }
    
    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?
    @ObservationIgnored
    private var pdfLoadTask: Task<Void, Never>?

    @ObservationIgnored
    private var photoLoadTask: Task<Void, Never>?

    /// 取消所有进行中的任务（由 View 的 onDisappear 调用）
    public func cancelOngoingTasks() {
        ocrTask?.cancel()
        ocrTask = nil
        photoLoadTask?.cancel()
        photoLoadTask = nil
        pdfLoadTask?.cancel()
        pdfLoadTask = nil
        isProcessing = false
    }
}

