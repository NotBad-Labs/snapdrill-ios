//
//  MetricServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  MetricService 测试：测 handler 纯逻辑（手造快照），不测 MetricKit 框架本身
//  （模拟器不投递真 payload、注册行为不可控）。
//

import Testing
import Foundation
@testable import SnapDrillCore

@Suite("MetricServiceMock 记录行为")
struct MetricServiceMockTests {

    @Test("handle 记录快照")
    func handleRecordsSnapshots() {
        let mock = MetricServiceMock()
        let snapshot = MetricPayloadSnapshot(kind: .diagnostic, crashCount: 2, receivedAt: Date(timeIntervalSince1970: 0))
        mock.handle(snapshot)

        #expect(mock.receivedSnapshots.count == 1)
        #expect(mock.receivedSnapshots.first == snapshot)
    }

    @Test("startMonitoring 计数")
    func startMonitoringCounts() {
        let mock = MetricServiceMock()
        mock.startMonitoring()
        mock.startMonitoring()

        #expect(mock.startMonitoringCallCount == 2)
    }

    @Test("reset 清零")
    func resetClears() {
        let mock = MetricServiceMock()
        mock.startMonitoring()
        mock.handle(MetricPayloadSnapshot(kind: .metric, receivedAt: Date(timeIntervalSince1970: 0)))
        mock.reset()

        #expect(mock.receivedSnapshots.isEmpty)
        #expect(mock.startMonitoringCallCount == 0)
    }
}

@Suite("MetricPayloadSnapshot 语义")
struct MetricPayloadSnapshotTests {

    @Test("hasDiagnosticSignal：任一异常计数 > 0")
    func diagnosticSignalDetection() {
        let clean = MetricPayloadSnapshot(kind: .diagnostic, receivedAt: Date(timeIntervalSince1970: 0))
        #expect(clean.hasDiagnosticSignal == false)

        let crashed = MetricPayloadSnapshot(kind: .diagnostic, crashCount: 1, receivedAt: Date(timeIntervalSince1970: 0))
        #expect(crashed.hasDiagnosticSignal == true)

        let hung = MetricPayloadSnapshot(kind: .diagnostic, hangCount: 3, receivedAt: Date(timeIntervalSince1970: 0))
        #expect(hung.hasDiagnosticSignal == true)
    }

    @Test("metric 类型默认无诊断信号")
    func metricKindNoSignal() {
        let metric = MetricPayloadSnapshot(kind: .metric, receivedAt: Date(timeIntervalSince1970: 0))
        #expect(metric.hasDiagnosticSignal == false)
    }
}

@Suite("LiveMetricService handle 落盘逻辑")
struct LiveMetricServiceTests {

    private func makeTempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("metrickit-test-\(UUID().uuidString)", isDirectory: true)
    }

    @Test("诊断快照含 JSON → 落盘到注入目录")
    func handlePersistsDiagnosticJSON() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = LiveMetricService(storageDirectory: tempDir)
        let json = Data(#"{"crash":1}"#.utf8)
        service.handle(MetricPayloadSnapshot(
            kind: .diagnostic, crashCount: 1, jsonRepresentation: json, receivedAt: Date(timeIntervalSince1970: 0)
        ))

        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        let written = try #require(files.first)
        #expect(try Data(contentsOf: written) == json)
    }

    @Test("快照无 JSON → 不落盘")
    func handleSkipsPersistWhenNoJSON() {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = LiveMetricService(storageDirectory: tempDir)
        service.handle(MetricPayloadSnapshot(kind: .metric, receivedAt: Date(timeIntervalSince1970: 0)))

        let files = (try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)) ?? []
        #expect(files.isEmpty)
    }

    @Test("nil 落盘目录 → 不崩溃、不落盘")
    func handleToleratesNilDirectory() {
        let service = LiveMetricService(storageDirectory: nil)
        // 不应抛出/崩溃
        service.handle(MetricPayloadSnapshot(
            kind: .diagnostic, crashCount: 1, jsonRepresentation: Data("x".utf8), receivedAt: Date(timeIntervalSince1970: 0)
        ))
    }

    @Test("落盘轮转：超过上限保留最近 N 个")
    func rotateKeepsAtMostMaxFiles() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = LiveMetricService(storageDirectory: tempDir, maxStoredFiles: 2)
        for index in 0..<5 {
            service.handle(MetricPayloadSnapshot(
                kind: .diagnostic, crashCount: 1,
                jsonRepresentation: Data("\(index)".utf8),
                receivedAt: Date(timeIntervalSince1970: TimeInterval(index))
            ))
        }

        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        #expect(files.count == 2)
    }

    @Test("同一秒同类型两快照都落盘（文件名唯一，不互相覆盖）")
    func sameSecondSnapshotsBothPersist() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let service = LiveMetricService(storageDirectory: tempDir, maxStoredFiles: 30)
        let sameTime = Date(timeIntervalSince1970: 100)
        service.handle(MetricPayloadSnapshot(
            kind: .diagnostic, crashCount: 1, jsonRepresentation: Data("a".utf8), receivedAt: sameTime
        ))
        service.handle(MetricPayloadSnapshot(
            kind: .diagnostic, crashCount: 1, jsonRepresentation: Data("b".utf8), receivedAt: sameTime
        ))

        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        #expect(files.count == 2)
    }

    @Test("MetricKit subscriber 回调选择子存在（防 ObjC 可选方法静默错名）")
    func metricKitSubscriberSelectorsExist() {
        let service = LiveMetricService(storageDirectory: nil)
        #expect(service.responds(to: NSSelectorFromString("didReceiveMetricPayloads:")))
        #expect(service.responds(to: NSSelectorFromString("didReceiveDiagnosticPayloads:")))
    }
}
