// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadFeatureSettings",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadFeatureSettings", targets: ["NotBadFeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadService"),
    ],
    targets: [
        .target(
            name: "NotBadFeatureSettings",
            dependencies: [
                "NotBadCore",
                "NotBadUI",
                "NotBadService"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadFeatureSettingsTests",
            dependencies: ["NotBadFeatureSettings"]
        ),
    ]
)
