//
//  OCRServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务协议，定义图片文字识别的公开接口。

import CoreGraphics

/// 光学字符识别服务协议
public protocol OCRServiceProtocol: Sendable {
    func recognizeText(from cgImage: CGImage) async throws -> String
}
