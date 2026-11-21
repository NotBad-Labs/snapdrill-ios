import SwiftUI

/// Minimalist line-art panda mascot used only in empty states, completion screens, and save confirmation (PRD §7.2).
struct PandaMascotView: View {
    enum Mood {
        case welcoming
        case celebrating
        case savedBadge
    }

    let mood: Mood
    var size: CGFloat = 112

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width * (mood == .celebrating ? 0.5 : 0.46)
            let cy = canvasSize.height * 0.54

            let ink = Color(red: 0.13, green: 0.13, blue: 0.15)
            let paperWhite = Color(red: 0.996, green: 0.992, blue: 0.98)
            let yellow = Color(red: 0.935, green: 0.745, blue: 0.215)
            let red = Color(red: 0.835, green: 0.295, blue: 0.275)
            let inkBlue = Color(red: 0.173, green: 0.337, blue: 0.537)

            // Viewfinder accent brackets around welcoming mascot
            if mood == .welcoming {
                let m = s * 0.08
                let len = s * 0.14
                for (xSign, ySign, ox, oy) in [
                    (1.0, 1.0, m, m),
                    (-1.0, 1.0, canvasSize.width - m, m),
                    (1.0, -1.0, m, canvasSize.height - m),
                    (-1.0, -1.0, canvasSize.width - m, canvasSize.height - m)
                ] {
                    var bracket = Path()
                    bracket.move(to: CGPoint(x: ox + xSign * len, y: oy))
                    bracket.addLine(to: CGPoint(x: ox, y: oy))
                    bracket.addLine(to: CGPoint(x: ox, y: oy + ySign * len))
                    context.stroke(
                        bracket,
                        with: .color(inkBlue.opacity(0.65)),
                        style: StrokeStyle(lineWidth: max(2.5, s * 0.036), lineCap: .round, lineJoin: .round)
                    )
                }
            }

            // Ears
            let earR = s * 0.105
            context.fill(
                Path(ellipseIn: CGRect(x: cx - s * 0.26 - earR, y: cy - s * 0.24 - earR, width: earR * 2, height: earR * 2)),
                with: .color(ink)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: cx + s * 0.26 - earR, y: cy - s * 0.24 - earR, width: earR * 2, height: earR * 2)),
                with: .color(ink)
            )

            // Head base
            let headW = s * 0.62
            let headH = s * 0.54
            let headRect = CGRect(x: cx - headW / 2, y: cy - headH / 2, width: headW, height: headH)
            context.fill(Path(ellipseIn: headRect), with: .color(paperWhite))
            context.stroke(Path(ellipseIn: headRect), with: .color(ink), lineWidth: max(2.2, s * 0.028))

            // Eye patches
            let eyeW = s * 0.145
            let eyeH = s * 0.175
            let eyeY = cy - s * 0.02
            for dir in [-1.0, 1.0] {
                let ex = cx + dir * s * 0.135
                var patchCtx = context
                patchCtx.translateBy(x: ex, y: eyeY)
                patchCtx.rotate(by: .radians(dir * 0.22))
                let patchRect = CGRect(x: -eyeW / 2, y: -eyeH / 2, width: eyeW, height: eyeH)
                patchCtx.fill(Path(ellipseIn: patchRect), with: .color(ink))

                if mood == .celebrating {
                    // Happy crescent highlight
                    var arc = Path()
                    arc.addArc(center: CGPoint(x: 0, y: eyeH * 0.08), radius: eyeW * 0.24, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                    patchCtx.stroke(arc, with: .color(paperWhite), style: StrokeStyle(lineWidth: max(1.8, s * 0.024), lineCap: .round))
                } else {
                    let glint = s * 0.045
                    patchCtx.fill(
                        Path(ellipseIn: CGRect(x: -glint / 2, y: -glint / 2, width: glint, height: glint)),
                        with: .color(paperWhite)
                    )
                }
            }

            // Nose & smile
            let noseW = s * 0.09
            let noseH = s * 0.056
            context.fill(
                Path(ellipseIn: CGRect(x: cx - noseW / 2, y: cy + s * 0.075, width: noseW, height: noseH)),
                with: .color(ink)
            )
            var smile = Path()
            smile.move(to: CGPoint(x: cx - s * 0.055, y: cy + s * 0.16))
            smile.addQuadCurve(to: CGPoint(x: cx, y: cy + s * 0.17), control: CGPoint(x: cx - s * 0.025, y: cy + s * 0.195))
            smile.addQuadCurve(to: CGPoint(x: cx + s * 0.055, y: cy + s * 0.16), control: CGPoint(x: cx + s * 0.025, y: cy + s * 0.195))
            context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: max(1.6, s * 0.02), lineCap: .round))

            // Yellow pencil accessory for welcoming / celebrating
            if mood != .savedBadge {
                var penCtx = context
                penCtx.translateBy(x: cx + s * 0.36, y: cy + s * 0.04)
                penCtx.rotate(by: .radians(0.46))

                let pw = s * 0.115
                let ph = s * 0.36
                let bodyRect = CGRect(x: -pw / 2, y: -ph * 0.5, width: pw, height: ph * 0.72)
                penCtx.fill(Path(roundedRect: bodyRect, cornerRadius: pw * 0.18), with: .color(yellow))

                let eraserRect = CGRect(x: -pw / 2, y: -ph * 0.65, width: pw, height: ph * 0.16)
                penCtx.fill(Path(roundedRect: eraserRect, cornerRadius: pw * 0.2), with: .color(red))

                var tip = Path()
                tip.move(to: CGPoint(x: -pw / 2, y: ph * 0.22))
                tip.addLine(to: CGPoint(x: pw / 2, y: ph * 0.22))
                tip.addLine(to: CGPoint(x: 0, y: ph * 0.45))
                tip.closeSubpath()
                penCtx.fill(tip, with: .color(Color(red: 0.94, green: 0.84, blue: 0.68)))

                var outline = Path()
                outline.addRoundedRect(in: CGRect(x: -pw / 2, y: -ph * 0.65, width: pw, height: ph * 0.87), cornerSize: CGSize(width: pw * 0.18, height: pw * 0.18))
                penCtx.stroke(outline, with: .color(ink), lineWidth: max(1.6, s * 0.02))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
