// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  功能模块包，按功能域拆为 5 个独立 target，编译器强制约束跨域类型访问。
//

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "SnapDrillFeatures",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SnapDrillFeatureCapture",   targets: ["SnapDrillFeatureCapture"]),
        .library(name: "SnapDrillFeatureLibrary",   targets: ["SnapDrillFeatureLibrary"]),
        .library(name: "SnapDrillFeatureReview",    targets: ["SnapDrillFeatureReview"]),
        .library(name: "SnapDrillFeatureDashboard", targets: ["SnapDrillFeatureDashboard"]),
        .library(name: "SnapDrillFeatureSettings",  targets: ["SnapDrillFeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
        .package(path: "../SnapDrillUI"),
        .package(path: "../SnapDrillData"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "SnapDrillFeatureCapture",
            dependencies: ["SnapDrillCore", "SnapDrillUI", "SnapDrillData"],
            swiftSettings: sharedSwiftSettings
        ),
        .target(
            name: "SnapDrillFeatureLibrary",
            dependencies: [
                "SnapDrillCore", "SnapDrillUI", "SnapDrillData",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            swiftSettings: sharedSwiftSettings
        ),
        // SnapDrillFeatureReview 依赖 SnapDrillFeatureLibrary：
        // ReviewCardContent 内嵌 LibraryEditView（复习时编辑卡片内容）。
        .target(
            name: "SnapDrillFeatureReview",
            dependencies: ["SnapDrillCore", "SnapDrillUI", "SnapDrillData",
                           "SnapDrillFeatureLibrary"],
            swiftSettings: sharedSwiftSettings
        ),
        // SnapDrillFeatureDashboard 依赖 SnapDrillFeatureLibrary：
        // DashboardView 使用 SubjectManagerView（分类管理，迁入 Library 后引用）。
        .target(
            name: "SnapDrillFeatureDashboard",
            dependencies: ["SnapDrillCore", "SnapDrillUI", "SnapDrillData",
                           "SnapDrillFeatureLibrary"],
            swiftSettings: sharedSwiftSettings
        ),
        // SnapDrillFeatureSettings 依赖 SnapDrillFeatureLibrary：
        // SettingsView 包含 SubjectManagerView / SourceManagerView / GradeManagerView（分类管理，语义归 Library）。
        .target(
            name: "SnapDrillFeatureSettings",
            dependencies: ["SnapDrillCore", "SnapDrillUI", "SnapDrillData",
                           "SnapDrillFeatureLibrary"],
            swiftSettings: sharedSwiftSettings
        ),
        .testTarget(
            name: "SnapDrillFeaturesTests",
            dependencies: [
                "SnapDrillFeatureCapture",
                "SnapDrillFeatureLibrary",
                "SnapDrillFeatureReview",
                "SnapDrillFeatureDashboard",
                "SnapDrillFeatureSettings",
                "SnapDrillCore",
                "SnapDrillData",
                "SnapDrillUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: sharedSwiftSettings
        ),
    ]
)
