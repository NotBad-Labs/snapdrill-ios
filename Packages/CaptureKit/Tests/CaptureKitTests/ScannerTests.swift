import Testing
import CoreGraphics
@testable import CaptureKit

@Suite("LiveDocumentDetector Tests")
struct LiveDocumentDetectorTests {
    
    @Test("默认配置")
    func testDefaultConfiguration() {
        let config = LiveDocumentDetector.Configuration()
        
        #expect(config.minimumConfidence == 0.6)
        #expect(config.minimumArea == 0.3)
        #expect(config.detectionFPS == 5)
    }
    
    @Test("自定义配置")
    func testCustomConfiguration() {
        let config = LiveDocumentDetector.Configuration(
            minimumConfidence: 0.8,
            minimumArea: 0.5,
            detectionFPS: 10
        )
        
        #expect(config.minimumConfidence == 0.8)
        #expect(config.minimumArea == 0.5)
        #expect(config.detectionFPS == 10)
    }
    
    @Test("检测结果 - 可拍照判断")
    func testDetectionResult_CanCapture() {
        let detected = LiveDocumentDetector.DetectionResult.detected(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
            corners: [],
            confidence: 0.9,
            area: 0.64
        )
        
        let notFound = LiveDocumentDetector.DetectionResult.notFound(reason: "测试")
        
        #expect(detected.canCapture == true)
        #expect(notFound.canCapture == false)
    }
    
    @Test("检测结果 - UI 提示")
    func testDetectionResult_Hint() {
        let detected = LiveDocumentDetector.DetectionResult.detected(
            boundingBox: .zero,
            corners: [],
            confidence: 0.9,
            area: 0.5
        )
        
        let lowConfidence = LiveDocumentDetector.DetectionResult.lowConfidence(0.5)
        
        #expect(detected.hint.contains("检测到文档"))
        #expect(lowConfidence.hint.contains("50%"))
    }
    
    @Test("检测结果 - 颜色指示")
    func testDetectionResult_Color() {
        let detected = LiveDocumentDetector.DetectionResult.detected(
            boundingBox: .zero,
            corners: [],
            confidence: 0.9,
            area: 0.5
        )
        
        let notFound = LiveDocumentDetector.DetectionResult.notFound(reason: "测试")
        
        #expect(detected.color == .green)
        #expect(notFound.color == .red)
    }
}

@Suite("ScanState Tests")
struct ScanStateTests {
    
    @Test("状态 - 可拍照判断")
    func testScanState_CanCapture() {
        let searching = ScanState.searching
        let detected = ScanState.detected(
            documentRect: .zero,
            confidence: 0.9
        )
        
        #expect(searching.canCapture == false)
        #expect(detected.canCapture == true)
    }
    
    @Test("状态 - 处理中判断")
    func testScanState_IsProcessing() {
        let searching = ScanState.searching
        let processing = ScanState.processing(progress: 0.5)
        
        #expect(searching.isProcessing == false)
        #expect(processing.isProcessing == true)
    }
}

@Suite("DraftScan Tests")
struct DraftScanTests {
    
    @Test("验证 - 有效扫描")
    func testDraftScan_Valid() {
        let validDraft = DraftScan(
            originalImage: Data(),
            processedImage: Data(),
            extractedText: "这是一道数学题，求解 x + 2 = 5",
            documentRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
            confidence: 0.9
        )
        
        #expect(validDraft.isValid == true)
    }
    
    @Test("验证 - 置信度过低")
    func testDraftScan_LowConfidence() {
        let lowConfidenceDraft = DraftScan(
            originalImage: Data(),
            processedImage: Data(),
            extractedText: "足够长的文字内容用于测试",
            documentRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
            confidence: 0.5  // 低于 0.6
        )
        
        #expect(lowConfidenceDraft.isValid == false)
    }
    
    @Test("验证 - 文字太少")
    func testDraftScan_InsufficientText() {
        let shortTextDraft = DraftScan(
            originalImage: Data(),
            processedImage: Data(),
            extractedText: "短文本",  // 少于 20 字符
            documentRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
            confidence: 0.9
        )
        
        #expect(shortTextDraft.isValid == false)
    }
    
    @Test("验证 - 文档区域太小")
    func testDraftScan_SmallDocument() {
        let smallDocDraft = DraftScan(
            originalImage: Data(),
            processedImage: Data(),
            extractedText: "足够长的文字内容用于测试",
            documentRect: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2),  // 面积 0.04 < 0.3
            confidence: 0.9
        )
        
        #expect(smallDocDraft.isValid == false)
    }
    
    @Test("验证错误 - 抛出异常")
    func testDraftScan_ValidationError() throws {
        let invalidDraft = DraftScan(
            originalImage: Data(),
            processedImage: Data(),
            extractedText: "短",
            documentRect: .zero,
            confidence: 0.5
        )
        
        #expect(throws: DraftScan.ValidationError.self) {
            try invalidDraft.validate()
        }
    }
}
