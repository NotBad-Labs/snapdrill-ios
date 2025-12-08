// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OCRKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OCRKit",
            targets: ["OCRKit"]
        ),
    ],
    targets: [
        .target(
            name: "OCRKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OCRKitTests",
            dependencies: ["OCRKit"]
        ),
    ]
)
