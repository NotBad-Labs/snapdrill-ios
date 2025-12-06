// swift-tools-version: 5.9
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
            name: "ReviewKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency") // Swift 6 预备
            ]
        ),
        .executableTarget(
            name: "ReviewKitCLI",
            dependencies: ["ReviewKit"]
        ),
        .testTarget(
            name: "ReviewKitTests",
            dependencies: ["ReviewKit"]
        ),
    ]
)
