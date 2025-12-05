//
//  Logger+Extensions.swift
//  NotBad
//
//  统一日志记录
//

import OSLog

// MARK: - Logger Extensions

extension Logger {
    
    /// 日志子系统
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.notbad.app"
    
    // MARK: - Categories
    
    /// 应用生命周期日志
    static let app = Logger(subsystem: subsystem, category: "App")
    
    /// 数据操作日志
    static let data = Logger(subsystem: subsystem, category: "Data")
    
    /// UI 交互日志
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// 网络请求日志
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    /// 相机/扫描日志
    static let camera = Logger(subsystem: subsystem, category: "Camera")
    
    /// OCR 识别日志
    static let ocr = Logger(subsystem: subsystem, category: "OCR")
    
    /// 导出功能日志
    static let export = Logger(subsystem: subsystem, category: "Export")
    
    /// Widget 日志
    static let widget = Logger(subsystem: subsystem, category: "Widget")
    
    /// iCloud 同步日志
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    
    /// AI 分析日志
    static let ai = Logger(subsystem: subsystem, category: "AI")
    
    /// Spotlight 搜索日志
    static let search = Logger(subsystem: subsystem, category: "Search")
    
    /// 性能监控日志
    static let performance = Logger(subsystem: subsystem, category: "Performance")
}

// MARK: - Convenience Methods

extension Logger {
    
    /// 记录操作开始
    func operationStarted(_ operation: String) {
        self.info("▶️ \(operation, privacy: .public) started")
    }
    
    /// 记录操作完成
    func operationCompleted(_ operation: String, duration: TimeInterval? = nil) {
        if let duration = duration {
            self.info("✅ \(operation, privacy: .public) completed in \(String(format: "%.2f", duration))s")
        } else {
            self.info("✅ \(operation, privacy: .public) completed")
        }
    }
    
    /// 记录操作失败
    func operationFailed(_ operation: String, error: Error) {
        self.error("❌ \(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
    
    /// 记录用户操作
    func userAction(_ action: String) {
        self.info("👆 User: \(action, privacy: .public)")
    }
    
    /// 记录数据变更
    func dataChanged(_ description: String, count: Int? = nil) {
        if let count = count {
            self.info("📊 Data: \(description, privacy: .public) (count: \(count))")
        } else {
            self.info("📊 Data: \(description, privacy: .public)")
        }
    }
}
