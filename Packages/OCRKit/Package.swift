// swift-tools-version: 5.9

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
            dependencies: []
        ),
        .testTarget(
            name: "OCRKitTests",
            dependencies: ["OCRKit"]
        ),
    ]
)
