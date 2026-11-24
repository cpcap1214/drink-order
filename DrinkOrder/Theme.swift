import SwiftUI
import UIKit

/// Newsprint and brass：墨黑底、紙灰點單、黃銅色只用在價格與送出鍵
enum Theme {
    static let ground = Color(hex: 0x181715)   // 舞台底色（墨黑）
    static let paper = Color(hex: 0xE8E8E3)    // 點單紙、杯上貼紙
    static let surface = Color(hex: 0xDCDCD6)  // 紙上低一階的底
    static let ink = Color(hex: 0x181715)
    static let muted = Color(hex: 0x63625C)
    static let brass = Color(hex: 0xBFB21A)
    static let counter = Color(hex: 0x2A2824)  // 舞台底部的吧台，比底色高一階

    /// Besley 800（粗 Clarendon 襯線，像出單機上的大字），標題、名字、數字用；中文接思源黑體 Black
    static func display(_ size: CGFloat) -> Font {
        Font(uiFont(family: "Besley", size: size, wght: 800, cjkWght: 900) as CTFont)
    }

    /// Libre Franklin，內文 400、強調 600；中文接思源黑體
    static func text(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        let w = wght(for: weight)
        return Font(uiFont(family: "Libre Franklin", size: size, wght: w, cjkWght: w) as CTFont)
    }

    static func applyUIKitAppearance() {
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor(ink)
        seg.backgroundColor = UIColor(surface)
        seg.setTitleTextAttributes([
            .foregroundColor: UIColor(paper),
            .font: uiFont(family: "Libre Franklin", size: 15, wght: 600, cjkWght: 600),
        ], for: .selected)
        seg.setTitleTextAttributes([
            .foregroundColor: UIColor(ink),
            .font: uiFont(family: "Libre Franklin", size: 15, wght: 400, cjkWght: 400),
        ], for: .normal)
    }

    // MARK: 字型串接：拉丁字用指定字型，中文落到思源黑體（Noto Sans TC）

    private static let wghtAxis = 0x7767_6874 // 'wght'
    private static let variationKey = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
    private static var cache: [String: UIFont] = [:]

    private static func descriptor(family: String, wght: Int) -> UIFontDescriptor {
        UIFontDescriptor(fontAttributes: [
            .family: family,
            variationKey: [wghtAxis: wght],
        ])
    }

    static func uiFont(family: String, size: CGFloat, wght: Int, cjkWght: Int) -> UIFont {
        let key = "\(family)-\(size)-\(wght)-\(cjkWght)"
        if let f = cache[key] { return f }
        let cjk = descriptor(family: "Noto Sans TC", wght: cjkWght)
        let desc = descriptor(family: family, wght: wght)
            .addingAttributes([.cascadeList: [cjk]])
        let font = UIFont(descriptor: desc, size: size)
        cache[key] = font
        return font
    }

    private static func wght(for weight: Font.Weight) -> Int {
        switch weight {
        case .ultraLight: 200
        case .thin: 100
        case .light: 300
        case .medium: 500
        case .semibold: 600
        case .bold: 700
        case .heavy: 800
        case .black: 900
        default: 400
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// 上下兩邊咬出半圓缺口的紙條（像出單機撕下來的標籤）
struct ScallopedSlip: Shape {
    var radius: CGFloat = 6
    var spacing: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let count = max(1, Int(rect.width / spacing))
        let step = rect.width / CGFloat(count)

        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        for i in 0..<count {
            let cx = rect.minX + step * (CGFloat(i) + 0.5)
            p.addLine(to: CGPoint(x: cx - radius, y: rect.minY))
            p.addArc(center: CGPoint(x: cx, y: rect.minY), radius: radius,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        for i in (0..<count).reversed() {
            let cx = rect.minX + step * (CGFloat(i) + 0.5)
            p.addLine(to: CGPoint(x: cx + radius, y: rect.maxY))
            p.addArc(center: CGPoint(x: cx, y: rect.maxY), radius: radius,
                     startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        }
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
