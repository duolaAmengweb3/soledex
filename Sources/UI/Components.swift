import SwiftUI

func brandGlyph(_ brand: String) -> String { "shoe.fill" }

// Shows the owner's real photo (aspect-fill) when present, else a rich branded fallback.
struct SneakerImage: View {
    let item: Sneaker
    var glyphScale: CGFloat = 0.42
    var body: some View {
        if let ui = PhotoStore.load(item.imageFile) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            GeometryReader { g in
                ZStack {
                    LinearGradient(colors: [Color(hex: item.tint), Color(hex: item.tint).opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "shoe.fill").font(.system(size: min(g.size.width, g.size.height) * glyphScale, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92)).rotationEffect(.degrees(-8))
                }
            }
        }
    }
}

struct SoleThumb: View {
    let item: Sneaker
    var size: CGFloat = 64
    var body: some View {
        SneakerImage(item: item).frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }
}

// Fake barcode strip — gives the drop card a real box-label / ticket character.
struct Barcode: View {
    let seed: String
    var color: Color = .white
    private var widths: [CGFloat] {
        let h = abs(seed.hashValue)
        return (0..<34).map { CGFloat((h >> ($0 % 30)) & 0x3) + 1 }
    }
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, w in
                Rectangle().fill(color).frame(width: w)
            }
        }.frame(height: 26)
    }
}

// The signature artifact: a sneaker box label / ticket — real photo + barcode + style code.
struct DropCard: View {
    let item: Sneaker
    var body: some View {
        VStack(spacing: 0) {
            // dark ticket header
            HStack {
                Text("SOLEDEX").font(.system(size: 12, weight: .heavy)).tracking(2).foregroundStyle(.white)
                Spacer()
                Text(item.condition).font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.accent)
            }.padding(.horizontal, 16).padding(.vertical, 12).background(Theme.ink)

            // big real photo
            SneakerImage(item: item, glyphScale: 0.5).frame(height: 220).frame(maxWidth: .infinity).clipped()
                .overlay(alignment: .topLeading) {
                    if item.isRare { Chip(text: item.edition == "General Release" ? "GRAIL" : item.edition.uppercased(), icon: "flame.fill", color: Theme.rare).padding(12) }
                }

            VStack(spacing: 12) {
                VStack(spacing: 5) {
                    Text(item.name).font(.system(size: 20, weight: .heavy)).foregroundStyle(Theme.ink).multilineTextAlignment(.center).lineLimit(2)
                    Text([item.colorway, item.size.isEmpty ? "" : "Size \(item.size)"].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.inkMid)
                }
                Text(item.valuation.median.usd).font(Theme.display(46)).foregroundStyle(Theme.accent).monospacedDigit()
                // ticket footer: barcode + style code
                VStack(spacing: 5) {
                    Barcode(seed: item.styleCode.isEmpty ? item.name : item.styleCode, color: Theme.ink)
                    Text(item.styleCode.isEmpty ? item.year : "\(item.styleCode)   ·   \(item.year)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(Theme.inkMid)
                }.padding(.top, 2)
            }.padding(.vertical, 18).padding(.horizontal, 16)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .shadow(color: Color(hex: 0x3A1A0A).opacity(0.12), radius: 20, x: 0, y: 10)
    }
}

// Image-forward gallery tile.
struct ItemTile: View {
    let item: Sneaker
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                SneakerImage(item: item).frame(maxWidth: .infinity).frame(height: 130).clipped()
                if item.isRare { Image(systemName: "flame.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).padding(6).background(Theme.rare, in: Circle()).padding(8) }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.valuation.median.usd).font(Theme.display(18)).foregroundStyle(Theme.accent).monospacedDigit()
                    if item.hasCost { Text((item.profit >= 0 ? "▲" : "▼") + abs(item.profit).usd).font(.system(size: 10, weight: .bold)).foregroundStyle(item.profit >= 0 ? Theme.good : Theme.inkLow) }
                }
            }.padding(10)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ValueRangeBar: View {
    let v: Valuation
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.accent.opacity(0.14)).frame(height: 8)
                    let span = max(v.high - v.low, 1)
                    let x = CGFloat((v.median - v.low) / span) * g.size.width
                    Circle().fill(Theme.accent).frame(width: 14, height: 14).offset(x: min(max(x - 7, 0), g.size.width - 14))
                }
            }.frame(height: 14)
            HStack { Text(v.low.usd).font(.system(size: 12)).foregroundStyle(Theme.inkLow); Spacer(); Text(v.high.usd).font(.system(size: 12)).foregroundStyle(Theme.inkLow) }
        }
    }
}

struct Sparkline: View {
    let values: [Double]
    var stroke: Color = Theme.accent
    var body: some View {
        GeometryReader { g in
            let vs = values.isEmpty ? [0, 0] : values
            let lo = vs.min() ?? 0, hi = vs.max() ?? 1, span = max(hi - lo, 1)
            let pts = vs.enumerated().map { i, v in
                CGPoint(x: g.size.width * CGFloat(i) / CGFloat(max(vs.count - 1, 1)),
                        y: g.size.height * (1 - CGFloat((v - lo) / span)))
            }
            ZStack {
                Path { p in p.move(to: CGPoint(x: 0, y: g.size.height)); pts.forEach { p.addLine(to: $0) }; p.addLine(to: CGPoint(x: g.size.width, y: g.size.height)) }
                    .fill(LinearGradient(colors: [stroke.opacity(0.22), stroke.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                Path { p in p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) } }
                    .stroke(stroke, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if let last = pts.last { Circle().fill(stroke).frame(width: 7, height: 7).position(last) }
            }
        }
    }
}

struct EmptyState: View {
    let icon: String; let title: String; let message: String; let cta: String?; var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            ZStack { Circle().fill(Theme.accentSoft).frame(width: 96, height: 96)
                Image(systemName: icon).font(.system(size: 38)).foregroundStyle(Theme.accent) }
            Text(title).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(message).font(.subheadline).foregroundStyle(Theme.inkMid).multilineTextAlignment(.center).lineSpacing(3).padding(.horizontal, 28)
            if let cta, let action { Button(action: action) { Text(cta) }.buttonStyle(BlazeButton()).padding(.horizontal, 40).padding(.top, 4) }
        }
    }
}
