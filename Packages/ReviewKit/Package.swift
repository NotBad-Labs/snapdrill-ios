// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReviewKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ReviewKit",
            targets: ["ReviewKit"]
        ),
        // CLI 工具 - 用于验证核心逻辑的纯粹性
        .executable(
            name: "ReviewKitCLI",
            targets: ["ReviewKitCLI"]
        ),
    ],
    targets: [
        .target(
            name: "ReviewKitCore",
            dependencies: [],
            path: "Sources/ReviewKitCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ReviewKitModels",
            dependencies: ["ReviewKitCore"],
            path: "Sources/ReviewKitModels",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ReviewKitPersistence",
            dependencies: ["ReviewKitModels", "ReviewKitCore"],
            path: "Sources/ReviewKitPersistence",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ReviewKit",
            dependencies: ["ReviewKitCore", "ReviewKitModels", "ReviewKitPersistence"],
            path: "Sources/ReviewKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "ReviewKitCLI",
            dependencies: ["ReviewKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ReviewKitTests",
            dependencies: ["ReviewKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
