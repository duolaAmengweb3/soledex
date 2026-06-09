import SwiftUI

@MainActor func renderShareImage<V: View>(_ view: V) -> UIImage {
    let r = ImageRenderer(content: view.frame(width: 380)); r.scale = 3
    return r.uiImage ?? UIImage()
}

// Branded drop card for social sharing (one pair).
struct ShareDrop: View {
    let item: Sneaker
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SOLEDEX").font(.system(size: 14, weight: .heavy)).tracking(2).foregroundStyle(.white)
                Spacer()
                Text(item.size.isEmpty ? item.condition : "Size \(item.size)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.95))
            }.padding(.horizontal, 20).padding(.vertical, 14).background(item.isRare ? Theme.rare : Theme.accent)
            VStack(spacing: 14) {
                SoleThumb(item: item, size: 150)
                VStack(spacing: 6) {
                    Text(item.name).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center).lineLimit(2)
                    Text([item.styleCode, item.year].filter { !$0.isEmpty }.joined(separator: " · ")).font(.system(size: 15)).foregroundStyle(Theme.inkMid)
                }
                if item.isRare { Chip(text: item.edition == "General Release" ? "Grail" : item.edition, icon: "flame.fill", color: Theme.rare) }
                VStack(spacing: 2) {
                    Text("ESTIMATED VALUE").font(.system(size: 11, weight: .bold)).tracking(1.5).foregroundStyle(Theme.inkLow)
                    Text(item.valuation.median.usd).font(Theme.display(52)).foregroundStyle(Theme.accent).monospacedDigit()
                }
                Text("Scanned with Soledex").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.inkLow)
            }.padding(.vertical, 26).padding(.horizontal, 20)
        }
        .background(Theme.surface).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).padding(20).background(Theme.canvas)
    }
}

// The viral one: "my closet is worth $X" reveal.
struct ShareReveal: View {
    let total: Double; let count: Int; let top: [Sneaker]; var profit: Double? = nil
    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("MY SNEAKER CLOSET").font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(.white.opacity(0.9))
                Text(total.usd).font(Theme.display(56)).foregroundStyle(.white).monospacedDigit().minimumScaleFactor(0.5)
                Text("across \(count) pairs").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                if let profit, profit != 0 {
                    Text((profit > 0 ? "▲ up " : "▼ down ") + abs(profit).usd).font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4).background(.white.opacity(0.2), in: Capsule()).padding(.top, 2)
                }
            }
            if !top.isEmpty {
                VStack(spacing: 8) {
                    Text("HEAT").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(.white.opacity(0.85))
                    ForEach(top.prefix(3)) { it in
                        HStack(spacing: 10) {
                            SoleThumb(item: it, size: 34)
                            Text(it.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                            Spacer()
                            Text(it.valuation.median.usd).font(Theme.display(15)).foregroundStyle(.white).monospacedDigit()
                        }.padding(10).background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            Text("Scanned with Soledex").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
        }
        .padding(26)
        .background(LinearGradient(colors: [Theme.accent, Color(hex: 0xB02800)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).padding(20).background(Theme.canvas)
    }
}
