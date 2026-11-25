import SwiftUI

/// Pure, unit-testable geometry transforms for normalized crop boxes.
enum CropBoxGeometry {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    static func normalizedPoint(fromCanvasPoint location: CGPoint, in imageFrame: CGRect) -> CGPoint {
        let nx = min(0.99, max(0.01, (location.x - imageFrame.minX) / max(1, imageFrame.width)))
        let ny = min(0.99, max(0.01, (location.y - imageFrame.minY) / max(1, imageFrame.height)))
        return CGPoint(x: nx, y: ny)
    }

    static func resizedRect(
        from rect: CGRect,
        corner: Corner,
        toNormalizedPoint target: CGPoint,
        minSize: CGFloat = 0.08
    ) -> CGRect {
        let nx = min(0.99, max(0.01, target.x))
        let ny = min(0.99, max(0.01, target.y))
        var r = rect

        switch corner {
        case .topLeft:
            let newX = min(nx, r.maxX - minSize)
            let newY = min(ny, r.maxY - minSize)
            r = CGRect(x: newX, y: newY, width: r.maxX - newX, height: r.maxY - newY)
        case .topRight:
            let newMaxX = max(nx, r.minX + minSize)
            let newY = min(ny, r.maxY - minSize)
            r = CGRect(x: r.minX, y: newY, width: newMaxX - r.minX, height: r.maxY - newY)
        case .bottomLeft:
            let newX = min(nx, r.maxX - minSize)
            let newMaxY = max(ny, r.minY + minSize)
            r = CGRect(x: newX, y: r.minY, width: r.maxX - newX, height: newMaxY - r.minY)
        case .bottomRight:
            let newMaxX = max(nx, r.minX + minSize)
            let newMaxY = max(ny, r.minY + minSize)
            r = CGRect(x: r.minX, y: r.minY, width: newMaxX - r.minX, height: newMaxY - r.minY)
        }

        return r.clampedToUnitSquare()
    }
}

/// Renders and manages draggable/resizable question crop boxes over a page (PRD §8.2, F-05).
struct MultiBoxCropOverlay: View {
    let boxes: [CaptureCropBox]
    let activeBoxID: UUID?
    let imageFrame: CGRect
    let onSelectBox: (UUID) -> Void
    let onUpdateBox: (CaptureCropBox) -> Void
    let onDeleteBox: (UUID) -> Void
    var onDragEnded: (() -> Void)? = nil

    static let canvasSpaceName = "cropCanvas"

    var body: some View {
        ZStack {
            ForEach(Array(boxes.enumerated()), id: \.element.id) { index, box in
                let isActive = box.id == (activeBoxID ?? boxes.first?.id)
                CropBoxOverlayItem(
                    box: box,
                    indexNumber: index + 1,
                    isActive: isActive,
                    imageFrame: imageFrame,
                    onSelect: { onSelectBox(box.id) },
                    onUpdate: onUpdateBox,
                    onDelete: boxes.count > 1 ? { onDeleteBox(box.id) } : nil,
                    onDragEnded: onDragEnded
                )
            }
        }
        .coordinateSpace(name: Self.canvasSpaceName)
    }
}

/// Single numbered crop frame with pan + 4-corner resize handles in shared canvas coordinates.
struct CropBoxOverlayItem: View {
    let box: CaptureCropBox
    let indexNumber: Int
    let isActive: Bool
    let imageFrame: CGRect
    let onSelect: () -> Void
    let onUpdate: (CaptureCropBox) -> Void
    var onDelete: (() -> Void)? = nil
    var onDragEnded: (() -> Void)? = nil

    @State private var dragStartRect: CGRect?

    private var frameInView: CGRect {
        let r = box.normalizedRect
        return CGRect(
            x: imageFrame.minX + r.origin.x * imageFrame.width,
            y: imageFrame.minY + r.origin.y * imageFrame.height,
            width: r.width * imageFrame.width,
            height: r.height * imageFrame.height
        )
    }

    var body: some View {
        let rect = frameInView
        let strokeColor = isActive ? SnapDrillTheme.inkBlue : SnapDrillTheme.pencilYellow

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(strokeColor.opacity(isActive ? 0.14 : 0.08))
                .overlay(
                    Rectangle()
                        .strokeBorder(strokeColor, lineWidth: isActive ? 2.5 : 1.8)
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .onTapGesture { onSelect() }
                .gesture(
                    DragGesture(coordinateSpace: .named(MultiBoxCropOverlay.canvasSpaceName))
                        .onChanged { value in
                            onSelect()
                            if dragStartRect == nil { dragStartRect = box.normalizedRect }
                            guard let base = dragStartRect else { return }
                            let dx = value.translation.width / max(1, imageFrame.width)
                            let dy = value.translation.height / max(1, imageFrame.height)
                            let moved = CGRect(
                                x: min(1.0 - base.width, max(0.0, base.origin.x + dx)),
                                y: min(1.0 - base.height, max(0.0, base.origin.y + dy)),
                                width: base.width,
                                height: base.height
                            )
                            var updated = box
                            updated.normalizedRect = moved
                            onUpdate(updated)
                        }
                        .onEnded { _ in
                            dragStartRect = nil
                            onDragEnded?()
                        }
                )
                .accessibilityLabel(String(localized: "Question Frame \(indexNumber)"))

            // Numbered circle badge at top-left corner
            Text("\(indexNumber)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(strokeColor, in: Circle())
                .position(x: rect.minX + 12, y: rect.minY + 12)
                .accessibilityHidden(true)

            if isActive, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .position(x: rect.maxX - 4, y: rect.minY + 4)
                .accessibilityLabel(String(localized: "Remove Question Frame \(indexNumber)"))
            }

            if isActive {
                resizeHandle(corner: .topLeft, at: CGPoint(x: rect.minX, y: rect.minY), label: String(localized: "Top Left Crop Handle"))
                resizeHandle(corner: .topRight, at: CGPoint(x: rect.maxX, y: rect.minY), label: String(localized: "Top Right Crop Handle"))
                resizeHandle(corner: .bottomLeft, at: CGPoint(x: rect.minX, y: rect.maxY), label: String(localized: "Bottom Left Crop Handle"))
                resizeHandle(corner: .bottomRight, at: CGPoint(x: rect.maxX, y: rect.maxY), label: String(localized: "Bottom Right Crop Handle"))
            }
        }
    }

    private func resizeHandle(corner: CropBoxGeometry.Corner, at point: CGPoint, label: String) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .overlay(Circle().strokeBorder(SnapDrillTheme.inkBlue, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .position(point)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(MultiBoxCropOverlay.canvasSpaceName))
                    .onChanged { value in
                        let target = CropBoxGeometry.normalizedPoint(
                            fromCanvasPoint: value.location,
                            in: imageFrame
                        )
                        var updated = box
                        updated.normalizedRect = CropBoxGeometry.resizedRect(
                            from: box.normalizedRect,
                            corner: corner,
                            toNormalizedPoint: target
                        )
                        onUpdate(updated)
                    }
                    .onEnded { _ in
                        onDragEnded?()
                    }
            )
            .accessibilityLabel(label)
            .accessibilityHint(String(localized: "Drag to resize question frame"))
    }
}
