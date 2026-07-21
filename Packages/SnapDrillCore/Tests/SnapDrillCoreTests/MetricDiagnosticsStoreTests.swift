//
//  MetricDiagnosticsStoreTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Metric diagnostics store", .serialized)
struct MetricDiagnosticsStoreTests {
    @Test("Writes only beneath the app-owned diagnostics path")
    func writesExactOwnedPath() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let sentinels = try fixture.makeSiblingSentinels()

        try fixture.store().persist(
            Data("metric".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 1)
        )

        let files = try fixture.payloadFiles()
        #expect(files.count == 1)
        let written = try #require(files.first)
        #expect(try Data(contentsOf: written) == Data("metric".utf8))
        #expect(
            try written.resourceValues(
                forKeys: [.isExcludedFromBackupKey]
            ).isExcludedFromBackup == true
        )
        #expect(try fixture.protectionClass(at: written) == 3)
        #expect(FileManager.default.fileExists(atPath: fixture.diagnosticsURL.path))
        #expect(FileManager.default.fileExists(atPath: fixture.metricKitURL.path))
        #expect(
            try fixture.diagnosticsURL.resourceValues(
                forKeys: [.isExcludedFromBackupKey]
            ).isExcludedFromBackup == true
        )
        #expect(
            try fixture.protectionClass(at: fixture.diagnosticsURL) == 3
        )
        #expect(
            try fixture.protectionClass(at: fixture.metricKitURL) == 3
        )
        #expect(
            try fixture.root.resourceValues(
                forKeys: [.isExcludedFromBackupKey]
            ).isExcludedFromBackup != true
        )
        try fixture.expectSentinelsUnchanged(sentinels)
    }

    @Test("Every fixed-node attack fails closed", arguments: FixedNodeAttack.allCases)
    func fixedNodeAttackFailsClosed(attack: FixedNodeAttack) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let outside = fixture.container.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        let sentinel = outside.appendingPathComponent("sentinel")
        try Data("sentinel".utf8).write(to: sentinel)
        try attack.install(in: fixture, outside: outside)

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store().persist(
                Data("blocked".utf8),
                kind: .diagnostic,
                receivedAt: Date(timeIntervalSince1970: 2)
            )
        }
        #expect(try Data(contentsOf: sentinel) == Data("sentinel".utf8))
        #expect(try FileManager.default.contentsOfDirectory(atPath: outside.path) == ["sentinel"])
    }

    @Test(arguments: HostileEntry.allCases)
    func hostileChildBlocksWrite(entry: HostileEntry) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareMetricDirectory()
        let sentinel = fixture.container.appendingPathComponent("sentinel")
        try Data("sentinel".utf8).write(to: sentinel)
        try entry.install(in: fixture.metricKitURL, sentinel: sentinel)
        let before = try Data(contentsOf: sentinel)
        let namesBefore = try fixture.entryNames()

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store().persist(
                Data("blocked".utf8),
                kind: .diagnostic,
                receivedAt: Date(timeIntervalSince1970: 3)
            )
        }

        #expect(try Data(contentsOf: sentinel) == before)
        #expect(try fixture.entryNames() == namesBefore)
    }

    @Test("A valid crash staging residue is swept before publication")
    func validStagingResidueIsSwept() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareMetricDirectory()
        try Data("stale".utf8).write(to: fixture.stagingURL)

        try fixture.store().persist(
            Data("fresh".utf8),
            kind: .diagnostic,
            receivedAt: Date(timeIntervalSince1970: 4)
        )

        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path) == false)
        #expect(try fixture.payloadFiles().count == 1)
    }

    @Test("A hostile staging node is preserved and blocks publication", arguments: HostileStaging.allCases)
    func hostileStagingBlocksPublication(attack: HostileStaging) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareMetricDirectory()
        let sentinel = fixture.container.appendingPathComponent("staging-sentinel")
        try Data("sentinel".utf8).write(to: sentinel)
        try attack.install(at: fixture.stagingURL, sentinel: sentinel)

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store().persist(
                Data("blocked".utf8),
                kind: .diagnostic,
                receivedAt: Date(timeIntervalSince1970: 4)
            )
        }
        #expect(try Data(contentsOf: sentinel) == Data("sentinel".utf8))
        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path))
    }

    @Test("The production bound rotates exactly one oldest payload with a lexical tie-break")
    func productionBoundRotatesOldestPayload() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let sentinels = try fixture.makeSiblingSentinels()
        let identifiers = IdentifierSequence(count: 31)
        let store = fixture.store(makeIdentifier: identifiers.next)

        for index in 0..<31 {
            try store.persist(
                Data("payload-\(index)".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: TimeInterval(max(index - 1, 0)))
            )
        }

        let payloads = try fixture.payloadFiles().map { try Data(contentsOf: $0) }
        #expect(payloads.count == 30)
        #expect(!payloads.contains(Data("payload-0".utf8)))
        #expect(payloads.contains(Data("payload-1".utf8)))
        #expect(payloads.contains(Data("payload-30".utf8)))
        try fixture.expectSentinelsUnchanged(sentinels)
    }

    @Test("An over-limit inventory is preserved and refuses another payload")
    func overLimitInventoryRefusesWrite() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let initialStore = fixture.store(maxStoredFiles: 3)
        for index in 0..<3 {
            try initialStore.persist(
                Data("payload-\(index)".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: TimeInterval(index + 20))
            )
        }
        let before = try fixture.entryNames()

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(maxStoredFiles: 2).persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 30)
            )
        }
        #expect(try fixture.entryNames() == before)
    }

    @Test("An over-limit inventory is rejected before a valid staging residue is removed")
    func overLimitInventoryPreservesStaging() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let initialStore = fixture.store(maxStoredFiles: 3)
        for index in 0..<3 {
            try initialStore.persist(
                Data("payload-\(index)".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: TimeInterval(index + 30))
            )
        }
        try Data("staging".utf8).write(to: fixture.stagingURL)
        let before = try fixture.entryNames()

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(maxStoredFiles: 2).persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 40)
            )
        }
        #expect(try fixture.entryNames() == before)
        #expect(try Data(contentsOf: fixture.stagingURL) == Data("staging".utf8))
    }

    @Test("Directory attribute failure is explicit and preserves payload inventory")
    func directoryAttributeFailurePreservesInventory() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.store().persist(
            Data("existing".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 41)
        )
        let before = try fixture.entryNames()
        var attributes = MetricDiagnosticsDirectoryAttributes.live
        attributes.apply = { _ in throw POSIXError(.EACCES) }

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(fileAttributes: attributes).persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 42)
            )
        }
        #expect(try fixture.entryNames() == before)
    }

    @Test("Payload attribute failure removes only its own staging node")
    func payloadAttributeFailurePreservesInventory() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.store().persist(
            Data("existing".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 43)
        )
        let before = try fixture.entryNames()
        let thirdInvocation = InvocationGate(target: 3)
        var attributes = MetricDiagnosticsDirectoryAttributes.live
        let applyLive = attributes.apply
        attributes.apply = { descriptor in
            guard !thirdInvocation.isTargetInvocation() else {
                throw POSIXError(.EACCES)
            }
            try applyLive(descriptor)
        }

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(fileAttributes: attributes).persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 44)
            )
        }
        #expect(try fixture.entryNames() == before)
    }

    @Test("A destination collision never overwrites the existing payload")
    func destinationCollisionDoesNotOverwrite() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let identifier = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let store = fixture.store(makeIdentifier: { identifier })
        let receivedAt = Date(timeIntervalSince1970: 40)
        try store.persist(Data("first".utf8), kind: .metric, receivedAt: receivedAt)
        let before = try fixture.payloadFiles()
        #expect(before.count == 1)

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try store.persist(Data("second".utf8), kind: .metric, receivedAt: receivedAt)
        }
        let after = try fixture.payloadFiles()
        #expect(after == before)
        #expect(try Data(contentsOf: #require(after.first)) == Data("first".utf8))
    }

    @Test("A directory rebind during attribute application is rejected")
    func directoryRebindIsRejected() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let moved = fixture.container.appendingPathComponent("moved-diagnostics", isDirectory: true)
        var didRebind = false
        var attributes = MetricDiagnosticsDirectoryAttributes.live
        let applyLive = attributes.apply
        attributes.apply = { descriptor in
            guard !didRebind else { return }
            didRebind = true
            try FileManager.default.moveItem(at: fixture.diagnosticsURL, to: moved)
            try FileManager.default.createDirectory(
                at: fixture.metricKitURL,
                withIntermediateDirectories: true
            )
            try applyLive(descriptor)
        }

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(fileAttributes: attributes).persist(
                Data("blocked".utf8),
                kind: .diagnostic,
                receivedAt: Date(timeIntervalSince1970: 50)
            )
        }
        #expect(didRebind)
        #expect(try fixture.payloadFiles().isEmpty)
        let movedMetricKit = moved.appendingPathComponent("MetricKit", isDirectory: true)
        #expect(try FileManager.default.contentsOfDirectory(atPath: movedMetricKit.path).isEmpty)
    }

    @Test("A directory rebind before publication cannot divert a payload")
    func publisherRejectsDirectoryRebind() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareMetricDirectory()
        let moved = fixture.container.appendingPathComponent("moved-diagnostics", isDirectory: true)
        let trigger = DirectoryRebindTrigger(
            source: fixture.diagnosticsURL,
            destination: moved,
            replacementMetricKit: fixture.metricKitURL
        )

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(makeIdentifier: trigger.next).persist(
                Data("blocked".utf8),
                kind: .diagnostic,
                receivedAt: Date(timeIntervalSince1970: 51)
            )
        }
        #expect(trigger.didRun)
        #expect(trigger.errorDescription == nil)
        #expect(try fixture.payloadFiles().isEmpty)
        let movedMetricKit = moved.appendingPathComponent("MetricKit", isDirectory: true)
        #expect(try FileManager.default.contentsOfDirectory(atPath: movedMetricKit.path).isEmpty)
    }

    @Test("Unavailable production root reports an explicit store error")
    func unavailableRootFailsExplicitly() {
        let store = MetricDiagnosticsStore(rootURL: nil)
        #expect(throws: MetricDiagnosticsStoreError.self) {
            try store.persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 10)
            )
        }
    }

    @Test("An out-of-range payload timestamp fails explicitly instead of trapping")
    func outOfRangeTimestampFailsExplicitly() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let boundary = Date(timeIntervalSince1970: Double(UInt64.max) / 1_000)

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store().persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: boundary
            )
        }
        #expect(try fixture.payloadFiles().isEmpty)
    }
}
