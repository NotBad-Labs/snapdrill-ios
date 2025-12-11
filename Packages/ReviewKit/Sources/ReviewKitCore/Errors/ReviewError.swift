import Foundation

/// 通用领域错误
public enum ReviewError: Error, LocalizedError, Sendable {
    case invalidPerformance(value: Int)
    case itemNotFound(id: UUID)
    case storageUnavailable
    case unknown
    
    /// 人类可读的错误描述
    public var errorDescription: String? {
        switch self {
        case .invalidPerformance(let value):
            return "无效的掌握等级: \(value)。合法范围 0-4。"
        case .itemNotFound(let id):
            return "未找到复习项: \(id.uuidString)"
        case .storageUnavailable:
            return "存储不可用"
        case .unknown:
            return "未知错误"
        }
    }
}