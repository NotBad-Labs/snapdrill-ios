//
//  CaptureDraftServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureDraftService 的 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import UIKit

/// 采集草稿服务 Mock 实现
///
/// 状态完全保存在内存中，不写磁盘 / UserDefaults。
public final class CaptureDraftServiceMock: CaptureDraftServiceProtocol {

    public var hasDraft: Bool {
        storedDraft != nil
    }

    /// Mock 内部维护的草稿；可在测试中通过 `setDraftToLoad` 注入预设
    public private(set) var storedDraft: CaptureDraftService.Draft?

    /// `saveDraft` 单次调用记录
    public struct SaveCall: Sendable {
        public let image: UIImage?
        public let content: String
        public let subject: String?
    }

    /// `saveDraft` 调用记录
    public private(set) var saveCalls: [SaveCall] = []

    /// `clearDraft` 调用次数
    public private(set) var clearCallCount = 0

    public init(initialDraft: CaptureDraftService.Draft? = nil) {
        self.storedDraft = initialDraft
    }

    public func saveDraft(image: UIImage?, content: String, subject: String?) async {
        saveCalls.append(SaveCall(image: image, content: content, subject: subject))
        storedDraft = CaptureDraftService.Draft(
            image: image,
            content: content,
            date: Date(),
            subject: subject
        )
    }

    public func loadDraft() -> CaptureDraftService.Draft? {
        storedDraft
    }

    public func clearDraft() {
        clearCallCount += 1
        storedDraft = nil
    }

    /// 测试辅助：直接注入要 load 的草稿
    public func setDraftToLoad(_ draft: CaptureDraftService.Draft?) {
        storedDraft = draft
    }
}
