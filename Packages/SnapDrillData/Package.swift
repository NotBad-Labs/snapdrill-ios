// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  数据持久化层，基于 SwiftData 构建数据模型。
//

import PackageDescription

let package = Package(
    name: "SnapDrillData",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SnapDrillData", targets: ["SnapDrillData"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
    ],
    targets: [
        .target(
            name: "SnapDrillData",
            dependencies: ["SnapDrillCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SnapDrillDataTests",
            dependencies: ["SnapDrillData"]
        ),
    ]
)
