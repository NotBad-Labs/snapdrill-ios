import SwiftUI

/// Computes exact aspect-fit display frames shared across perspective, crop, and eraser overlays.
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

/// Interactive 4-corner perspective polygon overlay for Step 1 document edge adjustment (PRD F-02).
struct PerspectiveCornerOverlay: View {
    @Binding var corners: QuadCorners
    let imageFrame: CGRect
    let onCommit: (QuadCorners) -> Void

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

            cornerHandle(binding: $corners.topLeft, label: "Top Left Corner")
            cornerHandle(binding: $corners.topRight, label: "Top Right Corner")
            cornerHandle(binding: $corners.bottomRight, label: "Bottom Right Corner")
            cornerHandle(binding: $corners.bottomLeft, label: "Bottom Left Corner")
        }
    }

    private func cornerHandle(binding: Binding<CGPoint>, label: String) -> some View {
        let pt = viewPoint(for: binding.wrappedValue)
        return Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .overlay(Circle().strokeBorder(SnapDrillTheme.inkBlue, lineWidth: 3.5))
            .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1)
            .position(pt)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let nx = min(0.98, max(0.02, (value.location.x - imageFrame.minX) / max(1, imageFrame.width)))
                        let ny = min(0.98, max(0.02, (value.location.y - imageFrame.minY) / max(1, imageFrame.height)))
                        binding.wrappedValue = CGPoint(x: nx, y: ny)
                    }
                    .onEnded { _ in
                        onCommit(corners)
                    }
            )
            .accessibilityLabel(label)
    }

    private func viewPoint(for normalized: CGPoint) -> CGPoint {
        CGPoint(
            x: imageFrame.minX + normalized.x * imageFrame.width,
            y: imageFrame.minY + normalized.y * imageFrame.height
        )
    }
}
