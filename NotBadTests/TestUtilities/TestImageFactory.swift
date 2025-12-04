//
//  TestImageFactory.swift
//  NotBadTests
//
//  测试图片工厂 - 生成真实尺寸的测试图片
//
//  解决问题：测试中使用 Data([0x00]) 等假数据，无法发现真实性能问题
//

import UIKit

/// 测试图片工厂
///
/// 提供生成真实尺寸测试图片的方法，确保测试数据接近生产环境。
///
/// ## 使用示例
///
/// ```swift
/// // 生成小尺寸测试图片
/// let small = TestImageFactory.small
///
/// // 生成自定义尺寸图片
/// let custom = TestImageFactory.createImage(size: CGSize(width: 500, height: 500))
///
/// // 获取 JPEG 数据
/// let data = TestImageFactory.createJPEGData(size: .medium)
/// ```
public enum TestImageFactory {
    
    // MARK: - Standard Sizes
    
    /// 标准测试尺寸
    public enum Size {
        /// 缩略图尺寸 (140x140)
        case thumbnail
        /// 小图片 (300x300)
        case small
        /// 中等图片 (800x800)
        case medium
        /// 大图片 (1500x1500)
        case large
        /// 全尺寸 (2000x2000) - 模拟相机拍摄
        case fullSize
        /// 自定义尺寸
        case custom(CGSize)
        
        var cgSize: CGSize {
            switch self {
            case .thumbnail: return CGSize(width: 140, height: 140)
            case .small: return CGSize(width: 300, height: 300)
            case .medium: return CGSize(width: 800, height: 800)
            case .large: return CGSize(width: 1500, height: 1500)
            case .fullSize: return CGSize(width: 2000, height: 2000)
            case .custom(let size): return size
            }
        }
    }
    
    // MARK: - Quick Access
    
    /// 缩略图 (140x140)
    public static var thumbnail: UIImage {
        createImage(size: .thumbnail)
    }
    
    /// 小图片 (300x300)
    public static var small: UIImage {
        createImage(size: .small)
    }
    
    /// 中等图片 (800x800)
    public static var medium: UIImage {
        createImage(size: .medium)
    }
    
    /// 大图片 (1500x1500)
    public static var large: UIImage {
        createImage(size: .large)
    }
    
    /// 全尺寸图片 (2000x2000)
    public static var fullSize: UIImage {
        createImage(size: .fullSize)
    }
    
    // MARK: - Image Generation
    
    /// 创建指定尺寸的测试图片
    ///
    /// 生成带有随机内容的图片，模拟真实的题目照片。
    ///
    /// - Parameter size: 图片尺寸
    /// - Returns: 生成的 UIImage
    public static func createImage(size: Size) -> UIImage {
        createImage(cgSize: size.cgSize)
    }
    
    /// 创建指定 CGSize 的测试图片
    ///
    /// - Parameter cgSize: 图片尺寸
    /// - Returns: 生成的 UIImage
    public static func createImage(cgSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: cgSize)
        return renderer.image { context in
            // 绘制背景渐变
            let colors = [
                UIColor.systemBackground.cgColor,
                UIColor.secondarySystemBackground.cgColor
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: cgSize.width, y: cgSize.height),
                options: []
            )
            
            // 绘制模拟文字行（模拟题目内容）
            let lineHeight: CGFloat = cgSize.height / 15
            let margin: CGFloat = cgSize.width * 0.1
            
            for i in 0..<10 {
                let y = margin + CGFloat(i) * lineHeight * 1.5
                let width = cgSize.width * CGFloat.random(in: 0.5...0.8)
                let rect = CGRect(x: margin, y: y, width: width, height: lineHeight * 0.6)
                
                UIColor.label.withAlphaComponent(0.3).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 2).fill()
            }
            
            // 添加一些随机"公式"区域
            for _ in 0..<3 {
                let x = CGFloat.random(in: margin...(cgSize.width - margin - 100))
                let y = CGFloat.random(in: margin...(cgSize.height - margin - 50))
                let rect = CGRect(x: x, y: y, width: CGFloat.random(in: 80...150), height: CGFloat.random(in: 30...60))
                
                UIColor.systemBlue.withAlphaComponent(0.1).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
            }
        }
    }
    
    // MARK: - Data Generation
    
    /// 创建 JPEG 数据
    ///
    /// - Parameters:
    ///   - size: 图片尺寸
    ///   - quality: JPEG 压缩质量 (0.0 - 1.0)
    /// - Returns: JPEG 格式的 Data
    public static func createJPEGData(size: Size, quality: CGFloat = 0.8) -> Data {
        createImage(size: size).jpegData(compressionQuality: quality) ?? Data()
    }
    
    /// 创建 PNG 数据
    ///
    /// - Parameter size: 图片尺寸
    /// - Returns: PNG 格式的 Data
    public static func createPNGData(size: Size) -> Data {
        createImage(size: size).pngData() ?? Data()
    }
    
    /// 创建指定大小（KB）的 JPEG 数据
    ///
    /// 通过调整压缩质量来接近目标大小。
    ///
    /// - Parameters:
    ///   - targetKB: 目标大小（KB）
    ///   - tolerance: 允许的误差比例 (默认 0.2 = 20%)
    /// - Returns: 接近目标大小的 JPEG Data
    public static func createJPEGData(targetKB: Int, tolerance: Double = 0.2) -> Data {
        // 根据目标大小选择合适的图片尺寸
        let size: Size
        switch targetKB {
        case 0..<50: size = .small
        case 50..<200: size = .medium
        case 200..<500: size = .large
        default: size = .fullSize
        }
        
        let image = createImage(size: size)
        var quality: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: quality) ?? Data()
        
        // 迭代调整质量以接近目标大小
        let targetBytes = targetKB * 1024
        let minBytes = Int(Double(targetBytes) * (1 - tolerance))
        let maxBytes = Int(Double(targetBytes) * (1 + tolerance))
        
        for _ in 0..<5 {
            if data.count < minBytes {
                quality = min(1.0, quality + 0.1)
            } else if data.count > maxBytes {
                quality = max(0.1, quality - 0.1)
            } else {
                break
            }
            data = image.jpegData(compressionQuality: quality) ?? Data()
        }
        
        return data
    }
    
    // MARK: - Batch Generation
    
    /// 创建多张测试图片
    ///
    /// - Parameters:
    ///   - count: 图片数量
    ///   - size: 图片尺寸
    /// - Returns: UIImage 数组
    public static func createImages(count: Int, size: Size = .medium) -> [UIImage] {
        (0..<count).map { _ in createImage(size: size) }
    }
    
    /// 创建多份 JPEG 数据
    ///
    /// - Parameters:
    ///   - count: 数据数量
    ///   - size: 图片尺寸
    /// - Returns: Data 数组
    public static func createJPEGDatas(count: Int, size: Size = .medium) -> [Data] {
        (0..<count).map { _ in createJPEGData(size: size) }
    }
}

// MARK: - Convenience Extensions

public extension TestImageFactory {
    
    /// 打印图片信息（用于调试）
    static func printInfo(for image: UIImage, label: String = "Image") {
        let data = image.jpegData(compressionQuality: 0.8) ?? Data()
        print("[\(label)] Size: \(image.size), Data: \(data.count / 1024) KB")
    }
    
    /// 打印数据信息（用于调试）
    static func printInfo(for data: Data, label: String = "Data") {
        print("[\(label)] Size: \(data.count / 1024) KB (\(data.count) bytes)")
    }
}
