import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    private let perks: [(String, String)] = [
        ("infinity", "Unlimited scans & valuations"),
        ("square.grid.3x3.fill", "Unlimited closet size"),
        ("chart.line.uptrend.xyaxis", "Live market refresh & value trend"),
        ("doc.richtext", "Printable PDF closet inventory")
    ]
    var body: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkMid).padding(8) } }
                .padding(.horizontal, 12).padding(.top, 8)
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        ZStack { RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.accentSoft).frame(width: 84, height: 84)
                            Image(systemName: "crown.fill").font(.system(size: 34)).foregroundStyle(Theme.accent) }
                        Text("Soledex Pro").font(Theme.display(28)).foregroundStyle(Theme.ink)
                        Text("Value your whole collection.").font(.subheadline).foregroundStyle(Theme.inkMid)
                    }.padding(.top, 4)
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(perks, id: \.1) { p in
                            HStack(spacing: 12) {
                                Image(systemName: p.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.accent).frame(width: 26)
                                Text(p.1).font(.subheadline).foregroundStyle(Theme.ink); Spacer()
                            }
                        }
                    }.card(18)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill").font(.caption).foregroundStyle(Theme.good)
                        Text("Other sneaker apps charge monthly or take a cut when you sell. Soledex is one-time — pay once, own it forever. No subscription, no commission.")
                            .font(.caption).foregroundStyle(Theme.inkMid).lineSpacing(2)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(16).padding(.bottom, 120)
            }
        }
        .screenBg()
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button { Task { if await pro.purchase() { dismiss() } } } label: {
                    if pro.purchasing { ProgressView().tint(.white) } else { Text("Unlock Soledex Pro — \(pro.priceText) once") }
                }.buttonStyle(BlazeButton()).disabled(pro.purchasing)
                HStack(spacing: 16) {
                    Button("Restore") { Task { await pro.restore(); if pro.isPro { dismiss() } } }
                    Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Privacy", destination: URL(string: "https://duolaamengweb3.github.io/soledex/privacy.html")!)
                }.font(.caption).foregroundStyle(Theme.inkLow)
            }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8).background(Theme.canvas)
        }
    }
}
