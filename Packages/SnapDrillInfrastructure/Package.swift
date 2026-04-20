// swift-tools-version: 6.3
//
//  Package.swift
//  SnapDrillInfrastructure
//
//  Created by NotBad Labs on 2026/03/04.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Firebase 基础设施层：持有 Firebase SDK 依赖，保持 SnapDrillCore 零依赖。
//

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "SnapDrillInfrastructure",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SnapDrillInfrastructure", targets: ["SnapDrillInfrastructure"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(path: "../SnapDrillCore")
    ],
    targets: [
        .target(
            name: "SnapDrillInfrastructure",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "SnapDrillCore", package: "SnapDrillCore")
            ],
            swiftSettings: sharedSwiftSettings
        )
    ]
)
