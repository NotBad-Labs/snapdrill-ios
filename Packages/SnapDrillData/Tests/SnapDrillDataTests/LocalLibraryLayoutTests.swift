//
//  LocalLibraryLayoutTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile-free local-library lexical identifier, selector, and path tests.
//

import Foundation
import Testing
@testable import SnapDrillData

@Suite("LocalLibrary layout semantics")
struct LocalLibraryLayoutTests {
    private nonisolated static let canonicalValue = "01234567-89ab-cdef-0123-456789abcdef"

    @Test("canonical UUID accepts exact lowercase grammar")
    func canonicalUUIDAcceptsLowercaseGrammar() throws {
        let identifier = try #require(LocalLibraryUUID(canonicalString: Self.canonicalValue))
        let foundationUUID = try #require(UUID(uuidString: Self.canonicalValue))

        #expect(identifier.canonicalString == Self.canonicalValue)
        #expect(LocalLibraryUUID(foundationUUID) == identifier)
    }

    @Test(
        "canonical UUID rejects noncanonical lexical input",
        arguments: [
            "01234567-89AB-CDEF-0123-456789ABCDEF",
            "{01234567-89ab-cdef-0123-456789abcdef}",
            "0123456789abcdef0123456789abcdef",
            "01234567_89ab-cdef-0123-456789abcdef",
            "01234567-89ab-cdeg-0123-456789abcdef",
            " 01234567-89ab-cdef-0123-456789abcdef",
            "01234567-89ab-cdef-0123-456789abcdef ",
            "../01234567-89ab-cdef-0123-456789ab",
            "01234567-89ab-cdef-0123-456789abcde\u{0}",
            "01234567-89ab-cdef-0123-456789abcdeé"
        ]
    )
    func canonicalUUIDRejectsNoncanonicalInput(_ value: String) {
        #expect(LocalLibraryUUID(canonicalString: value) == nil)
    }

    @Test("selector encodes one lowercase UUID and one LF")
    func selectorEncodingIsExact() throws {
        let identifier = try #require(LocalLibraryUUID(canonicalString: Self.canonicalValue))
        let encoded = LocalLibraryActiveGenerationSelector.encode(identifier)

        #expect(encoded == Data("\(Self.canonicalValue)\n".utf8))
        #expect(encoded.count == 37)
        #expect(encoded.last == 0x0A)
        #expect(encoded.allSatisfy { $0 < 0x80 })
        #expect(LocalLibraryActiveGenerationSelector.decode(encoded) == identifier)
    }

    @Test(
        "selector rejects every noncanonical boundary class",
        arguments: malformedSelectors
    )
    func selectorRejectsMalformedBytes(_ bytes: Data) {
        #expect(LocalLibraryActiveGenerationSelector.decode(bytes) == nil)
    }

    @Test("layout derives the complete fixed path inventory")
    func layoutDerivesFixedPaths() throws {
        let root = URL(fileURLWithPath: "/Application Support/com.snapdrill.global", isDirectory: true)
        let identifier = try #require(LocalLibraryUUID(canonicalString: Self.canonicalValue))
        let layout = LocalLibraryLayout(appOwnedRootURL: root)

        #expect(layout.appOwnedRootURL == root)
        #expect(layout.localLibraryDirectoryURL.path == "\(root.path)/LocalLibrary")
        #expect(layout.recoveryIncidentsDirectoryURL.path == "\(root.path)/RecoveryIncidents")
        #expect(layout.activeGenerationSelectorURL.path == "\(root.path)/LocalLibrary/active-generation")
        #expect(layout.generationsDirectoryURL.path == "\(root.path)/LocalLibrary/generations")
        #expect(layout.transactionsDirectoryURL.path == "\(root.path)/LocalLibrary/transactions")
        #expect(
            layout.generationDirectoryURL(for: identifier).path
                == "\(root.path)/LocalLibrary/generations/\(Self.canonicalValue)"
        )
        #expect(
            layout.transactionDirectoryURL(for: identifier).path
                == "\(root.path)/LocalLibrary/transactions/\(Self.canonicalValue)"
        )
        #expect(
            layout.recoveryIncidentDirectoryURL(for: identifier).path
                == "\(root.path)/RecoveryIncidents/\(Self.canonicalValue)"
        )
    }

    @Test("layout construction is side-effect-free and remains beneath injected root")
    func layoutIsPureAndConfined() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalLibraryLayoutTests-\(UUID().uuidString)", isDirectory: true)
        let identifier = try #require(LocalLibraryUUID(canonicalString: Self.canonicalValue))
        let layout = LocalLibraryLayout(appOwnedRootURL: root)
        let derivedURLs = [
            layout.localLibraryDirectoryURL,
            layout.recoveryIncidentsDirectoryURL,
            layout.activeGenerationSelectorURL,
            layout.generationsDirectoryURL,
            layout.transactionsDirectoryURL,
            layout.generationDirectoryURL(for: identifier),
            layout.transactionDirectoryURL(for: identifier),
            layout.recoveryIncidentDirectoryURL(for: identifier)
        ]

        #expect(!FileManager.default.fileExists(atPath: root.path))
        #expect(derivedURLs.allSatisfy { isDescendant($0, of: root) })
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    private nonisolated static var malformedSelectors: [Data] {
        let uppercase = canonicalValue.uppercased()
        return [
            Data(uppercase.appending("\n").utf8),
            Data([0xEF, 0xBB, 0xBF]) + Data(canonicalValue.appending("\n").utf8),
            Data(canonicalValue.appending("\r\n").utf8),
            Data(canonicalValue.utf8),
            Data(canonicalValue.appending("\n\n").utf8),
            Data(" \(canonicalValue.dropFirst())\n".utf8),
            Data("\(canonicalValue.dropLast()) \n".utf8),
            Data("\(canonicalValue.dropLast())\u{0}\n".utf8),
            Data("\(canonicalValue.dropLast(2))é\n".utf8),
            Data("../generations/\(canonicalValue)\n".utf8),
            Data("\(canonicalValue)\nother".utf8)
        ]
    }

    private func isDescendant(_ candidate: URL, of root: URL) -> Bool {
        let rootComponents = root.standardizedFileURL.pathComponents
        let candidateComponents = candidate.standardizedFileURL.pathComponents
        return candidateComponents.starts(with: rootComponents) && candidateComponents.count > rootComponents.count
    }
}
