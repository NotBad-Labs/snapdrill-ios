//
//  CaptureDraftEnvelope.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import CryptoKit
import Foundation
import UIKit

nonisolated struct StoredCaptureDraft {
    let token: CaptureDraftToken
    let timestamp: Date
    let content: String
    let category: String?
    let imageJPEG: Data?
}

nonisolated enum CaptureDraftEnvelopeValidationError: Error, Equatable {
    case malformedEnvelope
    case unsupportedSchema
    case lengthMismatch
    case digestMismatch
    case invalidImage
    case emptyPayload

    var corruptionReason: CaptureDraftCorruptionReason {
        switch self {
        case .malformedEnvelope:
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
}

nonisolated struct CaptureDraftEnvelopeCodec {
    private static let schemaVersion = 1

    private struct Envelope: Codable {
        let schemaVersion: Int
        let payload: Payload
        let digest: String
    }

    private struct Payload: Codable {
        let captureID: UUID
        let generationID: UUID
        let timestamp: TimeInterval
        let content: String
        let category: String?
        let imageJPEG: Data?
        let contentByteCount: Int
        let categoryByteCount: Int
        let imageByteCount: Int
    }

    func encode(_ draft: StoredCaptureDraft) throws -> Data {
        let payload = Payload(
            captureID: draft.token.captureID,
            generationID: draft.token.generationID,
            timestamp: draft.timestamp.timeIntervalSince1970,
            content: draft.content,
            category: draft.category,
            imageJPEG: draft.imageJPEG,
            contentByteCount: draft.content.utf8.count,
            categoryByteCount: draft.category?.utf8.count ?? 0,
            imageByteCount: draft.imageJPEG?.count ?? 0
        )
        let envelope = Envelope(
            schemaVersion: Self.schemaVersion,
            payload: payload,
            digest: Self.digest(try Self.canonicalData(for: payload))
        )
        let bytes = try Self.encoder().encode(envelope)
        _ = try decode(bytes)
        return bytes
    }

    func decode(_ bytes: Data) throws -> StoredCaptureDraft {
        let envelope: Envelope
        do {
            envelope = try Self.decoder().decode(Envelope.self, from: bytes)
        } catch {
            throw CaptureDraftEnvelopeValidationError.malformedEnvelope
        }

        guard envelope.schemaVersion == Self.schemaVersion else {
            throw CaptureDraftEnvelopeValidationError.unsupportedSchema
        }
        let payload = envelope.payload
        guard payload.timestamp.isFinite,
              payload.contentByteCount == payload.content.utf8.count,
              payload.categoryByteCount == payload.category?.utf8.count ?? 0,
              payload.imageByteCount == payload.imageJPEG?.count ?? 0 else {
            throw CaptureDraftEnvelopeValidationError.lengthMismatch
        }
        let canonicalPayload: Data
        do {
            canonicalPayload = try Self.canonicalData(for: payload)
        } catch {
            throw CaptureDraftEnvelopeValidationError.malformedEnvelope
        }
        guard envelope.digest == Self.digest(canonicalPayload) else {
            throw CaptureDraftEnvelopeValidationError.digestMismatch
        }

        let hasText = !payload.content.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        if let imageJPEG = payload.imageJPEG, UIImage(data: imageJPEG) == nil {
            throw CaptureDraftEnvelopeValidationError.invalidImage
        }
        guard hasText || payload.imageJPEG != nil else {
            throw CaptureDraftEnvelopeValidationError.emptyPayload
        }

        return StoredCaptureDraft(
            token: CaptureDraftToken(
                captureID: payload.captureID,
                generationID: payload.generationID
            ),
            timestamp: Date(timeIntervalSince1970: payload.timestamp),
            content: payload.content,
            category: payload.category,
            imageJPEG: payload.imageJPEG
        )
    }

    func fingerprint(_ bytes: Data) -> String {
        Self.digest(bytes)
    }

    private static func canonicalData(for payload: Payload) throws -> Data {
        try encoder().encode(payload)
    }

    private static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        JSONDecoder()
    }
}

nonisolated struct CaptureDraftSettlementMarkerCodec {
    private static let schemaVersion = 1

    private struct Envelope: Codable {
        let schemaVersion: Int
        let payload: Payload
        let digest: String
    }

    private struct Payload: Codable {
        let captureID: UUID
        let generationID: UUID
    }

    func encode(_ token: CaptureDraftToken) throws -> Data {
        let payload = Payload(
            captureID: token.captureID,
            generationID: token.generationID
        )
        let envelope = Envelope(
            schemaVersion: Self.schemaVersion,
            payload: payload,
            digest: Self.digest(try Self.canonicalData(for: payload))
        )
        return try Self.encoder().encode(envelope)
    }

    func decode(_ bytes: Data) throws -> CaptureDraftToken {
        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: bytes)
        } catch {
            throw CaptureDraftEnvelopeValidationError.malformedEnvelope
        }
        guard envelope.schemaVersion == Self.schemaVersion else {
            throw CaptureDraftEnvelopeValidationError.unsupportedSchema
        }
        let canonicalPayload: Data
        do {
            canonicalPayload = try Self.canonicalData(for: envelope.payload)
        } catch {
            throw CaptureDraftEnvelopeValidationError.malformedEnvelope
        }
        guard envelope.digest == Self.digest(canonicalPayload) else {
            throw CaptureDraftEnvelopeValidationError.digestMismatch
        }
        return CaptureDraftToken(
            captureID: envelope.payload.captureID,
            generationID: envelope.payload.generationID
        )
    }

    private static func canonicalData(for payload: Payload) throws -> Data {
        try encoder().encode(payload)
    }

    private static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

enum CaptureDraftPayload {
    static func makeDraft(from stored: StoredCaptureDraft) -> CaptureDraft {
        CaptureDraft(
            image: stored.imageJPEG.flatMap(UIImage.init(data:)),
            content: stored.content,
            date: stored.timestamp,
            category: stored.category,
            token: stored.token
        )
    }

    static func makeImageJPEG(_ image: UIImage?) throws -> Data? {
        guard let image else {
            return nil
        }
        guard let compressed = ImageStorage.compressedJPEGData(
            from: image,
            maxLongSide: 2_000,
            quality: 0.8
        ) else {
            throw CaptureDraftServiceError.imageEncodingFailed
        }
        return compressed
    }
}

struct PendingPublication {
    let draft: StoredCaptureDraft
    let expected: CaptureDraftToken?

    func matches(
        requestedCaptureID: UUID?,
        expected: CaptureDraftToken?,
        content: String,
        category: String?,
        imageJPEG: Data?
    ) -> Bool {
        (requestedCaptureID == nil || draft.token.captureID == requestedCaptureID)
            && self.expected == expected
            && draft.content == content
            && draft.category == category
            && draft.imageJPEG == imageJPEG
    }
}
