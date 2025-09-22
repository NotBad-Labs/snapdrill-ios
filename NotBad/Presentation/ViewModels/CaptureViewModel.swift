//
//  CaptureViewModel.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI
import Combine
import UIKit

/// 拍照功能的视图模型
/// 负责管理拍照相关的UI状态和业务逻辑协调
@MainActor
final class CaptureViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// 是否显示相机界面
    @Published var showCamera = false
    
    /// 是否显示照片库
    @Published var showPhotoLibrary = false
    
    /// 是否正在处理OCR
    @Published var isProcessingOCR = false
    
    /// OCR处理进度 (0.0 - 1.0)
    @Published var ocrProgress: Double = 0.0
    
    /// 当前拍摄的图片
    @Published var capturedImage: UIImage?
    
    /// OCR识别结果
    @Published var ocrResult: OCRResult?
    
    // MARK: - Dependencies
    
    private let captureUseCase: CaptureReviewItemUseCase
    private weak var coordinator: CaptureCoordinator?
    private weak var errorHandler: AppErrorHandler?
    
    // MARK: - Initialization
    
    init(
        captureUseCase: CaptureReviewItemUseCase,
        coordinator: CaptureCoordinator
    ) {
        self.captureUseCase = captureUseCase
        self.coordinator = coordinator
    }

    /// 配置全局错误处理器（在View中从AppEnvironment注入）
    func configure(errorHandler: AppErrorHandler) {
        self.errorHandler = errorHandler
    }
    
    // MARK: - Public Interface
    
    /// 显示相机
    func showCameraView() {
        showCamera = true
    }
    
    /// 显示照片库
    func showPhotoLibraryView() {
        showPhotoLibrary = true
    }
    
    /// 处理拍摄的照片
    func handleCapturedImage(_ image: UIImage) {
        capturedImage = image
        showCamera = false
        
        Task {
            await processImageWithOCR(image)
        }
    }
    
    /// 处理从照片库选择的图片
    func handleSelectedImage(_ image: UIImage) {
        capturedImage = image
        showPhotoLibrary = false
        
        Task {
            await processImageWithOCR(image)
        }
    }
    
    /// 重新拍照
    func retakePhoto() {
        capturedImage = nil
        ocrResult = nil
        showCameraView()
    }
    
    /// 保存OCR结果为题目（改为进入保存表单，由用户补全信息）
    func saveAsReviewItem() {
        guard let result = ocrResult else {
            errorHandler?.present(message: "没有OCR结果可保存")
            return
        }
        // 组合一个可编辑的初始文本，交由后续编辑/保存页面处理
        var content = "题目：\(result.question)\n答案：\(result.answer)"
        if let notes = result.notes, !notes.isEmpty {
            content += "\n备注：\(notes)"
        }
        coordinator?.coordinate(to: .saveReviewItem(content: content))
    }
    
    /// 跳转到手动输入
    func navigateToManualInput() {
        // 直接进入保存表单，用户手动输入
        coordinator?.coordinate(to: .saveReviewItem(content: ""))
    }
    
    /// 清除错误信息
    func clearError() {
        // 保留占位，兼容旧调用；实际错误展示由 AppErrorHandler 统一处理
    }
    
    // MARK: - Private Methods
    
    /// 使用OCR处理图片
    private func processImageWithOCR(_ image: UIImage) async {
        isProcessingOCR = true
        ocrProgress = 0.0
        
        do {
            try Task.checkCancellation()
            // 模拟进度更新
            withAnimation(.easeInOut(duration: 0.5)) {
                ocrProgress = 0.3
            }
            
            // 调用OCR处理（这里需要实际的OCR实现）
            let result = try await performOCRProcessing(image)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                ocrProgress = 1.0
            }
            
            // 延迟以显示完成动画
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 500_000_000)
            try Task.checkCancellation()
            
            ocrResult = result
            isProcessingOCR = false
            ocrProgress = 0.0
            // 自动进入保存表单，用户可在表单中补全/修正信息
            if !Task.isCancelled {
                saveAsReviewItem()
            }
            
        } catch {
            isProcessingOCR = false
            ocrProgress = 0.0
            errorHandler?.handle(error)
        }
    }
    
    /// 执行OCR处理（临时实现）
    private func performOCRProcessing(_ image: UIImage) async throws -> OCRResult {
        // TODO: 实现真正的OCR处理
        // 这里返回一个模拟结果
        return OCRResult(
            question: "从图片中识别的题目",
            answer: "从图片中识别的答案",
            notes: "OCR识别备注",
            confidence: 0.95
        )
    }
    
}

// MARK: - Supporting Types

/// OCR识别结果
struct OCRResult: Sendable {
    let question: String
    let answer: String
    let notes: String?
    let confidence: Double
}