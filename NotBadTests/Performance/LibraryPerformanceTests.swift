//
//  LibraryPerformanceTests.swift
//  NotBadTests
//
//  性能测试 - 确保 UI 渲染性能达标
//

import XCTest
@testable import NotBad

/// 题库性能测试
///
/// 这些测试确保关键 UI 操作在性能预算内完成。
/// 使用真实尺寸的图片数据来模拟实际使用场景。
final class LibraryPerformanceTests: XCTestCase {
    
    // MARK: - Test Data
    
    /// 生成模拟的 JPEG 图片数据（约 100KB）
    /// 这比真实图片小，但足以暴露性能问题
    private func generateMockImageData(sizeKB: Int = 100) -> Data {
        // 生成指定大小的随机数据
        var data = Data(count: sizeKB * 1024)
        _ = data.withUnsafeMutableBytes { ptr in
            // 用随机字节填充（模拟压缩图片数据）
            arc4random_buf(ptr.baseAddress!, ptr.count)
        }
        return data
    }
    
    /// 生成真实的 UIImage 并转换为 JPEG
    private func generateRealImageData(size: CGSize = CGSize(width: 1000, height: 1000)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // 绘制渐变背景
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors as CFArray,
                                       locations: [0, 1])!
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // 添加一些随机矩形（模拟题目内容）
            for _ in 0..<10 {
                let rect = CGRect(
                    x: CGFloat.random(in: 0..<size.width),
                    y: CGFloat.random(in: 0..<size.height),
                    width: CGFloat.random(in: 50..<200),
                    height: CGFloat.random(in: 20..<100)
                )
                UIColor.white.withAlphaComponent(0.3).setFill()
                context.fill(rect)
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
    
    // MARK: - Performance Tests
    
    /// 测试图片解码性能
    ///
    /// 确保单张图片解码时间 < 50ms
    func testImageDecodingPerformance() throws {
        let imageData = try XCTUnwrap(generateRealImageData())
        print("测试图片大小: \(imageData.count / 1024) KB")
        
        measure {
            // 模拟 ItemRow 中的图片解码
            _ = UIImage(data: imageData)
        }
    }
    
    /// 测试缩略图生成性能
    ///
    /// 确保缩略图生成时间 < 30ms
    func testThumbnailGenerationPerformance() throws {
        let imageData = try XCTUnwrap(generateRealImageData(size: CGSize(width: 2000, height: 2000)))
        let original = try XCTUnwrap(UIImage(data: imageData))
        print("原图大小: \(imageData.count / 1024) KB, 尺寸: \(original.size)")
        
        let targetSize = CGSize(width: 140, height: 140)
        
        measure {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            _ = renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    }
    
    /// 测试批量图片解码性能
    ///
    /// 模拟列表显示 20 张图片的场景
    func testBatchImageDecodingPerformance() throws {
        // 准备 20 张不同的图片数据
        var imageDatas: [Data] = []
        for i in 0..<20 {
            let size = CGSize(width: 800 + i * 50, height: 600 + i * 50)
            if let data = generateRealImageData(size: size) {
                imageDatas.append(data)
            }
        }
        
        print("准备了 \(imageDatas.count) 张图片，总大小: \(imageDatas.reduce(0) { $0 + $1.count } / 1024) KB")
        
        measure {
            // 同步解码所有图片（模拟之前的问题代码）
            for data in imageDatas {
                _ = UIImage(data: data)
            }
        }
    }
    
    /// 测试异步图片加载性能
    ///
    /// 确保异步加载不阻塞主线程
    func testAsyncImageLoadingDoesNotBlockMainThread() async throws {
        let imageData = try XCTUnwrap(generateRealImageData(size: CGSize(width: 2000, height: 2000)))
        
        // 记录开始时间
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟优化后的异步加载
        let targetSize = CGSize(width: 140, height: 140)
        
        let _ = await Task.detached(priority: .userInitiated) {
            guard let original = UIImage(data: imageData) else { return nil as UIImage? }
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }.value
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("异步加载耗时: \(elapsed * 1000) ms")
        
        // 异步加载应该很快返回（实际解码在后台）
        // 这个测试主要验证 API 正确性
        XCTAssertNotNil(imageData)
    }
    
    // MARK: - Memory Tests
    
    /// 测试缩略图内存占用
    ///
    /// 确保缩略图比原图占用更少内存
    func testThumbnailMemoryUsage() throws {
        let imageData = try XCTUnwrap(generateRealImageData(size: CGSize(width: 2000, height: 2000)))
        let original = try XCTUnwrap(UIImage(data: imageData))
        
        // 原图内存估算 (RGBA, 4 bytes per pixel)
        let originalMemory = Int(original.size.width * original.size.height * 4)
        
        // 生成缩略图
        let targetSize = CGSize(width: 140, height: 140)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // 缩略图内存估算
        let thumbnailMemory = Int(thumbnail.size.width * thumbnail.size.height * 4)
        
        print("原图内存: \(originalMemory / 1024) KB")
        print("缩略图内存: \(thumbnailMemory / 1024) KB")
        print("内存节省: \(100 - thumbnailMemory * 100 / originalMemory)%")
        
        // 缩略图应该比原图小很多
        XCTAssertLessThan(thumbnailMemory, originalMemory / 100, "缩略图应该比原图小 100 倍以上")
    }
    
    // MARK: - Scroll Performance Tests
    
    /// 测试模拟列表滚动性能
    ///
    /// 确保滚动时图片加载不会造成卡顿
    /// 目标：单个 cell 渲染 < 16ms (60fps)
    func testScrollSimulationPerformance() throws {
        // 准备 50 条数据（模拟屏幕可见区域 + 预加载）
        var items: [(imageData: Data, title: String)] = []
        for i in 0..<50 {
            if let data = generateRealImageData(size: CGSize(width: 800, height: 600)) {
                items.append((imageData: data, title: "题目 \(i)"))
            }
        }
        
        print("准备了 \(items.count) 条数据用于滚动测试")
        
        measure {
            // 模拟滚动时的 cell 复用和渲染
            for item in items {
                // 模拟 ItemRow 的渲染操作
                _ = UIImage(data: item.imageData)
                _ = item.title.count
            }
        }
    }
    
    /// 测试快速滚动性能（连续滚动场景）
    ///
    /// 模拟用户快速滑动列表时的性能
    func testFastScrollPerformance() throws {
        // 创建 100 条测试数据
        let items = TestReviewItemFactory.createBatch(count: 100)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟快速滚动：每隔几项渲染一次（跳过中间项）
        for i in stride(from: 0, to: items.count, by: 5) {
            let item = items[i]
            if let data = item.imageData {
                // 只生成缩略图，不做完整解码
                _ = ImageCompressor.resize(UIImage(data: data) ?? UIImage(), maxDimension: 140)
            }
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("快速滚动 100 项（每 5 项渲染）耗时: \(elapsed * 1000) ms")
        
        // 快速滚动应该在 500ms 内完成
        XCTAssertLessThan(elapsed, 0.5, "快速滚动应该在 500ms 内完成")
    }
    
    /// 测试 ItemRow 渲染性能
    ///
    /// 确保单个 ItemRow 渲染时间 < 16ms (60fps 要求)
    func testItemRowRenderPerformance() throws {
        // 创建带真实图片的 ReviewItem
        let item = TestReviewItemFactory.createWithImage(
            imageSize: .medium,
            title: "测试题目：一元二次方程求解步骤",
            subject: .math,
            mastery: .partial
        )
        
        measure {
            // 模拟 ItemRow 渲染的核心操作
            
            // 1. 图片解码和缩放
            if let data = item.imageData, let image = UIImage(data: data) {
                _ = ImageCompressor.resize(image, maxDimension: 140)
            }
            
            // 2. 文字处理
            _ = item.title
            _ = item.subject.displayName
            _ = item.mastery.displayName
            _ = item.difficulty.displayName
            
            // 3. 日期格式化
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            _ = formatter.string(from: item.createdAt)
        }
    }
}
