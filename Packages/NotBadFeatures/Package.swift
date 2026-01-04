// swift-tools-version: 6.2
//
//  Package.swift
//  NotBadFeatures
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  功能模块包，包含 Dashboard, Review, Library, Settings 等业务模块。
//

import PackageDescription

let package = Package(
    name: "NotBadFeatures",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadFeatures", targets: ["NotBadFeatures"]),
    ],
    dependencies: [
        .package(path: "../NotBadCore"),
        .package(path: "../NotBadUI"),
        .package(path: "../NotBadData"),
    ],
    targets: [
        .target(
            name: "NotBadFeatures",
            dependencies: [
                "NotBadCore",
                "NotBadUI",
                "NotBadData"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
