import SwiftUI

enum Confidence: String, Codable { case high, medium, low
    var label: String { ["high":"High","medium":"Medium","low":"Low"][rawValue]! + " confidence" }
    var icon: String { ["high":"checkmark.seal.fill","medium":"checkmark.seal","low":"questionmark.circle"][rawValue]! }
    var color: Color { switch self { case .high: return Theme.good; case .medium: return Theme.accent; case .low: return Theme.warn } }
}

struct SoldComp: Identifiable, Codable, Hashable { var id = UUID(); var title: String; var price: Double; var date: String; var source: String }
struct Valuation: Codable, Hashable { var median, low, high: Double; var confidence: Confidence; var comps: [SoldComp]; var note: String? }

struct Sneaker: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var brand: String
    var model: String
    var colorway: String
    var styleCode: String
    var year: String
    var condition: String        // Deadstock (new) / VNDS / Used / Beat
    var edition: String          // General Release / Limited / Collab / Retro / Sample
    var history: String
    var rarityNote: String
    var legitTips: [String]
    var query: String            // eBay query string for revalue-by-size
    var valuation: Valuation
    var size: String = ""        // user-selected, refines valuation
    var purchasePrice: Double = 0 // what the owner paid → powers portfolio P&L
    var imageFile: String? = nil  // the owner's real photo on disk
    var notes: String = ""
    var tint: UInt = 0x2A2A2E
    var date: Date = Date()

    var isRare: Bool { !rarityNote.isEmpty || !["General Release", ""].contains(edition) }
    var hasCost: Bool { purchasePrice > 0 }
    var profit: Double { hasCost ? valuation.median - purchasePrice : 0 }
    var profitPct: Double { hasCost ? (valuation.median - purchasePrice) / purchasePrice * 100 : 0 }
}

extension Double { var usd: String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"; f.maximumFractionDigits = self >= 100 ? 0 : 0
    return f.string(from: NSNumber(value: self)) ?? "$\(Int(self))"
} }

let SneakerSizes = ["6","6.5","7","7.5","8","8.5","9","9.5","10","10.5","11","11.5","12","13","14"]

struct SizePrice: Identifiable, Hashable { var id: String { size }; var size: String; var median: Double; var count: Int }

// Closet value snapshot for the value-over-time trend.
struct Snapshot: Codable, Hashable, Identifiable { var id = UUID(); var date: Date; var value: Double; var cost: Double }

// Grail wishlist with a target price → alert when market drops to/under it.
struct WishItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var query: String
    var targetPrice: Double
    var currentValue: Double
    var tint: UInt = 0x2A2A2E
    var lastChecked: Date = Date()
    var alerted: Bool = false
    var hitTarget: Bool { currentValue > 0 && currentValue <= targetPrice }
}

enum Sample {
    static let items: [Sneaker] = [
        Sneaker(name: "Air Jordan 1 Retro High OG Chicago", brand: "Jordan", model: "Air Jordan 1 High", colorway: "Chicago", styleCode: "DZ5485-612", year: "2022",
            condition: "Deadstock (new)", edition: "Retro", history: "The 2022 'Lost & Found' Chicago revived one of the most iconic AJ1 colorways with an aged, vintage finish. A grail for most collectors.",
            rarityNote: "Iconic Chicago colorway, deadstock pairs hold strong resale.",
            legitTips: ["Style code DZ5485-612 must match the box label exactly", "Check the stitching on the Swoosh is tight and even", "Wings logo embossing should be crisp, not shallow"],
            query: "Jordan Air Jordan 1 High Chicago DZ5485-612",
            valuation: Valuation(median: 230, low: 180, high: 320, confidence: .high, comps: [
                SoldComp(title: "Air Jordan 1 Chicago Lost Found DS size 10", price: 225, date: "current listing", source: "eBay (asking)"),
                SoldComp(title: "AJ1 Chicago DZ5485-612 new", price: 245, date: "current listing", source: "eBay (asking)")
            ], note: "Based on current eBay asking prices, not final sold prices."), size: "10", purchasePrice: 180, tint: 0x8E2B2B),
        Sneaker(name: "Nike Dunk Low Panda", brand: "Nike", model: "Dunk Low", colorway: "Black White (Panda)", styleCode: "DD1391-100", year: "2021",
            condition: "Used", edition: "General Release", history: "The 'Panda' Dunk became the most-sold sneaker of its era — extremely common, so used pairs sit near retail.",
            rarityNote: "",
            legitTips: ["Panda is heavily faked — verify style code DD1391-100 on the tag", "Check the suede Swoosh edges are clean", "Insole stamp alignment should be straight"],
            query: "Nike Dunk Low Panda DD1391-100",
            valuation: Valuation(median: 90, low: 60, high: 130, confidence: .medium, comps: [
                SoldComp(title: "Nike Dunk Low Panda used size 9", price: 85, date: "current listing", source: "eBay (asking)")
            ], note: "Only a few live listings found — treat this as a rough guide."), size: "9", purchasePrice: 110, tint: 0x2A2A2E),
        Sneaker(name: "adidas Yeezy Boost 350 V2 Zebra", brand: "Yeezy", model: "Yeezy Boost 350 V2", colorway: "Zebra", styleCode: "CP9654", year: "2017",
            condition: "VNDS", edition: "Limited", history: "The Zebra 350 V2 is one of the most recognizable Yeezy colorways; restocks kept prices grounded but clean pairs still command a premium.",
            rarityNote: "Sought-after Yeezy colorway — clean pairs hold value.",
            legitTips: ["SPLY-350 text mirrored correctly on the stripe", "Style code CP9654 on the box label", "Boost sole should be bright white, not yellowed (unless aged)"],
            query: "adidas Yeezy Boost 350 V2 Zebra CP9654",
            valuation: Valuation(median: 240, low: 190, high: 330, confidence: .high, comps: [
                SoldComp(title: "Yeezy 350 V2 Zebra CP9654 size 10.5", price: 235, date: "current listing", source: "eBay (asking)"),
                SoldComp(title: "Yeezy Zebra VNDS", price: 250, date: "current listing", source: "eBay (asking)")
            ], note: "Based on current eBay asking prices, not final sold prices."), size: "10.5", purchasePrice: 220, tint: 0x6E5A44)
    ]

    static let history: [Snapshot] = {
        let vals: [(Int, Double, Double)] = [(56, 470, 510), (42, 495, 510), (28, 510, 510), (14, 535, 510), (5, 548, 510)]
        return vals.map { Snapshot(date: Date(timeIntervalSinceNow: -86400 * Double($0.0)), value: $0.1, cost: $0.2) }
    }()

    static let wishlist: [WishItem] = [
        WishItem(name: "Travis Scott Air Jordan 1 Low", query: "Travis Scott Air Jordan 1 Low Mocha", targetPrice: 1000, currentValue: 1180, tint: 0x4A3B2E),
        WishItem(name: "New Balance 550 White Green", query: "New Balance 550 White Green BB550", targetPrice: 95, currentValue: 88, tint: 0x394150)
    ]
}
