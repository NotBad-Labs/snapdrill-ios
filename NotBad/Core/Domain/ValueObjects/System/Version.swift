//
//  Version.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 SystemDomainError (或其他通用领域错误)

/// 系统领域错误 (仅为编译目的包含，实际应从 SystemDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/SystemDomainError.swift
enum SystemDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidVersionFormat(String) // 无效的版本号格式

    var description: String {
        switch self {
        case .invalidVersionFormat(let versionString):
            return "版本号格式 '\(versionString)' 无效，应为 'X.Y.Z' 或 'X.Y.Z (Build)' 形式。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 版本号值对象
/// 封装了应用程序或模块的版本信息，通常遵循语义化版本控制（Semantic Versioning）规范。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保版本号的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct Version: Codable, Sendable, Hashable {
    let major: Int // 主版本号
    let minor: Int // 次版本号
    let patch: Int // 修订版本号
    let build: Int? // 构建版本号，可选

    /// 初始化 Version
    /// - Parameters:
    ///   - major: 主版本号
    ///   - minor: 次版本号，默认为 0
    ///   - patch: 修订版本号，默认为 0
    ///   - build: 构建版本号，可选，默认为 nil
    /// - Throws: SystemDomainError 如果任何版本号为负数
    init(major: Int, minor: Int = 0, patch: Int = 0, build: Int? = nil) throws {
        guard major >= 0 && minor >= 0 && patch >= 0 else {
            throw SystemDomainError.invalidVersionFormat("版本号（主、次、修订）不能为负数。")
        }
        if let build = build, build < 0 {
            throw SystemDomainError.invalidVersionFormat("构建版本号不能为负数。")
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.build = build
    }

    /// 从字符串初始化 Version (例如 "1.0.0", "1.2.3", "1.2.3 (456)")
    /// - Parameter versionString: 版本号字符串
    /// - Throws: SystemDomainError 如果字符串格式无效
    init(fromString versionString: String) throws {
        let components = versionString.split(separator: " ").map { String($0) }
        let versionParts = components[0].split(separator: ".").compactMap { Int($0) }

        guard versionParts.count >= 1 else {
            throw SystemDomainError.invalidVersionFormat(versionString)
        }

        let major = versionParts[0]
        let minor = versionParts.count > 1 ? versionParts[1] : 0
        let patch = versionParts.count > 2 ? versionParts[2] : 0
        var build: Int? = nil

        if components.count > 1 {
            // 尝试解析构建号，例如 "(456)"
            let buildString = components[1]
            if buildString.hasPrefix("(") && buildString.hasSuffix(")") {
                let strippedBuild = String(buildString.dropFirst().dropLast())
                build = Int(strippedBuild)
            }
        }

        try self.init(major: major, minor: minor, patch: patch, build: build)
    }

    /// 获取版本号的字符串表示 (例如 "1.0.0", "1.2.3 (456)")
    var stringValue: String {
        var version = "\(major).\(minor).\(patch)"
        if let build = build {
            version += " (\(build))"
        }
        return version
    }

    /// 获取不包含构建号的版本字符串 (例如 "1.2.3")
    var semanticVersion: String {
        "\(major).\(minor).\(patch)"
    }

    /// 获取当前应用的版本号
    /// - Returns: 当前应用的版本号值对象，如果无法获取则返回 nil
    static func currentAppVersion() -> Version? {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
              let buildNumber = Int(buildString) else {
            return nil
        }
        return try? Version(fromString: "\(versionString) (\(buildNumber))")
    }

    /// 判断当前版本是否低于另一个版本
    /// - Parameter other: 另一个版本
    /// - Returns: true 如果当前版本低于另一个版本
    func isLower(than other: Version) -> Bool {
        if self.major != other.major {
            return self.major < other.major
        }
        if self.minor != other.minor {
            return self.minor < other.minor
        }
        if self.patch != other.patch {
            return self.patch < other.patch
        }
        // 如果语义版本相同，比较构建号
        if let selfBuild = self.build, let otherBuild = other.build {
            return selfBuild < otherBuild
        } else if self.build == nil && other.build != nil {
            return true // 没有构建号的版本被认为低于有构建号的版本
        }
        return false
    }

    /// 判断当前版本是否高于另一个版本
    /// - Parameter other: 另一个版本
    /// - Returns: true 如果当前版本高于另一个版本
    func isHigher(than other: Version) -> Bool {
        if self.major != other.major {
            return self.major > other.major
        }
        if self.minor != other.minor {
            return self.minor > other.minor
        }
        if self.patch != other.patch {
            return self.patch > other.patch
        }
        // 如果语义版本相同，比较构建号
        if let selfBuild = self.build, let otherBuild = other.build {
            return selfBuild > otherBuild
        } else if self.build != nil && other.build == nil {
            return true // 有构建号的版本被认为高于没有构建号的版本
        }
        return false
    }
}

// MARK: - Comparable (使版本号可比较大小)
extension Version: Comparable {
    static func < (lhs: Version, rhs: Version) -> Bool {
        return lhs.isLower(than: rhs)
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Version: CustomStringConvertible {
    var description: String {
        stringValue
    }
}

// MARK: - Sample Data for Testing
extension Version {
    static func sampleV1_0_0() -> Version {
        return try! Version(major: 1, minor: 0, patch: 0)
    }

    static func sampleV1_2_3() -> Version {
        return try! Version(major: 1, minor: 2, patch: 3)
    }

    static func sampleV1_2_3_build456() -> Version {
        return try! Version(major: 1, minor: 2, patch: 3, build: 456)
    }

    static func sampleV2_0_0() -> Version {
        return try! Version(major: 2, minor: 0, patch: 0)
    }

    static func invalidSample() -> Version {
        return try! Version(major: -1) // 这是一个无效的版本，用于测试错误处理
    }
}

