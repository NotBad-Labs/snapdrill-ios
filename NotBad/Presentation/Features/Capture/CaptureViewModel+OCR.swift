//
//  CaptureViewModel+OCR.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI
import OSLog

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

            isRecognizingText = false
            currentStep = .fillForm

            // 启动智能分析（异步，不阻塞）
            if smartAnalysisAvailable {
                Task {
                    await performSmartAnalysis(text: result)
                }
            }

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
        suggestedSubject = nil
        subjectWasAutoSelected = false
        await recognizeText()
    }

    /// 处理实时扫描结果
    func handleLiveScanResult(_ text: String, imageData: Data?) {
        Logger.ocr.info("handleLiveScanResult: text长度=\(text.count), 图片=\(imageData?.count ?? 0) bytes")
        
        // 关闭扫描器界面
        showLiveScanner = false
        isFromLiveScanner = true
        
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

        currentStep = .fillForm
        
        // 启动智能分析（异步，不阻塞）
        if smartAnalysisAvailable {
            Task {
                await performSmartAnalysis(text: text)
            }
        }

        Logger.ocr.debug("处理结果: title=\(self.title), hasImage=\(self.hasImage), isValid=\(self.isValid)")
    }
}

// MARK: - Smart Analysis

extension CaptureViewModel {
    /// 执行智能分析
    ///
    /// 使用 Apple Intelligence 分析题目内容，自动识别科目并生成标题建议
    func performSmartAnalysis(text: String) async {
        guard !text.isEmpty else { return }
        guard smartAnalysisAvailable else { return }
        
        isAnalyzing = true
        
        do {
            let result = try await smartAnalysisService.analyze(text: text)
            
            Logger.ai.info("科目: \(result.suggestedSubject.displayName), 置信度: \(result.confidence)")
            Logger.ai.debug("标题建议: \(result.suggestedTitle)")
            
            // 自动选择科目
            suggestedSubject = result.suggestedSubject
            subject = result.suggestedSubject
            subjectWasAutoSelected = true
            
            // 如果标题仍是默认提取的（第一行），且 AI 生成了更好的标题，则替换
            if result.confidence >= 0.7 && !result.suggestedTitle.isEmpty {
                let firstLine = recognizedText.components(separatedBy: .newlines).first ?? ""
                if title == String(firstLine.prefix(50)) {
                    title = result.suggestedTitle
                }
            }
            
            isAnalyzing = false
        } catch {
            Logger.ai.error("分析失败: \(error.localizedDescription)")
            isAnalyzing = false
            // 分析失败不影响正常流程，静默处理
        }
    }
    
    /// 手动触发智能分析
    func triggerSmartAnalysis() async {
        await performSmartAnalysis(text: recognizedText)
    }
}