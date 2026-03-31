//
//  CaptureDraftService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集草稿服务，负责暂时保存未确认的拍摄内容。跨域共用（Dashboard 检测、Capture 消费）。
//

import UIKit

/// 负责管理拍照识题的草稿缓存
///
/// 当用户意外退出编辑界面时，用于恢复之前的图片和识别文字。
public final class CaptureDraftService: CaptureDraftServiceProtocol {

    public static let shared = CaptureDraftService()

    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard

    private let draftImageName = "draft_capture.jpg"
    private let draftMetadataKey = UDKey.captureDraftMetadata

    private init() {}

    // MARK: - Models

    /// 草稿数据结构，携带图片、识别文本、学科和保存时间
    public struct Draft {
        /// 拍摄的原始图片
        public let image: UIImage
        /// OCR 识别文本（可为空字符串）
        public let content: String
        /// 草稿保存时间
        public let date: Date
        /// 保存时选中的学科（用于恢复提示展示）
        public let subject: String?
    }

    private struct DraftMetadata: Codable {
        let content: String
        let timestamp: TimeInterval
        /// 保存时选中的学科（旧草稿缺失时 decode 为 nil）
        let subject: String?
    }

    // MARK: - Public API

    /// 当前是否存在未保存的草稿（遵循 `CaptureDraftServiceProtocol`）
    public var hasDraft: Bool {
        return defaults.object(forKey: draftMetadataKey) != nil
    }

    /// 将图片和识别文本保存为草稿（遵循 `CaptureDraftServiceProtocol`）
    ///
    /// async 签名使调用方可在 Task 中执行（如 onDisappear），不直接阻塞 UI 事件循环。
    /// UIImage 非 Sendable，JPEG 压缩和文件写入无法安全移至后台，仍在 MainActor 执行。
    /// 草稿图片已压缩（JPEG 0.8），I/O 量小（通常 < 500KB），阻塞时间可接受。
    public func saveDraft(image: UIImage, content: String, subject: String? = nil) async {
        // 1. JPEG 压缩 + 写入文件（通过 ImageStorage 剥离 EXIF GPS，保护用户位置隐私）
        if let data = ImageStorage.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8),
           let path = draftImagePath() {
            do {
                try data.write(to: path)
            } catch {
                SnapDrillLogger.generic.warning("[DraftService] 草稿图片写入失败: \(error.localizedDescription)")
            }
        }

        // 2. 元数据写入 UserDefaults
        let metadata = DraftMetadata(content: content, timestamp: Date().timeIntervalSince1970, subject: subject)
        // best-effort: 元数据编码失败不影响图片已写入
        if let data = try? JSONEncoder().encode(metadata) {
            defaults.set(data, forKey: draftMetadataKey)
        }

        SnapDrillLogger.generic.info("[DraftService] Draft saved.")
    }

    /// 读取已保存的草稿；不存在、数据损坏或超过 7 天时返回 `nil`
    public func loadDraft() -> Draft? {
        // 1. Load Metadata
        guard let data = defaults.data(forKey: draftMetadataKey),
              let metadata = try? JSONDecoder().decode(DraftMetadata.self, from: data) else {
            return nil
        }

        // 2. 7 天过期检查——过期草稿静默清理，不打扰用户
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        if Date().timeIntervalSince1970 - metadata.timestamp > sevenDays {
            clearDraft()
            SnapDrillLogger.generic.info("[DraftService] 草稿已超过 7 天，自动清理")
            return nil
        }

        // 3. Load Image
        guard let path = draftImagePath(),
              let imageData = try? Data(contentsOf: path),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return Draft(
            image: image,
            content: metadata.content,
            date: Date(timeIntervalSince1970: metadata.timestamp),
            subject: metadata.subject
        )
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
