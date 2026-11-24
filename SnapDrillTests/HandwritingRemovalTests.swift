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

            // Printed dark horizontal bar in top band (RGB ~30, 30, 32)
            UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 35, width: 200, height: 16))

            // Red grading stroke in middle band
            UIColor(red: 0.86, green: 0.14, blue: 0.14, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 90, width: 180, height: 14))

            // Blue ballpoint stroke in lower band
            UIColor(red: 0.12, green: 0.30, blue: 0.85, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 30, y: 145, width: 180, height: 14))
        }
    }

    private func renderPureBlackInkOnlyImage() -> UIImage {
        let size = CGSize(width: 240, height: 160)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0).setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 24, y: 50, width: 180, height: 18))
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

    func testHeuristicInkRemoverStripsRedAndBlueWithoutArtificiallyDarkeningBlack() async throws {
        let source = renderMixedInkTestImage()
        let beforeBlack = samplePixelRGB(in: source, x: 80, y: 42)
        let sourceData = try XCTUnwrap(source.jpegData(compressionQuality: 0.95))

        let remover = CoreMLCapableInkRemover()
        let (cleanedData, succeeded) = await remover.removeInk(from: sourceData, mode: .autoAll)
        XCTAssertTrue(succeeded)

        let cleanedImage = try XCTUnwrap(UIImage(data: cleanedData))

        // Printed black stays dark and must NOT be artificially multiplied by 0.85
        let afterBlack = samplePixelRGB(in: cleanedImage, x: 80, y: 42)
        XCTAssertLessThan(afterBlack.r, 65)
        XCTAssertGreaterThanOrEqual(afterBlack.r, beforeBlack.r - 6)

        // Red & blue strokes erased smoothly to paper tone
        let redSpot = samplePixelRGB(in: cleanedImage, x: 80, y: 96)
        XCTAssertGreaterThan(redSpot.g, 210)
        XCTAssertLessThan(abs(redSpot.r - redSpot.g), 20)

        let blueSpot = samplePixelRGB(in: cleanedImage, x: 80, y: 152)
        XCTAssertGreaterThan(blueSpot.r, 210)
        XCTAssertLessThan(abs(blueSpot.b - blueSpot.r), 20)
    }

    func testPureBlackInkWithoutCoreMLModelDegradesHonestlyWithSucceededFalse() async throws {
        let blackOnlyData = try XCTUnwrap(renderPureBlackInkOnlyImage().jpegData(compressionQuality: 0.92))
        let remover = CoreMLCapableInkRemover()
        let (_, succeeded) = await remover.removeInk(from: blackOnlyData, mode: .autoAll)
        XCTAssertFalse(succeeded)
    }

    func testShadowGradientEnhancementLiftsUnevenLightingWithoutSeams() async throws {
        let size = CGSize(width: 320, height: 220)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let shadowed = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            // Simulate heavy shadow on left half (luma ~115) vs bright paper on right half (luma ~242)
            for x in 0..<Int(size.width) {
                let t = CGFloat(x) / size.width
                let val = 0.45 + 0.50 * t
                UIColor(red: val, green: val * 0.98, blue: val * 0.95, alpha: 1.0).setFill()
                cg.fill(CGRect(x: x, y: 0, width: 1, height: Int(size.height)))
            }
            // Blue pen inside the shadow region
            UIColor(red: 0.10, green: 0.28, blue: 0.78, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 40, y: 90, width: 80, height: 14))
        }

        let enhancer = ImageEnhancementService()
        let rawData = try XCTUnwrap(shadowed.jpegData(compressionQuality: 0.92))
        let enhancedData = enhancer.apply(.enhanced, to: rawData)
        let enhancedImg = try XCTUnwrap(UIImage(data: enhancedData))

        let leftPaperBefore = samplePixelRGB(in: shadowed, x: 30, y: 40)
        let leftPaperAfter = samplePixelRGB(in: enhancedImg, x: 30, y: 40)
        XCTAssertGreaterThan(leftPaperAfter.r, leftPaperBefore.r + 35)

        let remover = CoreMLCapableInkRemover()
        let (cleanedData, succeeded) = await remover.removeInk(from: enhancedData, mode: .autoAll)
        XCTAssertTrue(succeeded)
        let cleanedImg = try XCTUnwrap(UIImage(data: cleanedData))
        let spotAfter = samplePixelRGB(in: cleanedImg, x: 70, y: 96)
        XCTAssertGreaterThan(spotAfter.r, 145)
    }

    func testTimeoutDegradesPromptlyWithSucceededFalse() async throws {
        // Large high-res canvas under impossible timeout triggers timeout cancellation safely
        let big = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 2000)).image { ctx in
            UIColor(red: 0.95, green: 0.95, blue: 0.93, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2000, height: 2000))
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 100, y: 100, width: 1200, height: 40))
        }.jpegData(compressionQuality: 0.85)!

        let remover = HeuristicInkRemover(timeoutSeconds: 0.0001)
        let (output, succeeded) = await remover.removeInk(from: big, mode: .autoAll)
        XCTAssertFalse(succeeded)
        XCTAssertEqual(output, big)
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
