//
//  CaptureViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  相机拍摄、图库选图、OCR 识别的主 ViewModel。
//

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
@MainActor
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
    /// 是否弹出错误提示
    public var showErrorAlert = false
    /// 错误提示文本
    public var errorMessage = ""
    /// 是否正在显示 PDF 文件选择器
    public var isShowingPDFPicker = false
    
    // MARK: - Dependencies
    
    private let ocrService: OCRServiceProtocol
    
    // MARK: - Initialization
    
    /// 创建采集功能 ViewModel
    /// - Parameter ocrService: OCR 识别服务，默认使用 `OCRService()`
    public init(ocrService: OCRServiceProtocol = OCRService()) {
        self.ocrService = ocrService
    }
    
    // MARK: - Public API
    
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
                    self.errorMessage = "无法加载图片"
                    self.showErrorAlert = true
                }
            } catch is CancellationError {
                SnapDrillLogger.capture.info("相册加载任务已取消。")
            } catch {
                self.isProcessing = false
                self.errorMessage = "加载图片失败: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
        selectedPhotoItem = nil
    }
    
    /// 从剪贴板读取文本并跳转到编辑页
    ///
    /// 剪贴板为空或无文本时，展示错误提示。
    public func pasteFromClipboard(router: CaptureRouter) {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            router.push(.scannerResult(content: text, image: nil))
        } else {
            errorMessage = "剪贴板为空或没有可用的文本内容"
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
    
    /// 加载 PDF 文件并存入 Router，跳转到页面选择器
    ///
    /// 在安全域权限窗口内用 `Data(contentsOf:)` 完整读取文件数据，
    /// 再通过 `PDFDocument(data:)` 构建文档对象，避免权限释放后懒加载失败。
    ///
    /// - Parameters:
    ///   - url: 用户选择的 PDF 文件路径
    ///   - router: 采集模块路由器
    public func loadPDF(_ url: URL, router: CaptureRouter) {
        isProcessing = true
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
            isProcessing = false
        }

        // 在安全域权限窗口内完整读取数据，避免 PDFDocument 懒加载时权限已失效
        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "无法读取 PDF 文件"
            showErrorAlert = true
            return
        }

        guard let document = PDFDocument(data: data) else {
            errorMessage = "无法打开 PDF 文件"
            showErrorAlert = true
            return
        }

        guard document.pageCount > 0 else {
            errorMessage = "PDF 文件不包含任何页面"
            showErrorAlert = true
            return
        }

        router.pdfDocument = document
        router.push(.pdfPagePicker)
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
                        SnapDrillLogger.capture.warning("OCR returned empty text.")
                    }
                    router.push(.scannerResult(content: text, image: image))
                }
            } catch is CancellationError {
                SnapDrillLogger.capture.info("OCR Task cancelled.")
            } catch {
                SnapDrillLogger.capture.error("OCR Check failed: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isProcessing = false
                    // Even if OCR fails, pass the image
                    router.push(.scannerResult(content: "", image: image))
                }
            }
        }
    }
    
    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?

    @ObservationIgnored
    private var photoLoadTask: Task<Void, Never>?

    /// 取消所有进行中的任务（由 View 的 onDisappear 调用）
    public func cancelOngoingTasks() {
        ocrTask?.cancel()
        ocrTask = nil
        photoLoadTask?.cancel()
        photoLoadTask = nil
        isProcessing = false
    }
}

