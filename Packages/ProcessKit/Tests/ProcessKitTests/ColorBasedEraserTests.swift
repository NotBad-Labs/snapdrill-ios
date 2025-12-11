import Testing
@testable import ProcessKit

@Suite("ColorBasedEraser Tests")
struct ColorBasedEraserTests {
    
    let eraser = ColorBasedEraser()
    
    @Test("预定义颜色范围")
    func testPredefinedRanges() {
        // 蓝色范围
        let blue = ColorBasedEraser.blueInkRange
        #expect(blue.hue == 200...240)
        #expect(blue.saturation == 0.3...1.0)
        
        // 红色范围
        let red = ColorBasedEraser.redInkRange
        #expect(red.hue == 0...20)
        #expect(red.saturation == 0.5...1.0)
        
        // 铅笔范围（低饱和度）
        let pencil = ColorBasedEraser.pencilRange
        #expect(pencil.saturation == 0...0.15)
    }
    
    // TODO: 添加实际图片处理测试
    // @Test("擦除蓝色笔迹")
    // func testRemoveBlueInk() async throws { ... }
}
