//
//  CaptureDraftServiceProtocol.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义采集草稿服务协议，支持图片裁剪与临时状态管理。
//

import UIKit

@MainActor
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage, content: String)
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}
