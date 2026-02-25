//
//  CaptureViewModel.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
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
    
    public func processScannedImage(_ image: UIImage, router: CaptureRouter) {
        isProcessing = true
        Task {
            await processImageOCR(image, router: router)
        }
    }
    
    // MARK: - Private Logic
    
    private func processImageOCR(_ image: UIImage, router: CaptureRouter) async {
        do {
            guard let cgImage = image.cgImage else {
                throw OCRError.invalidImage
            }
            let text = try await ocrService.recognizeText(from: cgImage)
    
            await MainActor.run {
                self.isProcessing = false
                if text.isEmpty {
                    SnapDrillLogger.capture.warning("OCR returned empty text.")
                }
                router.push(.scannerResult(content: text, image: image))
            }
        } catch {
            SnapDrillLogger.capture.error("OCR Check failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isProcessing = false
                // Even if OCR fails, pass the image
                router.push(.scannerResult(content: "", image: image))
            }
        }
    }
}

