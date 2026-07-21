//
//  ContinuousCropperPresentationPolicy.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

enum ContinuousCropperPresentationPolicy {
    static func shouldPresent<Image>(originalAlbumImage: Image?) -> Bool {
        originalAlbumImage != nil
    }
}
