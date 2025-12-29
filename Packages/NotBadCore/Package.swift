// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadCore", targets: ["NotBadCore"]),
    ],
    targets: [
        .target(
            name: "NotBadCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadCoreTests",
            dependencies: ["NotBadCore"]
        ),
    ]
)
