import SwiftUI

// Heat — clean bright canvas, near-black ink, ONE blaze-orange accent, heavy display numerals,
// "drop card" (box-label style) as the hero artifact. Street energy, kept disciplined. Solid surfaces only.
// Deliberately distinct from Toydex (cool/cobalt), Proofd (warm cream/serif), Provena (dark/brass).
enum Theme {
    static let canvas   = Color(hex: 0xF6F5F2)   // bright warm-neutral
    static let surface  = Color(hex: 0xFFFFFF)
    static let elevated = Color(hex: 0xFFFFFF)
    static let ink      = Color(hex: 0x16130F)    // near-black
    static let inkMid   = Color(hex: 0x6B655D)
    static let inkLow   = Color(hex: 0xA8A199)
    static let accent   = Color(hex: 0xFF5A1F)    // THE color — blaze orange
    static let accentSoft = Color(hex: 0xFF5A1F).opacity(0.10)
    static let hairline = Color(hex: 0x16130F).opacity(0.08)

    static let good = Color(hex: 0x16A34A)        // value-positive / high confidence
    static let warn = Color(hex: 0xE0922A)        // low confidence
    static let rare = Color(hex: 0x111111)        // rarity badge (blackout — street/grail)

    // heavy rounded display for the value-forward numerals
    static func display(_ size: CGFloat, _ w: Font.Weight = .heavy) -> Font { .system(size: size, weight: w, design: .rounded) }
}

extension Color { init(hex: UInt) { self.init(.sRGB, red: Double((hex >> 16) & 0xff)/255, green: Double((hex >> 8) & 0xff)/255, blue: Double(hex & 0xff)/255) } }

extension View {
    func screenBg() -> some View { background(Theme.canvas.ignoresSafeArea()) }
    func card(_ pad: CGFloat = 16, radius: CGFloat = 18) -> some View {
        self.padding(pad)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
            .shadow(color: Color(hex: 0x3A1A0A).opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct BlazeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct Eyebrow: View { let text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 11, weight: .bold)).tracking(1.4).foregroundStyle(Theme.inkLow) } }

struct Chip: View {
    let text: String; var icon: String? = nil; var color: Color = Theme.inkMid
    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .bold)) }
            Text(text).font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(color == Theme.rare ? .white : color)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(color == Theme.rare ? Theme.rare : color.opacity(0.12), in: Capsule())
    }
}
