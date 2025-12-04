//
//  ExportCacheManager.swift
//  NotBad
//
//  导出文件缓存管理器
//
//  解决问题：用户筛选导出后，取消分享想换个应用分享时，文件丢失需要重新生成
//
//  解决方案：
//  1. 将导出文件保存到持久化目录而非临时目录
//  2. 缓存最近导出的文件（最多保留 5 个）
//  3. 提供"最近导出"列表，用户可以再次分享
//  4. 定期清理过期文件（超过 7 天）
//

import Foundation

// MARK: - Export Cache Manager

/// 导出文件缓存管理器
///
/// 使用 Swift actor 确保线程安全，替代 `@unchecked Sendable`。
/// 所有文件操作都在 actor 隔离域内执行，避免并发竞争。
actor ExportCacheManager {
    
    // MARK: - Singleton
    
    static let shared = ExportCacheManager()
    
    private init() {
        // 启动时清理过期文件（在 actor 内安全执行）
        Task { await cleanupExpiredFiles() }
    }
    
    // MARK: - Constants
    
    /// 最大缓存文件数
    private let maxCachedFiles = 5
    
    /// 文件过期天数
    private let expirationDays = 7
    
    /// 缓存目录名
    private let cacheDirectoryName = "ExportCache"
    
    // MARK: - Properties
    
    /// 缓存目录 URL
    private var cacheDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cachePath = documentsPath.appendingPathComponent(cacheDirectoryName)
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: cachePath.path) {
            try? FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
        }
        
        return cachePath
    }
    
    // MARK: - Public Methods
    
    /// 保存导出文件到缓存
    /// - Parameters:
    ///   - data: 文件数据
    ///   - fileName: 文件名
    /// - Returns: 缓存文件的 URL
    func cacheExportFile(data: Data, fileName: String) throws -> URL {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // 如果同名文件已存在，先删除
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        // 写入文件
        try data.write(to: fileURL)
        
        // 清理多余的缓存文件
        cleanupExcessFiles()
        
        return fileURL
    }
    
    /// 获取所有缓存的导出文件
    /// - Returns: 缓存文件信息列表，按修改时间倒序排列
    func getCachedFiles() -> [CachedExportFile] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        return files.compactMap { url -> CachedExportFile? in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let modificationDate = attributes[.modificationDate] as? Date,
                  let fileSize = attributes[.size] as? Int64 else {
                return nil
            }
            
            return CachedExportFile(
                url: url,
                fileName: url.lastPathComponent,
                fileType: url.pathExtension.uppercased(),
                createdAt: modificationDate,
                fileSize: fileSize
            )
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 删除指定的缓存文件
    func deleteFile(_ file: CachedExportFile) {
        try? FileManager.default.removeItem(at: file.url)
    }
    
    /// 删除所有缓存文件
    func deleteAllFiles() {
        let files = getCachedFiles()
        for file in files {
            try? FileManager.default.removeItem(at: file.url)
        }
    }
    
    /// 获取缓存目录总大小
    func getCacheSize() -> Int64 {
        getCachedFiles().reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - Private Methods
    
    /// 清理过期文件
    private func cleanupExpiredFiles() {
        let files = getCachedFiles()
        let expirationDate = Calendar.current.date(byAdding: .day, value: -expirationDays, to: Date())!
        
        for file in files where file.createdAt < expirationDate {
            try? FileManager.default.removeItem(at: file.url)
        }
    }
    
    /// 清理多余的缓存文件（保留最新的 maxCachedFiles 个）
    private func cleanupExcessFiles() {
        let files = getCachedFiles()
        
        if files.count > maxCachedFiles {
            let filesToDelete = files.suffix(from: maxCachedFiles)
            for file in filesToDelete {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
    }
}

// MARK: - Cached Export File

/// 缓存的导出文件信息
struct CachedExportFile: Identifiable {
    let url: URL
    let fileName: String
    let fileType: String
    let createdAt: Date
    let fileSize: Int64
    
    var id: URL { url }
    
    /// 格式化的文件大小
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// 格式化的创建时间
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// 文件类型图标
    var icon: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.richtext.fill"
        case "csv":
            return "tablecells.fill"
        case "json":
            return "curlybraces"
        case "zip":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
    
    /// 文件类型颜色
    var color: String {
        switch fileType.lowercased() {
        case "pdf":
            return "primary"
        case "csv":
            return "success"
        case "json":
            return "secondary"
        case "zip":
            return "warning"
        default:
            return "secondary"
        }
    }
}
