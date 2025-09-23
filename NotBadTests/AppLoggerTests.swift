//
//  AppLoggerTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class AppLoggerTests: XCTestCase {
    func testLogging_calls_doNotCrash() {
        // Exercise various log levels. No assertions needed; ensure no crash.
        AppLogger.info(.app, "info message")
        AppLogger.error(.data, "error message")
        AppLogger.fault(.network, "fault message")

        #if DEBUG
        AppLogger.debug(.viewModel, "debug message")
        #endif
    }

    func testTimer_recordsDuration_andStops() {
        // Ensure Timer start/stop executes without issues
        let timer = AppLogger.Timer("unit-test-timer", domain: .app)
        // Simulate small work
        usleep(10_000) // 10ms
        timer.stop(extra: "work=ok")
    }

    func testTimer_zeroDuration_stopImmediately() {
        // Stop immediately after start; should not crash and should log ~0ms.
        let timer = AppLogger.Timer("zero-duration", domain: .app)
        timer.stop()
    }

    func testTimer_multipleStop_callsDoNotCrash() {
        // Calling stop() multiple times should just log multiple entries without crashing.
        let timer = AppLogger.Timer("multi-stop", domain: .app)
        usleep(1_000) // 1ms
        timer.stop(extra: "first")
        usleep(1_000) // another 1ms
        timer.stop(extra: "second")
    }

    func testTimer_concurrentTimers_noCrash() {
        // Launch a handful of timers concurrently to ensure no threading issues or crashes.
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "appLogger.timer.tests", attributes: .concurrent)
        let iterations = 16
        for i in 0..<iterations {
            group.enter()
            queue.async {
                let t = AppLogger.Timer("concurrent-\(i)", domain: .app)
                // small, varied delay to simulate work without slowing tests
                usleep(useconds_t(500 + (i % 5) * 200))
                t.stop()
                group.leave()
            }
        }
        // Wait briefly; this should complete well under 1s.
        XCTAssertEqual(group.wait(timeout: .now() + 1.0), .success)
    }
}
