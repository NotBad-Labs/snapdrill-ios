//
//  RestoreProfileHelper.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore

enum RestoreProfileHelper {
    static func createRestoreTargetProfile(
        id: UUID,
        name: String,
        fallbackProfiles: [Profile]
    ) throws -> Profile {
        let fileManager = FileManager.default
        var profiles = try loadPersistedProfiles()
        if profiles.isEmpty {
            profiles = fallbackProfiles
        }

        if let existing = profiles.first(where: { $0.id == id }) {
            return existing
        }

        let profile = Profile(id: id, name: name)
        let profileDir = profileDirectory(for: id)

        try fileManager.createDirectory(at: profileDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: profileDir.appendingPathComponent("images"), withIntermediateDirectories: true)
        try saveDefaultPreferences(for: profile, in: profileDir)

        profiles.append(profile)
        try savePersistedProfiles(profiles)
        return profile
    }

    private static func profileDirectory(for profileId: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("profiles").appendingPathComponent(profileId.uuidString)
    }

    private static func profilesFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("profiles.json")
    }

    private static func loadPersistedProfiles() throws -> [Profile] {
        let url = profilesFileURL()
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Profile].self, from: data)
        } catch {
            if (error as NSError).code == NSFileNoSuchFileError {
                return []
            }
            throw error
        }
    }

    private static func savePersistedProfiles(_ profiles: [Profile]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profiles)
        try data.write(to: profilesFileURL())
    }

    private static func saveDefaultPreferences(for profile: Profile, in profileDir: URL) throws {
        let defaults: [String: Any] = [
            UDKey.userName: profile.name,
            UDKey.userAvatar: profile.avatar,
            UDKey.userAvatarColorIndex: profile.avatarColorIndex,
            UDKey.captureFieldSubject: true,
            UDKey.captureFieldSource: false,
            UDKey.captureFieldDifficulty: false,
            UDKey.captureFieldGrade: false,
            UDKey.captureFieldAnswer: false,
            UDKey.dailyReviewGoal: 10
        ]
        let data = try JSONSerialization.data(withJSONObject: defaults, options: .prettyPrinted)
        try data.write(to: profileDir.appendingPathComponent("preferences.json"))
    }
}
