// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadEngine",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadEngine", targets: ["NotBadEngine"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
    ],
    targets: [
        .target(
            name: "NotBadEngine",
            dependencies: ["NotBadCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadEngineTests",
            dependencies: ["NotBadEngine"]
        ),
    ]
)
