//
//  AppLogger.swift
//  NotBad
//
//  Created by GitHub Copilot on 9/22/25.
//

import Foundation
import os

/// 结构化日志域
enum LogDomain: String {
    case app
    case coordinator
    case data
    case network
    case viewModel
}

/// 统一日志入口（封装 os.Logger）
/// - 设计目标：
///   - 让调用点只关心 domain 与 level；
///   - 便于后续接入远程日志或隐私分级；
///   - DEBUG 下更啰嗦，RELEASE 下更克制。
enum AppLogger {
    private static func logger(for domain: LogDomain) -> Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "NotBad", category: domain.rawValue)
    }

    static func info(_ domain: LogDomain, _ message: String) {
        #if DEBUG
        logger(for: domain).info("\(message, privacy: .private(mask: .hash))")
        #else
        logger(for: domain).info("\(message)")
        #endif
    }

    static func debug(_ domain: LogDomain, _ message: String) {
        #if DEBUG
        logger(for: domain).debug("\(message, privacy: .private(mask: .hash))")
        #endif
    }

    static func error(_ domain: LogDomain, _ message: String) {
        logger(for: domain).error("\(message)")
    }

    static func fault(_ domain: LogDomain, _ message: String) {
        logger(for: domain).fault("\(message)")
    }

    /// 简易计时器，用于关键路径耗时统计
    struct Timer {
        private let start: DispatchTime
        private let domain: LogDomain
        private let label: String

        init(_ label: String, domain: LogDomain) {
            self.start = .now()
            self.domain = domain
            self.label = label
            AppLogger.debug(domain, "⏱️ Start: \(label)")
        }

        func stop(extra: String? = nil) {
            let end = DispatchTime.now()
            let nano = end.uptimeNanoseconds - start.uptimeNanoseconds
            let ms = Double(nano) / 1_000_000.0
            if let extra { AppLogger.info(domain, "⏱️ End: \(label) = \(String(format: "%.2f", ms)) ms | \(extra)") }
            else { AppLogger.info(domain, "⏱️ End: \(label) = \(String(format: "%.2f", ms)) ms") }
        }
    }
}
