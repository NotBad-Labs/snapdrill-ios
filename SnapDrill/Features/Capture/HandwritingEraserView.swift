import SwiftUI
import UIKit

/// Memory-efficient lightweight stroke command for Undo/Redo instead of storing full bitmaps (M1 / M-05).
struct EraserStroke: Identifiable, Sendable, Equatable {
    enum Mode: String, Sendable {
        case erase
        case restore
    }

    struct PaperRGB: Sendable, Equatable {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
    }

    let id: UUID
    let mode: Mode
    let normalizedPoints: [CGPoint]
    let normalizedRadiusX: CGFloat
    let paperColor: PaperRGB

    init(
        id: UUID = UUID(),
        mode: Mode,
        normalizedPoints: [CGPoint],
        normalizedRadiusX: CGFloat,
        paperColor: PaperRGB
    ) {
        self.id = id
        self.mode = mode
        self.normalizedPoints = normalizedPoints
        self.normalizedRadiusX = normalizedRadiusX
        self.paperColor = paperColor
    }
}

/// Off-MainActor rasterizer & local paper-tone sampler for manual touch-up strokes.
enum EraserStrokeEngine {
    static let maxUndoDepth = 30

    static func pushStroke(
        _ stroke: EraserStroke,
        into undoStack: inout [EraserStroke],
        redoStack: inout [EraserStroke],
        bakedStrokes: inout [EraserStroke]
    ) {
        undoStack.append(stroke)
        if undoStack.count > maxUndoDepth {
            let overflowCount = undoStack.count - maxUndoDepth
            bakedStrokes.append(contentsOf: undoStack.prefix(overflowCount))
            undoStack.removeFirst(overflowCount)
        }
        redoStack.removeAll()
    }

    static func downscaleForEditing(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let ratio = maxDimension / longest
        let targetSize = CGSize(
            width: (image.size.width * ratio).rounded(.down),
            height: (image.size.height * ratio).rounded(.down)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    static func sampleLocalPaperColor(in image: UIImage, aroundNormalizedPoints points: [CGPoint]) -> EraserStroke.PaperRGB {
        guard let cg = image.cgImage, cg.width > 0, cg.height > 0 else {
            return EraserStroke.PaperRGB(r: 0.96, g: 0.95, b: 0.93)
        }

        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let minNX = max(0.0, (xs.min() ?? 0.0) - 0.08)
        let maxNX = min(1.0, (xs.max() ?? 1.0) + 0.08)
        let minNY = max(0.0, (ys.min() ?? 0.0) - 0.08)
        let maxNY = min(1.0, (ys.max() ?? 1.0) + 0.08)

        let cropRect = CGRect(
            x: floor(minNX * CGFloat(cg.width)),
            y: floor(minNY * CGFloat(cg.height)),
            width: max(8, ceil((maxNX - minNX) * CGFloat(cg.width))),
            height: max(8, ceil((maxNY - minNY) * CGFloat(cg.height)))
        ).intersection(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))

        let regionCG = cg.cropping(to: cropRect) ?? cg
        let w = min(48, max(4, regionCG.width))
        let h = min(48, max(4, regionCG.height))
        var buf = [UInt8](repeating: 245, count: w * h * 4)
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
            return EraserStroke.PaperRGB(r: 0.96, g: 0.95, b: 0.93)
        }
        ctx.draw(regionCG, in: CGRect(x: 0, y: 0, width: w, height: h))

        var samples: [(luma: Int, r: UInt8, g: UInt8, b: UInt8)] = []
        samples.reserveCapacity(w * h)
        for idx in stride(from: 0, to: buf.count, by: 4) {
            let r = buf[idx], g = buf[idx + 1], b = buf[idx + 2]
            let luma = (299 * Int(r) + 587 * Int(g) + 114 * Int(b)) / 1000
            samples.append((luma, r, g, b))
        }
        guard !samples.isEmpty else {
            return EraserStroke.PaperRGB(r: 0.96, g: 0.95, b: 0.93)
        }
        samples.sort { $0.luma < $1.luma }
        let pick = samples[min(samples.count - 1, Int(Double(samples.count - 1) * 0.86))]
        return EraserStroke.PaperRGB(
            r: CGFloat(pick.r) / 255.0,
            g: CGFloat(pick.g) / 255.0,
            b: CGFloat(pick.b) / 255.0
        )
    }

    static func composite(
        baseImage: UIImage,
        originalReference: UIImage,
        strokes: [EraserStroke]
    ) -> UIImage {
        guard !strokes.isEmpty,
              baseImage.size.width > 0,
              baseImage.size.height > 0 else {
            return baseImage
        }

        let size = baseImage.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            for stroke in strokes {
                guard !stroke.normalizedPoints.isEmpty else { continue }
                let strokeWidth = max(2, stroke.normalizedRadiusX * 2 * size.width)
                let path = CGMutablePath()
                let pts = stroke.normalizedPoints.map { pt in
                    CGPoint(x: pt.x * size.width, y: pt.y * size.height)
                }
                if let first = pts.first {
                    path.move(to: first)
                    if pts.count == 1 {
                        path.addLine(to: CGPoint(x: first.x + 0.5, y: first.y + 0.5))
                    } else {
                        for pt in pts.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                }

                switch stroke.mode {
                case .erase:
                    let color = UIColor(
                        red: stroke.paperColor.r,
                        green: stroke.paperColor.g,
                        blue: stroke.paperColor.b,
                        alpha: 1.0
                    )
                    cg.addPath(path)
                    cg.setStrokeColor(color.cgColor)
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
                    originalReference.draw(in: CGRect(origin: .zero, size: size))
                    cg.restoreGState()
                }
            }
        }
    }
}

/// Manual touch-up eraser and restore brush using command-based undo stack, local paper sampling,
/// and off-MainActor rendering (PRD F-12, M1, M-05).
struct HandwritingEraserView: View {
    let initialImage: UIImage
    let originalReferenceImage: UIImage
    let onSave: (UIImage) -> Void

    private enum BrushPreset: CaseIterable, Identifiable {
        case small
        case medium
        case large

        var id: CGFloat { radiusPoints }

        var radiusPoints: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 16
            case .large: return 26
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .small: return String(localized: "Small Brush")
            case .medium: return String(localized: "Medium Brush")
            case .large: return String(localized: "Large Brush")
            }
        }
    }

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

        var strokeMode: EraserStroke.Mode {
            switch self {
            case .erase: return .erase
            case .restore: return .restore
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private let workingInitialImage: UIImage
    private let workingOriginalImage: UIImage

    @State private var currentDisplayImage: UIImage
    @State private var bakedBaseStrokes: [EraserStroke] = []
    @State private var undoStrokes: [EraserStroke] = []
    @State private var redoStrokes: [EraserStroke] = []
    @State private var toolMode: ToolMode = .erase
    @State private var brushRadiusPoints: CGFloat = 16
    @State private var isPeekingOriginal: Bool = false
    @State private var activePoints: [CGPoint] = []
    @State private var previewPaperColor: UIColor = UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0)
    @State private var isFinalizing = false
    @State private var previewGeneration: Int = 0
    @State private var previewTask: Task<Void, Never>?

    private static let canvasSpaceName = "eraserCanvas"

    init(initialImage: UIImage, originalReferenceImage: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.initialImage = initialImage
        self.originalReferenceImage = originalReferenceImage
        self.onSave = onSave
        let downInitial = EraserStrokeEngine.downscaleForEditing(initialImage)
        let downOrig = EraserStrokeEngine.downscaleForEditing(originalReferenceImage)
        self.workingInitialImage = downInitial
        self.workingOriginalImage = downOrig
        _currentDisplayImage = State(initialValue: downInitial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                GeometryReader { geo in
                    let imageFrame = AspectFitCalculator.fittedRect(
                        imageSize: currentDisplayImage.size,
                        in: geo.size
                    )

                    ZStack {
                        Image(uiImage: isPeekingOriginal ? workingOriginalImage : currentDisplayImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        // Live vector stroke preview while dragging (supports single-tap dot & clipped to imageFrame)
                        if !activePoints.isEmpty && !isPeekingOriginal {
                            Path { path in
                                guard let first = activePoints.first else { return }
                                path.move(to: first)
                                if activePoints.count == 1 {
                                    path.addLine(to: CGPoint(x: first.x + 0.5, y: first.y + 0.5))
                                } else {
                                    for pt in activePoints.dropFirst() {
                                        path.addLine(to: pt)
                                    }
                                }
                            }
                            .stroke(
                                toolMode == .erase
                                    ? Color(uiColor: previewPaperColor).opacity(0.82)
                                    : SnapDrillTheme.inkBlue.opacity(0.45),
                                style: StrokeStyle(lineWidth: brushRadiusPoints * 2, lineCap: .round, lineJoin: .round)
                            )
                            .clipShape(
                                Rectangle()
                                    .path(in: imageFrame)
                            )
                        }
                    }
                    .coordinateSpace(name: Self.canvasSpaceName)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.canvasSpaceName))
                            .onChanged { value in
                                guard !isPeekingOriginal, !isFinalizing,
                                      imageFrame.width > 0, imageFrame.height > 0 else { return }
                                if activePoints.isEmpty && !imageFrame.contains(value.location) {
                                    return
                                }
                                let clamped = CGPoint(
                                    x: min(imageFrame.maxX, max(imageFrame.minX, value.location.x)),
                                    y: min(imageFrame.maxY, max(imageFrame.minY, value.location.y))
                                )
                                activePoints.append(clamped)
                            }
                            .onEnded { _ in
                                guard !activePoints.isEmpty else { return }
                                let captured = activePoints
                                activePoints = []
                                commitStroke(viewPoints: captured, imageFrame: imageFrame)
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
                                .accessibilityLabel(mode.title)
                            }
                        }

                        HStack(spacing: 12) {
                            Text("Brush")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(SnapDrillTheme.inkSecondary)

                            ForEach(BrushPreset.allCases) { preset in
                                let size = preset.radiusPoints
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
                                .accessibilityLabel(preset.accessibilityLabel)
                            }

                            Spacer()

                            Button {
                                performUndo()
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .frame(width: 34, height: 34)
                            }
                            .disabled(undoStrokes.isEmpty || isFinalizing)
                            .accessibilityLabel(String(localized: "Undo Stroke"))

                            Button {
                                performRedo()
                            } label: {
                                Image(systemName: "arrow.uturn.forward")
                                    .frame(width: 34, height: 34)
                            }
                            .disabled(redoStrokes.isEmpty || isFinalizing)
                            .accessibilityLabel(String(localized: "Redo Stroke"))

                            Button {
                                isPeekingOriginal.toggle()
                            } label: {
                                Image(systemName: isPeekingOriginal ? "eye.fill" : "eye")
                                    .foregroundStyle(isPeekingOriginal ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkBlack)
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "Compare Original"))
                            .accessibilityValue(isPeekingOriginal ? String(localized: "Showing Original") : String(localized: "Showing Cleaned"))
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
                        .disabled(isFinalizing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        finalizeAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isFinalizing)
                }
            }
            .onAppear {
                let sample = EraserStrokeEngine.sampleLocalPaperColor(
                    in: workingInitialImage,
                    aroundNormalizedPoints: [CGPoint(x: 0.5, y: 0.5)]
                )
                previewPaperColor = UIColor(red: sample.r, green: sample.g, blue: sample.b, alpha: 1.0)
            }
        }
    }

    // MARK: - Async Off-MainActor Stroke Compositing

    private func commitStroke(viewPoints: [CGPoint], imageFrame: CGRect) {
        guard imageFrame.width > 0, imageFrame.height > 0 else { return }

        let normalizedPts = viewPoints.map { pt in
            CGPoint(
                x: min(1.0, max(0.0, (pt.x - imageFrame.minX) / imageFrame.width)),
                y: min(1.0, max(0.0, (pt.y - imageFrame.minY) / imageFrame.height))
            )
        }
        let normRadius = brushRadiusPoints / imageFrame.width
        let baseImg = workingInitialImage
        let mode = toolMode.strokeMode

        let localSample = EraserStrokeEngine.sampleLocalPaperColor(
            in: baseImg,
            aroundNormalizedPoints: normalizedPts
        )
        previewPaperColor = UIColor(red: localSample.r, green: localSample.g, blue: localSample.b, alpha: 1.0)

        let stroke = EraserStroke(
            mode: mode,
            normalizedPoints: normalizedPts,
            normalizedRadiusX: normRadius,
            paperColor: localSample
        )

        EraserStrokeEngine.pushStroke(
            stroke,
            into: &undoStrokes,
            redoStack: &redoStrokes,
            bakedStrokes: &bakedBaseStrokes
        )
        recompositeWorkingPreviewAsync()
    }

    private func performUndo() {
        guard let last = undoStrokes.popLast() else { return }
        redoStrokes.append(last)
        recompositeWorkingPreviewAsync()
    }

    private func performRedo() {
        guard let next = redoStrokes.popLast() else { return }
        undoStrokes.append(next)
        recompositeWorkingPreviewAsync()
    }

    private func recompositeWorkingPreviewAsync() {
        previewTask?.cancel()
        previewGeneration &+= 1
        let targetGeneration = previewGeneration
        let strokesSnapshot = bakedBaseStrokes + undoStrokes
        let base = workingInitialImage
        let orig = workingOriginalImage

        previewTask = Task {
            let rendered = await Task.detached(priority: .userInitiated) {
                guard !Task.isCancelled else { return nil as UIImage? }
                return EraserStrokeEngine.composite(
                    baseImage: base,
                    originalReference: orig,
                    strokes: strokesSnapshot
                )
            }.value
            guard !Task.isCancelled,
                  previewGeneration == targetGeneration,
                  let rendered else {
                return
            }
            currentDisplayImage = rendered
        }
    }

    private func finalizeAndDismiss() {
        previewTask?.cancel()
        previewGeneration &+= 1
        let strokesSnapshot = bakedBaseStrokes + undoStrokes
        if strokesSnapshot.isEmpty {
            dismiss()
            return
        }

        isFinalizing = true
        let fullBase = initialImage
        let fullOrig = originalReferenceImage

        Task.detached(priority: .userInitiated) {
            let fullResolution = EraserStrokeEngine.composite(
                baseImage: fullBase,
                originalReference: fullOrig,
                strokes: strokesSnapshot
            )
            await MainActor.run {
                isFinalizing = false
                onSave(fullResolution)
                dismiss()
            }
        }
    }
}
