//
//  CaptureDraftService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import CryptoKit
import Foundation
import UIKit

/// Persists the single Profile-free capture draft as one integrity-checked generation.
public final class CaptureDraftService: CaptureDraftServiceProtocol {
    private nonisolated static let schemaVersion = 1

    private nonisolated struct Envelope: Codable, Sendable {
        let schemaVersion: Int
        let payloadByteCount: Int
        let payload: Data
        let payloadSHA256: Data
    }

    private nonisolated struct Payload: Codable, Sendable {
        let captureID: UUID
        let generationID: UUID
        let timestampMilliseconds: Int64
        let content: String
        let contentUTF8ByteCount: Int
        let category: String?
        let imageJPEG: Data?
        let imageByteCount: Int
    }

    private let fileStore: CaptureDraftFileStore
    private let now: () -> Date

    /// Production composition entry point.
    public convenience init(fileManager: FileManager = .default) {
        let rootURL: URL?
        do {
            rootURL = try AppOwnedStorage(fileManager: fileManager).rootURL
        } catch {
            rootURL = nil
            SnapDrillLogger.capture.error(
                "[DraftService] Application Support unavailable: \(error.localizedDescription)"
            )
        }
        self.init(
            fileStore: CaptureDraftFileStore(trustRootURL: rootURL),
            now: Date.init
        )
    }

    init(
        fileStore: CaptureDraftFileStore,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileStore = fileStore
        self.now = now
    }

    public func loadDraftState() async -> CaptureDraftReadState {
        switch await fileStore.load() {
        case .missing:
            return .none
        case .unreadable(let observation):
            SnapDrillLogger.capture.error("[DraftService] Draft storage is unreadable")
            return .unrecoverable(
                failure(reason: .storageUnavailable, observation: observation)
            )
        case .bytes(let bytes, let revision):
            return decodeDraft(bytes, revision: revision)
        }
    }

    public func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        let generation = try encodeGeneration(
            image: image,
            content: content,
            category: category,
            expectedToken: expectedToken
        )
        let revision = try await fileStore.replace(
            generation.bytes,
            expectedRevision: expectedToken?.storageRevision
        )
        return generation.token(storageRevision: revision)
    }

    public func saveDraftAndBeginSettlement(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        let generation = try encodeGeneration(
            image: image,
            content: content,
            category: category,
            expectedToken: expectedToken
        )
        let revision = try await fileStore.replaceAndBeginSettlement(
            generation.bytes,
            expectedRevision: expectedToken?.storageRevision
        )
        return generation.token(storageRevision: revision)
    }

    private struct EncodedGeneration {
        let bytes: Data
        let captureID: UUID
        let generationID: UUID

        func token(storageRevision: String) -> CaptureDraftToken {
            CaptureDraftToken(
                captureID: captureID,
                generationID: generationID,
                storageRevision: storageRevision
            )
        }
    }

    private func encodeGeneration(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) throws -> EncodedGeneration {
        let imageData = try encodeImage(image)

        guard imageData != nil
                || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaptureDraftError.emptyDraft
        }

        let captureID = expectedToken?.captureID ?? UUID()
        let generationID = UUID()
        let timestamp = Int64((now().timeIntervalSince1970 * 1_000).rounded())
        let payload = Payload(
            captureID: captureID,
            generationID: generationID,
            timestampMilliseconds: timestamp,
            content: content,
            contentUTF8ByteCount: content.utf8.count,
            category: category,
            imageJPEG: imageData,
            imageByteCount: imageData?.count ?? 0
        )

        let payloadBytes: Data
        let envelopeBytes: Data
        do {
            payloadBytes = try Self.encoder().encode(payload)
            envelopeBytes = try Self.encoder().encode(
                Envelope(
                    schemaVersion: Self.schemaVersion,
                    payloadByteCount: payloadBytes.count,
                    payload: payloadBytes,
                    payloadSHA256: Self.digest(payloadBytes)
                )
            )
        } catch {
            SnapDrillLogger.capture.error(
                "[DraftService] Draft encoding failed: \(error.localizedDescription)"
            )
            throw CaptureDraftError.storageFailure
        }

        guard case .recoverable(let roundTrip) = decodeDraft(
            envelopeBytes,
            revision: "preflight"
        ),
        roundTrip.token.captureID == captureID,
        roundTrip.token.generationID == generationID else {
            SnapDrillLogger.capture.error("[DraftService] Encoded draft failed read-back validation")
            throw CaptureDraftError.storageFailure
        }

        return EncodedGeneration(
            bytes: envelopeBytes,
            captureID: captureID,
            generationID: generationID
        )
    }

    private func encodeImage(_ image: UIImage?) throws -> Data? {
        guard let image else { return nil }
        guard let encoded = ImageStorage.compressedJPEGData(
            from: image,
            maxLongSide: 2_000,
            quality: 0.8
        ) else {
            throw CaptureDraftError.imageEncodingFailed
        }
        return encoded
    }

    public func discardDraft(expectedToken: CaptureDraftToken) async throws {
        try await fileStore.discard(expectedObservation: expectedToken.storageRevision)
    }

    public func discardUnrecoverableDraft(
        expectedToken: CaptureDraftDiscardToken
    ) async throws {
        try await fileStore.discard(expectedObservation: expectedToken.storageObservation)
    }

    public func beginSettlement(expectedToken: CaptureDraftToken) async throws {
        try await fileStore.beginSettlement(expectedRevision: expectedToken.storageRevision)
    }

    public func completeSettlement(expectedToken: CaptureDraftToken) async throws {
        try await fileStore.completeSettlement(expectedRevision: expectedToken.storageRevision)
    }

    public func abortSettlement(expectedToken: CaptureDraftToken) async {
        await fileStore.abortSettlement(expectedRevision: expectedToken.storageRevision)
    }

    private func decodeDraft(_ bytes: Data, revision: String) -> CaptureDraftReadState {
        let envelope: Envelope
        do {
            envelope = try Self.decoder().decode(Envelope.self, from: bytes)
        } catch {
            return decodeFailure(.malformedEnvelope, revision: revision)
        }
        guard envelope.schemaVersion == Self.schemaVersion else {
            return decodeFailure(.unsupportedVersion, revision: revision)
        }
        guard envelope.payloadByteCount == envelope.payload.count else {
            return decodeFailure(.integrityCheckFailed, revision: revision)
        }
        guard envelope.payloadSHA256 == Self.digest(envelope.payload) else {
            return decodeFailure(.integrityCheckFailed, revision: revision)
        }

        let payload: Payload
        do {
            payload = try Self.decoder().decode(Payload.self, from: envelope.payload)
        } catch {
            return decodeFailure(.malformedEnvelope, revision: revision)
        }
        guard payload.contentUTF8ByteCount == payload.content.utf8.count,
              payload.imageByteCount == (payload.imageJPEG?.count ?? 0) else {
            return decodeFailure(.integrityCheckFailed, revision: revision)
        }
        guard payload.imageJPEG != nil
                || !payload.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return decodeFailure(.emptyDraft, revision: revision)
        }

        let image: UIImage?
        if let imageData = payload.imageJPEG {
            guard let decoded = UIImage(data: imageData) else {
                return decodeFailure(.imageDecodeFailed, revision: revision)
            }
            image = decoded
        } else {
            image = nil
        }

        let token = CaptureDraftToken(
            captureID: payload.captureID,
            generationID: payload.generationID,
            storageRevision: revision
        )
        return .recoverable(
            CaptureDraft(
                image: image,
                content: payload.content,
                date: Date(
                    timeIntervalSince1970: TimeInterval(payload.timestampMilliseconds) / 1_000
                ),
                category: payload.category,
                token: token
            )
        )
    }

    private func decodeFailure(
        _ reason: CaptureDraftFailureReason,
        revision: String
    ) -> CaptureDraftReadState {
        SnapDrillLogger.capture.error("[DraftService] Draft decode failed: \(String(describing: reason))")
        return .unrecoverable(failure(reason: reason, observation: revision))
    }

    private func failure(
        reason: CaptureDraftFailureReason,
        observation: String?
    ) -> CaptureDraftFailure {
        CaptureDraftFailure(
            reason: reason,
            discardToken: observation.map(CaptureDraftDiscardToken.init)
        )
    }

    private nonisolated static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private nonisolated static func decoder() -> JSONDecoder {
        JSONDecoder()
    }

    private nonisolated static func digest(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
