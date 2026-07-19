//
//  CaptureDraftStoreTypes.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation

enum CaptureDraftStoreState {
    case none
    case recoverable(StoredCaptureDraft)
    case durabilityPending(CaptureDraftRevision)
    case unrecoverable(CaptureDraftUnrecoverable)

    var revision: CaptureDraftRevision? {
        switch self {
        case .none:
            nil
        case .recoverable(let draft):
            .generation(draft.token)
        case .durabilityPending(let revision):
            revision
        case .unrecoverable(let failure):
            failure.revision
        }
    }
}

enum CaptureDraftStoreError: Error, Equatable {
    case staleRevision
    case persistenceFailed
    case publicationOutcomeUncertain
}

enum CaptureDraftSettlementGuard {
    case none
    case pending(CaptureDraftToken)
    case unresolved(CaptureDraftRevision)
}

extension CaptureDraftStore {
    static let directoryName = "Drafts"
    static let currentFileName = "current.v1"
    static let settlementFileName = "settlement.v1"
    static let currentStagingPrefix = ".current.v1."
    static let settlementStagingPrefix = ".settlement.v1."
    static let stagingSuffix = ".staging"
    static let retirementSuffix = ".retired"

    enum SettlementEvidence {
        case none
        case active(CaptureDraftToken)
        case retired(CaptureDraftToken)
        case unreadable
    }

    static func isStagingName(_ name: String) -> Bool {
        (name.hasPrefix(currentStagingPrefix) || name.hasPrefix(settlementStagingPrefix))
            && name.hasSuffix(stagingSuffix)
    }

    static func isRetirementName(_ name: String) -> Bool {
        name == ".\(currentFileName)\(retirementSuffix)"
            || name == ".\(settlementFileName)\(retirementSuffix)"
    }

    static func isNoSuchFile(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain
            && (nsError.code == NSFileNoSuchFileError
                || nsError.code == NSFileReadNoSuchFileError)
    }
}
