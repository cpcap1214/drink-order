import SwiftUI

/// 上寬下窄、底部圓角的杯身
struct CupShape: Shape {
    var bottomInsetRatio: CGFloat = 0.115

    func path(in rect: CGRect) -> Path {
        let inset = rect.width * bottomInsetRatio
        let r = min(12, rect.width * 0.1)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - inset - r, y: rect.maxY),
                       control: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + inset + r, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + inset, y: rect.maxY - r),
                       control: CGPoint(x: rect.minX + inset, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// 液面帶波浪的液體
struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat
    var surfaceY: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x: CGFloat = 0
        while x <= rect.width + 4 {
            let rel = Double(x / rect.width)
            let y = surfaceY + CGFloat(sin(phase + rel * 2 * .pi)) * amplitude
            p.addLine(to: CGPoint(x: x, y: y))
            x += 4
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
