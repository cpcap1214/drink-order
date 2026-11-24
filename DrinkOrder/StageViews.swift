import SwiftUI

// MARK: - 右上角小時鐘

struct ClockView: View {
    let date: Date

    @State private var hourAngle: Double = 0
    @State private var minuteAngle: Double = 0

    private let size: CGFloat = 54

    var body: some View {
        ZStack {
            Circle().fill(Theme.paper)

            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Theme.ink.opacity(i % 3 == 0 ? 1 : 0.35))
                    .frame(width: i % 3 == 0 ? 2.5 : 1.5, height: i % 3 == 0 ? 6 : 4)
                    .offset(y: -size / 2 + 6)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            hand(length: size * 0.26, width: 3.5)
                .rotationEffect(.degrees(hourAngle))
            hand(length: size * 0.38, width: 2)
                .rotationEffect(.degrees(minuteAngle))

            Circle().fill(Theme.ink).frame(width: 5, height: 5)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("取餐時間 \(Self.format(date))")
        .onAppear {
            let t = Self.angles(for: date)
            hourAngle = t.hour
            minuteAngle = t.minute
        }
        .onChange(of: date) { _, newDate in
            let t = Self.angles(for: newDate)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                hourAngle = Self.shortest(from: hourAngle, to: t.hour)
                minuteAngle = Self.shortest(from: minuteAngle, to: t.minute)
            }
        }
    }

    private func hand(length: CGFloat, width: CGFloat) -> some View {
        Capsule()
            .fill(Theme.ink)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
    }

    static func angles(for date: Date) -> (hour: Double, minute: Double) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double((c.hour ?? 0) % 12)
        let m = Double(c.minute ?? 0)
        return ((h + m / 60) * 30, m * 6)
    }

    /// 走最短的方向轉過去，避免 59 分 → 0 分時倒轉一整圈
    static func shortest(from current: Double, to target: Double) -> Double {
        var delta = (target - current).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return current + delta
    }

    static func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 杯數：旁邊的小杯子

struct MiniCupsView: View {
    let extra: Int
    let color: Color
    let sealed: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
            ForEach(0..<extra, id: \.self) { i in
                MiniCupView(color: color, sealed: sealed)
                    .offset(x: CGFloat(i % 3) * 27, y: -CGFloat(i / 3) * 40)
                    .transition(
                        .asymmetric(
                            insertion: .offset(x: 180).combined(with: .opacity),
                            removal: .offset(x: 180).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(width: 80, height: CGFloat(max(1, (extra + 2) / 3)) * 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: extra)
    }
}

struct MiniCupView: View {
    let color: Color
    let sealed: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            CupShape().fill(Color.white.opacity(0.06))
            Rectangle()
                .fill(color)
                .frame(height: 26)
                .animation(.easeInOut(duration: 0.8), value: color)
        }
        .clipShape(CupShape())
        .overlay(CupShape().stroke(Theme.paper, lineWidth: 1.5))
        .overlay(alignment: .top) {
            if sealed {
                Rectangle().fill(Theme.paper).frame(width: 26, height: 3).offset(y: -1)
            }
        }
        .frame(width: 24, height: 34)
    }
}

// MARK: - 袋子

/// 舞台左下、放在吧台上的牛皮紙袋，印著單號
struct BagView: View {
    let option: BagOption
    let orderNo: Int

    private static let kraft = Color(hex: 0xB98A57)
    private static let fold = Color(hex: 0xA57A4B)
    private static let handle = Color(hex: 0x7C5530)

    private var size: CGSize {
        option == .carrier ? CGSize(width: 112, height: 96) : CGSize(width: 72, height: 92)
    }

    var body: some View {
        VStack(spacing: -8) {
            // 提把
            HStack(spacing: option == .carrier ? 34 : 0) {
                ForEach(0..<(option == .carrier ? 2 : 1), id: \.self) { _ in
                    UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                        .stroke(Self.handle, lineWidth: 4)
                        .frame(width: 28, height: 30)
                }
            }
            ZStack(alignment: .top) {
                Rectangle().fill(Self.kraft)
                Rectangle().fill(Self.fold).frame(height: 12)
                Text("No.\(orderNo)")
                    .font(Theme.display(option == .carrier ? 22 : 16))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 30)
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityElement()
        .accessibilityLabel(option.rawValue)
    }
}

/// 點單上袋子選項的小圖
struct BagIcon: View {
    let option: BagOption
    let color: Color

    var body: some View {
        switch option {
        case .none:
            CupShape()
                .stroke(color, lineWidth: 2)
                .frame(width: 22, height: 30)
        case .single:
            bag(width: 22, handles: 1)
        case .carrier:
            bag(width: 38, handles: 2)
        }
    }

    private func bag(width: CGFloat, handles: Int) -> some View {
        VStack(spacing: -2) {
            HStack(spacing: 8) {
                ForEach(0..<handles, id: \.self) { _ in
                    UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5)
                        .stroke(color, lineWidth: 2)
                        .frame(width: 10, height: 9)
                }
            }
            Rectangle()
                .fill(color)
                .frame(width: width, height: 23)
        }
    }
}
