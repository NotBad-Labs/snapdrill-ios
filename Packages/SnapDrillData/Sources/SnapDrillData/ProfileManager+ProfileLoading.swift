//
//  ProfileManager+ProfileLoading.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore

extension ProfileManager {
    static func deduplicatedProfiles(_ profiles: [Profile]) -> [Profile] {
        var seenIds = Set<UUID>()
        var result: [Profile] = []
        for profile in profiles {
            guard seenIds.insert(profile.id).inserted else {
                SnapDrillLogger.data.warning("ProfileManager: 跳过重复 Profile ID: \(profile.id.uuidString)")
                continue
            }
            result.append(profile)
        }
        return result
    }
}
