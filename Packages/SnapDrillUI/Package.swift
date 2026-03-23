// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通用 UI 组件库，包含设计系统和基础控件。
//

import PackageDescription

let package = Package(
    name: "SnapDrillUI",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SnapDrillUI", targets: ["SnapDrillUI"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
        .package(url: "https://github.com/guoyingtao/Mantis.git", from: "2.23.0"),
    ],
    targets: [
        .target(
            name: "SnapDrillUI",
            dependencies: [
                "SnapDrillCore",
                .product(name: "Mantis", package: "Mantis")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SnapDrillUITests",
            dependencies: ["SnapDrillUI"]
        ),
    ]
)
