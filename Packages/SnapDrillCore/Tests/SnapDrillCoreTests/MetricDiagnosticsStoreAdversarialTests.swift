//
//  MetricDiagnosticsStoreAdversarialTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillCore

extension MetricDiagnosticsStoreTests {
    @Test("A fresh install creates the missing Application Support path")
    func missingApplicationSupportPathIsCreated() throws {
        let fixture = try Fixture(createContainer: false)
        defer { fixture.remove() }

        try fixture.store().persist(
            Data("fresh-install".utf8),
            kind: .diagnostic,
            receivedAt: Date(timeIntervalSince1970: 2)
        )

        #expect(FileManager.default.fileExists(atPath: fixture.container.path))
        #expect(FileManager.default.fileExists(atPath: fixture.root.path))
        #expect(try fixture.payloadFiles().count == 1)
    }

    @Test(
        "A link with a valid payload name blocks inventory",
        arguments: HostileStaging.allCases
    )
    func validNamedLinkBlocksInventory(attack: HostileStaging) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareMetricDirectory()
        let sentinel = fixture.container.appendingPathComponent("valid-name-sentinel")
        try Data("sentinel".utf8).write(to: sentinel)
        let payload = fixture.metricKitURL.appendingPathComponent(
            "00000000000000000001-metric-00000000000000000000000000000001.json"
        )
        try attack.install(at: payload, sentinel: sentinel)

        do {
            try fixture.store().persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 3)
            )
            Issue.record("Expected the valid-named link to block inventory")
        } catch let error as MetricDiagnosticsStoreError {
            #expect(error.outcome == .notPersisted)
            #expect(error.step == .inspectEntry)
        }
        #expect(try Data(contentsOf: sentinel) == Data("sentinel".utf8))
        #expect(FileManager.default.fileExists(atPath: payload.path))
    }

    @Test(
        "Rotation rejects a valid-named target replaced after inventory",
        arguments: HostileStaging.allCases
    )
    func rotationRejectsReplacedTarget(attack: HostileStaging) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let initialIdentifier = IdentifierSequence(count: 1)
        try fixture.store(maxStoredFiles: 1, makeIdentifier: initialIdentifier.next).persist(
            Data("oldest".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 10)
        )
        let original = try #require(fixture.payloadFiles().first)
        let displaced = fixture.container.appendingPathComponent("displaced-payload")
        let sentinel = fixture.container.appendingPathComponent("rotation-sentinel")
        try Data("sentinel".utf8).write(to: sentinel)
        let trigger = PayloadReplacementTrigger(
            source: original,
            displaced: displaced,
            sentinel: sentinel,
            attack: attack
        )

        do {
            try fixture.store(maxStoredFiles: 1, makeIdentifier: trigger.next).persist(
                Data("new".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 11)
            )
            Issue.record("Expected the replaced rotation target to fail closed")
        } catch let error as MetricDiagnosticsStoreError {
            #expect(error.outcome == .notPersisted)
            #expect(error.step == .rotate)
        }

        #expect(trigger.didRun)
        #expect(trigger.errorDescription == nil)
        #expect(try Data(contentsOf: sentinel) == Data("sentinel".utf8))
        #expect(try Data(contentsOf: displaced) == Data("oldest".utf8))
        #expect(FileManager.default.fileExists(atPath: original.path))
        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path) == false)
    }
}
