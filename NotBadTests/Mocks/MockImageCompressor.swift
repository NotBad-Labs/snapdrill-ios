//
//  MockImageCompressor.swift
//  NotBadTests
//
//  图片压缩器的 Mock 实现
//

import UIKit
@testable import NotBad

// MARK: - MockImageCompressor

/// 图片压缩器的 Mock 实现
///
/// 用于单元测试，可以控制压缩结果和追踪方法调用。
///
/// ## 使用示例
///
/// ```swift
/// @Test("图片压缩成功")
/// func testImageCompress() {
///     MockImageCompressor.reset()
///     MockImageCompressor.mockCompressedData = Data([0xFF, 0xD8])
///     
///     let result = MockImageCompressor.compress(UIImage())
///     
///     #expect(result != nil)
///     #expect(MockImageCompressor.compressCallCount == 1)
/// }
/// ```
enum MockImageCompressor: ImageCompressorProtocol {
    
    // MARK: - Configuration
    
    static let defaultQuality: CGFloat = 0.7
    static let defaultMaxDimension: CGFloat = 2048
    
    // MARK: - Mock Configuration
    // 使用 nonisolated(unsafe) 因为这是测试专用的 Mock
    // 在实际测试中由测试框架保证线程安全
    
    nonisolated(unsafe) private static var _mockCompressedData: Data? = Data([0xFF, 0xD8]) // JPEG header
    nonisolated(unsafe) private static var _mockResizedImage: UIImage? = nil
    nonisolated(unsafe) private static var _mockEstimatedSize: Int = 100
    nonisolated(unsafe) private static var _shouldReturnNil: Bool = false
    
    nonisolated(unsafe) private static var _compressCallCount: Int = 0
    nonisolated(unsafe) private static var _resizeCallCount: Int = 0
    nonisolated(unsafe) private static var _estimateSizeCallCount: Int = 0
    
    nonisolated(unsafe) private static var _lastCompressedImage: UIImage? = nil
    nonisolated(unsafe) private static var _lastQuality: CGFloat? = nil
    nonisolated(unsafe) private static var _lastMaxDimension: CGFloat? = nil
    
    // MARK: - Public Accessors
    
    static var mockCompressedData: Data? {
        get { _mockCompressedData }
        set { _mockCompressedData = newValue }
    }
    
    static var mockResizedImage: UIImage? {
        get { _mockResizedImage }
        set { _mockResizedImage = newValue }
    }
    
    static var mockEstimatedSize: Int {
        get { _mockEstimatedSize }
        set { _mockEstimatedSize = newValue }
    }
    
    static var shouldReturnNil: Bool {
        get { _shouldReturnNil }
        set { _shouldReturnNil = newValue }
    }
    
    static var compressCallCount: Int { _compressCallCount }
    static var resizeCallCount: Int { _resizeCallCount }
    static var estimateSizeCallCount: Int { _estimateSizeCallCount }
    
    static var lastCompressedImage: UIImage? { _lastCompressedImage }
    static var lastQuality: CGFloat? { _lastQuality }
    static var lastMaxDimension: CGFloat? { _lastMaxDimension }
    
    // MARK: - Compress
    
    static func compress(
        _ image: UIImage,
        quality: CGFloat,
        maxDimension: CGFloat
    ) -> Data? {
        _compressCallCount += 1
        _lastCompressedImage = image
        _lastQuality = quality
        _lastMaxDimension = maxDimension
        
        if _shouldReturnNil {
            return nil
        }
        
        return _mockCompressedData
    }
    
    // MARK: - Resize
    
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        _resizeCallCount += 1
        _lastMaxDimension = maxDimension
        
        return _mockResizedImage ?? image
    }
    
    // MARK: - Estimate Size
    
    static func estimateSize(_ image: UIImage, quality: CGFloat) -> Int {
        _estimateSizeCallCount += 1
        _lastQuality = quality
        
        return _mockEstimatedSize
    }
    
    // MARK: - Reset
    
    static func reset() {
        _mockCompressedData = Data([0xFF, 0xD8])
        _mockResizedImage = nil
        _mockEstimatedSize = 100
        _shouldReturnNil = false
        _compressCallCount = 0
        _resizeCallCount = 0
        _estimateSizeCallCount = 0
        _lastCompressedImage = nil
        _lastQuality = nil
        _lastMaxDimension = nil
    }
}
