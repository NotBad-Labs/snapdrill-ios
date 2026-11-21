import SwiftUI

/// Renders and manages draggable/resizable question crop boxes over a page (PRD §8.2, F-05).
struct MultiBoxCropOverlay: View {
    let boxes: [CaptureCropBox]
    let activeBoxID: UUID?
    let imageFrame: CGRect
    let onSelectBox: (UUID) -> Void
    let onUpdateBox: (CaptureCropBox) -> Void
    let onDeleteBox: (UUID) -> Void

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
                    onDelete: boxes.count > 1 ? { onDeleteBox(box.id) } : nil
                )
            }
        }
    }
}

/// Single numbered crop frame with pan + 4-corner resize handles.
struct CropBoxOverlayItem: View {
    let box: CaptureCropBox
    let indexNumber: Int
    let isActive: Bool
    let imageFrame: CGRect
    let onSelect: () -> Void
    let onUpdate: (CaptureCropBox) -> Void
    var onDelete: (() -> Void)? = nil

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
                    DragGesture()
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
                        }
                )

            // Numbered circle badge at top-left corner
            Text("\(indexNumber)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(strokeColor, in: Circle())
                .position(x: rect.minX + 12, y: rect.minY + 12)

            if isActive, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                }
                .position(x: rect.maxX - 4, y: rect.minY + 4)
                .accessibilityLabel(String(localized: "Remove Question Frame \(indexNumber)"))
            }

            if isActive {
                resizeHandle(corner: .topLeft, at: CGPoint(x: rect.minX, y: rect.minY))
                resizeHandle(corner: .topRight, at: CGPoint(x: rect.maxX, y: rect.minY))
                resizeHandle(corner: .bottomLeft, at: CGPoint(x: rect.minX, y: rect.maxY))
                resizeHandle(corner: .bottomRight, at: CGPoint(x: rect.maxX, y: rect.maxY))
            }
        }
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func resizeHandle(corner: Corner, at point: CGPoint) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 20, height: 20)
            .overlay(Circle().strokeBorder(SnapDrillTheme.inkBlue, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
            .position(point)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let nx = min(0.99, max(0.01, (value.location.x - imageFrame.minX) / max(1, imageFrame.width)))
                        let ny = min(0.99, max(0.01, (value.location.y - imageFrame.minY) / max(1, imageFrame.height)))
                        var r = box.normalizedRect
                        let minSize: CGFloat = 0.08

                        switch corner {
                        case .topLeft:
                            let maxX = r.maxX - minSize
                            let maxY = r.maxY - minSize
                            let newX = min(nx, maxX)
                            let newY = min(ny, maxY)
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

                        var updated = box
                        updated.normalizedRect = r.clampedToUnitSquare()
                        onUpdate(updated)
                    }
            )
    }
}
