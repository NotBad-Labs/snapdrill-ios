// swift-tools-version: 6.2
//
//  Package.swift
//  NotBadData
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  数据持久化层，基于 SwiftData 构建数据模型。
//

import PackageDescription

let package = Package(
    name: "NotBadData",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadData", targets: ["NotBadData"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
    ],
    targets: [
        .target(
            name: "NotBadData",
            dependencies: ["NotBadCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "NotBadDataTests",
            dependencies: ["NotBadData"]
        ),
    ]
)
