//
//  BackupServiceArchiveEntryValidationTests.swift
//  SnapDrillData
//
//  Validates archive namespace rules before restore mutates live image storage.
//

import Testing
import Foundation
import ZIPFoundation
@testable import SnapDrillData

@Suite("BackupService archive entry validation", .serialized)
struct BackupServiceArchiveEntryValidationTests {
    @Test("restoreImages rejects mixed entry types sharing one path before mutation")
    func restoreImages_rejectsMixedTypeDuplicateWithoutMutation() async throws {
        let service = BackupService()
        let profileId = UUID()
        let restoreDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreMixedEntryTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDirectory) }

        let originalImage = restoreDirectory.appendingPathComponent("images/keep.jpg")
        try writeString("original-image-data", to: originalImage)
        let duplicatePath = "profiles/\(profileId.uuidString)/images/keep.jpg"
        let archiveURL = try makeMixedTypeDuplicateArchive(path: duplicatePath)
        defer { cleanup(archiveURL) }

        await #expect(throws: BackupError.self) {
            try await service.restoreImages(
                from: archiveURL,
                profileId: profileId,
                to: restoreDirectory
            )
        }
        #expect(try stringContents(of: originalImage) == "original-image-data")
    }

    private func makeMixedTypeDuplicateArchive(path: String) throws -> URL {
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceMixedEntry_\(UUID().uuidString).zip")
        let archive = try Archive(url: archiveURL, accessMode: .create)
        let fileData = Data("replacement".utf8)
        try archive.addEntry(
            with: path,
            type: .file,
            uncompressedSize: Int64(fileData.count),
            provider: { position, size in
                fileData[Int(position) ..< Int(position) + size]
            }
        )
        try archive.addEntry(
            with: path,
            type: .directory,
            uncompressedSize: Int64(0),
            provider: { (_: Int64, _: Int) throws -> Data in Data() }
        )
        #expect(archive.filter { $0.path == path }.count == 2)
        return archiveURL
    }

    private func writeString(_ string: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(string.utf8).write(to: url)
    }

    private func stringContents(of url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return try #require(String(data: data, encoding: .utf8))
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
