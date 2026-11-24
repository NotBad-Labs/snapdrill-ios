import SwiftUI

/// Computes exact aspect-fit display frames and coordinate mapping shared across perspective, crop, and eraser overlays.
enum AspectFitCalculator {
    static func fittedRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        let x = (containerSize.width - w) / 2.0
        let y = (containerSize.height - h) / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

/// Pure, unit-testable coordinate transforms for 4-corner perspective adjustment.
enum PerspectiveCornerMath {
    static func normalizedPoint(fromCanvasPoint location: CGPoint, in imageFrame: CGRect) -> CGPoint {
        let nx = min(0.99, max(0.01, (location.x - imageFrame.minX) / max(1, imageFrame.width)))
        let ny = min(0.99, max(0.01, (location.y - imageFrame.minY) / max(1, imageFrame.height)))
        return CGPoint(x: nx, y: ny)
    }
}

/// Interactive 4-corner perspective polygon overlay for Step 1 document edge adjustment over the RAW photo (PRD F-02).
struct PerspectiveCornerOverlay: View {
    @Binding var corners: QuadCorners
    let imageFrame: CGRect
    let onCommit: (QuadCorners) -> Void

    private static let canvasSpaceName = "perspectiveCanvas"

    var body: some View {
        ZStack {
            // Translucent quad outline
            Path { path in
                let tl = viewPoint(for: corners.topLeft)
                let tr = viewPoint(for: corners.topRight)
                let br = viewPoint(for: corners.bottomRight)
                let bl = viewPoint(for: corners.bottomLeft)
                path.move(to: tl)
                path.addLine(to: tr)
                path.addLine(to: br)
                path.addLine(to: bl)
                path.closeSubpath()
            }
            .stroke(SnapDrillTheme.inkBlue, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            .background(
                Path { path in
                    path.move(to: viewPoint(for: corners.topLeft))
                    path.addLine(to: viewPoint(for: corners.topRight))
                    path.addLine(to: viewPoint(for: corners.bottomRight))
                    path.addLine(to: viewPoint(for: corners.bottomLeft))
                    path.closeSubpath()
                }
                .fill(SnapDrillTheme.inkBlue.opacity(0.08))
            )

            cornerHandle(
                point: corners.topLeft,
                label: String(localized: "Top Left Corner")
            ) { pt in
                var candidate = corners
                candidate.topLeft = pt
                if candidate.isConvexAndValid { corners = candidate }
            }

            cornerHandle(
                point: corners.topRight,
                label: String(localized: "Top Right Corner")
            ) { pt in
                var candidate = corners
                candidate.topRight = pt
                if candidate.isConvexAndValid { corners = candidate }
            }

            cornerHandle(
                point: corners.bottomRight,
                label: String(localized: "Bottom Right Corner")
            ) { pt in
                var candidate = corners
                candidate.bottomRight = pt
                if candidate.isConvexAndValid { corners = candidate }
            }

            cornerHandle(
                point: corners.bottomLeft,
                label: String(localized: "Bottom Left Corner")
            ) { pt in
                var candidate = corners
                candidate.bottomLeft = pt
                if candidate.isConvexAndValid { corners = candidate }
            }
        }
        .coordinateSpace(name: Self.canvasSpaceName)
    }

    private func cornerHandle(
        point normalizedPoint: CGPoint,
        label: String,
        onDrag: @escaping (CGPoint) -> Void
    ) -> some View {
        let pt = viewPoint(for: normalizedPoint)
        return Circle()
            .fill(Color.white)
            .frame(width: 26, height: 26)
            .overlay(Circle().strokeBorder(SnapDrillTheme.inkBlue, lineWidth: 3.5))
            .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .position(pt)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.canvasSpaceName))
                    .onChanged { value in
                        let next = PerspectiveCornerMath.normalizedPoint(
                            fromCanvasPoint: value.location,
                            in: imageFrame
                        )
                        onDrag(next)
                    }
                    .onEnded { _ in
                        onCommit(corners)
                    }
            )
            .accessibilityLabel(label)
            .accessibilityHint(String(localized: "Drag to align page corner"))
    }

    private func viewPoint(for normalized: CGPoint) -> CGPoint {
        CGPoint(
            x: imageFrame.minX + normalized.x * imageFrame.width,
            y: imageFrame.minY + normalized.y * imageFrame.height
        )
    }
}
