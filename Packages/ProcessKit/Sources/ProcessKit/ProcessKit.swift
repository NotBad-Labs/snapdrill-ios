import Foundation

/// ProcessKit 公开 API 入口
///
/// 图像处理引擎，提供手写擦除、图像增强等功能。
@available(iOS 17.0, macOS 14.0, *)
public struct ProcessKit {
    /// ProcessKit 版本
    public static let version = "0.1.0"
    
    /// 库名称
    public static let name = "ProcessKit"
    
    private init() {}
}

/// 处理结果
public struct ProcessResult: Sendable {
    /// 处理后的图片
    public let image: Data
    
    /// 处理耗时（秒）
    public let duration: TimeInterval
    
    /// 分割 mask（调试用，可选）
    public let segmentationMask: Data?
    
    public init(
        image: Data,
        duration: TimeInterval,
        segmentationMask: Data? = nil
    ) {
        self.image = image
        self.duration = duration
        self.segmentationMask = segmentationMask
    }
}
