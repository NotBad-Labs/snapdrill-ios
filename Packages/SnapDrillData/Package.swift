// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据持久化层，基于 SwiftData 构建数据模型。
//

import PackageDescription

let package = Package(
    name: "SnapDrillData",
    platforms: [.iOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "SnapDrillData", targets: ["SnapDrillData"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    ],
    targets: [
        .target(
            name: "SnapDrillData",
            dependencies: [
                "SnapDrillCore",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
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
