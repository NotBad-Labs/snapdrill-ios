//
//  CaptureDraftService.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  采集草稿服务，负责暂时保存未确认的拍摄内容。
//

import UIKit
import SnapDrillCore

/// 负责管理拍照识题的草稿缓存
///
/// 当用户意外退出编辑界面时，用于恢复之前的图片和识别文字。
@MainActor
public class CaptureDraftService: CaptureDraftServiceProtocol {
    
    public static let shared = CaptureDraftService()
    
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard
    
    private let draftImageName = "draft_capture.jpg"
    private let draftMetadataKey = "capture_draft_metadata"
    
    private init() {}
    
    // MARK: - Models
    
    public struct Draft {
        public let image: UIImage
        public let content: String
        public let date: Date
    }
    
    private struct DraftMetadata: Codable {
        let content: String
        let timestamp: TimeInterval
    }
    
    // MARK: - Public API
    
    public var hasDraft: Bool {
        return defaults.object(forKey: draftMetadataKey) != nil
    }
    
    public func saveDraft(image: UIImage, content: String) {
        // 1. Save Image
        if let data = image.jpegData(compressionQuality: 0.8),
           let path = draftImagePath() {
            try? data.write(to: path)
        }
        
        // 2. Save Metadata
        let metadata = DraftMetadata(content: content, timestamp: Date().timeIntervalSince1970)
        if let data = try? JSONEncoder().encode(metadata) {
            defaults.set(data, forKey: draftMetadataKey)
        }
        
        SnapDrillLogger.generic.info("[DraftService] Draft saved.")
    }
    
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
    
    public func clearDraft() {
        defaults.removeObject(forKey: draftMetadataKey)
        if let path = draftImagePath() {
            try? fileManager.removeItem(at: path)
        }
        SnapDrillLogger.generic.info("[DraftService] Draft cleared.")
    }
    
    // MARK: - Helpers
    
    private func draftImagePath() -> URL? {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cacheDir.appendingPathComponent(draftImageName)
    }
}
