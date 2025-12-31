// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotBadUI",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadUI", targets: ["NotBadUI"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(url: "https://github.com/guoyingtao/Mantis.git", from: "2.23.0"),
    ],
    targets: [
        .target(
            name: "NotBadUI",
            dependencies: [
                "NotBadCore",
                .product(name: "Mantis", package: "Mantis")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadUITests",
            dependencies: ["NotBadUI"]
        ),
    ]
)
