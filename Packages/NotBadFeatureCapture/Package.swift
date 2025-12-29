// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadFeatureCapture",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadFeatureCapture", targets: ["NotBadFeatureCapture"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadService"),
    ],
    targets: [
        .target(
            name: "NotBadFeatureCapture",
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
            name: "NotBadFeatureCaptureTests",
            dependencies: ["NotBadFeatureCapture"]
        ),
    ]
)
