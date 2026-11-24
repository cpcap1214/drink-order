import SwiftUI

// MARK: - 飲料種類

enum DrinkType: String, CaseIterable, Identifiable {
    case blackTea = "紅茶"
    case greenTea = "綠茶"
    case milkTea = "奶茶"
    case matchaLatte = "抹茶拿鐵"
    case taroMilk = "芋頭鮮奶"

    var id: String { rawValue }

    /// 中杯基本價
    var price: Int {
        switch self {
        case .blackTea: 30
        case .greenTea: 30
        case .milkTea: 45
        case .matchaLatte: 55
        case .taroMilk: 60
        }
    }

    /// 杯中液體顏色
    var color: Color {
        switch self {
        case .blackTea: Color(red: 0.80, green: 0.42, blue: 0.10)   // 琥珀色
        case .greenTea: Color(red: 0.78, green: 0.80, blue: 0.38)   // 淡黃綠
        case .milkTea: Color(red: 0.80, green: 0.63, blue: 0.47)    // 奶咖色
        case .matchaLatte: Color(red: 0.47, green: 0.66, blue: 0.30) // 抹茶綠
        case .taroMilk: Color(red: 0.74, green: 0.62, blue: 0.86)   // 芋頭紫
        }
    }
}

// MARK: - 杯型

enum CupSize: String, CaseIterable, Identifiable {
    case small = "小杯"
    case medium = "中杯"
    case large = "大杯"

    var id: String { rawValue }

    var extraPrice: Int {
        switch self {
        case .small: -5
        case .medium: 0
        case .large: 10
        }
    }

    /// 杯子縮放比例
    var scale: CGFloat {
        switch self {
        case .small: 0.72
        case .medium: 0.86
        case .large: 1.0
        }
    }
}

// MARK: - 其他加料（珍珠另用 Toggle）

enum Topping: String, CaseIterable, Identifiable {
    case coconut = "椰果"
    case pudding = "布丁"
    case grassJelly = "仙草"

    var id: String { rawValue }

    var price: Int {
        switch self {
        case .coconut: 10
        case .pudding: 15
        case .grassJelly: 10
        }
    }
}

// MARK: - 袋子

enum BagOption: String, CaseIterable, Identifiable {
    case none = "不用袋子"
    case single = "單杯袋"
    case carrier = "提袋"

    var id: String { rawValue }

    /// 整筆訂單收一次
    var price: Int {
        switch self {
        case .none: 0
        case .single: 1
        case .carrier: 2
        }
    }
}

// MARK: - 訂單

struct DrinkOrder {
    static let sweetnessLabels = ["無糖", "微糖", "半糖", "少糖", "全糖"]
    static let iceLabels = ["去冰", "微冰", "少冰", "正常冰"]
    static let pearlPrice = 10
    static let ownCupDiscount = 5

    var name = ""
    var drink: DrinkType = .milkTea
    var size: CupSize = .medium
    var sweetness: Double = 2   // 0...4
    var ice: Double = 2         // 0...3
    var pearls = false
    var toppings: Set<Topping> = []
    var ownCup = false
    var bag: BagOption = .none
    var cups = 1
    var pickupTime = Date().addingTimeInterval(30 * 60)

    var sweetnessIndex: Int { Int(sweetness.rounded()) }
    var iceIndex: Int { Int(ice.rounded()) }

    var sweetnessText: String { Self.sweetnessLabels[sweetnessIndex] }
    var iceText: String { Self.iceLabels[iceIndex] }

    /// 依固定順序排好的加料
    var sortedToppings: [Topping] { Topping.allCases.filter { toppings.contains($0) } }

    /// 一杯的價錢（含加料、自備杯折扣）
    var unitPrice: Int {
        drink.price + size.extraPrice
            + (pearls ? Self.pearlPrice : 0)
            + sortedToppings.reduce(0) { $0 + $1.price }
            - (ownCup ? Self.ownCupDiscount : 0)
    }

    /// 袋子整筆收一次
    var total: Int { unitPrice * cups + bag.price }

    /// 例：大杯珍珠奶茶
    var drinkTitle: String { size.rawValue + (pearls ? "珍珠" : "") + drink.rawValue }

    var pickupText: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: pickupTime)
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 例：小明 的訂單：大杯珍珠奶茶 半糖少冰 ×2，共 $130，15:30 取餐
    /// 有加料、自備杯、袋子時會插在杯數後面
    var summary: String {
        var parts = ["\(trimmedName) 的訂單：\(drinkTitle) \(sweetnessText)\(iceText) ×\(cups)"]
        if !toppings.isEmpty {
            parts.append("加" + sortedToppings.map(\.rawValue).joined(separator: "、"))
        }
        if ownCup { parts.append("自備杯") }
        if bag != .none { parts.append(bag.rawValue) }
        parts.append("共 $\(total)")
        parts.append("\(pickupText) 取餐")
        return parts.joined(separator: "，")
    }
}
