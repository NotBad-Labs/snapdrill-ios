//
//  CaptureDraftStore.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
final class CaptureDraftStore {
    private let storage: AppOwnedStorage
    private let publisher: DurableRegularFilePublisher
    private let files: CaptureDraftFileOperations
    private let codec: CaptureDraftEnvelopeCodec
    private let markerCodec: CaptureDraftSettlementMarkerCodec
    private let makeUUID: () -> UUID
    private var needsStartupDirectorySync = true
    init(
        storage: AppOwnedStorage,
        publisher: DurableRegularFilePublisher = DurableRegularFilePublisher(),
        files: CaptureDraftFileOperations = .live,
        codec: CaptureDraftEnvelopeCodec = CaptureDraftEnvelopeCodec(),
        markerCodec: CaptureDraftSettlementMarkerCodec = CaptureDraftSettlementMarkerCodec(),
        makeUUID: @escaping () -> UUID = UUID.init
    ) {
        self.storage = storage
        self.publisher = publisher
        self.files = files
        self.codec = codec
        self.markerCodec = markerCodec
        self.makeUUID = makeUUID
    }
    var currentURL: URL {
        draftsURL.appendingPathComponent(Self.currentFileName, isDirectory: false)
    }

    var settlementURL: URL {
        draftsURL.appendingPathComponent(Self.settlementFileName, isDirectory: false)
    }

    func state() -> CaptureDraftStoreState {
        guard files.fileExists(currentURL) else {
            return .none
        }

        let bytes: Data
        do {
            bytes = try files.read(currentURL)
        } catch {
            if Self.isNoSuchFile(error) {
                return .none
            }
            return .unrecoverable(
                CaptureDraftUnrecoverable(
                    reason: .unreadable,
                    revision: .corruptFingerprint(unreadableFingerprint())
                )
            )
        }

        let decodedState: CaptureDraftStoreState
        do {
            decodedState = .recoverable(try codec.decode(bytes))
        } catch let error as CaptureDraftEnvelopeValidationError {
            decodedState = .unrecoverable(
                CaptureDraftUnrecoverable(
                    reason: error.corruptionReason,
                    revision: .corruptFingerprint(codec.fingerprint(bytes))
                )
            )
        } catch {
            decodedState = .unrecoverable(
                CaptureDraftUnrecoverable(
                    reason: .malformedEnvelope,
                    revision: .corruptFingerprint(codec.fingerprint(bytes))
                )
            )
        }
        guard synchronizeStartupDirectoryIfNeeded() else {
            guard let revision = decodedState.revision else {
                return .none
            }
            return .durabilityPending(revision)
        }
        return decodedState
    }

    func publish(_ draft: StoredCaptureDraft) throws {
        let bytes: Data
        do {
            bytes = try codec.encode(draft)
        } catch {
            throw CaptureDraftStoreError.persistenceFailed
        }

        do {
            try publishBytes(
                bytes,
                stagingPrefix: Self.currentStagingPrefix,
                destinationFileName: Self.currentFileName
            )
            guard case .recoverable(let committed) = state(),
                  committed.token == draft.token else {
                throw CaptureDraftStoreError.publicationOutcomeUncertain
            }
        } catch let error as CaptureDraftStoreError {
            throw error
        } catch {
            throw CaptureDraftStoreError.persistenceFailed
        }
    }

    func discard(_ expected: CaptureDraftRevision) throws {
        let tombstone = retirementURL(for: currentURL)
        if !files.fileExists(currentURL), files.fileExists(tombstone) {
            guard retiredRevision(at: tombstone) == expected else {
                throw CaptureDraftStoreError.staleRevision
            }
            try finishRetirement(tombstone)
            return
        }
        guard state().revision == expected else {
            throw CaptureDraftStoreError.staleRevision
        }
        try retire(currentURL)
    }

    func markSettlement(_ token: CaptureDraftToken) throws {
        let bytes: Data
        do {
            bytes = try markerCodec.encode(token)
        } catch {
            throw CaptureDraftStoreError.persistenceFailed
        }

        try publishBytes(
            bytes,
            stagingPrefix: Self.settlementStagingPrefix,
            destinationFileName: Self.settlementFileName
        )
        guard case .active(let committed) = settlementEvidence(),
              committed == token else {
            throw CaptureDraftStoreError.publicationOutcomeUncertain
        }
    }

    func settlementGuard(
        currentRevision: CaptureDraftRevision?
    ) -> CaptureDraftSettlementGuard {
        guard let revision = currentRevision ?? pendingRetiredDraftRevision() else {
            return .none
        }
        switch settlementEvidence() {
        case .none:
            return .none
        case .active(let token), .retired(let token):
            guard revision == .generation(token) else {
                return .none
            }
            return .pending(token)
        case .unreadable:
            guard case .generation = revision else {
                return .none
            }
            return .unresolved(revision)
        }
    }

    func pendingRetiredDraftRevision() -> CaptureDraftRevision? {
        let tombstone = retirementURL(for: currentURL)
        guard files.fileExists(tombstone) else {
            return nil
        }
        return retiredRevision(at: tombstone)
    }

    func discardSettlementMarker(_ expected: CaptureDraftToken) throws {
        switch settlementEvidence() {
        case .none:
            return
        case .active(let token):
            guard token == expected else {
                return
            }
            try retire(settlementURL)
        case .retired(let token):
            guard token == expected else {
                return
            }
            try finishRetirement(retirementURL(for: settlementURL))
        case .unreadable:
            throw CaptureDraftStoreError.persistenceFailed
        }
    }

    func abortSettlement(_ expected: CaptureDraftToken) throws {
        try restoreRetiredDraftIfNeeded(expected)
        switch settlementEvidence() {
        case .unreadable:
            try discardUnreadableSettlementMarker(expected)
        case .none, .active, .retired:
            try discardSettlementMarker(expected)
        }
    }

    func removeOrphanedSettlementEvidence() throws {
        guard state().revision == nil,
              pendingRetiredDraftRevision() == nil else {
            return
        }
        switch settlementEvidence() {
        case .none:
            return
        case .active, .unreadable:
            try retire(settlementURL)
        case .retired:
            try finishRetirement(retirementURL(for: settlementURL))
        }
    }
}

private extension CaptureDraftStore {
    private var draftsURL: URL {
        storage.rootURL.appendingPathComponent(Self.directoryName, isDirectory: true)
    }

    private func ensureDirectories() throws {
        try files.createDirectory(storage.rootURL)
        try files.createDirectory(draftsURL)
        try synchronizeDirectoryChainIfNeeded()
    }

    private func publishBytes(
        _ bytes: Data,
        stagingPrefix: String,
        destinationFileName: String
    ) throws {
        do {
            try ensureDirectories()
            cleanupStagingFiles()
            cleanupRetirementFiles()
            let staging = try DurableRegularFilePublisher.RelativeFile(
                parentComponents: [Self.directoryName],
                fileName: stagingPrefix + makeUUID().uuidString.lowercased() + Self.stagingSuffix
            )
            let destination = try DurableRegularFilePublisher.RelativeFile(
                parentComponents: [Self.directoryName],
                fileName: destinationFileName
            )
            try publisher.publish(
                bytes,
                staging: staging,
                destination: destination,
                beneath: storage.rootURL,
                isExcludedFromBackup: true
            )
            cleanupStagingFiles()
        } catch let error as DurableRegularFilePublicationError {
            cleanupStagingFiles()
            if error.outcome == .publicationOutcomeUncertain {
                throw CaptureDraftStoreError.publicationOutcomeUncertain
            }
            throw CaptureDraftStoreError.persistenceFailed
        } catch let error as CaptureDraftStoreError {
            throw error
        } catch {
            throw CaptureDraftStoreError.persistenceFailed
        }
    }

    private func settlementEvidence() -> SettlementEvidence {
        if files.fileExists(settlementURL) {
            do {
                return .active(try markerCodec.decode(files.read(settlementURL)))
            } catch {
                SnapDrillLogger.capture.warning(
                    "Capture settlement marker is unreadable: \(error.localizedDescription)"
                )
                return .unreadable
            }
        }
        let tombstone = retirementURL(for: settlementURL)
        guard files.fileExists(tombstone) else {
            return .none
        }
        do {
            return .retired(try markerCodec.decode(files.read(tombstone)))
        } catch {
            SnapDrillLogger.capture.warning(
                "Retired Capture settlement marker is unreadable: \(error.localizedDescription)"
            )
            return .unreadable
        }
    }

    private func restoreRetiredDraftIfNeeded(_ expected: CaptureDraftToken) throws {
        let revision = CaptureDraftRevision.generation(expected)
        if files.fileExists(currentURL) {
            guard state().revision == revision else {
                throw CaptureDraftStoreError.staleRevision
            }
            try synchronizeDraftsDirectory()
            return
        }

        let tombstone = retirementURL(for: currentURL)
        guard files.fileExists(tombstone) else {
            return
        }
        guard retiredRevision(at: tombstone) == revision else {
            throw CaptureDraftStoreError.staleRevision
        }
        do {
            try files.move(tombstone, currentURL)
        } catch {
            if !Self.isNoSuchFile(error) {
                throw CaptureDraftStoreError.persistenceFailed
            }
        }
        try synchronizeDraftsDirectory()
    }

    private func discardUnreadableSettlementMarker(
        _ expected: CaptureDraftToken
    ) throws {
        guard state().revision == .generation(expected) else {
            throw CaptureDraftStoreError.staleRevision
        }
        let tombstone = retirementURL(for: settlementURL)
        if files.fileExists(settlementURL) {
            try retire(settlementURL)
        } else if files.fileExists(tombstone) {
            try finishRetirement(tombstone)
        } else {
            throw CaptureDraftStoreError.staleRevision
        }
    }

    private func synchronizeStartupDirectoryIfNeeded() -> Bool {
        guard needsStartupDirectorySync else {
            return true
        }
        do {
            try synchronizeDirectoryChainIfNeeded()
            return true
        } catch {
            SnapDrillLogger.capture.warning(
                "Capture draft startup durability sync deferred: \(error.localizedDescription)"
            )
            return false
        }
    }

    private func synchronizeDirectoryChainIfNeeded() throws {
        guard needsStartupDirectorySync else {
            return
        }
        do {
            try files.synchronizeDirectoryChain(
                storage: storage,
                leafDirectory: draftsURL
            )
        } catch {
            throw CaptureDraftStoreError.publicationOutcomeUncertain
        }
        needsStartupDirectorySync = false
    }

    private func synchronizeDraftsDirectory() throws {
        do {
            try files.synchronizeDirectory(draftsURL)
        } catch {
            throw CaptureDraftStoreError.publicationOutcomeUncertain
        }
    }

    private func retire(_ source: URL) throws {
        let tombstone = retirementURL(for: source)
        if files.fileExists(tombstone) {
            try finishRetirement(tombstone)
        }
        do {
            try files.move(source, tombstone)
        } catch {
            if Self.isNoSuchFile(error) {
                return
            }
            throw CaptureDraftStoreError.persistenceFailed
        }

        try finishRetirement(tombstone)
    }

    private func finishRetirement(_ tombstone: URL) throws {
        do {
            try files.synchronizeDirectory(draftsURL)
        } catch {
            throw CaptureDraftStoreError.publicationOutcomeUncertain
        }

        do {
            if files.fileExists(tombstone) {
                try files.remove(tombstone)
                try files.synchronizeDirectory(draftsURL)
            }
        } catch {
            // The source absence was already durably committed. A hidden tombstone
            // can be cleaned on the next store operation without exposing a draft.
            SnapDrillLogger.capture.warning(
                "Capture draft tombstone cleanup deferred: \(error.localizedDescription)"
            )
        }
    }

    private func cleanupStagingFiles() {
        guard files.fileExists(draftsURL) else {
            return
        }
        let candidates: [URL]
        do {
            candidates = try files.contents(draftsURL)
        } catch {
            SnapDrillLogger.capture.warning(
                "Capture draft staging scan failed: \(error.localizedDescription)"
            )
            return
        }

        for candidate in candidates where Self.isStagingName(candidate.lastPathComponent) {
            do {
                let values = try candidate.resourceValues(
                    forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
                )
                guard values.isRegularFile == true, values.isSymbolicLink != true else {
                    continue
                }
                try files.remove(candidate)
            } catch {
                SnapDrillLogger.capture.warning(
                    "Capture draft staging cleanup failed: \(error.localizedDescription)"
                )
            }
        }
    }

    private func cleanupRetirementFiles() {
        guard files.fileExists(draftsURL) else {
            return
        }
        let candidates: [URL]
        do {
            candidates = try files.contents(draftsURL)
        } catch {
            return
        }

        for candidate in candidates where Self.isRetirementName(candidate.lastPathComponent) {
            do {
                try finishRetirement(candidate)
            } catch {
                SnapDrillLogger.capture.warning(
                    "Capture draft tombstone cleanup failed: \(error.localizedDescription)"
                )
            }
        }
    }

    private func retirementURL(for source: URL) -> URL {
        draftsURL.appendingPathComponent(
            ".\(source.lastPathComponent)\(Self.retirementSuffix)",
            isDirectory: false
        )
    }

    private func retiredRevision(at url: URL) -> CaptureDraftRevision? {
        let bytes: Data
        do {
            bytes = try files.read(url)
        } catch {
            return .corruptFingerprint(unreadableFingerprint(for: url))
        }
        do {
            return .generation(try codec.decode(bytes).token)
        } catch {
            return .corruptFingerprint(codec.fingerprint(bytes))
        }
    }

    private func unreadableFingerprint(for url: URL? = nil) -> String {
        do {
            let attributes = try files.attributes(url ?? currentURL)
            let size = attributes[.size] as? NSNumber
            let modified = attributes[.modificationDate] as? Date
            return "unreadable:\(size?.uint64Value ?? 0):\(modified?.timeIntervalSince1970 ?? 0)"
        } catch {
            return "unreadable:unknown"
        }
    }

}
