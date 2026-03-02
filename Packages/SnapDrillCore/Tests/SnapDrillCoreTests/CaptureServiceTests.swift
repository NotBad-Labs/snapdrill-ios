//
//  CaptureServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureService 单元测试，依赖 UIKit 渲染测试图片，仅在 iOS 环境下运行。
//

#if canImport(UIKit)
import XCTest
@testable import SnapDrillCore

final class CaptureServiceTests: XCTestCase {

    var sut: CaptureService!

    override func setUp() {
        super.setUp()
        sut = CaptureService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testShared_ShouldReturnSameInstance() {
        let instance1 = CaptureService.shared
        let instance2 = CaptureService.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same singleton instance")
    }

    // MARK: - Image Processing Tests

    func testProcessImage_WithValidImage_ShouldNotReturnNil() {
        let testImage = createTestImage()
        let result = sut.processImage(testImage)
        XCTAssertNotNil(result, "Should process valid image")
    }

    func testProcessImage_ShouldMaintainImageQuality() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let result = sut.processImage(testImage)
        XCTAssertNotNil(result)
        if let processedImage = result {
            XCTAssertGreaterThan(processedImage.size.width, 0)
            XCTAssertGreaterThan(processedImage.size.height, 0)
        }
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif
