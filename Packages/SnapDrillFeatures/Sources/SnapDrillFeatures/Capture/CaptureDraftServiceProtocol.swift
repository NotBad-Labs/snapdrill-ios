//
//  CaptureDraftServiceProtocol.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//

import UIKit

@MainActor
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage, content: String)
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}
