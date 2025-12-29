// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadData",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadData", targets: ["NotBadData"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
    ],
    targets: [
        .target(
            name: "NotBadData",
            dependencies: ["NotBadCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadDataTests",
            dependencies: ["NotBadData"]
        ),
    ]
)
