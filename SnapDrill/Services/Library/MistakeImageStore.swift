import Foundation
import UIKit

/// 错题图片落盘；`MistakeItem` 存相对路径（PRD §8.6）。
enum MistakeImageStore {
    private static let folderName = "MistakeImages"

    static func rootDirectory() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

  /// 返回相对 `Application Support` 的路径片段，便于迁移容器。
    static func writeJPEG(_ data: Data, fileName: String) throws -> String {
        let dir = try rootDirectory()
        let url = dir.appendingPathComponent(fileName, isDirectory: false)
        try data.write(to: url, options: [.atomic])
        return "\(folderName)/\(fileName)"
    }

    static func fileURL(relativePath: String) throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return support.appendingPathComponent(relativePath, isDirectory: false)
    }

    static func loadImage(relativePath: String) -> UIImage? {
        guard let url = try? fileURL(relativePath: relativePath),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }
}