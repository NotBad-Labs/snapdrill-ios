// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadFeatureReview",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadFeatureReview", targets: ["NotBadFeatureReview"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadEngine"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadData"),
    ],
    targets: [
        .target(
            name: "NotBadFeatureReview",
            dependencies: [
                "NotBadCore",
                "NotBadEngine",
                "NotBadUI",
                "NotBadData"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadFeatureReviewTests",
            dependencies: ["NotBadFeatureReview"]
        ),
    ]
)
