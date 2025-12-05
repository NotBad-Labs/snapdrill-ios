//
//  EndToEndScenarioTests.swift
//  NotBadTests
//
//  端到端场景集成测试
//

import XCTest
@testable import NotBad

/// 端到端场景测试
///
/// 模拟真实用户操作流程的集成测试
final class EndToEndScenarioTests: XCTestCase {
    
    // MARK: - Capture Flow Tests
    
    /// 测试拍照 -> OCR -> 保存流程
    @MainActor
    func testCaptureToSaveFlow() async throws {
        // 1. 模拟拍照获取图片
        let capturedImage = TestImageFactory.createImage(size: .large)
        let imageData = TestImageFactory.createJPEGData(size: .large)
        
        // 2. 进行 OCR 识别（空白图片可能无法识别文字，这是预期行为）
        let ocrService = OCRService.shared
        var recognizedText = ""
        do {
            recognizedText = try await ocrService.recognizeText(from: capturedImage)
        } catch {
            // 空白图片无法识别文字是正常的
            print("OCR 未识别到文字（这是测试图片的预期行为）: \(error)")
        }
        
        // 3. 创建 ReviewItem
        let reviewItem = ReviewItem(
            imageData: imageData,
            title: recognizedText.isEmpty ? "手动输入的标题" : String(recognizedText.prefix(50)),
            subject: .math,
            grade: .grade10
        )
        
        // 4. 验证数据完整性
        XCTAssertNotNil(reviewItem.imageData)
        XCTAssertFalse(reviewItem.title.isEmpty)
        XCTAssertTrue(reviewItem.hasImage)
        
        print("模拟完成: 拍照 -> OCR(\(recognizedText.count)字) -> 创建题目")
    }
    
    /// 测试 CaptureOrchestrator 完整流程
    @MainActor
    func testCaptureOrchestratorFlow() async {
        let orchestrator = CaptureOrchestrator()
        
        // 1. 初始状态：选择图片
        XCTAssertEqual(orchestrator.currentStep, .selectImage)
        
        // 2. 模拟选择图片
        let imageData = TestImageFactory.createJPEGData(size: .medium)
        if let image = UIImage(data: imageData) {
            orchestrator.handleNewImage(image)
        }
        
        // 3. 状态应该转到填表
        XCTAssertEqual(orchestrator.currentStep, .fillForm)
        
        // 4. 填写表单
        orchestrator.formVM.title = "一元二次方程求解"
        orchestrator.formVM.subject = .math
        orchestrator.formVM.difficulty = .medium
        orchestrator.formVM.knowledgePointsInput = "方程, 因式分解"
        
        // 5. 验证表单状态
        XCTAssertEqual(orchestrator.formVM.title, "一元二次方程求解")
        XCTAssertEqual(orchestrator.formVM.subject, .math)
        XCTAssertEqual(orchestrator.formVM.parsedKnowledgePoints.count, 2)
    }
    
    // MARK: - Library Flow Tests
    
    /// 测试大数据量列表操作流程
    @MainActor
    func testLargeLibraryFlow() {
        // 创建 100 条模拟数据
        let items = TestReviewItemFactory.createRealisticDataset(count: 100)
        
        // 1. 测试筛选
        let mathItems = items.filter { $0.subject == .math }
        print("100 条中有 \(mathItems.count) 条数学题")
        
        // 2. 测试排序
        let sortedByDate = items.sorted { $0.createdAt > $1.createdAt }
        XCTAssertEqual(sortedByDate.count, 100)
        
        // 3. 测试搜索
        let searchResults = items.filter { $0.title.contains("数学") || $0.title.contains("物理") }
        print("搜索到 \(searchResults.count) 条结果")
        
        // 4. 测试分组
        let groupedBySubject = Dictionary(grouping: items, by: { $0.subject })
        print("按学科分组: \(groupedBySubject.keys.count) 个学科")
        
        // 5. 测试统计
        let needsReview = items.filter { $0.needsReview }.count
        let mastered = items.filter { $0.isMastered }.count
        print("需要复习: \(needsReview), 已掌握: \(mastered)")
    }
    
    /// 测试 LibraryViewModel 筛选流程
    @MainActor
    func testLibraryViewModelFilterFlow() {
        let viewModel = LibraryViewModel()
        
        // 模拟设置筛选条件（使用正确的单选 API）
        viewModel.selectSubject(.math)
        viewModel.selectMastery(.partial)
        viewModel.selectDifficulty(.hard)
        
        // 验证筛选状态
        XCTAssertNotNil(viewModel.selectedSubject)
        XCTAssertNotNil(viewModel.selectedMastery)
        XCTAssertNotNil(viewModel.selectedDifficulty)
        XCTAssertTrue(viewModel.hasActiveFilters)
        
        // 重置筛选
        viewModel.resetFilters()
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    // MARK: - Review Flow Tests
    
    /// 测试复习会话流程
    @MainActor
    func testReviewSessionFlow() {
        let viewModel = ReviewViewModel()
        
        // 1. 开始复习会话
        viewModel.startSession()
        XCTAssertEqual(viewModel.sessionState, .inProgress)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertNotNil(viewModel.sessionStartTime)
        
        // 2. 模拟进度
        viewModel.currentIndex = 5
        XCTAssertEqual(viewModel.currentIndex, 5)
        
        // 3. 结束会话
        viewModel.endSession()
        XCTAssertEqual(viewModel.sessionState, .completed)
    }
    
    // MARK: - Export Flow Tests
    
    /// 测试完整导出流程
    @MainActor
    func testExportFlow() {
        // 1. 选择要导出的题目
        let items = TestReviewItemFactory.createMixedBatch(count: 20, imageRatio: 0.5)
        
        // 2. 按学科筛选
        let mathAndPhysics = items.filter { $0.subject == .math || $0.subject == .physics }
        
        // 3. 导出 PDF
        let service = PDFExportService.shared
        let pdfData = service.exportToPDF(
            items: mathAndPhysics,
            title: "数学物理错题集",
            includeImages: true,
            includeNotes: true,
            showAnswerArea: true
        )
        
        // 4. 验证导出结果
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertTrue(pdfData.prefix(4) == Data([0x25, 0x50, 0x44, 0x46])) // %PDF
        
        print("导出 \(mathAndPhysics.count) 题，PDF 大小: \(pdfData.count / 1024) KB")
    }
    
    // MARK: - Dashboard Flow Tests
    
    /// 测试仪表盘数据计算流程
    @MainActor
    func testDashboardFlow() {
        let viewModel = DashboardViewModel()
        
        // 创建测试数据
        let items = TestReviewItemFactory.createRealisticDataset(count: 50)
        
        // 计算统计数据
        let stats = viewModel.computeStatistics(from: items)
        
        // 验证统计结果
        XCTAssertEqual(stats.totalCount, 50)
        XCTAssertGreaterThanOrEqual(stats.masteryRate, 0)
        XCTAssertLessThanOrEqual(stats.masteryRate, 1)
        
        print("仪表盘统计: 总数=\(stats.totalCount), 掌握率=\(Int(stats.masteryRate * 100))%")
    }
    
    // MARK: - Performance Scenario Tests
    
    /// 测试典型使用场景的整体性能
    @MainActor
    func testTypicalUsageScenarioPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. 加载列表 (100 条)
        let items = TestReviewItemFactory.createRealisticDataset(count: 100)
        let loadTime = CFAbsoluteTimeGetCurrent()
        
        // 2. 筛选 (多条件)
        let filtered = items.filter {
            $0.subject == .math &&
            $0.mastery != .mastered &&
            $0.needsReview
        }
        let filterTime = CFAbsoluteTimeGetCurrent()
        
        // 3. 排序
        let sorted = filtered.sorted { $0.nextReviewDate < $1.nextReviewDate }
        let sortTime = CFAbsoluteTimeGetCurrent()
        
        // 4. 生成缩略图 (模拟)
        for item in sorted.prefix(20) {
            if let data = item.imageData, let image = UIImage(data: data) {
                let _ = ImageCompressor.resize(image, maxDimension: 140)
            }
        }
        let thumbnailTime = CFAbsoluteTimeGetCurrent()
        
        // 报告各阶段时间
        print("""
        📊 典型使用场景性能报告:
        - 加载 100 条数据: \((loadTime - startTime) * 1000) ms
        - 多条件筛选: \((filterTime - loadTime) * 1000) ms
        - 排序: \((sortTime - filterTime) * 1000) ms
        - 生成 20 个缩略图: \((thumbnailTime - sortTime) * 1000) ms
        - 总计: \((thumbnailTime - startTime) * 1000) ms
        """)
        
        // 整个流程应该在 2 秒内完成
        XCTAssertLessThan(thumbnailTime - startTime, 2.0)
    }
}
