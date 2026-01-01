// swift-tools-version: 6.2
//
//  Package.swift
//  NotBadCore
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  核心业务逻辑包，包含 Service, Model, Engine 等。
//

import PackageDescription

let package = Package(
    name: "NotBadCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "NotBadCore", targets: ["NotBadCore"]),
    ],
    targets: [
        .target(
            name: "NotBadCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "NotBadCoreTests",
            dependencies: ["NotBadCore"]
        )
    ]
)
