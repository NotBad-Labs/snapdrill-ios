// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心业务逻辑包，包含 Service, Model, Engine 等。
//

import PackageDescription

let package = Package(
    name: "SnapDrillCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SnapDrillCore", targets: ["SnapDrillCore"]),
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "SnapDrillCore",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk")
            ],
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
