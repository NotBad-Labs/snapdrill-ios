// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadService",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadService", targets: ["NotBadService"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
    ],
    targets: [
        .target(
            name: "NotBadService",
            dependencies: ["NotBadCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadServiceTests",
            dependencies: ["NotBadService"]
        ),
    ]
)
