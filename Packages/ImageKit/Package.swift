// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ImageKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ImageKit",
            targets: ["ImageKit"]
        ),
    ],
    targets: [
        .target(
            name: "ImageKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ImageKitTests",
            dependencies: ["ImageKit"]
        ),
    ]
)
