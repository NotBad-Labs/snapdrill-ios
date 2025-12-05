//
//  OCRViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import Observation
import UIKit

// MARK: - OCRViewModel

/// OCR 识别视图模型
///
/// 负责调用 OCR 服务，管理识别状态和结果。
@MainActor
@Observable
final class OCRViewModel {
    
    // MARK: - State
    
    /// 是否正在识别
    var isRecognizing: Bool = false
    
    /// 识别出的文本
    var recognizedText: String = ""
    
    // MARK: - Dependencies
    
    private let ocrService = OCRService.shared
    
    // MARK: - Actions
    
    /// 识别图片中的文本
    /// - Parameter image: 目标图片
    /// - Returns: 识别出的文本（如果成功）
    func recognizeText(from image: UIImage) async -> String? {
        isRecognizing = true
        defer { isRecognizing = false }
        
        do {
            let text = try await ocrService.recognizeText(from: image)
            self.recognizedText = text
            return text
        } catch {
            print("OCR failed: \(error)")
            return nil
        }
    }
    
    /// 重置状态
    func reset() {
        isRecognizing = false
        recognizedText = ""
    }
}
