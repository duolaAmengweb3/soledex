import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    private let points: [(String, String, String)] = [
        ("camera.viewfinder", "Snap any sneaker", "Jordans, Yeezys, Dunks — any pair, point and shoot."),
        ("tag.fill", "See what it's worth", "Real eBay prices with a range — never an invented number."),
        ("checkmark.shield.fill", "One-time, honest", "Pay once if you love it. No subscription, no bait-and-switch.")
    ]
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)
            VStack(spacing: 10) {
                ZStack { RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.accentSoft).frame(width: 96, height: 96)
                    Image(systemName: "shoe.fill").font(.system(size: 40)).foregroundStyle(Theme.accent) }
                Text("Soledex").font(Theme.display(34)).foregroundStyle(Theme.ink)
                Text("What is your closet actually worth?").font(.callout).foregroundStyle(Theme.inkMid)
            }
            Spacer(minLength: 24)
            VStack(alignment: .leading, spacing: 22) {
                ForEach(points, id: \.1) { p in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: p.0).font(.title3).foregroundStyle(Theme.accent).frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.1).font(.headline).foregroundStyle(Theme.ink)
                            Text(p.2).font(.subheadline).foregroundStyle(Theme.inkMid).lineSpacing(2)
                        }
                    }
                }
            }.padding(.horizontal, 28)
            Spacer()
            VStack(spacing: 10) {
                Button { store.onboarded = true; store.showScan = true } label: { Text("Scan a pair") }.buttonStyle(BlazeButton())
                Button { store.onboarded = true } label: { Text("I'll explore first").font(.subheadline.weight(.medium)).foregroundStyle(Theme.inkMid) }
            }.padding(.horizontal, 24).padding(.bottom, 16)
        }
        .screenBg()
    }
}
