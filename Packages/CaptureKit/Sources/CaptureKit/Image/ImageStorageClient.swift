import Foundation
import CoreGraphics

/// 异步图片存储接口，供 CaptureKit 及宿主应用实现或注入。
public protocol ImageStorageClient: Sendable {
    /// 保存图片
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - id: 关联的业务 ID
    ///   - compressionQuality: JPEG 压缩质量
    /// - Returns: 保存后的文件名
    func saveImage(_ image: PlatformImage, id: UUID, compressionQuality: CGFloat) async throws -> String

    /// 保存图片二进制数据
    /// - Parameters:
    ///   - data: 图片数据
    ///   - id: 关联的业务 ID
    /// - Returns: 保存后的文件名
    func saveData(_ data: Data, id: UUID) async throws -> String

    /// 读取图片
    /// - Parameter fileName: 文件名
    /// - Returns: 图片对象，若不存在返回 nil
    func loadImage(named fileName: String?) async -> PlatformImage?

    /// 读取图片数据
    /// - Parameter fileName: 文件名
    /// - Returns: 数据，若不存在返回 nil
    func loadData(named fileName: String?) async -> Data?

    /// 删除单个图片
    /// - Parameter fileName: 文件名
    func deleteImage(named fileName: String?) async

    /// 批量删除图片
    /// - Parameter fileNames: 文件名列表
    func deleteImages(named fileNames: [String?]) async

    /// 判断图片是否存在
    /// - Parameter fileName: 文件名
    /// - Returns: 是否存在
    func exists(named fileName: String?) async -> Bool

    /// 获取文件 URL
    /// - Parameter fileName: 文件名
    /// - Returns: 完整 URL，若不存在返回 nil
    func fileURL(for fileName: String?) async -> URL?

    /// 清空所有图片
    func clearAll() async

    /// 已格式化的存储大小描述
    var formattedSize: String { get async }

    /// 图片数量
    var imageCount: Int { get async }
}

/// 图片存储客户端的通用错误
public enum ImageStorageClientError: Error, LocalizedError {
    /// 目录不可用
    case directoryUnavailable
    /// 文件名无效
    case invalidFileName
    /// 图片压缩失败
    case compressionFailed
    /// 写入磁盘失败
    case saveFailed(Error)
    /// 无法从数据解码图片
    case imageDecodeFailed

    /// 用户可读的错误描述
    public var errorDescription: String? {
        switch self {
        case .directoryUnavailable:
            return "图片存储目录不可用"
        case .invalidFileName:
            return "文件名无效"
        case .compressionFailed:
            return "图片压缩失败"
        case .saveFailed(let error):
            return "图片写入失败：\(error.localizedDescription)"
        case .imageDecodeFailed:
            return "无法从数据解码图片"
        }
    }
}
