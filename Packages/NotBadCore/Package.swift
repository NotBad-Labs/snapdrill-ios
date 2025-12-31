// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotBadCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadCore", targets: ["NotBadCore"]),
    ],
    targets: [
        .target(
            name: "NotBadCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadCoreTests",
            dependencies: ["NotBadCore"]
        )
    ]
)
