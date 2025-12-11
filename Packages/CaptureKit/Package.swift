// swift-tools-version: 6.2
// CaptureKit - 录入能力层
//
// 合并自 ImageKit + OCRKit，提供完整的录入链路：
// - 图片存储与管理
// - OCR 文字识别
// - 统一的录入服务入口

import PackageDescription

let package = Package(
    name: "CaptureKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CaptureKit",
            targets: ["CaptureKit"]
        )
    ],
    targets: [
        .target(
            name: "CaptureKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "CaptureKitTests",
            dependencies: ["CaptureKit"]
        )
    ]
)
