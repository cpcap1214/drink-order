import SwiftUI

/// 中間那杯會跟著選項即時變化的飲料
struct CupView: View {
    let order: DrinkOrder
    let sealed: Bool
    let strawIn: Bool

    // 尺寸（以大杯為基準，杯型靠 scaleEffect 縮放）
    static let cupW: CGFloat = 130
    static let cupH: CGFloat = 190
    static let headroom: CGFloat = 110          // 杯口上方留給吸管、糖粒的空間
    static let surface: CGFloat = 30            // 液面距杯口的距離（杯內座標）
    static let containerW: CGFloat = 170
    static var containerH: CGFloat { headroom + cupH }

    @State private var grains: [SugarGrain] = []
    @State private var splashID: UUID?

    private var iceCount: Int { order.iceIndex * 2 }

    var body: some View {
        ZStack {
            straw
            cupGroup
                .frame(width: Self.cupW, height: Self.cupH)
                .position(x: Self.containerW / 2, y: Self.headroom + Self.cupH / 2)
            ForEach(grains) { g in
                SugarGrainView(grain: g)
            }
        }
        .frame(width: Self.containerW, height: Self.containerH)
        .onChange(of: order.sweetnessIndex) { old, new in dropSugar(from: old, to: new) }
        .onChange(of: iceCount) { old, new in
            guard new > old else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                splashID = UUID()
            }
        }
    }

    // MARK: 杯身（杯內座標 130 x 190）

    private var cupGroup: some View {
        ZStack {
            interior
                .clipShape(CupShape())

            // 冰塊：從上方掉進杯子，去冰時融化
            ZStack {
                ForEach(0..<iceCount, id: \.self) { i in
                    IceCubeView(rotation: Self.iceRotations[i])
                        .position(Self.icePositions[i])
                        .transition(Self.iceTransition(index: i))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.55), value: iceCount)

            if let splashID {
                SplashView()
                    .id(splashID)
                    .position(x: Self.cupW / 2, y: Self.surface)
            }

            // 玻璃杯外框與反光
            // 玻璃反光：一條平塗的亮帶
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 10)
                .offset(x: -Self.cupW / 2 + 22)
                .clipShape(CupShape())
            // 自備杯：杯身換成黃銅色粗框
            CupShape()
                .stroke(order.ownCup ? Theme.brass : Theme.paper, lineWidth: order.ownCup ? 5 : 2.5)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: order.ownCup)

            NameSticker(name: order.trimmedName)
                .position(x: Self.cupW / 2, y: 108)

            SealFilm(sealed: sealed)
                .position(x: Self.cupW / 2, y: 0)
        }
    }

    private var interior: some View {
        ZStack {
            Rectangle().fill(Color.white.opacity(0.035))

            // 液體：換飲料時顏色漸變
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                WaveShape(phase: t * 2.2, amplitude: 2.5, surfaceY: Self.surface)
                    .fill(order.drink.color)
            }
            .opacity(0.95)
            .animation(.easeInOut(duration: 0.8), value: order.drink)

            // 布丁：杯底左側一塊
            ToppingPiece(isOn: order.toppings.contains(.pudding), index: 0, fromY: 70) {
                PuddingView()
            }
            .position(x: 44, y: 164)

            // 仙草：底部上方幾塊深色凍
            ForEach(Array(Self.jellyPositions.enumerated()), id: \.offset) { i, p in
                ToppingPiece(isOn: order.toppings.contains(.grassJelly), index: i, fromY: 110) {
                    JellyCube(rotation: Double(i * 17 % 30) - 15)
                }
                .position(p)
            }

            // 椰果：懸浮在中段，從液面掉下來
            ForEach(Array(Self.coconutPositions.enumerated()), id: \.offset) { i, p in
                ToppingPiece(isOn: order.toppings.contains(.coconut), index: i, fromY: -70) {
                    CoconutCube(rotation: Double(i * 23 % 40) - 20)
                }
                .position(p)
            }

            // 珍珠
            ForEach(Array(Self.pearlPositions.enumerated()), id: \.offset) { i, p in
                PearlView(index: i, total: Self.pearlPositions.count, isOn: order.pearls)
                    .position(p)
            }
        }
    }

    private var straw: some View {
        Capsule()
            .fill(Theme.paper)
            .frame(width: 10, height: 210)
            .rotationEffect(.degrees(9))
            .position(x: Self.containerW / 2 + 14, y: strawIn ? 150 : 10)
            .opacity(strawIn ? 1 : 0)
    }

    // MARK: 糖粒

    private func dropSugar(from old: Int, to new: Int) {
        guard new > old, new > 0 else { return }
        let count = new * 7 + 3
        let cupTop = Self.headroom
        let newGrains = (0..<count).map { _ in
            SugarGrain(
                x: CGFloat.random(in: 50...(Self.containerW - 50)),
                startY: CGFloat.random(in: -10...30),
                endY: cupTop + Self.surface + CGFloat.random(in: -2...6),
                drift: CGFloat.random(in: -8...8),
                delay: Double.random(in: 0...0.45),
                rotation: Double.random(in: 0...90)
            )
        }
        grains += newGrains
        let ids = Set(newGrains.map(\.id))
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            grains.removeAll { ids.contains($0.id) }
        }
    }

    // MARK: 固定位置資料

    static let icePositions: [CGPoint] = [
        CGPoint(x: 42, y: 46), CGPoint(x: 84, y: 40),
        CGPoint(x: 104, y: 60), CGPoint(x: 60, y: 66),
        CGPoint(x: 28, y: 70), CGPoint(x: 80, y: 78),
    ]
    static let jellyPositions: [CGPoint] = [
        CGPoint(x: 92, y: 140), CGPoint(x: 74, y: 128), CGPoint(x: 104, y: 122),
        CGPoint(x: 58, y: 142), CGPoint(x: 86, y: 112),
    ]
    static let coconutPositions: [CGPoint] = [
        CGPoint(x: 34, y: 84), CGPoint(x: 52, y: 96), CGPoint(x: 96, y: 90),
        CGPoint(x: 70, y: 80), CGPoint(x: 108, y: 104), CGPoint(x: 40, y: 112),
        CGPoint(x: 82, y: 100), CGPoint(x: 62, y: 116), CGPoint(x: 100, y: 74),
    ]
    static let iceRotations: [Double] = [12, -10, 22, -18, 6, -26]

    static let pearlPositions: [CGPoint] = {
        var pts: [CGPoint] = []
        let d: CGFloat = 13
        for row in 0..<4 {
            let count = 7 - row
            let startX = cupW / 2 - CGFloat(count - 1) * d / 2
            let y = cupH - 8 - CGFloat(row) * 11
            for c in 0..<count {
                let jitter = CGFloat((row * 7 + c) % 3) - 1
                pts.append(CGPoint(x: startX + CGFloat(c) * d + jitter, y: y))
            }
        }
        return pts
    }()

    static func iceTransition(index: Int) -> AnyTransition {
        .asymmetric(
            insertion: .offset(y: -170)
                .combined(with: .opacity)
                .animation(.spring(response: 0.45, dampingFraction: 0.5).delay(Double(index % 2) * 0.12)),
            removal: .modifier(active: MeltModifier(progress: 1), identity: MeltModifier(progress: 0))
                .animation(.easeIn(duration: 1.1))
        )
    }
}

// MARK: - 名字貼紙（和點單同一張紙）

struct NameSticker: View {
    let name: String

    private var fontSize: CGFloat {
        name.count <= 4 ? 19 : max(10, 78 / CGFloat(name.count))
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(name.enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.1).combined(with: .opacity).combined(with: .offset(y: -8)),
                            removal: .opacity
                        )
                    )
            }
        }
        .font(Theme.display(fontSize))
        .foregroundStyle(Theme.ink)
        .frame(width: 86, height: 36)
        .background(Theme.paper)
        .rotationEffect(.degrees(-4))
        .scaleEffect(name.isEmpty ? 0.3 : 1)
        .opacity(name.isEmpty ? 0 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: name)
    }
}

// MARK: - 封膜

struct SealFilm: View {
    let sealed: Bool

    var body: some View {
        Rectangle()
            .fill(Theme.paper)
            .frame(width: 140, height: 8)
            .scaleEffect(x: sealed ? 1 : 0.05, y: 1)
            .offset(y: sealed ? 0 : -40)
            .opacity(sealed ? 1 : 0)
    }
}

// MARK: - 冰塊

struct IceCubeView: View {
    let rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.78))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 8, height: 4)
                    .padding(4)
            }
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(rotation))
    }
}

/// 冰塊融化：往下塌、變糊、變透明
struct MeltModifier: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1 + progress * 0.25, y: 1 - progress * 0.8, anchor: .bottom)
            .blur(radius: progress * 4)
            .opacity(1 - progress)
    }
}

/// 冰塊落水的水花
struct SplashView: View {
    @State private var burst = false

    private let drops: [(angle: Double, distance: CGFloat)] = [
        (-160, 26), (-130, 34), (-105, 30), (-75, 30), (-50, 34), (-20, 26),
    ]

    var body: some View {
        ZStack {
            ForEach(drops.indices, id: \.self) { i in
                let d = drops[i]
                let rad = d.angle * .pi / 180
                Circle()
                    .fill(Theme.paper)
                    .frame(width: 6, height: 6)
                    .offset(x: burst ? cos(rad) * d.distance : 0,
                            y: burst ? sin(rad) * d.distance : 0)
                    .scaleEffect(burst ? 0.4 : 1)
                    .opacity(burst ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { burst = true }
        }
    }
}

// MARK: - 其他加料

/// 加料出現／消失：從 fromY 的位置彈進來，關掉就退回去
struct ToppingPiece<Content: View>: View {
    let isOn: Bool
    let index: Int
    let fromY: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .offset(y: isOn ? 0 : fromY)
            .opacity(isOn ? 1 : 0)
            .animation(
                isOn
                    ? .spring(response: 0.5, dampingFraction: 0.5).delay(Double(index) * 0.05)
                    : .easeIn(duration: 0.45).delay(Double(index) * 0.02),
                value: isOn
            )
    }
}

struct PuddingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0x7A3E14)).frame(height: 7)   // 焦糖
            Rectangle().fill(Color(hex: 0xEDBE4E))                     // 布丁
        }
        .frame(width: 44, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct JellyCube: View {
    let rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(hex: 0x241A15))
            .overlay(alignment: .topLeading) {
                Rectangle().fill(Color.white.opacity(0.18)).frame(width: 5, height: 2).padding(3)
            }
            .frame(width: 15, height: 15)
            .rotationEffect(.degrees(rotation))
    }
}

struct CoconutCube: View {
    let rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: 0xF4F1E4).opacity(0.75))
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - 珍珠

struct PearlView: View {
    let index: Int
    let total: Int
    let isOn: Bool

    var body: some View {
        Circle()
            .fill(Color(hex: 0x2B1A12))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 4, height: 4)
                    .offset(x: 3, y: 2.5)
            }
            .frame(width: 13, height: 13)
            .offset(y: isOn ? 0 : 80)
            .opacity(isOn ? 1 : 0)
            .animation(
                isOn
                    ? .spring(response: 0.45, dampingFraction: 0.42).delay(Double(index) * 0.045)
                    : .easeIn(duration: 0.6).delay(Double(total - index) * 0.02),
                value: isOn
            )
    }
}

// MARK: - 糖粒

struct SugarGrain: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let drift: CGFloat
    let delay: Double
    let rotation: Double
}

struct SugarGrainView: View {
    let grain: SugarGrain
    @State private var appeared = false
    @State private var fallen = false
    @State private var dissolved = false

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.white)
            .frame(width: 4, height: 4)
            .rotationEffect(.degrees(fallen ? grain.rotation + 180 : grain.rotation))
            .position(x: grain.x + (fallen ? grain.drift : 0),
                      y: fallen ? grain.endY : grain.startY)
            .opacity(appeared && !dissolved ? 1 : 0)
            .onAppear {
                withAnimation(.linear(duration: 0.05).delay(grain.delay)) { appeared = true }
                withAnimation(.easeIn(duration: 0.7).delay(grain.delay)) { fallen = true }
                withAnimation(.easeOut(duration: 0.3).delay(grain.delay + 0.65)) { dissolved = true }
            }
    }
}
