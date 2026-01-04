// swift-tools-version: 6.2
//
//  Package.swift
//  NotBadUI
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  通用 UI 组件库，包含设计系统和基础控件。
//

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
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "NotBadUITests",
            dependencies: ["NotBadUI"]
        ),
    ]
)
