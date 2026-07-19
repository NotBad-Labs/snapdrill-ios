import CryptoKit
import Foundation
import Testing
import UIKit
@testable import SnapDrillCore

enum Corruption: String, CaseIterable, CustomTestStringConvertible {
    case truncated
    case unsupportedSchema
    case lengthMismatch
    case digestMismatch
    case invalidImage
    case emptyPayload

    var testDescription: String { rawValue }

    var expectedReason: CaptureDraftCorruptionReason {
        switch self {
        case .truncated:
            .malformedEnvelope
        case .unsupportedSchema:
            .unsupportedSchema
        case .lengthMismatch:
            .lengthMismatch
        case .digestMismatch:
            .digestMismatch
        case .invalidImage:
            .invalidImage
        case .emptyPayload:
            .emptyPayload
        }
    }

    func apply(to url: URL, original: Data) throws {
        switch self {
        case .truncated:
            try Data(original.prefix(max(1, original.count / 3))).write(to: url)
        case .unsupportedSchema:
            try rewrite(original, at: url) { envelope in
                envelope.schemaVersion = 999
            }
        case .lengthMismatch:
            try rewrite(original, at: url) { envelope in
                envelope.payload.contentByteCount = 999
            }
        case .digestMismatch:
            try rewrite(original, at: url, refreshDigest: false) { envelope in
                envelope.digest = String(repeating: "0", count: 64)
            }
        case .invalidImage:
            try rewrite(original, at: url) { envelope in
                envelope.payload.imageJPEG = Data([0x00, 0x01])
                envelope.payload.imageByteCount = 2
            }
        case .emptyPayload:
            try rewrite(original, at: url) { envelope in
                envelope.payload.content = ""
                envelope.payload.contentByteCount = 0
                envelope.payload.imageJPEG = nil
                envelope.payload.imageByteCount = 0
            }
        }
    }

    private func rewrite(
        _ original: Data,
        at url: URL,
        refreshDigest: Bool = true,
        mutation: (inout MutableEnvelope) -> Void
    ) throws {
        var envelope = try JSONDecoder().decode(MutableEnvelope.self, from: original)
        mutation(&envelope)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        if refreshDigest {
            let canonicalPayload = try encoder.encode(envelope.payload)
            envelope.digest = SHA256.hash(data: canonicalPayload)
                .map { String(format: "%02x", $0) }
                .joined()
        }
        try encoder.encode(envelope).write(to: url)
    }
}

private struct MutableEnvelope: Codable {
    var schemaVersion: Int
    var payload: MutablePayload
    var digest: String
}

private struct MutablePayload: Codable {
    var captureID: UUID
    var generationID: UUID
    var timestamp: TimeInterval
    var content: String
    var category: String?
    var imageJPEG: Data?
    var contentByteCount: Int
    var categoryByteCount: Int
    var imageByteCount: Int
}

func testImage(_ color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(
        size: CGSize(width: 12, height: 12),
        format: format
    ).image { context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
    }
}

func postRenameSyncFailingOncePublisher() -> DurableRegularFilePublisher {
    var calls = DurableRegularFileSystemCalls.live
    calls.fullSync = { _ in 0 }
    var shouldFailSync = true
    calls.sync = { descriptor in
        if shouldFailSync {
            shouldFailSync = false
            errno = EIO
            return -1
        }
        return Darwin.fsync(descriptor)
    }
    return DurableRegularFilePublisher(systemCalls: calls)
}

final class CaptureDraftTestFixture {
    let applicationSupportURL: URL
    let store: CaptureDraftStore
    let service: CaptureDraftService
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) throws {
        applicationSupportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CaptureDraftTests-\(UUID())", isDirectory: true)
        self.now = now
        let storage = try AppOwnedStorage(applicationSupportDirectory: applicationSupportURL)
        store = CaptureDraftStore(storage: storage)
        service = CaptureDraftService(store: store, now: now)
    }

    func makeService(
        publisher: DurableRegularFilePublisher = DurableRegularFilePublisher(),
        files: CaptureDraftFileOperations = .live
    ) throws -> CaptureDraftService {
        let storage = try AppOwnedStorage(applicationSupportDirectory: applicationSupportURL)
        return CaptureDraftService(
            store: CaptureDraftStore(
                storage: storage,
                publisher: publisher,
                files: files
            ),
            now: now
        )
    }

    func preparedCurrentURL() throws -> URL {
        let draftsURL = applicationSupportURL
            .appendingPathComponent(AppOwnedStorage.directoryName, isDirectory: true)
            .appendingPathComponent("Drafts", isDirectory: true)
        try FileManager.default.createDirectory(
            at: draftsURL,
            withIntermediateDirectories: true
        )
        return draftsURL.appendingPathComponent("current.v1")
    }

    func cleanup() {
        do {
            try FileManager.default.removeItem(at: applicationSupportURL)
        } catch {
            if (error as NSError).code != NSFileNoSuchFileError {
                Issue.record("Fixture cleanup failed: \(error)")
            }
        }
    }
}
