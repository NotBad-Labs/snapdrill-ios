//
//  CaptureOrchestrator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import Observation
import SwiftData
import SwiftUI

// MARK: - Orchestrator Step

/// 协调器内部使用的步骤状态
enum OrchestratorStep: Int, CaseIterable {
    case selectImage = 0
    case fillForm = 1
    case review = 2
}

// MARK: - CaptureOrchestrator

/// 录入流程协调器
///
/// 负责管理录入流程的整体状态和步骤切换，协调各个子 ViewModel 的工作。
/// 采用有限状态机 (FSM) 思想，确保流程的单向流动。
@MainActor
@Observable
final class CaptureOrchestrator {
    
    // MARK: - Sub-ViewModels
    
    /// 图片选择 ViewModel
    var imageSelectionVM = ImageSelectionViewModel()
    
    /// OCR 处理 ViewModel
    var ocrVM = OCRViewModel()
    
    /// 表单编辑 ViewModel
    var formVM = ReviewItemFormViewModel()
    
    // MARK: - Global State
    
    /// 当前步骤
    var currentStep: OrchestratorStep = .selectImage
    
    /// 是否正在保存
    var isSaving: Bool = false
    
    /// 全局提示状态
    var showAlert: Bool = false
    var alertMessage: String = ""
    var isSuccessAlert: Bool = false
    
    // MARK: - Dependencies
    
    var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // 可以在这里设置 ViewModel 之间的联动
        // 例如：图片选择完成后，自动触发 OCR
    }
    
    // MARK: - Actions
    
    /// 处理新选择的图片
    func handleNewImage(_ image: UIImage) {
        // 1. 更新图片状态
        imageSelectionVM.handlePickedImage(image)
        
        // 2. 自动触发 OCR
        Task {
            if let text = await ocrVM.recognizeText(from: image) {
                // 3. 填充表单
                formVM.autoFill(with: text)
            }
        }
        
        // 4. 切换步骤
        currentStep = .fillForm
    }
    
    /// 保存错题
    func save() {
        guard let context = modelContext else { return }
        guard let imageData = imageSelectionVM.selectedImageData else {
            showAlert(message: String(localized: "capture_validation_image_required"))
            return
        }
        
        if formVM.title.isEmpty {
            showAlert(message: String(localized: "capture_validation_title_required"))
            return
        }
        
        isSaving = true
        
        // 创建 ReviewItemModel（持久化模型）
        let newModel = ReviewItemModel(
            imageData: imageData,
            title: formVM.title,
            note: formVM.note,
            subjectRaw: formVM.subject.rawValue,
            gradeRaw: formVM.grade.rawValue,
            knowledgePointsRaw: formVM.knowledgePointsInput,
            difficultyRaw: formVM.difficulty.rawValue,
            errorTypeRaw: formVM.errorType.rawValue,
            sourceRaw: formVM.source.rawValue,
            reviewItemTypeRaw: formVM.reviewItemType.rawValue
        )
        
        // 保存到数据库
        context.insert(newModel)
        
        do {
            try context.save()
            
            // 创建领域实体用于通知
            let entity = ReviewItemMapper.toEntity(from: newModel)
            
            // 发送通知
            NotificationCenter.default.post(name: .reviewItemAdded, object: entity)
            
            // 显示成功提示
            showAlert(message: String(localized: "capture_save_success"), isSuccess: true)
            
        } catch {
            showAlert(message: "保存失败: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    /// 重置所有状态
    func reset() {
        imageSelectionVM.reset()
        ocrVM.reset()
        formVM.reset()
        currentStep = .selectImage
        isSaving = false
    }
    
    // MARK: - Helper
    
    private func showAlert(message: String, isSuccess: Bool = false) {
        self.alertMessage = message
        self.isSuccessAlert = isSuccess
        self.showAlert = true
    }
}
