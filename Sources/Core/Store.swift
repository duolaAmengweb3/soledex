import SwiftUI
import UIKit

@MainActor
final class Store: ObservableObject {
    @Published var items: [Sneaker] = []
    @Published var snapshots: [Snapshot] = []
    @Published var wishlist: [WishItem] = []
    @Published var isPro = false
    @Published var showScan = false
    @Published var refreshing = false
    @AppStorage("soledex.onboarded") var onboarded = false
    @AppStorage("soledex.seeded") private var seeded = false

    @Published var scanDate = ""; @Published var scansToday = 0
    static let freePerDay = 3
    static let proDailyCap = 40
    static let freeCollectionMax = 25
    var canAddMore: Bool { isPro || items.count < Self.freeCollectionMax }

    private let key = "soledex.store.v1"
    init() { load() }

    var totalValue: Double { items.reduce(0) { $0 + $1.valuation.median } }
    var hasItems: Bool { !items.isEmpty }
    // Portfolio P&L — the investment view sneakerheads actually want.
    var totalCost: Double { items.reduce(0) { $0 + $1.purchasePrice } }
    var hasCostData: Bool { items.contains { $0.hasCost } }
    var totalProfit: Double { items.filter { $0.hasCost }.reduce(0) { $0 + $1.profit } }
    var costBasis: Double { items.filter { $0.hasCost }.reduce(0) { $0 + $1.purchasePrice } }
    var bestPerformer: Sneaker? { items.filter { $0.hasCost }.max { $0.profit < $1.profit } }

    // Value-over-time trend.
    var trendSeries: [Snapshot] { (snapshots + [Snapshot(date: Date(), value: totalValue, cost: totalCost)]).suffix(12) }
    var trendChange: Double { guard let first = snapshots.first else { return 0 }; return totalValue - first.value }
    var hasTrend: Bool { snapshots.count >= 2 }

    func recordSnapshot() {
        let cal = Calendar.current
        if let last = snapshots.last, cal.isDate(last.date, inSameDayAs: Date()) {
            snapshots[snapshots.count - 1] = Snapshot(date: Date(), value: totalValue, cost: totalCost)
        } else if !items.isEmpty {
            snapshots.append(Snapshot(date: Date(), value: totalValue, cost: totalCost))
        }
        if snapshots.count > 60 { snapshots.removeFirst(snapshots.count - 60) }
        save()
    }

    // Re-query eBay for every pair so the closet value reflects the live market (powers the trend).
    func refreshPrices() async {
        guard !refreshing else { return }
        refreshing = true
        for i in items.indices where !items[i].query.isEmpty {
            if let v = try? await SoledexAPI.revalue(query: items[i].query, size: items[i].size), !v.comps.isEmpty { items[i].valuation = v }
        }
        recordSnapshot(); refreshing = false; save()
    }

    // Wishlist.
    func addWish(_ w: WishItem) { wishlist.insert(w, at: 0); save() }
    func removeWish(_ w: WishItem) { wishlist.removeAll { $0.id == w.id }; save() }
    var wishHits: [WishItem] { wishlist.filter { $0.hitTarget } }

    @discardableResult func checkWishlist() async -> [WishItem] {
        var newHits: [WishItem] = []
        for i in wishlist.indices where !wishlist[i].query.isEmpty {
            if let v = try? await SoledexAPI.revalue(query: wishlist[i].query, size: ""), v.median > 0 {
                wishlist[i].currentValue = v.median; wishlist[i].lastChecked = Date()
                if wishlist[i].hitTarget && !wishlist[i].alerted { wishlist[i].alerted = true; newHits.append(wishlist[i]) }
                if !wishlist[i].hitTarget { wishlist[i].alerted = false }
            }
        }
        save(); return newHits
    }
    private func today() -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date()) }
    var scansLeftToday: Int { max(0, Self.freePerDay - (scanDate == today() ? scansToday : 0)) }
    var canScan: Bool { let n = scanDate == today() ? scansToday : 0; return isPro ? n < Self.proDailyCap : n < Self.freePerDay }
    func recordScan() { if scanDate != today() { scanDate = today(); scansToday = 0 }; scansToday += 1; save() }

    func add(_ c: Sneaker) { items.insert(c, at: 0); save() }
    func delete(_ c: Sneaker) { items.removeAll { $0.id == c.id }; save() }
    func update(_ c: Sneaker) { if let i = items.firstIndex(where: { $0.id == c.id }) { items[i] = c; save() } }

    // Printable PDF — closet inventory for insurance / records (the Pro export perk).
    func inventoryPDF() -> URL {
        let pageW: CGFloat = 612, pageH: CGFloat = 792, m: CGFloat = 48
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Soledex-Closet.pdf")
        let df = DateFormatter(); df.dateStyle = .long
        try? UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH)).writePDF(to: url) { ctx in
            ctx.beginPage(); var y: CGFloat = m
            func line(_ s: String, _ f: UIFont, _ col: UIColor = .black, _ gap: CGFloat = 18) {
                if y > pageH - m { ctx.beginPage(); y = m }
                (s as NSString).draw(at: CGPoint(x: m, y: y), withAttributes: [.font: f, .foregroundColor: col]); y += gap
            }
            line("Soledex — Sneaker Closet", .systemFont(ofSize: 22, weight: .bold), .black, 30)
            line("Generated \(df.string(from: Date()))", .systemFont(ofSize: 11), .gray, 16)
            line("Estimated total value: \(totalValue.usd)", .systemFont(ofSize: 13, weight: .semibold), .darkGray, 22)
            line("Values reflect current eBay asking prices, not a formal appraisal.", .systemFont(ofSize: 10), .gray, 22)
            for (i, it) in items.enumerated() {
                line("\(i + 1).  \(it.name)", .systemFont(ofSize: 13, weight: .semibold), .black, 17)
                line("     \(it.brand) · \(it.styleCode) · size \(it.size.isEmpty ? "—" : it.size) · \(it.condition)", .systemFont(ofSize: 11), .darkGray, 15)
                line("     Estimated \(it.valuation.median.usd)   (range \(it.valuation.low.usd)–\(it.valuation.high.usd))", .systemFont(ofSize: 11), .black, 16)
                if !it.notes.isEmpty { line("     Note: \(it.notes)", .systemFont(ofSize: 10), .gray, 15) }
                y += 8
            }
        }
        return url
    }

    private struct Snap: Codable { var items: [Sneaker]; var isPro: Bool; var scanDate: String; var scansToday: Int; var snapshots: [Snapshot]?; var wishlist: [WishItem]? }
    private func save() {
        if let d = try? JSONEncoder().encode(Snap(items: items, isPro: isPro, scanDate: scanDate, scansToday: scansToday, snapshots: snapshots, wishlist: wishlist)) { UserDefaults.standard.set(d, forKey: key) }
    }
    private func load() {
        let a = ProcessInfo.processInfo.arguments
        if a.contains("-pro") { isPro = true }
        if let d = UserDefaults.standard.data(forKey: key), let s = try? JSONDecoder().decode(Snap.self, from: d) {
            items = s.items; isPro = isPro || s.isPro; scanDate = s.scanDate; scansToday = s.scansToday
            snapshots = s.snapshots ?? []; wishlist = s.wishlist ?? []
        }
        if (!seeded && items.isEmpty) || (a.contains("-seed") && items.isEmpty) {
            items = Sample.items; snapshots = Sample.history; wishlist = Sample.wishlist; seeded = true; save()
        }
        recordSnapshot()
    }
    func persist() { save() }
}
