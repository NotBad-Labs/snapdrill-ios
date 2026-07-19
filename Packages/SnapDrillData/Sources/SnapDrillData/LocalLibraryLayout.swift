//
//  LocalLibraryLayout.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile-free local-library identifiers, selector grammar, and path layout.
//

import Foundation

/// A lowercase canonical UUID used by LocalLibrary disk artifacts.
///
/// String input is validated lexically. It is never normalized, so malformed or
/// noncanonical input cannot silently select a different disk artifact.
nonisolated struct LocalLibraryUUID: Hashable, Sendable {
    static let canonicalByteCount = 36

    let canonicalString: String

    init?(canonicalString: String) {
        let bytes = Array(canonicalString.utf8)
        guard bytes.count == Self.canonicalByteCount,
              bytes.enumerated().allSatisfy({ Self.isCanonicalByte($0.element, at: $0.offset) })
        else {
            return nil
        }

        self.canonicalString = canonicalString
    }

    init(_ uuid: UUID) {
        canonicalString = uuid.uuidString.lowercased()
    }

    private static func isCanonicalByte(_ byte: UInt8, at index: Int) -> Bool {
        switch index {
        case 8, 13, 18, 23:
            return byte == 0x2D
        default:
            return (0x30...0x39).contains(byte) || (0x61...0x66).contains(byte)
        }
    }
}

/// Exact wire grammar for `LocalLibrary/active-generation`.
nonisolated enum LocalLibraryActiveGenerationSelector {
    static let byteCount = LocalLibraryUUID.canonicalByteCount + 1
    private static let lineFeed: UInt8 = 0x0A

    static func encode(_ generationID: LocalLibraryUUID) -> Data {
        var bytes = Data(generationID.canonicalString.utf8)
        bytes.append(lineFeed)
        return bytes
    }

    static func decode(_ bytes: Data) -> LocalLibraryUUID? {
        guard bytes.count == byteCount, bytes.last == lineFeed else {
            return nil
        }

        let identifierBytes = bytes.dropLast()
        guard let value = String(bytes: identifierBytes, encoding: .utf8) else {
            return nil
        }
        return LocalLibraryUUID(canonicalString: value)
    }
}

/// Pure URL composition for the Profile-free local-library disk layout.
nonisolated struct LocalLibraryLayout: Sendable {
    let appOwnedRootURL: URL

    init(appOwnedRootURL: URL) {
        self.appOwnedRootURL = appOwnedRootURL
    }

    var localLibraryDirectoryURL: URL {
        appOwnedRootURL.appendingPathComponent("LocalLibrary", isDirectory: true)
    }

    var recoveryIncidentsDirectoryURL: URL {
        appOwnedRootURL.appendingPathComponent("RecoveryIncidents", isDirectory: true)
    }

    var activeGenerationSelectorURL: URL {
        localLibraryDirectoryURL.appendingPathComponent("active-generation", isDirectory: false)
    }

    var generationsDirectoryURL: URL {
        localLibraryDirectoryURL.appendingPathComponent("generations", isDirectory: true)
    }

    var transactionsDirectoryURL: URL {
        localLibraryDirectoryURL.appendingPathComponent("transactions", isDirectory: true)
    }

    func generationDirectoryURL(for id: LocalLibraryUUID) -> URL {
        generationsDirectoryURL.appendingPathComponent(id.canonicalString, isDirectory: true)
    }

    func transactionDirectoryURL(for id: LocalLibraryUUID) -> URL {
        transactionsDirectoryURL.appendingPathComponent(id.canonicalString, isDirectory: true)
    }

    func recoveryIncidentDirectoryURL(for id: LocalLibraryUUID) -> URL {
        recoveryIncidentsDirectoryURL.appendingPathComponent(id.canonicalString, isDirectory: true)
    }
}
