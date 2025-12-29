// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadUI", targets: ["NotBadUI"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
    ],
    targets: [
        .target(
            name: "NotBadUI",
            dependencies: ["NotBadCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadUITests",
            dependencies: ["NotBadUI"]
        ),
    ]
)
