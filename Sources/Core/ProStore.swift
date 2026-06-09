import Foundation
import StoreKit

/// StoreKit 2 — Soledex Pro is a one-time non-consumable buyout (no subscription).
@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.duolaameng.soledex.pro"
    @Published var product: Product?
    @Published var isPro = false
    @Published var purchasing = false
    var priceText: String { product?.displayPrice ?? "$14.99" }

    func load() async {
        if let p = try? await Product.products(for: [Self.productID]).first { product = p }
        await refresh()
        Task.detached { for await u in Transaction.updates { if let t = try? u.payloadValue { await t.finish(); await self.refresh() } } }
    }
    func refresh() async {
        for await r in Transaction.currentEntitlements {
            if case .verified(let t) = r, t.productID == Self.productID, t.revocationDate == nil { isPro = true; return }
        }
        isPro = false
    }
    @discardableResult func purchase() async -> Bool {
        guard let product else { return false }
        purchasing = true; defer { purchasing = false }
        if let r = try? await product.purchase(), case .success(let v) = r, case .verified(let t) = v {
            await t.finish(); await refresh(); return isPro
        }
        return false
    }
    func restore() async { try? await AppStore.sync(); await refresh() }
}
