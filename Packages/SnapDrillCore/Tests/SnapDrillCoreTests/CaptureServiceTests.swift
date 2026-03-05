//
//  CaptureServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureService 单元测试。
//  注意：CaptureService 当前为空壳 actor（TODO: UI Integration Pending），
//  图像处理 API 尚未实现，测试将在 API 落地后补齐。
//

import XCTest
@testable import SnapDrillCore

final class CaptureServiceTests: XCTestCase {

    // MARK: - 初始化测试

    func testCaptureServiceCanBeInstantiated() {
        let service = CaptureService()
        _ = service
        // CaptureService 是 actor，能正常初始化即通过
        // TODO: 当 processImage / OCR 等 API 实现后，在此补充功能测试
    }
}
