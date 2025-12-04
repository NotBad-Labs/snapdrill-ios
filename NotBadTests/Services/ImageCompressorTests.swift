//
//  ImageCompressorTests.swift
//  NotBadTests
//
//  Phase 6: 图片压缩器测试
//

import Testing
import Foundation
import UIKit
@testable import NotBad

// MARK: - ImageCompressor Tests

@Suite("ImageCompressor 测试")
struct ImageCompressorTests {
    
    // MARK: - 配置测试
    
    @Test("默认配置正确")
    func defaultConfiguration() {
        #expect(ImageCompressor.defaultQuality == 0.7)
        #expect(ImageCompressor.defaultMaxDimension == 2048)
    }
    
    // MARK: - 压缩测试
    
    @Test("compress 压缩图片返回数据")
    func compressReturnsData() {
        // 创建一个简单的测试图片
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        let data = ImageCompressor.compress(image)
        
        #expect(data != nil)
        #expect(data!.count > 0)
    }
    
    @Test("compress 使用自定义质量")
    func compressWithCustomQuality() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        let highQuality = ImageCompressor.compress(image, quality: 1.0)
        let lowQuality = ImageCompressor.compress(image, quality: 0.1)
        
        #expect(highQuality != nil)
        #expect(lowQuality != nil)
        // 高质量压缩应该产生更大的数据
        #expect(highQuality!.count >= lowQuality!.count)
    }
    
    // MARK: - 调整大小测试
    
    @Test("resize 调整图片大小")
    func resizeAdjustsImageSize() {
        // 创建大图片
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4000, height: 3000))
        let largeImage = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4000, height: 3000))
        }
        
        let resized = ImageCompressor.resize(largeImage, maxDimension: 1000)
        
        // 最大尺寸应该是 1000
        #expect(resized.size.width <= 1000)
        #expect(resized.size.height <= 1000)
    }
    
    @Test("resize 保持宽高比")
    func resizePreservesAspectRatio() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        let image = renderer.image { context in
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
        }
        
        let resized = ImageCompressor.resize(image, maxDimension: 100)
        
        // 应该保持 2:1 的宽高比
        let ratio = resized.size.width / resized.size.height
        #expect(abs(ratio - 2.0) < 0.01)
    }
    
    @Test("resize 小图片不放大")
    func resizeDoesNotEnlargeSmallImages() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        let smallImage = renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }
        
        let resized = ImageCompressor.resize(smallImage, maxDimension: 1000)
        
        // 小图片不应该被放大
        #expect(resized.size.width == 50)
        #expect(resized.size.height == 50)
    }
    
    // MARK: - 大小估算测试
    
    @Test("estimateSize 返回 KB 值")
    func estimateSizeReturnsKB() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.purple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        let size = ImageCompressor.estimateSize(image)
        
        #expect(size >= 0)
    }
}

// MARK: - MockImageCompressor Tests

@Suite("MockImageCompressor 测试")
struct MockImageCompressorTests {
    
    @Test("默认配置与 ImageCompressor 一致")
    func defaultConfigurationMatchesReal() {
        #expect(MockImageCompressor.defaultQuality == ImageCompressor.defaultQuality)
        #expect(MockImageCompressor.defaultMaxDimension == ImageCompressor.defaultMaxDimension)
    }
    
    @Test("compress 返回 Mock 数据")
    func compressReturnsMockData() {
        MockImageCompressor.reset()
        let mockData = Data([0x01, 0x02, 0x03])
        MockImageCompressor.mockCompressedData = mockData
        
        let result = MockImageCompressor.compress(UIImage())
        
        #expect(result == mockData)
        #expect(MockImageCompressor.compressCallCount == 1)
    }
    
    @Test("compress 可以返回 nil")
    func compressCanReturnNil() {
        MockImageCompressor.reset()
        MockImageCompressor.shouldReturnNil = true
        
        let result = MockImageCompressor.compress(UIImage())
        
        #expect(result == nil)
    }
    
    @Test("resize 追踪调用")
    func resizeTracksCall() {
        MockImageCompressor.reset()
        let image = UIImage()
        
        _ = MockImageCompressor.resize(image, maxDimension: 500)
        
        #expect(MockImageCompressor.resizeCallCount == 1)
        #expect(MockImageCompressor.lastMaxDimension == 500)
    }
    
    @Test("estimateSize 返回 Mock 值")
    func estimateSizeReturnsMockValue() {
        MockImageCompressor.reset()
        MockImageCompressor.mockEstimatedSize = 256
        
        let size = MockImageCompressor.estimateSize(UIImage())
        
        #expect(size == 256)
        #expect(MockImageCompressor.estimateSizeCallCount == 1)
    }
    
    @Test("reset 清除所有状态")
    func resetClearsAllState() {
        // 首先重置以确保干净状态
        MockImageCompressor.reset()
        
        // 设置一些状态
        MockImageCompressor.mockCompressedData = Data([0xFF])
        MockImageCompressor.shouldReturnNil = true
        MockImageCompressor.mockEstimatedSize = 999
        _ = MockImageCompressor.compress(UIImage())
        _ = MockImageCompressor.resize(UIImage())
        _ = MockImageCompressor.estimateSize(UIImage())
        
        // 执行 reset
        MockImageCompressor.reset()
        
        // 验证状态被清除
        #expect(MockImageCompressor.compressCallCount == 0)
        #expect(MockImageCompressor.resizeCallCount == 0)
        #expect(MockImageCompressor.estimateSizeCallCount == 0)
        #expect(MockImageCompressor.shouldReturnNil == false)
        #expect(MockImageCompressor.mockEstimatedSize == 100)
    }
}

// MARK: - ImageCompressorProtocol Conformance Tests

@Suite("ImageCompressorProtocol 协议测试")
struct ImageCompressorProtocolTests {
    
    @Test("ImageCompressor 符合 ImageCompressorProtocol")
    func imageCompressorConformsToProtocol() {
        // 静态方法测试
        #expect(ImageCompressor.defaultQuality == 0.7)
        #expect(ImageCompressor.defaultMaxDimension == 2048)
    }
    
    @Test("MockImageCompressor 符合 ImageCompressorProtocol")
    func mockImageCompressorConformsToProtocol() {
        #expect(MockImageCompressor.defaultQuality == 0.7)
        #expect(MockImageCompressor.defaultMaxDimension == 2048)
    }
}
