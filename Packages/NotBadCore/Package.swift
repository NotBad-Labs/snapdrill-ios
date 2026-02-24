// swift-tools-version: 6.2
//
//  Package.swift
//  NotBadCore
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
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
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "NotBadCoreTests",
            dependencies: ["NotBadCore"]
        )
    ]
)
