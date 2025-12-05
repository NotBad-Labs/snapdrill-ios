//
//  CaptureOrchestratorTests.swift
//  NotBadTests
//
//  CaptureOrchestrator 单元测试
//

import Testing
import Foundation
import UIKit
@testable import NotBad

@Suite("CaptureOrchestrator 测试")
@MainActor
struct CaptureOrchestratorTests {

    @Test("初始状态正确")
    func initialState() {
        let orchestrator = CaptureOrchestrator()
        
        #expect(orchestrator.currentStep == .selectImage)
        #expect(orchestrator.isSaving == false)
        #expect(orchestrator.showAlert == false)
    }
    
    @Test("处理新图片切换步骤")
    func handleNewImage() {
        let orchestrator = CaptureOrchestrator()
        let image = UIImage() // 空图片对象
        
        orchestrator.handleNewImage(image)
        
        #expect(orchestrator.imageSelectionVM.selectedUIImage == image)
        #expect(orchestrator.currentStep == .fillForm)
    }
    
    @Test("重置状态")
    func reset() {
        let orchestrator = CaptureOrchestrator()
        orchestrator.currentStep = .review
        orchestrator.isSaving = true
        
        orchestrator.reset()
        
        #expect(orchestrator.currentStep == .selectImage)
        #expect(orchestrator.isSaving == false)
        #expect(orchestrator.imageSelectionVM.selectedImage == nil)
    }
}
