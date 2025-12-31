// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotBadFeatures",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadFeatures", targets: ["NotBadFeatures"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadData"),
    ],
    targets: [
        .target(
            name: "NotBadFeatures",
            dependencies: [
                "NotBadCore",
                "NotBadUI",
                "NotBadData"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
