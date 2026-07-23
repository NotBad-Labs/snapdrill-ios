// swift-tools-version: 6.3
//
//  Package.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  核心业务逻辑包，包含 Service, Model, Engine 等。
//

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "SnapDrillCore",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SnapDrillCore", targets: ["SnapDrillCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SnapDrillCore",
            dependencies: [],
            swiftSettings: sharedSwiftSettings
        ),
        .testTarget(
            name: "SnapDrillCoreTests",
            dependencies: ["SnapDrillCore"],
            resources: [.copy("Fixtures/CanonicalJPEG")],
            swiftSettings: sharedSwiftSettings
        )
    ]
)
