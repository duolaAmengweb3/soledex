import SwiftUI

struct ScanHomeView: View {
    @EnvironmentObject var store: Store
    @Binding var showSettings: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // hero: dark closet-value block (3-second read)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CLOSET VALUE").font(.system(size: 11, weight: .bold)).tracking(1.4).foregroundStyle(.white.opacity(0.55))
                        Text(store.totalValue.usd).font(Theme.display(50)).foregroundStyle(.white).monospacedDigit().minimumScaleFactor(0.6)
                        HStack(spacing: 8) {
                            Text("\(store.items.count) pair\(store.items.count == 1 ? "" : "s")").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                            if store.hasCostData {
                                Text((store.totalProfit >= 0 ? "▲ " : "▼ ") + abs(store.totalProfit).usd)
                                    .font(.system(size: 13, weight: .heavy)).foregroundStyle(store.totalProfit >= 0 ? Theme.good : Theme.accent)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(LinearGradient(colors: [Color(hex: 0x1E1B17), Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color(hex: 0x000000).opacity(0.16), radius: 16, x: 0, y: 7)

                    Button { store.showScan = true } label: {
                        HStack(spacing: 9) { Image(systemName: "camera.viewfinder"); Text("Scan a pair") }
                    }.buttonStyle(BlazeButton())
                    if !store.isPro {
                        Text("\(store.scansLeftToday) free scans left today").font(.caption).foregroundStyle(Theme.inkLow)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if !store.items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Eyebrow(text: "Recently scanned"); Spacer() }
                            VStack(spacing: 12) {
                                ForEach(store.items.prefix(4)) { it in
                                    NavigationLink { ItemDetailView(item: it) } label: { ItemRow(item: it) }.buttonStyle(.plain)
                                }
                            }.card(14)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "Soledex reads")
                            HStack(spacing: 10) {
                                ReadChip(icon: "magnifyingglass", t: "Identify")
                                ReadChip(icon: "tag", t: "Value it")
                                ReadChip(icon: "sparkles", t: "Spot rares")
                            }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.bottom, 36)
            }
            .screenBg()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Text("Soledex").font(Theme.display(20, .heavy)).foregroundStyle(Theme.accent) }
                ToolbarItem(placement: .topBarTrailing) { Button { showSettings = true } label: { Image(systemName: "gearshape").foregroundStyle(Theme.inkMid) }.accessibilityLabel("Settings") }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
        }
    }
}

struct ItemRow: View {
    let item: Sneaker
    var body: some View {
        HStack(spacing: 12) {
            SoleThumb(item: item, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.brand).font(.system(size: 12)).foregroundStyle(Theme.inkMid)
                    if item.isRare { Chip(text: "Rare", icon: "sparkles", color: Theme.rare) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.valuation.median.usd).font(Theme.display(16)).foregroundStyle(Theme.ink).monospacedDigit()
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.inkLow)
            }
        }
    }
}

private struct ReadChip: View {
    let icon: String; let t: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 17)).foregroundStyle(Theme.accent)
            Text(t).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.inkMid)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }
}
