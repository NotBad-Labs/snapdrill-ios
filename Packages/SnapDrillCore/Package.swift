// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  核心业务逻辑包，包含 Service, Model, Engine 等。
//

import PackageDescription

let package = Package(
    name: "SnapDrillCore",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "SnapDrillCore", targets: ["SnapDrillCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SnapDrillCore",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SnapDrillCoreTests",
            dependencies: ["SnapDrillCore"]
        )
    ]
)
