// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProcessKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ProcessKit",
            targets: ["ProcessKit"]
        )
    ],
    targets: [
        .target(
            name: "ProcessKit",
            dependencies: [],
            resources: [
                .process("Resources")  // Core ML 模型存放位置
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "ProcessKitTests",
            dependencies: ["ProcessKit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny")
            ]
        )
    ]
)
