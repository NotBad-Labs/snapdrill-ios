//
//  CaptureDraftService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集草稿服务，负责暂时保存未确认的拍摄内容。跨域共用（Dashboard 检测、Capture 消费）。
//

#if canImport(UIKit)
import UIKit

/// 负责管理拍照识题的草稿缓存
///
/// 当用户意外退出编辑界面时，用于恢复之前的图片和识别文字。
@MainActor
public final class CaptureDraftService: CaptureDraftServiceProtocol {

    public static let shared = CaptureDraftService()

    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard

    private let draftImageName = "draft_capture.jpg"
    private let draftMetadataKey = "capture_draft_metadata"

    private init() {}

    // MARK: - Models

    /// 草稿数据结构，携带图片、识别文本和保存时间
    public struct Draft {
        /// 拍摄的原始图片
        public let image: UIImage
        /// OCR 识别文本（可为空字符串）
        public let content: String
        /// 草稿保存时间
        public let date: Date
    }

    private struct DraftMetadata: Codable {
        let content: String
        let timestamp: TimeInterval
    }

    // MARK: - Public API

    /// 当前是否存在未保存的草稿（遵循 `CaptureDraftServiceProtocol`）
    public var hasDraft: Bool {
        return defaults.object(forKey: draftMetadataKey) != nil
    }

    /// 将图片和识别文本保存为草稿（遵循 `CaptureDraftServiceProtocol`）
    public func saveDraft(image: UIImage, content: String) {
        // 1. Save Image
        if let data = image.jpegData(compressionQuality: 0.8),
           let path = draftImagePath() {
            do {
                try data.write(to: path)
            } catch {
                SnapDrillLogger.generic.warning("[DraftService] 草稿图片写入失败: \(error.localizedDescription)")
            }
        }

        // 2. Save Metadata
        let metadata = DraftMetadata(content: content, timestamp: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(metadata) {
            defaults.set(data, forKey: draftMetadataKey)
        }

        SnapDrillLogger.generic.info("[DraftService] Draft saved.")
    }

    /// 读取已保存的草稿；不存在或数据损坏时返回 `nil`（遵循 `CaptureDraftServiceProtocol`）
    public func loadDraft() -> Draft? {
        // 1. Load Metadata
        guard let data = defaults.data(forKey: draftMetadataKey),
              let metadata = try? JSONDecoder().decode(DraftMetadata.self, from: data) else {
            return nil
        }

        // 2. Load Image
        guard let path = draftImagePath(),
              let imageData = try? Data(contentsOf: path),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return Draft(image: image, content: metadata.content, date: Date(timeIntervalSince1970: metadata.timestamp))
    }

    /// 清除已保存的草稿（遵循 `CaptureDraftServiceProtocol`）
    public func clearDraft() {
        defaults.removeObject(forKey: draftMetadataKey)
        if let path = draftImagePath() {
            try? fileManager.removeItem(at: path)
        }
        SnapDrillLogger.generic.info("[DraftService] Draft cleared.")
    }

    // MARK: - Private Helpers

    private func draftImagePath() -> URL? {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cacheDir.appendingPathComponent(draftImageName)
    }
}
#endif
