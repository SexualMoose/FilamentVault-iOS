import SwiftUI

/// 3D filament-spool swatch rendered in SwiftUI Canvas. Same proportions as
/// the Android version: tilted perspective with front/back flanges, filament
/// barrel with cylindrical gradient shading, and concentric winding lines.
struct ColorSwatchSpool: View {
    let colorHex: String
    var size: CGFloat = 80

    var body: some View {
        Canvas { ctx, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            let filamentColor = Color(hex: colorHex, fallback: .gray)
            let filamentDark = darken(filamentColor, 0.6)
            let filamentHighlight = lighten(filamentColor, 1.35)

            let tilt = h * 0.13
            let cx = w / 2
            let frontY = h * 0.57
            let backY = frontY - tilt

            let outerRx = w * 0.46
            let outerRy = h * 0.27
            let midRx = w * 0.33
            let midRy = h * 0.20
            let innerRx = w * 0.12
            let innerRy = h * 0.07

            let flangeColor = Color(red: 0.29, green: 0.29, blue: 0.29)
            let flangeSide = Color(red: 0.23, green: 0.23, blue: 0.23)
            let coreColor = Color(red: 0.10, green: 0.10, blue: 0.10)
            let coreSide = Color(red: 0.07, green: 0.07, blue: 0.07)

            // ── Barrel depth (visible side strip between back & front) ──

            // Outer flange barrel
            var outerSide = Path()
            outerSide.addArc(
                center: CGPoint(x: cx, y: backY),
                radius: 1,
                startAngle: .degrees(180),
                endAngle: .degrees(360),
                clockwise: false,
                transform: scaleY(1, ry: outerRy / outerRx, rx: outerRx)
            )
            // Simpler side path using line+arc combinations
            outerSide = sidePath(cx: cx, rx: outerRx, ry: outerRy, backY: backY, frontY: frontY)
            ctx.fill(outerSide, with: .color(flangeSide))

            // Filament barrel side with horizontal gradient (cylindrical shading)
            let filamentSide = sidePath(cx: cx, rx: midRx, ry: midRy, backY: backY, frontY: frontY)
            ctx.fill(
                filamentSide,
                with: .linearGradient(
                    Gradient(colors: [
                        filamentDark, filamentColor, filamentHighlight,
                        filamentColor, filamentDark
                    ]),
                    startPoint: CGPoint(x: cx - midRx, y: frontY),
                    endPoint: CGPoint(x: cx + midRx, y: frontY)
                )
            )

            // Core barrel
            let coreBarrel = sidePath(cx: cx, rx: innerRx, ry: innerRy, backY: backY, frontY: frontY)
            ctx.fill(coreBarrel, with: .color(coreSide))

            // ── Front face ──

            // Front flange disk
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: cx - outerRx, y: frontY - outerRy,
                    width: outerRx * 2, height: outerRy * 2
                )),
                with: .color(flangeColor)
            )

            // Front filament ring — radial gradient for wound-filament shading
            let frontRingRect = CGRect(
                x: cx - midRx, y: frontY - midRy,
                width: midRx * 2, height: midRy * 2
            )
            ctx.fill(
                Path(ellipseIn: frontRingRect),
                with: .radialGradient(
                    Gradient(colors: [filamentHighlight, filamentColor, filamentDark]),
                    center: CGPoint(x: cx - midRx * 0.15, y: frontY - midRy * 0.2),
                    startRadius: 0,
                    endRadius: midRx * 1.3
                )
            )

            // Subtle concentric winding lines
            for i in 1...4 {
                let ratio = CGFloat(i) / 5.0
                let rx = innerRx + (midRx - innerRx) * ratio
                let ry = innerRy + (midRy - innerRy) * ratio
                ctx.stroke(
                    Path(ellipseIn: CGRect(
                        x: cx - rx, y: frontY - ry,
                        width: rx * 2, height: ry * 2
                    )),
                    with: .color(.white.opacity(0.07)),
                    lineWidth: 0.8
                )
            }

            // Front core hole
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: cx - innerRx, y: frontY - innerRy,
                    width: innerRx * 2, height: innerRy * 2
                )),
                with: .color(coreColor)
            )

            // Thin outline for visibility on dark backgrounds
            ctx.stroke(
                Path(ellipseIn: CGRect(
                    x: cx - outerRx, y: frontY - outerRy,
                    width: outerRx * 2, height: outerRy * 2
                )),
                with: .color(.white.opacity(0.15)),
                lineWidth: 0.8
            )
        }
        .frame(width: size, height: size)
    }

    private func sidePath(cx: CGFloat, rx: CGFloat, ry: CGFloat, backY: CGFloat, frontY: CGFloat) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: cx - rx, y: backY - ry, width: rx * 2, height: ry * 2))
        p.addRect(CGRect(x: cx - rx, y: backY, width: rx * 2, height: frontY - backY))
        p.addEllipse(in: CGRect(x: cx - rx, y: frontY - ry, width: rx * 2, height: ry * 2))
        return p
    }

    private func scaleY(_ sx: CGFloat, ry: CGFloat, rx: CGFloat) -> CGAffineTransform {
        CGAffineTransform.identity
    }

    private func darken(_ color: Color, _ factor: CGFloat) -> Color {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red: r * factor, green: g * factor, blue: b * factor, opacity: a)
    }

    private func lighten(_ color: Color, _ factor: CGFloat) -> Color {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: min(r * factor, 1),
            green: min(g * factor, 1),
            blue: min(b * factor, 1),
            opacity: a
        )
    }
}
