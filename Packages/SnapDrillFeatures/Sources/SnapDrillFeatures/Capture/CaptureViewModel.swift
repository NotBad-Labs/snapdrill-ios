//
//  CaptureViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Observation
import SnapDrillCore
import SwiftUI
import PhotosUI

@Observable
@MainActor
public final class CaptureViewModel {
    
    // MARK: - State
    
    public var isShowingScanner = false
    public var selectedPhotoItem: PhotosPickerItem?
    public var isProcessing = false
    public var isViewActive = false
    public var showDraftAlert = false
    public var pendingDraft: CaptureDraftService.Draft? = nil
    public var showErrorAlert = false
    public var errorMessage = ""
    
    // MARK: - Dependencies
    
    private let ocrService: OCRServiceProtocol
    
    // MARK: - Initialization
    
    public init(ocrService: OCRServiceProtocol = OCRService()) {
        self.ocrService = ocrService
    }
    
    // MARK: - Public API
    
    public func checkDraftOnAppear() {
        if let draft = CaptureDraftService.shared.loadDraft() {
            pendingDraft = draft
            showDraftAlert = true
        }
    }
    
    public func startEditingDraft(router: CaptureRouter) {
        if let draft = pendingDraft {
            router.push(.scannerResult(content: draft.content, image: draft.image))
        }
        clearDraft()
    }
    
    public func clearDraft() {
        CaptureDraftService.shared.clearDraft()
        pendingDraft = nil
    }
    
    public func loadPhoto(_ item: PhotosPickerItem, router: CaptureRouter) {
        isProcessing = true
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await processImageOCR(image, router: router)
                } else {
                    await MainActor.run {
                        self.isProcessing = false
                        self.errorMessage = "无法加载图片"
                        self.showErrorAlert = true
                    }
                }
            } catch {
                 await MainActor.run {
                     self.isProcessing = false
                     self.errorMessage = "加载图片失败: \(error.localizedDescription)"
                     self.showErrorAlert = true
                 }
            }
        }
        selectedPhotoItem = nil // Reset picker
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

    public func processScannedImage(_ image: UIImage, router: CaptureRouter) {
        isProcessing = true
        Task {
            await processImageOCR(image, router: router)
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
    nonisolated(unsafe) private var ocrTask: Task<Void, Never>?
    
    public func cancelOngoingTasks() {
        ocrTask?.cancel()
        ocrTask = nil
        isProcessing = false
    }
    
    deinit {
        ocrTask?.cancel()
    }
}

