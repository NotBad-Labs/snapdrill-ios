// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadFeatureLibrary",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadFeatureLibrary", targets: ["NotBadFeatureLibrary"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadData"),
    ],
    targets: [
        .target(
            name: "NotBadFeatureLibrary",
            dependencies: [
                "NotBadCore",
                "NotBadUI",
                "NotBadData"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadFeatureLibraryTests",
            dependencies: ["NotBadFeatureLibrary"]
        ),
    ]
)
