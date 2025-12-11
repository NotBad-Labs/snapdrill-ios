import Testing
import CoreGraphics
@testable import ProcessKit

@Suite("ImageProcessor Tests")
struct ImageProcessorTests {
    
    @Test("默认配置")
    func testDefaultConfiguration() {
        let config = ImageProcessor.Configuration()
        
        #expect(config.modelName == "HandwritingSegmentation")
        #expect(config.maxProcessingSize.width == 2048)
        #expect(config.maxProcessingSize.height == 2048)
        #expect(config.useNeuralEngine == true)
    }
    
    @Test("自定义配置")
    func testCustomConfiguration() {
        let config = ImageProcessor.Configuration(
            modelName: "CustomModel",
            maxProcessingSize: CGSize(width: 1024, height: 1024),
            useNeuralEngine: false
        )
        
        #expect(config.modelName == "CustomModel")
        #expect(config.maxProcessingSize.width == 1024)
        #expect(config.useNeuralEngine == false)
    }
    
    // TODO: 添加实际处理测试
    // @Test("Core ML 模型加载")
    // func testModelLoading() async throws { ... }
}
