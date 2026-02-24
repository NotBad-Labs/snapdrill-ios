// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  功能模块包，包含 Dashboard, Review, Library, Settings 等业务模块。
//

import PackageDescription

let package = Package(
    name: "SnapDrillFeatures",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SnapDrillFeatures", targets: ["SnapDrillFeatures"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
        .package(path: "../SnapDrillUI"),
        .package(path: "../SnapDrillData"),
    ],
    targets: [
        .target(
            name: "SnapDrillFeatures",
            dependencies: [
                "SnapDrillCore",
                "SnapDrillUI",
                "SnapDrillData"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SnapDrillFeaturesTests",
            dependencies: ["SnapDrillFeatures"]
        )
    ]
)
