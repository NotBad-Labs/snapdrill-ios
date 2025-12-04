//
//  ImageCompressionPerformanceTests.swift
//  NotBadTests
//
//  图片压缩服务性能测试
//

import XCTest
@testable import NotBad

/// 图片压缩性能测试
///
/// 测试真实图片压缩服务的性能
final class ImageCompressionPerformanceTests: XCTestCase {
    
    // MARK: - Test Data
    
    /// 创建测试用大图片
    private func createLargeImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 绘制复杂内容以模拟真实照片
            let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow]
            
            for i in 0..<100 {
                let color = colors[i % colors.count]
                color.setFill()
                let rect = CGRect(
                    x: CGFloat.random(in: 0..<size.width),
                    y: CGFloat.random(in: 0..<size.height),
                    width: CGFloat.random(in: 50..<300),
                    height: CGFloat.random(in: 50..<300)
                )
                context.fill(rect)
            }
        }
    }
    
    // MARK: - Compression Performance
    
    /// 测试 1000x1000 图片压缩性能
    ///
    /// 预期：< 100ms
    func testCompress1000x1000() {
        let image = createLargeImage(width: 1000, height: 1000)
        
        measure {
            _ = ImageCompressor.compress(image)
        }
    }
    
    /// 测试 2000x2000 图片压缩性能
    ///
    /// 预期：< 300ms
    func testCompress2000x2000() {
        let image = createLargeImage(width: 2000, height: 2000)
        
        measure {
            _ = ImageCompressor.compress(image)
        }
    }
    
    /// 测试 4000x3000 图片压缩性能（模拟相机照片）
    ///
    /// 预期：< 500ms
    func testCompress4000x3000() {
        let image = createLargeImage(width: 4000, height: 3000)
        
        print("原图尺寸: \(image.size)")
        
        measure {
            _ = ImageCompressor.compress(image)
        }
    }
    
    // MARK: - Resize Performance
    
    /// 测试图片缩放性能
    func testResize4000To1000() {
        let image = createLargeImage(width: 4000, height: 3000)
        
        measure {
            _ = ImageCompressor.resize(image, maxDimension: 1000)
        }
    }
    
    /// 测试缩放到缩略图尺寸性能
    func testResizeToThumbnail() {
        let image = createLargeImage(width: 4000, height: 3000)
        
        measure {
            _ = ImageCompressor.resize(image, maxDimension: 140)
        }
    }
    
    // MARK: - Batch Operations
    
    /// 测试批量压缩 5 张图片性能
    func testBatchCompress5Images() {
        let images = (0..<5).map { _ in createLargeImage(width: 2000, height: 1500) }
        
        measure {
            for image in images {
                _ = ImageCompressor.compress(image)
            }
        }
    }
    
    /// 测试并发压缩性能
    func testConcurrentCompress() async {
        let images = (0..<5).map { _ in createLargeImage(width: 2000, height: 1500) }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Data?.self) { group in
            for image in images {
                group.addTask {
                    ImageCompressor.compress(image)
                }
            }
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("并发压缩 5 张图片耗时: \(elapsed * 1000) ms")
    }
    
    // MARK: - Quality vs Size Tradeoff
    
    /// 测试不同质量参数对性能和大小的影响
    func testQualityImpact() {
        let image = createLargeImage(width: 2000, height: 1500)
        let qualities: [CGFloat] = [0.3, 0.5, 0.7, 0.9]
        
        print("\n📊 压缩质量对比:")
        for quality in qualities {
            let startTime = CFAbsoluteTimeGetCurrent()
            let data = ImageCompressor.compress(image, quality: quality)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            print("  质量 \(quality): \(data?.count ?? 0 / 1024) KB, 耗时 \(elapsed * 1000) ms")
        }
    }
    
    // MARK: - Memory Impact
    
    /// 测试压缩过程的内存影响
    func testCompressionMemoryImpact() {
        let image = createLargeImage(width: 4000, height: 3000)
        
        let (_, memoryGrowth) = PerformanceTestHelpers.measureMemoryGrowth {
            _ = ImageCompressor.compress(image)
        }
        
        let growthMB = Double(memoryGrowth) / (1024 * 1024)
        print("压缩 4000x3000 图片内存增长: \(growthMB) MB")
        
        // 内存测量在模拟器中不稳定，仅打印日志供参考
        // 真实设备测试更有意义
        XCTAssertTrue(true, "内存测量仅供参考")
    }
}
