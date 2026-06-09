import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var showPaywall = false

    private var filtered: [Sneaker] {
        guard !query.isEmpty else { return store.items }
        let q = query.lowercased()
        return store.items.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.notes.lowercased().contains(q) }
    }
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var byValue: [Sneaker] { store.items.sorted { $0.valuation.median > $1.valuation.median } }
    private var topItem: Sneaker? { byValue.first }
    private var revealImage: Image { Image(uiImage: renderShareImage(ShareReveal(total: store.totalValue, count: store.items.count, top: Array(byValue.prefix(3)), profit: store.hasCostData ? store.totalProfit : nil))) }

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ScrollView {
                        EmptyState(icon: "square.grid.2x2", title: "Your closet is empty",
                                   message: "Scan a pair and add it here to track what your collection is worth — all stored privately on your device.",
                                   cta: "Scan a pair") { store.showScan = true }
                            .padding(.top, 80)
                    }
                } else { populated }
            }
            .screenBg()
            .navigationTitle("Closet")
            .toolbar {
                if !store.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        if store.isPro {
                            ShareLink(item: store.inventoryPDF()) { Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.accent) }
                        } else {
                            Button { showPaywall = true } label: { Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.inkLow) }
                        }
                    }
                }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            .searchable(text: $query, prompt: "Search your closet")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func heroStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(.white.opacity(0.5))
            Text(value).font(Theme.display(19)).foregroundStyle(color).monospacedDigit()
        }.frame(maxWidth: .infinity)
    }

    private var populated: some View {
        ScrollView {
            VStack(spacing: 16) {
                // dark hero block — the drama
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLOSET VALUE").font(.system(size: 11, weight: .bold)).tracking(1.4).foregroundStyle(.white.opacity(0.55))
                            Text(store.totalValue.usd).font(Theme.display(46)).foregroundStyle(.white).monospacedDigit().minimumScaleFactor(0.6)
                        }
                        Spacer()
                        if store.hasTrend {
                            Text((store.trendChange >= 0 ? "▲ " : "▼ ") + abs(store.trendChange).usd)
                                .font(.system(size: 14, weight: .heavy)).foregroundStyle(store.trendChange >= 0 ? Theme.good : Theme.accent)
                                .padding(.horizontal, 10).padding(.vertical, 5).background(.white.opacity(0.12), in: Capsule())
                        }
                    }
                    if store.hasTrend { Sparkline(values: store.trendSeries.map(\.value), stroke: Theme.accent).frame(height: 54) }
                    HStack(spacing: 0) {
                        heroStat("PAIRS", "\(store.items.count)", .white)
                        if store.hasCostData {
                            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 30)
                            heroStat("PAID", store.costBasis.usd, .white)
                            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 30)
                            heroStat(store.totalProfit >= 0 ? "PROFIT" : "DOWN", (store.totalProfit >= 0 ? "+" : "") + store.totalProfit.usd, store.totalProfit >= 0 ? Theme.good : Theme.accent)
                        }
                    }
                }
                .padding(20)
                .background(LinearGradient(colors: [Color(hex: 0x1E1B17), Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color(hex: 0x000000).opacity(0.18), radius: 18, x: 0, y: 8)

                HStack(spacing: 10) {
                    ShareLink(item: revealImage, preview: SharePreview("My sneaker closet", image: revealImage)) {
                        HStack(spacing: 7) { Image(systemName: "square.and.arrow.up"); Text("Share") }
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 48)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Button { if store.isPro { Task { await store.refreshPrices() } } else { showPaywall = true } } label: {
                        HStack(spacing: 6) { if store.refreshing { ProgressView().controlSize(.mini) } else { Image(systemName: store.isPro ? "arrow.clockwise" : "lock.fill") }
                            Text(store.refreshing ? "Refreshing…" : "Refresh").fontWeight(.bold) }
                            .font(.system(size: 15)).foregroundStyle(Theme.ink).frame(maxWidth: .infinity).frame(height: 48)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1))
                    }.disabled(store.refreshing)
                }

                if let gem = topItem, store.items.count >= 2 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill").foregroundStyle(Theme.rare)
                        Text("Hidden gem: **\(gem.name)** at \(gem.valuation.median.usd) is your heat.")
                            .font(.system(size: 12)).foregroundStyle(Theme.inkMid)
                        Spacer(minLength: 0)
                    }.padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1))
                }

                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(filtered) { it in
                        NavigationLink { ItemDetailView(item: it) } label: { ItemTile(item: it) }.buttonStyle(.plain)
                    }
                }
                if filtered.isEmpty { Text("No items match “\(query)”.").font(.subheadline).foregroundStyle(Theme.inkMid).padding(.top, 24) }
            }
            .padding(.horizontal, 16).padding(.bottom, 36)
        }
    }
}

struct ItemDetailView: View {
    @State var item: Sneaker
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var showCorrect = false
    private var shareImage: Image { Image(uiImage: renderShareImage(ShareDrop(item: item))) }
    var body: some View {
        ScrollView { DetailContent(item: item, onCorrect: { showCorrect = true }, onChange: { item = $0; store.update($0) }).padding(.horizontal, 18).padding(.bottom, 24) }
            .screenBg()
            .navigationTitle(item.name).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        ShareLink(item: shareImage, preview: SharePreview(item.name, image: shareImage)) { Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.accent) }
                        Menu { Button(role: .destructive) { store.delete(item); dismiss() } label: { Label("Delete", systemImage: "trash") } }
                            label: { Image(systemName: "ellipsis.circle").foregroundStyle(Theme.inkMid) }
                    }
                }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            .sheet(isPresented: $showCorrect) { CorrectionView(item: item) { c in item = c; store.update(c) } }
    }
}
