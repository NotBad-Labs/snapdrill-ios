//
//  ImageCompressorProtocol.swift
//  NotBad
//
//  图片压缩服务协议定义
//

import UIKit

// MARK: - Image Compressor Protocol

/// 图片压缩服务协议
///
/// 该协议定义了图片压缩和调整大小的标准接口，用于：
/// - 提供统一的图片处理 API
/// - 支持依赖注入和单元测试
/// - 提供可替换的图片处理策略
protocol ImageCompressorProtocol {
    /// 默认压缩质量
    static var defaultQuality: CGFloat { get }
    
    /// 默认最大尺寸
    static var defaultMaxDimension: CGFloat { get }
    
    /// 压缩图片
    ///
    /// - Parameters:
    ///   - image: 需要压缩的图片
    ///   - quality: 压缩质量 (0.0-1.0)
    ///   - maxDimension: 最大尺寸（宽或高的最大值）
    /// - Returns: 压缩后的图片数据，压缩失败返回 nil
    static func compress(
        _ image: UIImage,
        quality: CGFloat,
        maxDimension: CGFloat
    ) -> Data?
    
    /// 调整图片大小
    ///
    /// - Parameters:
    ///   - image: 需要调整大小的图片
    ///   - maxDimension: 最大尺寸
    /// - Returns: 调整大小后的图片
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage
    
    /// 估算压缩后的文件大小（KB）
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - quality: 压缩质量
    /// - Returns: 估算的文件大小（KB）
    static func estimateSize(_ image: UIImage, quality: CGFloat) -> Int
}

// MARK: - Default Parameter Values Extension

extension ImageCompressorProtocol {
    /// 使用默认参数的压缩方法
    static func compress(_ image: UIImage) -> Data? {
        compress(image, quality: defaultQuality, maxDimension: defaultMaxDimension)
    }
    
    /// 使用默认质量的压缩方法
    static func compress(_ image: UIImage, maxDimension: CGFloat) -> Data? {
        compress(image, quality: defaultQuality, maxDimension: maxDimension)
    }
    
    /// 使用默认尺寸的压缩方法
    static func compress(_ image: UIImage, quality: CGFloat) -> Data? {
        compress(image, quality: quality, maxDimension: defaultMaxDimension)
    }
    
    /// 使用默认参数的调整大小方法
    static func resize(_ image: UIImage) -> UIImage {
        resize(image, maxDimension: defaultMaxDimension)
    }
    
    /// 使用默认质量的大小估算方法
    static func estimateSize(_ image: UIImage) -> Int {
        estimateSize(image, quality: defaultQuality)
    }
}
