import SwiftUI

// Shared identify→value body. Size selector re-queries eBay for size-specific comps (the sneaker differentiator).
struct DetailContent: View {
    @State var item: Sneaker
    var onCorrect: (() -> Void)? = nil
    var onChange: ((Sneaker) -> Void)? = nil
    @State private var revaluing = false
    @State private var dealPrice: Double = 0
    @State private var spread: [SizePrice] = []
    @State private var loadingSpread = false

    var body: some View {
        VStack(spacing: 16) {
            DropCard(item: item)

            // value + honest trust claim
            VStack(alignment: .leading, spacing: 12) {
                HStack { Eyebrow(text: "Estimated value"); Spacer(); if revaluing { ProgressView().controlSize(.mini) } }
                Text(item.valuation.median.usd).font(Theme.display(40)).foregroundStyle(Theme.ink).monospacedDigit()
                if !item.valuation.comps.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 12)).foregroundStyle(Theme.good)
                        Text("From \(item.valuation.comps.count) real eBay listings — not an AI guess").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.good)
                    }
                }
                ValueRangeBar(v: item.valuation)
                HStack(spacing: 5) { Image(systemName: item.valuation.confidence.icon).font(.caption); Text(item.valuation.confidence.label).font(.caption.weight(.semibold)) }.foregroundStyle(item.valuation.confidence.color)
                if let note = item.valuation.note { Text(note).font(.system(size: 12)).foregroundStyle(Theme.inkMid).lineSpacing(2) }
                if item.hasCost {
                    Divider().overlay(Theme.hairline)
                    HStack {
                        Text("You paid \(item.purchasePrice.usd)").font(.system(size: 13)).foregroundStyle(Theme.inkMid)
                        Spacer()
                        Text((item.profit >= 0 ? "▲ " : "▼ ") + abs(item.profit).usd + String(format: " (%+.0f%%)", item.profitPct))
                            .font(.system(size: 14, weight: .heavy)).foregroundStyle(item.profit >= 0 ? Theme.good : Theme.accent)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            // Deal Check — practical buying tool: is the asking price fair vs market?
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Deal check — thinking of buying?")
                HStack {
                    Text("$").foregroundStyle(Theme.inkMid)
                    TextField("Asking price", value: $dealPrice, format: .number).keyboardType(.decimalPad).font(.system(size: 16, weight: .semibold))
                }.padding(.horizontal, 12).frame(height: 46).background(Theme.canvas, in: RoundedRectangle(cornerRadius: 12))
                if dealPrice > 0 {
                    let m = item.valuation.median, diff = m - dealPrice
                    let good = diff >= m * 0.08, bad = diff <= -m * 0.08
                    HStack(spacing: 8) {
                        Image(systemName: good ? "checkmark.seal.fill" : bad ? "exclamationmark.triangle.fill" : "equal.circle.fill")
                            .foregroundStyle(good ? Theme.good : bad ? Theme.accent : Theme.inkMid)
                        Text(good ? "Good deal — about \(abs(diff).usd) under market" : bad ? "Pricey — about \(abs(diff).usd) over market" : "Fair — right around market")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            // size selector — the sneaker differentiator
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Your size — price varies a lot by size")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SneakerSizes, id: \.self) { s in
                            Button { selectSize(s) } label: {
                                Text("US \(s)").font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(item.size == s ? .white : Theme.ink)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(item.size == s ? Theme.accent : Theme.canvas, in: Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).card(16)

            // size-price spread — which sizes command more
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Size spread — value by size")
                if spread.isEmpty {
                    Button { loadSpread() } label: {
                        HStack(spacing: 8) { if loadingSpread { ProgressView().controlSize(.mini) } else { Image(systemName: "chart.bar.fill") }
                            Text(loadingSpread ? "Checking sizes…" : "See which sizes are worth more").fontWeight(.semibold) }
                            .font(.system(size: 14)).foregroundStyle(Theme.accent)
                    }.disabled(loadingSpread)
                } else {
                    let maxV = spread.map(\.median).max() ?? 1
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(spread) { sp in
                            VStack(spacing: 4) {
                                Text(sp.median.usd).font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.inkMid)
                                RoundedRectangle(cornerRadius: 4).fill(sp.size == item.size ? Theme.accent : Theme.accent.opacity(0.3))
                                    .frame(height: max(8, CGFloat(sp.median / maxV) * 90))
                                Text(sp.size).font(.system(size: 10, weight: sp.size == item.size ? .bold : .regular)).foregroundStyle(sp.size == item.size ? Theme.ink : Theme.inkLow)
                            }.frame(maxWidth: .infinity)
                        }
                    }.frame(height: 130)
                    Text("Live eBay medians by US size. Your size is highlighted.").font(.caption2).foregroundStyle(Theme.inkLow)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            // comps
            if !item.valuation.comps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Live eBay listings behind this")
                    ForEach(item.valuation.comps) { c in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.title).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink).lineLimit(1)
                                Text("\(c.source) • \(c.date)").font(.system(size: 12)).foregroundStyle(Theme.inkLow)
                            }
                            Spacer(); Text(c.price.usd).font(Theme.display(15)).foregroundStyle(Theme.ink).monospacedDigit()
                        }
                        if c.id != item.valuation.comps.last?.id { Divider().overlay(Theme.hairline) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).card(18)
            }

            // sell
            VStack(spacing: 8) {
                Link(destination: ebayURL) {
                    HStack { Image(systemName: "tag.fill"); Text("Sell on eBay").fontWeight(.bold); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Text("Opens current eBay listings. Soledex never handles payments or takes a commission.").font(.caption2).foregroundStyle(Theme.inkLow).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            }

            // legit self-check ★ sneaker-specific
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Legit check — things to verify yourself")
                if item.legitTips.isEmpty {
                    Text("Always compare the box label, style code and stitching against an authentic reference before buying.").font(.system(size: 14)).foregroundStyle(Theme.inkMid)
                } else {
                    ForEach(item.legitTips, id: \.self) { t in
                        HStack(alignment: .top, spacing: 8) { Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accent).padding(.top, 2)
                            Text(t).font(.system(size: 14)).foregroundStyle(Theme.ink).lineSpacing(2) }
                    }
                }
                Text("These are tips to help you check — not an authentication guarantee.").font(.caption2).foregroundStyle(Theme.inkLow)
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            // rarity
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Hype check")
                if item.isRare {
                    Chip(text: item.edition == "General Release" ? "Grail" : item.edition, icon: "flame.fill", color: Theme.rare)
                    Text(item.rarityNote.isEmpty ? "This release can carry a premium over general releases." : item.rarityNote).font(.system(size: 14)).foregroundStyle(Theme.ink).lineSpacing(2)
                } else {
                    HStack(spacing: 8) { Image(systemName: "checkmark.circle").foregroundStyle(Theme.inkMid); Text("General release — no hype premium found.").font(.system(size: 14)).foregroundStyle(Theme.inkMid) }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            // details
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Details")
                row("Brand", item.brand); row("Model", item.model); row("Colorway", item.colorway)
                if !item.styleCode.isEmpty { row("Style code", item.styleCode) }
                row("Year", item.year); row("Condition", item.condition)
            }.frame(maxWidth: .infinity, alignment: .leading).card(18)

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) { Eyebrow(text: "My notes"); Text(item.notes).font(.system(size: 14)).foregroundStyle(Theme.ink).lineSpacing(3) }
                    .frame(maxWidth: .infinity, alignment: .leading).card(18)
            }
            if !item.history.isEmpty {
                VStack(alignment: .leading, spacing: 8) { Eyebrow(text: "About this"); Text(item.history).font(.system(size: 14)).foregroundStyle(Theme.inkMid).lineSpacing(4) }
                    .frame(maxWidth: .infinity, alignment: .leading).card(18)
            }
            if let onCorrect {
                Button(action: onCorrect) {
                    HStack(spacing: 8) { Image(systemName: "pencil.and.outline"); Text("Wrong? Fix it").fontWeight(.medium); Spacer(); Image(systemName: "chevron.right").font(.caption) }
                        .foregroundStyle(Theme.inkMid).frame(maxWidth: .infinity).frame(height: 48)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline, lineWidth: 1))
                }
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        Group { if !v.isEmpty { HStack { Text(k).font(.system(size: 14)).foregroundStyle(Theme.inkMid); Spacer(); Text(v).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink) } } }
    }
    private var ebayURL: URL {
        let q = (item.query + (item.size.isEmpty ? "" : " size \(item.size)")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.ebay.com/sch/i.html?_nkw=\(q)")!
    }
    private func loadSpread() {
        guard !loadingSpread, !item.query.isEmpty else { return }
        loadingSpread = true
        Task { if let r = try? await SoledexAPI.spread(query: item.query) { spread = r }; loadingSpread = false }
    }
    private func selectSize(_ s: String) {
        guard !revaluing else { return }
        item.size = (item.size == s ? "" : s)
        onChange?(item)
        guard !item.size.isEmpty, !item.query.isEmpty else { return }
        revaluing = true
        Task {
            if let v = try? await SoledexAPI.revalue(query: item.query, size: item.size), !v.comps.isEmpty {
                item.valuation = v; onChange?(item)
            }
            revaluing = false
        }
    }
}

struct ResultView: View {
    let item: Sneaker
    var onClose: () -> Void
    @EnvironmentObject var store: Store
    @State private var working: Sneaker
    @State private var saved = false
    @State private var showPaywall = false
    init(item: Sneaker, onClose: @escaping () -> Void) { self.item = item; self.onClose = onClose; _working = State(initialValue: item) }

    var body: some View {
        NavigationStack {
            ScrollView { DetailContent(item: working, onChange: { working = $0 }).padding(.horizontal, 18).padding(.bottom, 24) }
                .screenBg()
                .sheet(isPresented: $showPaywall) { PaywallView() }
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 12) {
                        Button { if store.canAddMore { store.add(working); saved = true; onClose() } else { showPaywall = true } } label: {
                            Label(saved ? "Saved" : "Add to closet", systemImage: saved ? "checkmark" : "plus")
                        }.buttonStyle(BlazeButton())
                        ShareLink(item: shareImage, preview: SharePreview(working.name, image: shareImage)) {
                            Image(systemName: "square.and.arrow.up").frame(width: 54, height: 54)
                                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15)).foregroundStyle(Theme.ink)
                                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.hairline, lineWidth: 1))
                        }
                    }.padding(.horizontal, 18).padding(.vertical, 10).background(Theme.canvas)
                }
                .navigationTitle("Identified").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { onClose() } label: { Image(systemName: "xmark").foregroundStyle(Theme.inkMid) } } }
                .toolbarBackground(Theme.canvas, for: .navigationBar)
        }
    }
    private var shareImage: Image { Image(uiImage: renderShareImage(ShareDrop(item: working))) }
}
