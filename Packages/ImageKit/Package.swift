// swift-tools-version: 5.9

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
            dependencies: []
        ),
        .testTarget(
            name: "ImageKitTests",
            dependencies: ["ImageKit"]
        ),
    ]
)
