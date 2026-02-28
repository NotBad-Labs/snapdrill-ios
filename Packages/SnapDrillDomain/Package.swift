// swift-tools-version: 6.2
//
//  Package.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "SnapDrillDomain",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "SnapDrillDomain", targets: ["SnapDrillDomain"]),
    ],
    dependencies: [
        .package(path: "../SnapDrillCore"),
    ],
    targets: [
        .target(
            name: "SnapDrillDomain",
            dependencies: [
                "SnapDrillCore"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SnapDrillDomainTests",
            dependencies: ["SnapDrillDomain"]
        ),
    ]
)
