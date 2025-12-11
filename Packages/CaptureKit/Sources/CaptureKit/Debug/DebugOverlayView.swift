// CaptureKit - 调试视图
//
// 用于验证 OCR 坐标是否准确的"测谎仪"视图。
// 在图片上绘制红框，确认边界框计算正确。
//
// ⚠️ 仅用于开发调试，正式发布时可移除

#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - Debug Overlay View

/// 调试视图：用于验证 OCR 坐标是否准确
///
/// 在图片上绘制红框，验证边界框是否精准套住文字。
/// 自动处理不同坐标系的转换。
///
/// ## 使用示例
///
/// ```swift
/// DebugOverlayView(
///     image: capturedImage,
///     ocrResult: captureResult.ocrResult
/// )
/// ```
@available(iOS 16.0, *)
/// 调试视图：用于验证 OCR 坐标是否准确
public struct DebugOverlayView: View {
    
    // MARK: - Properties
    
    let image: UIImage
    let ocrResult: OCRResult
    let showConfidence: Bool
    let boxColor: Color
    
    // MARK: - Initialization
    
    public init(
        image: UIImage,
        ocrResult: OCRResult,
        showConfidence: Bool = true,
        boxColor: Color = .red
    ) {
        self.image = image
        self.ocrResult = ocrResult
        self.showConfidence = showConfidence
        self.boxColor = boxColor
    }
    
    // MARK: - Body
    
    /// 渲染调试覆盖层，展示图片、边框和调试信息
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // 1. 底图
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        // 2. 绘制边界框
                        Canvas { context, size in
                            drawBoundingBoxes(context: context, size: size)
                        }
                    )
                
                // 3. 调试信息面板
                debugInfoPanel
            }
        }
    }
    
    // MARK: - Drawing
    
    private func drawBoundingBoxes(context: GraphicsContext, size: CGSize) {
        let imageSize = image.size
        let viewSize = size
        
        // 计算缩放比例（Aspect Fit）
        let widthRatio = viewSize.width / imageSize.width
        let heightRatio = viewSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        
        // 计算图片在 Canvas 中的偏移量（居中）
        let imageWidth = imageSize.width * scale
        let imageHeight = imageSize.height * scale
        let xOffset = (viewSize.width - imageWidth) / 2
        let yOffset = (viewSize.height - imageHeight) / 2
        
        // 遍历每一行文字
        for (index, line) in ocrResult.lines.enumerated() {
            // 使用 OCRLine 的坐标转换方法（自动处理不同坐标系）
            let uiKitBox = line.boundingBoxInUIKit(imageSize: imageSize)
            
            // 转换到 View 坐标
            let rect = CGRect(
                x: xOffset + uiKitBox.origin.x * scale,
                y: yOffset + uiKitBox.origin.y * scale,
                width: uiKitBox.width * scale,
                height: uiKitBox.height * scale
            )
            
            // 画边框
            let path = Path(rect)
            context.stroke(path, with: .color(boxColor), lineWidth: 2)
            
            // 画半透明背景
            context.fill(path, with: .color(boxColor.opacity(0.1)))
            
            // 标注序号和坐标系
            let coordLabel = line.coordinateSystem == .visionNormalized ? "V" : "P"
            let text = Text("\(index + 1)\(coordLabel)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            context.draw(
                text,
                at: CGPoint(x: rect.minX + 10, y: rect.minY + 10)
            )
        }
    }
    
    // MARK: - Debug Info Panel
    
    private var debugInfoPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Debug Info")
                .font(.caption.bold())
            
            Text("图片尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                .font(.caption2)
            
            Text("识别行数: \(ocrResult.lines.count)")
                .font(.caption2)
            
            Text("总置信度: \(String(format: "%.1f%%", ocrResult.confidence * 100))")
                .font(.caption2)
            
            if let firstLine = ocrResult.lines.first {
                Text("首行坐标系: \(firstLine.coordinateSystem.rawValue)")
                    .font(.caption2)
                Text("首行框: (\(String(format: "%.2f", firstLine.boundingBox.origin.x)), \(String(format: "%.2f", firstLine.boundingBox.origin.y)))")
                    .font(.caption2)
            }
            
            // 图例
            HStack(spacing: 4) {
                Text("V=Vision归一化")
                Text("P=像素坐标")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(8)
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Debug Overlay - Vision") {
    // 创建测试数据（Vision 归一化坐标）
    let testImage = UIImage(systemName: "doc.text.fill")!
        .withTintColor(.blue)
        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 200))
    
    let testResult = OCRResult(
        text: "测试文字",
        lines: [
            OCRLine(text: "第一行", confidence: 0.95, boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.3, height: 0.1), coordinateSystem: .visionNormalized),
            OCRLine(text: "第二行", confidence: 0.88, boundingBox: CGRect(x: 0.1, y: 0.6, width: 0.5, height: 0.1), coordinateSystem: .visionNormalized),
        ],
        confidence: 0.92
    )
    
    return DebugOverlayView(
        image: testImage,
        ocrResult: testResult
    )
}

@available(iOS 16.0, *)
#Preview("Debug Overlay - Pixel") {
    // 创建测试数据（像素坐标）
    let testImage = UIImage(systemName: "doc.text.fill")!
        .withTintColor(.green)
        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 200))
    
    let testResult = OCRResult(
        text: "测试文字",
        lines: [
            OCRLine(text: "第一行", confidence: 1.0, boundingBox: CGRect(x: 20, y: 20, width: 60, height: 20), coordinateSystem: .pixelTopLeft),
            OCRLine(text: "第二行", confidence: 1.0, boundingBox: CGRect(x: 20, y: 50, width: 100, height: 20), coordinateSystem: .pixelTopLeft),
        ],
        confidence: 1.0
    )
    
    return DebugOverlayView(
        image: testImage,
        ocrResult: testResult,
        boxColor: .green
    )
}

#endif
