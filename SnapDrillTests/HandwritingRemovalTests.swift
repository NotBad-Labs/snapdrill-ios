import UIKit
import XCTest
@testable import SnapDrill

final class HandwritingRemovalTests: XCTestCase {
    private func renderMixedInkTestImage() -> UIImage {
        let size = CGSize(width: 300, height: 200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Clean paper background
            UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0).setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            // Printed black horizontal bar in top band (y: 35..50)
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 35, width: 200, height: 16))

            // Red grading stroke in middle band (y: 90..105)
            UIColor(red: 0.86, green: 0.14, blue: 0.14, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 90, width: 180, height: 14))

            // Blue ballpoint stroke in lower band (y: 145..160)
            UIColor(red: 0.12, green: 0.30, blue: 0.85, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 145, width: 180, height: 14))
        }
    }

    private func samplePixelRGB(in image: UIImage, x: Int, y: Int) -> (r: Int, g: Int, b: Int) {
        let cg = image.cgImage!
        var pixel = [UInt8](repeating: 0, count: 4)
        let ctx = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )!
        ctx.draw(cg, in: CGRect(x: -x, y: -(cg.height - 1 - y), width: cg.width, height: cg.height))
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }

    func testHeuristicInkRemoverStripsRedAndBlueWhilePreservingPrintedBlack() async throws {
        let source = renderMixedInkTestImage()
        let sourceData = try XCTUnwrap(source.jpegData(compressionQuality: 0.95))

        let remover = HeuristicInkRemover()
        let (cleanedData, succeeded) = await remover.removeInk(from: sourceData, mode: .autoAll)
        XCTAssertTrue(succeeded)

        let cleanedImage = try XCTUnwrap(UIImage(data: cleanedData))

        // Printed black bar at (80, 42) must stay dark
        let blackSample = samplePixelRGB(in: cleanedImage, x: 80, y: 42)
        XCTAssertLessThan(blackSample.r, 65)
        XCTAssertLessThan(blackSample.g, 65)
        XCTAssertLessThan(blackSample.b, 65)

        // Red grading bar at (80, 96) must be erased back to bright neutral paper
        let redSpot = samplePixelRGB(in: cleanedImage, x: 80, y: 96)
        XCTAssertGreaterThan(redSpot.g, 210)
        XCTAssertLessThan(abs(redSpot.r - redSpot.g), 20)

        // Blue pen bar at (80, 152) must be erased back to bright neutral paper
        let blueSpot = samplePixelRGB(in: cleanedImage, x: 80, y: 152)
        XCTAssertGreaterThan(blueSpot.r, 210)
        XCTAssertLessThan(abs(blueSpot.b - blueSpot.r), 20)
    }

    func testInvalidImageDataFallsBackSafelyWithoutThrowing() async {
        let remover = HeuristicInkRemover()
        let garbage = Data([0x01, 0x02, 0x03, 0xFF])
        let (output, succeeded) = await remover.removeInk(from: garbage, mode: .autoAll)
        XCTAssertFalse(succeeded)
        XCTAssertEqual(output, garbage)

        let (offOut, offSucceeded) = await remover.removeInk(from: garbage, mode: .off)
        XCTAssertTrue(offSucceeded)
        XCTAssertEqual(offOut, garbage)
    }
}
