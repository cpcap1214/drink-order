import SwiftUI

struct ContentView: View {
    @State private var order = DrinkOrder()
    @State private var sealed = false
    @State private var strawIn = false
    @State private var shakeCount = 0
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var orderNo = Int.random(in: 101...899)
    @FocusState private var nameFocused: Bool

    private var canSubmit: Bool { !order.trimmedName.isEmpty && !isSubmitting }

    var body: some View {
        VStack(spacing: 0) {
            stage
            ScrollView {
                VStack(spacing: 10) {
                    slip
                    stub
                }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.ground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("訂單成立", isPresented: $showAlert) {
            Button("好") { finishOrder() }
        } message: {
            Text(order.summary)
        }
    }

    // MARK: - 舞台：杯子、時鐘、小杯子

    private var stage: some View {
        ZStack {
            // 背後放大到整個舞台寬的飲料名，比底色亮一階
            Text(order.drink.rawValue)
                .font(Theme.display(150))
                .foregroundStyle(Theme.counter)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 54)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: order.drink)
                .accessibilityHidden(true)

            // 吧台：杯子放在上面
            Rectangle()
                .fill(Theme.counter)
                .frame(height: 30)
                .frame(maxHeight: .infinity, alignment: .bottom)

            // 左下：袋子
            ZStack(alignment: .bottomLeading) {
                Color.clear
                if order.bag != .none {
                    BagView(option: order.bag, orderNo: orderNo)
                        .id(order.bag)
                        .transition(.asymmetric(
                            insertion: .offset(y: 160),
                            removal: .offset(y: 160)
                        ))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.62), value: order.bag)
            .padding(.leading, 20)
            .padding(.bottom, 14)

            CupView(order: order, sealed: sealed, strawIn: strawIn)
                .scaleEffect(order.size.scale, anchor: .bottom)
                .animation(.spring(response: 0.45, dampingFraction: 0.45), value: order.size)
                .keyframeAnimator(initialValue: ShakeValues(), trigger: shakeCount) { content, v in
                    content
                        .rotationEffect(.degrees(v.angle), anchor: .bottom)
                        .offset(x: v.x, y: v.y)
                } keyframes: { _ in
                    KeyframeTrack(\.angle) {
                        CubicKeyframe(-12, duration: 0.1)
                        CubicKeyframe(12, duration: 0.12)
                        CubicKeyframe(-10, duration: 0.12)
                        CubicKeyframe(10, duration: 0.12)
                        CubicKeyframe(-6, duration: 0.12)
                        CubicKeyframe(4, duration: 0.1)
                        CubicKeyframe(0, duration: 0.12)
                    }
                    KeyframeTrack(\.x) {
                        CubicKeyframe(-6, duration: 0.1)
                        CubicKeyframe(6, duration: 0.12)
                        CubicKeyframe(-5, duration: 0.12)
                        CubicKeyframe(5, duration: 0.12)
                        CubicKeyframe(-3, duration: 0.12)
                        CubicKeyframe(0, duration: 0.22)
                    }
                    KeyframeTrack(\.y) {
                        SpringKeyframe(-18, duration: 0.25)
                        SpringKeyframe(-10, duration: 0.3)
                        SpringKeyframe(0, duration: 0.35)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 16)

            // 左上：品名與價格（Besley 行高較高，往上收）
            VStack(alignment: .leading, spacing: -10) {
                Text(order.drinkTitle)
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.paper)
                    .contentTransition(.interpolate)
                    .animation(.snappy, value: order.drinkTitle)
                Text("$\(order.total)")
                    .font(Theme.display(44))
                    .foregroundStyle(Theme.brass)
                    .contentTransition(.numericText(value: Double(order.total)))
                    .animation(.snappy, value: order.total)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 右上：取餐時鐘
            ClockView(date: order.pickupTime)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // 右下：其他杯
            VStack(alignment: .trailing, spacing: 6) {
                if order.cups > 1 {
                    Text("×\(order.cups)")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.paper)
                        .contentTransition(.numericText(value: Double(order.cups)))
                        .transition(.opacity)
                }
                MiniCupsView(extra: order.cups - 1, color: order.drink.color, sealed: sealed)
            }
            .animation(.snappy, value: order.cups)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 350)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { nameFocused = false }
    }

    // MARK: - 點單：出單機印出來的那張標籤

    private var slip: some View {
        VStack(alignment: .leading, spacing: 26) {
            // 抬頭：像出單機印出的單號
            HStack(alignment: .firstTextBaseline) {
                Text("點單")
                    .font(Theme.display(34))
                Spacer()
                Text("No.\(orderNo)")
                    .font(Theme.display(26))
                    .contentTransition(.numericText(value: Double(orderNo)))
            }
            .foregroundStyle(Theme.ink)

            // 名字
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("名字")
                TextField("", text: $order.name,
                          prompt: Text("寫上你的名字").foregroundStyle(Theme.muted))
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.ink)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Theme.surface)
                    .onChange(of: order.name) { _, new in
                        if new.count > 10 { order.name = String(new.prefix(10)) }
                    }
            }

            // 飲料
            HStack {
                fieldLabel("飲料")
                Spacer()
                Menu {
                    Picker("飲料種類", selection: $order.drink) {
                        ForEach(DrinkType.allCases) { d in
                            Text("\(d.rawValue)  $\(d.price)").tag(d)
                        }
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(order.drink.rawValue)
                            .font(Theme.display(24))
                        Text("$\(order.drink.price)")
                            .font(Theme.text(17).monospacedDigit())
                            .foregroundStyle(Theme.muted)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Theme.ink)
                }
            }
            .padding(.bottom, -12)

            drinkSwatches

            // 杯型
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("杯型")
                Picker("杯型", selection: $order.size) {
                    ForEach(CupSize.allCases) { s in
                        Text(s.extraPrice == 0 ? s.rawValue
                             : "\(s.rawValue) \(s.extraPrice > 0 ? "+" : "")\(s.extraPrice)")
                            .tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            levelSlider(title: "甜度", value: $order.sweetness, labels: DrinkOrder.sweetnessLabels)
            levelSlider(title: "冰塊", value: $order.ice, labels: DrinkOrder.iceLabels)

            Toggle(isOn: $order.pearls) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    fieldLabel("珍珠")
                    Text("+$\(DrinkOrder.pearlPrice)")
                        .font(Theme.text(17).monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("加料")
                toppingTiles
            }

            Toggle(isOn: $order.ownCup) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    fieldLabel("自備杯")
                    Text("−$\(DrinkOrder.ownCupDiscount)")
                        .font(Theme.text(17).monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
            }

            Stepper(value: $order.cups, in: 1...10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    fieldLabel("杯數")
                    Text("\(order.cups)")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText(value: Double(order.cups)))
                        .animation(.snappy, value: order.cups)
                }
            }

            DatePicker(selection: $order.pickupTime, displayedComponents: .hourAndMinute) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    fieldLabel("取餐")
                    Text(minutesUntilPickup)
                        .font(Theme.text(17))
                        .foregroundStyle(Theme.muted)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: minutesUntilPickup)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("袋子")
                bagTiles
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 34)
        .padding(.bottom, 30)
        .background(Theme.paper, in: ScallopedSlip())
        .tint(Theme.ink)
        .environment(\.colorScheme, .light)
    }

    // MARK: - 存根：撕下來的那一截，放明細、合計和送出

    private var stub: some View {
        VStack(alignment: .leading, spacing: 22) {
            receipt

            HStack(alignment: .firstTextBaseline) {
                fieldLabel("合計")
                Spacer()
                Text("$\(order.total)")
                    .font(Theme.display(52))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText(value: Double(order.total)))
                    .animation(.snappy, value: order.total)
            }

            Button(action: submit) {
                HStack {
                    Text(order.trimmedName.isEmpty ? "先寫上名字" : "送出訂單")
                        .font(Theme.display(22))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundStyle(canSubmit ? Theme.ink : Theme.muted)
                .padding(.horizontal, 20)
                .frame(height: 64)
                .background(canSubmit ? Theme.brass : Theme.surface)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle())
            .disabled(!canSubmit)
            .animation(.snappy, value: canSubmit)
        }
        .padding(.horizontal, 22)
        .padding(.top, 32)
        .padding(.bottom, 30)
        .background(Theme.paper, in: ScallopedSlip())
        .environment(\.colorScheme, .light)
    }

    /// 其他加料：可複選的方塊
    private var toppingTiles: some View {
        HStack(spacing: 8) {
            ForEach(Topping.allCases) { t in
                let on = order.toppings.contains(t)
                Button {
                    if on { order.toppings.remove(t) } else { order.toppings.insert(t) }
                } label: {
                    VStack(spacing: 2) {
                        Text(t.rawValue)
                            .font(Theme.text(17, weight: .semibold))
                        Text("+\(t.price)")
                            .font(Theme.text(14).monospacedDigit())
                    }
                    .foregroundStyle(on ? Theme.paper : Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(on ? Theme.ink : Theme.surface)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("\(t.rawValue) 加 \(t.price) 元")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(.snappy, value: order.toppings)
    }

    /// 袋子：三選一，每格畫出袋子的樣子
    private var bagTiles: some View {
        HStack(spacing: 8) {
            ForEach(BagOption.allCases) { b in
                let on = order.bag == b
                Button {
                    order.bag = b
                } label: {
                    VStack(spacing: 8) {
                        BagIcon(option: b, color: on ? Theme.paper : Theme.ink)
                            .frame(height: 34)
                        Text(b.price == 0 ? b.rawValue : "\(b.rawValue) +\(b.price)")
                            .font(Theme.text(15, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(on ? Theme.paper : Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(on ? Theme.ink : Theme.surface)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(.snappy, value: order.bag)
    }

    /// 五種飲料的色票，點了就換（和上面的 Picker 綁同一個值）
    private var drinkSwatches: some View {
        HStack(spacing: 0) {
            ForEach(DrinkType.allCases) { d in
                let selected = d == order.drink
                Button {
                    order.drink = d
                } label: {
                    VStack(spacing: 8) {
                        SwatchCup(color: d.color)
                        Text(d.rawValue)
                            .font(Theme.text(14, weight: selected ? .bold : .regular))
                            .foregroundStyle(selected ? Theme.ink : Theme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selected ? Theme.surface : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("\(d.rawValue) \(d.price) 元")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: order.drink)
    }

    /// 合計上方的明細，像收據一樣逐項列出
    private var receipt: some View {
        VStack(spacing: 10) {
            receiptRow(order.drink.rawValue, "\(order.drink.price)")
            receiptRow("\(order.sweetnessText) \(order.iceText)", "")
            if order.size.extraPrice != 0 {
                receiptRow(order.size.rawValue,
                           order.size.extraPrice > 0 ? "+\(order.size.extraPrice)" : "\(order.size.extraPrice)")
            }
            if order.pearls {
                receiptRow("珍珠", "+\(DrinkOrder.pearlPrice)")
            }
            ForEach(order.sortedToppings) { t in
                receiptRow(t.rawValue, "+\(t.price)")
            }
            if order.ownCup {
                receiptRow("自備杯", "−\(DrinkOrder.ownCupDiscount)")
            }
            if order.cups > 1 {
                receiptRow("每杯 \(order.unitPrice) × \(order.cups) 杯", "\(order.unitPrice * order.cups)")
            }
            if order.bag != .none {
                receiptRow(order.bag.rawValue, "+\(order.bag.price)")
            }
        }
        .animation(.snappy, value: order.toppings)
        .animation(.snappy, value: order.ownCup)
        .animation(.snappy, value: order.bag)
        .animation(.snappy, value: order.size)
        .animation(.snappy, value: order.pearls)
        .animation(.snappy, value: order.cups)
    }

    private func receiptRow(_ item: String, _ price: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(item)
            Spacer()
            Text(price)
                .monospacedDigit()
        }
        .font(Theme.text(17))
        .foregroundStyle(Theme.ink)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var minutesUntilPickup: String {
        let mins = Int((order.pickupTime.timeIntervalSinceNow / 60).rounded())
        if mins <= 0 { return "現在" }
        if mins < 60 { return "\(mins) 分鐘後" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h) 小時後" : "\(h) 小時 \(m) 分後"
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.text(17, weight: .semibold))
            .foregroundStyle(Theme.ink)
    }

    /// 分段的 Slider，下方印出每一段的名稱，可直接點選
    private func levelSlider(title: String, value: Binding<Double>, labels: [String]) -> some View {
        let selected = Int(value.wrappedValue.rounded())
        let last = labels.count - 1
        return VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            Slider(value: value, in: 0...Double(last), step: 1) {
                Text(title)
            }
            GeometryReader { geo in
                let inset: CGFloat = 18
                let span = geo.size.width - inset * 2
                ForEach(labels.indices, id: \.self) { i in
                    Button {
                        value.wrappedValue = Double(i)
                    } label: {
                        Text(labels[i])
                            .font(Theme.text(14, weight: i == selected ? .bold : .regular))
                            .foregroundStyle(i == selected ? Theme.ink : Theme.muted)
                            .fixedSize()
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .position(x: inset + span * CGFloat(i) / CGFloat(last), y: 12)
                }
            }
            .frame(height: 24)
        }
    }

    // MARK: - 送出：封膜 → 插吸管 → 搖一搖 → alert

    private func submit() {
        nameFocused = false
        isSubmitting = true
        Task {
            withAnimation(.easeOut(duration: 0.4)) { sealed = true }
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { strawIn = true }
            try? await Task.sleep(for: .milliseconds(650))
            shakeCount += 1
            try? await Task.sleep(for: .milliseconds(1000))
            showAlert = true
        }
    }

    private func finishOrder() {
        withAnimation(.easeInOut(duration: 0.5)) {
            sealed = false
            strawIn = false
            orderNo += 1
        }
        isSubmitting = false
    }
}

/// 點單上的小杯色票
struct SwatchCup: View {
    let color: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(Theme.paper)
            Rectangle().fill(color).frame(height: 30)
        }
        .clipShape(CupShape())
        .overlay(CupShape().stroke(Theme.ink, lineWidth: 2))
        .frame(width: 30, height: 40)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct ShakeValues {
    var angle: Double = 0
    var x: CGFloat = 0
    var y: CGFloat = 0
}

#Preview {
    ContentView()
}
