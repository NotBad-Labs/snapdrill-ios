//
//  CaptureViewModel+OCR.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI

// MARK: - OCR Actions

extension CaptureViewModel {
    /// 识别图片中的文字
    func recognizeText() async {
        guard let image = selectedUIImage else { return }

        isRecognizingText = true

        do {
            let result = try await ocrService.recognizeText(from: image)
            recognizedText = result

            // 提取标题
            let extractedTitle = ocrService.extractTitle(from: result)
            if title.isEmpty {
                title = extractedTitle
            }

            // 填充笔记
            if note.isEmpty {
                note = result
            }

            isRecognizingText = false
            currentStep = .fillForm

            showSuccessAlert(String(localized: "capture_ocr_success"))
        } catch {
            isRecognizingText = false
            currentStep = .fillForm

            showWarningAlert(String(format: String(localized: "capture_ocr_failure"), error.localizedDescription))
        }
    }

    /// 重新识别
    func retryRecognition() async {
        recognizedText = ""
        title = ""
        note = ""
        await recognizeText()
    }

    /// 处理实时扫描结果
    func handleLiveScanResult(_ text: String, imageData: Data?) {
        #if DEBUG
        print("🔍 [CaptureVM] handleLiveScanResult: text长度=\(text.count), 图片=\(imageData?.count ?? 0) bytes")
        #endif
        recognizedText = text
        
        // 保存截图
        if let imageData = imageData {
            selectedImageData = imageData
            if let uiImage = UIImage(data: imageData) {
                selectedImage = Image(uiImage: uiImage)
                selectedUIImage = uiImage
            }
        }

        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if title.isEmpty {
            title = String(firstLine.prefix(50))
        }

        if note.isEmpty {
            note = text
        }

        currentStep = .fillForm

        #if DEBUG
        print("🔍 [CaptureVM] 处理结果: title=\(title), hasImage=\(hasImage), isValid=\(isValid)")
        #endif
    }
}
