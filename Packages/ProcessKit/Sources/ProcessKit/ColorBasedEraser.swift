import Foundation
import CoreImage
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

/// 基于颜色范围的手写擦除（快速方案）
///
/// 适用场景：
/// - 蓝色圆珠笔答题
/// - 红笔批注
/// - 铅笔手写（灰色）
///
/// 不适用：黑色笔迹（与印刷体同色）
@available(iOS 17.0, macOS 14.0, *)
public struct ColorBasedEraser: Sendable {
    
    /// 墨水颜色类型
    public enum InkColor: Sendable {
        case blue      // 蓝色圆珠笔
        case red       // 红笔
        case pencil    // 铅笔灰
        case custom(HSVRange)  // 自定义颜色范围
    }
    
    /// HSV 颜色范围
    public struct HSVRange: Sendable {
        public let hue: ClosedRange<CGFloat>         // 0-360
        public let saturation: ClosedRange<CGFloat>  // 0-1
        public let value: ClosedRange<CGFloat>       // 0-1
        
        public init(
            hue: ClosedRange<CGFloat>,
            saturation: ClosedRange<CGFloat>,
            value: ClosedRange<CGFloat>
        ) {
            self.hue = hue
            self.saturation = saturation
            self.value = value
        }
    }
    
    // MARK: - 预定义颜色范围
    
    /// 蓝色笔迹范围（H: 200-240, S: 0.3-1.0, V: 0.2-0.9）
    public static let blueInkRange = HSVRange(
        hue: 200...240,
        saturation: 0.3...1.0,
        value: 0.2...0.9
    )
    
    /// 红色笔迹范围（H: 0-20 or 340-360, S: 0.5-1.0, V: 0.4-1.0）
    public static let redInkRange = HSVRange(
        hue: 0...20,
        saturation: 0.5...1.0,
        value: 0.4...1.0
    )
    
    /// 铅笔笔迹范围（低饱和度灰色）
    public static let pencilRange = HSVRange(
        hue: 0...360,
        saturation: 0...0.15,
        value: 0.3...0.7
    )
    
    // MARK: - Public API
    
    public init() {}
    
    /// 擦除指定颜色的笔迹
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - colors: 要擦除的颜色列表
    ///   - replacement: 替换颜色（默认白色）
    /// - Returns: 处理后的图片
    public func removeInk(
        from image: PlatformImage,
        colors: [InkColor],
        replacement: PlatformColor? = nil
    ) -> PlatformImage? {
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let ciImage = CIImage(cgImage: cgImage)
        #endif
        
        var result = ciImage
        
        #if canImport(UIKit)
        let replacementColor = replacement ?? .white
        #elseif canImport(AppKit)
        let replacementColor = replacement ?? .white
        #endif
        
        // 依次擦除每种颜色
        for color in colors {
            let range = colorRange(for: color)
            result = eraseColor(in: result, range: range, replacement: replacementColor)
        }
        
        // 转回平台图片
        let context = CIContext()
        guard let cgImage = context.createCGImage(result, from: result.extent) else {
            return nil
        }
        
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }
    
    // MARK: - Private Helpers
    
    private func colorRange(for color: InkColor) -> HSVRange {
        switch color {
        case .blue:
            return Self.blueInkRange
        case .red:
            return Self.redInkRange
        case .pencil:
            return Self.pencilRange
        case .custom(let range):
            return range
        }
    }
    
    /// 使用 Core Image 擦除指定 HSV 范围的颜色
    private func eraseColor(
        in image: CIImage,
        range: HSVRange,
        replacement: PlatformColor
    ) -> CIImage {
        // TODO: 实现基于 HSV 的颜色过滤
        // 1. RGB → HSV 转换
        // 2. 范围检测
        // 3. 替换为白色
        
        // 临时实现：返回原图
        return image
    }
}

// MARK: - Convenience Extensions

@available(iOS 17.0, macOS 14.0, *)
extension ColorBasedEraser {
    /// 快捷方法：擦除蓝色笔迹
    public func removeBlueInk(from image: PlatformImage) -> PlatformImage? {
        removeInk(from: image, colors: [.blue])
    }
    
    /// 快捷方法：擦除红色笔迹
    public func removeRedInk(from image: PlatformImage) -> PlatformImage? {
        removeInk(from: image, colors: [.red])
    }
    
    /// 快捷方法：擦除铅笔笔迹
    public func removePencil(from image: PlatformImage) -> PlatformImage? {
        removeInk(from: image, colors: [.pencil])
    }
}
