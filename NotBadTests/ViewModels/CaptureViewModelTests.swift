//
//  CaptureViewModelTests.swift
//  NotBadTests
//
//  CaptureViewModel 单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("CaptureViewModel 测试")
@MainActor
struct CaptureViewModelTests {
    
    // MARK: - 初始化测试
    
    @Test("初始状态正确")
    func initialState() {
        let viewModel = CaptureViewModel()
        
        #expect(viewModel.selectedItem == nil)
        #expect(viewModel.selectedImage == nil)
        #expect(viewModel.selectedImageData == nil)
        #expect(viewModel.title == "")
        #expect(viewModel.note == "")
        #expect(viewModel.subject == .math)
        #expect(viewModel.grade == .grade10)
        #expect(viewModel.knowledgePointsInput == "")
        #expect(viewModel.difficulty == .medium)
        #expect(viewModel.errorType == .other)
        #expect(viewModel.source == .other)
        #expect(viewModel.questionType == .other)
        #expect(viewModel.currentStep == .selectImage)
        #expect(viewModel.isSaving == false)
        #expect(viewModel.isRecognizingText == false)
    }
    
    // MARK: - hasImage 测试
    
    @Test("hasImage 正确判断")
    func hasImageProperty() {
        let viewModel = CaptureViewModel()
        
        #expect(viewModel.hasImage == false)
        
        viewModel.selectedImageData = Data([0x00, 0x01])
        #expect(viewModel.hasImage == true)
    }
    
    // MARK: - 验证测试
    
    @Test("isValid 无图片且无识别文字时为 false")
    func isValidWithoutImage() {
        let viewModel = CaptureViewModel()
        viewModel.title = "测试标题"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test("isValid 无标题时为 false")
    func isValidWithoutTitle() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        
        #expect(viewModel.isValid == false)
    }
    
    @Test("isValid 有图片和标题时为 true")
    func isValidWithCompleteData() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        viewModel.title = "测试标题"
        
        #expect(viewModel.isValid == true)
    }
    
    @Test("isValid 实时扫描模式无图片但有标题时为 true")
    func isValidWithLiveScannerMode() {
        let viewModel = CaptureViewModel()
        viewModel.recognizedText = "扫描识别的文字"
        viewModel.title = "测试标题"
        // 无图片 (selectedImageData == nil)
        
        #expect(viewModel.isFromLiveScanner == true)
        #expect(viewModel.isValid == true)
    }
    
    @Test("isValid 空白标题时为 false")
    func isValidWithBlankTitle() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        viewModel.title = "   "
        
        #expect(viewModel.isValid == false)
    }
    
    @Test("validationErrors 无图片无扫描时返回图片错误")
    func validationErrorsProperty() {
        let viewModel = CaptureViewModel()
        
        let errors = viewModel.validationErrors
        
        #expect(errors.count == 2)
        #expect(errors.contains { $0.contains("图片") })
        #expect(errors.contains { $0.contains("标题") })
    }
    
    @Test("validationErrors 实时扫描模式不要求图片")
    func validationErrorsWithLiveScanner() {
        let viewModel = CaptureViewModel()
        viewModel.recognizedText = "扫描文字"
        viewModel.title = "标题"
        
        let errors = viewModel.validationErrors
        
        #expect(errors.isEmpty)
    }
    
    @Test("validationErrors 有图片后减少")
    func validationErrorsWithImage() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        
        let errors = viewModel.validationErrors
        
        #expect(errors.count == 1)
        #expect(errors.contains { $0.contains("标题") })
    }
    
    // MARK: - canProceed 测试
    
    @Test("canProceed 根据步骤判断")
    func canProceedByStep() {
        let viewModel = CaptureViewModel()
        
        // selectImage 步骤需要图片
        viewModel.currentStep = .selectImage
        #expect(viewModel.canProceed == false)
        
        viewModel.selectedImageData = Data([0x00])
        #expect(viewModel.canProceed == true)
        
        // recognize 步骤始终可以继续
        viewModel.currentStep = .recognize
        #expect(viewModel.canProceed == true)
        
        // fillForm 步骤需要 isValid
        viewModel.currentStep = .fillForm
        viewModel.title = ""
        #expect(viewModel.canProceed == false)
        
        viewModel.title = "测试"
        #expect(viewModel.canProceed == true)
        
        // review 步骤需要 isValid
        viewModel.currentStep = .review
        #expect(viewModel.canProceed == true)
    }
    
    // MARK: - 知识点测试
    
    @Test("addKnowledgePoint 添加知识点")
    func addKnowledgePointAction() {
        let viewModel = CaptureViewModel()
        
        viewModel.addKnowledgePoint("函数")
        #expect(viewModel.knowledgePointsInput == "函数")
        
        viewModel.addKnowledgePoint("极值")
        #expect(viewModel.knowledgePointsInput == "函数, 极值")
    }
    
    @Test("addKnowledgePoint 忽略空字符串")
    func addKnowledgePointIgnoresEmpty() {
        let viewModel = CaptureViewModel()
        
        viewModel.addKnowledgePoint("")
        #expect(viewModel.knowledgePointsInput == "")
        
        viewModel.addKnowledgePoint("   ")
        #expect(viewModel.knowledgePointsInput == "")
    }
    
    @Test("parsedKnowledgePoints 正确解析")
    func parsedKnowledgePointsProperty() {
        let viewModel = CaptureViewModel()
        viewModel.knowledgePointsInput = "函数, 极值, 导数"
        
        let points = viewModel.parsedKnowledgePoints
        
        #expect(points.count == 3)
        #expect(points.contains("函数"))
        #expect(points.contains("极值"))
        #expect(points.contains("导数"))
    }
    
    // MARK: - 图片操作测试
    
    @Test("clearImage 清除图片状态")
    func clearImageAction() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        viewModel.currentStep = .fillForm
        
        viewModel.clearImage()
        
        #expect(viewModel.selectedImageData == nil)
        #expect(viewModel.selectedImage == nil)
        #expect(viewModel.selectedUIImage == nil)
        #expect(viewModel.currentStep == .selectImage)
    }
    
    // MARK: - 实时扫描结果测试
    
    @Test("handleLiveScanResult 处理扫描结果")
    func handleLiveScanResultAction() {
        let viewModel = CaptureViewModel()
        
        viewModel.handleLiveScanResult("第一行\n第二行\n第三行")
        
        #expect(viewModel.recognizedText == "第一行\n第二行\n第三行")
        #expect(viewModel.title == "第一行")
        #expect(viewModel.note == "第一行\n第二行\n第三行")
        #expect(viewModel.currentStep == .fillForm)
    }
    
    @Test("handleLiveScanResult 标题长度限制")
    func handleLiveScanResultTitleLimit() {
        let viewModel = CaptureViewModel()
        let longText = String(repeating: "字", count: 100)
        
        viewModel.handleLiveScanResult(longText)
        
        #expect(viewModel.title.count == 50)
    }
    
    @Test("handleLiveScanResult 不覆盖已有标题")
    func handleLiveScanResultKeepsExistingTitle() {
        let viewModel = CaptureViewModel()
        viewModel.title = "已有标题"
        
        viewModel.handleLiveScanResult("新文字")
        
        #expect(viewModel.title == "已有标题")
    }
    
    // MARK: - proceedToReview 测试
    
    @Test("proceedToReview 有效时进入预览")
    func proceedToReviewValid() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        viewModel.title = "测试"
        
        viewModel.proceedToReview()
        
        #expect(viewModel.currentStep == .review)
    }
    
    @Test("proceedToReview 无效时不进入预览")
    func proceedToReviewInvalid() {
        let viewModel = CaptureViewModel()
        viewModel.currentStep = .fillForm
        
        viewModel.proceedToReview()
        
        #expect(viewModel.currentStep == .fillForm)
    }
    
    // MARK: - resetForm 测试
    
    @Test("resetForm 重置所有字段")
    func resetFormAction() {
        let viewModel = CaptureViewModel()
        viewModel.selectedImageData = Data([0x00])
        viewModel.title = "测试"
        viewModel.note = "笔记"
        viewModel.subject = .physics
        viewModel.grade = .grade11
        viewModel.difficulty = .hard
        viewModel.currentStep = .review
        
        viewModel.resetForm(keepSubjectAndGrade: false)
        
        #expect(viewModel.selectedImageData == nil)
        #expect(viewModel.title == "")
        #expect(viewModel.note == "")
        #expect(viewModel.subject == .math)
        #expect(viewModel.grade == .grade10)
        #expect(viewModel.difficulty == .medium)
        #expect(viewModel.currentStep == .selectImage)
    }
    
    @Test("resetForm 保留学科和年级")
    func resetFormKeepSubjectAndGrade() {
        let viewModel = CaptureViewModel()
        viewModel.subject = .physics
        viewModel.grade = .grade11
        
        viewModel.resetForm(keepSubjectAndGrade: true)
        
        #expect(viewModel.subject == .physics)
        #expect(viewModel.grade == .grade11)
    }
    
    // MARK: - CaptureStep 测试
    
    @Test("CaptureStep 所有步骤都有属性")
    func captureStepProperties() {
        for step in CaptureStep.allCases {
            #expect(!step.title.isEmpty)
            #expect(!step.icon.isEmpty)
        }
    }
    
    @Test("CaptureStep rawValue 顺序正确")
    func captureStepOrder() {
        #expect(CaptureStep.selectImage.rawValue == 0)
        #expect(CaptureStep.recognize.rawValue == 1)
        #expect(CaptureStep.fillForm.rawValue == 2)
        #expect(CaptureStep.review.rawValue == 3)
    }
    
    // MARK: - AlertType 测试
    
    @Test("AlertType 所有类型都有属性")
    func alertTypeProperties() {
        let types: [AlertType] = [.success, .warning, .error, .info]
        
        for type in types {
            #expect(!type.icon.isEmpty)
        }
    }
}
