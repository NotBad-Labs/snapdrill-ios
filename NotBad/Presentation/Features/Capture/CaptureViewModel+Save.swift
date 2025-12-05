//
//  CaptureViewModel+Save.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI
import UIKit
import OSLog

// MARK: - Save Actions

extension CaptureViewModel {
    /// 进入预览步骤
    func proceedToReview() {
        guard isValid else { return }
        currentStep = .review
    }

    /// 保存错题
    func saveItem() {
        guard let modelContext else {
            Logger.data.error("保存失败：modelContext 为 nil")
            showErrorAlert(String(localized: "capture_save_error_context"))
            return
        }

        // 验证：必须有图片或来自实时扫描
        guard hasImage || isFromLiveScanner else {
            Logger.data.error("保存失败：无图片且非实时扫描")
            showErrorAlert(String(localized: "capture_save_error_no_image"))
            return
        }

        isSaving = true

        // 创建领域实体
        let newItem = ReviewItem(
            imageData: selectedImageData,  // 可为 nil（实时扫描模式）
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note,
            subject: subject,
            grade: grade,
            knowledgePoints: KnowledgePoints(from: knowledgePointsInput),
            difficulty: difficulty,
            errorType: errorType,
            source: source,
            reviewItemType: reviewItemType
        )

        Logger.data.info("创建 ReviewItem: id=\(newItem.id), title=\(newItem.title)")

        // 转换为持久化模型并插入
        let model = ReviewItemMapper.toModel(from: newItem)
        modelContext.insert(model)
        Logger.data.debug("insert 完成")

        do {
            try modelContext.save()
            Logger.data.info("✅ ReviewItem 保存成功: \(newItem.id)")

            // 触觉反馈 - 成功
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // 延迟显示成功提示，改善体验
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                self?.isSaving = false
                self?.showSuccessAlert(String(localized: "capture_save_success"))

                // 发送通知
                NotificationCenter.default.post(name: .reviewItemAdded, object: newItem)
            }
        } catch {
            Logger.data.error("❌ ReviewItem 保存失败: \(error.localizedDescription)")

            // 触觉反馈 - 失败
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            isSaving = false
            showErrorAlert(String(format: String(localized: "capture_save_error_generic"), error.localizedDescription))
        }
    }

    /// 保存并继续录入下一题
    func saveAndContinue() {
        saveItem()

        // 保存成功后重置（保留学科和年级）
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            self?.resetForm(keepSubjectAndGrade: true)
        }
    }

    /// 重置表单
    ///
    /// - Parameter keepSubjectAndGrade: 是否保留学科和年级设置
    func resetForm(keepSubjectAndGrade: Bool = false) {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
        title = ""
        note = ""
        knowledgePointsInput = ""
        recognizedText = ""
        currentStep = .selectImage

        if !keepSubjectAndGrade {
            subject = .math
            grade = CaptureViewModel.getUserDefaultGrade()
        }

        difficulty = .medium
        errorType = .other
        source = .other
        reviewItemType = .other
    }
}

// MARK: - Alert Helpers

extension CaptureViewModel {
    func showSuccessAlert(_ message: String) {
        alertType = .success
        alertMessage = message
        isSuccessAlert = true
        showAlert = true
    }

    func showWarningAlert(_ message: String) {
        alertType = .warning
        alertMessage = message
        isSuccessAlert = false
        showAlert = true
    }

    func showErrorAlert(_ message: String) {
        alertType = .error
        alertMessage = message
        isSuccessAlert = false
        showAlert = true
    }

    /// 显示验证错误
    func showValidationError() {
        let errors = validationErrors
        if !errors.isEmpty {
            showWarningAlert(errors.joined(separator: "\n"))
        }
    }
}
