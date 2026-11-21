import SwiftUI
import UIKit

/// Manual touch-up eraser and restore brush allowing pixel-accurate cleanup of residual ink
/// or recovery of erased diagram details (PRD F-12).
struct HandwritingEraserView: View {
    let initialImage: UIImage
    let originalReferenceImage: UIImage
    let onSave: (UIImage) -> Void

    private enum ToolMode: String, CaseIterable, Identifiable {
        case erase
        case restore

        var id: String { rawValue }

        var title: String {
            switch self {
            case .erase: return String(localized: "Erase Ink")
            case .restore: return String(localized: "Restore Original")
            }
        }

        var symbolName: String {
            switch self {
            case .erase: return "eraser.fill"
            case .restore: return "arrow.uturn.left.circle.fill"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var currentImage: UIImage
    @State private var undoStack: [UIImage] = []
    @State private var redoStack: [UIImage] = []
    @State private var toolMode: ToolMode = .erase
    @State private var brushRadiusPoints: CGFloat = 16
    @State private var isPeekingOriginal: Bool = false
    @State private var activePoints: [CGPoint] = []
    @State private var paperToneColor: UIColor = UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0)

    init(initialImage: UIImage, originalReferenceImage: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.initialImage = initialImage
        self.originalReferenceImage = originalReferenceImage
        self.onSave = onSave
        _currentImage = State(initialValue: initialImage)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Canvas workspace
                GeometryReader { geo in
                    let imageFrame = AspectFitCalculator.fittedRect(
                        imageSize: currentImage.size,
                        in: geo.size
                    )

                    ZStack {
                        Image(uiImage: isPeekingOriginal ? originalReferenceImage : currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        // Live stroke preview while dragging
                        if !activePoints.isEmpty && !isPeekingOriginal {
                            Path { path in
                                guard let first = activePoints.first else { return }
                                path.move(to: first)
                                for pt in activePoints.dropFirst() {
                                    path.addLine(to: pt)
                                }
                            }
                            .stroke(
                                toolMode == .erase
                                    ? Color(uiColor: paperToneColor).opacity(0.82)
                                    : SnapDrillTheme.inkBlue.opacity(0.45),
                                style: StrokeStyle(lineWidth: brushRadiusPoints * 2, lineCap: .round, lineJoin: .round)
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isPeekingOriginal else { return }
                                if imageFrame.contains(value.location) {
                                    activePoints.append(value.location)
                                }
                            }
                            .onEnded { _ in
                                guard !activePoints.isEmpty else { return }
                                applyStroke(viewPoints: activePoints, imageFrame: imageFrame)
                                activePoints = []
                            }
                    )
                }
                .padding(.horizontal, 12)

                // Tool controls
                PaperCard(padding: 12) {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            ForEach(ToolMode.allCases) { mode in
                                let selected = toolMode == mode
                                Button {
                                    toolMode = mode
                                } label: {
                                    Label(mode.title, systemImage: mode.symbolName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 12) {
                            Text("Brush")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(SnapDrillTheme.inkSecondary)

                            ForEach([CGFloat(10), CGFloat(16), CGFloat(26)], id: \.self) { size in
                                let active = abs(brushRadiusPoints - size) < 1
                                Button {
                                    brushRadiusPoints = size
                                } label: {
                                    Circle()
                                        .fill(active ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkSecondary.opacity(0.35))
                                        .frame(width: size * 0.85, height: size * 0.85)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .strokeBorder(active ? SnapDrillTheme.inkBlue : SnapDrillTheme.ruledLine, lineWidth: 1.2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Button {
                                undo()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .frame(width: 34, height: 34)
                            }
                            .disabled(undoStack.isEmpty)

                            Button {
                                redo()
                            } label: {
                                Image(systemName: "arrow.uturn.forward")
                                    .frame(width: 34, height: 34)
                            }
                            .disabled(redoStack.isEmpty)

                            Button {} label: {
                                Image(systemName: "eye")
                                    .frame(width: 34, height: 34)
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPeekingOriginal = true }
                                    .onEnded { _ in isPeekingOriginal = false }
                            )
                            .accessibilityLabel(String(localized: "Hold to Compare Original"))
                        }
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.bottom, 8)
            }
            .paperBackground()
            .navigationTitle(String(localized: "Manual Eraser"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(currentImage)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                paperToneColor = samplePaperTone(from: initialImage)
            }
        }
    }

    // MARK: - Stroke Application

    private func applyStroke(viewPoints: [CGPoint], imageFrame: CGRect) {
        guard imageFrame.width > 0, imageFrame.height > 0,
              currentImage.size.width > 0, currentImage.size.height > 0 else { return }

        undoStack.append(currentImage)
        redoStack.removeAll()

        let scaleX = currentImage.size.width / imageFrame.width
        let scaleY = currentImage.size.height / imageFrame.height
        let strokeWidth = brushRadiusPoints * 2 * scaleX

        let imagePoints = viewPoints.map { pt in
            CGPoint(
                x: (pt.x - imageFrame.minX) * scaleX,
                y: (pt.y - imageFrame.minY) * scaleY
            )
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = currentImage.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: currentImage.size, format: format)

        let updated = renderer.image { ctx in
            let cg = ctx.cgContext
            currentImage.draw(in: CGRect(origin: .zero, size: currentImage.size))

            let path = CGMutablePath()
            if let first = imagePoints.first {
                path.move(to: first)
                if imagePoints.count == 1 {
                    path.addLine(to: CGPoint(x: first.x + 0.5, y: first.y + 0.5))
                } else {
                    for pt in imagePoints.dropFirst() {
                        path.addLine(to: pt)
                    }
                }
            }

            switch toolMode {
            case .erase:
                cg.addPath(path)
                cg.setStrokeColor(paperToneColor.cgColor)
                cg.setLineWidth(strokeWidth)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)
                cg.strokePath()
            case .restore:
                cg.saveGState()
                let stroked = path.copy(
                    strokingWithWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round,
                    miterLimit: 4
                )
                cg.addPath(stroked)
                cg.clip()
                originalReferenceImage.draw(in: CGRect(origin: .zero, size: currentImage.size))
                cg.restoreGState()
            }
        }

        currentImage = updated
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(currentImage)
        currentImage = previous
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentImage)
        currentImage = next
    }

    private func samplePaperTone(from image: UIImage) -> UIColor {
        guard let cg = image.cgImage else {
            return UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0)
        }
        let w = min(64, max(1, cg.width))
        let h = min(64, max(1, cg.height))
        var buf = [UInt8](repeating: 248, count: w * h * 4)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &buf,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0)
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var samples: [(luma: Int, r: UInt8, g: UInt8, b: UInt8)] = []
        for idx in stride(from: 0, to: buf.count, by: 4) {
            let r = buf[idx], g = buf[idx + 1], b = buf[idx + 2]
            let luma = (299 * Int(r) + 587 * Int(g) + 114 * Int(b)) / 1000
            samples.append((luma, r, g, b))
        }
        samples.sort { $0.luma < $1.luma }
        let pick = samples[min(samples.count - 1, Int(Double(samples.count - 1) * 0.88))]
        return UIColor(
            red: CGFloat(max(pick.r, 232)) / 255.0,
            green: CGFloat(max(pick.g, 230)) / 255.0,
            blue: CGFloat(max(pick.b, 224)) / 255.0,
            alpha: 1.0
        )
    }
}
