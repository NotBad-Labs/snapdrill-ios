import Foundation
import SwiftData
import NotBadCore

/// 数据持久化层
@MainActor
public final class DataHandler {
    public static let shared = DataHandler()
    
    // TODO: 配置 SwiftData ModelContainer
    
    private init() {}
}
