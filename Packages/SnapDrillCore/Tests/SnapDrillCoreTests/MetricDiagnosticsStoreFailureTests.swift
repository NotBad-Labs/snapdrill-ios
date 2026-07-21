//
//  MetricDiagnosticsStoreFailureTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Metric diagnostics store failure handling", .serialized)
struct MetricDiagnosticsStoreFailureTests {
    typealias Fixture = MetricDiagnosticsStoreTests.Fixture

    @Test("Enumeration failure refuses a write without changing inventory")
    func enumerationFailurePreservesInventory() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let baselineStore = fixture.store(maxStoredFiles: 2)
        try baselineStore.persist(
            Data("existing".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 5)
        )
        let before = try fixture.entryNames()
        var fileSystem = MetricDiagnosticsFileSystem.live
        fileSystem.listNames = { _ in throw MetricDiagnosticsPOSIXError(code: EIO) }

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(maxStoredFiles: 2, fileSystem: fileSystem).persist(
                Data("new".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 6)
            )
        }
        #expect(try fixture.entryNames() == before)
    }

    @Test("Delete failure refuses a write without changing payload inventory")
    func deleteFailurePreservesInventory() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let baselineStore = fixture.store(maxStoredFiles: 2)
        try baselineStore.persist(
            Data("first".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 7)
        )
        try baselineStore.persist(
            Data("second".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 8)
        )
        let before = try fixture.entryNames()
        var fileSystem = MetricDiagnosticsFileSystem.live
        let unlinkLive = fileSystem.unlinkAt
        fileSystem.unlinkAt = { parent, name in
            if name == MetricDiagnosticsStore.stagingFileName {
                return unlinkLive(parent, name)
            }
            errno = EACCES
            return -1
        }

        do {
            try fixture.store(maxStoredFiles: 2, fileSystem: fileSystem).persist(
                Data("third".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 9)
            )
            Issue.record("Expected the injected rotation delete to fail")
        } catch let error as MetricDiagnosticsStoreError {
            #expect(error.outcome == .notPersisted)
            #expect(error.step == .rotate)
        }
        #expect(try fixture.entryNames() == before)
    }

    @Test("A staging write failure at capacity preserves every existing payload")
    func writeFailureAtCapacityPreservesInventory() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let baselineStore = fixture.store(maxStoredFiles: 2)
        try baselineStore.persist(
            Data("first".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 10)
        )
        try baselineStore.persist(
            Data("second".utf8),
            kind: .metric,
            receivedAt: Date(timeIntervalSince1970: 11)
        )
        let before = try fixture.entryNames()
        var fileSystem = MetricDiagnosticsFileSystem.live
        fileSystem.write = { _, _, _ in
            errno = ENOSPC
            return -1
        }

        do {
            try fixture.store(maxStoredFiles: 2, fileSystem: fileSystem).persist(
                Data("third".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 12)
            )
            Issue.record("Expected the injected staging write to fail")
        } catch let error as MetricDiagnosticsStoreError {
            #expect(error.outcome == .notPersisted)
            #expect(error.step == .writeStaging)
            #expect(error.code == ENOSPC)
        }
        #expect(try fixture.entryNames() == before)
        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path) == false)
    }

    @Test("A directory sync failure after rename reports an uncertain outcome")
    func postRenameSyncFailureIsUncertain() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var didRename = false
        var fileSystem = MetricDiagnosticsFileSystem.live
        let renameLive = fileSystem.renameAt
        let synchronizeLive = fileSystem.synchronize
        fileSystem.renameAt = { parent, oldName, newName, flags in
            let result = renameLive(parent, oldName, newName, flags)
            if result == 0 { didRename = true }
            return result
        }
        fileSystem.synchronize = { descriptor in
            guard didRename else { return synchronizeLive(descriptor) }
            errno = EIO
            return -1
        }

        do {
            try fixture.store(fileSystem: fileSystem).persist(
                Data("persisted".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 13)
            )
            Issue.record("Expected the injected post-rename sync to fail")
        } catch let error as MetricDiagnosticsStoreError {
            #expect(error.outcome == .persistenceOutcomeUncertain)
            #expect(error.step == .synchronizeDirectory)
        }
        #expect(try fixture.payloadFiles().count == 1)
        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path) == false)
    }

    @Test("Failure cleanup never deletes a replacement staging node")
    func failureCleanupRequiresStagingIdentity() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let displaced = fixture.metricKitURL.appendingPathComponent("displaced-staging")
        let replacement = Data("replacement".utf8)
        var fileSystem = MetricDiagnosticsFileSystem.live
        fileSystem.write = { _, _, _ in
            do {
                try FileManager.default.moveItem(at: fixture.stagingURL, to: displaced)
                try replacement.write(to: fixture.stagingURL)
            } catch {
                errno = EIO
                return -1
            }
            errno = ENOSPC
            return -1
        }

        #expect(throws: MetricDiagnosticsStoreError.self) {
            try fixture.store(fileSystem: fileSystem).persist(
                Data("blocked".utf8),
                kind: .metric,
                receivedAt: Date(timeIntervalSince1970: 14)
            )
        }
        #expect(try Data(contentsOf: fixture.stagingURL) == replacement)
        #expect(FileManager.default.fileExists(atPath: displaced.path))
    }
}
