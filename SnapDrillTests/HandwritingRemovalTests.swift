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

    func testJPEGBlackTextAntiAliasedFringeWithoutCoreMLDegradesHonestlyWithSucceededFalse() async throws {
        let size = CGSize(width: 600, height: 320)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                .foregroundColor: UIColor(white: 0.06, alpha: 1.0)
            ]
            NSString(string: "1. Solve 2x + 3 = 11 for real x.").draw(at: CGPoint(x: 32, y: 48), withAttributes: attrs)
            NSString(string: "2. Factor f(x) = x^2 - 4x + 3.").draw(at: CGPoint(x: 32, y: 120), withAttributes: attrs)
            NSString(string: "Student answer: x = 4, roots 1 and 3").draw(at: CGPoint(x: 32, y: 192), withAttributes: attrs)
        }
        let jpegData = try XCTUnwrap(image.jpegData(compressionQuality: 0.85))
        let remover = CoreMLCapableInkRemover()
        let (_, succeeded) = await remover.removeInk(from: jpegData, mode: .autoAll)
        XCTAssertFalse(succeeded)
    }

    func testFaintPencilStrokeIsCleanedInAutoAllMode() async throws {
        let size = CGSize(width: 320, height: 200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            // Faint graphite pencil band (luma ~215, relDark ~28)
            UIColor(red: 0.84, green: 0.83, blue: 0.82, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 40, y: 80, width: 220, height: 14))
        }
        let jpegData = try XCTUnwrap(image.jpegData(compressionQuality: 0.92))
        let remover = CoreMLCapableInkRemover()
        let (cleanedData, succeeded) = await remover.removeInk(from: jpegData, mode: .autoAll)
        XCTAssertTrue(succeeded)
        let cleanedImg = try XCTUnwrap(UIImage(data: cleanedData))
        let spot = samplePixelRGB(in: cleanedImg, x: 120, y: 87)
        XCTAssertGreaterThan(spot.r, 232)
    }

    func testEraserOverThirtyStrokesPreservesEarlierStrokes() throws {
        let size = CGSize(width: 240, height: 240)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let base = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            // Dark stroke at top (y = 24) to be erased by stroke #1
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 40, y: 20, width: 160, height: 12))
        }

        var undoStrokes: [EraserStroke] = []
        var redoStrokes: [EraserStroke] = []
        var bakedStrokes: [EraserStroke] = []

        // Stroke #1 erases the black bar at normalized y = 0.11
        let stroke1 = EraserStroke(
            mode: .erase,
            normalizedPoints: [CGPoint(x: 0.2, y: 0.11), CGPoint(x: 0.8, y: 0.11)],
            normalizedRadiusX: 0.05,
            paperColor: EraserStroke.PaperRGB(r: 1.0, g: 1.0, b: 1.0)
        )
        EraserStrokeEngine.pushStroke(stroke1, into: &undoStrokes, redoStack: &redoStrokes, bakedStrokes: &bakedStrokes)

        // Add 35 more strokes elsewhere so undoStrokes exceeds maxUndoDepth (30)
        for i in 0..<35 {
            let yNorm = 0.45 + CGFloat(i % 10) * 0.04
            let extra = EraserStroke(
                mode: .erase,
                normalizedPoints: [CGPoint(x: 0.2, y: yNorm), CGPoint(x: 0.5, y: yNorm)],
                normalizedRadiusX: 0.02,
                paperColor: EraserStroke.PaperRGB(r: 1.0, g: 1.0, b: 1.0)
            )
            EraserStrokeEngine.pushStroke(extra, into: &undoStrokes, redoStack: &redoStrokes, bakedStrokes: &bakedStrokes)
        }

        XCTAssertEqual(undoStrokes.count, EraserStrokeEngine.maxUndoDepth)
        XCTAssertEqual(bakedStrokes.count, 6)

        let composited = EraserStrokeEngine.composite(
            baseImage: base,
            originalReference: base,
            strokes: bakedStrokes + undoStrokes
        )
        let erasedPixel = samplePixelRGB(in: composited, x: 120, y: 26)
        XCTAssertGreaterThan(erasedPixel.r, 240)
        XCTAssertGreaterThan(erasedPixel.g, 240)
        XCTAssertGreaterThan(erasedPixel.b, 240)
    }
}
